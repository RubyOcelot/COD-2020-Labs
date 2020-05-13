`timescale 1ns / 100ps

module blk_mem_tb;
    reg [3:0] a;
    wire [7:0] dout;
    reg we,clk,en;
    reg [7:0] din;
    
    parameter PERIOD = 10;
    parameter CYCLE = 40;
     
    blk_mem_gen_0 my_ram(.clka(clk), .wea(we), .dina(din), .addra(a), .douta(dout), .ena(en));
    
    initial
    begin
        clk = 0;
        repeat (2 * CYCLE)
        	#(PERIOD/2) clk = ~clk;
        //$finish;
    end


    initial begin
        en=1;
        we=1;
        a=4'd0;
        din=8'd23;
        
        #PERIOD;
        en=1;
        we=1;
        a=4'd1;
        din=8'd45;
        
        #PERIOD;
        en=1;
        we=0;
        a=4'd1;
        din=8'd79;
        
        #PERIOD;
        en=0;
        we=0;
        a=4'd0;
        din=8'd78;
                
        #PERIOD;
        en=1;
        we=1;
        a=4'd15;
        din=8'd89;
        
        #PERIOD;
        en=0;
        we=1;
        a=4'd14;
        din=8'd0;
        
        #PERIOD;
        en=1;
        we=0;
        a=4'd14;
        din=8'd18;
        
        #PERIOD;
        en=1;
        we=0;
        a=4'd15;
        din=8'd23;

        #PERIOD 
        en=1;
        we=1;
        a=4'd0;
        din=8'd56;
        
        #PERIOD;
        en=1;
        we=0;
        a=4'd0;
        din=8'd1;
        
        #PERIOD;
        $finish;      
    end
endmodule

 