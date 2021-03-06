
`include "parameters.v"

module iterator(
	clk,
	reset,
	en_ctrl, 
	i, 
	j, 
	k,
	l,
	m, 
	n,
	en_sum,
	en_save,
	fin_r,
	in_row,
	in_col
);
	parameter [`BYTE-1:0] CONV_DIM_IMG    = 32; //dimension of input img
	parameter [`BYTE-1:0] CONV_DIM_OUT    = 32; //dimension of output img
	parameter [`BYTE-1:0] CONV_DIM_KERNEL = 5;  //dimension of kernel mask
	parameter [`BYTE-1:0] CONV_OUT_CH     = 32; //dimension of output channel
	parameter [`BYTE-1:0] CONV_DIM_CH     = 3;
	parameter [`BYTE-1:0] STRIDE          = 1;
	parameter [`BYTE-1:0] PADDING         = 2;
	
	input clk;
	input en_ctrl;
	input reset;

	output en_sum;
	output en_save;
	output reg fin_r;
	output reg [`BYTE-1:0] i;
	output reg [`BYTE-1:0] j; 
	output reg [`BYTE-1:0] k; 
	output reg [`BYTE-1:0] m; 
	output reg [`BYTE-1:0] n; 
	output reg [`BYTE-1:0] l; 
	output signed [`BYTE-1:0]  in_row, in_col;

	reg fin, finish;
	
	wire cond;
	assign in_row = (STRIDE * j) + m - PADDING;
	assign in_col = (STRIDE * k) + n - PADDING;
	assign cond   = en_ctrl & ~fin_r;
	assign en_sum = (en_ctrl && (l < CONV_DIM_CH) && (in_row >= 8'd0 && in_col >= 8'd0 && in_row < CONV_DIM_IMG && in_col < CONV_DIM_IMG)) ? 1'b1 : 1'b0;
	assign en_save = (m > 8'd0 || n > 8'd0) ? 1'b0 : (j < 8'd2) ? 1'd1 : (l == 8'd0) ? 1'd1 : 1'b0; 
	
	/*always @(j, k, l, m, n, en_save) begin
		if (j < 8'd2 && m == 0 && n == 0) begin
			en_save <= 1;
		end else if(j >= 8'd2 && m == 0 && n == 0 && l == 0) begin
			en_save <= 1;
		end else begin
			en_save <= 0;
		end
	end*/

	always @(posedge clk) begin
		if(reset) begin
			fin <= 0;
			fin_r <= 0;
		end else begin
			fin <= finish;
			fin_r <= fin;
		end
	end
	
	always @(posedge clk) begin
		if(reset) begin
			i <= 0;
			j <= 0;
			k <= 0;
			m <= 0;
			n <= 0;
			finish <= 0;
		end else if(cond) begin
		    if(en_sum) begin
				l <= l + 8'd1;
			end else begin
				l <= 0;
				n <= n + 8'd1;
				if(n == (CONV_DIM_KERNEL-1)) begin
			    	n <= 8'b0;
			    	m <= m + 8'b1;
			    	if(m == (CONV_DIM_KERNEL-1)) begin
			    		m <= 0;
			       		k <= k + 8'b1;
			       		if(k == (CONV_DIM_OUT-1)) begin
			           		k <= 0;
			           		j <= j + 8'b1;
			           		if(j == (CONV_DIM_OUT-1)) begin
				           		j <= 0;
				           		i <= i + 8'b1;
				           		if(i == (CONV_OUT_CH-1)) begin
				            		i <= 0;
					          		finish <= 1;
				           		end
				   	    	end
			           	end
		           	end
			    end
			end
		end
	end

endmodule