// synopsys translate_off

`include ...

// synopsys translate_on

module HD(code_word1, code_word2, out_n);
input [6:0] code_word1;
input [6:0] code_word2;
output signed [5:0] out_n;

wire eb1;
wire signed [3:0] c1;
HD_cwc cwc1(code_word1, eb1, c1);
wire eb2;
wire signed [3:0] c2;
HD_cwc cwc2(code_word2, eb2, c2);

reg signed [5:0] a, b;
reg add_sub;
always @(*) begin
	/*
	a <= (eb1 ? c1 : (c1 << 1));
	b <= (eb1 ? (c2 << 1) : c2);
	add_sub <= eb1 ^ eb2;
	*/
	case ({eb1, eb2})
		2'b00, 2'b01 : a <= (c1 << 1);
		2'b10, 2'b11 : a <= c1;
	endcase
	case ({eb1, eb2})
		2'b00, 2'b01 : b <= c2;
		2'b10, 2'b11 : b <= (c2 << 1);
	endcase
	case ({eb1, eb2})
		2'b00, 2'b11 : add_sub <= 1'b0;
		2'b01, 2'b10 : add_sub <= 1'b1;
	endcase
end

DW01_addsub #(6) addsuber (.A(a), .B(b), .CI(1'b0), .ADD_SUB(add_sub), .SUM(out_n), .CO());
//ADDSUB#(.width(6)) adder(a, b, add_sub, out_n);

endmodule

module HD_cwc(code_word, eb, c); // codeword correction
input [6:0] code_word;
output reg eb; // error bit
output reg signed [3:0] c; // correct original information

wire circle1 = code_word[6] ^ code_word[3] ^ code_word[2] ^ code_word[1];
wire circle2 = code_word[5] ^ code_word[3] ^ code_word[2] ^ code_word[0];
wire circle3 = code_word[4] ^ code_word[3] ^ code_word[1] ^ code_word[0];
always @(*) begin
	eb <= 1'bx;
	c <= code_word[3:0];
	case ({circle1, circle2, circle3})
		3'b111 : begin
			eb <= code_word[3];
			c[3] <= ~code_word[3];
		end
		3'b110 : begin
			eb <= code_word[2];
			c[2] <= ~code_word[2];
		end
		3'b101 : begin
			eb <= code_word[1];
			c[1] <= ~code_word[1];
		end
		3'b011 : begin
			eb <= code_word[0];
			c[0] <= ~code_word[0];
		end
		3'b100 : eb <= code_word[6];
		3'b010 : eb <= code_word[5];
		3'b001 : eb <= code_word[4];
		default : c <= 4'bx;
	endcase
end

/*
wire [7:1] rcw = {code_word[3:1], code_word[6], code_word[0], code_word[5:4]}; // rearranged clock word
wire circle1 = rcw[4] ^ rcw[7] ^ rcw[6] ^ rcw[5];
wire circle2 = rcw[2] ^ rcw[7] ^ rcw[6] ^ rcw[3];
wire circle3 = rcw[1] ^ rcw[7] ^ rcw[5] ^ rcw[3];
wire [2:0] ep = {circle1, circle2, circle3}; // error position
always @(*) begin
	eb <= rcw[ep];
	c <= {rcw[7:5], rcw[3]};
	case (ep)
		3'd7 : c[3] <= ~rcw[7];
		3'd6 : c[2] <= ~rcw[6];
		3'd5 : c[1] <= ~rcw[5];
		3'd3 : c[0] <= ~rcw[3];
	endcase
end
*/

/*
wire circle1 = code_word[6] ^ code_word[3] ^ code_word[2] ^ code_word[1];
wire circle2 = code_word[5] ^ code_word[3] ^ code_word[2] ^ code_word[0];
wire circle3 = code_word[4] ^ code_word[3] ^ code_word[1] ^ code_word[0];
reg [6:0] err;
always @(*) begin
	err <= 7'b0;
	case ({circle1, circle2, circle3})
		3'b111 : err[3] <= 1'b1;
		3'b110 : err[2] <= 1'b1;
		3'b101 : err[1] <= 1'b1;
		3'b011 : err[0] <= 1'b1;
		3'b100 : err[6] <= 1'b1;
		3'b010 : err[5] <= 1'b1;
		3'b001 : err[4] <= 1'b1;
		default : err <= 7'bx;
	endcase
end
always @(*) begin
	eb <= |(code_word & err);
	c <= code_word[3:0] ^ err[3:0];
end
*/

endmodule

module HA(a, b, s, c);
input a;
input b;
output s;
output c;

assign s = a ^ b;
assign c = a & b;
endmodule

module FA(a, b, cin, s, cout);
input a;
input b;
input cin;
output s;
output cout;

wire s1, c1;
HA ha1(a, b, s1, c1);
wire s2, c2;
HA ha2(s1, cin, s2, c2);
assign s = s2;
assign cout = c1 | c2;
endmodule

module ADDSUB#(parameter width = 1) (a, b, add_sub, s);
input [width - 1:0] a;
input [width - 1:0] b;
input add_sub;
output [width - 1:0] s;

wire [width - 1:0] c;
FA fa0(a[0], b[0] ^ add_sub, add_sub, s[0], c[0]);
genvar gv_i;
generate
	for (gv_i = 1; gv_i < width; gv_i = gv_i + 1) begin
		FA fa(a[gv_i], b[gv_i] ^ add_sub, c[gv_i - 1], s[gv_i], c[gv_i]);
	end
endgenerate
endmodule





