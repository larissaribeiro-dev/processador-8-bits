// =============================================================================
// Arquivo    : clock_divider.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI, Larissa Ribeiro e Samy Mallmann
// Descrição  : Divisor de clock. Recebe 50 MHz da DE10-Lite e gera um clock
//              lento (~1 Hz) para que a execução do processador seja visível
//              nos LEDs da placa.
//
// Entradas   :
//   clk_50   — clock de 50 MHz vindo do pino MAX10_CLK1_50 da DE10-Lite
//   rst_n    — reset assíncrono ativo em nível baixo (KEY[0] da placa)
//
// Saídas     :
//   clk_out  — clock dividido (~1 Hz para visualização nos LEDs)
// =============================================================================

module clock_divider #(
    parameter MAX_COUNT = 25_000_000   
                                       
)(
    input  wire clk_50,
    input  wire rst_n,
    output reg  clk_out
);

    // -------------------------------------------------------------------------
    // Contador interno
    // 25 bits são suficientes para contar até 25_000_000
    // (2^25 = 33_554_432 > 25_000_000)
    // -------------------------------------------------------------------------
    reg [24:0] counter;

    always @(posedge clk_50 or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 25'd0;
            clk_out <= 1'b0;
        end
        else begin
            if (counter >= MAX_COUNT - 1) begin
                counter <= 25'd0;
                clk_out <= ~clk_out;   // inverte o clock de saída
            end
            else begin
                counter <= counter + 25'd1;
            end
        end
    end

endmodule
