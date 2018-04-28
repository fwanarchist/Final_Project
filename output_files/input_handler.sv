module input_handler (
	input logic Frame_Clk, Clk, Reset,
	input logic new_data,
	input logic [7:0] dx, dy,
	input logic dx_sign, dy_sign,
	input logic m1, m2, m3,
	output fixed_real Theta, Phi,
	output logic Click
);
	logic old_frame_clk, frame_clk_rising_edge, new_data_rising_edge, old_new_data, old_m1, old_m1_n, Click_n;
	logic [31:0] x_buffer, y_buffer, x_buffer_n, y_buffer_n;
	fixed_real Phi_n, Theta_n, x_buffer_scaled, y_buffer_scaled, Phi_n_raw, Theta_n_raw;
	
	assign x_buffer_scaled = ~{{6{x_buffer[31]}},x_buffer,26'b0} + 64'd1;
	assign y_buffer_scaled = {{6{y_buffer[31]}},x_buffer,26'b0};
	
	assign Theta_n_raw = x_buffer_scaled + Theta;
	assign Phi_n_raw = y_buffer_scaled + Phi;
	
	assign frame_clk_rising_edge = ~old_frame_clk && Frame_Clk;
	assign new_data_rising_edge = ~old_new_data && new_data;
	
	always_ff @ (posedge Clk) begin
		if(Reset) begin
			x_buffer <= 32'b0;
			y_buffer <= 32'b0;
			Theta <= 64'd90 << 32;
			Phi <= 64'd90 << 32;
			Click <= 1'b0;
			old_m1 <= 1'b1;
			old_frame_clk <= 1'b1;
		end
		else begin
			x_buffer <= x_buffer_n;
			y_buffer <= y_buffer_n;
			Theta <= Theta_n;
			Phi <= Phi_n;
			Click <= Click_n;
			old_m1 <= old_m1_n;
		end
		old_frame_clk <= Frame_Clk;
	end
	
	always_comb begin
		x_buffer_n = x_buffer;
		y_buffer_n = y_buffer;
		Theta_n = Theta;
		Phi_n = Phi;
		Click_n = Click;
		old_m1_n = old_m1;
		if(frame_clk_rising_edge) begin
			if(Phi_n_raw[63]) Phi_n = 63'b0;
			else if(Phi_n_raw > 64'd180 << 32) Phi_n = 63'd180 << 32;
			else Phi_n = Phi_n_raw;
			if(Theta_n_raw[63]) Theta_n = 63'b0;
			else if(Theta_n_raw > 64'd180 << 32) Theta_n = 63'd180 << 32;
			else Theta_n = Theta_n_raw;
			Click_n = 1'b0;
		end
		else if(new_data_rising_edge) begin
			x_buffer_n = x_buffer + dx_sign?~{24'b0,dx}+32'd1:{24'b0,dx};
			y_buffer_n = y_buffer + dy_sign?~{24'b0,dy}+32'd1:{24'b0,dy};
			old_m1_n = m1;
			if( m1 && ~old_m1) begin
				Click_n = 1'b1;
			end
		end
	end
endmodule
