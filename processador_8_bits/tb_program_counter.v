// =============================================================================
// Arquivo    : tb_program_counter.v
// Projeto    : SAP-1 — Processador 8 bits
// Descrição  : Testbench UNITÁRIO do Program Counter.
//
// O que este testbench valida:
//   1. Reset assíncrono: pc_out = 0 e bus_out = 0
//   2. Sem Cp nem Ep: PC não muda, barramento = 0
//   3. Cp=1: PC incrementa em cada borda de subida do clock
//   4. Ep=1: PC aparece no barramento (bits [3:0] do bus_out)
//   5. Cp=0, Ep=0: PC mantém valor (não incrementa, não sai no bus)
//   6. Overflow: PC vai de 4'hF para 4'h0 (conta circular)
//   7. Reset no meio da contagem
// =============================================================================

`timescale 1ns / 1ps

module tb_program_counter;

    // -------------------------------------------------------------------------
    // Sinais de teste
    // -------------------------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg        Cp;
    reg        Ep;
    wire [3:0] pc_out;
    wire [7:0] bus_out;

    // -------------------------------------------------------------------------
    // Instância do módulo sob teste
    // -------------------------------------------------------------------------
    program_counter uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .Cp      (Cp),
        .Ep      (Ep),
        .pc_out  (pc_out),
        .bus_out (bus_out)
    );

    // -------------------------------------------------------------------------
    // Clock: período = 100 ns (10 MHz simulado — fácil de ler no waveform)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #50 clk = ~clk;

    // -------------------------------------------------------------------------
    // Tarefa auxiliar: aplica 1 ciclo de clock e verifica valores
    // -------------------------------------------------------------------------
    integer erros = 0;

    task clock_cycle;
        begin
            @(posedge clk);
            #1; // pequeno atraso após borda para leitura estável
        end
    endtask

    task check;
        input [3:0] pc_esperado;
        input [7:0] bus_esperado;
        input [63:0] teste_num;
        begin
            if (pc_out !== pc_esperado) begin
                $display("[FALHA] T%0d: pc_out  esperado=%0d obtido=%0d  (t=%0t ns)",
                         teste_num, pc_esperado, pc_out, $time);
                erros = erros + 1;
            end
            if (bus_out !== bus_esperado) begin
                $display("[FALHA] T%0d: bus_out esperado=%08b obtido=%08b  (t=%0t ns)",
                         teste_num, bus_esperado, bus_out, $time);
                erros = erros + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Sequência de estímulos
    // -------------------------------------------------------------------------
    initial begin
        $display("============================================================");
        $display("  TESTBENCH: Program Counter");
        $display("============================================================");

        // Inicialização
        rst_n = 0; Cp = 0; Ep = 0;

        // ---- Teste 1: Reset assíncrono ----
        #30;
        check(4'd0, 8'h00, 1);
        $display("[OK]    T1: Reset -> pc_out=0, bus_out=0x00");

        // ---- Libera reset ----
        rst_n = 1;
        #10;

        // ---- Teste 2: Cp=0 Ep=0 — PC não muda, bus=0 ----
        Cp = 0; Ep = 0;
        clock_cycle;
        check(4'd0, 8'h00, 2);
        $display("[OK]    T2: Cp=0,Ep=0 -> PC permanece 0, bus=0x00");

        // ---- Teste 3: Ep=1 — PC aparece no barramento ----
        Ep = 1;
        #1;
        if (bus_out !== 8'h00) begin
            $display("[FALHA] T3: Ep=1 -> bus_out deveria ser 0x00. Obtido: %08b", bus_out);
            erros = erros + 1;
        end else begin
            $display("[OK]    T3: Ep=1 -> PC=0 aparece no barramento: 0x%02X", bus_out);
        end
        Ep = 0;

        // ---- Teste 4: Cp=1 — PC incrementa ----
        Cp = 1;
        clock_cycle; check(4'd1, 8'h00, 4);
        $display("[OK]    T4a: Cp=1 -> PC=1");
        clock_cycle; check(4'd2, 8'h00, 4);
        $display("[OK]    T4b: Cp=1 -> PC=2");
        clock_cycle; check(4'd3, 8'h00, 4);
        $display("[OK]    T4c: Cp=1 -> PC=3");

        // ---- Teste 5: Cp=1 e Ep=1 — PC incrementa E aparece no bus ----
        Ep = 1;
        clock_cycle;  // PC deve ir para 4
        if (pc_out !== 4'd4 || bus_out !== 8'h04) begin
            $display("[FALHA] T5: Cp=1,Ep=1 -> esperado pc=4,bus=0x04. Obtido pc=%0d,bus=0x%02X",
                     pc_out, bus_out);
            erros = erros + 1;
        end else begin
            $display("[OK]    T5: Cp=1,Ep=1 -> PC=4 e bus_out=0x04 simultaneamente");
        end
        Ep = 0;

        // ---- Teste 6: Cp=0 — PC congela ----
        Cp = 0;
        clock_cycle; check(4'd4, 8'h00, 6);
        clock_cycle; check(4'd4, 8'h00, 6);
        $display("[OK]    T6: Cp=0 -> PC congelado em 4");

        // ---- Avança até o overflow (PC=15→0) ----
        Cp = 1;
        // PC está em 4, precisamos de mais 11 incrementos para chegar em 15
        repeat(11) clock_cycle;
        check(4'd15, 8'h00, 7);
        $display("[OK]    T7: PC chegou em 15 (4'hF)");

        // ---- Teste 8: Overflow — 15 → 0 ----
        clock_cycle;
        check(4'd0, 8'h00, 8);
        $display("[OK]    T8: Overflow: PC voltou para 0 (4'hF + 1 = 0)");

        // ---- Teste 9: Reset assíncrono no meio da contagem ----
        Cp = 1;
        repeat(5) clock_cycle; // PC agora está em 5
        rst_n = 0;
        #5;
        if (pc_out !== 4'd0) begin
            $display("[FALHA] T9: Reset assincrono -> pc_out deveria ser 0. Obtido: %0d", pc_out);
            erros = erros + 1;
        end else begin
            $display("[OK]    T9: Reset assincrono no meio da contagem -> PC=0 imediatamente");
        end
        rst_n = 1;

        // ---- Resultado Final ----
        #100;
        $display("============================================================");
        if (erros == 0)
            $display("  RESULTADO: SUCESSO — Todos os testes passaram!");
        else
            $display("  RESULTADO: FALHA — %0d erro(s) encontrado(s)!", erros);
        $display("============================================================");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Dump de formas de onda
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_program_counter.vcd");
        $dumpvars(0, tb_program_counter);
    end

endmodule
