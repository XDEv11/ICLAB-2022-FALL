//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : UT_TOP.v
//   Module Name : UT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

// synopsys translate_off

`include "B2BCD_IP.v"
`include ...

// synopsys translate_on

module UT_TOP (
    // Input signals
    clk, rst_n, in_valid, in_time,
    // Output signals
    out_valid, out_display, out_day
);
input clk, rst_n, in_valid;
input [30:0] in_time;
output reg out_valid;
output reg [3:0] out_display;
output reg [2:0] out_day;
// ===============================================================
//
// ===============================================================

reg [6:0] binary;
wire [7:0] bcd;
B2BCD_IP #(.WIDTH(7), .DIGIT(2)) u_B2BCD_IP(.Binary_code(binary), .BCD_code(bcd));

reg [3:0] state, nxt_state;
localparam Idle	= 4'd0;
localparam S1	= 4'd1;
localparam S2	= 4'd2;
localparam S3	= 4'd3;
localparam S4	= 4'd4;
localparam S5	= 4'd5;
localparam S6	= 4'd6;
localparam S7	= 4'd7;
localparam S8	= 4'd8;
localparam S9	= 4'd9;
localparam S10	= 4'd10;
localparam S11	= 4'd11;
localparam S12	= 4'd12;
localparam S13	= 4'd13;
localparam S14	= 4'd14;
localparam S15	= 4'd15;

always @(*) begin
	nxt_state <= state;
	case (state)
		Idle :
			if (in_valid) nxt_state <= S1;
		S1  : nxt_state <= S2;
		S2  : nxt_state <= S3;
		S3  : nxt_state <= S4;
		S4  : nxt_state <= S5;
		S5  : nxt_state <= S6;
		S6  : nxt_state <= S7;
		S7  : nxt_state <= S8;
		S8  : nxt_state <= S9;
		S9  : nxt_state <= S10;
		S10 : nxt_state <= S11;
		S11 : nxt_state <= S12;
		S12 : nxt_state <= S13;
		S13 : nxt_state <= S14;
		S14 : nxt_state <= S15;
		S15 : nxt_state <= Idle;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) state <= Idle;
	else state <= nxt_state;
end

reg is_21th_century;
reg [30:0] seconds;

localparam UT_20000101_000000 = 31'd946684800;
wire signed [31:0] _temp_1 = in_time - UT_20000101_000000;
wire _is_21th_century = !_temp_1[31];
wire [30:0] _seconds = (_is_21th_century ? _temp_1[30:0] : in_time); // [0:1200798848)
/*------------------------------------------------------------*/

reg [13:0] days;

/*
wire [23:0] div_86400_quotient;
DW_div #(.a_width(24), .b_width(10), .tc_mode(0), .rem_mode(1))
	u_DW_div_675(.a(seconds[30:7]), .b(10'd675), .quotient(div_86400_quotient), .remainder(), .divide_by_0());
wire [13:0] _temp_2_2 = div_86400_quotient;
*/
wire [45:0] _temp_2_1 = seconds[30:7] * 23'd6362915; // Magic
wire [13:0] _temp_2_2 = _temp_2_1[45:32];
wire [13:0] _days = _temp_2_2; // [0:13899)
/*------------------------------------------------------------*/

reg [6:0] years;

localparam DAYS_1968_1969 = 31'd731;
wire [13:0] _temp_3_1 = days + DAYS_1968_1969;
wire [13:0] _dayss = (is_21th_century ? days : _temp_3_1);
//wire [13:0] div_1461_quotient;
//DW_div #(.a_width(14), .b_width(11), .tc_mode(0), .rem_mode(1))
//	u_DW_div_1461(.a(_dayss), .b(11'd1461), .quotient(div_1461_quotient), .remainder(), .divide_by_0());
reg [3:0] div_1461_quotient;
always @(*) begin
	if (_dayss < 14'd1461) div_1461_quotient <= 4'd0;
	else if (_dayss < 14'd2922) div_1461_quotient <= 4'd1;
	else if (_dayss < 14'd4383) div_1461_quotient <= 4'd2;
	else if (_dayss < 14'd5844) div_1461_quotient <= 4'd3;
	else if (_dayss < 14'd7305) div_1461_quotient <= 4'd4;
	else if (_dayss < 14'd8766) div_1461_quotient <= 4'd5;
	else if (_dayss < 14'd10227) div_1461_quotient <= 4'd6;
	else if (_dayss < 14'd11688) div_1461_quotient <= 4'd7;
	else if (_dayss < 14'd13149) div_1461_quotient <= 4'd8;
	else div_1461_quotient <= 4'd9;
end
wire [3:0] _temp_3_3 = div_1461_quotient;
//wire [25:0] _temp_3_2 = _dayss * 12'd2871; // Magic
//wire [3:0] _temp_3_3 = _temp_3_2[25:22];
wire [3:0] _ye4rs = _temp_3_3; // [0:10)
/*------------------------------------------------------------*/

reg leap;

wire [13:0] _temp_4_1 = years[5:2] * 11'd1461;
wire [10:0] _temp_4_2 = _dayss - _temp_4_1;
reg [1:0] _ears;
reg _leap;
reg [8:0] _days_iy; // [0:367)
always @(*) begin
	if (_temp_4_2 < 11'd366) begin
		_leap <= 1'b1;
		_ears <= 2'd0;
		_days_iy <= _temp_4_2;
	end
	else if (_temp_4_2 < 11'd731) begin
		_leap <= 1'b0;
		_ears <= 2'd1;
		_days_iy <= _temp_4_2 - 11'd366;
	end
	else if (_temp_4_2 < 11'd1096) begin
		_leap <= 1'b0;
		_ears <= 2'd2;
		_days_iy <= _temp_4_2 - 11'd731;
	end
	else begin
		_leap <= 1'b0;
		_ears <= 2'd3;
		_days_iy <= _temp_4_2 - 11'd1096;
	end
end
/*------------------------------*/

wire [4:0] _temp_4_3 = years[5:2] + 5'd17;
wire [4:0] _temp_4_4 = (is_21th_century ? years[5:2] : _temp_4_3);
wire [6:0] _years = {_temp_4_4, _ears}; // [70:100) or [0:39)
/*------------------------------------------------------------*/

reg [3:0] months;

wire [8:0] _days_before_month [1:12];
assign _days_before_month[1]	= -9'sd1;
assign _days_before_month[2]	= 9'd30;
assign _days_before_month[3]	= 9'd58 + leap;
assign _days_before_month[4]	= 9'd89 + leap;
assign _days_before_month[5]	= 9'd119 + leap;
assign _days_before_month[6]	= 9'd150 + leap;
assign _days_before_month[7]	= 9'd180 + leap;
assign _days_before_month[8]	= 9'd211 + leap;
assign _days_before_month[9]	= 9'd242 + leap;
assign _days_before_month[10]	= 9'd272 + leap;
assign _days_before_month[11]	= 9'd303 + leap;
assign _days_before_month[12]	= 9'd333 + leap;
//assign _days_before_month[13]	= 9'd364 + leap;
reg [8:0] _temp_5;
reg [3:0] _months_iy; // [0:13)
reg [4:0] _days_im; // [0:32)
integer i;
always @(*) begin
	_months_iy <= 4'd12;
	_temp_5 <= _days_before_month[12];
	for (i = 11; i >= 1; i = i - 1) begin
		if (days[8:0] <= _days_before_month[i + 1]) begin
			_months_iy <= i;
			_temp_5 <= _days_before_month[i];
		end
	end
	_days_im <= days[8:0] - _temp_5;
end
//=====+++++-----!!!!!//

wire [23:0] _temp_6_1 = days * 10'd675;
wire [9:0] _temp_6_2 = seconds[30:7] - _temp_6_1;
wire [16:0] _seconds_id = {_temp_6_2, seconds[6:0]}; // [0:86400)
/*------------------------------------------------------------*/

reg [16:0] div_60_a;
wire [14:0] div_60_quotient;
wire [5:0] div_60_remainder;
assign div_60_remainder[1:0] = div_60_a[1:0];
DW_div #(.a_width(15), .b_width(4), .tc_mode(0), .rem_mode(1))
	u_DW_div_15(.a(div_60_a[16:2]), .b(4'd15), .quotient(div_60_quotient), .remainder(div_60_remainder[5:2]), .divide_by_0());
// synopsys dc_script_begin
//
// set_implementation mlt u_DW_div_15
//
// synopsys dc_script_end
/*------------------------------*/

reg [10:0] minutes;

wire [10:0] _minutes_id = div_60_quotient; // [0:1440)
wire [5:0] _seconds_im = div_60_remainder; // [0:60)
/*------------------------------------------------------------*/

reg [4:0] hours;

wire [4:0] _hours_id = div_60_quotient; // [0:24)
wire [5:0] _minutes_ih = div_60_remainder; // [0:60)
/*------------------------------*/

always @(*) begin
	div_60_a <= 17'bx;
	case (state)
		S3 : div_60_a <= seconds[16:0];
		S4 : div_60_a <= minutes;
	endcase
end
//=====+++++-----!!!!!//

reg [13:0] dc;

wire [13:0] _temp_8 = _days + (is_21th_century ? 3'd6 : 3'd4);
wire [13:0] _dc = _temp_8;
/*------------------------------------------------------------*/

wire [2:0] div_7_remainder;
DW_div #(.a_width(14), .b_width(3), .tc_mode(0), .rem_mode(1))
	u_DW_div_7(.a(dc), .b(3'd7), .quotient(), .remainder(div_7_remainder), .divide_by_0());
// synopsys dc_script_begin
//
// set_implementation mlt u_DW_div_7
//
// synopsys dc_script_end
wire [2:0] _temp_9_3 = div_7_remainder;
//wire [27:0] _temp_9_1 = dc * 15'd18725; // Magic
//wire [13:0] _temp_9_2 = _temp_9_1[27:17] * 3'd7;
//wire [2:0] _temp_9_3 = dc - _temp_9_2;
wire [2:0] _dow = _temp_9_3;
//=====+++++-----!!!!!//

always @(posedge clk) begin
	case (state)
		Idle : begin
			//if (in_valid) begin
				is_21th_century <= _is_21th_century;
				seconds <= _seconds;
			//end
		end
		S1 : begin
			dc <= _dc;

			days <= _days;
		end
		S2 : begin
			years[5:2] <= _ye4rs;

			seconds <= _seconds_id;
		end
		S3 : begin
			years <= _years;
			leap <= _leap;
			days <= _days_iy;

			minutes <= _minutes_id;
			seconds <= _seconds_im;
		end
		S4 : begin
			months <= _months_iy;
			days <= _days_im;

			hours <= _hours_id;
			minutes <= _minutes_ih;
		end
	endcase
end

always @(posedge clk) begin
	binary <= 7'bx;
	case (state)
		S3 : binary <= _years;
		S4 : binary <= years;
		S5, S6 : binary <= months;
		S7, S8 : binary <= days[4:0];
		S9, S10 : binary <= hours;
		S11, S12 : binary <= minutes[5:0];
		S13, S14 : binary <= seconds[5:0];
	endcase
end

always @(*) begin
	out_valid <= 1'b0;
	case (state)
		S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15 : out_valid <= 1'b1;
	endcase
	out_display <= 4'b0;
	case (state)
		S2 : out_display <= (is_21th_century ? 4'd2 : 4'd1);
		S3 : out_display <= (is_21th_century ? 4'd0 : 4'd9);
		S4, S6, S8, S10, S12, S14 : out_display <= bcd[7:4];
		S5, S7, S9, S11, S13, S15 : out_display <= bcd[3:0];
	endcase
	out_day <= 3'd0;
	case (state)
		S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15 : out_day <= _dow;
	endcase
end

endmodule




