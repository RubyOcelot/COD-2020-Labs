`timescale 1ns / 100ps

module sort_tb;
    reg clk, rst;
    reg [3:0] x0, x1, x2, x3;
    wire [3:0] s0, s1, s2, s3;
    wire done;
    
parameter PERIOD = 10, 	//
CYCLE = 40;		//

    sort #(4) SORT(.clk(clk), .rst(rst), .x0(x0), .x1(x1), .x2(x2), .x3(x3), .s0(s0), .s1(s1), .s2(s2), .s3(s3), .done(done));
    
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
    #PERIOD rst = 0;
    
    #(PERIOD*10) rst = 1;
    #PERIOD rst = 0;
    
    #(PERIOD*10) rst = 1;
    #PERIOD rst = 0;    
    end
    
    initial
    begin
    x0 = 3;
    x1 = 5;
    x2 = 7;
    x3 = 8;
    
    #(PERIOD*11);
    x0 = 10;
    x1 = 8;
    x2 = 15;
    x3 = 2;

    #(PERIOD*11);
    x0 = 2;
    x1 = 3;
    x2 = 9;
    x3 = 12;
end
endmodule
