module fifo
(input clk, rst,		//时钟（上升沿有效）、异步复位（高电平有效）
input [7:0] din,		//入队列数据
input en_in, 		//入队列使能，高电平有效
input en_out,		//出队列使能，高电平有效
output [7:0] dout, 	//出队列数据
output [4:0] count	//队列数据计数
);

wire edge_en_in,edge_en_out;
edg edg_in(.y(en_in),.rst(rst),.clk(clk),.p(edge_en_in));
edg edg_out(.y(en_out),.rst(rst),.clk(clk),.p(edge_en_out));

wire wait_in,wait_out;
wire finish_in,finish_out;
wai wai_in(.i_start(edge_en_in),.rst(rst),.clk(clk),.i_finish(finish_in),.o_status(wait_in));
wai wai_out(.i_start(edge_en_out),.rst(rst),.clk(clk),.i_finish(finish_out),.o_status(wait_out));

localparam ctrl_wait=3'd0;
localparam ctrl_in_1=3'd2;
localparam ctrl_in_2=3'd3;
localparam ctrl_out_1=3'd5;
localparam ctrl_out_2=3'd6;

reg [4:0]count_r=5'd0;
assign count=count_r;

reg [2:0]ctrl_state=ctrl_wait,ctrl_next_state;

reg en,we;
reg [3:0]head=4'd0,tail=4'd0;

assign finish_in=(ctrl_state==ctrl_in_2);
assign finish_out=(ctrl_state==ctrl_out_2);

always @(posedge clk,posedge rst) begin
    if(rst) begin
        ctrl_state<=ctrl_wait;
        en<=1'b0;
        we<=1'b0;
        head<=4'd0;
        tail<=4'd0;
        count_r<=5'd0;
    end
    else ctrl_state<=ctrl_next_state;
end

always@* begin
    ctrl_next_state=ctrl_state;
    case(ctrl_state)
        ctrl_wait:begin
            if(wait_in&(count_r<16))
                ctrl_next_state=ctrl_in_1;
            else begin
                if(wait_out&(count_r>0))
                    ctrl_next_state=ctrl_out_1;
            end
        end
        ctrl_in_1:begin
            ctrl_next_state=ctrl_in_2;
        end
        ctrl_in_2:begin
            ctrl_next_state=ctrl_wait;
        end
        ctrl_out_1:begin
            ctrl_next_state=ctrl_out_2;
        end
        ctrl_out_2:begin
            ctrl_next_state=ctrl_wait;
        end
    endcase
end 

reg [7:0]dout_r;
wire [7:0]dout_w;
reg [3:0]a;
blk_mem_gen_0 my_ram(.clka(clk), .wea(we), .dina(din), .addra(a), .douta(dout_w), .ena(en));

assign dout=dout_r;
//in&out
always @(posedge clk ) begin
    case(ctrl_state)
        ctrl_in_1:begin
            we<=1'b1;
            en<=1'b1;
            a<=tail;
        end
        ctrl_in_2:begin
            we<=1'b0;
            en<=1'b0;
            tail<=tail+4'd1;
            count_r<=count_r+5'd1;
        end
        ctrl_out_1:begin
            we<=1'b0;
            en<=1'b1;
            a<=head;
        end
        ctrl_out_2:begin
            we<=1'b0;
            en<=1'b0;
            dout_r<=dout_w;
            head<=head+4'd1;
            count_r<=count_r-5'd1;
        end
        default:begin
        end
    endcase
end

endmodule


//edge
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

module wai(
    input i_start,rst,clk,i_finish,
    output o_status
);
localparam wait_S0=1'd0;
localparam wait_S1=1'd1;
reg wait_state,wait_next_state;
assign  o_status = (wait_state==wait_S1); 

always @(posedge clk, posedge rst)
  if (rst) wait_state <= wait_S0;
  else wait_state <= wait_next_state; 

always @* begin 
  wait_next_state = wait_state;
  case (wait_state)
    wait_S0: if (i_start) wait_next_state = wait_S1;
            else wait_next_state = wait_S0;
    wait_S1: if (i_finish) wait_next_state = wait_S0;
            else wait_next_state = wait_S1;
    default: wait_next_state = wait_S0;
  endcase
end
endmodule
