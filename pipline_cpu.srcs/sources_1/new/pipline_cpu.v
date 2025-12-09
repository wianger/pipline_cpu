`timescale 1ns / 1ps

`timescale 1ns / 1ps

module pipline_cpu(
    input wire clock,
    input wire reset
);
    // IF Stage
    wire [31:0] pc_out;
    wire [31:0] pc_plus_4;
    wire [31:0] next_pc;
    wire [31:0] instr;
    wire        pc_write;
    wire        if_id_stall;
    wire        if_flush; // For branch taken

    // ID Stage
    wire [31:0] id_pc;
    wire [31:0] id_inst;
    wire [5:0]  opcode = id_inst[31:26];
    wire [4:0]  rs = id_inst[25:21];
    wire [4:0]  rt = id_inst[20:16];
    wire [4:0]  rd = id_inst[15:11];
    wire [4:0]  shamt = id_inst[10:6];
    wire [5:0]  funct = id_inst[5:0];
    wire [15:0] imm16 = id_inst[15:0];
    wire [25:0] instr_index = id_inst[25:0];

    wire [31:0] reg_data1, reg_data2;
    wire [31:0] forward_id_data1, forward_id_data2; // Forwarded data in ID
    wire [31:0] ext_imm;
    
    // Control Signals (ID)
    wire ctrl_reg_dst, ctrl_alu_src, ctrl_mem_to_reg, ctrl_reg_write;
    wire ctrl_mem_read, ctrl_mem_write, ctrl_branch, ctrl_jump, ctrl_jump_reg, ctrl_jal;
    wire ctrl_sign_ext;
    wire [5:0] ctrl_alu_op;
    wire [3:0] ctrl_alu_op_type; // From Control Unit to ALU Control Unit
    wire [1:0] ctrl_mem_size;
    wire       ctrl_mem_unsigned;
    
    // Hazard & Branch
    wire id_ex_flush;
    wire branch_taken;
    wire [31:0] branch_target;
    wire hazard_id_ex_flush;
    
    // Syscall Detection
    // Opcode 0 (R-type) and Funct 0x0C (12)
    always @(*) begin
        if (opcode == 6'b000000 && funct == 6'b001100) begin
            $display("Syscall detected at PC %h. Finishing simulation.", id_pc);
            $finish;
        end
    end
    
    // ID/EX Inputs (MUXed for JAL/Flush)
    wire [5:0]  id_ex_in_alu_op;
    wire        id_ex_in_alu_src;
    wire        id_ex_in_reg_dst;
    wire [31:0] id_ex_in_data1;
    wire [31:0] id_ex_in_imm;
    wire [4:0]  id_ex_in_shamt;
    wire [4:0]  id_ex_in_rs, id_ex_in_rt, id_ex_in_rd;
    wire [1:0]  id_ex_in_mem_size;
    wire        id_ex_in_mem_unsigned;
    
    // EX Stage
    wire [31:0] ex_pc;
    wire [31:0] ex_read_data1, ex_read_data2;
    wire [31:0] ex_imm;
    wire [4:0]  ex_shamt;
    wire [4:0]  ex_rs, ex_rt, ex_rd;
    wire [5:0]  ex_alu_op;
    wire        ex_alu_src, ex_reg_dst;
    wire        ex_reg_write, ex_mem_to_reg, ex_mem_read, ex_mem_write, ex_branch;
    wire [1:0]  ex_mem_size;
    wire        ex_mem_unsigned;
    
    wire [31:0] alu_in_a, alu_in_b, alu_in_b_final;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [1:0]  forward_a, forward_b;
    wire [4:0]  ex_write_reg;

    // MEM Stage
    wire [31:0] mem_alu_result, mem_write_data;
    wire [4:0]  mem_write_reg;
    wire        mem_reg_write, mem_mem_to_reg, mem_mem_read, mem_mem_write, mem_branch;
    wire [1:0]  mem_mem_size;
    wire        mem_mem_unsigned;
    wire        mem_zero; // Not used for branch anymore
    wire [31:0] mem_read_data;
    wire [31:0] mem_pc; // PC in MEM stage
    wire [31:0] mem_final_read_data; // Data after Byte/Half extraction

    // WB Stage
    wire [31:0] wb_read_data, wb_alu_result;
    wire [4:0]  wb_write_reg;
    wire        wb_reg_write, wb_mem_to_reg;
    wire [31:0] wb_write_data;
    wire [31:0] wb_pc;

    // --- IF Stage Logic ---
    
    assign pc_plus_4 = pc_out + 4;
    
    // Next PC Logic
    // Priority: Reset (handled in PC) > Branch/Jump > PC+4
    // Branch/Jump taken logic from ID stage
    assign next_pc = branch_taken ? branch_target : pc_plus_4;
    
    // Flush IF/ID if branch taken
    // DELAY SLOT SUPPORT: Do NOT flush IF/ID on branch taken.
    // The instruction at PC+4 (Delay Slot) must be executed.
    assign if_flush = 1'b0; // No flush for delay slot

    pc pc_module(
        .reset(reset),
        .clock(clock),
        .pcwrite(pc_write),
        .nextpc(next_pc),
        .pcValue(pc_out)
    );

    instruction_memory im_module(
        .address(pc_out),
        .instruction(instr)
    );

    if_id_reg if_id_module(
        .clock(clock),
        .reset(reset),
        .stall(if_id_stall),
        .flush(if_flush),
        .if_pc(pc_plus_4),
        .if_inst(instr),
        .id_pc(id_pc),
        .id_inst(id_inst)
    );

    // --- ID Stage Logic ---

    wire ctrl_jalr;

    control_unit ctrl_module(
        .opcode(opcode),
        .funct(funct),
        .reg_dst(ctrl_reg_dst),
        .alu_src(ctrl_alu_src),
        .mem_to_reg(ctrl_mem_to_reg),
        .reg_write(ctrl_reg_write),
        .mem_read(ctrl_mem_read),
        .mem_write(ctrl_mem_write),
        .branch(ctrl_branch),
        .jump(ctrl_jump),
        .jump_reg(ctrl_jump_reg),
        .jal(ctrl_jal),
        .jalr(ctrl_jalr),
        .sign_ext(ctrl_sign_ext),
        .alu_op_type(ctrl_alu_op_type),
        .mem_size(ctrl_mem_size),
        .mem_unsigned(ctrl_mem_unsigned)
    );

    alu_control_unit alu_ctrl_module(
        .alu_op_type(ctrl_alu_op_type),
        .funct(funct),
        .alu_control(ctrl_alu_op)
    );

    registers reg_file(
        .reset(reset),
        .clock(clock),
        .readregister1(rs),
        .readregister2(rt),
        .regwrite(wb_reg_write),
        .writeregister(wb_write_reg),
        .writedata(wb_write_data),
        .pc(wb_pc - 4),
        .readdata1(reg_data1),
        .readdata2(reg_data2)
    );

    // ID Forwarding Logic (Simple MUXing for Branch Unit)
    // Forward from MEM stage (ALU result OR Memory Output) or WB stage
    
    // Determine data from MEM stage: ALU result or Memory Output?
    // If it's a Load instruction (mem_mem_read=1), we need the memory data.
    // Since Data Memory is asynchronous read, mem_read_data is valid in this cycle.
    wire [31:0] mem_forward_data = mem_mem_read ? mem_read_data : mem_alu_result;

    assign forward_id_data1 = 
        (mem_reg_write && (mem_write_reg != 0) && (mem_write_reg == rs)) ? mem_forward_data :
        (wb_reg_write && (wb_write_reg != 0) && (wb_write_reg == rs)) ? wb_write_data :
        reg_data1;

    assign forward_id_data2 = 
        (mem_reg_write && (mem_write_reg != 0) && (mem_write_reg == rt)) ? mem_forward_data :
        (wb_reg_write && (wb_write_reg != 0) && (wb_write_reg == rt)) ? wb_write_data :
        reg_data2;

    branch_unit branch_module(
        .opcode(opcode),
        .funct(funct),
        .rt_index(rt),
        .rs_data(forward_id_data1),
        .rt_data(forward_id_data2),
        .pc_plus_4(id_pc),
        .instr_index(instr_index),
        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );

    hazard_detection_unit hazard_module(
        .if_id_rs(rs),
        .if_id_rt(rt),
        .id_branch(ctrl_branch),
        .id_jump_reg(ctrl_jump_reg),
        .id_ex_mem_read(ex_mem_read),
        .id_ex_reg_write(ex_reg_write),
        .id_ex_rt(ex_rt), // Actually we should check against the write reg of EX
        .id_ex_rd(ex_write_reg), // Using the calculated write reg from EX
        .ex_mem_mem_read(mem_mem_read),
        .ex_mem_write_reg(mem_write_reg),
        .pc_write(pc_write),
        .if_id_stall(if_id_stall),
        .id_ex_flush(hazard_id_ex_flush)
    );

    // Sign Extension (Controlled by Control Unit)
    assign ext_imm = ctrl_sign_ext ? {{16{imm16[15]}}, imm16} : {16'b0, imm16};

    // ID/EX Input MUXing for JAL and Flush
    // If JAL: ALUOp=ADD, ALUSrc=1, Data1=PC, Imm=4, RegDst=1(rd), Rd=31
    // DELAY SLOT SUPPORT: Do NOT flush ID/EX on branch taken.
    assign id_ex_flush = hazard_id_ex_flush; // Only flush on hazard

    assign id_ex_in_alu_op  = (ctrl_jal || ctrl_jalr) ? 6'b100000 : ctrl_alu_op; // ADD for JAL/JALR
    assign id_ex_in_alu_src = (ctrl_jal || ctrl_jalr) ? 1'b1 : ctrl_alu_src;
    assign id_ex_in_reg_dst = (ctrl_jal || ctrl_jalr) ? 1'b1 : ctrl_reg_dst; // Select Rd (which we force to 31 for JAL)
    assign id_ex_in_data1   = (ctrl_jal || ctrl_jalr) ? id_pc : reg_data1;
    assign id_ex_in_imm     = (ctrl_jal || ctrl_jalr) ? 32'd4 : ext_imm;
    assign id_ex_in_shamt   = shamt;
    assign id_ex_in_rs      = rs;
    assign id_ex_in_rt      = rt;
    assign id_ex_in_rd      = ctrl_jal ? 5'd31 : rd; // JAL uses 31, JALR uses rd
    assign id_ex_in_mem_size = ctrl_mem_size;
    assign id_ex_in_mem_unsigned = ctrl_mem_unsigned;

    id_ex_reg id_ex_module(
        .clock(clock),
        .reset(reset),
        .stall(1'b0), // ID/EX usually doesn't stall
        .flush(id_ex_flush),
        
        // Control
        .id_reg_write(ctrl_reg_write),
        .id_mem_to_reg(ctrl_mem_to_reg),
        .id_mem_read(ctrl_mem_read),
        .id_mem_write(ctrl_mem_write),
        .id_branch(ctrl_branch),
        .id_mem_size(id_ex_in_mem_size),
        .id_mem_unsigned(id_ex_in_mem_unsigned),
        .id_alu_op(id_ex_in_alu_op),
        .id_alu_src(id_ex_in_alu_src),
        .id_reg_dst(id_ex_in_reg_dst),
        
        // Data
        .id_pc(id_pc),
        .id_read_data1(id_ex_in_data1),
        .id_read_data2(reg_data2), // JAL doesn't use rt data
        .id_imm(id_ex_in_imm),
        .id_shamt(id_ex_in_shamt),
        .id_rs(id_ex_in_rs),
        .id_rt(id_ex_in_rt),
        .id_rd(id_ex_in_rd),
        
        // Outputs
        .ex_reg_write(ex_reg_write),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_branch(ex_branch),
        .ex_mem_size(ex_mem_size),
        .ex_mem_unsigned(ex_mem_unsigned),
        .ex_alu_op(ex_alu_op),
        .ex_alu_src(ex_alu_src),
        .ex_reg_dst(ex_reg_dst),
        .ex_pc(ex_pc),
        .ex_read_data1(ex_read_data1),
        .ex_read_data2(ex_read_data2),
        .ex_imm(ex_imm),
        .ex_shamt(ex_shamt),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_rd(ex_rd)
    );

    // --- EX Stage Logic ---

    forwarding_unit fwd_module(
        .id_ex_rs(ex_rs),
        .id_ex_rt(ex_rt),
        .ex_mem_rd(mem_write_reg),
        .ex_mem_reg_write(mem_reg_write),
        .mem_wb_rd(wb_write_reg),
        .mem_wb_reg_write(wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // ALU Input MUXes
    // ALU Input A: Forwarding > Shift Amount > Reg Data
    // Note: SLL/SRL/SRA use shamt as Input A (in my alu.v design)
    // OP_SLL=000000, OP_SRL=000010, OP_SRA=000011
    wire is_shift_imm = (ex_alu_op == 6'b000000) || (ex_alu_op == 6'b000010) || (ex_alu_op == 6'b000011);
    
    wire [31:0] alu_in_a_fwd;
    assign alu_in_a_fwd = (forward_a == 2'b10) ? mem_alu_result :
                          (forward_a == 2'b01) ? wb_write_data :
                          ex_read_data1;
    
    // For SLLV, SRLV, SRAV, the shift amount comes from Rs (alu_in_a_fwd), and data to shift comes from Rt (alu_in_b_final)
    // But my ALU design expects shift amount in A and data in B for shift ops.
    // SLL/SRL/SRA (imm): A = shamt, B = Rt
    // SLLV/SRLV/SRAV (reg): A = Rs, B = Rt
    
    assign alu_in_a = is_shift_imm ? {27'b0, ex_shamt} : alu_in_a_fwd;

    wire [31:0] alu_in_b_temp;
    assign alu_in_b_temp = (forward_b == 2'b10) ? mem_alu_result :
                           (forward_b == 2'b01) ? wb_write_data :
                           ex_read_data2;

    assign alu_in_b_final = ex_alu_src ? ex_imm : alu_in_b_temp;

    wire [31:0] alu_out_internal;
    
    // HI/LO Registers
    reg [31:0] hi;
    reg [31:0] lo;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            hi <= 32'b0;
            lo <= 32'b0;
        end else begin
            case (ex_alu_op)
                6'b010010: hi <= alu_in_a; // MTHI
                6'b010011: lo <= alu_in_a; // MTLO
                6'b011000: {hi, lo} <= $signed(alu_in_a) * $signed(alu_in_b_final); // MULT
                6'b011001: {hi, lo} <= alu_in_a * alu_in_b_final; // MULTU
                6'b011010: begin // DIV
                    if (alu_in_b_final != 0) begin
                        lo <= $signed(alu_in_a) / $signed(alu_in_b_final);
                        hi <= $signed(alu_in_a) % $signed(alu_in_b_final);
                    end
                end
                6'b011011: begin // DIVU
                    if (alu_in_b_final != 0) begin
                        lo <= alu_in_a / alu_in_b_final;
                        hi <= alu_in_a % alu_in_b_final;
                    end
                end
            endcase
        end
    end

    assign alu_result = (ex_alu_op == 6'b010000) ? hi : // MFHI
                        (ex_alu_op == 6'b010001) ? lo : // MFLO
                        alu_out_internal;

    alu alu_module(
        .A(alu_in_a),
        .B(alu_in_b_final),
        .Op(ex_alu_op),
        .C(alu_out_internal),
        .zero(alu_zero)
    );

    assign ex_write_reg = ex_reg_dst ? ex_rd : ex_rt;

    ex_mem_reg ex_mem_module(
        .clk(clock),
        .rst(reset),
        .stall(1'b0),
        .flush(1'b0), // Usually no flush needed here unless exception
        
        .ex_reg_write(ex_reg_write),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_branch(ex_branch),
        .ex_mem_size(ex_mem_size),
        .ex_mem_unsigned(ex_mem_unsigned),
        
        .ex_alu_result(alu_result),
        .ex_mem_write_data(alu_in_b_temp), // Store data comes from rt (forwarded)
        .ex_write_reg(ex_write_reg),
        .ex_zero(alu_zero),
        .ex_branch_target(32'b0), // Not used as branch is in ID
        .ex_pc(ex_pc),
        
        .mem_reg_write(mem_reg_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_mem_read(mem_mem_read),
        .mem_mem_write(mem_mem_write),
        .mem_branch(mem_branch),
        .mem_mem_size(mem_mem_size),
        .mem_mem_unsigned(mem_mem_unsigned),
        .mem_alu_result(mem_alu_result),
        .mem_write_data(mem_write_data),
        .mem_write_reg(mem_write_reg),
        .mem_zero(mem_zero),
        .mem_branch_target(),
        .mem_pc(mem_pc)
    );

    // --- MEM Stage Logic ---

    data_memory dm_module(
        .reset(reset),
        .clock(clock),
        .address(mem_alu_result),
        .memread(mem_mem_read),
        .memwrite(mem_mem_write),
        .writedata(mem_write_data),
        .pc(mem_pc - 4),
        .size(mem_mem_size),
        .readdata(mem_read_data)
    );

    // Load Data Selection Logic (Byte/Half Extraction & Extension)
    reg [31:0] load_data_extracted;
    always @(*) begin
        case (mem_mem_size)
            2'b00: load_data_extracted = mem_read_data; // Word
            2'b01: begin // Byte
                case (mem_alu_result[1:0])
                    2'b00: load_data_extracted = {{24{mem_mem_unsigned ? 1'b0 : mem_read_data[7]}}, mem_read_data[7:0]};
                    2'b01: load_data_extracted = {{24{mem_mem_unsigned ? 1'b0 : mem_read_data[15]}}, mem_read_data[15:8]};
                    2'b10: load_data_extracted = {{24{mem_mem_unsigned ? 1'b0 : mem_read_data[23]}}, mem_read_data[23:16]};
                    2'b11: load_data_extracted = {{24{mem_mem_unsigned ? 1'b0 : mem_read_data[31]}}, mem_read_data[31:24]};
                endcase
            end
            2'b10: begin // Half
                case (mem_alu_result[1])
                    1'b0: load_data_extracted = {{16{mem_mem_unsigned ? 1'b0 : mem_read_data[15]}}, mem_read_data[15:0]};
                    1'b1: load_data_extracted = {{16{mem_mem_unsigned ? 1'b0 : mem_read_data[31]}}, mem_read_data[31:16]};
                endcase
            end
            default: load_data_extracted = mem_read_data;
        endcase
    end
    
    assign mem_final_read_data = load_data_extracted;

    mem_wb_reg mem_wb_module(
        .clock(clock),
        .reset(reset),
        .stall(1'b0),
        .flush(1'b0),
        
        .mem_reg_write(mem_reg_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_read_data(mem_final_read_data), // Use the extracted data
        .mem_alu_result(mem_alu_result),
        .mem_write_reg(mem_write_reg),
        .mem_pc(mem_pc),
        
        .wb_reg_write(wb_reg_write),
        .wb_mem_to_reg(wb_mem_to_reg),
        .wb_read_data(wb_read_data),
        .wb_alu_result(wb_alu_result),
        .wb_write_reg(wb_write_reg),
        .wb_pc(wb_pc)
    );

    // --- WB Stage Logic ---

    assign wb_write_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;

endmodule
