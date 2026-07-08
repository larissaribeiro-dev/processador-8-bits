// =============================================================================
// Arquivo    : tb_processador_8_bits_corrigido.v
// Projeto    : SAP-1 — Processador 8 bits
// Descrição  : Testbench Global
// =============================================================================

`timescale 1ns / 1ps

module tb_processador_8_bits;

    // -------------------------------------------------------------------------
    // Sinais de estímulo (Entradas do Top)
    // -------------------------------------------------------------------------
    reg        MAX10_CLK1_50;
    reg  [1:0] KEY;

    // -------------------------------------------------------------------------
    // Sinais de observação (Saídas do Top)
    // -------------------------------------------------------------------------
    wire [9:0] LEDR;

    // -------------------------------------------------------------------------
    // Parâmetros de Simulação
    //
    //   MAX_COUNT_SIM = 2:
    //     → clock do processador = 2 × 2 × 20ns = 80 ns por ciclo
    //     → programa completo (28 ciclos) = ~2.240 ns de simulação
    //
    //   TIMEOUT_NS = 2 × 20 × 10.000 = 400.000 ns
    //     → margem de ~178× o tempo necessário. Seguro.
    //     → se o HLT não aparecer em 400 µs simulados, há um bug real.
    // -------------------------------------------------------------------------
    localparam MAX_COUNT_SIM = 2;
    localparam TIMEOUT_NS    = MAX_COUNT_SIM * 20 * 10_000; // BUG 2 CORRIGIDO

    initial MAX10_CLK1_50 = 1'b0;
    always  #10 MAX10_CLK1_50 = ~MAX10_CLK1_50;

    processador_8_bits_top #(
        .MAX_COUNT (MAX_COUNT_SIM)
    ) uut (
        .MAX10_CLK1_50 (MAX10_CLK1_50),
        .KEY           (KEY),
        .LEDR          (LEDR)
    );

    // -------------------------------------------------------------------------
    // Procedimento de Teste Principal
    // -------------------------------------------------------------------------
    initial begin
        // 1. Inicialização
        $display("==================================================");
        $display("   TESTBENCH GLOBAL — SAP-1 Processador 8 bits   ");
        $display("   MAX_COUNT_SIM = %0d  |  TIMEOUT = %0d ns      ", MAX_COUNT_SIM, TIMEOUT_NS);
        $display("   Periodo do clk_proc = %0d ns por ciclo        ", MAX_COUNT_SIM * 2 * 20);
        $display("==================================================");

        KEY = 2'b11; // Botões soltos (ativos em baixo)

        // 2. Aplica Reset (pressiona KEY[0] por 40 ns)
        $display("[%0t ns] Aplicando Reset (KEY[0]=0)...", $time);
        #40;
        KEY[0] = 1'b0;
        #40;
        KEY[0] = 1'b1;
        $display("[%0t ns] Reset liberado — processador em execucao!", $time);

        // 3. Monitor de debug: imprime toda vez que qualquer sinal muda
        $monitor("[%0t ns] PC=%0d | ACUM=%0d (0x%h = %b) | BUS=0x%h | HLT=%b",
                 $time,
                 uut.u_pc.pc_out,
                 uut.u_acum.acum_out,
                 uut.u_acum.acum_out,
                 uut.u_acum.acum_out,
                 uut.w_bus,
                 LEDR[8]);

        // 4. Aguarda HLT com timeout de segurança
        fork
            begin : bloco_hlt
                wait (LEDR[8] == 1'b1);
                disable bloco_timeout;
            end
            begin : bloco_timeout
                #(TIMEOUT_NS);
                $display("\n==================================================");
                $display(" >> ERRO FATAL: TIMEOUT após %0d ns!", TIMEOUT_NS);
                $display(" >> HLT nao detectado — verifique:");
                $display("    1. Se MAX_COUNT esta sendo passado ao top-level");
                $display("    2. Se a RAM tem o programa correto carregado");
                $display("    3. O historico do $monitor acima para o ultimo estado");
                $display("==================================================\n");
                disable bloco_hlt;
                $stop;
            end
        join

        // BUG 4 CORRIGIDO: apenas um $monitoroff, sem disable fork duplicado
        $monitoroff;

        // 5. Aguarda estabilização final
        #200;

        // 6. Verificação do resultado
        $display("\n==================================================");
        $display("   EXECUCAO FINALIZADA — HLT detectado           ");
        $display("==================================================");
        $display("   LEDR[9]   (HLT)         = %b", LEDR[9]);
        $display("   LEDR[8]   (HLT via ctrl) = %b", LEDR[8]);
        $display("   LEDR[7:0] (resultado)    = %b = %0d decimal", LEDR[7:0], LEDR[7:0]);
        $display("   Esperado: 28+14-10 = 32 = 00100000b");

        if (LEDR[7:0] == 8'd32) begin
            $display("\n>> STATUS: *** SUCESSO ABSOLUTO! ***");
            $display("   28 + 14 - 10 = 32 confirmado nos LEDs.");
        end else begin
            $display("\n>> STATUS: *** FALHA! ***");
            $display("   Esperado: 32 (0x20) | Obtido: %0d (0x%h)", LEDR[7:0], LEDR[7:0]);
            $display("   Verifique o conteudo da RAM e os opcodes.");
        end
        $display("==================================================\n");

        $finish;
    end

    // -------------------------------------------------------------------------
    // Dump de formas de onda
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_processador_8_bits.vcd");
        $dumpvars(0, tb_processador_8_bits);
    end

endmodule