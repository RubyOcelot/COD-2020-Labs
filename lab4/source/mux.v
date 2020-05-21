module mux_1
#(parameter N = 32)
(
    input i_sel,
    input [N-1:0]num0,num1,
    output [N-1:0]o_m
);
reg [N-1:0]m_r;
assign o_m=m_r;
always@(*)begin
    case (i_sel)
        1'd0: m_r=num0;
        1'd1: m_r=num1;
        default: begin end
    endcase
end
endmodule 

module mux_2
#(parameter N = 32)
(
    input [1:0]i_sel,
    input [N-1:0]num0,num1,num2,num3,
    output [N-1:0]o_m
);
reg [N-1:0]m_r;
assign o_m=m_r;
always@(*)begin
    case (i_sel)
        2'd0: m_r=num0;
        2'd1: m_r=num1;
        2'd2: m_r=num2;
        2'd3: m_r=num3;
        default: begin end
    endcase
end
endmodule