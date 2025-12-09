`timescale 1ns / 1ps

module alu(
    input  [31:0] A,
    input  [31:0] B,
    input  [5:0]  Op,
    output reg [31:0] C,
    output        zero
);
    // Opcode localparams definition
    localparam OP_SLL  = 6'b000000;
    localparam OP_SRL  = 6'b000010;
    localparam OP_SRA  = 6'b000011;
    localparam OP_ADD  = 6'b100000;
    localparam OP_ADDU = 6'b100001;
    localparam OP_SUB  = 6'b100010;
    localparam OP_SUBU = 6'b100011;
    localparam OP_AND  = 6'b100100;
    localparam OP_OR   = 6'b100101;
    localparam OP_XOR  = 6'b100110;
    localparam OP_NOR  = 6'b100111;
    localparam OP_LUI  = 6'b101000;
    localparam OP_SLT  = 6'b101010;
    localparam OP_SLTU = 6'b101011;
    
    // Variable Shift Operations
    localparam OP_SLLV = 6'b000100;
    localparam OP_SRLV = 6'b000110;
    localparam OP_SRAV = 6'b000111;

    wire is_sub = (Op == OP_SUB) || (Op == OP_SUBU) || (Op == OP_SLT) || (Op == OP_SLTU);
    wire [31:0] B_eff = is_sub ? (~B + 32'b1) : B;
    wire [31:0] arith_res;
    add add_inst (
        .a(A),
        .b(B_eff),
        .sum(arith_res)
    );
    assign zero = (C == 32'b0);

    always @(*) begin
        C <= 32'b0;
        case (Op)
            // Arithmetic Operations (using the adder instance)
            OP_ADD, OP_ADDU, OP_SUB, OP_SUBU: begin
                C <= arith_res;
            end

            // Logic Operations
            OP_AND: C <= A & B;
            OP_OR:  C <= A | B;
            OP_XOR: C <= A ^ B;
            OP_NOR: C <= ~(A | B);
            OP_SLL, OP_SLLV: C <= B << A[4:0];        // Logical Left Shift
            OP_SRL, OP_SRLV: C <= B >> A[4:0];        // Logical Right Shift
            OP_SRA, OP_SRAV: C <= $signed(B) >>> A[4:0]; // Arithmetic Right Shift

            // Load Upper Immediate
            OP_LUI: C <= B << 16;
            
            // Set Less Than
            OP_SLT:  C <= ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            OP_SLTU: C <= (A < B) ? 32'd1 : 32'd0;
            
            default: C <= 32'b0;
        endcase
    end
endmodule