// =============================================================================
// Arquivo    : output_register.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI, Larissa Ribeiro e Samy Mallmann
// Descrição  : Registrador de Saída — registrador de 8 bits que recebe o
//              resultado do Acumulador A (via barramento W) e o mantém
//              disponível para exibição no display binário (LEDs da DE10-Lite).
//
// Funcionamento:
//   - Lo_n (Load Output, ativo '0'): captura dado do barramento na borda ↑
//     Isso ocorre quando Ea=1 e Lo_n=0 simultaneamente:
//       → Ea=1  : Acumulador A coloca seu valor no barramento W
//       → Lo_n=0: Registrador de saída captura o valor do barramento
//   - Saída contínua para os LEDs (display binário)
//   - NÃO possui saída para o barramento W
//
// Na DE10-Lite:
//   out_data[7:0] → LEDR[7:0]  (display binário de 8 bits)
//
// Entradas   :
//   clk      — clock do processador
//   rst_n    — reset assíncrono ativo em nível baixo
//   Lo_n     — Load Output Register, ativo em '0'
//   bus_in   — barramento W de 8 bits
//
// Saídas     :
//   out_data — valor capturado → LEDs da placa (display binário)
// =============================================================================

module output_register (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       Lo_n,      // ~Lo: load output register (ativo em baixo)
    input  wire [7:0] bus_in,    // barramento W
    output reg  [7:0] out_data   // saída para os LEDs (display binário)
);

    // -------------------------------------------------------------------------
    // Captura dado do barramento quando Lo_n = 0 (borda de subida do clk)
    // Reset assíncrono — LEDs apagados no reset
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 8'h00;
        end
        else if (!Lo_n) begin
            out_data <= bus_in;
        end
    end

endmodule
