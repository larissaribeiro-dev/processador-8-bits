// =============================================================================
// Arquivo    : tb_clock_divider.v
// Projeto    : SAP-1 — Processador 8 bits
// Descrição  : Testbench UNITÁRIO do Clock Divider.
//
// O que este testbench valida:
//   1. Reset assíncrono: clk_out permanece em 0 enquanto rst_n = 0
//   2. Contagem correta: clk_out inverte após MAX_COUNT ciclos
//   3. Frequência: com MAX_COUNT = 5 (simulação), período = 10 ciclos de clk_50
//
// IMPORTANTE:
//   Na simulação usamos MAX_COUNT = 5 (parâmetro reduzido) para não esperar
//   25 milhões de ciclos. O comportamento lógico é idêntico ao hardware real.
//
// Como rodar no ModelSim:
//   vsim -G MAX_COUNT=5 tb_clock_divider
// =============================================================================

`timescale 1ns / 1ps

module tb_clock_divider;

    // -------------------------------------------------------------------------
    // Sinais de teste
    // -------------------------------------------------------------------------
    reg  clk_50;
    reg  rst_n;
    wire clk_out;

    // -------------------------------------------------------------------------
    // Instância do módulo sob teste
    // MAX_COUNT = 5 para simulação rápida (comportamento idêntico ao real)
    // -------------------------------------------------------------------------
    clock_divider #(
        .MAX_COUNT(5)
    ) uut (
        .clk_50  (clk_50),
        .rst_n   (rst_n),
        .clk_out (clk_out)
    );

    // -------------------------------------------------------------------------
    // Gerador de clock de 50 MHz → período = 20 ns
    // -------------------------------------------------------------------------
    initial clk_50 = 0;
    always #10 clk_50 = ~clk_50;

    // -------------------------------------------------------------------------
    // Variáveis para verificação automática
    // -------------------------------------------------------------------------
    integer erros = 0;
    integer i;
    time t_borda_anterior;
    time t_periodo;

    // -------------------------------------------------------------------------
    // Sequência de estímulos
    // -------------------------------------------------------------------------
    initial begin
        $display("============================================================");
        $display("  TESTBENCH: Clock Divider (MAX_COUNT = 5)");
        $display("  Clock de entrada: 50 MHz  (periodo = 20 ns)");
        $display("  Inversao esperada: a cada 5 ciclos = 100 ns");
        $display("  Periodo clk_out esperado: 200 ns (5 Hz simulados)");
        $display("============================================================");

        // --- Teste 1: Reset ---
        rst_n = 0;
        repeat(4) @(posedge clk_50);

        if (clk_out !== 1'b0) begin
            $display("[FALHA] T1: clk_out deve ser 0 durante reset. Obtido: %b", clk_out);
            erros = erros + 1;
        end else begin
            $display("[OK]    T1: Reset manteve clk_out = 0");
        end

        // --- Libera o reset ---
        @(negedge clk_50);
        rst_n = 1;
        $display("[INFO]  Reset liberado em t = %0t ns", $time);

        // --- Teste 2: Aguarda primeira inversão de clk_out ---
        @(posedge clk_out);
        t_borda_anterior = $time;
        $display("[OK]    T2: Primeira borda de subida de clk_out em t = %0t ns", t_borda_anterior);

        // --- Teste 3: Mede o período do clk_out ---
        @(posedge clk_out);
        t_periodo = $time - t_borda_anterior;
        $display("[INFO]  Periodo medido de clk_out: %0t ns", t_periodo);

        // Com MAX_COUNT=5 e clk_50 de 20 ns: período = 2 * 5 * 20 = 200 ns
        if (t_periodo == 200) begin
            $display("[OK]    T3: Periodo correto (200 ns para MAX_COUNT=5)");
        end else begin
            $display("[FALHA] T3: Periodo incorreto. Esperado: 200 ns | Obtido: %0t ns", t_periodo);
            erros = erros + 1;
        end

        // --- Teste 4: Mais algumas inversões para confirmar estabilidade ---
        repeat(3) @(posedge clk_out);
        $display("[OK]    T4: Mais 3 inversoes ocorreram corretamente");

        // --- Teste 5: Reset no meio da operação ---
        rst_n = 0;
        @(posedge clk_50);
        if (clk_out !== 1'b0) begin
            $display("[FALHA] T5: clk_out deve voltar a 0 com reset ativo. Obtido: %b", clk_out);
            erros = erros + 1;
        end else begin
            $display("[OK]    T5: Reset no meio da operacao -> clk_out = 0 imediatamente");
        end
        rst_n = 1;

        // --- Resultado Final ---
        #50;
        $display("============================================================");
        if (erros == 0)
            $display("  RESULTADO: SUCESSO — Todos os testes passaram!");
        else
            $display("  RESULTADO: FALHA — %0d erro(s) encontrado(s)!", erros);
        $display("============================================================");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Monitor de eventos (log de todas as mudanças em clk_out)
    // -------------------------------------------------------------------------
    initial begin
        $monitor("[MONITOR] t=%0t ns | rst_n=%b | clk_out=%b", $time, rst_n, clk_out);
    end

    // -------------------------------------------------------------------------
    // Dump de formas de onda para o ModelSim
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_clock_divider.vcd");
        $dumpvars(0, tb_clock_divider);
    end

endmodule
