module simple_riscv_processor(
  input clk,
  input reset,
  // Instruction memory interface
  output reg [31:0] instruction_address,
  input [31:0] instruction_data,
  // Data memory interface
  output reg [31:0] data_address,
  input  [31:0] data_read_data,
  output reg data_write_enable,
  output reg [31:0] data_write_data
);

  // Register file
  reg [31:0] register_file[31:0];

  // Program counter (PC)
  reg [31:0] pc;

  // Control signals
  reg [2:0] alu_op;
  reg [1:0] mem_op;
  reg reg_write_enable;
  reg branch;

  // Temporary registers for pipeline stages
  reg [31:0] reg1, reg2, immediate, rd, rs1, rs2;

  parameter RESET_VALUE = 32'h0;
  parameter ALU_ADD = 3'b000;
  parameter ALU_SUB = 3'b001;
  parameter ALU_AND = 3'b010;
  parameter ALU_OR  = 3'b011;
  parameter ALU_XOR = 3'b100;
  parameter ALU_SLT = 3'b101;
  parameter MEM_READ = 2'b00;
  parameter MEM_WRITE = 2'b01;

  // Reset initialization
  always @(posedge reset) begin
    pc <= RESET_VALUE;
    register_file <= 'b0; // Initialize all registers to 0
  end

  // Instruction fetch
  always @(posedge clk) begin
    if (reset) begin
      instruction_address <= RESET_VALUE;
    end else begin
      instruction_address <= pc;
    end
  end

  // Instruction decode
  always @(posedge clk) begin
    if (reset) begin
      reg1 <= RESET_VALUE;
      reg2 <= RESET_VALUE;
      immediate <= RESET_VALUE;
      rd <= RESET_VALUE;
      rs1 <= RESET_VALUE;
      rs2 <= RESET_VALUE;
    end else begin
      // Extract instruction fields
      rd <= instruction_data[11:7];
      rs1 <= instruction_data[19:15];
      rs2 <= instruction_data[24:20];
      immediate <= {{20{instruction_data[31]}}, instruction_data[31:20]};

      // Decode control signals
      case (instruction_data[6:0])
        7'b0110011: begin // R-type (ADD, SUB, AND, OR, XOR, SLT)
          case (instruction_data[14:12])
            3'b000: alu_op <= (instruction_data[30] ? ALU_SUB : ALU_ADD);
            3'b111: alu_op <= ALU_AND;
            3'b110: alu_op <= ALU_OR;
            3'b100: alu_op <= ALU_XOR;
            3'b010: alu_op <= ALU_SLT;
            default: alu_op <= ALU_ADD;
          endcase
          mem_op <= MEM_READ;
          reg_write_enable <= 1'b1;
          branch <= 1'b0;
        end
        7'b0010011: begin // I-type (ADDI)
          alu_op <= ALU_ADD;
          mem_op <= MEM_READ;
          reg_write_enable <= 1'b1;
          branch <= 1'b0;
        end
        7'b0000011: begin // Load
          alu_op <= ALU_ADD;
          mem_op <= MEM_READ;
          reg_write_enable <= 1'b1;
          branch <= 1'b0;
        end
        7'b0100011: begin // Store
          alu_op <= ALU_ADD;
          mem_op <= MEM_WRITE;
          reg_write_enable <= 1'b0;
          branch <= 1'b0;
        end
        7'b1100011: begin // Branch (BEQ)
          alu_op <= ALU_SUB;
          mem_op <= MEM_READ;
          reg_write_enable <= 1'b0;
          branch <= 1'b1;
        end
        default: begin
          alu_op <= ALU_ADD;
          mem_op <= MEM_READ;
          reg_write_enable <= 1'b0;
          branch <= 1'b0;
        end
      endcase

      // Read registers
      reg1 <= register_file[rs1];
      reg2 <= register_file[rs2];
    end
  end

  // Execute
  always @(posedge clk) begin
    if (reset) begin
      // Reset signals
    end else begin
      case (alu_op)
        ALU_ADD: data_write_data <= reg1 + (branch ? immediate : reg2);
        ALU_SUB: data_write_data <= reg1 - reg2;
        ALU_AND: data_write_data <= reg1 & reg2;
        ALU_OR:  data_write_data <= reg1 | reg2;
        ALU_XOR: data_write_data <= reg1 ^ reg2;
        ALU_SLT: data_write_data <= (reg1 < reg2) ? 32'b1 : 32'b0;
        default: data_write_data <= 32'b0;
      endcase

      // Set data memory address
      data_address <= reg1 + immediate;

      // Set write enable for data memory
      data_write_enable <= (mem_op == MEM_WRITE);
    end
  end

  // Memory access and write-back
  always @(posedge clk) begin
    if (reset) begin
      // Reset signals
    end else begin
      if (reg_write_enable) begin
        register_file[rd] <= (mem_op == MEM_READ) ? data_read_data : data_write_data;
      end
      if (branch && data_write_data == 32'b0) begin
        pc <= pc + immediate;
      end else begin
        pc <= pc + 4;
      end
    end
  end

endmodule
