module BP(
  clk,
  rst_n,
  in_valid,
  guy,
  in0,
  in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  
  out_valid,
  out
);

input             clk, rst_n;
input             in_valid;
input       [2:0] guy;
input       [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
output reg        out_valid;
output reg  [1:0] out;
//=====+++++-----!!!!!//    
localparam MOV_STOP		= 2'd0;
localparam MOV_RIGHT	= 2'd1;
localparam MOV_LEFT		= 2'd2;
localparam MOV_JUMP		= 2'd3;
integer i;

reg in_flag;
reg [2:0] in_pos;
reg in_jump;
always @(*) begin
	in_flag <= |in0;
	in_pos <= 3'bx;
	case (1'b0) // synopsys parallel_case
		in0[0], in0[1] : in_pos <= 3'd0;
		in1[0], in1[1] : in_pos <= 3'd1;
		in2[0], in2[1] : in_pos <= 3'd2;
		in3[0], in3[1] : in_pos <= 3'd3;
		in4[0], in4[1] : in_pos <= 3'd4;
		in5[0], in5[1] : in_pos <= 3'd5;
		in6[0], in6[1] : in_pos <= 3'd6;
		in7[0], in7[1] : in_pos <= 3'd7;
	endcase
	in_jump <= in0[0] & in1[0] & in2[0] & in3[0] & in4[0] & in5[0] & in6[0] & in7[0];
end

reg [2:0] player;
wire [2:0] player_right = player + 3'd1;
wire [2:0] player_left = player - 3'd1;
reg flag [1:4];
reg [2:0] pos [1:4];
reg [1:0] ans [5:64];

reg [1:0] mov;
reg [2:0] player_next;
reg [2:0] target;
always @(*) begin
	target <= 3'd3;
	if (in_valid && in_flag) target <= in_pos;
	for (i = 1; i <= 4; i = i + 1) begin
		if (flag[i]) target <= pos[i];
	end
end
always @(*) begin
	if (!flag[4] && pos[4][0]) mov <= MOV_JUMP;
	else if (player == target) mov <= MOV_STOP;
	else if (player < target) mov <= MOV_RIGHT;
	else mov <= MOV_LEFT;

	if (!flag[4] && pos[4][0]) player_next <= player;
	else if (player == target) player_next <= player;
	else if (player < target) player_next <= player_right;
	else player_next <= player_left;
end

reg in_valid_last;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) in_valid_last <= 1'b0;
	else in_valid_last <= in_valid;
end
wire in_valid_begin = !in_valid_last && in_valid;
wire in_valid_end = in_valid_last && !in_valid;

reg [5:0] cnt;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt <= 6'd0;
	end
	else begin
		if (in_valid_end) cnt <= 6'd1;
		else if (cnt) cnt <= cnt + 6'd1;
	end
end

always @(posedge clk) begin
	player <= 3'bx; //
	for (i = 1; i <= 4; i = i + 1) begin //
		flag[i] <= 1'bx;
		pos[i] <= 3'bx;
	end
	for (i = 5; i <= 64; i = i + 1) ans[i] <= 2'bx; //

	if (in_valid_begin) begin
		player <= guy;
		for (i = 2; i <= 4; i = i + 1) begin
			flag[i] <= 1'b0;
			pos[i][0] <= 1'b0;
		end
		flag[1] <= 1'b1;
		pos[1] <= guy;
	end
	else begin
		player <= player_next;
		for (i = 2; i <= 4; i = i + 1) begin
			flag[i] <= flag[i - 1];
			pos[i] <= pos[i - 1];
		end
		if (in_valid) begin
			if (in_flag && in_jump) begin
				flag[2] <= 1'b1;
				pos[2] <= in_pos;
				flag[1] <= 1'b0;
				pos[1][0] <= 1'b1;
			end
			else begin
				flag[1] <= in_flag;
				if (in_flag) pos[1] <= in_pos;
				else pos[1][0] <= 1'b0;
			end
		end
		else begin
			flag[1] <= 1'b0;
			pos[1][0] <= 1'b0;
		end
	end
	for (i = 6; i <= 64; i = i + 1) ans[i] <= ans[i - 1];
	ans[5] <= mov;
end

always @(*) begin
	out_valid <= 1'b0;
	out <= 2'b00;
	if (cnt) begin
		out_valid <= 1'b1;
		out <= ans[64];
	end
end

endmodule

