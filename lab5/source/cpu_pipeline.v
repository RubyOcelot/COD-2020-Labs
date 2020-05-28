module cpu_multi_cycle	//单周期CPU
(input clk,			//时钟（上升沿有效）
input rst,				//异步复位，高电平有效
output [15:0]status,
output [31:0]m_data,rf_data,
input [15:0]m_rf_addr,
input [2:0]i_sel,
output reg [31:0]o_sel_data
);

reg [31:0]PC=32'd0,MemoryDataRegister=32'd0,A=32'd0,B=32'd0,ALUOut=32'd0,IR=32'd0;

wire [31:0]alu_result;
wire [31:0]write_reg_data,read_reg_data_1,read_reg_data_2;
wire [31:0]read_mem_data;
wire [31:0]alu_in_1,alu_in_2;
wire [4:0]write_reg_addr;
wire PCwe,ALUZero;
reg RegWrite;
reg PCWriteCond,PCWrite,IorD,MemRead,MemWrite,MemtoReg,IRWrite,ALUSrcA,RegDst;
reg [1:0]PCSource,ALUSrcB;
reg [2:0]ALUOp,ALUm;
wire [31:0]pc_jump,pc_next;
wire [31:0]ins_15_0_sext,ins_15_0_sext_shift_2;
wire [8:0]mem_addr;
wire [5:0]Op;

//dbg
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
register_file #(32) my_rf(.clk(clk), .ra0(IR[25:21]), .rd0(read_reg_data_1), .ra1(IR[20:16]), .rd1(read_reg_data_2), .wa(write_reg_addr), .we(RegWrite), .wd(write_reg_data),.dbgra(m_rf_addr[4:0]),.dbgrd(rf_data));

mux_1 #(5) write_register_addr_mux(.i_sel(RegDst),.num0(IR[20:16]),.num1(IR[15:11]),.o_m(write_reg_addr));
mux_1 #(32) write_register_data_mux(.i_sel(MemtoReg),.num0(ALUOut),.num1(MemoryDataRegister),.o_m(write_reg_data));

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
reg [3:0]ctrl_state=IDLE,ctrl_state_next;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        ctrl_state<=IDLE;
    end
    else begin
        ctrl_state<=ctrl_state_next;
    end
end

always @(*) begin
    case(ctrl_state)
        IDLE:ctrl_state_next=IF;
        IF:ctrl_state_next=ID;
        ID:begin
            case(Op)
                LW:ctrl_state_next=MC;
                SW:ctrl_state_next=MC;
                ADD:ctrl_state_next=REX;
                ADDI:ctrl_state_next=IEX;
                BEQ:ctrl_state_next=BC;
                J:ctrl_state_next=JC;
            endcase
        end
        MC:begin
            case(Op)
                LW:ctrl_state_next=MAR;
                SW:ctrl_state_next=MAW;
            endcase
        end
        MAR:ctrl_state_next=WBS;
        WBS:ctrl_state_next=IF;
        MAW:ctrl_state_next=IF;
        REX:ctrl_state_next=RRC;
        RRC:ctrl_state_next=IF;
        BC:ctrl_state_next=IF;
        JC:ctrl_state_next=IF;
        IEX:ctrl_state_next=IRC;
        IRC:ctrl_state_next=IF;
        default:begin
            ctrl_state_next=IF;
        end
    endcase
end


always @(*) begin
    {PCWriteCond,PCWrite,IorD,MemRead,MemWrite,MemtoReg,IRWrite,PCSource,ALUOp,ALUSrcB,ALUSrcA,RegWrite,RegDst}=17'd0;
    if(!rst)
        case (ctrl_state)
            IF:begin
                MemRead=1'b1;
                IorD=1'b0;
                IRWrite=1'b1;
                ALUSrcA=1'b0;
                ALUSrcB=2'b01;
                ALUOp=3'b00;
                PCWrite=1'b1;
                PCSource=2'b00;
            end
            ID:begin
                ALUSrcA=1'd0;
                ALUSrcB=2'b11;
                ALUOp=3'b00;
            end
            MC:begin
                ALUSrcA=1'd1;
                ALUSrcB=2'b10;
                ALUOp=3'b00;
            end
            MAR:begin
                MemRead=1'b1;
                IorD=1'b1;
            end
            WBS:begin
                RegDst=1'b0;
                RegWrite=1'b1;
                MemtoReg=1'b1;
            end
            MAW:begin
                MemWrite=1'b1;
                IorD=1'b1;
            end
            REX:begin
                ALUSrcA=1'd1;
                ALUSrcB=2'b00;
                ALUOp=3'b10;
            end
            RRC:begin
                RegDst=1'b1;
                RegWrite=1'b1;
                MemtoReg=1'b0;
            end
            BC:begin
                ALUSrcA=1'b1;
                ALUSrcB=2'b00;
                ALUOp=3'b01;
                PCWriteCond=1'b1;
                PCSource=2'b01;
            end
            JC: begin
                PCWrite=1'b1;
                PCSource=2'b10;
            end
            IEX:begin
                ALUSrcA=1'd1;
                ALUSrcB=2'b10;
                ALUOp=3'b00;//TODO
            end
            IRC:begin
                RegDst=1'b0;
                RegWrite=1'b1;
                MemtoReg=1'b0;
            end
            default: begin
                
            end
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
