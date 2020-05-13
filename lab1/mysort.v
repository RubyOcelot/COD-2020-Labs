module sort
#(parameter N = 4) 			//数据宽度
(output [N-1:0] s0, s1, s2, s3, 	//排序后的四个数据（递增）
output reg done, 				//排序结束标志
input [N-1:0] x0, x1, x2, x3,	//原始输入数据
input clk, rst				//时钟（上升沿有效）、复位（高电平有效）
);
reg [2:0]current_state,next_state;
localparam LOAD=3'd0;
localparam CX01F=3'd1;
localparam CX12F=3'd2;
localparam CX23F=3'd3;
localparam CX01S=3'd4;
localparam CX12S=3'd5;
localparam CX01T=3'd6;
localparam HLT=3'd7;

always @(posedge clk, posedge rst)
	if (rst) current_state <= LOAD;
	else
	   current_state <= next_state;
always @(*) begin
   case (current_state)
      LOAD:  next_state = CX01F;
      CX01F: next_state = CX12F;
      CX12F: next_state = CX23F;
      CX23F: next_state = CX01S;
      CX01S: next_state = CX12S;
      CX12S: next_state = CX01T;
      CX01T: next_state = HLT;
      HLT: next_state = HLT;
      default: next_state = HLT;
   endcase
end

reg [11:0] m;
reg [3:0]  en;
wire [3:0]  i0, i1, i2, i3, r0, r1, r2, r3, i4, i5, y;
wire of, sf, ex_sig;
assign sf=y[3];
assign ex_sig=sf^of;
localparam SUB=3'b001;
// Data Path
register    R0 (i0, en[0], rst, clk, r0), 
		    R1 (i1, en[1], rst, clk, r1), 
	        R2 (i2, en[2], rst, clk, r2),
	        R3 (i3, en[3], rst, clk, r3);
alu #(4) ALU (.a(i5), .b(i4), .m(SUB), .of(of), .y(y));
mux     M0 (m[1:0], x0, 4'b0, r1, i0), 
        M1 (m[3:2], x1, r0,   r2, i1),
        M2 (m[5:4], x2, r1,   r3, i2),
        M3 (m[7:6], x3, r2, 4'b0, i3),
        M4 (m[9:8],   r0, r1, r2, i4),
        M5 (m[11:10], r1, r2, r3, i5);

assign {s0,s1,s2,s3}={r0,r1,r2,r3};

always @(*) begin
    {m, en, done} = 17'h0;
    case (current_state)
        LOAD: {m, en} = {12'b0, 4'b1111};
        CX01F, CX01S, CX01T: begin 
            {m, en} = {2'd0, 2'd0, 2'd0, 2'd0, 2'd1, 2'd2, 1'd0, 1'd0, ex_sig, ex_sig};
        end
        CX12F, CX12S: begin 
            {m, en} = {2'd1, 2'd1, 2'd0, 2'd1, 2'd2, 2'd0, 1'd0, ex_sig, ex_sig, 1'd0};
        end
        CX23F: begin
            {m, en} = {2'd2, 2'd2, 2'd1, 2'd2, 2'd0, 2'd0, ex_sig, ex_sig, 1'd0, 1'd0};
        end
        HLT: done = 1;
        default:begin end
    endcase
end


endmodule

module register(
    input [3:0]i_num,
    input en,rst,clk,
    output [3:0]o_num
);
reg [3:0]num_r;
assign o_num=num_r;
always @(posedge clk) begin
    if(rst) begin
        num_r<=4'b0;
    end
    else if(en)begin
        num_r<=i_num;
    end
end

endmodule

module mux(
    input [1:0]i_m,
    input [3:0]num0,num1,num2,
    output [3:0]o_m
);
reg [3:0]m_r;
assign o_m=m_r;
always@(*)begin
    case (i_m)
        2'd0: m_r=num0;
        2'd1: m_r=num1;
        2'd2: m_r=num2;
        default: begin end
    endcase
end
endmodule