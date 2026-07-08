// =============================================================================
// Arquivo    : accumulator.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI, Larissa Ribeiro e Samy Mallmann
// Descrição  : Acumulador A — registrador de 8 bits que armazena resultados
//              intermediários durante a execução do processador.
//
//  Possui DUAS saídas:
//    1) Saída direta para o Somador/Subtrator (acum_out) — SEMPRE ativa
//    2) Saída para o barramento W — habilitada quando Ea = 1
//
//  - La_n (Load Accumulator, ativo '0'): captura dado do barramento na borda ↑
//  - Ea   (Enable Accumulator, ativo '1'): coloca valor de A no barramento W
//
// Entradas   :
//   clk      — clock do processador
//   rst_n    — reset assíncrono ativo em nível baixo
//   La_n     — Load Accumulator, ativo em '0'
//   Ea       — Enable Accumulator para o barramento, ativo em '1'
//   bus_in   — barramento W de 8 bits
//
// Saídas     :
//   acum_out — valor do acumulador → Somador/Subtrator (contínuo)
//   bus_out  — valor do acumulador → barramento W (quando Ea = 1)
// =============================================================================

module accumulator (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       La_n,      // ~La: load accumulator (ativo em baixo)
    input  wire       Ea,        //  Ea: enable to bus    (ativo em alto)
    input  wire [7:0] bus_in,    // barramento W
    output reg  [7:0] acum_out,  // saída para a ALU (sempre ativa)
    output wire [7:0] bus_out    // saída para o barramento W
);

    // -------------------------------------------------------------------------
    // Captura dado do barramento quando La_n = 0 (borda de subida do clk)
    // Reset assíncrono
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acum_out <= 8'h00;
        end
        else if (!La_n) begin
            acum_out <= bus_in;
        end
    end

    // -------------------------------------------------------------------------
    // Saída para o barramento — habilitada quando Ea = 1
    // -------------------------------------------------------------------------
    assign bus_out = Ea ? acum_out : 8'h00;

endmodule
