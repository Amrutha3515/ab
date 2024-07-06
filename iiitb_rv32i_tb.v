module tb_simple_riscv_processor;

  reg clk;
  reg reset;
  wire [31:0] instruction_address;
  reg [31:0] instruction_data;
  wire [31:0] data_address;
  reg [31:0] data_read_data;
  wire data_write_enable;
  wire [31:0] data_write_data;

  // Instantiate the processor
  simple_riscv_processor uut (
    .clk(clk),
    .reset(reset),
    .instruction_address(instruction_address),
    .instruction_data(instruction_data),
    .data_address(data_address),
    .data_read_data(data_read_data),
    .data_write_enable(data_write_enable),
    .data_write_data(data_write_data)
  );

  // Instruction memory
  reg [31:0] instruction_memory[0:255];
  
  // Data memory
  reg [31:0] data_memory[0:255];

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initialize instruction memory with a simple program
    instruction_memory[0] = 32'b0000000_00001_00010_000_00011_0110011; // ADD x3, x1, x2
    instruction_memory[1] = 32'b0000000_00100_00101_000_00110_0110011; // ADD x6, x4, x5
    instruction_memory[2] = 32'b0000000_00001_00010_000_00111_0010011; // ADDI x7, x2, 1
    instruction_memory[3] = 32'b0000000_00001_00010_010_00001_0000011; // LW x1, 2(x2)
    instruction_memory[4] = 32'b0000000_00100_00010_010_00100_0100011; // SW x4, 2(x2)
    instruction_memory[5] = 32'b0000000_00001_00010_000_00001_1100011; // BEQ x1, x2, 1
    instruction_memory[6] = 32'b0000000_00000_00000_000_00000_1110011; // ECALL (halt)

    // Initialize data memory
    data_memory[0] = 32'h00000000;
    data_memory[1] = 32'h00000001;
    data_memory[2] = 32'h00000002;
    data_memory[3] = 32'h00000003;
    data_memory[4] = 32'h00000004;
    data_memory[5] = 32'h00000005;

    // Initialize the processor
    reset = 1;
    #10;
    reset = 0;

    // Run the test for a certain number of clock cycles
    #100;

    // Check the results
    $display("Register x3: %h", uut.register_file[3]); // Should be x1 + x2
    $display("Register x6: %h", uut.register_file[6]); // Should be x4 + x5
    $display("Register x7: %h", uut.register_file[7]); // Should be x2 + 1
    $display("Data memory[2]: %h", data_memory[2]); // Should be x4

    // End the simulation
    $stop;
  end

  // Instruction memory read
  always @(instruction_address) begin
    instruction_data <= instruction_memory[instruction_address >> 2];
  end

  // Data memory read and write
  always @(posedge clk) begin
    if (data_write_enable) begin
      data_memory[data_address >> 2] <= data_write_data;
    end
    data_read_data <= data_memory[data_address >> 2];
  end

endmodule
