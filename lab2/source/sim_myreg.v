`timescale 1ns / 100ps

module myreg_tb;
    reg [4:0] ra0, ra1, wa;
    wire [31:0] rd0, rd1;
    reg we,clk;
    reg [31:0] wd;
    
    parameter PERIOD = 10;
    parameter CYCLE = 40;		
     
    register_file #(32) my_rf(.clk(clk), .ra0(ra0), .rd0(rd0), .ra1(ra1), .rd1(rd1), .wa(wa), .we(we), .wd(wd));
    
    initial
    begin
        clk = 0;
        repeat (2 * CYCLE)
        	#(PERIOD/2) clk = ~clk;
        $finish;
    end

    initial begin
        ra0=5'd0;
        #(PERIOD/2);
        ra1=5'd1;
        #(PERIOD*3);
        ra0=5'd31;
        ra1=5'd20;
        #(PERIOD*3);
        ra0=5'd25;
        #(PERIOD/2);
        ra1=5'd30;
        #(PERIOD);
        ra0=5'd0;
        
    end

    initial begin
        we=1;
        wa=5'd0;
        wd=32'd123;
        
        #PERIOD;
        wa=5'd1;
        wd=32'd456;
        
        #PERIOD;
        wa=5'd31;
        wd=32'd789;
        
        #PERIOD;
        wa=5'd20;
        wd=32'd378;
                
        #PERIOD;
        wa=5'd25;
        wd=32'd23428;
        
        #PERIOD;
        wa=5'd29;
        wd=32'd32768;
        
        #PERIOD;
        wa=5'd10;
        wd=32'd1278;
        
        #PERIOD;
        wa=5'd30;
        wd=32'd2342234;

        #PERIOD 
        we=0;
        wa=5'd0;
        wd=32'd123456;
        
        #PERIOD;
        we=1;
        wa=5'd0;
        wd=32'd123456;
        
        #PERIOD;
        $finish;      
    end
endmodule

 