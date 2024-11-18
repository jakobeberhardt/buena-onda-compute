module fetch_decode (
input wire reset,
input wire i_clock,
reg [31:0] instructions [0:4095];
output reg pc[3:0]
)

@(posedge i_clock or posedge reset) begin
	if(reset) pc <= 4'b0000';
	

	else pc <= pc + 1;
end


