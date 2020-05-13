module cpu_one_cycle	//单周期CPU
(input clk,			//时钟（上升沿有效）
input rst				//异步复位，高电平有效
);

reg [31:0]pc;

wire [31:0]instruction,alu_result;
wire [31:0]write_reg_data,read_reg_data_1,read_reg_data_2;
wire [31:0]read_mem_data;
wire [31:0]alu_in_2;
wire zero;
wire [4:0]write_reg_addr;
reg regdst,alusrc,aluop,memwrite,memread,memtoreg,branch,jump,regwrite;
wire [2:0]alu_control;
wire pc_mux_1_sel;
wire [31:0]pc_plus_4,pc_jump,pc_br,pc_next;

//instruction rom
dist_rom ins_rom(.clk(clk), .a(a), .spo(instruction));

//reg file
register_file #(32) my_rf(.clk(clk), .ra0(instruction[25:21]), .rd0(read_reg_data_1), .ra1(instruction[20:16]), .rd1(read_reg_data_2), .wa(write_reg_addr), .we(regwrite), .wd(write_reg_data));

mux #(5) write_register_addr_mux(.i_sel(regdst),.num0(instruction[20:16]),.num1(instruction[15:11]),.o_m(write_reg_addr));
mux #(32) write_register_data_mux(.i_sel(memtoreg),.num0(alu_result),.num1(read_mem_data),.o_m(write_reg_data));

//control
always @(*) begin
    {regdst,alusrc,aluop,memwrite,memread,memtoreg,branch,jump,regwrite}=9'd0;
    case (instruction[31:26])
        6'b000000: begin
            if(instruction[5:0]==6'b100000) begin//add
                regwrite=1'd1;
                aluop=1'd1;
                regdst=1'd1;
                alusrc=1'd0;
                memtoreg=1'd0;
            end
        end 
        6'b001000: begin//addi
            regwrite=1'd1;
            aluop=1'd1;
            regdst=1'd0;
            alusrc=1'd1;
            memtoreg=1'd0;
        end
        6'b100011: begin//lw
            regwrite=1'd1;
            aluop=1'd1;
            regdst=1'd0;
            alusrc=1'd1;
            memread=1'd1;
            memtoreg=1'd1;
        end
        6'b101011: begin//sw
            regwrite=1'd0;
            aluop=1'd1;
            alusrc=1'd1;
            memwrite=1'd1;
        end
        6'b000100: begin//beq
            jump=1'd0;
            aluop=1'd1;
            alusrc=1'd0;
        end
        6'b000010: begin//j
            jump=1'd1;
        end
        default: begin end
    endcase
end

mux #(32) alu_in_2_mux(.i_sel(alusrc),.num0(read_reg_data_2),.num1(instruction[15:11]),.o_m(alu_in_2));

alu #(32) arith_ALU(.y(alu_result),.zf(zero),.a(read_reg_data_1),.b(alu_in_2),.m(alu_control));

//alu contol
always @(*) begin
    if(aluop)
        case (instruction[5:0])
            6'b000000: begin
                if(instruction[5:0]==6'b100000) begin//add
                    alu_control=3'b000;
                end
            end
            6'b000100: begin
                alu_control=3'b001;
            end
            default: begin
                
            end
        endcase
    else

end

//data memory
dist_ram data_ram(.clk(clk), .we(memwrite), .d(read_reg_data_2), .a(alu_result), .spo(read_mem_data));

//pc mux
mux #(32) pc_mux_1(.i_sel(pc_mux_1_sel),.num0(pc_plus_4),.num1(pc_br),.o_m(pc_mux_1_out));
assign pc_mux_1_sel=branch&zero;
assign pc_plus_4=pc+32'd4;
assign pc_br=pc_plus_4+{16{instruction[15]},instruction[15:0]};

mux #(32) pc_mux_2(.i_sel(jump),.num0(pc_mux_1_out),.num1(pc_jump),.o_m(pc_next));
assign pc_jump={pc_plus_4[31:26],instruction[25:0]};

//pc
always @(posedge clk or posedge rst) begin
    if(rst) begin
        pc<=32'd0;
    end
    else
        pc<=pc_next;
end

endmodule
