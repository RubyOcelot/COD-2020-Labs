module edg(
    input y,rst,clk,
    output p
);
localparam edge_S0=2'd0;
localparam edge_S1=2'd1;
localparam edge_S2=2'd2;

reg [1:0]edge_state,edge_next_state;

//output logic
assign  p = (edge_state==edge_S1); 

//state logic
always @(posedge clk, posedge rst)
  if (rst) edge_state <= edge_S0;
  else edge_state <= edge_next_state; 

//next state logic
always @* begin 
  edge_next_state = edge_state;
  case (edge_state)
    edge_S0: if (y) edge_next_state = edge_S1;
            else edge_next_state = edge_S0;
    edge_S1: if (y) edge_next_state = edge_S2;
            else edge_next_state = edge_S0;
    edge_S2: if (y) edge_next_state = edge_S2;
            else edge_next_state = edge_S0;
    default: edge_next_state = edge_S0;
  endcase
end
endmodule