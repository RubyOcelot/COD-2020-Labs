`timescale 1ns / 100ps

module top_unit_tb;
    reg rst,clk;
    reg m_rf;
    reg [15:0]m_rf_addr;
    reg input_btn,left_btn,right_btn;
    reg [15:0]sw;
    
    parameter PERIOD = 10;
    parameter CYCLE = 1000;
     
    top_unit my_top_unit(.clk(clk), .rst(rst),.m_rf(m_rf),.m_rf_addr(m_rf_addr),.input_btn(input_btn),.left_btn(left_btn),.right_btn(right_btn),.sw(sw));
    
    initial
    begin
        clk = 0;
        repeat (2 * CYCLE)
        	#(PERIOD/2) clk = ~clk;
        $finish;
    end
    
    reg [31:0] num1=~(32'd0)+32'd1;
    //reg [31:0] num1=32'd0;

    reg [31:0] num2=~(32'd23333)+32'd1;
    //reg [31:0] num2=32'd19260817;
    
    initial
    begin
        rst = 1;
        #(PERIOD)
        rst = 0;
        m_rf = 1;
        m_rf_addr=16'd16;

        #(PERIOD)
        sw=num1[31:16];
        left_btn=1;
        #(PERIOD)
        left_btn=0;
        #(PERIOD)
        sw=num1[15:0];
        right_btn=1;
        #(PERIOD)
        right_btn=0;
        #(PERIOD)
        input_btn=1;
        #(PERIOD)
        input_btn=0;

        #(PERIOD*20)

        #(PERIOD)
        sw=num2[31:16];
        left_btn=1;
        #(PERIOD)
        left_btn=0;
        #(PERIOD)
        sw=num2[15:0];
        right_btn=1;
        #(PERIOD)
        right_btn=0;
        #(PERIOD)
        input_btn=1;
        #(PERIOD)
        input_btn=0;

        #(PERIOD*80)
        m_rf_addr=16'd0;
        repeat(32)begin
            #(PERIOD)
            m_rf_addr=m_rf_addr+16'd1;
        end

    end


endmodule
