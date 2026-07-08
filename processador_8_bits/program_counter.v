// =============================================================================
// Arquivo    : program_counter.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI
// Descrição  : Contador de Programa (PC) de 4 bits.
//              Armazena o endereço da próxima instrução a ser buscada.
//              Conta de 0000 a 1111 (0 a 15) conforme a execução avança.
//
// Funcionamento:
//   - Cp  (Counter Program)      : borda de subida do clk → incrementa PC
//   - Ep  (Enable Program)       : coloca o valor do PC no barramento W
//   - CLR (assíncrono, ativo '0'): zera o PC (reset da placa KEY[0])
//
// Entradas   :
//   clk   — clock do processador (vindo do clock_divider)
//   rst_n — reset assíncrono ativo em nível baixo
//   Cp    — sinal de controle: habilita incremento do PC
//   Ep    — sinal de controle: habilita saída do PC no barramento
//
// Saídas     :
//   pc_out [3:0] — valor atual do PC (4 bits)
//   bus_out[7:0] — saída para o barramento W (apenas 4 bits inferiores usados)
//                  os 4 bits superiores são 0 quando Ep=1
// =============================================================================

module program_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       Cp,        // incrementa PC
    input  wire       Ep,        // coloca PC no barramento
    output reg  [3:0] pc_out,    // valor interno do PC
    output wire [7:0] bus_out    // saída para o barramento W
);

    // -------------------------------------------------------------------------
    // Lógica de incremento — síncrona, controlada por Cp
    // Reset assíncrono por rst_n
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 4'b0000;
        end
        else if (Cp) begin
            pc_out <= pc_out + 4'd1;
        end
    end

    // -------------------------------------------------------------------------
    // Saída para o barramento — tristate simulado por MUX
    // Quando Ep=1: coloca os 4 bits do PC nos 4 bits inferiores do barramento
    // Quando Ep=0: saída em alta impedância simulada (zera — será ignorada
    //              pelo árbitro do barramento no top-level)
    // -------------------------------------------------------------------------
    assign bus_out = Ep ? {4'b0000, pc_out} : 8'h00;

endmodule
