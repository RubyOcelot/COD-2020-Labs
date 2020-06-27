module cpu_pipeline	//单周期CPU
(input clk,			//时钟（上升沿有效）
input rst,				//异步复位，高电平有效
output [31:0]m_data,rf_data,
input [15:0]m_rf_addr,
input input_flag,
input [31:0]input_data,
output output_flag,
output [31:0]output_data,
input output_finish_flag
);


//pipeline regs
reg [31:0]PC=32'd0;
reg [31:0]IF_ID_NPC=32'd0,IF_ID_IR=32'd0;
reg [31:0]ID_EX_NPC=32'd0,ID_EX_IR=32'd0,ID_EX_A=32'd0,ID_EX_B=32'd0,ID_EX_IMMI=32'd0;
reg [31:0]EX_MEM_Y=32'd0,EX_MEM_B=32'd0;
reg [31:0]MEM_WB_MDR=32'd0,MEM_WB_Y=32'd0;
reg EX_MEM_ZF=1'd0;
reg [4:0]EX_MEM_WA=5'd0,MEM_WB_WA=5'd0;


//control regs
reg [1:0]ID_EX_WB=2'd0,EX_MEM_WB=2'd0,MEM_WB_WB=2'd0;
reg [2:0]ID_EX_M=3'd0,EX_MEM_M=3'd0;
reg [5:0]ID_EX_EX=6'd0;
reg EX_MEM_J=1'd0;

reg [1:0]wb_ctrl;
reg [2:0]m_ctrl;
reg [5:0]ex_ctrl;

//
wire [31:0]alu_result;
wire [31:0]write_reg_data,read_reg_data_1,read_reg_data_2;
wire [31:0]read_mem_data;
wire [31:0]real_reg_a,real_reg_b,alu_in_2;
wire [4:0]write_reg_addr;


wire RegWrite,MemtoReg;
wire Jump,Branch,MemRead,MemWrite;
reg [1:0]PCSrc;
wire RegDst,ALUSrc;
wire [2:0]ALUOp;
reg [2:0]ALUm;
wire Zero;
wire [31:0]instruction;
wire [31:0]pc_plus,pc_next;
wire [31:0]pc_br,pc_j;

//forward
reg [1:0]forward_sel_a=2'd0,forward_sel_b=2'd0;

//branch sig
reg clear_IF_ID=1'b0,clear_ID_EX=1'b0;

//opcode
localparam LW   =   6'b100011;
localparam SW   =   6'b101011;
localparam ADD  =   6'b000000;
localparam ADDI =   6'b001000;
localparam BEQ  =   6'b000100;
localparam J    =   6'b000010;

//branch control unit
always @(*) begin
    clear_IF_ID=1'b0;
    clear_ID_EX=1'b0;
    PCSrc=2'b0;
    if(ID_EX_IR[31:26]==BEQ&Zero)begin
        clear_IF_ID=1'b1;
        clear_ID_EX=1'b1;
        PCSrc=2'd2;
    end
    else if(IF_ID_IR[31:26]==J) begin
        clear_IF_ID=1'b1;
        PCSrc=2'd1;
    end
end


//forwarding unit
mux_2 #(32) forward_mux_a(.i_sel(forward_sel_a),.num0(ID_EX_A),.num1(write_reg_data),.num2(EX_MEM_Y),.num3(read_mem_data),.o_m(real_reg_a));
mux_2 #(32) forward_mux_b(.i_sel(forward_sel_b),.num0(ID_EX_B),.num1(write_reg_data),.num2(EX_MEM_Y),.num3(read_mem_data),.o_m(real_reg_b));
always @(*) begin
    if(ID_EX_IR[25:21]==5'd0)begin
        forward_sel_a=2'd0;
    end
    else if((EX_MEM_WA==ID_EX_IR[25:21])&&(EX_MEM_WB==2'b11))begin
        forward_sel_a=2'd3;
    end
    else if(EX_MEM_WA==ID_EX_IR[25:21]&&EX_MEM_WB==2'b10)begin
        forward_sel_a=2'd2;
    end
    else if(MEM_WB_WA==ID_EX_IR[25:21]&&MEM_WB_WB[1:1]==1'b1)begin
        forward_sel_a=2'd1;
    end
    else begin
        forward_sel_a=2'd0;
    end
end

always @(*) begin
    if(ID_EX_IR[20:16]==5'd0)begin
        forward_sel_b=2'd0;
    end
    else if(EX_MEM_WA==ID_EX_IR[20:16]&&EX_MEM_WB==2'b11)begin
        forward_sel_b=2'd3;
    end
    else if(EX_MEM_WA==ID_EX_IR[20:16]&&EX_MEM_WB==2'b10)begin
        forward_sel_b=2'd2;
    end
    else if(MEM_WB_WA==ID_EX_IR[20:16]&&MEM_WB_WB[1:1]==1'b1)begin
        forward_sel_b=2'd1;
    end
    else begin
        forward_sel_b=2'd0;
    end
end


//instruction rom
dist_rom ins_rom(.a(PC[9:2]), .spo(instruction));

//reg file
register_file #(32) my_rf(.clk(clk), .ra0(IF_ID_IR[25:21]), .rd0(read_reg_data_1), .ra1(IF_ID_IR[20:16]), .rd1(read_reg_data_2), .wa(MEM_WB_WA), .we(RegWrite), .wd(write_reg_data),.dbgra(m_rf_addr[4:0]),.dbgrd(rf_data));

mux_1 #(5) write_register_addr_mux(.i_sel(RegDst),.num0(ID_EX_IR[20:16]),.num1(ID_EX_IR[15:11]),.o_m(write_reg_addr));
mux_1 #(32) write_register_data_mux(.i_sel(MemtoReg),.num0(MEM_WB_Y),.num1(MEM_WB_MDR),.o_m(write_reg_data));

//control
//ALUOp
localparam ALUOP_ADD      =3'd3;
localparam ALUOP_SUB      =3'd1;
localparam ALUOP_FUNCT    =3'd2;
localparam ALUOP_NOP      =3'd0;

always @(*) begin
    {wb_ctrl,m_ctrl,ex_ctrl}=11'd0;
    if(!rst)
        case (IF_ID_IR[31:26])
            LW  :begin
                {wb_ctrl,m_ctrl,ex_ctrl}={1'b1,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,ALUOP_ADD,1'b1};
            end
            SW  :begin
                {wb_ctrl,m_ctrl,ex_ctrl}={1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,ALUOP_ADD,1'b1};
            end
            ADD :begin
                {wb_ctrl,m_ctrl,ex_ctrl}={1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,ALUOP_FUNCT,1'b0};
            end
            ADDI:begin
                {wb_ctrl,m_ctrl,ex_ctrl}={1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,ALUOP_ADD,1'b1};
            end
            BEQ :begin
                {wb_ctrl,m_ctrl,ex_ctrl}={1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,ALUOP_SUB,1'b0};
            end
            J   :begin
                {wb_ctrl,m_ctrl,ex_ctrl}={1'b0,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,ALUOP_NOP,1'b1};
            end
            default: begin
            
            end
        endcase
end

assign {Jump,RegDst,ALUOp,ALUSrc}=ID_EX_EX;
assign {Branch,MemRead,MemWrite}=EX_MEM_M;
assign {RegWrite,MemtoReg}=MEM_WB_WB; 

//alu
mux_1 #(32) alu_in_2_mux(.i_sel(ALUSrc),.num0(real_reg_b),.num1(ID_EX_IMMI),.o_m(alu_in_2));

alu #(32) arith_ALU(.y(alu_result),.zf(Zero),.a(real_reg_a),.b(alu_in_2),.m(ALUm));

//alu control
//TODO
localparam m_ADD=3'b000;
localparam m_SUB=3'b001;
localparam m_AND=3'b010;
localparam m_OR =3'b011;
localparam m_XOR=3'b100;
localparam m_NOP=3'b101;

always @(*) begin
    case (ALUOp)
        ALUOP_ADD   :   ALUm=m_ADD;
        ALUOP_SUB   :   ALUm=m_SUB;
        ALUOP_FUNCT :   begin
            case (ID_EX_IR[5:0])
                6'b100000:ALUm=m_ADD; 
                default: begin
                    ALUm=m_NOP;
                end
            endcase
        end
        default: begin
            ALUm=m_NOP;
        end
    endcase
end

//TODO MemRead
//data memory
data_mem_with_IO data_ram_IO(.clk(clk), .rst(rst), .we(MemWrite), .re(MemRead),
        .d(EX_MEM_B), .a(EX_MEM_Y[9:2]), .spo(read_mem_data), .dpra(m_rf_addr[9:2]), .dpo(m_data),
        .input_flag(input_flag),.input_data(input_data),
        .output_flag(output_flag),.output_data(output_data),.output_finish_flag(output_finish_flag));

//pc mux
mux_2 #(32) pc_mux(.i_sel(PCSrc),.num0(pc_plus),.num1(pc_j),.num2(pc_br),.o_m(pc_next));
assign pc_plus=PC+32'd4;
assign pc_br=ID_EX_NPC+{ID_EX_IMMI[29:0],2'd0};
assign pc_j ={IF_ID_NPC[31:28],{IF_ID_IR[25:0]},{2'd0}};

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
    else if(clear_IF_ID) begin
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
        ID_EX_A<=32'd0;
        ID_EX_B<=32'd0;
        ID_EX_IMMI<=32'd0;
        ID_EX_IR<=32'd0;
        ID_EX_WB<=2'd0;
        ID_EX_M<=3'd0;
        ID_EX_EX<=6'd0;
    end
    else begin
        ID_EX_NPC<=IF_ID_NPC;
        ID_EX_A<= read_reg_data_1;
        ID_EX_B<= read_reg_data_2;
        ID_EX_IMMI<={{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
        ID_EX_IR<=IF_ID_IR;
        if(clear_ID_EX)begin
            {ID_EX_WB,ID_EX_M,ID_EX_EX}<=11'd0;
        end
        else begin
            ID_EX_WB<=wb_ctrl;
            ID_EX_M<=m_ctrl;
            ID_EX_EX<=ex_ctrl;
        end
    end
end

//EX-MEM
always @(posedge clk or posedge rst) begin
    if(rst) begin
        EX_MEM_Y<=32'd0;
        EX_MEM_B<=32'd0;
        EX_MEM_WA<=5'd0;
        EX_MEM_WB<=2'd0;
        EX_MEM_M<=3'd0;
    end
    else begin
        EX_MEM_Y<=alu_result;
        EX_MEM_B<=real_reg_b;
        EX_MEM_WA<=write_reg_addr;
        EX_MEM_WB<=ID_EX_WB;
        EX_MEM_M<=ID_EX_M;
    end
end

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
