// synopsys translate_off

`include ...

// synopsys translate_on

module EDH#(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32) (
	//Connection wires
	input clk,
	input rst_n,
	input in_valid,
	input [1:0] op,
	input [3:0] pic_no,     
	input [5:0] se_no,     
	output reg busy,          
	// axi write address channel 
	output     [ID_WIDTH-1:0] awid_m_inf,
	output reg [ADDR_WIDTH-1:0] awaddr_m_inf,
	output     [2:0] awsize_m_inf,
	output     [1:0] awburst_m_inf,
	output reg [7:0] awlen_m_inf,
	output reg awvalid_m_inf,
	input awready_m_inf,
	// axi write data channel 
	output reg [DATA_WIDTH-1:0] wdata_m_inf,
	output reg wlast_m_inf,
	output reg wvalid_m_inf,
	input wready_m_inf,
	// axi write response channel
	input [ID_WIDTH-1:0] bid_m_inf,
	input [1:0] bresp_m_inf,
	input bvalid_m_inf,
	output reg bready_m_inf,
	// -----------------------------
	// axi read address channel 
	output     [ID_WIDTH-1:0] arid_m_inf,
	output reg [ADDR_WIDTH-1:0] araddr_m_inf,
	output reg [7:0] arlen_m_inf,
	output     [2:0] arsize_m_inf,
	output     [1:0] arburst_m_inf,
	output reg arvalid_m_inf,
	input arready_m_inf,
	// -----------------------------
	// axi read data channel 
	input [ID_WIDTH-1:0] rid_m_inf,
	input [DATA_WIDTH-1:0] rdata_m_inf,
	input [1:0] rresp_m_inf,
	input rlast_m_inf,
	input rvalid_m_inf,
	output reg rready_m_inf
	// -----------------------------
);
integer i, j, k;
genvar gv_i, gv_j, gv_k;

reg [1:0] op_reg;
reg [3:0] pic_no_reg;
reg [5:0] se_no_reg;
reg [7:0] se [0:3][0:3];

wire [127:0] sram_Q;
reg sram_WEN;
reg [7:0] sram_A;
reg [127:0] sram_D;
sram_256x128 u_sram_256x128(.Q(sram_Q), .CLK(clk), .CEN(1'b0), .WEN(sram_WEN), .A(sram_A), .D(sram_D), .OEN(1'b0));

reg [127:0] word;
reg [127:0] temp;
/*------------------------------*/

localparam ed_lat = 16 + 3;
reg ed_reset;
reg ed_stall;
reg [127:0] ed_input;
reg [127:0] ed_res;

reg [7:0] ed_data [0:3][0:63];
reg ed_data_flag [0:3];

wire [7:0] _ed_data [0:3][0:63];
wire _ed_data_flag [0:3];
generate
	for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
		for (gv_j = 0; gv_j < 4; gv_j = gv_j + 1) begin
			for (gv_k = 0; gv_k < 16; gv_k = gv_k + 1) begin
				if (gv_j == 3) begin
					if (gv_i == 3) begin
						assign _ed_data[3][48 + gv_k] = ed_input[gv_k * 8 + 7-:8];
					end
					else begin
						assign _ed_data[gv_i][48 + gv_k] = ed_data[gv_i + 1][gv_k];
					end
				end
				else begin
					assign _ed_data[gv_i][gv_j * 16 + gv_k] = ed_data[gv_i][gv_j * 16 + 16 + gv_k];
				end
			end
		end
		assign _ed_data_flag[gv_i] = ed_data_flag[(gv_i + 1) % 4];
	end
endgenerate
always @(posedge clk) begin
	if (!ed_stall) begin
		for (i = 0; i < 4; i = i + 1)
			for (j = 0; j < 64; j = j + 1) ed_data[i][j] <= _ed_data[i][j];
	end
	if (ed_reset) begin
		ed_data_flag[0] <= 1'b0; ed_data_flag[1] <= 1'b0; ed_data_flag[2] <= 1'b0; ed_data_flag[3] <= 1'b1;
	end
	else if (!ed_stall) begin
		for (i = 0; i < 4; i = i + 1) ed_data_flag[i] <= _ed_data_flag[i];
	end
end

wire [127:0] _ed_res;
generate
	wire [7:0] _ed_data0 [0:3][0:18];
	for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
		for (gv_j = 0; gv_j < 16; gv_j = gv_j + 1) begin
			assign _ed_data0[gv_i][gv_j] = ed_data[gv_i][gv_j];
		end
		for (gv_j = 16; gv_j < 19; gv_j = gv_j + 1) begin
			assign _ed_data0[gv_i][gv_j] = (ed_data_flag[0] ? 8'd0 : ed_data[gv_i][gv_j]);
		end
	end
	for (gv_k = 0; gv_k < 16; gv_k = gv_k + 1) begin
		wire signed [9:0] _data1 [0:3][0:3];
		for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
			for (gv_j = 0; gv_j < 4; gv_j = gv_j + 1) begin
				DW01_addsub#(.width(10)) u_DW01_addsub(.A({2'b0, _ed_data0[gv_i][gv_k + gv_j]}), .B({2'b0, se[gv_i][gv_j]}), .CI(1'b0), .ADD_SUB(~op_reg[0]), .SUM(_data1[gv_i][gv_j]), .CO());
			end
		end

		reg [7:0] data2 [0:3][0:3];
		wire [7:0] _data2 [0:3][0:3];
		for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
			for (gv_j = 0; gv_j < 4; gv_j = gv_j + 1) begin
				assign _data2[gv_i][gv_j] = (_data1[gv_i][gv_j][9] ? 8'd0 : (_data1[gv_i][gv_j][8] ? 8'd255 : _data1[gv_i][gv_j]));
			end
		end
		always @(posedge clk) begin
			for (i = 0; i < 4; i = i + 1)
				for (j = 0; j < 4; j = j + 1) data2[i][j] <= _data2[i][j];
		end
		wire [127:0] data2_flatten;
		for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
			for (gv_j = 0; gv_j < 4; gv_j = gv_j + 1) begin
				assign data2_flatten[(gv_i * 4 + gv_j) * 8 + 7-:8] = data2[gv_i][gv_j];
			end
		end

		reg [31:0] data3_flatten;
		wire [31:0] _data3_flatten;
		for (gv_i = 0; gv_i < 4; gv_i = gv_i + 1) begin
			DW_minmax#(.width(8), .num_inputs(4)) u_DW_minmax_1(.a(data2_flatten[gv_i * 32 + 31-:32]), .tc(1'b0), .min_max(op_reg[0]), .value(_data3_flatten[gv_i * 8 + 7-:8]), .index());
		end
		always @(posedge clk) begin
			data3_flatten <= _data3_flatten;
		end

		DW_minmax#(.width(8), .num_inputs(4)) u_DW_minmax_2(.a(data3_flatten), .tc(1'b0), .min_max(op_reg[0]), .value(_ed_res[8 * gv_k + 7-:8]), .index());
	end
endgenerate
always @(posedge clk) begin
	ed_res <= _ed_res;
end
/*------------------------------*/

reg [11:0] h_data [0:255];

reg [127:0] _word_sr;
always @(*) begin
	_word_sr <= word;
	_word_sr[63:0] <= word[127:64];
end

reg [11:0] _h_data_cdf [0:255];
always @(*) begin
	for (i = 0; i < 256; i = i + 1) begin
		_h_data_cdf[i] <= h_data[i] +
						(word[7:0] == i) +
						(word[15:8] == i) +
						(word[23:16] == i) +
						(word[31:24] == i) +
						(word[39:32] == i) +
						(word[47:40] == i) +
						(word[55:48] == i) +
						(word[63:56] == i);
	end
end
/*------------------------------*/

localparam h_map_lat = 8;
reg [11:0] cdf_min;

wire [11:0] _h_data_0_add_1 = h_data[1] + h_data[0];
wire [11:0] cdf_min_next = (cdf_min ? cdf_min : h_data[1]);

reg [11:0] divisor;
wire [11:0] _cdf_max_sub_cdf_min = 13'd4096 - cdf_min;
always @(posedge clk) begin
	divisor <= _cdf_max_sub_cdf_min;
end
reg [19:0] cdfi_sub_cdf_minx255;
wire [11:0] _cdfi_sub_cdf_min = h_data[0] - cdf_min;
wire [19:0] _cdfi_sub_cdf_minx255 = (_cdfi_sub_cdf_min << 8) - _cdfi_sub_cdf_min;
always @(posedge clk) begin
	cdfi_sub_cdf_minx255 <= _cdfi_sub_cdf_minx255;
end

wire [19:0] rq_cur [0:7];
wire [19:0] _rq_nxt [0:7];
wire [12:0] _rq_temp_0 [0:7];
wire signed [13:0] _rq_temp_1 [0:7];
reg [19:0] _rq_nxt_reg [0:7];
generate
	assign rq_cur[0] = cdfi_sub_cdf_minx255;
	for (gv_i = 1; gv_i < 8; gv_i = gv_i + 1) begin
		assign rq_cur[gv_i] = _rq_nxt_reg[gv_i - 1];
	end
	for (gv_i = 0; gv_i < 8; gv_i = gv_i + 1) begin
		assign _rq_temp_0[gv_i] = rq_cur[gv_i][19:7];
		assign _rq_temp_1[gv_i] = _rq_temp_0[gv_i] - divisor;
		assign _rq_nxt[gv_i] = (_rq_temp_1[gv_i][13] ?
			{_rq_temp_0[gv_i][11:0], rq_cur[gv_i][6:0], 1'b0} :
			{_rq_temp_1[gv_i][11:0], rq_cur[gv_i][6:0], 1'b1});
	end
	for (gv_i = 0; gv_i < 8; gv_i = gv_i + 1) begin
		always @(posedge clk) begin
			_rq_nxt_reg[gv_i] <= _rq_nxt[gv_i];
		end
	end
endgenerate
wire [7:0] _pixel_map = _rq_nxt[7][7:0];
/*------------------------------*/

localparam h_res_lat = 1;
reg h_res_stall;
reg [127:0] h_res;

wire [127:0] _h_res;
generate
	for (gv_k = 0; gv_k < 16; gv_k = gv_k + 1) begin
		assign _h_res[gv_k * 8 + 7-:8] = h_data[word[gv_k * 8 + 7-:8]];
	end
endgenerate
always @(posedge clk) begin
	if (!h_res_stall) begin
		h_res <= _h_res;
	end
end
/*------------------------------*/

reg [4:0] state, nxt_state;
localparam Idle		= 5'b00000;
//...
localparam ED_0		= 5'b00001;
localparam ED_1		= 5'b00011;
localparam ED_2		= 5'b00010;
localparam ED_3		= 5'b00110;
localparam ED_4		= 5'b00111;
localparam ED_5		= 5'b00101;
localparam ED_6		= 5'b00100;
localparam ED_7		= 5'b01100;
localparam ED_8		= 5'b01101;
localparam ED_9		= 5'b01111;
localparam ED_10	= 5'b01110;
//...
localparam H_0		= 5'b01010;
localparam H_1		= 5'b01011;
localparam H_2		= 5'b01001;
localparam H_3		= 5'b01000;
localparam H_4		= 5'b11000;
localparam H_5		= 5'b11001;
localparam H_6		= 5'b11011;
localparam H_7		= 5'b11010;
localparam H_8		= 5'b11110;
localparam H_9		= 5'b11111;
localparam H_10		= 5'b11101;
/*
localparam Idle		= 5'd0;
//...
localparam ED_0		= 5'd1;
localparam ED_1		= 5'd2;
localparam ED_2		= 5'd3;
localparam ED_3		= 5'd4;
localparam ED_4		= 5'd5;
localparam ED_5		= 5'd6;
localparam ED_6		= 5'd7;
localparam ED_7		= 5'd8;
localparam ED_8		= 5'd9;
localparam ED_9		= 5'd10;
localparam ED_10	= 5'd11;
//...
localparam H_0		= 5'd12;
localparam H_1		= 5'd13;
localparam H_2		= 5'd14;
localparam H_3		= 5'd15;
localparam H_4		= 5'd16;
localparam H_5		= 5'd17;
localparam H_6		= 5'd18;
localparam H_7		= 5'd19;
localparam H_8		= 5'd20;
localparam H_9		= 5'd21;
localparam H_10		= 5'd22;
//...
*/

reg [7:0] cnt;

wire [7:0] cnt_add_1 = cnt + 8'd1;
wire [7:0] cnt_add_2 = cnt + 8'd2;
wire cnt_is_255 = (cnt == 8'd255);

wire ed_3_end = (cnt == ed_lat - 1);
wire ed_5_end = cnt_is_255;
wire ed_8_end = cnt_is_255;
wire h_2_end = cnt_is_255;
wire h_5_end = (cnt == h_map_lat - 1);
wire h_6_end = h_5_end;
wire h_7_end = (cnt == h_res_lat - 1);
wire h_8_end = h_7_end;

always @(*) begin
	nxt_state <= state;
	case (state)
		Idle :
			if (in_valid) begin
				if (op[1]/*op == 2'd2*/) nxt_state <= H_0;
				else/* if (op == 2'd0 || op == 2'd1)*/ nxt_state <= ED_0;
			end
		ED_0 :
			if (arready_m_inf) nxt_state <= ED_1;
		ED_1 :
			if (rvalid_m_inf) nxt_state <= ED_2;
		ED_2 :
			if (arready_m_inf) nxt_state <= ED_3;
		ED_3 :
			if (ed_3_end) nxt_state <= ED_4;
		ED_4 :
			if (rlast_m_inf) nxt_state <= ED_5;
		ED_5 :
			if (ed_5_end) nxt_state <= ED_6;
		ED_6 :
			if (awready_m_inf) nxt_state <= ED_7;
		ED_7 : nxt_state <= ED_8;
		ED_8 :
			if (wready_m_inf) begin
				if (ed_8_end) nxt_state <= ED_10;
			end
			else nxt_state <= ED_9;
		ED_9 :
			if (wready_m_inf) begin
				if (ed_8_end) nxt_state <= ED_10;
				else nxt_state <= ED_8;
			end
		ED_10 :
			if (bvalid_m_inf) nxt_state <= Idle;
		H_0 :
			if (arready_m_inf) nxt_state <= H_1;
		H_1 :
			if (rvalid_m_inf) nxt_state <= H_2;
		H_2 :
			if (h_2_end) nxt_state <= H_3;
			else nxt_state <= H_1;
		H_3 : nxt_state <= H_4;
		H_4 :
			if (awready_m_inf) nxt_state <= H_5;
		H_5 :
			if (h_5_end) nxt_state <= H_6;
		H_6 :
			if (h_6_end) nxt_state <= H_7;
		H_7 :
			if (h_7_end) nxt_state <= H_8;
		H_8 :
			if (wready_m_inf) begin
				if (h_8_end) nxt_state <= H_10;
			end
			else nxt_state <= H_9;
		H_9 :
			if (wready_m_inf) begin
				if (h_8_end) nxt_state <= H_10;
				else nxt_state <= H_8;
			end
		H_10 :
			if (bvalid_m_inf) nxt_state <= Idle;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) state <= Idle;
	else state <= nxt_state;
end

// SRAM
always @(*) begin
	sram_WEN <= 1'b1;
	sram_A <= 8'bx;
	sram_D <= 128'bx;
	case (state)
		ED_4, ED_5 : begin
			sram_WEN <= 1'b0;
			sram_A <= cnt;
			sram_D <= ed_res;
		end
		ED_6 : begin
			//if (awready_m_inf) begin //
				sram_A <= 8'd0;
			//end
		end
		ED_7 : begin
			sram_A <= 8'd1;
		end
		ED_8, ED_9, H_8, H_9 : begin
			//if (wready_m_inf) begin //
				sram_A <= cnt_add_2;
			//end
		end
		H_2 : begin
			sram_WEN <= 1'b0;
			sram_A <= cnt;
			sram_D <= word;
		end
		H_6 : begin
			if (h_6_end) sram_A <= 8'd1;
			else sram_A <= 8'd0;
		end
		H_7 : begin
			sram_A <= cnt_add_2;
		end
	endcase
end

// DRAM read
assign arid_m_inf = 4'b0;
assign arsize_m_inf = 3'b100;
assign arburst_m_inf = 2'b01;
always @(*) begin
	araddr_m_inf <= 32'bx;
	arlen_m_inf <= 8'bx;
	arvalid_m_inf <= 1'b0;
	rready_m_inf <= 1'b0;
	case (state)
		ED_0 : begin
			araddr_m_inf <= {16'h0003, 6'b0, se_no_reg, 4'b0};
			arlen_m_inf <= 8'd0;
			arvalid_m_inf <= 1'b1;
		end
		ED_1 : begin
			rready_m_inf <= 1'b1;
		end
		ED_2, H_0 : begin
			araddr_m_inf <= {16'h0004, pic_no_reg, 12'b0};
			arlen_m_inf <= 8'd255;
			arvalid_m_inf <= 1'b1;
		end
		ED_3, ED_4, H_1 : begin
			rready_m_inf <= 1'b1;
		end
	endcase
end

// DRAM write
assign awid_m_inf = 4'b0;
assign awsize_m_inf = 3'b100;
assign awburst_m_inf = 2'b01;
always @(*) begin
	awaddr_m_inf <= 32'bx;
	awlen_m_inf <= 8'bx;
	awvalid_m_inf <= 1'b0;
	wdata_m_inf <= 128'bx;
	wlast_m_inf <= 1'bx;
	wvalid_m_inf <= 1'b0;
	bready_m_inf <= 1'b0;
	case (state)
		ED_6 : begin
			awaddr_m_inf <= {16'h0004, pic_no_reg, 12'b0};
			awlen_m_inf <= 8'd255;
			awvalid_m_inf <= 1'b1;
		end
		ED_8, ED_9 : begin
			wdata_m_inf <= word;
			wlast_m_inf <= ed_8_end;
			wvalid_m_inf <= 1'b1;
		end
		ED_10 : begin
			bready_m_inf <= 1'b1;
		end
		H_4 : begin
			awaddr_m_inf <= {16'h0004, pic_no_reg, 12'b0};
			awlen_m_inf <= 8'd255;
			awvalid_m_inf <= 1'b1;
		end
		H_8, H_9 : begin
			wdata_m_inf <= h_res;
			wlast_m_inf <= h_8_end;
			wvalid_m_inf <= 1'b1;
		end
		H_10 : begin
			bready_m_inf <= 1'b1;
		end
	endcase
end

always @(*) begin
	ed_reset <= 1'b0;
	ed_stall <= 1'b1;
	ed_input <= 128'bx;
	h_res_stall <= 1'b1;
	case (state)
		ED_2 : begin
			//if (arready_m_inf) begin //
				ed_reset <= 1'b1;
			//end
		end
		ED_3, ED_4 : begin
			if (rvalid_m_inf) begin
				ed_stall <= 1'b0;
				ed_input <= rdata_m_inf;
			end
		end
		ED_5 : begin
			ed_stall <= 1'b0;
			ed_input <= 8'd0;
		end
		H_7 : begin
			h_res_stall <= 1'b0;
		end
		H_8, H_9 : begin
			if (wready_m_inf) begin
				h_res_stall <= 1'b0;
			end
		end
	endcase
end

always @(posedge clk) begin
	case (state)
		Idle : begin
			if (in_valid) begin //
				op_reg <= op;
				pic_no_reg <= pic_no;
				se_no_reg <= se_no;
			end
		end
		ED_1 : begin
			if (rvalid_m_inf) begin //
				for (i = 0; i < 4; i = i + 1)
					for (j = 0; j < 4; j = j + 1) begin
						if (op_reg[0]/*op_reg == 2'd1*/) se[i][j] <= rdata_m_inf[(3 - i) * 32 + (3 - j) * 8 + 7-:8];
						else/* if (op_reg == 2'd0)*/ se[i][j] <= rdata_m_inf[i * 32 + j * 8 + 7-:8];
					end
				cnt <= 8'd0;
			end
		end
		ED_3: begin
			if (rvalid_m_inf) begin
				if (ed_3_end) cnt <= 8'd0;
				else cnt <= cnt_add_1;
			end
		end
		ED_4 : begin
			if (rvalid_m_inf) begin
				cnt <= cnt_add_1;
			end
		end
		ED_5 : begin
			cnt <= cnt_add_1;
		end
		ED_6 : begin
			//if (awready_m_inf) begin //
				cnt <= 8'd0;
			//end
		end
		ED_7 : begin
			word <= sram_Q;
		end
		ED_8 : begin
			if (wready_m_inf) begin
				word <= sram_Q;
				cnt <= cnt_add_1;
			end
			//else begin //
				temp <= sram_Q;
			//end
		end
		ED_9 : begin
			if (wready_m_inf) begin
				word <= temp;
				cnt <= cnt_add_1;
			end
		end
		H_0 : begin
			cnt <= 8'd0;
			word <= 128'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF;
			for (i = 0; i < 256; i = i + 1) h_data[i] <= 12'd0;
		end
		H_1 : begin
			if (rvalid_m_inf) begin
				word <= rdata_m_inf;
			end
			else word <= 128'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF;
			for (i = 0; i < 256; i = i + 1) h_data[i] <= _h_data_cdf[i];
		end
		H_2 : begin
			cnt <= cnt_add_1;
			word <= _word_sr;
			for (i = 0; i < 256; i = i + 1) h_data[i] <= _h_data_cdf[i];
		end
		H_3 : begin
			for (i = 0; i < 256; i = i + 1) h_data[i] <= _h_data_cdf[i];
		end
		H_4 : begin
			//if (awready_m_inf) begin //
				cnt <= 8'd0;
				cdf_min <= h_data[0];
			//end
		end
		H_5 : begin
			cnt <= cnt_add_1;
			cdf_min <= cdf_min_next;
			h_data[0] <= _h_data_0_add_1;
			for (i = 1; i + 1 < 256; i = i + 1) h_data[i] <= h_data[i + 1];
		end
		H_6 : begin
			cnt <= cnt_add_1;
			cdf_min <= cdf_min_next;
			if (h_6_end) h_data[0] <= h_data[1];
			else h_data[0] <= _h_data_0_add_1;
			for (i = 1; i + 1 < 256; i = i + 1) h_data[i] <= h_data[i + 1];
			if (h_6_end) h_data[255] <= 8'd255;
			else h_data[255] <= _pixel_map;

			if (h_6_end) begin
				cnt <= 8'd0;
			end//
				word <= sram_Q;
			//end
		end
		H_7 : begin
			cnt <= cnt_add_1;
			word <= sram_Q;
		end
		H_8 : begin
			if (wready_m_inf) begin
				cnt <= cnt_add_1;
				word <= sram_Q;
			end
			//else begin //
				temp <= sram_Q;
			//end
		end
		H_9 : begin
			if (wready_m_inf) begin
				cnt <= cnt_add_1;
				word <= temp;
			end
		end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		busy <= 1'b0;
	end
	else begin
		busy <= 1'b1;
		case (state)
			Idle : busy <= 1'b0;
		endcase
	end
end

endmodule
