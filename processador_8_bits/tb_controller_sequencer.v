// =============================================================================
// Arquivo    : tb_controller_sequencer.v
// Projeto    : SAP-1 — Processador 8 bits
// Descrição  : Testbench UNITÁRIO do Controller/Sequencer.
//
// O que este testbench valida:
//   1. Ring Counter: avança T1→T2→T3→T4→T5→T6→T1 na borda NEGATIVA do clock
//   2. Ciclo de Busca (T1–T3): sinais iguais para TODAS as instruções
//   3. Execução LDA: sinais corretos em T4, T5, T6
//   4. Execução ADD: sinais corretos em T4, T5, T6
//   5. Execução SUB: sinais corretos em T4, T5, T6
//   6. Execução OUT: sinais corretos em T4 (Ea, Lo_n)
//   7. Execução HLT: sinal hlt=1 e ring congelado
//   8. Reset: ring volta para T1
//
// Referência da Palavra de Controle (Lista 4):
//   CON = Cp | Ep | ~Lm | ~CE | ~Li | ~Ei | ~La | Ea | Su | Eu | ~Lb | ~Lo
//
// Tabela de controle (Lista 4):
//   T1:  Ep=1, Lm_n=0
//   T2:  Cp=1
//   T3:  CE_n=0, Li_n=0
//   LDA T4: Ei_n=0, Lm_n=0   | ADD T4: Ei_n=0, Lm_n=0 | SUB T4: Ei_n=0, Lm_n=0
//   LDA T5: CE_n=0, La_n=0   | ADD T5: CE_n=0, Lb_n=0  | SUB T5: CE_n=0, Lb_n=0
//   LDA T6: (nenhum)          | ADD T6: La_n=0, Eu=1    | SUB T6: La_n=0, Eu=1, Su=1
//   OUT T4: Ea=1, Lo_n=0      | HLT T4: hlt=1
// =============================================================================

`timescale 1ns / 1ps

module tb_controller_sequencer;

    // -------------------------------------------------------------------------
    // Sinais de teste
    // -------------------------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg  [3:0] opcode;

    wire       Cp, Ep;
    wire       Lm_n, CE_n, Li_n, Ei_n, La_n;
    wire       Ea, Su, Eu;
    wire       Lb_n, Lo_n;
    wire       hlt;

    // -------------------------------------------------------------------------
    // Instância do módulo sob teste
    // -------------------------------------------------------------------------
    controller_sequencer uut (
        .clk  (clk),
        .rst_n(rst_n),
        .opcode(opcode),
        .Cp   (Cp),
        .Ep   (Ep),
        .Lm_n (Lm_n),
        .CE_n (CE_n),
        .Li_n (Li_n),
        .Ei_n (Ei_n),
        .La_n (La_n),
        .Ea   (Ea),
        .Su   (Su),
        .Eu   (Eu),
        .Lb_n (Lb_n),
        .Lo_n (Lo_n),
        .hlt  (hlt)
    );

    // -------------------------------------------------------------------------
    // Clock: 100 ns de período
    // O ring counter avança na borda NEGATIVA (negedge)
    // -------------------------------------------------------------------------
    initial clk = 1;
    always #50 clk = ~clk;

    // -------------------------------------------------------------------------
    // Opcodes (conforme Lista 4)
    // -------------------------------------------------------------------------
    localparam LDA = 4'b0000;
    localparam ADD = 4'b0001;
    localparam SUB = 4'b0010;
    localparam OUT = 4'b1110;
    localparam HLT = 4'b1111;

    // -------------------------------------------------------------------------
    // Infraestrutura de verificação
    // -------------------------------------------------------------------------
    integer erros = 0;

    // Avança para a próxima borda negativa (próximo estado do ring)
    task next_state;
        begin
            @(negedge clk);
            #2;  // aguarda propagação
        end
    endtask

    // Verifica o sinal e reporta
    task check_sinal;
        input       obtido;
        input       esperado;
        input [127:0] nome;
        input [7:0]  estado;
        begin
            if (obtido !== esperado) begin
                $display("[FALHA]   %s: esperado=%b obtido=%b (estado T%0d)",
                         nome, esperado, obtido, estado);
                erros = erros + 1;
            end
        end
    endtask

    // Verifica TODOS os sinais de um estado de busca
    task check_busca;
        input [7:0] t;
        input exp_Cp, exp_Ep, exp_Lm_n, exp_CE_n, exp_Li_n;
        input exp_Ei_n, exp_La_n, exp_Ea, exp_Su, exp_Eu, exp_Lb_n, exp_Lo_n;
        begin
            check_sinal(Cp,   exp_Cp,   "Cp",   t);
            check_sinal(Ep,   exp_Ep,   "Ep",   t);
            check_sinal(Lm_n, exp_Lm_n, "Lm_n", t);
            check_sinal(CE_n, exp_CE_n, "CE_n", t);
            check_sinal(Li_n, exp_Li_n, "Li_n", t);
            check_sinal(Ei_n, exp_Ei_n, "Ei_n", t);
            check_sinal(La_n, exp_La_n, "La_n", t);
            check_sinal(Ea,   exp_Ea,   "Ea",   t);
            check_sinal(Su,   exp_Su,   "Su",   t);
            check_sinal(Eu,   exp_Eu,   "Eu",   t);
            check_sinal(Lb_n, exp_Lb_n, "Lb_n", t);
            check_sinal(Lo_n, exp_Lo_n, "Lo_n", t);
        end
    endtask

    // =========================================================================
    // SEQUÊNCIA DE TESTES
    // =========================================================================
    initial begin
        $display("============================================================");
        $display("  TESTBENCH: Controller / Sequencer (FSM Ring Counter)");
        $display("  Ring Counter avanca na borda NEGATIVA do clock");
        $display("  Palavra de controle: Cp|Ep|~Lm|~CE|~Li|~Ei|~La|Ea|Su|Eu|~Lb|~Lo");
        $display("============================================================");

        // Estado inicial
        opcode = 4'bXXXX;
        rst_n  = 0;
        @(posedge clk); #2;

        // ---- Teste 0: Reset — ring deve começar em T1 ----
        rst_n = 1;
        #2; // combinacional atualiza
        $display("\n--- T1 apos reset ---");
        // No estado T1: Ep=1, Lm_n=0, resto inativos
        check_busca(1,
            0,  // Cp
            1,  // Ep   ← ativo
            0,  // Lm_n ← ativo (nivel baixo)
            1,  // CE_n
            1,  // Li_n
            1,  // Ei_n
            1,  // La_n
            0,  // Ea
            0,  // Su
            0,  // Eu
            1,  // Lb_n
            1   // Lo_n
        );
        $display("[OK]    T1: Ep=1, Lm_n=0 (endereco do PC vai para o MAR)");

        // ---- Avança para T2 ----
        next_state;
        $display("\n--- T2 ---");
        check_busca(2,
            1,  // Cp   ← ativo (incrementa PC)
            0,  // Ep
            1,  // Lm_n
            1,  // CE_n
            1,  // Li_n
            1,  // Ei_n
            1,  // La_n
            0,  // Ea
            0,  // Su
            0,  // Eu
            1,  // Lb_n
            1   // Lo_n
        );
        $display("[OK]    T2: Cp=1 (PC incrementado)");

        // ---- Avança para T3 ----
        next_state;
        $display("\n--- T3 ---");
        check_busca(3,
            0,  // Cp
            0,  // Ep
            1,  // Lm_n
            0,  // CE_n  ← ativo (RAM habilita saida)
            0,  // Li_n  ← ativo (instrucao vai para IR)
            1,  // Ei_n
            1,  // La_n
            0,  // Ea
            0,  // Su
            0,  // Eu
            1,  // Lb_n
            1   // Lo_n
        );
        $display("[OK]    T3: CE_n=0, Li_n=0 (instrucao da RAM vai para o IR)");

        // =========================================================
        // TESTE COM INSTRUÇÃO LDA
        // =========================================================
        $display("\n========================================");
        $display("  INSTRUCAO: LDA (opcode=0000)");
        $display("========================================");
        opcode = LDA;

        next_state; // T4 (LDA)
        $display("--- T4 (LDA) ---");
        if (Ei_n !== 0 || Lm_n !== 0) begin
            $display("[FALHA] T4 LDA: Ei_n=%b Lm_n=%b (esperado: Ei_n=0, Lm_n=0)", Ei_n, Lm_n);
            erros = erros + 1;
        end else $display("[OK]    T4 LDA: Ei_n=0 (operando->bus), Lm_n=0 (endereco->MAR)");
        // Verifica sinais inativos esperados
        if (Cp || Ep || !CE_n || !Li_n || !La_n || Ea || Su || Eu || !Lb_n || !Lo_n) begin
            $display("[FALHA] T4 LDA: Sinais inativos com valores errados");
            erros = erros + 1;
        end

        next_state; // T5 (LDA)
        $display("--- T5 (LDA) ---");
        if (CE_n !== 0 || La_n !== 0) begin
            $display("[FALHA] T5 LDA: CE_n=%b La_n=%b (esperado: CE_n=0, La_n=0)", CE_n, La_n);
            erros = erros + 1;
        end else $display("[OK]    T5 LDA: CE_n=0 (RAM->bus), La_n=0 (bus->Acumulador)");

        next_state; // T6 (LDA) — nenhum sinal ativo
        $display("--- T6 (LDA) ---");
        if (Cp || Ep || !Lm_n || !CE_n || !Li_n || !Ei_n || !La_n || Ea || Su || Eu || !Lb_n || !Lo_n || hlt) begin
            $display("[FALHA] T6 LDA: Estado ocioso deveria ter todos os sinais inativos");
            erros = erros + 1;
        end else $display("[OK]    T6 LDA: Estado ocioso — nenhum sinal ativo (correto para LDA)");

        // =========================================================
        // NOVO CICLO DE BUSCA para ADD
        // =========================================================
        next_state; // volta T1
        next_state; // T2
        next_state; // T3

        $display("\n========================================");
        $display("  INSTRUCAO: ADD (opcode=0001)");
        $display("========================================");
        opcode = ADD;

        next_state; // T4 (ADD)
        $display("--- T4 (ADD) ---");
        if (Ei_n !== 0 || Lm_n !== 0) begin
            $display("[FALHA] T4 ADD: Ei_n=%b Lm_n=%b", Ei_n, Lm_n);
            erros = erros + 1;
        end else $display("[OK]    T4 ADD: Ei_n=0, Lm_n=0 (igual LDA)");

        next_state; // T5 (ADD)
        $display("--- T5 (ADD) ---");
        if (CE_n !== 0 || Lb_n !== 0) begin
            $display("[FALHA] T5 ADD: CE_n=%b Lb_n=%b (esperado: CE_n=0, Lb_n=0)", CE_n, Lb_n);
            erros = erros + 1;
        end else $display("[OK]    T5 ADD: CE_n=0 (RAM->bus), Lb_n=0 (bus->Reg B)");

        next_state; // T6 (ADD)
        $display("--- T6 (ADD) ---");
        if (La_n !== 0 || Eu !== 1 || Su !== 0) begin
            $display("[FALHA] T6 ADD: La_n=%b Eu=%b Su=%b (esperado: La_n=0, Eu=1, Su=0)", La_n, Eu, Su);
            erros = erros + 1;
        end else $display("[OK]    T6 ADD: La_n=0, Eu=1, Su=0 (A = A+B via ALU)");

        // =========================================================
        // NOVO CICLO DE BUSCA para SUB
        // =========================================================
        next_state; // T1
        next_state; // T2
        next_state; // T3

        $display("\n========================================");
        $display("  INSTRUCAO: SUB (opcode=0010)");
        $display("========================================");
        opcode = SUB;

        next_state; // T4 (SUB)
        $display("--- T4 (SUB) ---");
        if (Ei_n !== 0 || Lm_n !== 0) begin
            $display("[FALHA] T4 SUB: Ei_n=%b Lm_n=%b", Ei_n, Lm_n);
            erros = erros + 1;
        end else $display("[OK]    T4 SUB: Ei_n=0, Lm_n=0 (igual LDA/ADD)");

        next_state; // T5 (SUB)
        $display("--- T5 (SUB) ---");
        if (CE_n !== 0 || Lb_n !== 0) begin
            $display("[FALHA] T5 SUB: CE_n=%b Lb_n=%b", CE_n, Lb_n);
            erros = erros + 1;
        end else $display("[OK]    T5 SUB: CE_n=0, Lb_n=0 (igual ADD)");

        next_state; // T6 (SUB)
        $display("--- T6 (SUB) ---");
        if (La_n !== 0 || Eu !== 1 || Su !== 1) begin
            $display("[FALHA] T6 SUB: La_n=%b Eu=%b Su=%b (esperado: La_n=0, Eu=1, Su=1)", La_n, Eu, Su);
            erros = erros + 1;
        end else $display("[OK]    T6 SUB: La_n=0, Eu=1, Su=1 (A = A-B, complemento de 2)");

        // =========================================================
        // NOVO CICLO DE BUSCA para OUT
        // =========================================================
        next_state; // T1
        next_state; // T2
        next_state; // T3

        $display("\n========================================");
        $display("  INSTRUCAO: OUT (opcode=1110)");
        $display("========================================");
        opcode = OUT;

        next_state; // T4 (OUT)
        $display("--- T4 (OUT) ---");
        if (Ea !== 1 || Lo_n !== 0) begin
            $display("[FALHA] T4 OUT: Ea=%b Lo_n=%b (esperado: Ea=1, Lo_n=0)", Ea, Lo_n);
            erros = erros + 1;
        end else $display("[OK]    T4 OUT: Ea=1, Lo_n=0 (Acumulador->bus->Reg Saida->LEDs)");

        next_state; // T5 (OUT) — ocioso
        next_state; // T6 (OUT) — ocioso
        $display("[OK]    T5/T6 OUT: estados ociosos");

        // =========================================================
        // NOVO CICLO DE BUSCA para HLT
        // =========================================================
        next_state; // T1
        next_state; // T2
        next_state; // T3

        $display("\n========================================");
        $display("  INSTRUCAO: HLT (opcode=1111)");
        $display("========================================");
        opcode = HLT;

        next_state; // T4 (HLT)
        $display("--- T4 (HLT) ---");
        if (hlt !== 1) begin
            $display("[FALHA] T4 HLT: hlt deveria ser 1. Obtido: %b", hlt);
            erros = erros + 1;
        end else $display("[OK]    T4 HLT: hlt=1 — processador congelado!");

        // Com hlt=1, o ring não deve avançar na próxima negedge
        @(negedge clk); #2;
        if (hlt !== 1) begin
            $display("[FALHA] HLT: ring avancou quando deveria estar congelado");
            erros = erros + 1;
        end else $display("[OK]    HLT: Ring congelado com hlt=1 — instrucao funciona corretamente");

        // =========================================================
        // RESULTADO FINAL
        // =========================================================
        #100;
        $display("\n============================================================");
        if (erros == 0)
            $display("  RESULTADO: SUCESSO — FSM do Controller verificada!");
        else
            $display("  RESULTADO: FALHA — %0d erro(s) encontrado(s)!", erros);
        $display("============================================================");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Monitor de estados
    // -------------------------------------------------------------------------
    initial begin
        $monitor("[t=%5t] clk=%b | opcode=%b | Cp=%b Ep=%b Lm_n=%b CE_n=%b Li_n=%b Ei_n=%b La_n=%b Ea=%b Su=%b Eu=%b Lb_n=%b Lo_n=%b hlt=%b",
                 $time, clk, opcode, Cp, Ep, Lm_n, CE_n, Li_n, Ei_n, La_n, Ea, Su, Eu, Lb_n, Lo_n, hlt);
    end

    // -------------------------------------------------------------------------
    // Dump de formas de onda
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_controller_sequencer.vcd");
        $dumpvars(0, tb_controller_sequencer);
    end

endmodule
