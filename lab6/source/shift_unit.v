module shift_unit
(
    input [31:0]i_data,
    input [4:0]shamt,
    input [1:0]type,
    output reg [31:0]o_data
);
always@(*)begin
    case(type)
        2'b00:
            case (shamt)
                32'd0   :o_data=i_data;
                32'd1   :o_data={i_data[30:0],1'd0};
                32'd2   :o_data={i_data[29:0],2'd0};
                32'd3   :o_data={i_data[28:0],3'd0};
                32'd4   :o_data={i_data[27:0],4'd0};
                32'd5   :o_data={i_data[26:0],5'd0};
                32'd6   :o_data={i_data[25:0],6'd0};
                32'd7   :o_data={i_data[24:0],7'd0};
                32'd8   :o_data={i_data[23:0],8'd0};
                32'd9   :o_data={i_data[22:0],9'd0};
                32'd10  :o_data={i_data[21:0],10'd0};
                32'd11  :o_data={i_data[20:0],11'd0};
                32'd12  :o_data={i_data[19:0],12'd0};
                32'd13  :o_data={i_data[18:0],13'd0};
                32'd14  :o_data={i_data[17:0],14'd0};
                32'd15  :o_data={i_data[16:0],15'd0};
                32'd16  :o_data={i_data[15:0],16'd0};
                32'd17  :o_data={i_data[14:0],17'd0};
                32'd18  :o_data={i_data[13:0],18'd0};
                32'd19  :o_data={i_data[12:0],19'd0};
                32'd20  :o_data={i_data[11:0],20'd0};
                32'd21  :o_data={i_data[10:0],21'd0};
                32'd22  :o_data={i_data[9:0],22'd0};
                32'd23  :o_data={i_data[8:0],23'd0};
                32'd24  :o_data={i_data[7:0],24'd0};
                32'd25  :o_data={i_data[6:0],25'd0};
                32'd26  :o_data={i_data[5:0],26'd0};
                32'd27  :o_data={i_data[4:0],27'd0};
                32'd28  :o_data={i_data[3:0],28'd0};
                32'd29  :o_data={i_data[2:0],29'd0};
                default begin
                    o_data=i_data;
                end
            endcase
        2'b10:
            case (shamt)
                32'd0   :o_data=i_data;
                32'd1   :o_data={1'd0,i_data[31:1]};
                default begin
                    o_data=i_data;
                end
            endcase
        //TODO
    endcase
end
endmodule