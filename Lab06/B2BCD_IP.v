//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : B2BCD_IP.v
//   Module Name : B2BCD_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module B2BCD_IP #(parameter WIDTH = 4, parameter DIGIT = 2) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1:0]   Binary_code;
output [DIGIT*4-1:0] BCD_code;

// ===============================================================
// Soft IP DESIGN
// ===============================================================

wire [WIDTH - 1:0] binary_shift [0:WIDTH - 1];
wire [3:0] BCD_add3 [0:WIDTH - 1][0:DIGIT - 1];
wire [3:0] BCD_shift [0:WIDTH - 1][0:DIGIT - 1]; 

genvar gv_j, gv_i;

assign binary_shift[0] = Binary_code;
generate
	for (gv_i = 1; gv_i < WIDTH; gv_i = gv_i + 1) begin
		assign binary_shift[gv_i] = {binary_shift[gv_i - 1][WIDTH - 2:0], 1'b0};
	end
endgenerate

generate
	for (gv_j = 0; gv_j < DIGIT; gv_j = gv_j + 1) begin
		assign BCD_add3[0][gv_j] = 4'b0;
	end
	for (gv_i = 1; gv_i < WIDTH; gv_i = gv_i + 1) begin
		for (gv_j = 0; gv_j < DIGIT; gv_j = gv_j + 1) begin
			//if (gv_j * 4 - 1 <= gv_i - 1) begin
				assign BCD_add3[gv_i][gv_j] = (BCD_shift[gv_i - 1][gv_j] > 4'd4 ? BCD_shift[gv_i - 1][gv_j] + 4'd3 : BCD_shift[gv_i - 1][gv_j]);
			/*end
			else begin
				assign BCD_add3[gv_i][gv_j] = BCD_shift[gv_i - 1][gv_j];
			end*/
		end
	end
endgenerate

generate
	for (gv_i = 0; gv_i < WIDTH; gv_i = gv_i + 1) begin
		assign BCD_shift[gv_i][0] = {BCD_add3[gv_i][0][2:0], binary_shift[gv_i][WIDTH - 1]};
		for (gv_j = 1; gv_j < DIGIT; gv_j = gv_j + 1) begin
			assign BCD_shift[gv_i][gv_j] = {BCD_add3[gv_i][gv_j][2:0], BCD_add3[gv_i][gv_j - 1][3]};
		end
	end
endgenerate

generate
	assign BCD_code[0] = BCD_shift[WIDTH - 1][0][0];
	assign BCD_code[1] = BCD_shift[WIDTH - 1][0][1];
	assign BCD_code[2] = BCD_shift[WIDTH - 1][0][2];
	assign BCD_code[3] = BCD_shift[WIDTH - 1][0][3];
	for (gv_j = 1; gv_j < DIGIT; gv_j = gv_j + 1) begin
		assign BCD_code[gv_j * 4    ] = BCD_shift[WIDTH - 1][gv_j][0];
		assign BCD_code[gv_j * 4 + 1] = BCD_shift[WIDTH - 1][gv_j][1];
		assign BCD_code[gv_j * 4 + 2] = BCD_shift[WIDTH - 1][gv_j][2];
		assign BCD_code[gv_j * 4 + 3] = BCD_shift[WIDTH - 1][gv_j][3];
	end
endgenerate

endmodule
