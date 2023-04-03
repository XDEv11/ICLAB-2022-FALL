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
input        clk, rst_n, in_valid, in_valid2;
input signed [15:0] matrix;
input [1:0]  matrix_size;
input [3:0]  i_mat_idx, w_mat_idx;

output reg       	     out_valid;
output reg signed [39:0] out_value;
//---------------------------------------------------------------------
//
//---------------------------------------------------------------------
genvar gv_i, gv_j;
integer i, j;

wire signed [15:0] m_Q;
reg m_WEN;
reg [11:0] m_A;
reg signed [15:0] m_D;
sram_4096x16 u_sram_4096x16_m(.Q(m_Q), .CLK(clk), .CEN(1'b0), .WEN(m_WEN), .A(m_A), .D(m_D), .OEN(1'b0));
wire signed [15:0] w_Q [0:15];
reg w_WEN [0:15];
reg [7:0] w_A [0:15];
reg signed [15:0] w_D [0:15];
generate
	for (gv_i = 0; gv_i < 16; gv_i = gv_i + 1) begin:SRAM_BLOCK
		sram_256x16 u_sram_256x16_w(.Q(w_Q[gv_i]), .CLK(clk), .CEN(1'b0), .WEN(w_WEN[gv_i]), .A(w_A[gv_i]), .D(w_D[gv_i]), .OEN(1'b0));
	end
endgenerate

reg signed [15:0] mult_a [0:15];
reg signed [15:0] mult_b [0:15];
wire signed [31:0] mult_product [0:15];
generate
	for (gv_i = 0; gv_i < 16; gv_i = gv_i + 1) begin:MULT_BLOCK
		DW02_mult_2_stage #(.A_width(16), .B_width(16))
			u_DW02_mult_2_stage(.A(mult_a[gv_i]), .B(mult_b[gv_i]), .TC(1'b1), .CLK(clk), .PRODUCT(mult_product[gv_i]));
	end
endgenerate

reg signed [39:0] add_a [0:15];
reg signed [39:0] add_b [0:15];
wire signed [39:0] add_sum [0:15];
generate
	for (gv_i = 0; gv_i < 16; gv_i = gv_i + 1) begin:ADD_BLOCK
		DW01_add #(.width(40))
			u_DW01_add(.A(add_a[gv_i]), .B(add_b[gv_i]), .CI(1'b0), .SUM(add_sum[gv_i]), .CO());
	end
endgenerate

reg [1:0] sz;
reg [3:0] size_sub_1;
reg [3:0] mi, wi;

reg signed [39:0] ans [0:30];

reg [3:0] rcnt;
wire [3:0] rcnt_end = size_sub_1;
wire rcnt_is_end = (rcnt == rcnt_end);
wire [3:0] rcnt_add_1 = rcnt + 4'd1;
wire [3:0] rcnt_next = (rcnt_is_end ? 4'd0 : rcnt_add_1);

reg [3:0] ccnt;
wire [3:0] ccnt_end = size_sub_1;
wire ccnt_is_begin = (ccnt == 4'd0);
wire ccnt_is_end = (ccnt == ccnt_end);
wire [3:0] ccnt_add_1 = ccnt + 4'd1;
wire [3:0] ccnt_next = (ccnt_is_end ? 4'd0 : ccnt_add_1);

reg [3:0] cnt;
wire cnt_eq_15 = (cnt == 4'd15);
wire [3:0] cnt_next = cnt + 4'd1;

localparam [5:0] wait_cycles = 6'd4;
reg [5:0] ocnt;
//wire signed [5:0] _ocnt_sub_wait_cycles = ocnt - wait_cycles;
//wire output_is_begin = !_ocnt_sub_wait_cycles[5];
//wire [4:0] ocnt_sub_wait_cycles = (output_is_begin ? _ocnt_sub_wait_cycles[4:0] : 5'd0);
//wire output_is_end = (ocnt_sub_wait_cycles == {size_sub_1, 1'b0});
wire output_is_begin = (ocnt >= wait_cycles);
wire output_is_end = (ocnt == {size_sub_1, 1'b0} + wait_cycles);
wire [5:0] ocnt_add_1 = ocnt + 6'd1;

reg [4:0] icnt;
wire [4:0] icnt_add_1 = icnt + 5'd1;

reg [2:0] state, nxt_state;
localparam Idle1	= 3'd0;
localparam Readm	= 3'd1;
localparam Readw	= 3'd2;
localparam Idle2	= 3'd3;
localparam Wait		= 3'd4;
localparam Work		= 3'd5;
localparam Output	= 3'd6;

always @(*) begin
	nxt_state <= state;
	case (state)
		Idle1 :
			if (in_valid) begin
				nxt_state <= Readm;
			end
		Readm :
			//if (in_valid) begin
				if (ccnt_is_end && rcnt_is_end && cnt_eq_15) nxt_state <= Readw;
			//end
		Readw :
			//if (in_valid) begin
				if (ccnt_is_end && rcnt_is_end && cnt_eq_15) nxt_state <= Idle2;
			//end
		Idle2 :
			if (in_valid2) begin
				nxt_state <= Wait;
			end
		Wait : nxt_state <= Work;
		Work :
			if (ccnt_is_end && rcnt_is_end) nxt_state <= Output;
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
	m_A <= 12'bx;
	m_D <= 16'sbx;
	for (i = 0; i < 16; i = i + 1) begin
		w_WEN[i] <= 1'b1;
		w_A[i] <= 8'bx;
		w_D[i] <= 16'sbx;
	end
	case (state)
		Idle1 : begin
			//if(in_valid) begin
				m_WEN <= 1'b0;
				m_A <= {4'd0, 4'd0, 4'd0};
				m_D <= matrix;
			//end
		end
		Readm : begin
			//if(in_valid) begin
				m_WEN <= 1'b0;
				m_A <= {cnt, rcnt, ccnt};
				m_D <= matrix;
			//end
		end
		Readw : begin
			//if(in_valid) begin
				w_WEN[ccnt] <= 1'b0;
				w_A[ccnt] <= {cnt, rcnt};
				w_D[ccnt] <= matrix;
			//end
		end
		Wait : begin
			m_A <= {mi, 4'd0, 4'd0};
			for (i = 0; i < 16; i = i + 1) w_A[i] <= {wi, 4'd0};
		end
		Work : begin
			//if (!(ccnt_is_end && rcnt_is_end)) begin
				if (ccnt_is_end) m_A <= {mi, rcnt_next, ccnt_next};
				else m_A <= {mi, rcnt, ccnt_next};
				for (i = 0; i < 16; i = i + 1) w_A[i] <= {wi, ccnt_next};
			//end
		end
	endcase
end

reg reset_flag, reset_flag_mult, reset_flag_add;
always @(posedge clk) begin
	reset_flag <= 1'b0;
	reset_flag_mult <= reset_flag;
	reset_flag_add <= reset_flag_mult;
	case (state)
		Wait : begin
			reset_flag <= 1'b1;
		end
	endcase
end

reg shift_flag, shift_flag_mult, shift_flag_add;
always @(posedge clk) begin
	shift_flag <= 1'b0;
	shift_flag_mult <= shift_flag;
	shift_flag_add <= shift_flag_mult;
	case (state)
		Work : begin
			if (ccnt_is_end && !rcnt_is_end) shift_flag <= 1'b1;
		end
	endcase
end

reg signed [15:0] _mult_a [0:15];
reg signed [15:0] _mult_b [0:15];
always @(posedge clk) begin
	for (i = 0; i < 16; i = i + 1) begin
		_mult_a[i] <= 16'sd0;
		_mult_b[i] <= 16'sd0;
	end
	case (state)
		Work : begin
			for (i = 0; i < 16; i = i + 1) begin
				_mult_a[i] <= m_Q;
				_mult_b[i] <= w_Q[i];
			end
		end
	endcase
end

always @(*) begin
	for (i = 0; i < 16; i = i + 1) begin
		mult_a[i] <= _mult_a[i];
		mult_b[i] <= _mult_b[i];
	end
end

reg signed [31:0] _mult_product [0:15];
always @(posedge clk) begin
	for (i = 0; i < 16; i = i + 1) begin
		_mult_product[i] <= mult_product[i];
	end
end

always @(*) begin
	for (i = 0; i < 16; i = i + 1) begin
		add_a[i] <= ans[15 + i];
		add_b[i] <= _mult_product[i];
	end
end

reg signed [39:0] ans_temp [0:30];
always @(*) begin
	for (i = 0; i < 15; i = i + 1) begin
		ans_temp[i] <= ans[i];
	end
	for (i = 15; i < 31; i = i + 1) begin
		ans_temp[i] <= add_sum[i - 15];
	end
end

reg signed [39:0] ans_next [0:30];
always @(*) begin
	if (reset_flag_add) begin
		for (i = 0; i < 31; i = i + 1) begin
			ans_next[i] <= 40'd0;
		end
	end
	else if (shift_flag_add) begin
		for (i = 0; i < 31; i = i + 1) begin
			if (i == 16) begin
				if (sz == 2'b00) ans_next[16] <= 40'sb0;
				else ans_next[16] <= ans_temp[17];
			end
			else if (i == 18) begin
				if (sz == 2'b01) ans_next[18] <= 40'sb0;
				else ans_next[18] <= ans_temp[19];
			end
			else if (i == 22) begin
				if (sz == 2'b10) ans_next[22] <= 40'sb0;
				else ans_next[22] <= ans_temp[23];
			end
			else if (i == 30) begin
				ans_next[30] <= 40'sb0;
			end
			else begin
				ans_next[i] <= ans_temp[i + 1];
			end
		end
	end
	else begin
		for (i = 0; i < 31; i = i + 1) begin
			ans_next[i] <= ans_temp[i];
		end
	end
end

always @(posedge clk) begin
	for (i = 0; i < 31; i = i + 1) begin
		ans[i] <= ans_next[i];
	end
end

always @(posedge clk) begin
	ccnt <= 4'd0; //
	ocnt <= 6'd0; //
	icnt <= 5'd15 - size_sub_1; //
	case (state)
		Idle1 : begin
			//if (in_valid) begin
				sz <= matrix_size;
				case (matrix_size)
					2'b00 : size_sub_1 <= 4'd1;
					2'b01 : size_sub_1 <= 4'd3;
					2'b10 : size_sub_1 <= 4'd7;
					2'b11 : size_sub_1 <= 4'd15;
				endcase
				ccnt <= 4'd1;
				rcnt <= 4'd0;
				cnt <= 4'd0;
			//end
		end
		Readm : begin
			//if (in_valid) begin
				ccnt <= ccnt_next;
				if (ccnt_is_end) rcnt <= rcnt_next;
				if (ccnt_is_end && rcnt_is_end) cnt <= cnt_next;
			//end
		end
		Readw : begin
			//if (in_valid) begin
				ccnt <= ccnt_next;
				if (ccnt_is_end) rcnt <= rcnt_next;
				if (ccnt_is_end && rcnt_is_end) cnt <= cnt_next;
			//end
		end
		Idle2 : begin
			//if (in_valid2) begin
				mi <= i_mat_idx;
				wi <= w_mat_idx;
				ocnt <= 6'd0;
				icnt <= 5'd15 - size_sub_1;
			//end
		end
		Work : begin
			ccnt <= ccnt_next;
			if (ccnt_is_end) rcnt <= rcnt_next;
			if (rcnt_is_end) ocnt <= ocnt_add_1;
			if (output_is_begin) icnt <= icnt_add_1;
		end
		Output : begin
			ocnt <= ocnt_add_1;
			if (output_is_begin) icnt <= icnt_add_1;
			if (output_is_end) cnt <= cnt_next;
		end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_valid <= 1'b0;
		out_value <= 40'sb0;
	end
	else begin
		out_valid <= 1'b0;
		out_value <= 40'sbx;
		case (state)
			Work, Output : begin
				if (output_is_begin) begin
					out_valid <= 1'b1;
					out_value <= ans[icnt];
				end
			end
		endcase
	end
end

endmodule





