// =============================================================================
// Arquivo    : ram_16x8.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI, Larissa Ribeiro e Samy Mallmann
// Descrição  : - Memória RAM 16x8 bits: armazena o programa e os dados.
//              - 16 posições de 8 bits cada.
//              - Apenas leitura durante execução (~CE habilita saída).
//
// Programa de teste pré-carregado (endereços 0x0 a 0x3):
//
//   Endereço | Binário   | Instrução     | Comentário
//   ---------|-----------|---------------|---------------------------
//   0x0      | 0000 1101 | LDA 13 (0xD) | Acumulador ← RAM[13] = 28
//   0x1      | 0001 1110 | ADD 14 (0xE) | Acumulador ← 28 + RAM[14] = 28+14 = 42
//   0x2      | 0010 1111 | SUB 15 (0xF) | Acumulador ← 42 - RAM[15] = 42-10 = 32
//   0x3      | 1110 0000 | OUT          | Registrador de saída ← 32
//   0x4      | 1111 0000 | HLT          | Para o processamento
//   ...
//   0xD (13) | 0001 1100 | dado: 28     | 0x1C
//   0xE (14) | 0000 1110 | dado: 14     | 0x0E
//   0xF (15) | 0000 1010 | dado: 10     | 0x0A
//
//   Resultado esperado nos LEDs: 32 = 0010 0000
//
//	Funcionamento:
//   - CE_n (Chip Enable, ativo '0'): habilita saída da RAM no barramento
//   - Leitura assíncrona: dado disponível assim que CE_n = 0
//   - Endereço vem do MAR (4 bits)
//
// Entradas   :
//   CE_n     — Chip Enable, ativo em nível baixo
//   addr     — endereço de 4 bits vindo do MAR
//
// Saídas     :
//   bus_out  — dado de 8 bits para o barramento W
// =============================================================================

module ram_16x8 (
    input  wire       CE_n,       // ~CE: chip enable (ativo em baixo)
    input  wire [3:0] addr,       // endereço vindo do MAR
    output wire [7:0] bus_out     // saída para o barramento W
);

    // -------------------------------------------------------------------------
    // Memória: 16 posições de 8 bits
    // -------------------------------------------------------------------------
    reg [7:0] mem [0:15];

    // -------------------------------------------------------------------------
    // Inicialização da memória com o programa de teste
    // O bloco 'initial' é sintetizável na MAX 10 como inicialização de RAM
    // -------------------------------------------------------------------------
    initial begin
        // --- Programa (endereços 0x0 a 0x4) ---
        mem[4'h0] = 8'b0000_1101;  // LDA 13  → carrega RAM[13] no acumulador
        mem[4'h1] = 8'b0001_1110;  // ADD 14  → acumulador = acumulador + RAM[14]
        mem[4'h2] = 8'b0010_1111;  // SUB 15  → acumulador = acumulador - RAM[15]
        mem[4'h3] = 8'b1110_0000;  // OUT     → saída = acumulador
        mem[4'h4] = 8'b1111_0000;  // HLT     → para o processamento

        // --- Posições não utilizadas pelo programa ---
        mem[4'h5] = 8'h00;
        mem[4'h6] = 8'h00;
        mem[4'h7] = 8'h00;
        mem[4'h8] = 8'h00;
        mem[4'h9] = 8'h00;
        mem[4'hA] = 8'h00;
        mem[4'hB] = 8'h00;
        mem[4'hC] = 8'h00;

        // --- Dados (endereços 0xD, 0xE, 0xF) ---
        mem[4'hD] = 8'd28;         // 0001_1100 = 28 decimal
        mem[4'hE] = 8'd14;         // 0000_1110 = 14 decimal
        mem[4'hF] = 8'd10;         // 0000_1010 = 10 decimal
    end

    // -------------------------------------------------------------------------
    // Leitura assíncrona — saída habilitada quando CE_n = 0
    // Quando CE_n = 1: saída em alta impedância (barramento liberado)
    // -------------------------------------------------------------------------
    assign bus_out = (!CE_n) ? mem[addr] : 8'h00;

endmodule
