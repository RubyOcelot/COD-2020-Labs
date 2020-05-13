module debug_unit(
    input clk,succ,step,rst,
    input [2:0]sel,
    input m_rf,
    input inc,
    input dec,
    output [15:0]led,
    output [7:0]seg_data,
    output [7:0]seg_sel
);

wire cpu_clk;
reg run=0;
wire step_edge;
wire [11:0]status; 
wire [31:0]m_data,rf_data;
wire [15:0]m_rf_addr;
reg [15:0]m_addr=0,rf_addr=0;
wire inc_edge,dec_edge;
wire [31:0]selected_data,seg_num;


edg step_edg(.clk(clk),.rst(rst),.y(step),.p(step_edge));
always @(posedge clk ) begin
    if(rst)begin
        run<=1'd0;
        m_addr=0;
        rf_addr=0;
    end
    else 
        if(succ|step)
            run<=1'd1;
        else
            run<=1'd0;
end

//run
assign cpu_clk=clk&run;
cpu_one_cycle my_cpu(.clk(cpu_clk), .rst(rst),.status(status),.m_data(m_data),.rf_data(rf_data),.m_rf_addr(m_rf_addr),.i_sel(sel),.o_sel_data(selected_data));


assign m_rf_addr=(m_rf)?m_addr:rf_addr;
//led
assign led=(sel>3'd0)?{4'd0,status}:m_rf_addr;

//inc dec
edg inc_edg(.clk(clk),.rst(rst),.y(inc),.p(inc_edge));
edg dec_edg(.clk(clk),.rst(rst),.y(dec),.p(dec_edge));
always @(posedge clk ) begin
    if(m_rf) begin
        if(inc)
            m_addr<=m_addr+16'd1;
        else if(dec)
            m_addr<=m_addr-16'd1;
    end
    else begin
        if(inc)
            rf_addr<=rf_addr+16'd1;
        else if(dec)
            rf_addr<=rf_addr-16'd1;
    end
end

//seg
assign seg_num=(sel>3'd0)?selected_data:((m_rf)?m_data:rf_data);

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