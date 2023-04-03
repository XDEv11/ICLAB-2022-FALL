module TT(
	//Input Port
	clk,
	rst_n,
	in_valid,
	source,
	destination,

	//Output Port
	out_valid,
	cost
	);

input			   clk, rst_n, in_valid;
input	   [3:0]   source;
input	   [3:0]   destination;

output reg		  out_valid;
output reg  [3:0]   cost;

//==============================================//
reg [1:0] state, nxt_state;
localparam Idle		= 2'd0;
localparam Read		= 2'd3;
localparam Bfs		= 2'd1;
localparam Output	= 2'd2;

reg [3:0] s, d;
reg adj [0:15][0:15];
reg vis [0:15];
reg [2:0] dis2;
wire [2:0] dis2_add_1 = dis2 + 3'd1;
reg output1;

integer i, j;
genvar gv_i, gv_j;

wor vis_next1 [0:15];
generate
	for (gv_i = 0; gv_i <= 15; gv_i = gv_i + 1) begin
		for (gv_j = 0; gv_j <= 15; gv_j = gv_j + 1) begin
			if (gv_j < gv_i) begin
				assign vis_next1[gv_i] = (vis[gv_j] && adj[gv_j][gv_i]);
			end
			else if (gv_j == gv_i) begin
				assign vis_next1[gv_i] = vis[gv_j];
			end
			else if (gv_j > gv_i) begin
				assign vis_next1[gv_i] = (vis[gv_j] && adj[gv_i][gv_j]);
			end
		end
	end
endgenerate
wor vis_next2 [0:15];
generate
	for (gv_i = 0; gv_i <= 15; gv_i = gv_i + 1) begin
		for (gv_j = 0; gv_j <= 15; gv_j = gv_j + 1) begin
			if (gv_j < gv_i) begin
				assign vis_next2[gv_i] = (vis_next1[gv_j] && adj[gv_j][gv_i]);
			end
			else if (gv_j == gv_i) begin
				assign vis_next2[gv_i] = vis_next1[gv_j];
			end
			else if (gv_j > gv_i) begin
				assign vis_next2[gv_i] = (vis_next1[gv_j] && adj[gv_i][gv_j]);
			end
		end
	end
endgenerate

wire bfs_found1 = vis_next1[d];
wire bfs_found2 = vis_next2[d];
wire bfs_found = bfs_found1 || bfs_found2;

wand bfs_end;
generate
	for (gv_i = 0; gv_i <= 15; gv_i = gv_i + 1) begin
		assign bfs_end = (vis[gv_i] == vis_next2[gv_i]);
	end
endgenerate

always @(*) begin
	nxt_state <= state;
	case(state)
		Idle :
			if (in_valid) nxt_state <= Read;
		Read :
			if (!in_valid) begin
				if (bfs_found) nxt_state <= Output;
				else nxt_state <= Bfs;
			end
		Bfs : 
			if (bfs_found || bfs_end) nxt_state <= Idle;
		Output : nxt_state <= Idle;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) state <= Idle;
	else state <= nxt_state;
end

always @(posedge clk) begin
	for (i = 0; i <= 15; i = i + 1) vis[i] <= 1'bx; //
	dis2 <= 3'bx; //
	case (state)
		Idle : begin
			for (i = 0; i <= 15; i = i + 1)
				for (j = i + 1; j <= 15; j = j + 1) adj[i][j] <= 1'b0;
			//if (in_valid) begin
				//s <= source;
				d <= destination;

				for (i = 0; i <= 15; i = i + 1) vis[i] <= 1'b0;
				vis[source] <= 1'b1;
				dis2 <= 3'd0;
			//end
		end
		Read : begin
			if (in_valid) begin
				//if (source < destination)
					adj[source][destination] <= 1'b1;
				//else /*if (destination < source)*/
					adj[destination][source] <= 1'b1;

				for (i = 0; i <= 15; i = i + 1) vis[i] <= vis[i];
				dis2 <= 3'd0;
			end
			else begin
				output1 <= bfs_found1;
				for (i = 0; i <= 15; i = i + 1) vis[i] <= vis_next2[i];
				dis2 <= dis2_add_1;
			end
		end
		Bfs : begin
			for (i = 0; i <= 15; i = i + 1) vis[i] <= vis_next2[i];
			dis2 <= dis2_add_1;
		end
	endcase
end

always @(*) begin
	out_valid <= 1'b0;
	cost <= 4'b0;
	case (state)
		Bfs : begin
			if (bfs_found) begin
				out_valid <= 1'b1;
				cost <= bfs_found1 ? {dis2, 1'b1} : {dis2_add_1, 1'b0};
			end
			else if (bfs_end) begin
				out_valid <= 1'b1;
				cost <= 4'd0;
			end
		end
		Output : begin
			out_valid <= 1'b1;
			cost <= output1 ? 4'd1 : 4'd2;
		end
	endcase
end

endmodule 
