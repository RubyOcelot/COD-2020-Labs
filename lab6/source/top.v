module top_unit(
    input clk,rst,
    input m_rf,
    input [15:0]m_rf_addr,
    output [15:0]led,
    output [7:0]seg_data,
    output reg [7:0]seg_sel,
    input input_btn,left_btn,right_btn,
    input [15:0]sw
);

//peek
wire [31:0]m_data,rf_data;
reg [15:0]m_addr=0,rf_addr=0;

//seg
wire [31:0]selected_data;
wire [7:0]seg_data_all[0:7];
reg [2:0]cur_seg;
reg [31:0]seg_num;

//IO
wire input_flag;
reg [31:0]input_data=32'd0;
reg output_finish_flag=1'd0;
wire output_flag;
wire [31:0]output_data;

//bus
wire [31:0]bus_din,bus_dout;
wire [7:0]bus_addr;
wire bus_r,bus_w;

/*
//seg
ROM_for_seg num0(.a(seg_num[3:0]),.spo(seg_data_all[3'd0]));
ROM_for_seg num1(.a(seg_num[7:4]),.spo(seg_data_all[3'd1]));
ROM_for_seg num2(.a(seg_num[11:8]),.spo(seg_data_all[3'd2]));
ROM_for_seg num3(.a(seg_num[15:12]),.spo(seg_data_all[3'd3]));
ROM_for_seg num4(.a(seg_num[19:16]),.spo(seg_data_all[3'd4]));
ROM_for_seg num5(.a(seg_num[23:20]),.spo(seg_data_all[3'd5]));
ROM_for_seg num6(.a(seg_num[27:24]),.spo(seg_data_all[3'd6]));
ROM_for_seg num7(.a(seg_num[31:28]),.spo(seg_data_all[3'd7]));
assign seg_data=seg_data_all[cur_seg];
always @(*) begin
    case (cur_seg)
        3'd0: seg_sel=8'b00000001;
        3'd1: seg_sel=8'b00000010;
        3'd2: seg_sel=8'b00000100;
        3'd3: seg_sel=8'b00001000;
        3'd4: seg_sel=8'b00010000;
        3'd5: seg_sel=8'b00100000;
        3'd6: seg_sel=8'b01000000;
        3'd7: seg_sel=8'b10000000;
        default: seg_sel=8'b00000000;
    endcase
end
reg [19:0]cnt=0;
always @(posedge clk ) begin
    if(cnt==20'd1)begin
        cur_seg<=cur_seg+3'd1;
    end 
end
localparam MAX_COUNT=20'd1000000;
always @(posedge clk ) begin
    if(cnt<MAX_COUNT-20'd1)
        cnt<=cnt+20'd1;
    else
        cnt<=20'd0;
end
*/
always @(posedge clk or posedge rst) begin
    if(rst)begin
        seg_num<=32'd0;
        output_finish_flag<=1'd0;
    end
    else begin
        if(output_flag)begin
            seg_num<=output_data;
            output_finish_flag<=1'd1; 
        end
        else begin
            output_finish_flag<=1'd0; 
        end
    end
end

always @(posedge clk ) begin
    if(left_btn)begin
        input_data[31:16]<=sw;
    end
    if(right_btn)begin
        input_data[15:0]<=sw;
    end
end

//run
cpu_pipeline my_cpu(.clk(clk), .rst(rst),
        .rf_data(rf_data),.m_rf_addr(m_rf_addr),
        .bus_din(bus_din),.bus_addr(bus_addr),.bus_dout(bus_dout),.bus_r(bus_r),.bus_w(bus_w));

//bus
bus ram_IO(.clk(clk), .rst(rst), .we(bus_w), .re(bus_r),
        .d(bus_dout), .a(bus_addr), .spo(bus_din), .dpra(m_rf_addr[9:2]), .dpo(m_data),
        .input_flag(input_flag),.input_data(input_data),
        .output_flag(output_flag),.output_data(output_data),
        .output_finish_flag(output_finish_flag));


//led TODO
//assign led=(sel>3'd0)?{4'd0,status}:m_rf_addr;

edg input_flag_edg(.clk(clk),.rst(rst),.y(input_btn),.p(input_flag));

endmodule