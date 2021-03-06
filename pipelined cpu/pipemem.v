module pipemem(mwmem,malu,mb,clock,mem_clock,mmo,
	real_in_port0,real_in_port1,real_out_port0,real_out_port1,
	real_out_port2,real_out_port3); 
	
	input wire mwmem, clock,mem_clock;
	input wire [31:0] malu,mb,real_in_port0,real_in_port1;

	output wire [31:0] mmo,real_out_port0,real_out_port1,real_out_port2,real_out_port3;
	wire [31:0] datain, mem_dataout,io_dataout;
	
	wire write_mem_enable,write_io_enable;
	assign datain = mb; //之前保留eb的原因就是，rt中的值可能作为数据写入存储器
	assign write_mem_enable = mwmem & ~malu[7];  //malu[7]=0表示mem
	assign write_io_enable = mwmem & malu[7];    //malu[7]=1表示io
	
	io_input_reg io_input_regx2(malu,mem_clock,io_dataout,real_in_port0,real_in_port1);
	//(addr,io_clk,io_read_data,in_port0,in_port1)
	io_output_reg io_output_regx2(malu,datain,write_io_enable,mem_clock,real_out_port0,real_out_port1,real_out_port2,real_out_port3);
	//(addr,datain,write_io_enable,io_clk,out_port0,out_port1,out_port2); 
	
	lpm_ram_dq_dram dram (malu[6:2], mem_clock, datain, write_mem_enable,mem_dataout);
	//(addr[6:2], dmem_clk, datain, write_data_enable,mem_dataout ); addr是存储器地址，由alu计算出来所以存在malu中，除以4，转换成number
	mux2x32 mem_out_mux(mem_dataout,io_dataout,malu[7],mmo);

	
endmodule