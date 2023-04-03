// synopsys translate_off
`ifdef RTL
`include "GATED_OR.v"
`else
`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SP(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);

// INPUT AND OUTPUT DECLARATION  
input		clk;
input		rst_n;
input		in_valid;
input		cg_en;
input [8:0] in_data;
input [2:0] in_mode;

output reg				out_valid;
output reg signed [9:0]	out_data;
/* My Design */
integer i;
genvar gv_i;

reg [2:0] mode;
reg signed [8:0] data [0:8];
reg signed [8:0] mx, mn, md, hd;
reg signed [8:0] maximum, median, minimum;

reg signed [8:0] element_tbg2b;
wire signed [8:0] g2bed;
wire [7:0] g2b_temp;
generate
	assign g2b_temp[7] = element_tbg2b[7];
	for (gv_i = 6; gv_i >= 0; gv_i = gv_i - 1) begin
		assign g2b_temp[gv_i] = element_tbg2b[gv_i] ^ g2b_temp[gv_i + 1];
	end
endgenerate
assign g2bed = (element_tbg2b[8] ? -g2b_temp : g2b_temp);

reg signed [8:0] element_tbmnx;
wire signed [8:0] mned = (element_tbmnx < mn ? element_tbmnx : mn);
wire signed [8:0] mxed = (element_tbmnx > mx ? element_tbmnx : mx);

reg signed [8:0] element_tbmhd [0:1];
wire signed [9:0] mded_temp = element_tbmhd[0] + element_tbmhd[1];
wire signed [9:0] hded_temp = element_tbmhd[0] - element_tbmhd[1];
//wire signed [8:0] mded = mded_temp / 2;
wire signed [8:0] mded = mded_temp[9:1] + (mded_temp[9] & mded_temp[0]);
wire signed [8:0] hded = hded_temp[9:1];

reg signed [8:0] element_tba [0:8];
wire signed [8:0] adjusted [0:8];
generate
	for (gv_i = 0; gv_i < 9; gv_i = gv_i + 1) begin
		wire adjusted_temp0;
		//wire signed [8:0] adjusted_temp1;
		wire signed [8:0] adjusted_temp2;
		assign adjusted_temp0 = (element_tba[gv_i] > md);
		AddSub#(.width(9)) u_AddSub(element_tba[gv_i], hd, adjusted_temp0, adjusted_temp2);
		//assign adjusted_temp2 = (adjusted_temp0 ? element_tba[gv_i] - hd : element_tba[gv_i] + hd);
		//assign adjusted_temp1 = (adjusted_temp0 ? -hd : hd);
		//assign adjusted_temp2 = element_tba[gv_i] + adjusted_temp1;
		assign adjusted[gv_i] = (element_tba[gv_i] == md ? element_tba[gv_i] : adjusted_temp2);
	end
endgenerate

reg signed [8:0] element_tbSMA3 [0:8];
wire signed [8:0] SMA3ed [0:8];
generate
	for (gv_i = 0; gv_i < 9; gv_i = gv_i + 1) begin
		wire signed [10:0] SMA3ed_temp0;
		//wire [9:0] SMA3ed_temp1;
		//wire [18:0] SMA3ed_temp2;
		//wire [7:0] SMA3ed_temp3;
		assign SMA3ed_temp0 = element_tbSMA3[(gv_i - 1 + 9) % 9] + element_tbSMA3[gv_i] + element_tbSMA3[(gv_i + 1) % 9];
		//assign SMA3ed_temp1 = (SMA3ed_temp0[10] ? -SMA3ed_temp0 : SMA3ed_temp0);
		//assign SMA3ed_temp2 = SMA3ed_temp1 * 10'd683;
		//assign SMA3ed_temp3 = SMA3ed_temp2[18:11];
		//assign SMA3ed[gv_i] = (SMA3ed_temp0[10] ? -SMA3ed_temp3 : SMA3ed_temp3);
		assign SMA3ed[gv_i] = SMA3ed_temp0 / 3;
	end
endgenerate

reg signed [8:0] element_tbMMM [0:8];
wire signed [8:0] maximumed, medianed, minimumed;

wire signed [8:0] MMMed_temp0 [0:8];
Sort3#(.width(9)) u_Sort3_1(element_tbMMM[0], element_tbMMM[1], element_tbMMM[2], MMMed_temp0[0], MMMed_temp0[1], MMMed_temp0[2]);
Sort3#(.width(9)) u_Sort3_2(element_tbMMM[3], element_tbMMM[4], element_tbMMM[5], MMMed_temp0[3], MMMed_temp0[4], MMMed_temp0[5]);
Sort3#(.width(9)) u_Sort3_3(element_tbMMM[6], element_tbMMM[7], element_tbMMM[8], MMMed_temp0[6], MMMed_temp0[7], MMMed_temp0[8]);
wire signed [8:0] MMMed_temp1 [0:8];
Sort3#(.width(9)) u_Sort3_4(MMMed_temp0[0], MMMed_temp0[3], MMMed_temp0[6], MMMed_temp1[0], MMMed_temp1[1], MMMed_temp1[2]);
Sort3#(.width(9)) u_Sort3_5(MMMed_temp0[1], MMMed_temp0[4], MMMed_temp0[7], MMMed_temp1[3], MMMed_temp1[4], MMMed_temp1[5]);
Sort3#(.width(9)) u_Sort3_6(MMMed_temp0[2], MMMed_temp0[5], MMMed_temp0[8], MMMed_temp1[6], MMMed_temp1[7], MMMed_temp1[8]);
wire signed [8:0] MMMed_temp2 [3:5];
Sort3#(.width(9)) u_Sort3_7(MMMed_temp1[2], MMMed_temp1[4], MMMed_temp1[6], MMMed_temp2[3], MMMed_temp2[4], MMMed_temp2[5]);
assign maximumed = MMMed_temp1[0];
assign medianed = MMMed_temp2[4];
assign minimumed = MMMed_temp1[8];

reg [1:0] state, nxt_state;
localparam Idle		= 2'b00;
localparam Read		= 2'b01;
localparam Work		= 2'b10;
localparam Output	= 2'b11;

reg [2:0] cnt;
wire [2:0] cnt_add_1 = cnt + 3'd1;
wire cnt_eq [0:7];
assign cnt_eq[0] = (cnt == 3'd0);
assign cnt_eq[1] = (cnt == 3'd1);
assign cnt_eq[2] = (cnt == 3'd2);
assign cnt_eq[3] = (cnt == 3'd3);
assign cnt_eq[4] = (cnt == 3'd4);
assign cnt_eq[5] = (cnt == 3'd5);
assign cnt_eq[6] = (cnt == 3'd6);
assign cnt_eq[7] = (cnt == 3'd7);

always @(*) begin
	nxt_state <= state;
	case (state)
		Idle :
			if (in_valid) nxt_state <= Read;
		Read :
			if (cnt_eq[7]) nxt_state <= Work;
		Work : nxt_state <= Output;
		Output :
			if (cnt_eq[2]) nxt_state <= Idle;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) state <= Idle;
	else state <= nxt_state;
end

reg sleep_ctrl_g2b;
always @(*) begin
	sleep_ctrl_g2b <= 1'b1;
	case (state)
		Idle : begin
			if (in_valid) begin
				if (in_mode[0]) begin
					sleep_ctrl_g2b <= 1'b0;
				end
			end
		end
		Read : begin
			if (mode[0]) begin
				sleep_ctrl_g2b <= 1'b0;
			end
		end
	endcase
end
reg signed [8:0] _element_tbg2b;
always @(*) begin
	_element_tbg2b <= 9'sbx;
	case (state)
		Idle : begin
			if (in_valid) begin
				if (in_mode[0]) begin
					_element_tbg2b <= in_data;
				end
			end
		end
		Read : begin
			if (mode[0]) begin
				_element_tbg2b <= in_data;
			end
		end
	endcase
end
always @(*) begin
	element_tbg2b <= (sleep_ctrl_g2b ? 9'sb0 : _element_tbg2b);
end

reg sleep_ctrl_mnx;
always @(*) begin
	sleep_ctrl_mnx <= 1'b1;
	case (state)
		Read : begin
			if (mode[1]) begin
				sleep_ctrl_mnx <= 1'b0;
			end
		end
	endcase
end
reg signed [8:0] _element_tbmnx;
always @(*) begin
	_element_tbmnx <= 9'sbx;
	case (state)
		Read : begin
			if (mode[1]) begin
				if (mode[0]) begin
					_element_tbmnx <= g2bed;
				end
				else begin
					_element_tbmnx <= in_data;
				end
			end
		end
	endcase
end
always @(*) begin
	element_tbmnx <= (sleep_ctrl_mnx ? 9'sb0 : _element_tbmnx);
end

reg sleep_ctrl_mhd;
always @(*) begin
	sleep_ctrl_mhd <= 1'b1;
	case (state)
		Read : begin
			if (mode[1] && cnt_eq[7]) begin
				sleep_ctrl_mhd <= 1'b0;
			end
		end
	endcase
end
reg signed [8:0] _element_tbmhd [0:1];
always @(*) begin
	_element_tbmhd[0] <= 9'sbx;
	_element_tbmhd[1] <= 9'sbx;
	case (state)
		Read : begin
			if (mode[1] && cnt_eq[7]) begin
				_element_tbmhd[0] <= mxed;
				_element_tbmhd[1] <= mned;
			end
		end
	endcase
end
always @(*) begin
	element_tbmhd[0] <= (sleep_ctrl_mhd ? 9'sb0 :  _element_tbmhd[0]);
	element_tbmhd[1] <= (sleep_ctrl_mhd ? 9'sb0 :  _element_tbmhd[1]);
end

reg sleep_ctrl_adjust;
wire gclk_adjust;
GATED_OR GATED_adjust(.CLOCK(clk), .SLEEP_CTRL(sleep_ctrl_adjust & cg_en), .RST_N(rst_n), .CLOCK_GATED(gclk_adjust));
always @(*) begin
	sleep_ctrl_adjust <= 1'b1;
	case (state)
		Read : begin
			if (mode[1] && cnt_eq[7]) begin
				sleep_ctrl_adjust <= 1'b0;
			end
		end
	endcase
end
always @(posedge gclk_adjust) begin
	for (i = 0; i < 9; i = i + 1) element_tba[i] <= 9'sbx;
	case (state)
		Read : begin
			if (mode[1] && cnt_eq[7]) begin
				if (mode[0]) begin
					for (i = 0; i <= 7; i = i + 1) element_tba[i] <= data[i];
					element_tba[8] <= g2bed;
				end
				else begin
					for (i = 0; i <= 7; i = i + 1) element_tba[i] <= data[i];
					element_tba[8] <= in_data;
				end
			end
		end
	endcase
end

reg sleep_ctrl_SMA3;
always @(*) begin
	sleep_ctrl_SMA3 <= 1'b1;
	case (state)
		Work : begin
			if (mode[2]) begin
				sleep_ctrl_SMA3 <= 1'b0;
			end
		end
	endcase
end
reg signed [8:0] _element_tbSMA3 [0:8];
always @(*) begin
	for (i = 0; i < 9; i = i + 1) _element_tbSMA3[i] <= 9'sbx;
	case (state)
		Work : begin
			if (mode[2]) begin
				for (i = 0; i < 9; i = i + 1) begin
					if (mode[1]) _element_tbSMA3[i] <= adjusted[i];
					else _element_tbSMA3[i] <= data[i];
				end
			end
		end
	endcase
end
always @(*) begin
	for (i = 0; i < 9; i = i + 1) element_tbSMA3[i] <= (sleep_ctrl_SMA3 ? 9'sb0 : _element_tbSMA3[i]);
end

reg sleep_ctrl_MMM;
wire gclk_MMM;
GATED_OR GATED_MMM(.CLOCK(clk), .SLEEP_CTRL(sleep_ctrl_MMM & cg_en), .RST_N(rst_n), .CLOCK_GATED(gclk_MMM));
always @(*) begin
	sleep_ctrl_MMM <= 1'b1;
	case (state)
		Work : begin
			sleep_ctrl_MMM <= 1'b0;
		end
	endcase
end
always @(posedge gclk_MMM) begin
	for (i = 0; i < 9; i = i + 1) element_tbMMM[i] <= 9'sbx;
	case (state)
		Work : begin
			for (i = 0; i < 9; i = i + 1) begin
				if (mode[2]) element_tbMMM[i] <= SMA3ed[i];
				else if (mode[1]) element_tbMMM[i] <= adjusted[i];
				else element_tbMMM[i] <= data[i];
			end
		end
	endcase
end

always @(posedge clk) begin
	cnt <= 3'd0;
	case (state)
		Read : begin
			if (!cnt_eq[7]) cnt <= cnt_add_1;
		end
		Output : begin
			if (!cnt_eq[2]) cnt <= cnt_add_1;
		end
	endcase
end

reg sleep_ctrl_dataassign0;
wire gclk_dataassign0;
GATED_OR GATED_dataassign0(.CLOCK(clk), .SLEEP_CTRL(sleep_ctrl_dataassign0 & cg_en), .RST_N(rst_n), .CLOCK_GATED(gclk_dataassign0));
always @(*) begin
	sleep_ctrl_dataassign0 <= 1'b1;
	case (state)
		Idle : begin // For OR gate, the allow switching cycle is clock at high period.
			sleep_ctrl_dataassign0 <= 1'b0;
		end
	endcase
end
always @(posedge gclk_dataassign0) begin
	case (state)
		Idle : begin
			if (in_valid) begin
				mode <= in_mode;
				if (in_mode[0]) begin
					data[0] <= g2bed;
				end
				else begin
					data[0] <= in_data;
				end
			end
		end
	endcase
end

generate
	for (gv_i = 1; gv_i < 9; gv_i = gv_i + 1) begin
		reg sleep_ctrl_dataassign;
		wire gclk_dataassign;
		GATED_OR GATED_dataassign(.CLOCK(clk), .SLEEP_CTRL(sleep_ctrl_dataassign & cg_en), .RST_N(rst_n), .CLOCK_GATED(gclk_dataassign));
		always @(*) begin
			sleep_ctrl_dataassign <= 1'b1;
			case (state)
				Read : begin
					if (cnt_eq[gv_i - 1]) begin
						sleep_ctrl_dataassign <= 1'b0;
					end
				end
			endcase
		end
		always @(posedge gclk_dataassign) begin
			case (state)
				Read : begin
					if (cnt_eq[gv_i - 1]) begin
						if (mode[0]) begin
							data[gv_i] <= g2bed;
						end
						else begin
							data[gv_i] <= in_data;
						end
					end
				end
			endcase
		end
	end
endgenerate

reg sleep_ctrl_mnxassign;
wire gclk_mnxassign;
GATED_OR GATED_mnxassign(.CLOCK(clk), .SLEEP_CTRL(sleep_ctrl_mnxassign & cg_en), .RST_N(rst_n), .CLOCK_GATED(gclk_mnxassign));
always @(*) begin
	sleep_ctrl_mnxassign <= 1'b1;
	case (state)
		Idle : begin // For OR gate, the allow switching cycle is clock at high period.
			sleep_ctrl_mnxassign <= 1'b0;
		end
		Read : begin
			if (mode[1] && !cnt_eq[7]) begin
				sleep_ctrl_mnxassign <= 1'b0;
			end
		end
	endcase
end
always @(posedge gclk_mnxassign) begin
	mn <= 9'sb0;
	mx <= 9'sb0;
	case (state)
		Idle : begin
			if (in_valid) begin
				if (in_mode[1]) begin
					if (in_mode[0]) begin
						mn <= g2bed;
						mx <= g2bed;
					end
					else begin
						mn <= in_data;
						mx <= in_data;
					end
				end
			end
		end
		Read : begin
			if (mode[1] && !cnt_eq[7]) begin
				if (mode[0]) begin
					mn <= mned;
					mx <= mxed;
				end
				else begin
					mn <= mned;
					mx <= mxed;
				end
			end
		end
	endcase
end

reg sleep_ctrl_mhdassignassign;
wire gclk_mhdassignassign;
GATED_OR GATED_mhdassignassign(.CLOCK(clk), .SLEEP_CTRL(sleep_ctrl_mhdassignassign & cg_en), .RST_N(rst_n), .CLOCK_GATED(gclk_mhdassignassign));
always @(*) begin
	sleep_ctrl_mhdassignassign <= 1'b1;
	case (state)
		Read : begin
			if (mode[1] && cnt_eq[7]) begin
				sleep_ctrl_mhdassignassign <= 1'b0;
			end
		end
	endcase
end
always @(posedge gclk_mhdassignassign) begin
	md <= 9'sbx;
	hd <= 9'sbx;
	case (state)
		Read : begin
			if (mode[1] && cnt_eq[7]) begin
				md <= mded;
				hd <= hded;
			end
		end
	endcase
end

reg sleep_ctrl_MMMassign;
wire gclk_MMMassign;
GATED_OR GATED_MMMassign(.CLOCK(clk), .SLEEP_CTRL(sleep_ctrl_MMMassign & cg_en), .RST_N(rst_n), .CLOCK_GATED(gclk_MMMassign));
always @(*) begin
	sleep_ctrl_MMMassign <= 1'b1;
	case (state)
		Output : begin
			if (cnt_eq[0]) begin
				sleep_ctrl_MMMassign <= 1'b0;
			end
		end
	endcase
end
always @(posedge gclk_MMMassign) begin
	case (state)
		Output : begin
			if (cnt_eq[0]) begin
				median <= medianed;
				minimum <= minimumed;
			end
		end
	endcase
end

always @(*) begin
	out_valid <= 1'b0;
	out_data <= 10'sb0;
	case (state)
		Output : begin
			out_valid <= 1'b1;
			case (cnt)
				3'd0 : out_data <= maximumed;
				3'd1 : out_data <= median;
				3'd2 : out_data <= minimum;
			endcase
		end
	endcase
end

endmodule

module AddSub#(parameter width = 1) (a, b, add_sub, s);
input [width - 1:0] a;
input [width - 1:0] b;
input add_sub;
output [width - 1:0] s;

wire [width - 1:0] c;
Fall_adder fa0(a[0], b[0] ^ add_sub, add_sub, s[0], c[0]);
genvar gv_i;
generate
	for (gv_i = 1; gv_i < width; gv_i = gv_i + 1) begin
		Fall_adder fa(a[gv_i], b[gv_i] ^ add_sub, c[gv_i - 1], s[gv_i], c[gv_i]);
	end
endgenerate
endmodule

module Half_adder(a, b, s, c);
input a;
input b;
output s;
output c;

assign s = a ^ b;
assign c = a & b;
endmodule

module Fall_adder(a, b, cin, s, cout);
input a;
input b;
input cin;
output s;
output cout;

wire s1, c1;
Half_adder ha1(a, b, s1, c1);
wire s2, c2;
Half_adder ha2(s1, cin, s2, c2);
assign s = s2;
assign cout = c1 | c2;
endmodule

module Sort3#(parameter width = 1) (a, b, c, x, y, z);
input signed [width - 1:0] a, b, c;
output signed [width - 1:0] x, y, z;

wire signed [width - 1:0] layer1 [0:2];
wire layer1_cmp = (b < c);
assign layer1[0] = a;
assign layer1[1] = (layer1_cmp ? c : b);
assign layer1[2] = (layer1_cmp ? b : c);

wire signed [width - 1:0] layer2 [0:2];
wire layer2_cmp = (layer1[0] < layer1[1]);
assign layer2[0] = (layer2_cmp ? layer1[1] : layer1[0]);
assign layer2[1] = (layer2_cmp ? layer1[0] : layer1[1]);
assign layer2[2] = layer1[2];

wire layer3_cmp = (layer2[1] < layer2[2]);
assign x = layer2[0];
assign y = (layer3_cmp ? layer2[2] : layer2[1]);
assign z = (layer3_cmp ? layer2[1] : layer2[2]);

endmodule

