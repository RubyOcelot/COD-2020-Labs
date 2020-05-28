module cpu_multi_cycle	//单周期CPU
(input clk,			//时钟（上升沿有效）
input rst,				//异步复位，高电平有效
output [15:0]status,
output [31:0]m_data,rf_data,
input [15:0]m_rf_addr,
input [2:0]i_sel,
output reg [31:0]o_sel_data
);

//pipeline regs
reg [31:0]PC=32'd0;
reg [31:0]IF_ID_NPC=32'd0,IF_ID_IR=32'd0;
reg [31:0]ID_EX_NPC=32'd0,ID_EX_IR=32'd0,ID_EX_A=32'd0,ID_EX_B=32'd0,ID_EX_IMMI=32'd0;
reg [31:0]EX_MEM_NPC=32'd0,EX_MEM_ZF=32'd0,EX_MEM_Y=32'd0,EX_MEM_B=32'd0,EX_MEM_WA=32'd0;
reg [31:0]MEM_WB_MDR=32'd0,MEM_WB_Y=32'd0,MEM_WB_WA=32'd0;

//control regs
wire

wire [31:0]alu_result;
wire [31:0]write_reg_data,read_reg_data_1,read_reg_data_2;
wire [31:0]read_mem_data;
wire [31:0]alu_in_1,alu_in_2;
wire [4:0]write_reg_addr;
//WB
reg RegWrite,MemtoReg;
//M
reg Branch,MemRead,MemWrite;
wire PCSource;
//EX
reg RegDst,ALUSrc;
reg [2:0]ALUOp;


reg [2:0]ALUm;
wire [31:0]pc_jump,pc_next;
wire [31:0]ins_15_0_sext,ins_15_0_sext_shift_2;
wire [8:0]mem_addr;
wire [5:0]Op;

//dbg TODO
assign status={PCSource,PCwe,IorD,MemWrite,IRWrite,RegDst,MemtoReg,RegWrite,ALUm,ALUSrcA,ALUSrcB,ALUZero};
always @(*) begin
    case (i_sel)
        3'd1: o_sel_data=PC;
        3'd2: o_sel_data=IR;
        3'd3: o_sel_data=MemoryDataRegister;
        3'd4: o_sel_data=A;
        3'd5: o_sel_data=B;
        3'd6: o_sel_data=ALUOut;
        3'd7: o_sel_data=read_mem_data;//?
        default: begin end
    endcase
end

//reg file
register_file #(32) my_rf(.clk(clk), .ra0(IF_ID_IR[25:21]), .rd0(read_reg_data_1), .ra1(IF_ID_IR[20:16]), .rd1(read_reg_data_2), .wa(MEM_WB_WA), .we(RegWrite), .wd(write_reg_data),.dbgra(m_rf_addr[4:0]),.dbgrd(rf_data));

mux_1 #(5) write_register_addr_mux(.i_sel(RegDst),.num0(ID_EX_IR[20:16]),.num1(ID_EX_IR[15:11]),.o_m(write_reg_addr));
mux_1 #(32) write_register_data_mux(.i_sel(MemtoReg),.num0(MEM_WB_Y),.num1(MEM_WB_MDR),.o_m(write_reg_data));

//control
localparam IF=4'd0;
localparam ID=4'd1;
localparam MC=4'd2;
localparam MAR=4'd3;
localparam WBS=4'd4;
localparam MAW=4'd5;
localparam REX=4'd6;
localparam RRC=4'd7;
localparam BC=4'd8;
localparam JC=4'd9;
localparam IDLE=4'd10;
localparam IEX=4'd11;
localparam IRC=4'd12;

localparam LW=6'b100011;
localparam SW=6'b101011;
localparam ADD=6'b000000;
localparam ADDI=6'b001000;
localparam BEQ=6'b000100;
localparam J=6'b000010;

assign Op=IR[31:26];


always @(*) begin
    {RegWrite,MemtoReg,Branch,MemRead,MemWrite,RegDst,ALUOp,ALUSrc}=10'd0;
    if(!rst)
        case (IF_ID_IR[31:26])
            : 
            default: 
        endcase
end

//alu
mux_1 #(32) alu_in_1_mux(.i_sel(ALUSrcA),.num0(PC),.num1(A),.o_m(alu_in_1));
mux_2 #(32) alu_in_2_mux(.i_sel(ALUSrcB),.num0(B),.num1(32'd4),.num2(ins_15_0_sext),.num3(ins_15_0_sext_shift_2),.o_m(alu_in_2));
assign ins_15_0_sext={{16{IR[15]}},IR[15:0]};
assign ins_15_0_sext_shift_2={ins_15_0_sext[29:0],2'd0};

alu #(32) arith_ALU(.y(alu_result),.zf(ALUZero),.a(alu_in_1),.b(alu_in_2),.m(ALUm));

//alu control

localparam m_ADD=3'b000;
localparam m_SUB=3'b001;
localparam m_AND=3'b010;
localparam m_OR =3'b011;
localparam m_XOR=3'b100;

always @(*) begin
    case (ALUOp)
        3'b00:ALUm=m_ADD;
        3'b01:ALUm=m_SUB;
        3'b10:begin
            case (IR[5:0])
                6'b100000:ALUm=m_ADD; 
                default: begin
                    
                end
            endcase
        end
        default: begin
            
        end
    endcase
end

//TODO MemRead
//ins&data memory
mux_1 #(9) mem_addr_mux(.i_sel(IorD),.num0(PC[10:2]),.num1(ALUOut[10:2]),.o_m(mem_addr));
dist_mem I_D_ram(.clk(clk), .we(MemWrite), .d(B), .a(mem_addr), .spo(read_mem_data), .dpra(m_rf_addr[10:2]), .dpo(m_data));

//pc mux
mux_2 #(32) pc_mux(.i_sel(PCSource),.num0(alu_result),.num1(ALUOut),.num2(pc_jump),.o_m(pc_next));
assign pc_jump={PC[31:28],IR[25:0],2'd0};

//pc
assign PCwe=PCWrite|(ALUZero&PCWriteCond);
always @(posedge clk or posedge rst) begin
    if(rst) begin
        PC<=32'd0;
    end
    else
        if(PCwe)
            PC<=pc_next;
end

//IR
always @(posedge clk or posedge rst) begin
    if(rst) begin
        IR<=32'd0;
    end
    else
        if(IRWrite)
            IR<=read_mem_data;
end

//other reg
always @(posedge clk or posedge rst) begin
    if(rst) begin
        MemoryDataRegister<=32'd0;
        A<=32'd0;
        B<=32'd0;
        ALUOut<=32'd0;
    end
    else begin
        MemoryDataRegister<=read_mem_data;
        A<=read_reg_data_1;
        B<=read_reg_data_2;
        ALUOut<=alu_result;
    end
end

endmodule
