module bus	//单周期CPU
(input clk,			//时钟（上升沿有效）
input rst,				//异步复位，高电平有效
input we,
input re,
input [31:0]d,
input [7:0]a,
output [31:0]spo,
input input_flag,
input [31:0]input_data,
output output_flag,
output [31:0]output_data
);
reg input_flag_r=1'b0,output_flag_r=1'b0;
reg [31:0]input_data_r=32'd0,output_data_r=32'd0;

//IO
always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_flag_r<=1'b0;
        output_flag_r<=1'b0;
    end
    else begin
        if (input_flag) begin
            input_flag_r<=1'b1;
            input_data_r<=input_data;
        end
    end
end

localparam OUT_FLAG =8'hfe;
localparam OUT_DATA =8'hff;
localparam IN_FLAG  =8'hfc;
localparam IN_DATA  =8'hfd;
//1 is busy 0 is avaliable

reg [31:0]spo_r=32'd0,dpo_r=32'd0;
wire [31:0]spo_mem,dpo_mem;
dist_ram data_ram(.clk(clk), .we(we), .d(d), .a(a), .spo(spo_mem));
assign spo=spo_r;
assign dpo=dpo_r;
always @(*) begin
    case (a)
        OUT_FLAG:begin
            spo_r=(output_flag_r==1'b1)?32'h80000000:32'h0;
        end 
        OUT_DATA:begin
            spo_r=output_data_r;
        end 
        IN_FLAG:begin
            spo_r=(input_flag_r==1'b1)?32'h80000000:32'h0;
        end 
        IN_DATA:begin
            spo_r=input_data_r;
        end 
        default: begin
            spo_r=spo_mem;
        end
    endcase
    case (dpra)
        default: begin
            dpo_r=dpo_mem;
        end
    endcase
end

//setflag
assign output_flag=output_flag_r;
assign output_data=output_data_r;
always @(posedge clk) begin
    output_flag_r<=1'b0;
    if(we)
        case (a)
            OUT_DATA:begin
                output_data_r<=d;
                output_flag_r<=1'b1;
            end 
            default: begin
            end
        endcase
    if(re)
        case (a)
            IN_DATA:begin
                input_flag_r<=1'b0;
            end 
            default: begin
            end
        endcase
end
endmodule