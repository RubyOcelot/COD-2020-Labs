`timescale 1ns / 100ps

module top_unit_tb;
    reg rst,clk;
    reg m_rf;
    reg [15:0]m_rf_addr;
    reg input_btn,left_btn,right_btn;
    reg [15:0]sw;
    
    parameter PERIOD = 10;
    parameter CYCLE = 500;
     
    top_unit my_top_unit(.clk(clk), .rst(rst),.m_rf(m_rf),.m_rf_addr(m_rf_addr),.input_btn(input_btn),.left_btn(left_btn),.right_btn(right_btn),.sw(sw));
    
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
        m_rf = 0;
        m_rf_addr=0;
        #(PERIOD*50)
        #(PERIOD)
        m_rf_addr=16'd8;
        #(PERIOD*5)
        m_rf=1;
        m_rf_addr=16'd9;
        #(PERIOD*5)
        m_rf_addr=16'd0;
        repeat(32)begin
            #(PERIOD)
            m_rf_addr=m_rf_addr+16'd1;
        end

    end


endmodule
