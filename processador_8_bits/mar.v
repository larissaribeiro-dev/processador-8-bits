// =============================================================================
// Arquivo    : mar.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI
// Descrição  : Memory Address Register (MAR) — registrador de 4 bits.
//              Armazena o endereço de memória que será acessado na RAM.
//
// Funcionamento:
//   - Recebe o endereço de 4 bits do barramento W (bits [3:0])
//   - Captura o endereço na borda de subida do clock quando ~Lm = 0
//     (~Lm ativo em nível baixo → Lm_n = 0 significa "carregar")
//   - Envia o endereço armazenado diretamente para a RAM (saída contínua)
//
// Entradas   :
//   clk      — clock do processador
//   rst_n    — reset assíncrono ativo em nível baixo
//   Lm_n     — Load MAR, ativo em '0' (barramento → MAR)
//   bus_in   — barramento W de 8 bits (apenas [3:0] são usados)
//
// Saídas     :
//   mar_addr — endereço de 4 bits enviado para a RAM
// =============================================================================

module mar (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       Lm_n,      // ~Lm: load MAR (ativo em nível baixo)
    input  wire [7:0] bus_in,    // barramento W
    output reg  [3:0] mar_addr   // endereço para a RAM
);

    // -------------------------------------------------------------------------
    // Captura o endereço do barramento na borda de subida quando Lm_n = 0
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mar_addr <= 4'b0000;
        end
        else if (!Lm_n) begin          // ativo em baixo: !Lm_n = 1 → carrega
            mar_addr <= bus_in[3:0];   // apenas os 4 bits inferiores do barramento
        end
    end

endmodule
