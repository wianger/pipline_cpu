`timescale 1ns / 1ps

module hazard_detection_unit(
    // ID Stage Info
    input wire [4:0] if_id_rs,
    input wire [4:0] if_id_rt,
    input wire       id_branch,      // 当前ID阶段是分支指令 (beq)
    input wire       id_jump_reg,    // 当前ID阶段是寄存器跳转 (jr)
    // 注意: j/jal 不需要寄存器数据，所以不需要检测数据冒险(除非jr用rs)

    // EX Stage Info
    input wire       id_ex_mem_read, // EX阶段是Load
    input wire       id_ex_reg_write,// EX阶段写寄存器
    input wire [4:0] id_ex_rt,       // Load的目标 (或R-type的目标)
    input wire [4:0] id_ex_rd,       // R-type的目标 (如果区分的话，通常统一用 write_reg)

    // MEM Stage Info (用于分支指令在ID阶段的冒险检测)
    input wire       ex_mem_mem_read,// MEM阶段是Load
    input wire [4:0] ex_mem_write_reg, // MEM阶段写回寄存器

    // 控制信号输出
    output reg pc_write,            // PC写使能
    output reg if_id_stall,         // IF/ID暂停
    output reg id_ex_flush          // ID/EX冲刷
);

    always @(*) begin
        // 默认状态：不暂停，不冲刷
        pc_write = 1'b1;
        if_id_stall = 1'b0;
        id_ex_flush = 1'b0;

        // 1. Load-Use Hazard (ALU指令在ID, Load在EX)
        // 如果EX阶段是Load，且ID阶段的源寄存器(rs或rt)依赖于Load的目标
        // 优化: 只有当ID指令确实使用rs/rt时才暂停 (这里假设外部控制单元已处理，或者我们简单假设R-type/I-type都用)
        // 对于Load-Use，必须暂停1个周期。
        // 注意：如果ID是Store，它需要rt作为源，也需要暂停。
        if (id_ex_mem_read && (id_ex_rt != 5'b0) && 
            ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt))) begin
            pc_write = 1'b0;
            if_id_stall = 1'b1;
            id_ex_flush = 1'b1;
        end

        // 2. Branch/Jump Hazard (分支在ID阶段解决)
        // 如果分支指令在ID阶段，它需要读取寄存器进行比较(beq)或跳转(jr)。
        // 如果这些寄存器正在被前序指令(在EX或MEM阶段)修改，我们需要暂停，
        // 直到数据被写回寄存器堆(WB阶段)或者我们可以转发(如果实现了ID转发)。
        // 这里假设没有ID阶段的转发逻辑，必须等待数据写入RegFile。

        if (id_branch || id_jump_reg) begin
            // Case A: 依赖于EX阶段的运算结果 (ALU或Load)
            // 无论EX是ALU还是Load，结果都还没写入RegFile。
            // 如果EX指令写的目标寄存器 == 分支源寄存器
            if (id_ex_reg_write && (id_ex_rd != 5'b0) && 
                ((id_ex_rd == if_id_rs) || (id_ex_rd == if_id_rt))) begin
                pc_write = 1'b0;
                if_id_stall = 1'b1;
                id_ex_flush = 1'b1;
            end
            // 注意：上面的 id_ex_rd 应该是 EX 阶段最终确定的写回寄存器地址 (可能是 rt 或 rd)
            // 如果 id_ex_mem_read 为真，目标通常是 rt。建议外部统一传入 ex_write_reg。

            // Case B: 依赖于MEM阶段的运算结果 (ALU或Load)
            // 优化: 由于我们在ID阶段实现了从MEM阶段的转发(包括Load数据)，
            // 所以这里不需要暂停！只要数据在MEM阶段产生(即使是Load)，
            // 都可以通过旁路送给ID阶段的分支比较器。
            // 唯一的例外是如果Data Memory是同步读(Sync Read)，则Load数据在MEM阶段不可用，必须暂停。
            // 但根据 data_memory.v 的实现，它是异步读，所以可以转发。
            
            /* 
            // 移除不必要的暂停
            if (ex_mem_write_reg != 5'b0 && 
                ((ex_mem_write_reg == if_id_rs) || (ex_mem_write_reg == if_id_rt))) begin
                pc_write = 1'b0;
                if_id_stall = 1'b1;
                id_ex_flush = 1'b1;
            end
            */
        end
    end

endmodule
