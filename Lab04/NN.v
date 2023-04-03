module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_u,
	in_valid_w,
	in_valid_v,
	in_valid_x,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	// Output signals
	out_valid,
	out
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input  clk, rst_n, in_valid_u, in_valid_w, in_valid_v, in_valid_x;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;
//---------------------------------------------------------------------
//
//---------------------------------------------------------------------
localparam sig_width = inst_sig_width;
localparam exp_width = inst_exp_width;
localparam ieee_compliance = inst_ieee_compliance;
localparam fp_width = sig_width + exp_width + 1;
localparam fp_one = {1'b0, {1'b0, {exp_width - 1{1'b1}}}, {sig_width{1'b0}}};

integer i, j;

wire in_valid = in_valid_u/* && in_valid_w && in_valid_v && in_valid_x*/;

reg [fp_width - 1:0] u [0:2][0:2];
reg [fp_width - 1:0] w [0:2][0:2];
reg [fp_width - 1:0] v [0:2][0:2];
reg [fp_width - 1:0] x [1:3][0:2];
reg [fp_width - 1:0] h [1:3][0:2];

reg [fp_width - 1:0] mult_a, mult_b;
wire [fp_width - 1:0] mult_z;
DW_fp_mult #(.sig_width(sig_width), .exp_width(exp_width), .ieee_compliance(ieee_compliance))
	u_DW_fp_mult(.a(mult_a), .b(mult_b), .rnd(3'b000), .z(mult_z), .status());
reg [fp_width - 1:0] mac_c;
wire [fp_width - 1:0] mac_z;
DW_fp_add #(.sig_width(sig_width), .exp_width(exp_width), .ieee_compliance(ieee_compliance))
	u_DW_fp_add(.a(mult_z), .b(mac_c), .z(mac_z), .status(), .rnd(3'b000));

reg [fp_width - 1:0] mult_a_2, mult_b_2;
wire [fp_width - 1:0] mult_z_2;
DW_fp_mult #(.sig_width(sig_width), .exp_width(exp_width), .ieee_compliance(ieee_compliance))
	u_DW_fp_mult_2(.a(mult_a_2), .b(mult_b_2), .rnd(3'b000), .z(mult_z_2), .status());
reg [fp_width - 1:0] mac_c_2;
wire [fp_width - 1:0] mac_z_2;
DW_fp_add #(.sig_width(sig_width), .exp_width(exp_width), .ieee_compliance(ieee_compliance))
	u_DW_fp_add_2(.a(mult_z_2), .b(mac_c_2), .z(mac_z_2), .status(), .rnd(3'b000));

reg [fp_width - 1:0] add_a, add_b;
wire [fp_width - 1:0] add_z;
DW_fp_add #(.sig_width(sig_width), .exp_width(exp_width), .ieee_compliance(ieee_compliance))
	u_DW_fp_add_3(.a(add_a), .b(add_b), .z(add_z), .status(), .rnd(3'b000));

reg [fp_width - 1:0] sigmoid1_a;
wire [fp_width - 1:0] sigmoid1_z;
DW_fp_exp #(.sig_width(sig_width), .exp_width(exp_width), .ieee_compliance(ieee_compliance), .arch(1))
	u_DW_fp_exp_sigmoid(.a({~sigmoid1_a[fp_width - 1], sigmoid1_a[fp_width - 2:0]}), .z(sigmoid1_z), .status());
reg [fp_width - 1:0] sigmoid2_a;
wire [fp_width - 1:0] sigmoid2_z;
DW_fp_add #(.sig_width(sig_width), .exp_width(exp_width), .ieee_compliance(ieee_compliance))
	u_DW_fp_add_sigmoid(.a(fp_one), .b(sigmoid2_a), .z(sigmoid2_z), .status(), .rnd(3'b000));
reg [fp_width - 1:0] sigmoid3_a;
wire [fp_width - 1:0] sigmoid3_z;
DW_fp_recip #(.sig_width(sig_width), .exp_width(exp_width), .ieee_compliance(ieee_compliance), .faithful_round(1))
	u_DW_fp_recip_sigmoid(.a(sigmoid3_a), .rnd(3'b000), .z(sigmoid3_z), .status());
// synopsys dc_script_begin
//
// set_implementation rtl u_DW_fp_mult
// set_implementation rtl u_DW_fp_add
//
// set_implementation rtl u_DW_fp_mult_2
// set_implementation rtl u_DW_fp_add_2
//
// set_implementation rtl u_DW_fp_add_3
//
// set_implementation rtl u_DW_fp_exp_sigmoid
// set_implementation rtl u_DW_fp_add_sigmoid
// set_implementation rtl u_DW_fp_recip_sigmoid
//
// synopsys dc_script_end

reg [5:0] state, nxt_state;
wire [5:0] state_add_1 = state + 6'd1;
localparam R1	= 6'd00;
localparam R2	= 6'd25;
localparam R3	= 6'd26;
localparam R4	= 6'd27;
localparam R5	= 6'd28;
localparam R6	= 6'd29;
localparam R7	= 6'd30;
localparam R8	= 6'd31;
localparam R9	= 6'd32;
localparam S1	= 6'd33;
localparam S2	= 6'd34;
localparam S3	= 6'd35;
localparam S4	= 6'd36;
localparam S5	= 6'd37;
localparam S6	= 6'd38;
localparam S7	= 6'd39;
localparam S8	= 6'd40;
localparam S9	= 6'd41;
localparam S10	= 6'd42;
localparam S11	= 6'd43;
localparam S12	= 6'd44;
localparam S13	= 6'd45;
localparam S14	= 6'd46;
localparam S15	= 6'd47;
localparam S16	= 6'd48;
localparam S17	= 6'd49;
localparam S18	= 6'd50;
localparam S19	= 6'd51;
localparam S20	= 6'd52;
localparam S21	= 6'd53;
localparam S22	= 6'd54;
localparam O1	= 6'd55;
localparam O2	= 6'd56;
localparam O3	= 6'd57;
localparam O4	= 6'd58;
localparam O5	= 6'd59;
localparam O6	= 6'd60;
localparam O7	= 6'd61;
localparam O8	= 6'd62;
localparam O9	= 6'd63;

always @(*) begin
	nxt_state <= state_add_1;
	case (state)
		R1 :
			if (in_valid) nxt_state <= R2;
			else nxt_state <= R1;
		//R9 : nxt_state <= S1;
		//S22 : nxt_state <= O1;
		//O9 : nxt_state <= R1;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) state <= R1;
	else state <= nxt_state;
end

always @(posedge clk) begin
	mult_a <= {fp_width{1'bx}};
	mult_b <= {fp_width{1'bx}};
	mac_c <= {fp_width{1'bx}};
	mult_a_2 <= {fp_width{1'bx}};
	mult_b_2 <= {fp_width{1'bx}};
	mac_c_2 <= {fp_width{1'bx}};
	add_a <= {fp_width{1'bx}};
	add_b <= {fp_width{1'bx}};
	sigmoid1_a <= {fp_width{1'bx}};
	sigmoid2_a <= {fp_width{1'bx}};
	sigmoid3_a <= {fp_width{1'bx}};
	case (state)
		R1 : begin
			mult_a <= weight_u;// u[0][0]
			mult_b <= data_x;// x[1][0]
		end
		R2 : begin
			mult_a <= weight_u;// u[0][1]
			mult_b <= data_x;// x[1][1]
			mac_c <= mult_z;
		end
		R3 : begin
			mult_a <= weight_u;// u[0][2]
			mult_b <= data_x;// x[1][2]
			mac_c <= mac_z;
		end
		R4 : begin
			mult_a <= weight_u;// u[1][0]
			mult_b <= x[1][0];

			mult_a_2 <= u[0][0];
			mult_b_2 <= data_x;// x[2][0]

			sigmoid1_a <= mac_z;// h[1][0]
		end
		R5 : begin
			mult_a <= weight_u;// u[1][1]
			mult_b <= x[1][1];
			mac_c <= mult_z;

			mult_a_2 <= u[0][1];
			mult_b_2 <= data_x;// x[2][1]
			mac_c_2 <= mult_z_2;

			sigmoid2_a <= sigmoid1_z;
		end
		R6 : begin
			mult_a <= weight_u;// u[1][2]
			mult_b <= x[1][2];
			mac_c <= mac_z;

			mult_a_2 <= u[0][2];
			mult_b_2 <= data_x;// x[2][2]
			mac_c_2 <= mac_z_2;

			sigmoid3_a <= sigmoid2_z;
		end
		R7 : begin
			mult_a <= weight_u;// u[2][0]
			mult_b <= x[1][0];

			mult_a_2 <= w[0][0];
			mult_b_2 <= sigmoid3_z;// h[1][0]

			sigmoid1_a <= mac_z;// h[1][1]
		end
		R8 : begin
			mult_a <= weight_u;// u[2][1]
			mult_b <= x[1][1];
			mac_c <= mult_z;

			mult_a_2 <= w[1][0];
			mult_b_2 <= h[1][0];

			sigmoid2_a <= sigmoid1_z;
		end
		R9 : begin
			mult_a <= weight_u;// u[2][2]
			mult_b <= x[1][2];
			mac_c <= mac_z;

			mult_a_2 <= w[2][0];
			mult_b_2 <= h[1][0];

			sigmoid3_a <= sigmoid2_z;
		end
		S1 : begin
			mult_a <= u[1][0];
			mult_b <= x[2][0];

			mult_a_2 <= w[0][1];
			mult_b_2 <= sigmoid3_z;// h[1][1]
			mac_c_2 <= h[3][0];

			sigmoid1_a <= mac_z;// h[1][2]
		end
		S2 : begin
			mult_a <= u[1][1];
			mult_b <= x[2][1];
			mac_c <= mult_z;

			mult_a_2 <= w[1][1];
			mult_b_2 <= h[1][1];
			mac_c_2 <= h[3][1];

			sigmoid2_a <= sigmoid1_z;
		end
		S3 : begin
			mult_a <= u[1][2];
			mult_b <= x[2][2];
			mac_c <= mac_z;

			mult_a_2 <= w[2][1];
			mult_b_2 <= h[1][1];
			mac_c_2 <= h[3][2];

			sigmoid3_a <= sigmoid2_z;
		end
		S4 : begin
			mult_a <= u[2][0];
			mult_b <= x[2][0];

			mult_a_2 <= w[0][2];
			mult_b_2 <= sigmoid3_z;// h[1][2]
			mac_c_2 <= h[3][0];
		end
		S5 : begin
			mult_a <= u[2][1];
			mult_b <= x[2][1];
			mac_c <= mult_z;

			mult_a_2 <= w[1][2];
			mult_b_2 <= h[1][2];
			mac_c_2 <= h[3][1];

			add_a <= h[2][0];
			add_b <= mac_z_2;// h[3][0] (tmp[0])
		end
		S6 : begin
			mult_a <= u[2][2];
			mult_b <= x[2][2];
			mac_c <= mac_z;

			mult_a_2 <= w[2][2];
			mult_b_2 <= h[1][2];
			mac_c_2 <= h[3][2];

			add_a <= h[2][1];
			add_b <= mac_z_2;// h[3][1] (tmp[1])

			sigmoid1_a <= add_z;// h[2][0]
		end
		S7 : begin
			mult_a <= u[0][0];
			mult_b <= x[3][0];

			add_a <= mac_z;// h[2][2]
			add_b <= mac_z_2;// h[3][2] (tmp[2])

			sigmoid2_a <= sigmoid1_z;

			sigmoid1_a <= add_z;// h[2][1]

/*------------------------------------------------------------*/
			mult_a_2 <= v[0][0];
			mult_b_2 <= h[1][0];
		end
		S8 : begin
			mult_a <= u[0][1];
			mult_b <= x[3][1];
			mac_c <= mult_z;

			sigmoid3_a <= sigmoid2_z;

			sigmoid2_a <= sigmoid1_z;

			sigmoid1_a <= add_z;// h[2][2]

/*------------------------------------------------------------*/
			mult_a_2 <= v[0][1];
			mult_b_2 <= h[1][1];
			mac_c_2 <= mult_z_2;
		end
		S9 : begin
			mult_a <= u[0][2];
			mult_b <= x[3][2];
			mac_c <= mac_z;

			mult_a_2 <= w[0][0];
			mult_b_2 <= sigmoid3_z;// h[2][0]

			sigmoid3_a <= sigmoid2_z;

			sigmoid2_a <= sigmoid1_z;
		end
		S10 : begin
			mult_a <= u[1][0];
			mult_b <= x[3][0];

			mult_a_2 <= w[0][1];
			mult_b_2 <= sigmoid3_z;// h[2][1]
			mac_c_2 <= mult_z_2;

			sigmoid3_a <= sigmoid2_z;
		end
		S11 : begin
			mult_a <= u[1][1];
			mult_b <= x[3][1];
			mac_c <= mult_z;

			mult_a_2 <= w[0][2];
			mult_b_2 <= sigmoid3_z;// h[2][2]
			mac_c_2 <= mac_z_2;
		end
		S12 : begin
			mult_a <= u[1][2];
			mult_b <= x[3][2];
			mac_c <= mac_z;

			mult_a_2 <= w[1][0];
			mult_b_2 <= h[2][0];

			add_a <= h[3][0];
			add_b <= mac_z_2;// h[3][0]
		end
		S13 : begin
			mult_a <= u[2][0];
			mult_b <= x[3][0];

			mult_a_2 <= w[1][1];
			mult_b_2 <= h[2][1];
			mac_c_2 <= mult_z_2;

			sigmoid1_a <= add_z;// h[3][0]
		end
		S14 : begin
			mult_a <= u[2][1];
			mult_b <= x[3][1];
			mac_c <= mult_z;

			mult_a_2 <= w[1][2];
			mult_b_2 <= h[2][2];
			mac_c_2 <= mac_z_2;

			sigmoid2_a <= sigmoid1_z;
		end
		S15 : begin
			mult_a <= u[2][2];
			mult_b <= x[3][2];
			mac_c <= mac_z;

			mult_a_2 <= w[2][0];
			mult_b_2 <= h[2][0];

			add_a <= h[3][1];
			add_b <= mac_z_2;// h[3][1]

			sigmoid3_a <= sigmoid2_z;
		end
		S16 : begin
			mult_a_2 <= w[2][1];
			mult_b_2 <= h[2][1];
			mac_c_2 <= mult_z_2;

			sigmoid1_a <= add_z;// h[3][1]

/*------------------------------------------------------------*/
			mult_a <= v[0][2];
			mult_b <= h[1][2];
			mac_c <= x[1][0];
		end
		S17 : begin
			mult_a_2 <= w[2][2];
			mult_b_2 <= h[2][2];
			mac_c_2 <= mac_z_2;

			sigmoid2_a <= sigmoid1_z;

/*------------------------------------------------------------*/
			mult_a <= v[1][0];
			mult_b <= h[1][0];
		end
		S18 : begin
			add_a <= h[3][2];
			add_b <= mac_z_2;// h[3][2]

			sigmoid3_a <= sigmoid2_z;

/*------------------------------------------------------------*/
			mult_a <= v[1][1];
			mult_b <= h[1][1];
			mac_c <= mult_z;

			mult_a_2 <= v[2][0];
			mult_b_2 <= h[1][0];
		end
		S19 : begin
			sigmoid1_a <= add_z;// h[3][2]

/*------------------------------------------------------------*/
			mult_a <= v[1][2];
			mult_b <= h[1][2];
			mac_c <= mac_z;

			mult_a_2 <= v[2][1];
			mult_b_2 <= h[1][1];
			mac_c_2 <= mult_z_2;
		end
		S20 : begin
			sigmoid2_a <= sigmoid1_z;

/*------------------------------------------------------------*/
			mult_a_2 <= v[2][2];
			mult_b_2 <= h[1][2];
			mac_c_2 <= mac_z_2;

			mult_a <= v[0][0];
			mult_b <= h[2][0];
		end
		S21 : begin
			sigmoid3_a <= sigmoid2_z;

/*------------------------------------------------------------*/
			mult_a <= v[0][1];
			mult_b <= h[2][1];
			mac_c <= mult_z;

			mult_a_2 <= v[1][0];
			mult_b_2 <= h[2][0];
		end
		S22 : begin
			mult_a <= v[0][2];
			mult_b <= h[2][2];
			mac_c <= mac_z;

			mult_a_2 <= v[1][1];
			mult_b_2 <= h[2][1];
			mac_c_2 <= mult_z_2;
		end
		O1 : begin
			mult_a_2 <= v[1][2];
			mult_b_2 <= h[2][2];
			mac_c_2 <= mac_z_2;

			mult_a <= v[2][0];
			mult_b <= h[2][0];
		end
		O2 : begin
			mult_a <= v[2][1];
			mult_b <= h[2][1];
			mac_c <= mult_z;

			mult_a_2 <= v[0][0];
			mult_b_2 <= h[3][0];
		end
		O3 : begin
			mult_a <= v[2][2];
			mult_b <= h[2][2];
			mac_c <= mac_z;

			mult_a_2 <= v[0][1];
			mult_b_2 <= h[3][1];
			mac_c_2 <= mult_z_2;
		end
		O4 : begin
			mult_a_2 <= v[0][2];
			mult_b_2 <= h[3][2];
			mac_c_2 <= mac_z_2;

			mult_a <= v[1][0];
			mult_b <= h[3][0];
		end
		O5 : begin
			mult_a <= v[1][1];
			mult_b <= h[3][1];
			mac_c <= mult_z;

			mult_a_2 <= v[2][0];
			mult_b_2 <= h[3][0];
		end
		O6 : begin
			mult_a <= v[1][2];
			mult_b <= h[3][2];
			mac_c <= mac_z;

			mult_a_2 <= v[2][1];
			mult_b_2 <= h[3][1];
			mac_c_2 <= mult_z_2;
		end
		O7 : begin
			mult_a_2 <= v[2][2];
			mult_b_2 <= h[3][2];
			mac_c_2 <= mac_z_2;
		end
		O8 : begin end
		O9 : begin end
	endcase
end

always @(posedge clk) begin
	case (state)
		R1 : begin
			u[0][0] <= weight_u;
			w[0][0] <= weight_w;
			v[0][0] <= weight_v;
			x[1][0] <= data_x;
		end
		R2 : begin
			u[0][1] <= weight_u;
			w[0][1] <= weight_w;
			v[0][1] <= weight_v;
			x[1][1] <= data_x;
		end
		R3 : begin
			u[0][2] <= weight_u;
			w[0][2] <= weight_w;
			v[0][2] <= weight_v;
			x[1][2] <= data_x;
		end
		R4 : begin
			u[1][0] <= weight_u;
			w[1][0] <= weight_w;
			v[1][0] <= weight_v;
			x[2][0] <= data_x;

			h[1][0] <= mac_z; // u[0] * x1
		end
		R5 : begin
			u[1][1] <= weight_u;
			w[1][1] <= weight_w;
			v[1][1] <= weight_v;
			x[2][1] <= data_x;
		end
		R6 : begin
			u[1][2] <= weight_u;
			w[1][2] <= weight_w;
			v[1][2] <= weight_v;
			x[2][2] <= data_x;
		end
		R7 : begin
			u[2][0] <= weight_u;
			w[2][0] <= weight_w;
			v[2][0] <= weight_v;
			x[3][0] <= data_x;

			h[1][1] <= mac_z; // u[1] * x1

			h[2][0] <= mac_z_2; // u[0] * x2

			h[1][0] <= sigmoid3_z; // h1[0]
		end
		R8 : begin
			u[2][1] <= weight_u;
			w[2][1] <= weight_w;
			v[2][1] <= weight_v;
			x[3][1] <= data_x;

			h[3][0] <= mult_z_2;
		end
		R9 : begin
			u[2][2] <= weight_u;
			w[2][2] <= weight_w;
			v[2][2] <= weight_v;
			x[3][2] <= data_x;

			h[3][1] <= mult_z_2;
		end
		S1 : begin
			h[1][2] <= mac_z; // u[2] * x1

			h[3][2] <= mult_z_2;

			h[1][1] <= sigmoid3_z; // h1[1]
		end
		S2 : begin
			h[3][0] <= mac_z_2;
		end
		S3 : begin
			h[3][1] <= mac_z_2;
		end
		S4 : begin
			h[2][1] <= mac_z; // u[1] * x2

			h[3][2] <= mac_z_2;

			h[1][2] <= sigmoid3_z; // h1[2]
		end
		S5 : begin end
		S6 : begin
			h[2][0] <= add_z; // u[0] * x2 + w[0] * h1
		end
		S7 : begin
			h[2][2] <= mac_z; // u[2] * x2

			h[2][1] <= add_z; // u[1] * x2 + w[1] * h1
		end
		S8 : begin
			h[2][2] <= add_z; // u[2] * x2 + w[2] * h1
		end
		S9 : begin
			h[2][0] <= sigmoid3_z; // h2[0]


/*------------------------------------------------------------*/
			x[1][0] <= mac_z_2; // y1[0] (2 / 3)
		end
		S10 : begin
			h[3][0] <= mac_z; // u[0] * x3

			h[2][1] <= sigmoid3_z; // h2[1]
		end
		S11 : begin
			h[2][2] <= sigmoid3_z; // h2[2]
		end
		S12 : begin end
		S13 : begin
			h[3][1] <= mac_z; // u[1] * x3

			h[3][0] <= add_z; // u[0] * x3 + w[0] * h2
		end
		S14 : begin end
		S15 : begin end
		S16 : begin
			h[3][2] <= mac_z; // u[2] * x3

			h[3][1] <= add_z; // u[1] * x3 + w[1] * h2

			h[3][0] <= sigmoid3_z; // h3[0]
		end
		S17 : begin
			x[1][0] <= mac_z; // y1[0]
		end
		S18 : begin end
		S19 : begin
			h[3][2] <= add_z; // u[2] * x3 + w[2] * h2

			h[3][1] <= sigmoid3_z; // h3[1]
		end
		S20 : begin
			x[1][1] <= mac_z; // y1[1]
		end
		S21 : begin
			x[1][2] <= mac_z_2; // y1[2]
		end
		S22 : begin
			h[3][2] <= sigmoid3_z; // h3[2]

/*------------------------------------------------------------*/
		end
		O1 : begin
			x[2][0] <= mac_z; // y2[0]
		end
		O2 : begin
			x[2][1] <= mac_z_2; // y2[1]
		end
		O3 : begin end
		O4 : begin
			x[2][2] <= mac_z; // y2[2]
		end
		O5 : begin
			x[3][0] <= mac_z_2; // y3[0]
		end
		O6 : begin end
		O7 : begin
			x[3][1] <= mac_z; // y3[1]
		end
		O8 : begin
			x[3][2] <= mac_z_2; // y3[2]
		end
		O9 : begin end
	endcase
end

always @(*) begin
	out_valid <= 1'b0;
	out <= {fp_width{1'b0}};
	case (state)
		O1 : begin
			out_valid <= 1'b1;
			if (!x[1][0][fp_width - 1]) out[fp_width - 2:0] <= x[1][0][fp_width - 2:0];
		end
		O2 : begin
			out_valid <= 1'b1;
			if (!x[1][1][fp_width - 1]) out[fp_width - 2:0] <= x[1][1][fp_width - 2:0];
		end
		O3 : begin
			out_valid <= 1'b1;
			if (!x[1][2][fp_width - 1]) out[fp_width - 2:0] <= x[1][2][fp_width - 2:0];
		end
		O4 : begin
			out_valid <= 1'b1;
			if (!x[2][0][fp_width - 1]) out[fp_width - 2:0] <= x[2][0][fp_width - 2:0];
		end
		O5 : begin
			out_valid <= 1'b1;
			if (!x[2][1][fp_width - 1]) out[fp_width - 2:0] <= x[2][1][fp_width - 2:0];
		end
		O6 : begin
			out_valid <= 1'b1;
			if (!x[2][2][fp_width - 1]) out[fp_width - 2:0] <= x[2][2][fp_width - 2:0];
		end
		O7 : begin
			out_valid <= 1'b1;
			if (!x[3][0][fp_width - 1]) out[fp_width - 2:0] <= x[3][0][fp_width - 2:0];
		end
		O8 : begin
			out_valid <= 1'b1;
			if (!x[3][1][fp_width - 1]) out[fp_width - 2:0] <= x[3][1][fp_width - 2:0];
		end
		O9 : begin
			out_valid <= 1'b1;
			if (!x[3][2][fp_width - 1]) out[fp_width - 2:0] <= x[3][2][fp_width - 2:0];
		end
	endcase
end

endmodule
