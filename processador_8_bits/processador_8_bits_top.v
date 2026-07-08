// =============================================================================
// Arquivo    : processador_8_bits_top.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI
// Descrição  : Módulo top-level do processador SAP-1.
//              Instancia e conecta todos os submódulos através do barramento W.
//              Mapeia os sinais para os pinos físicos da DE10-Lite.
//
// Mapeamento DE10-Lite:
//   MAX10_CLK1_50 → clk_50       (clock 50 MHz — pino PIN_P11)
//   KEY[0]        → rst_n        (reset ativo em baixo)
//   KEY[1]        → clk_manual_n (clock manual opcional — não usado por padrão)
//   LEDR[7:0]     → out_data     (display binário — resultado da execução)
//   LEDR[8]       → hlt_led      (LED acende quando HLT executado)
//   LEDR[9]       → clock lento  (pisca para indicar que o processador está vivo)
//
// Barramento W:
//   Implementado como MUX prioritário (MAX 10 não suporta tristate interno).
//   Prioridade: PC > RAM > IR > Acumulador > ALU
// =============================================================================

module processador_8_bits_top #(
    parameter MAX_COUNT = 25_000_000   // 25_000_000 = ~1 Hz na placa | 2 = simulação rápida
) (
    input  wire        MAX10_CLK1_50,   // clock 50 MHz da DE10-Lite
    input  wire [1:0]  KEY,             // KEY[0]=reset, KEY[1]=não usado
    output wire [9:0]  LEDR             // LEDs vermelhos
);

    // =========================================================================
    // Sinais internos
    // =========================================================================

    wire clk_slow;          // clock dividido (~1 Hz) para o processador
    wire rst_n;             // reset ativo em baixo
    wire hlt;               // sinal de halt do controller

    wire [7:0] w_bus;       // barramento principal de 8 bits

    wire [3:0] pc_out;      // saída do PC (endereço atual)
    wire [3:0] mar_addr;    // saída do MAR (endereço para a RAM)
    wire [3:0] opcode;      // saída do IR (nibble alto → controller)
    wire [7:0] acum_out;    // saída do Acumulador → ALU
    wire [7:0] b_out;       // saída do Reg B → ALU
    wire [7:0] out_data;    // saída do Reg de Saída → LEDs

    wire Cp, Ep;
    wire Lm_n, CE_n, Li_n, Ei_n, La_n;
    wire Ea, Su, Eu;
    wire Lb_n, Lo_n;

    wire [7:0] pc_bus_out;    // PC → W bus (quando Ep=1)
    wire [7:0] ram_bus_out;   // RAM → W bus (quando CE_n=0)
    wire [7:0] ir_bus_out;    // IR → W bus (quando Ei_n=0)
    wire [7:0] acum_bus_out;  // Acum → W bus (quando Ea=1)
    wire [7:0] alu_bus_out;   // ALU → W bus (quando Eu=1)

    // =========================================================================
    // Reset
    // =========================================================================
    assign rst_n = KEY[0];   // KEY[0] em nível baixo = reset

    // =========================================================================
    // Instância 1: Clock Divider
    // Usa o parâmetro MAX_COUNT 
    // =========================================================================
    clock_divider #(
        .MAX_COUNT (MAX_COUNT)   // recebe 25_000_000 (placa)
    ) u_clk_div (
        .clk_50  (MAX10_CLK1_50),
        .rst_n   (rst_n),
        .clk_out (clk_slow)
    );

    // =========================================================================
    // Instância 2: Program Counter
    // =========================================================================
    program_counter u_pc (
        .clk     (clk_slow),
        .rst_n   (rst_n),
        .Cp      (Cp),
        .Ep      (Ep),
        .pc_out  (pc_out),
        .bus_out (pc_bus_out)
    );

    // =========================================================================
    // Instância 3: MAR
    // =========================================================================
    mar u_mar (
        .clk      (clk_slow),
        .rst_n    (rst_n),
        .Lm_n     (Lm_n),
        .bus_in   (w_bus),
        .mar_addr (mar_addr)
    );

    // =========================================================================
    // Instância 4: RAM 16x8
    // =========================================================================
    ram_16x8 u_ram (
        .CE_n    (CE_n),
        .addr    (mar_addr),
        .bus_out (ram_bus_out)
    );

    // =========================================================================
    // Instância 5: Instruction Register
    // =========================================================================
    instruction_register u_ir (
        .clk     (clk_slow),
        .rst_n   (rst_n),
        .Li_n    (Li_n),
        .Ei_n    (Ei_n),
        .bus_in  (w_bus),
        .opcode  (opcode),
        .bus_out (ir_bus_out)
    );

    // =========================================================================
    // Instância 6: Acumulador A
    // =========================================================================
    accumulator u_acum (
        .clk      (clk_slow),
        .rst_n    (rst_n),
        .La_n     (La_n),
        .Ea       (Ea),
        .bus_in   (w_bus),
        .acum_out (acum_out),
        .bus_out  (acum_bus_out)
    );

    // =========================================================================
    // Instância 7: Registrador B
    // =========================================================================
    register_b u_reg_b (
        .clk     (clk_slow),
        .rst_n   (rst_n),
        .Lb_n    (Lb_n),
        .bus_in  (w_bus),
        .b_out   (b_out)
    );

    // =========================================================================
    // Instância 8: ALU
    // =========================================================================
    alu u_alu (
        .a_in    (acum_out),
        .b_in    (b_out),
        .Su      (Su),
        .Eu      (Eu),
        .bus_out (alu_bus_out)
    );

    // =========================================================================
    // Instância 9: Registrador de Saída
    // =========================================================================
    output_register u_out_reg (
        .clk      (clk_slow),
        .rst_n    (rst_n),
        .Lo_n     (Lo_n),
        .bus_in   (w_bus),
        .out_data (out_data)
    );

    // =========================================================================
    // Instância 10: Controller / Sequencer
    // =========================================================================
    controller_sequencer u_ctrl (
        .clk     (clk_slow),
        .rst_n   (rst_n),
        .opcode  (opcode),
        .Cp      (Cp),
        .Ep      (Ep),
        .Lm_n    (Lm_n),
        .CE_n    (CE_n),
        .Li_n    (Li_n),
        .Ei_n    (Ei_n),
        .La_n    (La_n),
        .Ea      (Ea),
        .Su      (Su),
        .Eu      (Eu),
        .Lb_n    (Lb_n),
        .Lo_n    (Lo_n),
        .hlt     (hlt)
    );

    // =========================================================================
    // ÁRBITRO DO BARRAMENTO W — MUX prioritário
    // =========================================================================
    assign w_bus = Ep      ? pc_bus_out   :
                   (!CE_n) ? ram_bus_out  :
                   (!Ei_n) ? ir_bus_out   :
                   Ea      ? acum_bus_out :
                   Eu      ? alu_bus_out  :
                             8'h00;

    // =========================================================================
    // Mapeamento para os LEDs da DE10-Lite
    // =========================================================================
    assign LEDR[7:0] = out_data;   // resultado binário (28+14-10 = 32 = 0010_0000)
    assign LEDR[8]   = hlt;        // acende quando HLT é executado
    assign LEDR[9]   = clk_slow;   // heartbeat: pisca em ~1 Hz na placa

endmodule