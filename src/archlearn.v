`include "parameters.v"

/*******************************************************************
*Module name:  archlearn
*Date Created: 05/08/2019
*Last Modified: 27/09/2019
*Description: Main module to cnn acceleration.
********************************************************************/
`define DATA               "C:/Users/gabri/Documents/Projetos/ArchLearn/simulation/result_conv1.txt"
`define DATA2              "C:/Users/gabri/Documents/Projetos/ArchLearn/simulation/result_conv2.txt"
`define DATA3              "C:/Users/gabri/Documents/Projetos/ArchLearn/simulation/result_conv3.txt"
`define IMG1_DATA          "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/debug_input1.mem"
`define CONV1_DATA         "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/conv1_wt.mem"
`define BIAS1_DATA         "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/conv1_bias.mem"
`define IMG2_DATA          "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/debug_input2.mem"
`define CONV2_DATA         "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/conv2_wt.mem"
`define BIAS2_DATA         "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/conv2_bias.mem"
`define IMG3_DATA          "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/debug_input3.mem"
`define CONV3_DATA         "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/conv3_wt.mem"
`define BIAS3_DATA         "C:/Users/gabri/Documents/Projetos/ArchLearn/testbenches/mem_files/conv3_bias.mem"

module archlearn(
    clk50,
    mosi,
    miso, 
    nss,
    sclk,
    reset,
	hex0,
	hex4,
	hex5,
	hex6,
	hex7,
	ledr,
	ledg,
	conv_end
);

    parameter [`BYTE-1:0] CONV_DIM_IMG2    = 16;
    parameter [`BYTE-1:0] CONV_DIM_OUT2    = 16;   //dimension of output img
    parameter [`BYTE-1:0] CONV_DIM_KERNEL2 = 5;    //dimension of kernel mask
    parameter [`BYTE-1:0] CONV_DIM_CH2     = 32;   //dimension of input channel
    parameter [`BYTE-1:0] CONV_OUT_CH2     = 16;  //dimension of output channel
    parameter [`BYTE-1:0] STRIDE2          = 1;   //stride len
    parameter [`BYTE-1:0] PADDING2         = 2;   // padding len
    parameter [`BYTE-1:0] KSIZE2           = 3;

    parameter [`BYTE-1:0] CONV_DIM_IMG3    = 8;
    parameter [`BYTE-1:0] CONV_DIM_OUT3    = 8;   //dimension of output img
    parameter [`BYTE-1:0] CONV_DIM_KERNEL3 = 5;    //dimension of kernel mask
    parameter [`BYTE-1:0] CONV_DIM_CH3     = 16;   //dimension of input channel
    parameter [`BYTE-1:0] CONV_OUT_CH3     = 32;  //dimension of output channel
    parameter [`BYTE-1:0] STRIDE3          = 1;   //stride len
    parameter [`BYTE-1:0] PADDING3         = 2;   // padding len
    parameter [`BYTE-1:0] KSIZE3           = 2;

	input clk50;
	input mosi;
	inout miso;
	input nss;
	input sclk;
	input reset;
    output [0:6] hex0, hex4, hex5, hex6, hex7;
	output [17:0] ledr;
	output [6:0] ledg;
	output conv_end;

	wire [3:0] state_debug;
	wire [`BYTE-1:0] stsourcedata;
	wire [`BYTE-1:0] stsinkdata;
	wire stsinkvalid;
	wire stsourceready;
	wire stsourcevalid;
	wire stsinkready;

	spi spi4(
		.sysclk(clk50),
		.nreset(~reset),
		.mosi(mosi),
		.nss(nss),
		.miso(miso),
		.sclk(sclk),
		.stsourceready (stsourceready), // avalon_streaming_source.ready
		.stsourcevalid (stsourcevalid), //                        .valid
		.stsourcedata  (stsourcedata),  //                        .data out
		.stsinkvalid   (stsinkvalid),   //   avalon_streaming_sink.valid out
		.stsinkdata    (stsinkdata),    //                        .data
		.stsinkready   (stsinkready)    //                        .ready out
	);

    assign data_in = (en_rmem == 3'b001) ? data_in1 : 
					 (en_rmem == 3'b010) ? data_in2 : 
					 (en_rmem == 3'b100) ? data_in3 : 8'h4a;

    assign convin = convin_r & en_conv;
	assign conv_end = (convin > 3'b0) ? 1'b1 : 1'b0;

    assign ledr[8:0] = en_wmem;
	assign ledr[11:9] = convin_r;
	assign ledr[17:12] = 6'b0;
	assign ledg[2:0] = en_rmem;
	assign ledg[6:4] = en_conv;
	assign ledg[3] = 1'b0;
	
	convert h0(clk50, state_debug, hex0);
	convert h4(clk50, data_in[3:0], hex4);
	convert h5(clk50, data_in[7:4], hex5);
	convert h6(clk50, data_out[3:0], hex6);
	convert h7(clk50, data_out[7:4], hex7);

	wire [7:0]  data_in, data_in1, data_in2, data_in3, data_out;
	wire [2:0]  convin;
	wire [15:0] addr;
	wire [8:0]  en_wmem;
	wire [2:0]  en_conv;
	wire [2:0]  en_rmem;
    wire [2:0]  convin_r;

	controller arch_control(
		.clk(clk50),
		.reset(reset),
		.stsinkvalid(stsourcevalid),
        .stsinkready(stsourceready),
		.stsinkdata(stsourcedata),
        .stsourceready(stsinkready),
		.stsourcedata(stsinkdata),
        .stsourcevalid(stsinkvalid),
		.data_in(data_in),
		.data_out(data_out),
		.convin(conv_end),
		.addr(addr),
		.en_wmem(en_wmem),
		.en_rmem(en_rmem),
		.en_conv(en_conv),
        .state_out(state_debug)
	);

    wire [15:0] s_addr, s_addr2, s_addr3;
    wire [15:0] w_addr, w_addr2, w_addr3;
    wire [15:0] b_addr, b_addr2, b_addr3;
    wire [15:0] save_addr, save_addr2, save_addr3;
    wire [7:0]  bias, bias2, bias3, signal, signal2, signal3, weight, weight2, weight3;
    wire signed [7:0] convout, convout2, convout3;
    wire s_convout, s_convout2, s_convout3, en_save, en_save2, en_save3, sload, sload2, sload3;  
    wire en_sum, en_sum2, en_sum3, en_write, en_write2, en_write3;
    wire en_mac, en_mac2, en_mac3, en_sat, en_sat2, en_sat3, en_mult_r, en_mult_r2, en_mult_r3;
    
    conv_ctrl groundctrl (
		.clk(clk50), 
		.reset(reset), 
		.en_ctrl(en_conv[0]), 
		.s_addr(s_addr), 
		.w_addr(w_addr), 
		.b_addr(b_addr), 
		.save_addr(save_addr), 
		.en_sum(en_sum), 
		.en_save(en_save),  
		.en_write(en_write), 
		.s_convout(s_convout), 
		.en_sat(en_sat), 
		.en_mac(en_mac), 
		.en_mult_r(en_mult_r), 
		.finish(convin_r[0])
	);

    convolve conv (
		.clk(clk50), 
		.reset(reset), 
		.clken(en_mac), 
		.s_convout(en_write), 
		.en_sat(en_sat), 
		.en_mult_r(en_mult_r), 
		.bias(bias), 
		.signal(signal), 
		.weight(weight), 
		.convout(convout)
	);

	conv_ctrl #(
        .CONV_DIM_IMG(CONV_DIM_IMG2),
        .CONV_DIM_OUT(CONV_DIM_OUT2),
        .CONV_DIM_KERNEL(CONV_DIM_KERNEL2),
        .CONV_DIM_CH(CONV_DIM_CH2),
        .CONV_OUT_CH(CONV_OUT_CH2),
        .STRIDE(STRIDE2),
        .PADDING(PADDING2),
        .KSIZE(KSIZE2)
    ) groundctrl2 (
        .clk(clk50),
        .reset(reset),
        .en_ctrl(en_conv[1]),
        .s_addr(s_addr2),
        .w_addr(w_addr2),
        .b_addr(b_addr2),
        .save_addr(save_addr2),
        .en_sum(en_sum2),
        .en_save(en_save2),
        .en_write(en_write2),
        .s_convout(s_convout2),
        .en_sat(en_sat2),
        .en_mac(en_mac2),
        .en_mult_r(en_mult_r2),
        .finish(convin_r[1])
    );

    convolve #(
        .BIAS_SHIFT(4),
        .OUT_SHIFT(9)
    ) conv2 (
        .clk(clk50),
        .reset(reset),
        .clken(en_mac2),
        .s_convout(en_write2),
        .en_sat(en_sat2),
        .en_mult_r(en_mult_r2),
        .bias(bias2),
        .signal(signal2),
        .weight(weight2),
        .convout(convout2)
    );

    conv_ctrl #(
        .CONV_DIM_IMG(CONV_DIM_IMG3),
        .CONV_DIM_OUT(CONV_DIM_OUT3),
        .CONV_DIM_KERNEL(CONV_DIM_KERNEL3),
        .CONV_DIM_CH(CONV_DIM_CH3),
        .CONV_OUT_CH(CONV_OUT_CH3),
        .STRIDE(STRIDE3),
        .PADDING(PADDING3),
        .KSIZE(KSIZE3)
    ) groundctrl3 (
        .clk(clk50),
        .reset(reset),
        .en_ctrl(en_conv[2]),
        .s_addr(s_addr3),
        .w_addr(w_addr3),
        .b_addr(b_addr3),
        .save_addr(save_addr3),
        .en_sum(en_sum3),
        .en_save(en_save3),
        .en_write(en_write3),
        .s_convout(s_convout3),
        .en_sat(en_sat3),
        .en_mac(en_mac3),
        .en_mult_r(en_mult_r3),
        .finish(convin_r[2])
    );

    convolve #(
        .BIAS_SHIFT(1),
        .OUT_SHIFT(7)
    ) conv3 (
        .clk(clk50),
        .reset(reset),
        .clken(en_mac3),
        .s_convout(en_write3),
        .en_sat(en_sat3),
        .en_mult_r(en_mult_r3),
        .bias(bias3),
        .signal(signal3),
        .weight(weight3),
        .convout(convout3)
    );

	ram #(
        .MEM_LENGTH(`INPUT1_LENGTH),
        .MEM_INIT_FILE(`IMG1_DATA)
    ) input_mem (
        .clk(clk50),
		.read_address(s_addr),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[0]),
        .data_out(signal)
    );

    ram #(
        .MEM_LENGTH(`INPUT2_LENGTH),
        .MEM_INIT_FILE(`IMG2_DATA)
    ) input_mem2 (
        .clk(clk50),
		.read_address(s_addr2),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[1]),
        .data_out(signal2)
    );

    ram #(
        .MEM_LENGTH(`INPUT3_LENGTH),
        .MEM_INIT_FILE(`IMG3_DATA)
    ) input_mem3 (
        .clk(clk50),
		.read_address(s_addr3),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[2]),
        .data_out(signal3)
    );

    ram #(
        .MEM_LENGTH(`CONV1_MEM_LENGTH),
        .MEM_INIT_FILE(`CONV1_DATA)
    ) conv1_in_mem (
        .clk(clk50),
		.read_address(w_addr),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[3]),
        .data_out(weight)
    );

    ram #(
        .MEM_LENGTH(`CONV2_MEM_LENGTH),
        .MEM_INIT_FILE(`CONV2_DATA)
    ) conv1_in_mem2 (
        .clk(clk50),
		.read_address(w_addr2),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[4]),
        .data_out(weight2)
    );

    ram #(
        .MEM_LENGTH(`CONV3_MEM_LENGTH),
        .MEM_INIT_FILE(`CONV3_DATA)
    ) conv1_in_mem3 (
        .clk(clk50),
		.read_address(w_addr3),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[5]),
        .data_out(weight3)
    );

    ram #(
        .MEM_LENGTH(`BIAS1_LENGTH),
        .MEM_INIT_FILE(`BIAS1_DATA)
    ) bias_in_mem (
        .clk(clk50),
		.read_address(b_addr),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[6]),
        .data_out(bias)
    );

    ram #(
        .MEM_LENGTH(`BIAS2_LENGTH),
        .MEM_INIT_FILE(`BIAS2_DATA)
    ) bias_in_mem2 (
        .clk(clk50),
		.read_address(b_addr2),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[7]),
        .data_out(bias2)
    );

    ram #(
        .MEM_LENGTH(`BIAS3_LENGTH),
        .MEM_INIT_FILE(`BIAS3_DATA)
    ) bias_in_mem3 (
        .clk(clk50),
		.read_address(b_addr3),
        .write_address(addr),
        .data_in(data_out),
        .write_enable(en_wmem[8]),
        .data_out(bias3)
    );

    ram #(
        .MEM_LENGTH(`CONV1OUT_LENGTH),
        .MEM_INIT_FILE()
    ) conv1_out_mem (
        .clk(clk50),
		.read_address(addr),
        .write_address(save_addr),
        .data_in(convout),
        .write_enable(en_write),
        .data_out(data_in1)
    );

    ram #(
        .MEM_LENGTH(`CONV2OUT_LENGTH),
		.MEM_INIT_FILE()
    ) conv1_out_mem2 (
        .clk(clk50),
		.read_address(addr),
        .write_address(save_addr2),
        .data_in(convout2),
        .write_enable(en_write2),
        .data_out(data_in2)
    );

    ram #(
        .MEM_LENGTH(`CONV3OUT_LENGTH),
		.MEM_INIT_FILE()
    ) conv1_out_mem3 (
        .clk(clk50),
		.read_address(addr),
        .write_address(save_addr3),
        .data_in(convout3),
        .write_enable(en_write3),
        .data_out(data_in3)
    );

endmodule