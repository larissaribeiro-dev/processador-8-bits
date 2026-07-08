// =============================================================================
// Arquivo    : register_b.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI, Larissa Ribeiro e Samy Mallmann
// Descrição  : Registrador B — registrador de 8 bits usado exclusivamente
//              para fornecer o segundo operando ao Somador/Subtrator (ALU).
//              Não possui saída para o barramento W (sem sinal Enable).
//
// Funcionamento:
//   - Lb_n (Load Register B, ativo '0'): captura dado do barramento na borda ↑
//   - Saída direta para a ALU — SEMPRE ativa (sem sinal de enable)
//   - Não coloca dados no barramento W
//
// Entradas   :
//   clk      — clock do processador
//   rst_n    — reset assíncrono ativo em nível baixo
//   Lb_n     — Load Register B, ativo em '0'
//   bus_in   — barramento W de 8 bits
//
// Saídas     :
//   b_out    — valor do registrador B → ALU (sempre ativa)
// =============================================================================

module register_b (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       Lb_n,      // ~Lb: load register B (ativo em baixo)
    input  wire [7:0] bus_in,    // barramento W
    output reg  [7:0] b_out      // saída para a ALU (sempre ativa)
);

    // -------------------------------------------------------------------------
    // Captura dado do barramento quando Lb_n = 0 (borda de subida do clk)
    // Reset assíncrono
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_out <= 8'h00;
        end
        else if (!Lb_n) begin
            b_out <= bus_in;
        end
    end

endmodule
