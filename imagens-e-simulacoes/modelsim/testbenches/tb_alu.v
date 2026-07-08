// =============================================================================
// Arquivo    : tb_alu.v
// Projeto    : SAP-1 — Processador 8 bits
// Descrição  : Testbench UNITÁRIO da ALU (Somador/Subtrator).
//
// O que este testbench valida:
//   1. Adição básica   (Su=0): resultado correto de A + B
//   2. Subtração       (Su=1): resultado correto de A - B (complemento de 2)
//   3. Isolamento do barramento (Eu=0): bus_out deve ser 0x00
//   4. Enable do barramento    (Eu=1): bus_out reflete o resultado
//   5. Casos do programa real: 28+14=42, 42-10=32
//   6. Subtração com resultado negativo (complemento de 2)
//   7. Overflow e valores-limite (0xFF, 0x00)
// =============================================================================

`timescale 1ns / 1ps

module tb_alu;

    // -------------------------------------------------------------------------
    // Sinais de teste
    // -------------------------------------------------------------------------
    reg  [7:0] a_in;
    reg  [7:0] b_in;
    reg        Su;
    reg        Eu;
    wire [7:0] bus_out;

    // -------------------------------------------------------------------------
    // Instância do módulo sob teste
    // -------------------------------------------------------------------------
    alu uut (
        .a_in   (a_in),
        .b_in   (b_in),
        .Su     (Su),
        .Eu     (Eu),
        .bus_out(bus_out)
    );

    // -------------------------------------------------------------------------
    // Variável de erro e tarefa de verificação
    // -------------------------------------------------------------------------
    integer erros = 0;
    integer teste;

    task verifica;
        input [7:0] a;
        input [7:0] b;
        input       su_val;
        input       eu_val;
        input [7:0] esperado;
        input [7:0] t;
        reg   [7:0] calc;
        begin
            a_in = a; b_in = b; Su = su_val; Eu = eu_val;
            #5; // aguarda propagação combinacional
            calc = su_val ? (a - b) : (a + b);

            if (Eu == 0) begin
                // Com Eu=0, barramento deve ser 0x00
                if (bus_out !== 8'h00) begin
                    $display("[FALHA] T%0d: Eu=0 -> bus_out deveria ser 0x00. Obtido: 0x%02X", t, bus_out);
                    erros = erros + 1;
                end else begin
                    $display("[OK]    T%0d: Eu=0 -> barramento isolado (bus_out=0x00). Resultado interno: %0d",
                             t, calc);
                end
            end else begin
                // Com Eu=1, barramento deve mostrar o resultado
                if (bus_out !== esperado) begin
                    $display("[FALHA] T%0d: %0d %s %0d -> esperado=0x%02X(%0d) obtido=0x%02X(%0d)",
                             t, a, (su_val ? "-" : "+"), b, esperado, esperado, bus_out, bus_out);
                    erros = erros + 1;
                end else begin
                    $display("[OK]    T%0d: %3d %s %3d = %3d (0x%02X) | bus_out=0x%02X",
                             t, a, (su_val ? "-" : "+"), b, esperado, esperado, bus_out);
                end
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Sequência de estímulos
    // -------------------------------------------------------------------------
    initial begin
        $display("============================================================");
        $display("  TESTBENCH: ALU (Somador/Subtrator 8 bits)");
        $display("  ALU opera de forma ASSINCRONA — sem clock");
        $display("============================================================");

        // --- Bloco 1: Isolamento do barramento (Eu=0) ---
        $display("\n--- Bloco 1: Isolamento do barramento (Eu=0) ---");
        verifica(8'd28, 8'd14, 0, 0, 8'h00, 1);  // soma, barramento isolado
        verifica(8'd28, 8'd14, 1, 0, 8'h00, 2);  // sub, barramento isolado

        // --- Bloco 2: Adição (Su=0, Eu=1) ---
        $display("\n--- Bloco 2: Adicao (Su=0, Eu=1) ---");
        verifica(8'd0,  8'd0,  0, 1, 8'd0,  3);  // 0 + 0 = 0
        verifica(8'd5,  8'd3,  0, 1, 8'd8,  4);  // 5 + 3 = 8
        verifica(8'd28, 8'd14, 0, 1, 8'd42, 5);  // PROGRAMA REAL: 28 + 14 = 42
        verifica(8'd100,8'd55, 0, 1, 8'd155,6);  // 100 + 55 = 155
        verifica(8'd255,8'd1,  0, 1, 8'd0,  7);  // overflow: 255 + 1 = 0 (8 bits)

        // --- Bloco 3: Subtração (Su=1, Eu=1) ---
        $display("\n--- Bloco 3: Subtracao via complemento de 2 (Su=1, Eu=1) ---");
        verifica(8'd10, 8'd10, 1, 1, 8'd0,  8);  // 10 - 10 = 0
        verifica(8'd42, 8'd10, 1, 1, 8'd32, 9);  // PROGRAMA REAL: 42 - 10 = 32
        verifica(8'd50, 8'd20, 1, 1, 8'd30, 10); // 50 - 20 = 30
        verifica(8'd5,  8'd3,  1, 1, 8'd2,  11); // 5 - 3 = 2

        // Subtração negativa: 3 - 5 = -2 = 0xFE em complemento de 2
        verifica(8'd3,  8'd5,  1, 1, 8'hFE, 12);
        $display("          (resultado negativo: 3-5 = -2 = 0xFE em complemento de 2)");

        // --- Bloco 4: Teste do programa completo ---
        $display("\n--- Bloco 4: Simulacao do programa SAP-1 ---");
        $display("    LDA 13: carrega 28 no acumulador A");
        $display("    ADD 14: A = 28 + 14 = ?");
        verifica(8'd28, 8'd14, 0, 1, 8'd42, 13);
        $display("    SUB 15: A = 42 - 10 = ?");
        verifica(8'd42, 8'd10, 1, 1, 8'd32, 14);
        $display("    Resultado final esperado nos LEDs: 32 = 0x20 = 0010_0000");

        if (bus_out == 8'd32)
            $display("[OK]    T14: RESULTADO CORRETO! bus_out = 32 (0x20) = 0010_0000b");

        // --- Resultado Final ---
        #10;
        $display("\n============================================================");
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
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);
    end

endmodule
