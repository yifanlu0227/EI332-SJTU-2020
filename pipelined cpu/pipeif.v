module pipeif(pcsource,pc,bpc,da,jpc,npc,pc4,ins,mem_clock);
//instmem中取指令，同时设置下一条指令的PC值npc，
//pc4:原PC值+4
//bpc:beq和bne对应的pc值
//da:jr指令中读取的寄存器rs的值，
//jpc:j和jal指令对应的pc值。
//mem_clock是clock的反向，
//当clock从1跳变到0时，mem_clock从0跳变到1，读取出指令，使PC值有半个时钟周期的时间稳定下来，稳定后，再读取指令。

	input [1:0] pcsource;
	input mem_clock;
	input [31:0] pc,bpc,da,jpc;
	output wire [31:0] npc,pc4,ins;
	assign pc4 = pc+32'h4;
	
	mux4x32 npc_mux(pc4,bpc,da,jpc,pcsource,npc); //四选一，照着图排列
	//	选择pc+4/选择转移地址bne、beq/选择寄存器地址jr /选择跳转地址j、jal
	sc_instmem imem(pc,ins,mem_clock);
	
endmodule