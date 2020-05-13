`timescale 1ns / 100ps

module mycpu_single_tb;
    reg rst,clk;
    
    parameter PERIOD = 10;
    parameter CYCLE = 40;
     
    cpu_one_cycle my_cpu(.clk(clk), .rst(rst));
    
    initial
    begin
        clk = 0;
        repeat (2 * CYCLE)
        	#(PERIOD/2) clk = ~clk;
        $finish;
    end
    
    initial
    begin
        rst = 1;
        #(PERIOD)
        rst = 0;
    end


endmodule

 