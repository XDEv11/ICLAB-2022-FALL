module FD(input clk, INF.FD_inf inf);
import usertype::*;

Action				d_act;
Restaurant_id		d_res_id;
Food_id             d_food_ID;
servings_of_food    d_ser_food;
Delivery_man_id		d_id;
Customer_status		d_ctm_status;
logic rd_id_is_same;
assign rd_id_is_same = (d_res_id == d_id);

logic restaurant_flag;
D_man_Info restaurant_data;
res_info restaurant;

logic delivery_man_flag;
D_man_Info delivery_man;
res_info delivery_man_data;

Error_Msg err_msg;

// Order
Error_Msg err_msg_ordered;
res_info restaurant_ordered;
logic order_ok;
assign order_ok = (err_msg_ordered == No_Err);
limit_of_orders order_temp;
always_ff @(posedge clk) begin
	order_temp <= restaurant.limit_num_orders - restaurant.ser_FOOD1 - restaurant.ser_FOOD2 - restaurant.ser_FOOD3;
end
always_comb begin
	err_msg_ordered <= No_Err;
	if (order_temp < d_ser_food) err_msg_ordered <= Res_busy;

	restaurant_ordered <= restaurant;
	case (d_food_ID)
		FOOD1 : restaurant_ordered.ser_FOOD1 <= restaurant.ser_FOOD1 + d_ser_food;
		FOOD2 : restaurant_ordered.ser_FOOD2 <= restaurant.ser_FOOD2 + d_ser_food;
		FOOD3 : restaurant_ordered.ser_FOOD3 <= restaurant.ser_FOOD3 + d_ser_food;
	endcase
end

// Take
Error_Msg err_msg_took;
res_info restaurant_took;
D_man_Info delivery_man_took;
logic take_ok;
assign take_ok = (err_msg_took == No_Err);
servings_of_FOOD take_temp1;
always_comb begin
	take_temp1 <= 'bx;
	case (d_food_ID)
		FOOD1 : take_temp1 <= restaurant.ser_FOOD1;
		FOOD2 : take_temp1 <= restaurant.ser_FOOD2;
		FOOD3 : take_temp1 <= restaurant.ser_FOOD3;
	endcase
end
always_comb begin
	err_msg_took <= No_Err;
	if (delivery_man.ctm_info2.ctm_status != None) err_msg_took <= D_man_busy;
	else if (take_temp1 < d_ser_food) err_msg_took <= No_Food;

	restaurant_took <= restaurant;
	case (d_food_ID)
		FOOD1 : restaurant_took.ser_FOOD1 <= restaurant.ser_FOOD1 - d_ser_food;
		FOOD2 : restaurant_took.ser_FOOD2 <= restaurant.ser_FOOD2 - d_ser_food;
		FOOD3 : restaurant_took.ser_FOOD3 <= restaurant.ser_FOOD3 - d_ser_food;
	endcase
	delivery_man_took <= delivery_man;
	if (delivery_man.ctm_info1.ctm_status == None || (delivery_man.ctm_info1.ctm_status == Normal && d_ctm_status == VIP)) begin
		delivery_man_took.ctm_info1.ctm_status <= d_ctm_status;
		delivery_man_took.ctm_info1.res_ID <= d_res_id;
		delivery_man_took.ctm_info1.food_ID <= d_food_ID;
		delivery_man_took.ctm_info1.ser_food <= d_ser_food;
		delivery_man_took.ctm_info2 <= delivery_man.ctm_info1;
	end
	else begin
		delivery_man_took.ctm_info2.ctm_status <= d_ctm_status;
		delivery_man_took.ctm_info2.res_ID <= d_res_id;
		delivery_man_took.ctm_info2.food_ID <= d_food_ID;
		delivery_man_took.ctm_info2.ser_food <= d_ser_food;
	end
end

// Deliver
Error_Msg err_msg_delivered;
D_man_Info delivery_man_delivered;
logic deliver_ok;
assign deliver_ok = (err_msg_delivered == No_Err);
always_comb begin
	err_msg_delivered <= No_Err;
	if (delivery_man.ctm_info1.ctm_status == None) err_msg_delivered <= No_customers;

	delivery_man_delivered <= {delivery_man.ctm_info2, 16'b0};
end

// Cancel
Error_Msg err_msg_canceled;
D_man_Info delivery_man_canceled;
logic cancel_ok;
assign cancel_ok = (err_msg_canceled == No_Err);
logic res1_eq, food1_eq, ctm1_eq, res2_eq, food2_eq, ctm2_eq;
always_comb begin
	res1_eq <= (/*delivery_man.ctm_info1.ctm_status != None && */delivery_man.ctm_info1.res_ID == d_res_id);
	food1_eq <= (delivery_man.ctm_info1.food_ID == d_food_ID);
	res2_eq <= (delivery_man.ctm_info2.ctm_status != None && delivery_man.ctm_info2.res_ID == d_res_id);
	food2_eq <= (delivery_man.ctm_info2.food_ID == d_food_ID);
end
assign ctm1_eq = (res1_eq && food1_eq);
assign ctm2_eq = (res2_eq && food2_eq);
always_comb begin
	err_msg_canceled <= No_Err;
	if (delivery_man.ctm_info1.ctm_status == None) err_msg_canceled <= Wrong_cancel;
	else if (!res1_eq && !res2_eq) err_msg_canceled <= Wrong_res_ID;
	else if (!ctm1_eq && !ctm2_eq) err_msg_canceled <= Wrong_food_ID;

	delivery_man_canceled <= delivery_man;
	if (ctm1_eq) begin
		if (ctm2_eq) delivery_man_canceled.ctm_info1 <= 16'b0;
		else delivery_man_canceled.ctm_info1 <= delivery_man.ctm_info2;
		delivery_man_canceled.ctm_info2 <= 16'b0;
	end
	else begin
		if (ctm2_eq) delivery_man_canceled.ctm_info2 <= 16'b0;
	end
end

enum logic [4:0] {
	Idle			= 5'd0,
	Order_res		= 5'd1,
	Order_food1		= 5'd2,
	Order_food2		= 5'd3,
	Order_Readr		= 5'd4,
	Take_id			= 5'd5,
	Take_cus1		= 5'd6,
	Take_cus2		= 5'd7,
	Take_Readd		= 5'd8,
	Deliver_id		= 5'd9,
	Cancel_res		= 5'd10,
	Cancel_food		= 5'd11,
	Cancel_id		= 5'd12,
	Read_res1		= 5'd13,
	Read_res2		= 5'd14,
	Read_d_man1		= 5'd15,
	Read_d_man2		= 5'd16,
	Order_calc		= 5'd17,
	Order_calc2		= 5'd18,
	Take_calc		= 5'd19,
	Deliver_calc	= 5'd20,
	Cancel_calc		= 5'd21,
	Write_res1		= 5'd22,
	Write_res2		= 5'd23,
	Write_d_man1	= 5'd24,
	Write_d_man2	= 5'd25,
	Output			= 5'd26
} state, nxt_state;

always_comb begin
	nxt_state <= state;
	case (state)
		Idle :
			if (inf.act_valid) begin
				case (inf.D.d_act[0])
					Order	: nxt_state <= Order_res;
					Take	: nxt_state <= Take_id;
					Deliver	: nxt_state <= Deliver_id;
					Cancel	: nxt_state <= Cancel_res;
				endcase
			end
		Order_res :
			if (inf.res_valid) nxt_state <= Order_food1;
			else if (inf.food_valid) nxt_state <= Order_calc;
		Order_food1 :
			if (inf.food_valid) nxt_state <= Order_Readr;
			else nxt_state <= Order_food2;
		Order_food2 :
			if (inf.food_valid) begin
				if (restaurant_flag || inf.C_out_valid) nxt_state <= Order_calc;
				else nxt_state <= Order_Readr;
			end
		Order_Readr :
			if (restaurant_flag || inf.C_out_valid) nxt_state <= Order_calc;
		Take_id :
			if (inf.id_valid) nxt_state <= Take_cus1;
			else if (inf.cus_valid) nxt_state <= Read_res1;
		Take_cus1 :
			if (inf.cus_valid) nxt_state <= Read_res1;
			else nxt_state <= Take_cus2;
		Take_cus2 :
			if (inf.cus_valid) begin
				if (delivery_man_flag || inf.C_out_valid) nxt_state <= Read_res1;
				else nxt_state <= Take_Readd;
			end
		Take_Readd :
			if (delivery_man_flag || inf.C_out_valid) nxt_state <= Read_res1;
		Deliver_id :
			if (inf.id_valid) nxt_state <= Read_d_man1;
		Cancel_res :
			if (inf.res_valid) nxt_state <= Cancel_food;
		Cancel_food :
			if (inf.food_valid) nxt_state <= Cancel_id;
		Cancel_id :
			if (inf.id_valid) nxt_state <= Read_d_man1;
		Read_res1 : nxt_state <= Read_res2;
		Read_res2 :
			if (inf.C_out_valid) begin
				case (d_act)
					Take	: nxt_state <= Take_calc;
				endcase
			end
		Read_d_man1 : nxt_state <= Read_d_man2;
		Read_d_man2 :
			if (inf.C_out_valid) begin
				case (d_act)
					Deliver	: nxt_state <= Deliver_calc;
					Cancel	: nxt_state <= Cancel_calc;
				endcase
			end
		Order_calc : nxt_state <= Order_calc2;
		Order_calc2 :
			if (order_ok) nxt_state <= Write_res1;
			else nxt_state <= Output;
		Take_calc :
			if (take_ok) begin
				if (rd_id_is_same) nxt_state <= Write_d_man1;
				else nxt_state <= Write_res1;
			end
			else nxt_state <= Output;
		Deliver_calc :
			if (deliver_ok) nxt_state <= Write_d_man1;
			else nxt_state <= Output;
		Cancel_calc :
			if (cancel_ok) nxt_state <= Write_d_man1;
			else nxt_state <= Output;
		Write_res1 : nxt_state <= Write_res2;
		Write_res2 :
			if (inf.C_out_valid) begin
				nxt_state <= Output;
				case (d_act)
					//Order	: nxt_state <= Output;
					Take	: nxt_state <= Write_d_man1;
				endcase
			end
		Write_d_man1 : nxt_state <= Write_d_man2;
		Write_d_man2 :
			if (inf.C_out_valid) begin
				nxt_state <= Output;
				/*case (d_act)
					Take	: nxt_state <= Output;
					Deliver	: nxt_state <= Output;
					Cancel	: nxt_state <= Output;
				endcase*/
			end
		Output : nxt_state <= Idle;
	endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) state <= Idle;
	else state <= nxt_state;
end

always_comb begin
	inf.C_in_valid <= 1'b0;
	inf.C_r_wb <= 1'b0;
	inf.C_addr <= 8'b0;
	inf.C_data_w <= 64'b0;
	case (state)
		Order_food1, Read_res1 : begin
			inf.C_in_valid <= 1'b1;
			inf.C_r_wb <= 1'b1;
			inf.C_addr <= d_res_id;
		end
		Take_cus1, Read_d_man1 : begin
			inf.C_in_valid <= 1'b1;
			inf.C_r_wb <= 1'b1;
			inf.C_addr <= d_id;
		end
		Write_res1 : begin
			inf.C_in_valid <= 1'b1;
			inf.C_r_wb <= 1'b0;
			inf.C_addr <= d_res_id;
			inf.C_data_w <= {restaurant_data, restaurant};
		end
		Write_d_man1 : begin
			inf.C_in_valid <= 1'b1;
			inf.C_r_wb <= 1'b0;
			inf.C_addr <= d_id;
			inf.C_data_w <= {delivery_man, delivery_man_data};
		end
	endcase
end

always_ff @(posedge clk) begin
	case (state)
		Idle : begin
			if (inf.act_valid) begin
				d_act <= inf.D.d_act[0];
			end
		end
		Order_res : begin
			if (inf.res_valid) begin
				d_res_id <= inf.D.d_res_id[0];
			end
			else if (inf.food_valid) begin
				d_food_ID <= inf.D.d_food_ID_ser[0].d_food_ID;
				d_ser_food <= inf.D.d_food_ID_ser[0].d_ser_food;
			end
		end
		Order_food1, Order_food2 : begin
			if (inf.food_valid) begin
				d_food_ID <= inf.D.d_food_ID_ser[0].d_food_ID;
				d_ser_food <= inf.D.d_food_ID_ser[0].d_ser_food;
			end
		end
		Take_id : begin
			if (inf.id_valid) begin
				d_id <= inf.D.d_id[0];
			end
			else if (inf.cus_valid) begin
				d_ctm_status <= inf.D.d_ctm_info[0].ctm_status;
				d_res_id <= inf.D.d_ctm_info[0].res_ID;
				d_food_ID <= inf.D.d_ctm_info[0].food_ID;
				d_ser_food <= inf.D.d_ctm_info[0].ser_food;
			end
		end
		Take_cus1, Take_cus2 : begin
			if (inf.cus_valid) begin
				d_ctm_status <= inf.D.d_ctm_info[0].ctm_status;
				d_res_id <= inf.D.d_ctm_info[0].res_ID;
				d_food_ID <= inf.D.d_ctm_info[0].food_ID;
				d_ser_food <= inf.D.d_ctm_info[0].ser_food;
			end
		end
		Deliver_id : begin
			if (inf.id_valid) begin
				d_id <= inf.D.d_id[0];
			end
		end
		Cancel_res : begin
			if (inf.res_valid) begin
				d_res_id <= inf.D.d_res_id[0];
			end
		end
		Cancel_food : begin
			if (inf.food_valid) begin
				d_food_ID <= inf.D.d_food_ID_ser[0].d_food_ID;
				d_ser_food <= inf.D.d_food_ID_ser[0].d_ser_food;
			end
		end
		Cancel_id : begin
			if (inf.id_valid) begin
				d_id <= inf.D.d_id[0];
			end
		end
	endcase
end

always_ff @(posedge clk) begin
	case (state)
		Idle : begin
			restaurant_flag <= 1'b0;
			delivery_man_flag <= 1'b0;
			err_msg <= No_Err;
		end
		Order_food2 : begin
			if (inf.C_out_valid) begin
				restaurant_flag <= 1'b1;
				restaurant_data	<= inf.C_data_r[63:32];
				restaurant		<= inf.C_data_r[31: 0];
			end
		end
		Take_cus2 : begin
			if (inf.C_out_valid) begin
				delivery_man_flag <= 1'b1;
				delivery_man		<= inf.C_data_r[63:32];
				delivery_man_data	<= inf.C_data_r[31: 0];
			end
		end
		Order_Readr, Read_res2 : begin
			if (inf.C_out_valid) begin
				restaurant_data	<= inf.C_data_r[63:32];
				restaurant		<= inf.C_data_r[31: 0];
			end
		end
		Take_Readd, Read_d_man2 : begin
			if (inf.C_out_valid) begin
				delivery_man		<= inf.C_data_r[63:32];
				delivery_man_data	<= inf.C_data_r[31: 0];
			end
		end
		Order_calc2 : begin
			err_msg <= err_msg_ordered;
			if (order_ok) begin
				restaurant <= restaurant_ordered;
				//if (rd_id_is_same) delivery_man_data <= restaurant_ordered;//
			end
		end
		Take_calc : begin
			err_msg <= err_msg_took;
			if (take_ok) begin
				restaurant <= restaurant_took;
				if (rd_id_is_same) delivery_man_data <= restaurant_took;
				delivery_man <= delivery_man_took;
				//if (rd_id_is_same) restaurant_data <= delivery_man_took;//
			end
		end
		Deliver_calc : begin
			err_msg <= err_msg_delivered;
			if (deliver_ok) begin
				delivery_man <= delivery_man_delivered;
				//if (rd_id_is_same) restaurant_data <= delivery_man_delivered;//
			end
		end
		Cancel_calc : begin
			err_msg <= err_msg_canceled;
			if (cancel_ok) begin
				delivery_man <= delivery_man_canceled;
				//if (rd_id_is_same) restaurant_data <= delivery_man_canceled;//
			end
		end
	endcase
end

always_comb begin
	inf.out_valid <= 1'b0;
	inf.err_msg <= No_Err;
	inf.complete <= 1'b0;
	inf.out_info <= 64'b0;
	case (state)
		Output : begin
			inf.out_valid <= 1'b1;
			inf.err_msg <= err_msg;
			if (err_msg == No_Err) begin
				inf.complete <= 1'b1;
				case (d_act)
					Order	: inf.out_info <= {32'b0, restaurant};
					Take	: inf.out_info <= {delivery_man, restaurant};
					Deliver	: inf.out_info <= {delivery_man, 32'b0};
					Cancel	: inf.out_info <= {delivery_man, 32'b0};
				endcase
			end
		end
	endcase
end

endmodule
