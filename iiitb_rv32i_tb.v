module iiitb_rv32i_tb;

    // Inputs
    reg clk, RN;

    // Outputs
    wire [31:0] WB_OUT, NPC;

    // Instantiate the Unit Under Test (UUT)
    iiitb_rv32i rv32 (
        .clk(clk),
        .RN(RN),
        .NPC(NPC),
        .WB_OUT(WB_OUT)
    );

    // Clock generation
    always #3 clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize Inputs
        RN = 1'b1;
        clk = 1'b1;

        // Initialize VCD dump
        $dumpfile("iiitb_rv32i.vcd");
        $dumpvars(0, iiitb_rv32i_tb);

        // Release reset
        #5 RN = 1'b0;

        // Run simulation for 300 time units
        #300 $finish;
   
