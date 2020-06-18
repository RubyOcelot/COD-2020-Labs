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
reg [31:0]EX_MEM_NPC=32'd0,EX_MEM_Y=32'd0,EX_MEM_B=32'd0;
reg [31:0]MEM_WB_MDR=32'd0,MEM_WB_Y=32'd0;
reg EX_MEM_ZF=1'd0;
reg [4:0]EX_MEM_WA=5'd0,MEM_WB_WA=5'd0;


//control regs
reg [1:0]ID_EX_WB=2'd0,EX_MEM_WB=2'd0,MEM_WB_WB=2'd0;
reg [2:0]ID_EX_M=3'd0,EX_MEM_M=3'd0;
reg [4:0]ID_EX_EX=5'd0;

wire [1:0]wb_wire;
wire [2:0]m_wire;
wire [4:0]ex_wire;

//
wire [31:0]alu_result;
wire [31:0]write_reg_data,read_reg_data_1,read_reg_data_2;
wire [31:0]read_mem_data;
wire [31:0]alu_in_1,alu_in_2;
wire [4:0]write_reg_addr;


wire RegWrite,MemtoReg;
wire Branch,MemRead,MemWrite;
wire PCSrc;
reg RegDst,ALUSrc;
reg [2:0]ALUOp;
reg [2:0]ALUm;
wire [31:0]instruction;
wire [31:0]pc_plus,pc_next;

//dbg TODO
/*
assign status={PCSrc,PCwe,IorD,MemWrite,IRWrite,RegDst,MemtoReg,RegWrite,ALUm,ALUSrcA,ALUSrcB,Zero};
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
end*/

//instruction rom
dist_rom ins_rom(.a(pc[9:2]), .spo(instruction));

//reg file
register_file #(32) my_rf(.clk(clk), .ra0(IF_ID_IR[25:21]), .rd0(read_reg_data_1), .ra1(IF_ID_IR[20:16]), .rd1(read_reg_data_2), .wa(MEM_WB_WA), .we(RegWrite), .wd(write_reg_data),.dbgra(m_rf_addr[4:0]),.dbgrd(rf_data));

mux_1 #(5) write_register_addr_mux(.i_sel(RegDst),.num0(ID_EX_IR[20:16]),.num1(ID_EX_IR[15:11]),.o_m(write_reg_addr));
mux_1 #(32) write_register_data_mux(.i_sel(MemtoReg),.num0(MEM_WB_Y),.num1(MEM_WB_MDR),.o_m(write_reg_data));

//control
//opcode
localparam LW   =   6'b100011;
localparam SW   =   6'b101011;
localparam ADD  =   6'b000000;
localparam ADDI =   6'b001000;
localparam BEQ  =   6'b000100;
localparam J    =   6'b000010;


always @(*) begin
    {wb_wire,m_wire,ex_wire}=10'd0;
    if(!rst)
        case (IF_ID_IR[31:26])
            LW  :begin
                {wb_wire,m_wire,ex_wire}={1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,3'b,1'b1};
            end
            SW  :begin
                {wb_wire,m_wire,ex_wire}={1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,3'b,1'b1};
            end
            ADD :begin
                {wb_wire,m_wire,ex_wire}={1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,3'b,1'b0};
            end
            ADDI:begin
                {wb_wire,m_wire,ex_wire}={1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,3'b,1'b1};
            end
            BEQ :begin
                {wb_wire,m_wire,ex_wire}={1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,3'b,1'b0};
            end
            J   :begin
                {wb_wire,m_wire,ex_wire}={1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,3'b,1'b1};
            end
            default: 
        endcase
end

assign {RegDst,ALUOp,ALUSrc}=ID_EX_EX;
assign {Branch,MemRead,MemWrite}=EX_MEM_M;
assign {RegWrite,MemtoReg}=MEM_WB_WB;

//alu
mux_1 #(32) alu_in_2_mux(.i_sel(ALUSrc),.num0(ID_EX_B),.num1(ID_EX_IMMI),.o_m(alu_in_2));
assign ins_15_0_sext={{16{IR[15]}},IR[15:0]};
assign ins_15_0_sext_shift_2={ins_15_0_sext[29:0],2'd0};

alu #(32) arith_ALU(.y(alu_result),.zf(Zero),.a(ID_EX_A),.b(alu_in_2),.m(ALUm));

//alu control
//TODO
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
            case (ID_EX_IR[5:0])
                6'b100000:ALUm=m_ADD; 
                default: begin
                    ALUm=3'b101;
                end
            endcase
        end
        default: begin
            
        end
    endcase
end

//TODO MemRead
//data memory
dist_mem data_ram(.clk(clk), .we(MemWrite), .d(EX_MEM_B), .a(EX_MEM_Y[9:2]), .spo(read_mem_data), .dpra(m_rf_addr[9:2]), .dpo(m_data));

//pc mux
mux_1 #(32) pc_mux(.i_sel(PCSrc),.num0(pc_plus),.num1(EX_MEM_NPC),.o_m(pc_next));
assign pc_plus=PC+32'd4;

//pc
always @(posedge clk or posedge rst) begin
    if(rst) begin
        PC<=32'd0;
    end 
    else begin
        PC<=pc_next;
    end
end

//IF-ID
always @(posedge clk or posedge rst) begin
    if(rst) begin
        IF_ID_NPC<=32'd0;
        IF_ID_IR<=32'd0;
    end
    else begin
        IF_ID_NPC<=pc_plus;
        IF_ID_IR<=instruction;
    end
end

//ID-EX
always @(posedge clk or posedge rst) begin
    if(rst) begin
        ID_EX_NPC<=32'd0;
        ID_EX_IR<=32'd0;
        ID_EX_A<=32'd0;
        ID_EX_B<=32'd0;
        ID_EX_IMMI<=32'd0;
        ID_EX_WB<=2'd0;
        ID_EX_M<=3'd0;
        ID_EX_EX<=5'd0;
    end
    else begin
        ID_EX_NPC<=IF_ID_NPC;
        ID_EX_IR<=IF_ID_IR;
        ID_EX_A<= read_reg_data_1;
        ID_EX_B<= read_reg_data_2;
        ID_EX_IMMI<={{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
        ID_EX_WB<=wb_wire;
        ID_EX_M<=m_wire;
        ID_EX_EX<=ex_wire;
    end
end

//EX-MEM
always @(posedge clk or posedge rst) begin
    if(rst) begin
        EX_MEM_NPC<=32'd0;
        EX_MEM_ZF<=1'd0;
        EX_MEM_Y<=32'd0;
        EX_MEM_B<=32'd0;
        EX_MEM_WA<=5'd0;
        EX_MEM_WB<=2'd0;
        EX_MEM_M<=3'd0;
    end
    else begin
        EX_MEM_NPC<=ID_EX_NPC+{ID_EX_IMMI[29:0],2'd0};
        EX_MEM_ZF<=Zero;
        EX_MEM_Y<=alu_result;
        EX_MEM_B<=ID_EX_B;
        EX_MEM_WA<=write_reg_addr;
        EX_MEM_WB<=ID_EX_WB;
        EX_MEM_M<=ID_EX_M;
    end
end
assign PCSrc=Branch&EX_MEM_ZF;

//MEM-WB
always @(posedge clk or posedge rst) begin
    if(rst) begin
        MEM_WB_MDR<=32'd0;
        MEM_WB_Y<=32'd0;
        MEM_WB_WA<=5'd0;
        MEM_WB_WB<=2'd0;
    end
    else begin
        MEM_WB_MDR<=read_mem_data;
        MEM_WB_Y<=EX_MEM_Y;
        MEM_WB_WA<=EX_MEM_WA;
        MEM_WB_WB<=EX_MEM_WB;
    end
end
endmodule
