module pipeid(mwreg,mrn,ern,ewreg,em2reg,mm2reg,dpc4,inst,ins,
	wrn,wdi,ealu,malu,mmo,wwreg,mem_clock,resetn,
	bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
	daluimm,da,db,dimm,dsa,drn,dshift,djal,
	drs,drt/*,npc*/,ebubble,dbubble); 
	// ID stage
	//ID 指令译码模块。注意其中包含控制器 CU、寄存器堆、及多个多路器等。
	//其中的寄存器堆，会在系统 clock 的下沿进行寄存器写入，也就是给信号从 WB 阶段
	//传输过来留有半个 clock 的延迟时间，亦即确保信号稳定。
	//该阶段 CU 产生的、要传播到流水线后级的信号较多。
	input wire mem_clock,resetn;
	input wire mwreg,ewreg,em2reg,mm2reg,wwreg;
	input wire[4:0] mrn,ern,wrn; //
	input wire[31:0] dpc4,ins,inst,wdi,ealu,malu,mmo;
	input wire ebubble;
	output wire dbubble;
	
	output wire dwreg,dm2reg,dwmem,daluimm,dshift,djal,wpcir;
	output wire[3:0] daluc;
	output wire[31:0] da,db,dimm,bpc,jpc,dsa;
	output wire [4:0] drn,drs,drt;
	output wire [1:0] pcsource;
	
	wire regrt,sext; //from cu,内部信号线 ,regrt=1选择rt ，regrt=0选择rd
	wire [31:0] q1,q2;
	wire [1:0] fwda,fwdb;
	wire rsrtequ = ~|(da^db); //beq bne指令要判断两数相不相等，如果相等，rsrtequ=1
	
	mux4x32 da_mux(q1,ealu,malu,mmo,fwda,da);//da还有个身份就是jr指令的跳转地址i
	mux4x32 db_mux(q2,ealu,malu,mmo,fwdb,db);
	assign drs = inst[25:21];
	assign drt = inst[20:16];
	assign dsa = {27'b0,inst[10:6]};
	assign dbubble = (pcsource != 2'b00); 
	//pcsource!=2'b00 的时候，也就是不是pc+4的情况,控制冒险都默认产生气泡。
	//dbubble 高有效，意味着产生气泡
	
	
	
	wire	e = sext & inst[15]; //符号拓展，sext信号和立即数最高位并
	assign dimm = {{16{e}}, inst[15:0]};
	assign jpc = {dpc4[31:28],inst[25:0],1'b0,1'b0}; //j和jal指令对应的pc值。 pc<-(pc+4)[31:28],addr <<2
	wire [31:0] offset = {{14{e}},inst[15:0],1'b0,1'b0};
	assign bpc = dpc4 + offset; //beq和bne对应的pc值
	assign drn = regrt? inst[20:16]:inst[15:11];  // rt:inst[20:16]  rd:inst[15:11]
	
	sc_cu cu(inst[31:26],inst[5:0],rsrtequ,dwmem,dwreg,regrt,dm2reg,daluc,dshift,daluimm,
		pcsource,djal,sext,wpcir,inst[25:21],inst[20:16],mrn,mm2reg,mwreg,ern,em2reg,ewreg,fwda,fwdb,ebubble);


	
	//regrt 用来选择rd还是rt作为写回寄存器
	regfile rf (drs,drt,wdi,wrn,wwreg,mem_clock,resetn,q1,q2);
	//(rna,rnb,d,wn,we,clk,clrn,qa,qb);
	
endmodule