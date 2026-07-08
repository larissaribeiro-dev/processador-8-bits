// =============================================================================
// Arquivo    : controller_sequencer.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI, Larissa Ribeiro e Samy Mallmann
// Descrição  : Controlador-Sequenciador — núcleo do SAP-1.
//              Implementa a FSM com 6 estados de temporização (T1–T6)
//              usando um RING COUNTER (contador circular).
//              Gera a palavra de controle de 12 bits que comanda todos
//              os registradores conforme a instrução em execução.
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │  PALAVRA DE CONTROLE — 12 bits                                          │
// │  CON = Cp | Ep | ~Lm | ~CE | ~Li | ~Ei | ~La | Ea | Su | Eu | ~Lb | ~Lo │
// │        11   10    9     8     7     6     5    4    3    2    1     0   │
// └─────────────────────────────────────────────────────────────────────────┘
//
// Ring Counter — acionado pela borda NEGATIVA do clock
// Apenas uma saída alta por vez: T1, T2, T3, T4, T5, T6, T1, T2...
//
// Tabela de controle (da Lista 4):
// ┌──────────┬──────────┬───────────┬─────────────────┐
// │  Ciclo   │ Operação │  Estado   │  Sinais Ativos  │
// ├──────────┼──────────┼───────────┼─────────────────┤
// │  Busca   │  Todas   │ T1        │ Ep, ~Lm         │
// │  Busca   │  Todas   │ T2        │ Cp              │
// │  Busca   │  Todas   │ T3        │ ~CE, ~Li        │
// ├──────────┼──────────┼───────────┼─────────────────┤
// │ Execução │  LDA     │ T4        │ ~Ei, ~Lm        │
// │ Execução │  LDA     │ T5        │ ~CE, ~La        │
// │ Execução │  LDA     │ T6        │ (nenhum)        │
// ├──────────┼──────────┼───────────┼─────────────────┤
// │ Execução │  ADD     │ T4        │ ~Ei, ~Lm        │
// │ Execução │  ADD     │ T5        │ ~CE, ~Lb        │
// │ Execução │  ADD     │ T6        │ ~La, Eu         │
// ├──────────┼──────────┼───────────┼─────────────────┤
// │ Execução │  SUB     │ T4        │ ~Ei, ~Lm        │
// │ Execução │  SUB     │ T5        │ ~CE, ~Lb        │
// │ Execução │  SUB     │ T6        │ ~La, Eu, Su     │
// ├──────────┼──────────┼───────────┼─────────────────┤
// │ Execução │  OUT     │ T4        │ Ea, ~Lo         │
// │ Execução │  OUT     │ T5        │ (nenhum)        │
// │ Execução │  OUT     │ T6        │ (nenhum)        │
// ├──────────┼──────────┼───────────┼─────────────────┤
// │ Execução │  HLT     │ T4–T6     │ (nenhum/halt)   │
// └──────────┴──────────┴───────────┴─────────────────┘
//
// Opcodes (conforme Lista 4):
//   LDA = 4'b0000
//   ADD = 4'b0001
//   SUB = 4'b0010
//   OUT = 4'b1110
//   HLT = 4'b1111
//
// Entradas   :
//   clk      — clock do processador
//   rst_n    — reset assíncrono ativo em nível baixo
//   opcode   — 4 bits superiores do IR (instrução atual)
//
// Saídas     :
//   Cp, Ep           — controles do Program Counter
//   Lm_n             — controle do MAR
//   CE_n             — controle da RAM
//   Li_n, Ei_n       — controles do Instruction Register
//   La_n, Ea         — controles do Acumulador A
//   Su, Eu           — controles da ALU
//   Lb_n             — controle do Registrador B
//   Lo_n             — controle do Registrador de Saída
//   hlt              — sinal de halt (para o clock divider)
// =============================================================================

module controller_sequencer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] opcode,    // vem do Instruction Register

    // --- Sinais de controle de saída ---
    output reg        Cp,        // incrementa PC
    output reg        Ep,        // PC → barramento
    output reg        Lm_n,      // barramento → MAR    (ativo em baixo)
    output reg        CE_n,      // RAM → barramento    (ativo em baixo)
    output reg        Li_n,      // barramento → IR     (ativo em baixo)
    output reg        Ei_n,      // operando IR → barramento (ativo em baixo)
    output reg        La_n,      // barramento → Acumulador  (ativo em baixo)
    output reg        Ea,        // Acumulador → barramento
    output reg        Su,        // 0=soma, 1=subtração
    output reg        Eu,        // ALU → barramento
    output reg        Lb_n,      // barramento → Reg B  (ativo em baixo)
    output reg        Lo_n,      // barramento → Reg Saída (ativo em baixo)
    output reg        hlt        // sinal de parada
);

    // =========================================================================
    // RING COUNTER — 6 estados, um bit alto por vez
    // Acionado pela borda NEGATIVA do clock (conforme Lista 4)
    // Estado inicial após reset: T1 (6'b000001)
    // =========================================================================
    reg [5:0] ring;   // ring[0]=T1, ring[1]=T2, ..., ring[5]=T6

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring <= 6'b000001;      // começa em T1
        end
        else begin
            if (!hlt) begin
                // rotação circular: T1→T2→T3→T4→T5→T6→T1→...
                ring <= {ring[4:0], ring[5]};
            end
            // quando hlt=1: ring não avança — processador congela em T4
            // (não há atribuição, ring mantém o valor atual)
        end
    end

    // =========================================================================
    // Definição dos opcodes (parâmetros locais)
    // =========================================================================
    localparam LDA = 4'b0000;
    localparam ADD = 4'b0001;
    localparam SUB = 4'b0010;
    localparam OUT = 4'b1110;
    localparam HLT = 4'b1111;

    // =========================================================================
    // GERADOR DE PALAVRA DE CONTROLE
    // Combinacional — atualizado a cada mudança de estado ou opcode
    //
    // Valores INATIVOS (padrão de repouso):
    //   Sinais ativos em BAIXO  → valor inativo = 1
    //   Sinais ativos em ALTO   → valor inativo = 0
    //
    // Lm_n, CE_n, Li_n, Ei_n, La_n, Lb_n, Lo_n = 1 (inativos)
    // Cp, Ep, Ea, Su, Eu, hlt = 0 (inativos)
    // =========================================================================
    always @(*) begin
        // --- Valores padrão (todos inativos) ---
        Cp   = 1'b0;
        Ep   = 1'b0;
        Lm_n = 1'b1;
        CE_n = 1'b1;
        Li_n = 1'b1;
        Ei_n = 1'b1;
        La_n = 1'b1;
        Ea   = 1'b0;
        Su   = 1'b0;
        Eu   = 1'b0;
        Lb_n = 1'b1;
        Lo_n = 1'b1;
        hlt  = 1'b0;

        // =====================================================================
        // CICLO DE BUSCA — T1, T2, T3 (igual para TODAS as instruções)
        // =====================================================================

        if (ring[0]) begin          // T1 — Estado de Endereço
            Ep   = 1'b1;           // PC → barramento W
            Lm_n = 1'b0;           // barramento W → MAR
        end

        else if (ring[1]) begin     // T2 — Estado de Incremento
            Cp   = 1'b1;           // PC = PC + 1
        end

        else if (ring[2]) begin     // T3 — Estado de Memória
            CE_n = 1'b0;           // RAM[MAR] → barramento W
            Li_n = 1'b0;           // barramento W → IR
        end

        // =====================================================================
        // CICLO DE EXECUÇÃO — T4, T5, T6 (depende do opcode)
        // =====================================================================

        else if (ring[3]) begin     // T4
            case (opcode)
                LDA: begin
                    Ei_n = 1'b0;   // operando do IR → barramento
                    Lm_n = 1'b0;   // barramento → MAR
                end
                ADD: begin
                    Ei_n = 1'b0;   // operando do IR → barramento
                    Lm_n = 1'b0;   // barramento → MAR
                end
                SUB: begin
                    Ei_n = 1'b0;   // operando do IR → barramento
                    Lm_n = 1'b0;   // barramento → MAR
                end
                OUT: begin
                    Ea   = 1'b1;   // Acumulador → barramento
                    Lo_n = 1'b0;   // barramento → Reg Saída
                end
                HLT: begin
                    hlt  = 1'b1;   // para o processamento
                end
                default: begin
                    hlt  = 1'b1;   // instrução desconhecida → halt
                end
            endcase
        end

        else if (ring[4]) begin     // T5
            case (opcode)
                LDA: begin
                    CE_n = 1'b0;   // RAM[MAR] → barramento
                    La_n = 1'b0;   // barramento → Acumulador A
                end
                ADD: begin
                    CE_n = 1'b0;   // RAM[MAR] → barramento
                    Lb_n = 1'b0;   // barramento → Registrador B
                end
                SUB: begin
                    CE_n = 1'b0;   // RAM[MAR] → barramento
                    Lb_n = 1'b0;   // barramento → Registrador B
                end
                OUT: begin
                    // nenhum sinal ativo (estado ocioso)
                end
                HLT: begin
                    hlt  = 1'b1;
                end
                default: begin
                    hlt  = 1'b1;
                end
            endcase
        end

        else if (ring[5]) begin     // T6
            case (opcode)
                LDA: begin
                    // nenhum sinal ativo (estado ocioso para LDA)
                end
                ADD: begin
                    La_n = 1'b0;   // barramento → Acumulador A
                    Eu   = 1'b1;   // ALU (A+B) → barramento
                    // Su = 0 (adição) — já é o valor padrão
                end
                SUB: begin
                    La_n = 1'b0;   // barramento → Acumulador A
                    Eu   = 1'b1;   // ALU (A-B) → barramento
                    Su   = 1'b1;   // seleciona subtração
                end
                OUT: begin
                    // nenhum sinal ativo (estado ocioso)
                end
                HLT: begin
                    hlt  = 1'b1;
                end
                default: begin
                    hlt  = 1'b1;
                end
            endcase
        end

    end // always

endmodule
