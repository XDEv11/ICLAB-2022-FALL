`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_FD.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

// Read from DRAM
logic [7:0] dram ['h10000 : 'h10000 + 256 * 8 - 1];
res_info restaurants [0:255];
D_man_Info deliver_men [0:255];
initial begin
	$readmemh("../00_TESTBED/DRAM/dram.dat", dram);
	for (int i = 0; i < 256; ++i) begin
		restaurants[i] = {dram['h10000 + i * 8 + 0], dram['h10000 + i * 8 + 1], dram['h10000 + i * 8 + 2], dram['h10000 + i * 8 + 3]};
		deliver_men[i] = {dram['h10000 + i * 8 + 4], dram['h10000 + i * 8 + 5], dram['h10000 + i * 8 + 6], dram['h10000 + i * 8 + 7]};
	end
end

// Main
typedef struct {
    Action				d_act;
	int same;
	Restaurant_id 		d_res_id;
	Food_id             d_food_ID;
	servings_of_food    d_ser_food;
	Delivery_man_id		d_id;
	Customer_status     d_ctm_status;
} input_info;
typedef struct {
	logic complete;
	Error_Msg err_msg;
	logic [63:0] out_info;
} output_info;

`define act_num 400

input_info inputs [0:`act_num];
output_info outputs [0:`act_num];

int latency, total_latency;

initial begin
	gen_input_task;
	calc_output_task;

	total_latency = 0;

	reset_task;
	@(negedge clk);
	for (int act_cnt = 0; act_cnt < `act_num; ++act_cnt) begin

		give_input_task(act_cnt);
		check_output_task(act_cnt);

		//$display("%3d %p lat=%0d", act_cnt, inputs[act_cnt].d_act, latency); //

		total_latency = total_latency + latency;

		if (act_cnt != `act_num - 1) begin
			int gap = $urandom_range(2, 10);
			gap = 2; //
			repeat(gap) @(negedge clk);
		end
		else @(negedge clk);
	end
	//$display("tot_lat=%0d", total_latency); //
	//$display("Total coverage %f\%",$get_coverage()); //
	$finish;
end

// Task
task reset_task;
	inf.act_valid = 1'b0; inf.res_valid = 1'b0; inf.food_valid = 1'b0; inf.id_valid = 1'b0; inf.cus_valid = 1'b0; inf.D = 'bx;

	inf.rst_n = 1'b1;
	#1 inf.rst_n = 1'b0;
	#14 inf.rst_n = 1'b1;
endtask

task gen_input_task;
	int act_cnt = 0;

	// restaurants 0 - 254
	// (14, 0, 0, 0)
	// restaurants 255
	// (255, 0, 0, 0)

	int id1 = 0, id2 = 60;
	// delivery men 0 - 59
	// (false, false)
	// delivery men 60 - 256
	// (true, true)

	input_info order_Res_busy, order_success;
	input_info take_No_Food, take_D_man_busy;
	input_info deliver_No_customers, deliver_success;
	input_info cancel_Wrong_cancel, cancel_Wrong_res_ID, cancel_Wrong_food_ID;

// Order
	order_Res_busy.d_act = Order; order_Res_busy.same = 0;
	order_Res_busy.d_res_id = 0; order_Res_busy.d_food_ID = FOOD1; order_Res_busy.d_ser_food = 15;

	order_success.d_act = Order; order_success.same = 0;
	order_success.d_res_id = 255; order_success.d_food_ID = FOOD1; order_success.d_ser_food = 1;

// Take
	take_D_man_busy.d_act = Take; take_D_man_busy.same = 0;
	take_D_man_busy.d_id = id2;
	take_D_man_busy.d_res_id = id2; take_D_man_busy.d_food_ID = FOOD1; take_D_man_busy.d_ser_food = 1;

	take_No_Food.d_act = Take; take_No_Food.same = 0;
	take_No_Food.d_id = id1;
	take_No_Food.d_res_id = id1; take_No_Food.d_food_ID = FOOD1; take_No_Food.d_ser_food = 15;

// Deliver
	deliver_No_customers.d_act = Deliver;
	deliver_No_customers.d_id = id1;

	deliver_success.d_act = Deliver;
	deliver_success.d_id = id2;

// Cancel
	cancel_Wrong_cancel.d_act = Cancel;
	cancel_Wrong_cancel.d_id = id1;
	cancel_Wrong_cancel.d_res_id = 0; cancel_Wrong_cancel.d_food_ID = FOOD1; cancel_Wrong_cancel.d_ser_food = 0;

	cancel_Wrong_res_ID.d_act = Cancel;
	cancel_Wrong_res_ID.d_id = id2;
	cancel_Wrong_res_ID.d_res_id = 1; cancel_Wrong_res_ID.d_food_ID = FOOD1; cancel_Wrong_res_ID.d_ser_food = 0;

	cancel_Wrong_food_ID.d_act = Cancel;
	cancel_Wrong_food_ID.d_id = id2;
	cancel_Wrong_food_ID.d_res_id = 0; cancel_Wrong_food_ID.d_food_ID = FOOD3; cancel_Wrong_food_ID.d_ser_food = 0;

// errs (200 + 75)
	// 20 (Deliver <-> Take)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = deliver_No_customers;
		inputs[act_cnt].d_id = id1; ++id1;
		++act_cnt;
		inputs[act_cnt] = take_No_Food;
		inputs[act_cnt].d_id = id1; inputs[act_cnt].d_res_id = id1; ++id1;
		++act_cnt;
	end
	// 20 (Deliver <-> Order)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = deliver_No_customers;
		inputs[act_cnt].d_id = id1; ++id1;
		++act_cnt;
		inputs[act_cnt] = order_Res_busy;
		++act_cnt;
	end
	// 19 (Deliver <-> Cancel)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = deliver_success; // **
		inputs[act_cnt].d_id = id2; ++id2;
		++act_cnt;
		if (i != 9) begin
			inputs[act_cnt] = cancel_Wrong_cancel;
			inputs[act_cnt].d_id = id1; ++id1;
			++act_cnt;
		end
	end
	// 20 (Cancel <-> Take)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = cancel_Wrong_cancel;
		inputs[act_cnt].d_id = id1; ++id1;
		++act_cnt;
		inputs[act_cnt] = take_No_Food;
		inputs[act_cnt].d_id = id1; inputs[act_cnt].d_res_id = id1; ++id1;
		++act_cnt;
	end
	// 19 (Cancel <-> Order)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = cancel_Wrong_res_ID;
		inputs[act_cnt].d_id = id2; ++id2;
		++act_cnt;
		if (i != 9) begin
			inputs[act_cnt] = order_success; // **
			++act_cnt;
		end
	end
	// 20 (Order <-> Take)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = order_Res_busy;
		++act_cnt;
		inputs[act_cnt] = take_D_man_busy;
		inputs[act_cnt].d_id = id2; inputs[act_cnt].d_res_id = id2; ++id2;
		++act_cnt;
	end
	// 10 (Take <-> Take)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = take_D_man_busy; inputs[act_cnt].same = 1;
		inputs[act_cnt].d_id = id2 - 1; inputs[act_cnt].d_res_id = id2 - 1;
		++act_cnt;
	end

	// 60
	for (int i = 0; i < 60; ++i) begin
		inputs[act_cnt] = take_D_man_busy; inputs[act_cnt].same = 1;
		inputs[act_cnt].d_id = id2 - 1; inputs[act_cnt].d_res_id = id2 - 1;
		++act_cnt;
	end

	// 1 (Take -> Order)
	inputs[act_cnt] = order_success; // **
	++act_cnt;
	// 10 (Order <-> Order)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = order_success; inputs[act_cnt].same = 1; // **
		++act_cnt;
	end

	// 34
	for (int i = 0; i < 34; ++i) begin
		inputs[act_cnt] = order_success; inputs[act_cnt].same = 1; // **
		++act_cnt;
	end

	// 1 (Order -> Cancel)
	inputs[act_cnt] = cancel_Wrong_cancel;
	inputs[act_cnt].d_id = id1; ++id1;
	++act_cnt;
	// 10 (Cancel <-> Cancel)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = cancel_Wrong_res_ID;
		inputs[act_cnt].d_id = id2; ++id2;
		++act_cnt;
	end

	// 20
	for (int i = 0; i < 20; ++i) begin
		inputs[act_cnt] = cancel_Wrong_food_ID;
		inputs[act_cnt].d_id = id2; ++id2;
		++act_cnt;
	end

	// 1 (Cancel -> Deliver)
	inputs[act_cnt] = deliver_success; // **
	inputs[act_cnt].d_id = id2; ++id2;
	++act_cnt;
	// 10 (Deliver <-> Deliver)
	for (int i = 0; i < 10; ++i) begin
		inputs[act_cnt] = deliver_success; // **
		inputs[act_cnt].d_id = id2; ++id2;
		++act_cnt;
	end

// complete (200 - 75)
	// 125
	for (int i = 131; i < 256; ++i) begin
		inputs[act_cnt] = deliver_success;
		inputs[act_cnt].d_id = id2; ++id2;
		++act_cnt;
	end

	//$display("%d, %d, %d", id1, id2, act_cnt);
endtask

task calc_output_task;
	for (int act_cnt = 0; act_cnt < `act_num; ++act_cnt) begin
		outputs[act_cnt].complete = 1'b0;
		outputs[act_cnt].err_msg = No_Err;
		outputs[act_cnt].out_info = 64'b0;
		if (inputs[act_cnt].d_act == Order) begin
			if (restaurants[inputs[act_cnt].d_res_id].limit_num_orders >=
					{1'b0, restaurants[inputs[act_cnt].d_res_id].ser_FOOD1} +
					restaurants[inputs[act_cnt].d_res_id].ser_FOOD2 +
					restaurants[inputs[act_cnt].d_res_id].ser_FOOD3 +
					inputs[act_cnt].d_ser_food) begin
				case (inputs[act_cnt].d_food_ID)
					FOOD1 : restaurants[inputs[act_cnt].d_res_id].ser_FOOD1 += inputs[act_cnt].d_ser_food;
					FOOD2 : restaurants[inputs[act_cnt].d_res_id].ser_FOOD2 += inputs[act_cnt].d_ser_food;
					FOOD3 : restaurants[inputs[act_cnt].d_res_id].ser_FOOD3 += inputs[act_cnt].d_ser_food;
				endcase
				outputs[act_cnt].complete = 1'b1;
				outputs[act_cnt].out_info = {32'b0, restaurants[inputs[act_cnt].d_res_id]};
			end
			else outputs[act_cnt].err_msg = Res_busy;
		end
		else if (inputs[act_cnt].d_act == Take) begin
			if (deliver_men[inputs[act_cnt].d_id].ctm_info2.ctm_status != None) outputs[act_cnt].err_msg = D_man_busy;
			else begin
				case (inputs[act_cnt].d_food_ID)
					FOOD1 : begin
						if (restaurants[inputs[act_cnt].d_res_id].ser_FOOD1 >= inputs[act_cnt].d_ser_food)
							restaurants[inputs[act_cnt].d_res_id].ser_FOOD1 -= inputs[act_cnt].d_ser_food;
						else outputs[act_cnt].err_msg = No_Food;
					end
					FOOD2 : begin
						if (restaurants[inputs[act_cnt].d_res_id].ser_FOOD2 >= inputs[act_cnt].d_ser_food)
							restaurants[inputs[act_cnt].d_res_id].ser_FOOD2 -= inputs[act_cnt].d_ser_food;
						else outputs[act_cnt].err_msg = No_Food;
					end
					FOOD3 : begin
						if (restaurants[inputs[act_cnt].d_res_id].ser_FOOD3 >= inputs[act_cnt].d_ser_food)
							restaurants[inputs[act_cnt].d_res_id].ser_FOOD3 -= inputs[act_cnt].d_ser_food;
						else outputs[act_cnt].err_msg = No_Food;
					end
				endcase
				if (outputs[act_cnt].err_msg == No_Err) begin
					if (deliver_men[inputs[act_cnt].d_id].ctm_info1.ctm_status == None || (deliver_men[inputs[act_cnt].d_id].ctm_info1.ctm_status == Normal && inputs[act_cnt].d_ctm_status == VIP)) begin
						deliver_men[inputs[act_cnt].d_id].ctm_info2 = deliver_men[inputs[act_cnt].d_id].ctm_info1;
						deliver_men[inputs[act_cnt].d_id].ctm_info1.ctm_status = inputs[act_cnt].d_ctm_status;
						deliver_men[inputs[act_cnt].d_id].ctm_info1.res_ID = inputs[act_cnt].d_res_id;
						deliver_men[inputs[act_cnt].d_id].ctm_info1.food_ID = inputs[act_cnt].d_food_ID;
						deliver_men[inputs[act_cnt].d_id].ctm_info1.ser_food = inputs[act_cnt].d_ser_food;
					end
					else begin
						deliver_men[inputs[act_cnt].d_id].ctm_info2.ctm_status = inputs[act_cnt].d_ctm_status;
						deliver_men[inputs[act_cnt].d_id].ctm_info2.res_ID = inputs[act_cnt].d_res_id;
						deliver_men[inputs[act_cnt].d_id].ctm_info2.food_ID = inputs[act_cnt].d_food_ID;
						deliver_men[inputs[act_cnt].d_id].ctm_info2.ser_food = inputs[act_cnt].d_ser_food;
					end
					outputs[act_cnt].complete = 1'b1;
					outputs[act_cnt].out_info = {deliver_men[inputs[act_cnt].d_id], restaurants[inputs[act_cnt].d_res_id]};
				end
			end
		end
		else if (inputs[act_cnt].d_act == Deliver) begin
			if (deliver_men[inputs[act_cnt].d_id].ctm_info1.ctm_status == None) outputs[act_cnt].err_msg = No_customers;
			else begin
				deliver_men[inputs[act_cnt].d_id].ctm_info1 = deliver_men[inputs[act_cnt].d_id].ctm_info2;
				deliver_men[inputs[act_cnt].d_id].ctm_info2 = 16'b0;
				outputs[act_cnt].complete = 1'b1;
				outputs[act_cnt].out_info = {deliver_men[inputs[act_cnt].d_id], 32'b0};
			end
		end
		else if (inputs[act_cnt].d_act == Cancel) begin
			if (deliver_men[inputs[act_cnt].d_id].ctm_info1.ctm_status == None) outputs[act_cnt].err_msg = Wrong_cancel;
			else if (deliver_men[inputs[act_cnt].d_id].ctm_info1.res_ID != inputs[act_cnt].d_res_id &&
					(deliver_men[inputs[act_cnt].d_id].ctm_info2.res_ID != inputs[act_cnt].d_res_id))
				outputs[act_cnt].err_msg = Wrong_res_ID;
			else begin
				if (deliver_men[inputs[act_cnt].d_id].ctm_info1.res_ID == inputs[act_cnt].d_res_id &&
						deliver_men[inputs[act_cnt].d_id].ctm_info1.food_ID == inputs[act_cnt].d_food_ID) begin
					deliver_men[inputs[act_cnt].d_id].ctm_info1 = 16'b0;
					outputs[act_cnt].complete = 1'b1;
				end
				if (deliver_men[inputs[act_cnt].d_id].ctm_info2.res_ID == inputs[act_cnt].d_res_id &&
						deliver_men[inputs[act_cnt].d_id].ctm_info2.food_ID == inputs[act_cnt].d_food_ID) begin
					deliver_men[inputs[act_cnt].d_id].ctm_info2 = 16'b0;
					outputs[act_cnt].complete = 1'b1;
				end
				if (deliver_men[inputs[act_cnt].d_id].ctm_info1.ctm_status == None) begin
					deliver_men[inputs[act_cnt].d_id].ctm_info1 = deliver_men[inputs[act_cnt].d_id].ctm_info2;
					deliver_men[inputs[act_cnt].d_id].ctm_info2 = 16'b0;
				end
				if (outputs[act_cnt].complete == 1'b1) outputs[act_cnt].out_info = {deliver_men[inputs[act_cnt].d_id], 32'b0};
				else outputs[act_cnt].err_msg = Wrong_food_ID;
			end
		end
	end
endtask

task give_input_task (input int act_cnt);
	int arr [4], size = 0;

	arr[size++] = 0;
	if (inputs[act_cnt].d_act == Order) begin
		if (!inputs[act_cnt].same) arr[size++] = 1; // res
		arr[size++] = 2; // food
	end
	else if (inputs[act_cnt].d_act == Take) begin
		if (!inputs[act_cnt].same) arr[size++] = 3; // id
		arr[size++] = 4; // cus
	end
	else if (inputs[act_cnt].d_act == Deliver) begin
		arr[size++] = 3; // id
	end
	else if (inputs[act_cnt].d_act == Cancel) begin
		arr[size++] = 1; // res
		arr[size++] = 2; // food
		arr[size++] = 3; // id
	end

	for (int i = 0; i < size; ++i) begin
		case (arr[i])
			0 : begin // act
				inf.act_valid = 1'b1;
				inf.D.d_act[0] = inputs[act_cnt].d_act;
			end
			1 : begin // res
				inf.res_valid = 1'b1;
				inf.D.d_res_id[0] = inputs[act_cnt].d_res_id;
			end
			2 : begin // food
				inf.food_valid = 1'b1;
				inf.D.d_food_ID_ser[0].d_food_ID = inputs[act_cnt].d_food_ID;
				inf.D.d_food_ID_ser[0].d_ser_food = inputs[act_cnt].d_ser_food;
			end
			3 : begin // id
				inf.id_valid = 1'b1;
				inf.D.d_id[0] = inputs[act_cnt].d_id;
			end
			4 : begin // cus
				inf.cus_valid = 1'b1;
				inf.D.d_ctm_info[0].ctm_status = inputs[act_cnt].d_ctm_status;
				inf.D.d_ctm_info[0].res_ID = inputs[act_cnt].d_res_id;
				inf.D.d_ctm_info[0].food_ID = inputs[act_cnt].d_food_ID;
				inf.D.d_ctm_info[0].ser_food = inputs[act_cnt].d_ser_food;
			end
		endcase
		@(negedge clk);
		inf.act_valid = 1'b0; inf.res_valid = 1'b0; inf.food_valid = 1'b0; inf.id_valid = 1'b0; inf.cus_valid = 1'b0; inf.D = 'bx;
		if (i != size - 1) begin
			int gap = $urandom_range(1, 5);
			gap = 1; //
			repeat(gap) @(negedge clk);
		end
	end
	@(negedge clk);
endtask

task check_output_task (input int act_cnt);
	latency = 1;
	while (inf.out_valid === 1'b0) begin
		latency = latency + 1;
		@(negedge clk);
	end

	if (inf.complete !== outputs[act_cnt].complete || inf.err_msg !== outputs[act_cnt].err_msg || inf.out_info !== outputs[act_cnt].out_info) begin
		$display("Wrong Answer");
		$finish;
	end
endtask

endprogram
