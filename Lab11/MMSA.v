// synopsys translate_off

`include ...

// synopsys translate_on

module MMSA(
// input signals
    clk,
    rst_n,
    in_valid,
    in_valid2,
    matrix,
    matrix_size,
    i_mat_idx,
    w_mat_idx,

// output signals
    out_valid,
    out_value
);
input clk;
input rst_n;
input in_valid;
input in_valid2;
input matrix;
input [1:0]  matrix_size;
input i_mat_idx, w_mat_idx;

output reg out_valid;
output reg out_value;
//---------------------------------------------------------------------
//
//---------------------------------------------------------------------
genvar gv_i, gv_j;
integer i, j;

wire signed [127:0] m_Q;
reg m_WEN;
reg [6:0] m_A;
reg signed [127:0] m_D;
sram_128x128 u_sram_128x128_m(.Q(m_Q), .CLK(clk), .CEN(1'b0), .WEN(m_WEN), .A(m_A), .D(m_D), .OEN(1'b0));
wire [127:0] w_Q;
reg w_WEN;
reg [6:0] w_A;
reg [127:0] w_D;
sram_128x128 u_sram_128x128_w(.Q(w_Q), .CLK(clk), .CEN(1'b0), .WEN(w_WEN), .A(w_A), .D(w_D), .OEN(1'b0));

reg [127:0] data_in;
reg [1:0] sz;
reg [2:0] size_sub_1;
reg [3:0] mi, wi;
reg signed [37:0] ans [0:14];
reg signed [39:0] data_out;

reg output_is_begin;
reg output_is_end;

reg [3:0] bcnt;
wire bcnt_eq_0 = (bcnt == 4'd0);
wire bcnt_eq_3 = (bcnt == 4'd3);
wire bcnt_eq_15 = (bcnt == 4'd15);
wire [3:0] bcnt_add_1 = bcnt + 4'd1;

reg [2:0] ccnt;
wire [2:0] ccnt_end = size_sub_1;
wire ccnt_is_begin = (ccnt == 3'd0);
wire ccnt_is_end = (ccnt == ccnt_end);
wire [2:0] ccnt_add_1 = ccnt + 3'd1;
wire [2:0] ccnt_next = (ccnt_is_end ? 3'd0 : ccnt_add_1);

reg [2:0] rcnt;
wire [2:0] rcnt_end = size_sub_1;
wire rcnt_is_begin = (rcnt == 3'd0);
wire rcnt_is_end = (rcnt == rcnt_end);
wire [2:0] rcnt_add_1 = rcnt + 3'd1;
wire [2:0] rcnt_next = (rcnt_is_end ? 3'd0 : rcnt_add_1);

wire rcnt_eq_ccnt = (rcnt == ccnt);
wire ccnt_eq_size_sub_1_sub_rcnt = (ccnt == size_sub_1 - rcnt);
wire [2:0] rcnt_sub_ccnt_next = rcnt - ccnt_next;
wire [2:0] size_sub_1_sub_rcnt_next = size_sub_1 - rcnt_next;
wire [2:0] ccnt_add_rcnt_next = ccnt + rcnt_next;

reg [3:0] cnt;
wire cnt_eq_15 = (cnt == 4'd15);
wire [3:0] cnt_next = cnt + 4'd1;

reg [2:0] state, nxt_state;
localparam Idle1	= 3'd0;
localparam Readm	= 3'd1;
localparam Readw	= 3'd2;
localparam Idle2	= 3'd3;
localparam Work1	= 3'd4;
localparam Work2	= 3'd5;
localparam Output	= 3'd6;

wire [127:0] data_in_next_b = {{127{1'b0}}, matrix};
wire [127:0] data_in_next_m = {data_in[126:0], matrix};
wire [127:0] data_in_next_w = {w_Q[111:0], data_in[14:0], matrix};
wire [3:0] mi_next = {mi[2:0], i_mat_idx};
wire [3:0] wi_next = {wi[2:0], w_mat_idx};

wire signed [31:0] p [0:7];
generate
	for (gv_i = 0; gv_i < 8; gv_i = gv_i + 1) begin:MULT_BLOCK
		DW02_mult #(.A_width(16), .B_width(16))
			u_DW02_mult(.A(m_Q[(7 - gv_i) * 16 + 15 -: 16]), .B(w_Q[(7 - gv_i) * 16 + 15 -: 16]), .TC(1'b1), .PRODUCT(p[gv_i]));
	end
endgenerate
wire signed [32:0] dp_aux1 [0:3];
generate
	for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin:ADD_BLOCK_1
		DW01_add #(.width(33))
			u_DW01_add(.A({p[gv_i * 2][31], p[gv_i * 2]}), .B({p[gv_i * 2 + 1][31], p[gv_i * 2 + 1]}), .CI(1'b0), .SUM(dp_aux1[gv_i]), .CO());
	end
endgenerate
wire signed [33:0] dp_aux2 [0:1];
generate
	for (gv_i = 0; gv_i < 2; gv_i = gv_i + 1) begin:ADD_BLOCK_2
		DW01_add #(.width(34))
			u_DW01_add(.A({dp_aux1[gv_i * 2][32], dp_aux1[gv_i * 2]}), .B({dp_aux1[gv_i * 2 + 1][32], dp_aux1[gv_i * 2 + 1]}), .CI(1'b0), .SUM(dp_aux2[gv_i]), .CO());
	end
endgenerate
wire signed [34:0] dp;
DW01_add #(.width(35))
	u_DW01_add(.A({dp_aux2[0][33], dp_aux2[0]}), .B({dp_aux2[1][33], dp_aux2[1]}), .CI(1'b0), .SUM(dp), .CO());
reg signed [37:0] ans_next [0:14];

always @(*) begin
	nxt_state <= state;
	case (state)
		Idle1 :
			if (in_valid) begin
				nxt_state <= Readm;
			end
		Readm :
			//if (in_valid) begin
				if (bcnt_eq_15 && ccnt_is_end && rcnt_is_end && cnt_eq_15) nxt_state <= Readw;
			//end
		Readw :
			//if (in_valid) begin
				if (bcnt_eq_15 && ccnt_is_end && rcnt_is_end && cnt_eq_15) nxt_state <= Idle2;
			//end
		Idle2 :
			if (bcnt_eq_3) begin
				nxt_state <= Work1;
			end
		Work1 :
			if (rcnt_eq_ccnt && rcnt_is_end) nxt_state <= Work2;
		Work2 :
			if (ccnt_eq_size_sub_1_sub_rcnt && ccnt_is_end) nxt_state <= Output;
		Output :
			if (output_is_end) begin
				if (cnt_eq_15) nxt_state <= Idle1;
				else nxt_state <= Idle2;
			end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) state <= Idle1;
	else state <= nxt_state;
end

always @(*) begin
	m_WEN <= 1'b1;
	m_A <= 7'bx;
	m_D <= 128'bx;
	w_WEN <= 1'b1;
	w_A <= 7'bx;
	w_D <= 128'bx;
	case (state)
		Readm : begin
			//if(in_valid) begin
				if (bcnt_eq_15 && ccnt_is_end) begin//
					m_A <= {cnt, rcnt};
					m_WEN <= 1'b0;
					m_D <= data_in_next_m;
				end
			//end
		end
		Readw : begin
			//if(in_valid) begin
				w_A <= {cnt, ccnt};
				if (bcnt_eq_15) begin
					w_WEN <= 1'b0;
					if (rcnt_is_begin) w_D <= {{112{1'b0}}, data_in_next_w[15:0]};
					else w_D <= data_in_next_w;
				end
			//end
		end
		Idle2 : begin
			//if (bcnt_eq_3) begin
				m_A <= {mi_next, 3'd0};
				w_A <= {wi_next, 3'd0};
			//end
		end
		Work1 : begin
			if (rcnt_eq_ccnt) begin
				m_A <= {mi, rcnt_next};
				if (rcnt_is_end) m_A <= {mi, rcnt_end};
			end
			else m_A <= {mi, rcnt_sub_ccnt_next};
			if (rcnt_eq_ccnt) begin
				w_A <= {wi, 3'd0};
				if (rcnt_is_end) w_A <= {wi, 3'd1};
			end
			else w_A <= {wi, ccnt_next};
		end
		Work2 : begin
			if (ccnt_eq_size_sub_1_sub_rcnt) m_A <= {mi, size_sub_1};
			else m_A <= {mi, size_sub_1_sub_rcnt_next};
			if (ccnt_eq_size_sub_1_sub_rcnt) w_A <= {wi, ccnt_next};
			else w_A <= {wi, ccnt_add_rcnt_next};
		end
	endcase
end

reg signed [37:0] ans_old;
always @(*) begin
	ans_old <= 38'sbx;
	case (state)
		Work1 : begin
			ans_old <= ans[rcnt];
		end
		Work2 : begin
			ans_old <= ans[{1'b0, size_sub_1} + ccnt];
		end
	endcase
end

wire signed [37:0] ans_new;
DW01_add #(.width(38))
	u_DW01_add_2(.A(ans_old), .B({{3{dp[34]}}, dp}), .CI(1'b0), .SUM(ans_new), .CO());

always @(*) begin
	for (i = 0; i < 15; i = i + 1) ans_next[i] <= ans[i];
	case (state)
		Work1 : begin
			for (i = 0; i < 8; i = i + 1) begin
				if (i == 0) begin
					if (rcnt == i) ans_next[i] <= dp;
				end
				else begin
					if (rcnt == i) ans_next[i] <= ans_new;
				end
			end
		end
		Work2 : begin
			for (i = 1; i < 15; i = i + 1) begin
				if (i == 14) begin
					if (size_sub_1 + ccnt == i) ans_next[i] <= dp;
				end
				else begin
					if (size_sub_1 + ccnt == i) ans_next[i] <= ans_new;
				end
			end
		end
	endcase
end

always @(*) begin
	output_is_begin <= 1'b0;
	case (state)
		Work1 : begin
			if (rcnt_is_begin && ccnt_is_begin) output_is_begin <= 1'b1;
		end
	endcase
end

always @(posedge clk) begin
	case (state)
		Idle1 : begin
			//if (in_valid) begin
				sz <= matrix_size;
				case (matrix_size)
					2'b00 : size_sub_1 <= 4'd1;
					2'b01 : size_sub_1 <= 4'd3;
					2'b10 : size_sub_1 <= 4'd7;
				endcase
				data_in <= data_in_next_b; // reading
			//end
			bcnt <= 4'd1;
			ccnt <= 3'd0;
			rcnt <= 3'd0;
			cnt <= 4'd0;
		end
		Readm : begin
			//if (in_valid) begin
				if (bcnt_eq_0 && ccnt_is_begin) data_in <= data_in_next_b; // reading
				else data_in <= data_in_next_m; // reading
				bcnt <= (bcnt_eq_15 ? 4'd0 : bcnt_add_1);
				if (bcnt_eq_15) ccnt <= ccnt_next;
				if (bcnt_eq_15 && ccnt_is_end) rcnt <= rcnt_next;
				if (bcnt_eq_15 && ccnt_is_end && rcnt_is_end) cnt <= cnt_next;
			//end
		end
		Readw : begin
			//if (in_valid) begin
				data_in <= data_in_next_w; // reading
				bcnt <= (bcnt_eq_15 ? 4'd0 : bcnt_add_1);
				if (bcnt_eq_15) ccnt <= ccnt_next;
				if (bcnt_eq_15 && ccnt_is_end) rcnt <= rcnt_next;
				if (bcnt_eq_15 && ccnt_is_end && rcnt_is_end) cnt <= cnt_next;
			//end
		end
		Idle2 : begin
			//if (in_valid2) begin
				mi <= mi_next; // reading
				wi <= wi_next; // reading
			if (in_valid2) begin
				bcnt <= (bcnt_eq_3 ? 4'd0 : bcnt_add_1);
			end//
			for (i = 0; i < 15; i = i + 1) ans[i] <= 38'sd0;
		end
		Work1 : begin
			for (i = 0; i < 15; i = i + 1) ans[i] <= ans_next[i];
			ccnt <= ccnt_next;
			if (rcnt_eq_ccnt) begin
				rcnt <= rcnt_next;
				ccnt <= 3'd0;
				if (rcnt_is_end) begin
					ccnt <= 3'd1;
					rcnt <= 3'd0;
				end
			end
		end
		Work2 : begin
			for (i = 0; i < 15; i = i + 1) ans[i] <= ans_next[i];
			rcnt <= rcnt_next;
			if (ccnt_eq_size_sub_1_sub_rcnt) begin
				ccnt <= ccnt_next;
				rcnt <= 3'd0;
			end
		end
		Output : begin
			if (output_is_end) cnt <= cnt_next;
		end
	endcase
end


reg [2:0] state2, nxt_state2;
localparam Idle_s2		= 3'd0;
localparam Lout_5_s2	= 3'd1;
localparam Lout_4_s2	= 3'd2;
localparam Lout_3_s2	= 3'd3;
localparam Lout_210_s2	= 3'd4;
localparam Lout_s2		= 3'd5;
localparam Dout_s2		= 3'd6;

reg [2:0] llcnt;
wire [2:0] llcnt_sub_1 = llcnt - 3'd1;
wire llcnt_is_end = (llcnt == 3'd0);

reg [5:0] lcnt;
wire [5:0] lcnt_sub_1 = lcnt - 6'd1;
wire lcnt_is_end = (lcnt == 6'd1);

reg [3:0] ocnt;
wire [3:0] ocnt_add_1 = ocnt + 4'd1;
wire [3:0] ocnt_is_end = (ocnt == {size_sub_1, 1'b1});

reg find1_b;
reg [2:0] llcnt_next_b;
reg [5:0] lcnt_next_b;
reg signed [39:0] data_out_next_b;

reg find1;
reg [2:0] llcnt_next;
reg [5:0] lcnt_next;
reg signed [39:0] data_out_next;

always @(*) begin
	nxt_state2 <= state2;
	case (state2)
		Idle_s2 :
			if (output_is_begin) begin
				if (find1_b) nxt_state2 <= Lout_s2;
				else nxt_state2 <= Lout_4_s2;
			end
		Lout_5_s2 :
			if (find1) nxt_state2 <= Lout_s2;
			else nxt_state2 <= Lout_4_s2;
		Lout_4_s2 :
			if (find1) nxt_state2 <= Lout_s2;
			else nxt_state2 <= Lout_3_s2;
		Lout_3_s2 :
			if (find1) nxt_state2 <= Lout_s2;
			else nxt_state2 <= Lout_210_s2;
		Lout_210_s2 : nxt_state2 <= Lout_s2;
		Lout_s2 :
			if (llcnt_is_end) nxt_state2 <= Dout_s2;
		Dout_s2 :
			if (lcnt_is_end) begin
				if (ocnt_is_end) nxt_state2 <= Idle_s2;
				else nxt_state2 <= Lout_5_s2;
			end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) state2 <= Idle_s2;
	else state2 <= nxt_state2;
end

/*** WARNING ***/
// Using dp (dot product) directly is dangerous!!
// It depends on whether output_is_begin is high instantly.
always @(*) begin
	find1_b <= 1'b1;
	llcnt_next_b <= 3'bx;
	lcnt_next_b <= 6'bx;
	data_out_next_b <= 40'sbx;

	llcnt_next_b <= 3'd4;
	if (dp[34]) begin
		lcnt_next_b <= 6'd40;
		data_out_next_b <= {{5{1'b1}}, dp};
	end
	else if (dp[33]) begin
		lcnt_next_b <= 6'd34;
		data_out_next_b <= {dp[33:0], 6'bx};
	end
	else if (dp[32]) begin
		lcnt_next_b <= 6'd33;
		data_out_next_b <= {dp[32:0], 7'bx};
	end
	else if (dp[31]) begin
		lcnt_next_b <= 6'd32;
		data_out_next_b <= {dp[31:0], 8'bx};
	end
	else begin
		find1_b <= 1'b0;
		//llcnt_next_b <= 3'bx;
		data_out_next_b <= {dp[30:0], 9'bx};
	end
end

always @(*) begin
	find1 <= 1'b1;
	llcnt_next <= 3'bx;
	lcnt_next <= 6'bx;
	data_out_next <= 40'sbx;
	case (state2)
		Lout_5_s2 : begin
			llcnt_next <= 3'd4;
			if (data_out[37]) begin
				lcnt_next <= 6'd40;
				data_out_next <= data_out;
			end
			else if (data_out[36]) begin
				lcnt_next <= 6'd37;
				data_out_next <= {data_out[36:0], 3'bx};
			end
			else if (data_out[35]) begin
				lcnt_next <= 6'd36;
				data_out_next <= {data_out[35:0], 4'bx};
			end
			else if (data_out[34]) begin
				lcnt_next <= 6'd35;
				data_out_next <= {data_out[34:0], 5'bx};
			end
			else if (data_out[33]) begin
				lcnt_next <= 6'd34;
				data_out_next <= {data_out[33:0], 6'bx};
			end
			else if (data_out[32]) begin
				lcnt_next <= 6'd33;
				data_out_next <= {data_out[32:0], 7'bx};
			end
			else if (data_out[31]) begin
				lcnt_next <= 6'd32;
				data_out_next <= {data_out[31:0], 8'bx};
			end
			else begin
				find1 <= 1'b0;
				//llcnt_next <= 3'bx;
				data_out_next <= {data_out[30:0], 9'bx};
			end
		end
		Lout_4_s2 : begin
			llcnt_next <= 3'd3;
			if (data_out[39]) begin
				lcnt_next <= 6'd31;
				data_out_next <= data_out;
			end
			else if (data_out[38]) begin
				lcnt_next <= 6'd30;
				data_out_next <= {data_out[38:0], 1'bx};
			end
			else if (data_out[37]) begin
				lcnt_next <= 6'd29;
				data_out_next <= {data_out[37:0], 2'bx};
			end
			else if (data_out[36]) begin
				lcnt_next <= 6'd28;
				data_out_next <= {data_out[36:0], 3'bx};
			end
			else if (data_out[35]) begin
				lcnt_next <= 6'd27;
				data_out_next <= {data_out[35:0], 4'bx};
			end
			else if (data_out[34]) begin
				lcnt_next <= 6'd26;
				data_out_next <= {data_out[34:0], 5'bx};
			end
			else if (data_out[33]) begin
				lcnt_next <= 6'd25;
				data_out_next <= {data_out[33:0], 6'bx};
			end
			else if (data_out[32]) begin
				lcnt_next <= 6'd24;
				data_out_next <= {data_out[32:0], 7'bx};
			end
			else if (data_out[31]) begin
				lcnt_next <= 6'd23;
				data_out_next <= {data_out[31:0], 8'bx};
			end
			else if (data_out[30]) begin
				lcnt_next <= 6'd22;
				data_out_next <= {data_out[30:0], 9'bx};
			end
			else if (data_out[29]) begin
				lcnt_next <= 6'd21;
				data_out_next <= {data_out[29:0], 10'bx};
			end
			else if (data_out[28]) begin
				lcnt_next <= 6'd20;
				data_out_next <= {data_out[28:0], 11'bx};
			end
			else if (data_out[27]) begin
				lcnt_next <= 6'd19;
				data_out_next <= {data_out[27:0], 12'bx};
			end
			else if (data_out[26]) begin
				lcnt_next <= 6'd18;
				data_out_next <= {data_out[26:0], 13'bx};
			end
			else if (data_out[25]) begin
				lcnt_next <= 6'd17;
				data_out_next <= {data_out[25:0], 14'bx};
			end
			else if (data_out[24]) begin
				lcnt_next <= 6'd16;
				data_out_next <= {data_out[24:0], 15'bx};
			end
			else begin
				find1 <= 1'b0;
				//llcnt_next <= 3'bx;
				data_out_next <= {data_out[23:0], 16'bx};
			end
		end
		Lout_3_s2 : begin
			llcnt_next <= 3'd2;
			if (data_out[39]) begin
				lcnt_next <= 6'd15;
				data_out_next <= data_out;
			end
			else if (data_out[38]) begin
				lcnt_next <= 6'd14;
				data_out_next <= {data_out[38:0], 1'bx};
			end
			else if (data_out[37]) begin
				lcnt_next <= 6'd13;
				data_out_next <= {data_out[37:0], 2'bx};
			end
			else if (data_out[36]) begin
				lcnt_next <= 6'd12;
				data_out_next <= {data_out[36:0], 3'bx};
			end
			else if (data_out[35]) begin
				lcnt_next <= 6'd11;
				data_out_next <= {data_out[35:0], 4'bx};
			end
			else if (data_out[34]) begin
				lcnt_next <= 6'd10;
				data_out_next <= {data_out[34:0], 5'bx};
			end
			else if (data_out[33]) begin
				lcnt_next <= 6'd9;
				data_out_next <= {data_out[33:0], 6'bx};
			end
			else if (data_out[32]) begin
				lcnt_next <= 6'd8;
				data_out_next <= {data_out[32:0], 7'bx};
			end
			else begin
				find1 <= 1'b0;
				//llcnt_next <= 3'bx;
				data_out_next <= {data_out[31:0], 8'bx};
			end
		end
		Lout_210_s2 : begin
			llcnt_next <= 3'd1;
			if (data_out[39]) begin
				lcnt_next <= 6'd7;
				data_out_next <= data_out;
			end
			else if (data_out[38]) begin
				lcnt_next <= 6'd6;
				data_out_next <= {data_out[38:0], 1'bx};
			end
			else if (data_out[37]) begin
				lcnt_next <= 6'd5;
				data_out_next <= {data_out[37:0], 2'bx};
			end
			else if (data_out[36]) begin
				lcnt_next <= 6'd4;
				data_out_next <= {data_out[36:0], 3'bx};
			end
			else if (data_out[35]) begin
				find1 <= 1'b0;
				lcnt_next <= 6'd3;
				data_out_next <= {data_out[35:0], 4'bx};
			end
			else if (data_out[34]) begin
				find1 <= 1'b0;
				lcnt_next <= 6'd2;
				data_out_next <= {data_out[34:0], 5'bx};
			end
			else if (data_out[33]) begin
				find1 <= 1'b0;
				lcnt_next <= 6'd1;
				data_out_next <= {data_out[33:0], 6'bx};
			end
			else begin
				find1 <= 1'b0;
				//llcnt_next <= 3'bx;
				lcnt_next <= 6'd1;
				data_out_next <= {data_out[33:0], 6'bx};
			end
		end
	endcase
end

always @(posedge clk) begin
	case (state2)
		Idle_s2 : begin
			//if (output_is_begin) begin
				llcnt <= llcnt_next_b;
				lcnt <= lcnt_next_b;
				data_out <= data_out_next_b;
			//end
			ocnt <= 4'd1;
		end
		Lout_5_s2 : begin
			//if (find1) begin
				llcnt <= llcnt_next;
				lcnt <= lcnt_next;
			//end
			data_out <= data_out_next;
			ocnt <= ocnt_add_1;
		end
		Lout_4_s2, Lout_3_s2, Lout_210_s2 : begin
			//if (find1) begin
				llcnt <= llcnt_next;
				lcnt <= lcnt_next;
			//end
			data_out <= data_out_next;
		end
		Lout_s2 : begin
			llcnt <= llcnt_sub_1;
		end
		Dout_s2 : begin
			lcnt <= lcnt_sub_1;
			data_out <= {data_out[38:0], 1'b0};
			if (lcnt_is_end) data_out <= ans[ocnt];
		end
	endcase
end

always @(*) begin
	output_is_end <= 1'b0;
	case (state2)
		Dout_s2 : begin
			if (lcnt_is_end && ocnt_is_end) output_is_end <= 1'b1;
		end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_valid <= 1'b0;
		out_value <= 1'b0;
	end
	else begin
		out_valid <= 1'b0;
		out_value <= 1'b0;
		case (state2)
			Idle_s2 : begin
				if (output_is_begin) begin
					out_valid <= 1'b1;
					out_value <= find1_b;
				end
			end
			Lout_5_s2, Lout_4_s2, Lout_3_s2, Lout_210_s2 : begin
				out_valid <= 1'b1;
				out_value <= find1;
			end
			Lout_s2 : begin
				out_valid <= 1'b1;
				out_value <= lcnt[llcnt];
			end
			Dout_s2 : begin
				out_valid <= 1'b1;
				out_value <= data_out[39];
			end
		endcase
	end
end

endmodule

