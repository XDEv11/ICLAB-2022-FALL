// synopsys translate_off

`include ...

// synopsys translate_on

module MH (
	clk,
	clk2,
	rst_n,
	in_valid,
	op_valid,
	pic_data,
	se_data,
	op,
	out_valid,
	out_data
);
input			clk;
input			clk2;
input			rst_n;
input			in_valid;
input			op_valid;
input [31:0]	pic_data;
input [7:0]		se_data;
input [2:0]		op;
output reg			out_valid;
output reg [31:0]	out_data;
// 
integer i, j;
genvar gv_i, gv_j;

localparam EROSION	= 3'b010;
localparam DILATION	= 3'b011;
localparam HIS_EQ	= 3'b000;
localparam OPENING	= 3'b110;
localparam CLOSING	= 3'b111;

reg _in_valid;
reg [43:0] _in_data;
always @(*) begin
	_in_valid <= in_valid;
	_in_data <= {op_valid, op, se_data, pic_data};
end
wire datain_valid;
wire [43:0] datain;
DW_data_qsync_lh #(.width(44), .clk_ratio(4), .reg_data_s(1), .reg_data_d(1), .tst_mode(0))
	u_DW_data_qsync_lh(.clk_s(clk), .rst_s_n(rst_n), .init_s_n(1'b1), .send_s(_in_valid), .data_s(_in_data),
		.clk_d(clk2), .rst_d_n(rst_n), .init_d_n(1'b1), .data_avail_d(datain_valid), .data_d(datain), .test());

reg dataout_valid;
reg [31:0] dataout;
wire _out_valid;
wire [31:0] _out_data;
DW_data_qsync_hl #(.width(32), .clk_ratio(4), .tst_mode(0))
	u_DW_data_qsync_hl(.clk_s(clk2), .rst_s_n(rst_n), .init_s_n(1'b1), .send_s(dataout_valid), .data_s(dataout),
		.clk_d(clk), .rst_d_n(rst_n), .init_d_n(1'b1), .test(), .data_d(_out_data), .data_avail_d(_out_valid));
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_valid <= 1'b0;
		out_data <= 32'b0;
	end
	else begin
		out_valid <= 1'b0;
		out_data <= 32'b0;
		if (_out_valid) begin
			out_valid <= 1'b1;
			out_data <= _out_data;
		end
	end
end

wire [31:0] sram_Q;
reg sram_WEN;
reg [7:0] sram_A;
reg [31:0] sram_D;
sram_256x32 u_sram_256x32(.Q(sram_Q), .CLK(clk2), .CEN(1'b0), .WEN(sram_WEN), .A(sram_A), .D(sram_D), .OEN(1'b0));
//
reg [7:0] data_buffer [0:3][0:31];
reg [7:0] data_temp [0:3];
reg [2:0] data_op;
reg [7:0] data_se [0:3][0:3];

reg [9:0] cdf [0:255];
reg [9:0] cdf_min;
reg [7:0] cdf_min_idx;

reg [4:0] state, nxt_state;
localparam Idle		= 5'd0;
localparam Read1	= 5'd1;
localparam Read2	= 5'd2;
localparam Read3	= 5'd3;
localparam Read4	= 5'd4;
localparam Out_ED1	= 5'd5;
localparam Out_ED2	= 5'd6;
localparam Out_ED3	= 5'd7;
localparam Out_ED4	= 5'd8;
localparam Tmp_OC1	= 5'd9;
localparam Tmp_OC2	= 5'd10;
localparam Tmp_OC3	= 5'd11;
localparam Tmp_OC4	= 5'd12;
localparam Out_OC1	= 5'd13;
localparam Out_OC2	= 5'd14;
localparam Out_OC3	= 5'd15;
localparam Out_OC4	= 5'd16;
localparam Out_OC5	= 5'd17;
localparam Out_OC6	= 5'd18;
localparam Out_HE1	= 5'd19;
localparam Out_HE2	= 5'd20;
localparam Out_HE3	= 5'd21;
localparam Out_HE4	= 5'd22;
localparam Out_HE5	= 5'd23;
localparam Out_HE6	= 5'd24;
localparam Out_HE7	= 5'd25;
localparam Out_HE8	= 5'd26;

reg [7:0] cnt;
wire [7:0] cnt_add_1	= cnt + 8'd1;
wire [7:0] cnt_sub_33	= cnt - 8'd33;
wire cnt_eq_0	= (cnt == 8'd0);
wire cnt_eq_1	= (cnt == 8'd1);
wire cnt_eq_31	= (cnt == 8'd31);
wire cnt_eq_255	= (cnt == 8'd255);
wire cnt_ne_32	= (cnt != 8'd32);
wire cnt_lt_16	= (cnt < 8'd16);
wire cnt_lt_32	= (cnt < 8'd32);
wire cnt_gt_1	= (cnt > 8'd1);
wire cnt_ge_8	= (cnt >= 8'd8);
wire cnt_ge_16	= (cnt >= 8'd16);
wire cnt_ge_24	= (cnt >= 8'd24);
wire cnt_bt_24_31	= (cnt_lt_32 && cnt_ge_24);
wire cnt_bt_16_31	= (cnt_lt_32 && cnt_ge_16);
wire cnt_bt_8_31	= (cnt_lt_32 && cnt_ge_8);
wire cnt_eq_last_col = (cnt[2:0] == 3'd7);

always @(*) begin
	nxt_state <= state;
	case (state)
		Idle :
			if (datain_valid) nxt_state <= Read2;
		Read1 : nxt_state <= Read2;
		Read2 : nxt_state <= Read3;
		Read3 : nxt_state <= Read4;
		Read4 :
			if (cnt_eq_255) begin
				case (data_op)
					EROSION, DILATION : nxt_state <= Out_ED1;
					OPENING, CLOSING : nxt_state <= Tmp_OC1;
					HIS_EQ : nxt_state <= Out_HE1;
				endcase
			end
			else nxt_state <= Read1;
		Out_ED1 : nxt_state <= Out_ED2;
		Out_ED2 : nxt_state <= Out_ED3;
		Out_ED3 : nxt_state <= Out_ED4;
		Out_ED4 :
			if (cnt_eq_255) nxt_state <= Idle;
			else nxt_state <= Out_ED1;
		Tmp_OC1 : nxt_state <= Tmp_OC2;
		Tmp_OC2 : nxt_state <= Tmp_OC3;
		Tmp_OC3 : nxt_state <= Tmp_OC4;
		Tmp_OC4 :
			if (cnt_eq_31) nxt_state <= Out_OC1;
			else nxt_state <= Tmp_OC1;
		Out_OC1 : nxt_state <= Out_OC2;
		Out_OC2 : nxt_state <= Out_OC3;
		Out_OC3 : nxt_state <= Out_OC4;
		Out_OC4 :
			if (cnt_eq_31) nxt_state <= Out_OC5;
			else nxt_state <= Out_OC1;
		Out_OC5 : nxt_state <= Out_OC6;
		Out_OC6 : nxt_state <= Idle;
		Out_HE1 : nxt_state <= Out_HE2;
		Out_HE2 : nxt_state <= Out_HE3;
		Out_HE3 : nxt_state <= Out_HE4;
		Out_HE4 :
			if (cnt_eq_255) nxt_state <= Out_HE5;
			else nxt_state <= Out_HE1;
		Out_HE5 : nxt_state <= Out_HE6;
		Out_HE6 : nxt_state <= Out_HE7;
		Out_HE7 : nxt_state <= Out_HE8;
		Out_HE8 :
			if (cnt_eq_1) nxt_state <= Idle;
			else nxt_state <= Out_HE5;
	endcase
end

always @(posedge clk2 or negedge rst_n) begin
	if (!rst_n) state <= Idle;
	else state <= nxt_state;
end

//
reg ed_flag0;
always @(*) begin
	ed_flag0 <= 1'bx;
	case (state)
		Read1, Read2, Read3, Read4, Out_ED1, Out_ED2, Out_ED3, Out_ED4, Tmp_OC1, Tmp_OC2, Tmp_OC3, Tmp_OC4 : begin
			case (data_op)
				EROSION, OPENING : ed_flag0 <= 1'b1;
				DILATION, CLOSING : ed_flag0 <= 1'b0;
			endcase
		end
		Out_OC1, Out_OC2, Out_OC3, Out_OC4 : begin
			case (data_op)
				OPENING : ed_flag0 <= 1'b0;
				CLOSING : ed_flag0 <= 1'b1;
			endcase
		end
	endcase
end
reg [7:0] ed_se [0:3][0:3];
always @(*) begin
	for (i = 0; i < 4; i = i + 1)
		for (j = 0; j < 4; j = j + 1)
			if (ed_flag0) begin
				ed_se[i][j] <= data_se[i][j];
			end
			else begin
				ed_se[i][j] <= data_se[3 - i][3 - j];
			end
end
reg [7:0] ed_data0_1 [0:3][0:3];
always @(*) begin
	for (i = 0; i < 4; i = i + 1)
		for (j = 0; j < 4; j = j + 1) begin
			ed_data0_1[i][j] <= 8'bx;
		end
	case (state)
		Read1, Out_ED1, Tmp_OC1, Out_OC1 : begin
			for (j = 0; j < 4; j = j + 1) begin
				ed_data0_1[0][j] <= data_buffer[0][j];
			end
			for (j = 0; j < 4; j = j + 1) begin
				if (cnt_bt_24_31) ed_data0_1[1][j] <= 8'd0;
				else ed_data0_1[1][j] <= data_buffer[1][j];
			end
			for (j = 0; j < 4; j = j + 1) begin
				if (cnt_bt_16_31) ed_data0_1[2][j] <= 8'd0;
				else ed_data0_1[2][j] <= data_buffer[2][j];
			end
			for (j = 0; j < 4; j = j + 1) begin
				if (cnt_bt_8_31) ed_data0_1[3][j] <= 8'd0;
				else ed_data0_1[3][j] <= data_buffer[3][j];
			end
		end
		Read2, Out_ED2, Tmp_OC2, Out_OC2 : begin
			for (j = 0; j < 4; j = j + 1)
				if (j == 3) begin
					ed_data0_1[0][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[0][j]);
				end
				else begin
					ed_data0_1[0][j] <= data_buffer[0][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3) begin
					if (cnt_bt_24_31) ed_data0_1[1][j] <= 8'd0;
					else ed_data0_1[1][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[1][j]);
				end
				else begin
					if (cnt_bt_24_31) ed_data0_1[1][j] <= 8'd0;
					else ed_data0_1[1][j] <= data_buffer[1][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3) begin
					if (cnt_bt_16_31) ed_data0_1[2][j] <= 8'd0;
					else ed_data0_1[2][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[2][j]);
				end
				else begin
					if (cnt_bt_16_31) ed_data0_1[2][j] <= 8'd0;
					else ed_data0_1[2][j] <= data_buffer[2][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3) begin
					if (cnt_bt_8_31) ed_data0_1[3][j] <= 8'd0;
					else ed_data0_1[3][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[3][j]);
				end
				else begin
					if (cnt_bt_8_31) ed_data0_1[3][j] <= 8'd0;
					else ed_data0_1[3][j] <= data_buffer[3][j];
				end
		end
		Read3, Out_ED3, Tmp_OC3, Out_OC3 : begin
			for (j = 0; j < 4; j = j + 1)
				if (j == 3 || j == 2) begin
					ed_data0_1[0][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[0][j]);
				end
				else begin
					ed_data0_1[0][j] <= data_buffer[0][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3 || j == 2) begin
					if (cnt_bt_24_31) ed_data0_1[1][j] <= 8'd0;
					else ed_data0_1[1][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[1][j]);
				end
				else begin
					if (cnt_bt_24_31) ed_data0_1[1][j] <= 8'd0;
					else ed_data0_1[1][j] <= data_buffer[1][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3 || j == 2) begin
					if (cnt_bt_16_31) ed_data0_1[2][j] <= 8'd0;
					else ed_data0_1[2][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[2][j]);
				end
				else begin
					if (cnt_bt_16_31) ed_data0_1[2][j] <= 8'd0;
					else ed_data0_1[2][j] <= data_buffer[2][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3 || j == 2) begin
					if (cnt_bt_8_31) ed_data0_1[3][j] <= 8'd0;
					else ed_data0_1[3][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[3][j]);
				end
				else begin
					if (cnt_bt_8_31) ed_data0_1[3][j] <= 8'd0;
					else ed_data0_1[3][j] <= data_buffer[3][j];
				end
		end
		Read4, Out_ED4, Tmp_OC4, Out_OC4 : begin
			for (j = 0; j < 4; j = j + 1)
				if (j == 3 || j == 2 || j == 1) begin
					ed_data0_1[0][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[0][j]);
				end
				else begin
					ed_data0_1[0][j] <= data_buffer[0][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3 || j == 2 || j == 1) begin
					if (cnt_bt_24_31) ed_data0_1[1][j] <= 8'd0;
					else ed_data0_1[1][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[1][j]);
				end
				else begin
					if (cnt_bt_24_31) ed_data0_1[1][j] <= 8'd0;
					else ed_data0_1[1][j] <= data_buffer[1][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3 || j == 2 || j == 1) begin
					if (cnt_bt_16_31) ed_data0_1[2][j] <= 8'd0;
					else ed_data0_1[2][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[2][j]);
				end
				else begin
					if (cnt_bt_16_31) ed_data0_1[2][j] <= 8'd0;
					else ed_data0_1[2][j] <= data_buffer[2][j];
				end
			for (j = 0; j < 4; j = j + 1)
				if (j == 3 || j == 2 || j == 1) begin
					if (cnt_bt_8_31) ed_data0_1[3][j] <= 8'd0;
					else ed_data0_1[3][j] <= (cnt_eq_last_col ? 8'd0 : data_buffer[3][j]);
				end
				else begin
					if (cnt_bt_8_31) ed_data0_1[3][j] <= 8'd0;
					else ed_data0_1[3][j] <= data_buffer[3][j];
				end
		end
	endcase
end

wire [8:0] ed_data0_2 [0:3][0:3];
for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
	for (gv_j = 0; gv_j < 4; gv_j = gv_j + 1) begin
		DW01_addsub#(.width(8))
			u_DW01_addsub(.A(ed_data0_1[gv_i][gv_j]), .B(ed_se[gv_i][gv_j]), .CI(1'b0), .ADD_SUB(ed_flag0), .SUM(ed_data0_2[gv_i][gv_j][7:0]), .CO(ed_data0_2[gv_i][gv_j][8]));
	end
end

reg ed_flag1;
reg [7:0] ed_data1 [0:3][0:3];
wire [7:0] _ed_data1 [0:3][0:3];
for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
	for (gv_j = 0; gv_j < 4; gv_j = gv_j + 1) begin
		assign _ed_data1[gv_i][gv_j] = (ed_data0_2[gv_i][gv_j][8] ? (ed_flag0 ? 8'd0 : 8'd255) : ed_data0_2[gv_i][gv_j][7:0]);
	end
end
always @(posedge clk2) begin
	ed_flag1 <= ed_flag0;
	for (i = 0; i < 4; i = i + 1)
		for (j = 0; j < 4; j = j + 1) begin
			ed_data1[i][j] <= _ed_data1[i][j];
		end
end
wire [127:0] ed_data1_flatten;
for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
	for (gv_j = 0; gv_j < 4; gv_j = gv_j + 1) begin
		assign ed_data1_flatten[(gv_i * 4 + gv_j) * 8 + 7-:8] = ed_data1[gv_i][gv_j];
	end
end

reg [31:0] ed_res;
wire [7:0] _ed_res;
DW_minmax#(.width(8), .num_inputs(16))
	u_DW_minmax(.a(ed_data1_flatten), .tc(1'b0), .min_max(!ed_flag1), .value(_ed_res), .index());
always @(posedge clk2) begin
	ed_res[ 7: 0] <= ed_res[15: 8];
	ed_res[15: 8] <= ed_res[23:16];
	ed_res[23:16] <= ed_res[31:24];
	ed_res[31:24] <= _ed_res;
end

//
reg [9:0] cdf_next [0:255];
reg [9:0] cdf_min_next;
reg [7:0] cdf_min_idx_next;
always @(*) begin
	for (i = 0; i < 256; i = i + 1) begin
		if (i >= data_temp[0]) cdf_next[i] <= cdf[i] + 10'd1;
		else cdf_next[i] <= cdf[i];
	end
end
always @(*) begin
	if (cdf_min_idx >= data_temp[0]) begin
		cdf_min_next <= cdf[data_temp[0]] + 10'd1;
		cdf_min_idx_next <= data_temp[0];
	end
	else begin
		cdf_min_next <= cdf_min;
		cdf_min_idx_next <= cdf_min_idx;
	end
end

reg [9:0] he_cdf_max_sub_cdf_min;
wire [9:0] _he_cdf_max_sub_cdf_min = 11'd1024 - cdf_min;
always @(posedge clk2) begin
	he_cdf_max_sub_cdf_min <= _he_cdf_max_sub_cdf_min;
end

reg [9:0] he_cdfi;
wire [9:0] _he_cdfi = cdf[data_temp[0]];
always @(posedge clk2) begin
	he_cdfi <= _he_cdfi;
end

reg [17:0] he_cdfi_sub_cdf_minx255;
wire [9:0] _he_cdfi_sub_cdf_min = he_cdfi - cdf_min;
wire [17:0] _he_cdfi_sub_cdf_minx255 = _he_cdfi_sub_cdf_min * 8'd255;
always @(posedge clk2) begin
	he_cdfi_sub_cdf_minx255 <= _he_cdfi_sub_cdf_minx255;
end

wire [17:0] rq_cur [0:7];
wire [17:0] _rq_nxt [0:7];
wire [10:0] _rq_temp_0 [0:7];
wire signed [11:0] _rq_temp_1 [0:7];
reg [17:0] _rq_nxt_reg [0:7];
generate
	assign rq_cur[0] = he_cdfi_sub_cdf_minx255;
	for (gv_i = 1; gv_i < 8; gv_i = gv_i + 1) begin
		assign rq_cur[gv_i] = _rq_nxt_reg[gv_i - 1];
	end
	for (gv_i = 0; gv_i < 8; gv_i = gv_i + 1) begin
		assign _rq_temp_0[gv_i] = rq_cur[gv_i][17:7];
		assign _rq_temp_1[gv_i] = _rq_temp_0[gv_i] - he_cdf_max_sub_cdf_min;
		assign _rq_nxt[gv_i] = (_rq_temp_1[gv_i][11] ?
			{_rq_temp_0[gv_i][9:0], rq_cur[gv_i][6:0], 1'b0} :
			{_rq_temp_1[gv_i][9:0], rq_cur[gv_i][6:0], 1'b1});
	end
	for (gv_i = 0; gv_i < 8; gv_i = gv_i + 1) begin
		if (gv_i % 2 == 1) begin
			always @(posedge clk2) begin
				_rq_nxt_reg[gv_i] <= _rq_nxt[gv_i];
			end
		end
		else begin
			always @(*) begin
				_rq_nxt_reg[gv_i] <= _rq_nxt[gv_i];
			end
		end
	end
endgenerate

reg [31:0] he_res;
wire [7:0] _he_res = _rq_nxt[7][7:0];
always @(posedge clk2) begin
	he_res[ 7: 0] <= he_res[15: 8];
	he_res[15: 8] <= he_res[23:16];
	he_res[23:16] <= he_res[31:24];
	he_res[31:24] <= _he_res;
end

always @(*) begin
	sram_WEN <= 1'b1;
	sram_A <= cnt_add_1;
	sram_D <= 32'bx;
	case (state)
		Idle : begin
			sram_WEN <= 1'b0;
			sram_A <= cnt;
			sram_D <= datain[31:0];
		end
		Read1 : begin
			sram_WEN <= 1'b0;
			sram_A <= cnt;
			sram_D <= datain[31:0];
		end
		Read2 : begin
			if (!cnt_lt_16 && data_op != HIS_EQ) begin
				sram_WEN <= 1'b0;
				sram_A <= cnt_sub_33;
				sram_D <= ed_res;
			end
		end
		Out_ED2, Tmp_OC2, Out_OC2 : begin
			sram_WEN <= 1'b0;
			sram_A <= cnt_sub_33;
			sram_D <= ed_res;
		end
	endcase
end

always @(posedge clk2) begin
	case (state)
		Idle : begin
			cnt <= 8'd0;
		end
		Read4, Out_ED4, Tmp_OC4, Out_OC4, Out_HE4, Out_HE8 : begin
			cnt <= cnt_add_1;
		end
	endcase
end

always @(posedge clk2) begin
	for (i = 0; i < 4; i = i + 1)
		for (j = 0; j < 32; j = j + 1)
			if (i == 3 && j == 31) begin
				data_buffer[3][31] <= 8'bx;
			end
			else if (j == 31) begin
				data_buffer[i][31] <= data_buffer[i + 1][0];
			end
			else begin
				data_buffer[i][j] <= data_buffer[i][j + 1];
			end
	case (state)
		Idle, Read1 : begin
			data_buffer[3][31] <= datain[7:0];
			if (datain[43]) begin
				data_op <= datain[42:40];
			end
			if (cnt_lt_16) begin
				for (i = 0; i < 4; i = i + 1)
					for (j = 0; j < 4; j = j + 1)
						if (i == 3 && j == 3) begin
							data_se[3][3] <= datain[39:32];
						end
						else if (j == 3) begin
							data_se[i][3] <= data_se[i + 1][0];
						end
						else begin
							data_se[i][j] <= data_se[i][j + 1];
						end
			end
		end
		Read2 : begin
			data_buffer[3][31] <= datain[15:8];
		end
		Read3 : begin
			data_buffer[3][31] <= datain[23:16];
		end
		Read4 : begin
			data_buffer[3][31] <= datain[31:24];
		end
		Out_ED1, Tmp_OC1, Out_OC1 : begin
			data_buffer[3][31] <= sram_Q[7:0];
		end
		Out_ED2, Out_ED3, Out_ED4, Tmp_OC2, Tmp_OC3, Tmp_OC4, Out_OC2, Out_OC3, Out_OC4 : begin
			data_buffer[3][31] <= data_temp[1];
		end
	endcase
end

always @(posedge clk2) begin
	data_temp[0] <= data_temp[1];
	data_temp[1] <= data_temp[2];
	data_temp[2] <= data_temp[3];
	data_temp[3] <= 8'bx;
	case (state)
		Idle, Read1 : begin
			data_temp[0] <= datain[7:0];
			data_temp[1] <= datain[15:8];
			data_temp[2] <= datain[23:16];
			data_temp[3] <= datain[31:24];
		end
		Out_ED1, Tmp_OC1, Out_OC1, Out_HE1 : begin
			data_temp[0] <= sram_Q[7:0];
			data_temp[1] <= sram_Q[15:8];
			data_temp[2] <= sram_Q[23:16];
			data_temp[3] <= sram_Q[31:24];
		end
	endcase
end

always @(posedge clk2) begin //= =
	case (state)
		Idle : begin
			for (i = 0; i < 256; i = i + 1) begin
				cdf[i] <= 10'd0;
			end
		end
		Read1, Read2, Read3, Read4 : begin
			for (i = 0; i < 256; i = i + 1) begin
				cdf[i] <= cdf_next[i];
			end
		end
		Out_HE1 : begin
			for (i = 0; i < 256; i = i + 1) begin
				if (cnt_eq_0) cdf[i] <= cdf_next[i];
			end
		end
	endcase
end

always @(posedge clk2) begin
	case (state)
		Idle : begin
			cdf_min_idx <= 8'd255;
		end
		Read1, Read2, Read3, Read4 : begin
			cdf_min <= cdf_min_next;
			cdf_min_idx <= cdf_min_idx_next;
		end
		Out_HE1 : begin
			if (cnt_eq_0) begin
				cdf_min <= cdf_min_next;
				cdf_min_idx <= cdf_min_idx_next;
			end
		end
	endcase
end

always @(posedge clk2) begin
	dataout_valid <= 1'b0;
	dataout <= 32'b0;
	case (state)
		Out_ED1 : begin
			dataout_valid <= 1'b1;
			dataout <= sram_Q;
		end
		Out_OC2 : begin
			if (cnt_ne_32) begin
				dataout_valid <= 1'b1;
				dataout <= ed_res;
			end
		end
		Out_OC6 : begin
			dataout_valid <= 1'b1;
			dataout <= ed_res;
		end
		Out_HE3 : begin
			if (cnt_gt_1) begin
				dataout_valid <= 1'b1;
				dataout <= he_res;
			end
		end
		Out_HE7 : begin
			dataout_valid <= 1'b1;
			dataout <= he_res;
		end
	endcase
end

endmodule
