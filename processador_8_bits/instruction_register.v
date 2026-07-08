// =============================================================================
// Arquivo    : instruction_register.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI
// Descrição  : Registrador de Instruções (IR) de 8 bits.
//              Recebe a instrução completa do barramento W e a divide em:
//                - Nibble alto [7:4] → opcode  → vai para o Controller
//                - Nibble baixo[3:0] → operando → volta para o barramento W
//                                                  quando Ei_n = 0
//
// Funcionamento:
//   - Li_n (Load IR, ativo '0')   : captura instrução do barramento na borda ↑
//   - Ei_n (Enable IR, ativo '0') : coloca operando [3:0] no barramento W
//   - CLR  (rst_n, assíncrono)    : zera o registrador
//
// Entradas   :
//   clk      — clock do processador
//   rst_n    — reset assíncrono ativo em nível baixo
//   Li_n     — Load IR, ativo em '0'
//   Ei_n     — Enable IR (operando para o barramento), ativo em '0'
//   bus_in   — barramento W de 8 bits (instrução completa vinda da RAM)
//
// Saídas     :
//   opcode   — 4 bits superiores do IR → Controller/Sequencer
//   bus_out  — 8 bits para o barramento W (operando nos bits [3:0], resto = 0)
// =============================================================================

module instruction_register (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       Li_n,      // ~Li: load instruction register (ativo em baixo)
    input  wire       Ei_n,      // ~Ei: enable IR output to bus  (ativo em baixo)
    input  wire [7:0] bus_in,    // barramento W
    output wire [3:0] opcode,    // nibble alto → controller
    output wire [7:0] bus_out    // nibble baixo → barramento W
);

    // -------------------------------------------------------------------------
    // Registrador interno de 8 bits
    // -------------------------------------------------------------------------
    reg [7:0] ir_reg;

    // -------------------------------------------------------------------------
    // Captura instrução do barramento quando Li_n = 0 (borda de subida do clk)
    // Reset assíncrono
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ir_reg <= 8'h00;
        end
        else if (!Li_n) begin
            ir_reg <= bus_in;
        end
    end

    // -------------------------------------------------------------------------
    // Opcode: nibble mais significativo — saída contínua para o controller
    // -------------------------------------------------------------------------
    assign opcode = ir_reg[7:4];

    // -------------------------------------------------------------------------
    // Operando: nibble menos significativo → barramento W quando Ei_n = 0
    // Os 4 bits superiores do barramento são zerados (endereço é só 4 bits)
    // -------------------------------------------------------------------------
    assign bus_out = (!Ei_n) ? {4'b0000, ir_reg[3:0]} : 8'h00;

endmodule
