`timescale 1us / 1us

module testbench;

    reg clock;
    reg reset;

    // Instantiate the Unit Under Test (UUT)
    pipline_cpu uut (
        .clock(clock),
        .reset(reset)
    );

    initial begin
        // Initialize Inputs
        clock = 0;
        reset = 1;

        // Wait 100 us for global reset to finish
        #100;
        reset = 0;
        
        // Add a timeout to prevent infinite loops
        // Increased to match Mars 200k step limit (200k * 10ns = 2,000,000)
        #2500000; 
        $display("Simulation Timeout");
        $finish;
    end
    
    // Clock generation
    always #5 clock = ~clock; 

endmodule