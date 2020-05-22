`timescale 1ns / 100ps

module debug_unit_tb;
    reg rst,clk;
    reg succ,step,m_rf,inc,dec;
    reg [2:0]sel;
    
    parameter PERIOD = 10;
    parameter CYCLE = 250;
     
    debug_unit my_dbg_unit(.clk(clk), .rst(rst),.sel(sel),.succ(succ),.step(step),.m_rf(m_rf),.inc(inc));
    
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
        {succ,step,m_rf,inc,dec,sel}=8'd0;
        #(PERIOD)
        rst = 0;
        succ = 1;
        #(PERIOD*80)
        succ = 0;
        m_rf=1;
        
        repeat (8) begin
            #(PERIOD)
            inc=1;
            #(PERIOD)
            inc=0;
        end

        #(PERIOD*2)
        rst = 1;
        #(PERIOD)
        rst = 0;
        sel =3'd1;
        
        repeat (40) begin
            #(PERIOD)
            step=1;
            #(PERIOD)
            step=0;
        end
        
        repeat (7) begin
            #(PERIOD)
            sel = sel+3'd1;
        end

        m_rf=1;
        repeat (8) begin
            #(PERIOD)
            inc=1;
            #(PERIOD)
            inc=0;
        end

    end


endmodule
