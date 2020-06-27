module debug_unit(
    input clk,succ,step,rst,
    input [2:0]sel,
    input m_rf,
    input inc,
    input dec,
    output [15:0]led,
    output [7:0]seg_data,
    output reg [7:0]seg_sel
);

wire clkd;
reg run=0;
wire step_edge;
wire [15:0]status; 
wire [31:0]m_data,rf_data;
wire [15:0]m_rf_addr;
reg [15:0]m_addr=0,rf_addr=0;
wire inc_edge,dec_edge;
wire [31:0]selected_data,seg_num;
wire [7:0]seg_data_all[0:7];
reg [2:0]cur_seg;

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

assign seg_num=(sel>3'd0)?selected_data:((m_rf)?m_data:rf_data);

//clock control
edg step_edg(.clk(clk),.rst(rst),.y(step),.p(step_edge));
always @(posedge clk ) begin
    if(rst)begin
        run<=1'd0;
        m_addr=0;
        rf_addr=0;
    end
    else 
        if(succ|step_edge)
            run<=1'd1;
        else
            run<=1'd0;
end

//run
assign clkd=clk&run;
cpu_multi_cycle_good my_cpu(.clk(clkd), .rst(rst),.status(status),.m_data(m_data),.rf_data(rf_data),.m_rf_addr(m_rf_addr),.i_sel1(sel),.o_sel_data(selected_data));


assign m_rf_addr=(m_rf)?m_addr:rf_addr;
//led
assign led=(sel>3'd0)?{4'd0,status}:m_rf_addr;

//inc dec
edg inc_edg(.clk(clk),.rst(rst),.y(inc),.p(inc_edge));
edg dec_edg(.clk(clk),.rst(rst),.y(dec),.p(dec_edge));
always @(posedge clk ) begin
    if(m_rf) begin
        if(inc_edge)
            m_addr<=m_addr+16'd1;
        else if(dec_edge)
            m_addr<=m_addr-16'd1;
    end
    else begin
        if(inc_edge)
            rf_addr<=rf_addr+16'd1;
        else if(dec_edge)
            rf_addr<=rf_addr-16'd1;
    end
end

endmodule

module edg(
    input y,rst,clk,
    output p
);
localparam edge_S0=2'd0;
localparam edge_S1=2'd1;
localparam edge_S2=2'd2;

reg [1:0]edge_state,edge_next_state;

//output logic
assign  p = (edge_state==edge_S1); 

//state logic
always @(posedge clk, posedge rst)
  if (rst) edge_state <= edge_S0;
  else edge_state <= edge_next_state; 

//next state logic
always @* begin 
  edge_next_state = edge_state;
  case (edge_state)
    edge_S0: if (y) edge_next_state = edge_S1;
            else edge_next_state = edge_S0;
    edge_S1: if (y) edge_next_state = edge_S2;
            else edge_next_state = edge_S0;
    edge_S2: if (y) edge_next_state = edge_S2;
            else edge_next_state = edge_S0;
    default: edge_next_state = edge_S0;
  endcase
end
endmodule