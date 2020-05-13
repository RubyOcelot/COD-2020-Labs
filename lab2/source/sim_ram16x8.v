`timescale 1ns / 100ps

module dist_mem_tb;
    reg [3:0] a;
    wire [7:0] spo;
    reg we,clk;
    reg [7:0] d;
    
    parameter PERIOD = 10;
    parameter CYCLE = 40;
     
    dist_mem_gen_0 my_ram(.clk(clk), .we(we), .d(d), .a(a), .spo(spo));
    
    initial
    begin
        clk = 0;
        repeat (2 * CYCLE)
        	#(PERIOD/2) clk = ~clk;
        //$finish;
    end


    initial begin
        we=1;
        a=4'd0;
        d=8'd23;
        
        #PERIOD;
        we=1;
        a=4'd1;
        d=8'd45;
        
        #PERIOD;
        we=0;
        a=4'd1;
        d=8'd79;
        
        #PERIOD;
        we=0;
        a=4'd0;
        d=8'd78;
                
        #PERIOD;
        we=1;
        a=4'd15;
        d=8'd89;
        
        #PERIOD;
        we=1;
        a=4'd14;
        d=8'd0;
        
        #PERIOD;
        we=0;
        a=4'd14;
        d=8'd18;
        
        #PERIOD;
        we=0;
        a=4'd15;
        d=8'd23;

        #PERIOD 
        we=1;
        a=4'd0;
        d=8'd56;
        
        #PERIOD;
        we=0;
        a=4'd0;
        d=8'd1;
        
        #PERIOD;
        $finish;      
    end
endmodule

 