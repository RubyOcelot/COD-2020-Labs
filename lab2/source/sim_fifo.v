`timescale 1ns / 100ps

module myfifo_tb;
    wire [7:0] dout;
    reg clk,en_in,en_out,rst;
    reg [7:0] din;
    wire [4:0]count;
    
    parameter PERIOD = 10;
    parameter CYCLE = 500;
     
    fifo my_fifo(.clk(clk), .rst(rst), .din(din), .dout(dout), .en_in(en_in), .en_out(en_out), .count(count));
    
    initial
    begin
        clk = 0;
        repeat (2 * CYCLE)
        	#(PERIOD/2) clk = ~clk;
        //$finish;
    end


    initial begin
        rst=0;
        en_in=1;
        en_out=1;
        din=8'd23;
        
        #(PERIOD*10);
        en_in=0;
        en_out=0;
        
        #(PERIOD);
        en_in=1;
        en_out=0;
        din=8'd78;
                
        #(PERIOD*2);
        en_in=0;
        en_out=1;



        #(PERIOD*5);
        rst=1;
        en_in=0;
        en_out=0;
        
        #(PERIOD);
        rst=0;
        en_in=1;
        en_out=0;
        din=8'd66;
        
        #(PERIOD*5);
        en_in=0;
        en_out=0;
        
        #(PERIOD);
        en_in=1;
        en_out=0;
        din=8'd23;

        #(PERIOD*5) 
        en_in=0;
        en_out=0;
        
        #(PERIOD);
        en_in=1;
        en_out=0;
        din=8'd77;
        
        #(PERIOD*5);
        en_in=0;
        en_out=0;
        
        #(PERIOD);
        en_in=0;
        en_out=1;
        
        #(PERIOD*5);
        en_in=0;
        en_out=0;
        
        #(PERIOD);
        en_in=0;
        en_out=1;
        
        #(PERIOD*5);
        en_in=0;
        en_out=0;
        
        #(PERIOD);
        en_in=0;
        en_out=1;
        
        #(PERIOD*5);
        en_in=0;
        en_out=0;
        
        #(PERIOD);
        en_in=0;
        en_out=1;
        
        #(PERIOD*5);
        $finish;      
    end
endmodule

 