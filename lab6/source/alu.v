module alu
#(parameter WIDTH = 4) 	//数据宽度
(output [WIDTH-1:0] y, 		//运算结果
output zf, 					//零标志
output cf, 					//进位/借位标志
output of, 					//溢出标志
output sf,                  //最高位
input [WIDTH-1:0] a, b,		//两操作数
input [2:0]m						//操作类型
);
reg cf_r,of_r;
reg [WIDTH-1:0]y_r;
assign  zf=~|y;
assign  y=y_r;
assign  cf=cf_r;
assign  of=of_r;
assign  sf=y[WIDTH-1:WIDTH-1];

localparam ADD=3'b000;
localparam SUB=3'b001;
localparam AND=3'b010;
localparam  OR=3'b011;
localparam XOR=3'b100;

always@(*) begin
    case (m)
        ADD: begin 
            {cf_r, y_r} = a + b;
            of_r = (~a[WIDTH-1] & ~b[WIDTH-1] & y[WIDTH-1]) | (a[WIDTH-1] & b[WIDTH-1] & ~y[WIDTH-1]) ;
        end
        SUB: begin 
            {cf_r, y_r} = a - b;
            of_r = (~a[WIDTH-1] & b[WIDTH-1] & y[WIDTH-1]) | (a[WIDTH-1] & ~b[WIDTH-1] & ~y[WIDTH-1]) ;
        end
        AND: begin 
            y_r=a&b;
        end
         OR: begin 
            y_r=a|b;
        end
        XOR: begin 
            y_r=a^b;
        end
        default: begin
            {cf_r, of_r, y_r} = 0;
        end
    endcase
end

endmodule