// =============================================================================
// Arquivo    : tb_registradores.v
// Projeto    : SAP-1 — Processador 8 bits
// Descrição  : Testbench UNITÁRIO de todos os registradores do SAP-1:
//              - Accumulator (A)
//              - Register B
//              - MAR
//              - Instruction Register (IR)
//              - Output Register
//
// O que este testbench valida para cada registrador:
//   1. Reset assíncrono zera o registrador imediatamente
//   2. Sinal de Load inativo: dado NÃO é capturado
//   3. Sinal de Load ativo:   dado É capturado na borda de subida
//   4. Dados persistem após Load ser desativado
//   5. Saídas para o barramento (Enable/tri-state)
//   6. Separação opcode/operando do IR
// =============================================================================

`timescale 1ns / 1ps

module tb_registradores;

    // -------------------------------------------------------------------------
    // Clock: 100 ns de período
    // -------------------------------------------------------------------------
    reg clk;
    reg rst_n;

    initial clk = 0;
    always #50 clk = ~clk;

    // =========================================================================
    // Sinais para cada módulo
    // =========================================================================

    // -- Accumulator --
    reg        acc_La_n, acc_Ea;
    reg  [7:0] acc_bus_in;
    wire [7:0] acc_acum_out, acc_bus_out;

    // -- Register B --
    reg        regb_Lb_n;
    reg  [7:0] regb_bus_in;
    wire [7:0] regb_b_out;

    // -- MAR --
    reg        mar_Lm_n;
    reg  [7:0] mar_bus_in;
    wire [3:0] mar_addr;

    // -- Instruction Register --
    reg        ir_Li_n, ir_Ei_n;
    reg  [7:0] ir_bus_in;
    wire [3:0] ir_opcode;
    wire [7:0] ir_bus_out;

    // -- Output Register --
    reg        out_Lo_n;
    reg  [7:0] out_bus_in;
    wire [7:0] out_data;

    // =========================================================================
    // Instâncias dos módulos
    // =========================================================================

    accumulator U_ACC (
        .clk     (clk),
        .rst_n   (rst_n),
        .La_n    (acc_La_n),
        .Ea      (acc_Ea),
        .bus_in  (acc_bus_in),
        .acum_out(acc_acum_out),
        .bus_out (acc_bus_out)
    );

    register_b U_REGB (
        .clk    (clk),
        .rst_n  (rst_n),
        .Lb_n   (regb_Lb_n),
        .bus_in (regb_bus_in),
        .b_out  (regb_b_out)
    );

    mar U_MAR (
        .clk     (clk),
        .rst_n   (rst_n),
        .Lm_n    (mar_Lm_n),
        .bus_in  (mar_bus_in),
        .mar_addr(mar_addr)
    );

    instruction_register U_IR (
        .clk    (clk),
        .rst_n  (rst_n),
        .Li_n   (ir_Li_n),
        .Ei_n   (ir_Ei_n),
        .bus_in (ir_bus_in),
        .opcode (ir_opcode),
        .bus_out(ir_bus_out)
    );

    output_register U_OUT (
        .clk     (clk),
        .rst_n   (rst_n),
        .Lo_n    (out_Lo_n),
        .bus_in  (out_bus_in),
        .out_data(out_data)
    );

    // =========================================================================
    // Infraestrutura de verificação
    // =========================================================================
    integer erros = 0;

    task clock_cycle;
        begin
            @(posedge clk);
            #2;
        end
    endtask

    task falha;
        input [127:0] msg;
        begin
            $display("[FALHA] %s", msg);
            erros = erros + 1;
        end
    endtask

    // =========================================================================
    // TESTE DO ACCUMULATOR
    // =========================================================================
    task teste_accumulator;
        begin
            $display("\n========================================");
            $display("  ACCUMULATOR (Registrador A)");
            $display("========================================");

            acc_La_n = 1; acc_Ea = 0; acc_bus_in = 8'h00;

            // T1: Reset
            rst_n = 0; #30;
            if (acc_acum_out !== 8'h00 || acc_bus_out !== 8'h00) begin
                $display("[FALHA] ACC-T1: Reset -> acum_out=0x%02X bus_out=0x%02X", acc_acum_out, acc_bus_out);
                erros = erros + 1;
            end else $display("[OK]    ACC-T1: Reset -> acum_out=0x00, bus_out=0x00");
            rst_n = 1;

            // T2: La_n=1 (inativo) — dado NÃO deve ser capturado
            acc_La_n = 1; acc_bus_in = 8'hAB;
            clock_cycle;
            if (acc_acum_out !== 8'h00) begin
                $display("[FALHA] ACC-T2: La_n=1 -> acum_out deveria ser 0x00. Obtido: 0x%02X", acc_acum_out);
                erros = erros + 1;
            end else $display("[OK]    ACC-T2: La_n=1 (inativo) -> dado 0xAB NAO capturado, acum_out=0x00");

            // T3: La_n=0 (ativo) — captura 0x1C (28 decimal)
            acc_La_n = 0; acc_bus_in = 8'd28;
            clock_cycle;
            if (acc_acum_out !== 8'd28) begin
                $display("[FALHA] ACC-T3: La_n=0 -> acum_out deveria ser 28. Obtido: %0d", acc_acum_out);
                erros = erros + 1;
            end else $display("[OK]    ACC-T3: La_n=0 (ativo) -> capturou 28 (0x1C)");

            // T4: La_n=1 — dado persiste
            acc_La_n = 1; acc_bus_in = 8'hFF;
            clock_cycle;
            if (acc_acum_out !== 8'd28) begin
                $display("[FALHA] ACC-T4: La_n=1 -> acum_out deveria persistir em 28. Obtido: %0d", acc_acum_out);
                erros = erros + 1;
            end else $display("[OK]    ACC-T4: La_n=1 -> dado persiste em 28 (0xFF nao capturado)");

            // T5: Ea=1 — aparece no barramento
            acc_Ea = 1; #2;
            if (acc_bus_out !== 8'd28) begin
                $display("[FALHA] ACC-T5: Ea=1 -> bus_out deveria ser 28. Obtido: 0x%02X", acc_bus_out);
                erros = erros + 1;
            end else $display("[OK]    ACC-T5: Ea=1 -> 28 aparece no barramento (bus_out=0x1C)");

            // T6: Ea=0 — barramento isolado
            acc_Ea = 0; #2;
            if (acc_bus_out !== 8'h00) begin
                $display("[FALHA] ACC-T6: Ea=0 -> bus_out deveria ser 0x00. Obtido: 0x%02X", acc_bus_out);
                erros = erros + 1;
            end else $display("[OK]    ACC-T6: Ea=0 -> barramento isolado (bus_out=0x00), acum_out=28 continua");

            // T7: Saída para ALU é sempre ativa (independente de Ea)
            if (acc_acum_out !== 8'd28) begin
                $display("[FALHA] ACC-T7: acum_out (para ALU) deveria ser 28 mesmo com Ea=0. Obtido: %0d", acc_acum_out);
                erros = erros + 1;
            end else $display("[OK]    ACC-T7: acum_out=28 sempre disponivel para a ALU (independente de Ea)");
        end
    endtask

    // =========================================================================
    // TESTE DO REGISTER B
    // =========================================================================
    task teste_register_b;
        begin
            $display("\n========================================");
            $display("  REGISTER B");
            $display("========================================");

            regb_Lb_n = 1; regb_bus_in = 8'h00;

            // T1: Reset
            rst_n = 0; #30;
            if (regb_b_out !== 8'h00) begin
                $display("[FALHA] REGB-T1: Reset -> b_out=0x%02X (esperado 0x00)", regb_b_out);
                erros = erros + 1;
            end else $display("[OK]    REGB-T1: Reset -> b_out=0x00");
            rst_n = 1;

            // T2: Lb_n=1 — não captura
            regb_Lb_n = 1; regb_bus_in = 8'hCC;
            clock_cycle;
            if (regb_b_out !== 8'h00) begin
                $display("[FALHA] REGB-T2: Lb_n=1 -> b_out deveria ser 0x00. Obtido: 0x%02X", regb_b_out);
                erros = erros + 1;
            end else $display("[OK]    REGB-T2: Lb_n=1 (inativo) -> dado 0xCC NAO capturado");

            // T3: Lb_n=0 — captura 14 decimal
            regb_Lb_n = 0; regb_bus_in = 8'd14;
            clock_cycle;
            if (regb_b_out !== 8'd14) begin
                $display("[FALHA] REGB-T3: Lb_n=0 -> b_out deveria ser 14. Obtido: %0d", regb_b_out);
                erros = erros + 1;
            end else $display("[OK]    REGB-T3: Lb_n=0 -> capturou 14 (0x0E)");

            // T4: dado persiste, e não tem saída para barramento
            regb_Lb_n = 1; regb_bus_in = 8'hFF;
            clock_cycle;
            if (regb_b_out !== 8'd14) begin
                $display("[FALHA] REGB-T4: Persitencia falhou. Obtido: %0d", regb_b_out);
                erros = erros + 1;
            end else $display("[OK]    REGB-T4: Dado persiste em 14. Reg B nao tem saida para barramento.");
        end
    endtask

    // =========================================================================
    // TESTE DO MAR
    // =========================================================================
    task teste_mar;
        begin
            $display("\n========================================");
            $display("  MAR (Memory Address Register)");
            $display("========================================");

            mar_Lm_n = 1; mar_bus_in = 8'h00;

            // T1: Reset
            rst_n = 0; #30;
            if (mar_addr !== 4'h0) begin
                $display("[FALHA] MAR-T1: Reset -> mar_addr=0x%X (esperado 0x0)", mar_addr);
                erros = erros + 1;
            end else $display("[OK]    MAR-T1: Reset -> mar_addr=0x0");
            rst_n = 1;

            // T2: Lm_n=1 — não captura
            mar_Lm_n = 1; mar_bus_in = 8'hFF;
            clock_cycle;
            if (mar_addr !== 4'h0) begin
                $display("[FALHA] MAR-T2: Lm_n=1 -> mar_addr deveria ser 0. Obtido: %0d", mar_addr);
                erros = erros + 1;
            end else $display("[OK]    MAR-T2: Lm_n=1 (inativo) -> endereco nao foi alterado");

            // T3: Lm_n=0 — captura endereço 0xD (13 decimal, do programa real)
            mar_Lm_n = 0; mar_bus_in = 8'h0D;  // só bits [3:0] importam
            clock_cycle;
            if (mar_addr !== 4'hD) begin
                $display("[FALHA] MAR-T3: Lm_n=0 -> mar_addr deveria ser 0xD. Obtido: 0x%X", mar_addr);
                erros = erros + 1;
            end else $display("[OK]    MAR-T3: Lm_n=0 -> capturou endereco 0xD (13)");

            // T4: apenas bits [3:0] do barramento são usados
            mar_Lm_n = 0; mar_bus_in = 8'hAE;  // bits [3:0] = 0xE = 14
            clock_cycle;
            if (mar_addr !== 4'hE) begin
                $display("[FALHA] MAR-T4: MAR deveria capturar apenas bits[3:0]. Obtido: 0x%X", mar_addr);
                erros = erros + 1;
            end else $display("[OK]    MAR-T4: Apenas bits[3:0] capturados: bus=0xAE -> mar=0xE");

            // T5: persiste após Lm_n=1
            mar_Lm_n = 1;
            clock_cycle;
            if (mar_addr !== 4'hE) begin
                $display("[FALHA] MAR-T5: Persistencia falhou. Obtido: 0x%X", mar_addr);
                erros = erros + 1;
            end else $display("[OK]    MAR-T5: Endereco 0xE persiste com Lm_n=1");
        end
    endtask

    // =========================================================================
    // TESTE DO INSTRUCTION REGISTER
    // =========================================================================
    task teste_ir;
        begin
            $display("\n========================================");
            $display("  INSTRUCTION REGISTER (IR)");
            $display("========================================");

            ir_Li_n = 1; ir_Ei_n = 1; ir_bus_in = 8'h00;

            // T1: Reset
            rst_n = 0; #30;
            if (ir_opcode !== 4'h0 || ir_bus_out !== 8'h00) begin
                $display("[FALHA] IR-T1: Reset -> opcode=0x%X bus_out=0x%02X", ir_opcode, ir_bus_out);
                erros = erros + 1;
            end else $display("[OK]    IR-T1: Reset -> opcode=0x0, bus_out=0x00");
            rst_n = 1;

            // T2: Li_n=1 — não captura instrução LDA 13 (0x0D)
            ir_Li_n = 1; ir_bus_in = 8'b0000_1101; // LDA 13
            clock_cycle;
            if (ir_opcode !== 4'h0) begin
                $display("[FALHA] IR-T2: Li_n=1 -> opcode deveria ser 0. Obtido: 0x%X", ir_opcode);
                erros = erros + 1;
            end else $display("[OK]    IR-T2: Li_n=1 (inativo) -> instrucao LDA nao capturada");

            // T3: Li_n=0 — captura instrução LDA 13
            ir_Li_n = 0; ir_bus_in = 8'b0000_1101; // LDA=0000, operando=1101=13
            clock_cycle;
            if (ir_opcode !== 4'b0000) begin
                $display("[FALHA] IR-T3: opcode esperado LDA(0000). Obtido: %b", ir_opcode);
                erros = erros + 1;
            end else $display("[OK]    IR-T3: Li_n=0 -> capturou LDA (opcode=0000)");

            // T4: Ei_n=0 — operando aparece no barramento
            ir_Li_n = 1; ir_Ei_n = 0; #2;
            if (ir_bus_out !== 8'h0D) begin
                $display("[FALHA] IR-T4: Ei_n=0 -> bus_out deveria ser 0x0D. Obtido: 0x%02X", ir_bus_out);
                erros = erros + 1;
            end else $display("[OK]    IR-T4: Ei_n=0 -> operando 0xD (13) no barramento: bus_out=0x0D");

            // T5: Ei_n=1 — barramento isolado
            ir_Ei_n = 1; #2;
            if (ir_bus_out !== 8'h00) begin
                $display("[FALHA] IR-T5: Ei_n=1 -> bus_out deveria ser 0x00. Obtido: 0x%02X", ir_bus_out);
                erros = erros + 1;
            end else $display("[OK]    IR-T5: Ei_n=1 -> barramento isolado (bus_out=0x00)");

            // T6: instrução ADD 14 (opcode=0001, operando=1110=14)
            ir_Li_n = 0; ir_bus_in = 8'b0001_1110; // ADD 14
            clock_cycle;
            ir_Li_n = 1; ir_Ei_n = 0; #2;
            if (ir_opcode !== 4'b0001 || ir_bus_out !== 8'h0E) begin
                $display("[FALHA] IR-T6: ADD 14 -> opcode=%b bus_out=0x%02X", ir_opcode, ir_bus_out);
                erros = erros + 1;
            end else $display("[OK]    IR-T6: ADD 14 -> opcode=0001(ADD), operando=0xE(14) no barramento");

            // T7: instrução HLT (opcode=1111)
            ir_Ei_n = 1; ir_Li_n = 0; ir_bus_in = 8'b1111_0000; // HLT
            clock_cycle;
            if (ir_opcode !== 4'b1111) begin
                $display("[FALHA] IR-T7: HLT -> opcode esperado 1111. Obtido: %b", ir_opcode);
                erros = erros + 1;
            end else $display("[OK]    IR-T7: HLT -> opcode=1111 reconhecido");
        end
    endtask

    // =========================================================================
    // TESTE DO OUTPUT REGISTER
    // =========================================================================
    task teste_output_register;
        begin
            $display("\n========================================");
            $display("  OUTPUT REGISTER");
            $display("========================================");

            out_Lo_n = 1; out_bus_in = 8'h00;

            // T1: Reset
            rst_n = 0; #30;
            if (out_data !== 8'h00) begin
                $display("[FALHA] OUT-T1: Reset -> out_data=0x%02X (esperado 0x00)", out_data);
                erros = erros + 1;
            end else $display("[OK]    OUT-T1: Reset -> out_data=0x00 (LEDs apagados)");
            rst_n = 1;

            // T2: Lo_n=1 — não captura
            out_Lo_n = 1; out_bus_in = 8'hAA;
            clock_cycle;
            if (out_data !== 8'h00) begin
                $display("[FALHA] OUT-T2: Lo_n=1 -> out_data deveria ser 0x00. Obtido: 0x%02X", out_data);
                erros = erros + 1;
            end else $display("[OK]    OUT-T2: Lo_n=1 (inativo) -> dado 0xAA nao capturado");

            // T3: Lo_n=0 — captura RESULTADO FINAL DO PROGRAMA: 32 = 0x20
            out_Lo_n = 0; out_bus_in = 8'd32;
            clock_cycle;
            if (out_data !== 8'd32) begin
                $display("[FALHA] OUT-T3: Lo_n=0 -> out_data deveria ser 32. Obtido: %0d", out_data);
                erros = erros + 1;
            end else $display("[OK]    OUT-T3: Lo_n=0 -> capturou 32 (0x20 = 0010_0000b) -> LEDS corretos!");

            // T4: persiste e representa os LEDs
            out_Lo_n = 1; out_bus_in = 8'hFF;
            clock_cycle;
            if (out_data !== 8'd32) begin
                $display("[FALHA] OUT-T4: Persistencia falhou. Obtido: %0d", out_data);
                erros = erros + 1;
            end else $display("[OK]    OUT-T4: out_data persiste em 32 — LEDs mantem o resultado");
        end
    endtask

    // =========================================================================
    // PROGRAMA PRINCIPAL
    // =========================================================================
    initial begin
        $display("============================================================");
        $display("  TESTBENCH: Registradores do SAP-1");
        $display("  (Accumulator, Register B, MAR, IR, Output Register)");
        $display("============================================================");

        // Estado inicial de todos os sinais
        rst_n = 1;
        acc_La_n = 1; acc_Ea = 0;  acc_bus_in  = 8'h00;
        regb_Lb_n = 1;             regb_bus_in = 8'h00;
        mar_Lm_n = 1;              mar_bus_in  = 8'h00;
        ir_Li_n = 1; ir_Ei_n = 1; ir_bus_in   = 8'h00;
        out_Lo_n = 1;              out_bus_in  = 8'h00;

        // Executa cada suite de teste
        teste_accumulator;
        rst_n = 1; #20;

        teste_register_b;
        rst_n = 1; #20;

        teste_mar;
        rst_n = 1; #20;

        teste_ir;
        rst_n = 1; #20;

        teste_output_register;
        rst_n = 1; #20;

        // ---- Resultado Global ----
        #50;
        $display("\n============================================================");
        if (erros == 0)
            $display("  RESULTADO GLOBAL: SUCESSO — Todos os registradores OK!");
        else
            $display("  RESULTADO GLOBAL: FALHA — %0d erro(s) encontrado(s)!", erros);
        $display("============================================================");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Dump de formas de onda
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_registradores.vcd");
        $dumpvars(0, tb_registradores);
    end

endmodule
