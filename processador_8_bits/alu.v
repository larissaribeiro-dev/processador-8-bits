// =============================================================================
// Arquivo    : alu.v
// Projeto    : Processador 8 bits
// Autor      : Claude AI
// Descrição  : Somador/Subtrator de 8 bits (ALU simplificada).
//              Opera de forma ASSÍNCRONA — resultado sempre disponível.
//              Usa complemento de dois para subtração, conforme Lista 4.
//
// Funcionamento:
//   - Su = 0 → saída = A + B        (adição)
//   - Su = 1 → saída = A - B = A + (~B + 1)  (subtração via complemento de 2)
//   - Eu = 1 → coloca resultado no barramento W
//   - Eu = 0 → barramento liberado (alta impedância)
//
//   O Acumulador A alimenta continuamente a ALU.
//   O Registrador B alimenta continuamente a ALU.
//   O resultado só aparece no barramento quando Eu = 1.
//
// Entradas   :
//   a_in     — valor do Acumulador A (8 bits, sempre conectado)
//   b_in     — valor do Registrador B (8 bits, sempre conectado)
//   Su       — Subtract: 0 = soma, 1 = subtração
//   Eu       — Enable ALU output to bus, ativo em '1'
//
// Saídas     :
//   bus_out  — resultado da operação → barramento W (quando Eu = 1)
// =============================================================================

module alu (
    input  wire [7:0] a_in,      // do Acumulador A
    input  wire [7:0] b_in,      // do Registrador B
    input  wire       Su,        // 0=soma, 1=subtração
    input  wire       Eu,        // enable saída para o barramento
    output wire [7:0] bus_out    // resultado → barramento W
);

    // -------------------------------------------------------------------------
    // Cálculo assíncrono — sempre atualizado
    // Subtração implementada via complemento de dois:
    //   A - B = A + (~B) + 1
    // O Verilog faz isso automaticamente com o operador '-'
    // -------------------------------------------------------------------------
    wire [7:0] result;

    assign result = Su ? (a_in - b_in) : (a_in + b_in);

    // -------------------------------------------------------------------------
    // Saída para o barramento — habilitada quando Eu = 1
    // -------------------------------------------------------------------------
    assign bus_out = Eu ? result : 8'h00;

endmodule
