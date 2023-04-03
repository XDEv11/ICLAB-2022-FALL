`include "synchronizer.v"
`include "syn_XOR.v"
module CDC(
	//Input Port
	clk1,
    clk2,
    clk3,
	rst_n,
	in_valid1,
	in_valid2,
	user1,
	user2,

    //Output Port
    out_valid1,
    out_valid2,
	equal,
	exceed,
	winner
); 
input 		clk1, clk2, clk3, rst_n;
input 		in_valid1, in_valid2;
input [3:0]	user1, user2;

output reg	out_valid1, out_valid2;
output reg	equal, exceed, winner;
//---------------------------------------------------------------------
//
//---------------------------------------------------------------------
reg prob_flag_1;
wire prob_flag_3;
reg [4:0] prob_dividend1_reg_1, prob_dividend1_reg_3;
reg [5:0] prob_dividend2_reg_1, prob_dividend2_reg_3;
reg [5:0] prob_divisor_reg_1, prob_divisor_reg_3;
syn_XOR u_syn_XOR_prob_flag(.IN(prob_flag_1), .OUT(prob_flag_3), .TX_CLK(clk1), .RX_CLK(clk3), .RST_N(rst_n));
always @(posedge clk3) begin
	if (prob_flag_3) begin
		prob_dividend1_reg_3 <= prob_dividend1_reg_1;
		prob_dividend2_reg_3 <= prob_dividend2_reg_1;
		prob_divisor_reg_3 <= prob_divisor_reg_1;
	end
end

reg winner_flag_1;
wire winner_flag_3;
reg [1:0] winner_reg_1, winner_reg_3;
syn_XOR u_syn_XOR_winner_flag(.IN(winner_flag_1), .OUT(winner_flag_3), .TX_CLK(clk1), .RX_CLK(clk3), .RST_N(rst_n));
always @(posedge clk3) begin
	if (winner_flag_3) begin
		winner_reg_3 <= winner_reg_1;
	end
end
/*------------------------------*/

reg [3:0] point1, point2;
always @(*) begin
	point1 <= 4'bx;
	case (user1)
		4'd1, 4'd11, 4'd12, 4'd13 : point1 <= 4'd1;
		4'd2 : point1 <= 4'd2;
		4'd3 : point1 <= 4'd3;
		4'd4 : point1 <= 4'd4;
		4'd5 : point1 <= 4'd5;
		4'd6 : point1 <= 4'd6;
		4'd7 : point1 <= 4'd7;
		4'd8 : point1 <= 4'd8;
		4'd9 : point1 <= 4'd9;
		4'd10 : point1 <= 4'd10;
	endcase
	point2 <= 4'bx;
	case (user2)
		4'd1, 4'd11, 4'd12, 4'd13 : point2 <= 4'd1;
		4'd2 : point2 <= 4'd2;
		4'd3 : point2 <= 4'd3;
		4'd4 : point2 <= 4'd4;
		4'd5 : point2 <= 4'd5;
		4'd6 : point2 <= 4'd6;
		4'd7 : point2 <= 4'd7;
		4'd8 : point2 <= 4'd8;
		4'd9 : point2 <= 4'd9;
		4'd10 : point2 <= 4'd10;
	endcase
end
wire [3:0] point = (in_valid1 ? point1 : point2);

reg [4:0] player1, player2;

reg [4:0] player_next;
reg [4:0] _player_temp1;
reg [5:0] _player_temp2;
always @(*) begin
	_player_temp1 <= (in_valid1 ? player1 : player2);
	_player_temp2 <= _player_temp1 + point;
	player_next <= (_player_temp2[5] ? _player_temp1 : _player_temp2);
end

reg [5:0] g0cnt; // 52
reg [5:0] g1cnt; // 36
reg [5:0] g2cnt; // 32
reg [4:0] g3cnt; // 28
reg [4:0] g4cnt; // 24
reg [4:0] g5cnt; // 20
reg [4:0] g6cnt; // 16
reg [3:0] g7cnt; // 12
reg [3:0] g8cnt; // 8
reg [2:0] g9cnt; // 4
reg [5:0] g0cnt_next;
reg [5:0] g1cnt_next;
reg [5:0] g2cnt_next;
reg [4:0] g3cnt_next;
reg [4:0] g4cnt_next;
reg [4:0] g5cnt_next;
reg [4:0] g6cnt_next;
reg [3:0] g7cnt_next;
reg [3:0] g8cnt_next;
reg [2:0] g9cnt_next;
always @(*) begin
	g0cnt_next <= g0cnt - 6'd1;
	g1cnt_next <= g1cnt - (point > 1);
	g2cnt_next <= g2cnt - (point > 2);
	g3cnt_next <= g3cnt - (point > 3);
	g4cnt_next <= g4cnt - (point > 4);
	g5cnt_next <= g5cnt - (point > 5);
	g6cnt_next <= g6cnt - (point > 6);
	g7cnt_next <= g7cnt - (point > 7);
	g8cnt_next <= g8cnt - (point > 8);
	g9cnt_next <= g9cnt - (point > 9);
end

reg [5:0] dividend1_temp1;
reg [5:0] dividend2_temp;
always @(*) begin
	case (player_next)
		5'd31, 5'd30, 5'd29, 5'd28, 5'd27, 5'd26, 5'd25, 5'd24, 5'd23, 5'd22, 5'd21 : begin
			dividend1_temp1 <= g0cnt_next;
			dividend2_temp <= g0cnt_next;
		end
		5'd20 : begin
			dividend1_temp1 <= g0cnt_next;
			dividend2_temp <= g1cnt_next;
		end
		5'd19 : begin
			dividend1_temp1 <= g1cnt_next;
			dividend2_temp <= g2cnt_next;
		end
		5'd18 : begin
			dividend1_temp1 <= g2cnt_next;
			dividend2_temp <= g3cnt_next;
		end
		5'd17 : begin
			dividend1_temp1 <= g3cnt_next;
			dividend2_temp <= g4cnt_next;
		end
		5'd16 : begin
			dividend1_temp1 <= g4cnt_next;
			dividend2_temp <= g5cnt_next;
		end
		5'd15 : begin
			dividend1_temp1 <= g5cnt_next;
			dividend2_temp <= g6cnt_next;
		end
		5'd14 : begin
			dividend1_temp1 <= g6cnt_next;
			dividend2_temp <= g7cnt_next;
		end
		5'd13 : begin
			dividend1_temp1 <= g7cnt_next;
			dividend2_temp <= g8cnt_next;
		end
		5'd12 : begin
			dividend1_temp1 <= g8cnt_next;
			dividend2_temp <= g9cnt_next;
		end
		5'd11 : begin
			dividend1_temp1 <= g9cnt_next;
			dividend2_temp <= 6'd0;
		end
		default : begin
			dividend1_temp1 <= 6'd0;
			dividend2_temp <= 6'd0;
		end
	endcase
end
wire [4:0] dividend1_temp = dividend1_temp1 - dividend2_temp;

reg [3:0] state_1, nxt_state_1;
localparam Idle_1	= 4'b0000;
localparam Work0_1	= 4'b0001;
localparam Work1_1	= 4'b0011;
localparam Work2_1	= 4'b0010;
localparam Work3_1	= 4'b0110;
localparam Work4_1	= 4'b0111;
localparam Work5_1	= 4'b0101;
localparam Work6_1	= 4'b0100;
localparam Work7_1	= 4'b1100;
localparam Work8_1	= 4'b1101;
localparam Work9_1	= 4'b1111;

reg [2:0] epoch_cnt;
wire epoch_cnt_is_5 = (epoch_cnt == 3'd5);

always @(*) begin
	nxt_state_1 <= state_1;
	case (state_1)
		Idle_1 : nxt_state_1 <= Work0_1;
		Work0_1 :
			if (in_valid1) nxt_state_1 <= Work1_1;
		Work1_1 : nxt_state_1 <= Work2_1;
		Work2_1 : nxt_state_1 <= Work3_1;
		Work3_1 : nxt_state_1 <= Work4_1;
		Work4_1 : nxt_state_1 <= Work5_1;
		Work5_1 : nxt_state_1 <= Work6_1;
		Work6_1 : nxt_state_1 <= Work7_1;
		Work7_1 : nxt_state_1 <= Work8_1;
		Work8_1 : nxt_state_1 <= Work9_1;
		Work9_1 : nxt_state_1 <= Work0_1;
	endcase
end

always @(posedge clk1 or negedge rst_n) begin
	if(!rst_n) state_1 <= Idle_1;
	else state_1 <= nxt_state_1;
end

always @(posedge clk1) begin
	g0cnt <= 6'd52; g1cnt <= 6'd36; g2cnt <= 6'd32; g3cnt <= 5'd28; g4cnt <= 5'd24; //
	g5cnt <= 5'd20; g6cnt <= 5'd16; g7cnt <= 5'd12; g8cnt <= 5'd8; g9cnt <= 5'd4; //
	case (state_1)
		Idle_1 : begin
			epoch_cnt <= 3'd1;
			g0cnt <= 6'd52; g1cnt <= 6'd36; g2cnt <= 6'd32; g3cnt <= 5'd28; g4cnt <= 5'd24;
			g5cnt <= 5'd20; g6cnt <= 5'd16; g7cnt <= 5'd12; g8cnt <= 5'd8; g9cnt <= 5'd4;
		end
		Work0_1 : begin
			if (in_valid1) begin
				g0cnt <= g0cnt_next; g1cnt <= g1cnt_next; g2cnt <= g2cnt_next; g3cnt <= g3cnt_next; g4cnt <= g4cnt_next;
				g5cnt <= g5cnt_next; g6cnt <= g6cnt_next; g7cnt <= g7cnt_next; g8cnt <= g8cnt_next; g9cnt <= g9cnt_next;
			end
		end
		Work1_1, Work2_1, Work3_1, Work4_1, Work5_1, Work6_1, Work7_1, Work8_1 : begin
				g0cnt <= g0cnt_next; g1cnt <= g1cnt_next; g2cnt <= g2cnt_next; g3cnt <= g3cnt_next; g4cnt <= g4cnt_next;
				g5cnt <= g5cnt_next; g6cnt <= g6cnt_next; g7cnt <= g7cnt_next; g8cnt <= g8cnt_next; g9cnt <= g9cnt_next;
		end
		Work9_1 : begin
			if (epoch_cnt_is_5) begin
				epoch_cnt <= 3'd1;
				g0cnt <= 6'd52; g1cnt <= 6'd36; g2cnt <= 6'd32; g3cnt <= 5'd28; g4cnt <= 5'd24;
				g5cnt <= 5'd20; g6cnt <= 5'd16; g7cnt <= 5'd12; g8cnt <= 5'd8; g9cnt <= 5'd4;
			end
			else begin
				epoch_cnt <= epoch_cnt + 3'd1;
				g0cnt <= g0cnt_next; g1cnt <= g1cnt_next; g2cnt <= g2cnt_next; g3cnt <= g3cnt_next; g4cnt <= g4cnt_next;
				g5cnt <= g5cnt_next; g6cnt <= g6cnt_next; g7cnt <= g7cnt_next; g8cnt <= g8cnt_next; g9cnt <= g9cnt_next;
			end
		end
	endcase
end

always @(posedge clk1) begin
	player2 <= point2; //
	case (state_1)
		Work0_1 : begin
			player1 <= point1;
		end
		Work1_1, Work2_1, Work3_1, Work4_1 : begin
			player1 <= player_next;
		end
		Work5_1 : begin
			player2 <= point2;
		end
		Work6_1, Work7_1, Work8_1, Work9_1 : begin
			player2 <= player_next;
		end
	endcase
end

always @(posedge clk1 or negedge rst_n) begin
	if (!rst_n) begin
		prob_flag_1 <= 1'b0;
		winner_flag_1 <= 1'b0;
	end
	else begin
		prob_flag_1 <= 1'b0;
		winner_flag_1 <= 1'b0;
		case (state_1)
			Work1_1, Work2_1, Work6_1, Work7_1 : begin
				prob_flag_1 <= 1'b1;
			end
			Work8_1 : begin
				winner_flag_1 <= 1'b1;
			end
		endcase
	end
end

always @(posedge clk1) begin
	prob_dividend1_reg_1 <= dividend1_temp; //
	prob_dividend2_reg_1 <= dividend2_temp; //
	prob_divisor_reg_1 <= g0cnt_next; //
	winner_reg_1 <= 2'bx; //
	case (state_1)
		Work2_1, Work3_1, Work7_1, Work8_1 : begin
			prob_dividend1_reg_1 <= dividend1_temp;
			prob_dividend2_reg_1 <= dividend2_temp;
			prob_divisor_reg_1 <= g0cnt_next;
		end
		Work9_1 : begin
			if (player1 <= 6'd21 && player_next <= 6'd21) begin
				if (player1 > player_next) winner_reg_1 <= 2'b10;
				else if (player_next > player1) winner_reg_1 <= 2'b11;
				else winner_reg_1[1] <= 1'b0;
			end
			else if (player1 <= 6'd21) winner_reg_1 <= 2'b10;
			else if (player_next <= 6'd21) winner_reg_1 <= 2'b11;
			else winner_reg_1[1] <= 1'b0;
		end
	endcase
end
/*------------------------------*/

wire [5:0] divisor = prob_divisor_reg_3;

reg [12:0] rq1_cur;
wire [12:0] rq1_nxt;
wire [6:0] rq1_temp_0 = rq1_cur[12:6];
wire signed [7:0] rq1_temp_1 = rq1_temp_0 - divisor;
assign rq1_nxt = (rq1_temp_1[7] ?
	{rq1_temp_0[5:0], rq1_cur[5:0], 1'b0} :
	{rq1_temp_1[5:0], rq1_cur[5:0], 1'b1});
reg [12:0] rq2_cur;
wire [12:0] rq2_nxt;
wire [6:0] rq2_temp_0 = rq2_cur[12:6];
wire signed [7:0] rq2_temp_1 = rq2_temp_0 - divisor;
assign rq2_nxt = (rq2_temp_1[7] ?
	{rq2_temp_0[5:0], rq2_cur[5:0], 1'b0} :
	{rq2_temp_1[5:0], rq2_cur[5:0], 1'b1});

reg [3:0] state_1_3, nxt_state_1_3;
localparam Idle_1_3		= 4'b0000;
localparam Work0_1_3	= 4'b0001;
localparam Work1_1_3	= 4'b0011;
localparam Work2_1_3	= 4'b0010;
localparam Work3_1_3	= 4'b0110;
localparam Work4_1_3	= 4'b0111;
localparam Work5_1_3	= 4'b0101;
localparam Work6_1_3	= 4'b0100;
localparam Work7_1_3	= 4'b1100;
localparam Work8_1_3	= 4'b1101;

wire [10:0] prob_dividend1_reg_3x100 = prob_dividend1_reg_3 * 7'd100;
wire [12:0] prob_dividend2_reg_3x100 = prob_dividend2_reg_3 * 7'd100;

always @(*) begin
	nxt_state_1_3 <= state_1_3;
	case (state_1_3)
		Idle_1_3 :
			if (prob_flag_3) nxt_state_1_3 <= Work0_1_3;
		Work0_1_3 : nxt_state_1_3 <= Work1_1_3;
		Work1_1_3 : nxt_state_1_3 <= Work2_1_3;
		Work2_1_3 : nxt_state_1_3 <= Work3_1_3;
		Work3_1_3 : nxt_state_1_3 <= Work4_1_3;
		Work4_1_3 : nxt_state_1_3 <= Work5_1_3;
		Work5_1_3 : nxt_state_1_3 <= Work6_1_3;
		Work6_1_3 : nxt_state_1_3 <= Work7_1_3;
		Work7_1_3 : nxt_state_1_3 <= Work8_1_3;
		Work8_1_3 : nxt_state_1_3 <= Idle_1_3;
	endcase
end

always @(posedge clk3 or negedge rst_n) begin
	if(!rst_n) state_1_3 <= Idle_1_3;
	else state_1_3 <= nxt_state_1_3;
end

always @(posedge clk3) begin
	case (state_1_3)
		Work0_1_3 : begin
			rq1_cur <= prob_dividend1_reg_3x100;
			rq2_cur <= prob_dividend2_reg_3x100;
		end
		Work1_1_3, Work2_1_3, Work3_1_3, Work4_1_3, Work5_1_3, Work6_1_3, Work7_1_3 : begin
			rq1_cur <= rq1_nxt;
			rq2_cur <= rq2_nxt;
		end
	endcase
end

always @(*) begin
	out_valid1 <= 1'b0;
	equal <= 1'b0;
	exceed <= 1'b0;
	case (state_1_3)
		Work2_1_3, Work3_1_3, Work4_1_3, Work5_1_3, Work6_1_3, Work7_1_3, Work8_1_3 : begin
			out_valid1 <= 1'b1;
			equal <= rq1_cur[0];
			exceed <= rq2_cur[0];
		end
	endcase
end
/*---------------*/

reg [1:0] state_2_3, nxt_state_2_3;
localparam Idle_2_3		= 2'b00;
localparam Work0_2_3	= 2'b01;
localparam Work1_2_3	= 2'b11;

always @(*) begin
	nxt_state_2_3 <= state_2_3;
	case (state_2_3)
		Idle_2_3 :
			if (winner_flag_3) nxt_state_2_3 <= Work0_2_3;
		Work0_2_3 :
			if (winner_reg_3[1]) nxt_state_2_3 <= Work1_2_3;
			else nxt_state_2_3 <= Idle_2_3;
		Work1_2_3 : nxt_state_2_3 <= Idle_2_3;
	endcase
end

always @(posedge clk3 or negedge rst_n) begin
	if(!rst_n) state_2_3 <= Idle_2_3;
	else state_2_3 <= nxt_state_2_3;
end

always @(*) begin
	out_valid2 <= 1'b0;
	winner <= 1'b0;
	case (state_2_3)
		Work0_2_3 : begin
			out_valid2 <= 1'b1;
			winner <= winner_reg_3[1];
		end
		Work1_2_3 : begin
			out_valid2 <= 1'b1;
			winner <= winner_reg_3[0];
		end
	endcase
end

endmodule
