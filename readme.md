# 实验3 pipelined CPU（流水线）

518030910394 卢亦凡

## 一、实验目的

1. 理解计算机指令流水线的协调工作原理，初步掌握流水线的设计和实现原理。
2. 深刻理解流水线寄存器在流水线实现中所起的重要作用。
3. 理解和掌握流水段的划分、设计原理及其实现方法原理。
4. 掌握运算器、寄存器堆、存储器、控制器在流水工作方式下，有别于实验一的设
计和实现方法。
5. 掌握流水方式下，通过 I/O 端口与外部设备进行信息交互的方法。

## 二、实验要求

1. 完成 五级流水线 CPU 核心模块的设计 。
2. 完成对五级流水线 CPU 的 仿真，仿真测试程序应该具有与 实验一提供的标准测试
程序代码 相同 的功能。 对两种 CPU实现核心处理功能的过程和设计处理上的区别
作 对比 分析 。
3. 完成 流水线 CPU 的 IO 模块 仿真 ，对两种 CPU 实现相同IO功能的过程和设计处理上
的区别作对比分析

## 三、实验分析

流水线最核心的就是把每个阶段的功能分配清楚，有序实现。

1. **取指令的IF级电路：**

   最左边的流水线寄存器是程序计数器PC。IF右边的寄存器是指令寄存器IR。在clock上升沿，把IF中的指令存储器instmem取出的指令写入IR，同时把npc写入pc。npc是说pc有多个来源，`mux4x32 npc_mux(pc4,bpc,da,jpc,pcsource,npc); `在一个多选器里决定。

2. **指令译码ID级电路：**

   指令进入ID级。控制单元CU会根据指令码产生一系列的控制信号。同时，指令中的rs和rt位对应的寄存器数值都会被读出，无论会不会使用。控制信号有

   -  regrt为1时选择rt作为目的寄存器号，为0时选择rd；
   - aluimm为1时选择立即数送给ALU的b输入端，为0时选择寄存器数据；
   - aluc是ALU的操作控制码；
   - wmem为1时写存储器，为0时不写；
   - m2reg为1时选择存储器数据，为0时选择ALU的计算结果；
   - wreg为1时把结果写入寄存器堆，为0时r不写。

   由于我们要处理**控制冒险**，对于指令的一些处理将**提前到ID阶段**，

   在clock上升沿，这些数据和控制信号传入de_reg寄存器。

3. **指令执行EXE级电路：**

   EXE阶段，ALU计算出算术指令的结果，使用了来自de_reg的ealuc。其他未使用的控制指令进一步往后传递。alu的计算结果和epc4之间进行二选一（取决于当前的指令类型），得到ealu。clock上升沿的时候，这些数据和信号被传入em_reg。

4. **存储器访问MEM级电路：**
   
   在MEM主要是做一件事，要么将数据写入存储器，要么将出局从存储器中读出。至于选择哪一种行为，依然是由MEM前流水线寄存器中的控制信号决定的。clock上升沿的时候，将相关数据传入mw_reg。
   
5. **结果写回WB级电路：**

   这时从存储器中读出的数据/alu计算完成的数据已在流水线寄存器中准备好，由mw_reg的中的控制信号决定是否写回寄存器堆以及选择数据来源。

   

## 四、流水线冒险

流水线会遇到三类问题，分别是：

- 结构冒险（结构相关）
- 数据冒险（数据相关）
- 控制冒险（控制相关）

**结构冒险**是指流水线CPU在同时执行多条指令时硬件资源不足引起的冲突。比如流水线CPU只是用一个模块来存放指令和数据，而这个存储器模块又不支持两个同时访问。也就是IF的取指和MEM的读数/存数只能进行一个，造成的冲突。

**数据冒险**是指当前指令的操作数刚好是上一条或上上条指令的结果。由于计算出结果到写回寄存器还需要2个周期的时间，当前指令没法使用该结果作为操作数，由此造成的冲突。

但数据冒险也不是无法解决。当前指令的前一条在EXE阶段就完成了结果的计算，我们内部前推将其取来使用即可。使用直通（或称旁路）的方法，将EXE级的ealu和MEM级的malu、mmo传回到ID阶段，通过一个四选一多选器选出正确的操作数。

但是注意，lw指令的结果必须等到MEM阶段才能获取。这意味着下一条指令要用的话就必须等待一个周期。

**控制冒险**是CPU在执行跳转指令的时候会遇到的问题。由于跳转指令的发生在MEM阶段，因此会有多条本来不该发生的指令被取出并放入流水线执行。这是很严重的事情，多出来的指令会让流水线出错。我们的处理方法是，将对跳转指令的一处理提前到ID阶段，在ID阶段就判断跳转是否发生`(pcsource!=0) 我用dbubble表示`。若dbubble出现，我想出两种处理手段：

1. 冲刷流水线，在下次时钟上升沿清空IR（若不做处理，IR里inst存的该是跳转指令后相邻后面的一条指令，是我们不想见到的）。

2. 下一次时钟上升沿的时候将dbubble存进de_reg流水线寄存器，记为ebubble。接线让ebubble传回ID，这时跳转指令的后一指令也进入到了ID阶段。将该指令产生的控制信号全部清零，相当于阻止其进入EXE阶段，成功避免其影响。但这种操作会产生一个问题，就是跳转信号后面还是跳转信号(实验一的仿真波形720ns处beq指令后紧接j指令)，第二个跳转依然会在ID阶段被处理。不得不手动在beq指令后插入nop。相比之下，上一种方案没有这种顾忌。我先试了2再补充了1，所以代码变成两种方案的混合体。

   

## 五、代码实现

**pipelined_computer.v**

```verilog
//顶层文件就不贴出了，基本和给的一样
```

**pipepc.v**

```verilog
module pipepc(npc,wpcir,clock,resetn,pc);
//程序计数器模块，是最前面一级 IF 流水段的输入。
//npc: new pc 
//when wpcir=0 , do not write PC and IR
input wire [31:0] npc;
input wpcir;
input clock,resetn;
output reg [31:0] pc;
initial
begin
	pc <= -4;
end
always @(posedge clock)
begin
	if(resetn == 0)
	begin
		pc <= -4;
	end
	else 
	begin
		if(wpcir) // wpcir = 0 则插入气泡，保持PC不改变
		begin
			pc <= npc;
		end
	end
end
endmodule
```

**pipeif.v**

```verilog
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
```

**pipeir.v**

```verilog
module pipeir(pc4,ins,wpcir,clock,resetn,dpc4,inst,dbubble); // IF/ID 流水线寄存器
	//IF/ID 流水线寄存器模块，起承接 IF 阶段和 ID 阶段的流水任务。
	//在 clock 上升沿时，将 IF 阶段需传递给 ID 阶段的信息，锁存在 IF/ID 流水线寄存器
	//中，并呈现在 ID 阶段。
	input [31:0] pc4,ins;
	input dbubble;
	input wpcir,clock,resetn;
	output reg [31:0] dpc4,inst;
		
	always @(posedge clock)
	begin
		if(~resetn)
			begin
				dpc4 <= 0;
				inst <= 0; //指令清零
			end
		else
		begin 
			if(wpcir)  //例如lw后的add指令触发数据冒险，wpcir=0，则不写ir不执行下面语句。传给id的依然是add指令。
				begin
				dpc4 <= pc4; //数据锁存
				inst <= ins;
				end	
            if(dbubble) //跳转指令，就把IR清零！
				begin
				dpc4 <= 0;
				inst <= 0;
				end
		end
		
	end
	
endmodule
```

**pipeid.v**

```verilog
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
```

ID内部控制单元 **sc_cu.v**

```verilog
module sc_cu (op, func, rsrtequ, wmem, wreg, regrt, m2reg, aluc, shift,
              aluimm, pcsource, jal, sext, wpcir, rs, rt, mrn, mm2reg, mwreg, ern, em2reg, ewreg, fwda, fwdb,ebubble);
   input  [5:0] op,func;
   input        rsrtequ,ebubble;
	input  [4:0] rs, rt, mrn, ern; //newly added
	input 		 mm2reg, mwreg, em2reg, ewreg;  // newly added
	output       wpcir; //newly added
   output       wreg,regrt,jal,m2reg,shift,aluimm,sext,wmem;
   output [3:0] aluc;
   output [1:0] pcsource, fwda, fwdb; // newly added
	reg [1:0]	 fwda, fwdb;
   wire r_type = ~|op; //缩位运算符，归约或非，是000000结果才是1
   wire i_add = r_type & func[5] & ~func[4] & ~func[3] &
                ~func[2] & ~func[1] & ~func[0];          //100000
   wire i_sub = r_type & func[5] & ~func[4] & ~func[3] &
                ~func[2] &  func[1] & ~func[0];          //100010
      
   //  please complete the deleted code.
   
   wire i_and = r_type & func[5] & ~func[4] & ~func[3] &
                func[2] & ~func[1] & ~func[0];          //100100
   wire i_or  = r_type & func[5] & ~func[4] & ~func[3] &
                func[2] & ~func[1] & func[0];          //100101
   wire i_xor = r_type & func[5] & ~func[4] & ~func[3] &
                func[2] & func[1] & ~func[0];          //100110
   wire i_sll = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] & ~func[1] & ~func[0];          //000000
   wire i_srl = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] & func[1] & ~func[0];          //000010
   wire i_sra = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] & func[1] & func[0];          //000011
   wire i_jr  = r_type & ~func[5] & ~func[4] & func[3] &
                ~func[2] & ~func[1] & ~func[0];          //001000
                
   wire i_addi = ~op[5] & ~op[4] &  op[3] & ~op[2] & ~op[1] & ~op[0]; //001000
   wire i_andi = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] & ~op[0]; //001100
   
   wire i_ori  = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] & op[0]; //001101
   wire i_xori = ~op[5] & ~op[4] &  op[3] &  op[2] & op[1] & ~op[0]; //001110
   wire i_lw   = op[5] & ~op[4] &  ~op[3] &  ~op[2] & op[1] & op[0]; //100011
   wire i_sw   = op[5] & ~op[4] &  op[3] &  ~op[2] & op[1] & op[0]; //101011
   wire i_beq  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] & ~op[0]; //000100
   wire i_bne  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] & op[0]; //000101
   wire i_lui  = ~op[5] & ~op[4] &  op[3] &  op[2] & op[1] & op[0]; //001111
   wire i_j    = ~op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & ~op[0]; //000010
   wire i_jal  = ~op[5] & ~op[4] & ~op[3] & ~op[2] & op[1] & op[0]; //000011
   
  
   assign pcsource[1] = i_jr | i_j | i_jal;
   assign pcsource[0] = ( i_beq & rsrtequ ) | (i_bne & ~rsrtequ) | i_j | i_jal ;
	//在id阶段就判断是否发生跳转。带j的指令都是无条件跳转，而beq和bne在判断是否da=db后决定。da=db则z=0
   //beq、bne不跳转就是正常的pc+4,跳转是pc+4+(sign)imm<<2
	
	assign wpcir = ~(em2reg & (ern==rs | ern==rt ));  //em2reg有效,上一条是lw指令，且数据冒险
	//如果wpcir=0 插入气泡，把所有控制信号置0
	//ebubble=1表示前一条指令是跳转类型，并且已经保证发生跳转，目前在id的这条指令是不该出现的
	//所以把这条指令的控制信号全部清零
	wire signal_valid = (wpcir) & (~ebubble);
	assign wreg = signal_valid & (i_add | i_sub | i_and | i_or   | i_xor  |
                 i_sll | i_srl | i_sra | i_addi | i_andi |
                 i_ori | i_xori | i_lw | i_lui  | i_jal);
   
   assign aluc[3] = signal_valid & (i_sra);    // complete by yourself.
   assign aluc[2] = signal_valid & (i_sub | i_or | i_srl | i_sra | i_ori | i_beq | i_bne | i_lui);
   assign aluc[1] = signal_valid & (i_xor | i_sll | i_srl | i_sra | i_xori | i_lui);
   assign aluc[0] = signal_valid & (i_and | i_or | i_sll | i_srl | i_sra | i_andi | i_ori);
   assign shift   = signal_valid & (i_sll | i_srl | i_sra);

   assign aluimm  = signal_valid & (i_addi | i_andi | i_ori | i_xori | i_lw | i_sw | i_lui);
   assign sext    = signal_valid & (i_addi | i_lw | i_sw | i_beq | i_bne);
   assign wmem    = signal_valid & (i_sw);
   assign m2reg   = signal_valid & (i_lw);
   assign regrt   = (i_addi | i_andi | i_ori | i_xori | i_lw | i_lui); //无所谓，不后传,regrt=1时选择rt
   assign jal     = signal_valid & (i_jal);

	always @(*)
	begin
	fwda <= 2'b00; //正常无直通
	if(ewreg & ~em2reg &(ern!=0) & (ern==rs)) 
		//rs用到前条alu指令的结果。 如果上条往$0写的话，就要忽略，因为$0的恒为0，不可以直通
		begin
			fwda <= 2'b01; //select exe_alu : ealu
		end
	else
		begin
		if(mwreg & (mrn!=0) & (mrn==rs) &~mm2reg) //rs用到前前条alu指令的结果
			fwda <= 2'b10; //select mem_alu : malu
		else 
			begin 
				if(mwreg & (mrn!=0) & (mrn ==rs)& mm2reg) 
				//rs用到前前条lw指令的结果。如果用到前条指令lw的结果的话直接停顿了
					fwda <= 2'b11; //select mem_lw : mmo
			end
		end
	end
	
	always @(*)
	begin
	fwdb <= 2'b00; //正常无直通
	if(ewreg & ~em2reg &(ern!=0) & (ern==rt))
		begin
			fwdb <= 2'b01; //select exe_alu : ealu
		end
	else
		begin
		if(mwreg & (mrn!=0) & (mrn==rt) &~mm2reg)
			fwdb <= 2'b10; //select mem_alu : malu
		else 
			begin
				if(mwreg & (mrn!=0) & (mrn ==rt)& mm2reg)
					fwdb <= 2'b11; //select mem_lw : mmo
			end
		end
	end
endmodule
```

**pipedereg.v**

```verilog
module pipedereg(dbubble, drs, drt, dwreg, dm2reg, dwmem,
	daluc, daluimm, da, db, dimm, dsa, drn, dshift, djal,
	dpc4, clock, resetn, ebubble, ers, ert, ewreg, em2reg,
	ewmem, ealuc, ealuimm, ea, eb, eimm, esa, ern0, eshift, ejal, epc4)/*synthesis noprune*/;
	
	input dbubble,dwreg,dm2reg,dwmem,daluimm,dshift,djal;
	input clock,resetn;
	input [4:0] drs,drt,drn;
	input [3:0] daluc;
	input [31:0] da,db,dimm,dpc4,dsa;
	
	output reg ebubble;
	output reg ewreg, em2reg,ewmem,ealuimm,eshift,ejal;
	output reg[4:0] ers, ert, ern0; 
	output reg [3:0] ealuc;
	output reg [31:0] ea,eb,eimm,epc4,esa;
	
	always @(posedge clock)
	begin 
		if(~resetn)
		begin
			ewreg <= 0;
			em2reg <= 0;
			ewmem <= 0;
			ealuimm <= 0;
			eshift <= 0;
			ejal <= 0;
			ea <= 0;
			eb <= 0;
			eimm <= 0;
			epc4 <= 0;
			ern0 <= 0;
			ealuc <= 0;
			ers <= 0;
			ert <= 0;
			esa <= 0;
			ebubble <= 0;
		end
		else 
		begin
			ewreg <= dwreg;
			em2reg <= dm2reg;
			ewmem <= dwmem;
			ealuimm <= daluimm;
			eshift <= dshift;
			ejal <= djal;
			ea <= da;
			eb <= db;
			eimm <= dimm;
			epc4 <= dpc4;
			ern0 <= drn;
			ealuc <= daluc;
			ers <= drs;
			ert <= drt;
			esa <= dsa;
			ebubble <= dbubble;
		end
	end
endmodule
```

**pipeexe.v**

```verilog
module pipeexe(ealuc, ealuimm, ea, eb, eimm, esa, eshift, ern0,
	epc4, ejal, ern, ealu, ezero, ert, wrn, wdi, malu, wwreg,
	a,b,r); // EXE stage
	//( ealuimm, ea, eb, eimm, esa, eshift, ern0, epc4, ejal, ern, ealu, ezero, ert, wrn, wdi, malu, wwreg); // EXE stage
	
	input ealuimm,eshift,ejal;
	input [4:0] ert, esa, ern0 ; 
	input [3:0] ealuc;
	input [31:0] ea,eb,eimm,epc4;
	input [4:0] wrn;
	input [31:0] wdi;
	input [31:0] malu;
	input wwreg;
	
	output [31:0] ealu;
	output [4:0] ern;
	output ezero;
	
	output wire [31:0] a,b,r;
    //wire [31:0] epc8 = epc4+4; 由于没用delay slot，我们不需要pc+8
	assign ern = ern0 | {5{ejal}};  //if jal, then ern is 111111 refers to $31
	mux2x32 a_mux(ea,esa,eshift,a);
	mux2x32 b_mux(eb,eimm,ealuimm,b);
	mux2x32 ealu_mux(r,epc4,ejal,ealu);
    alu al_unit(a,b,ealuc,r,ezero); //这个ezero没用
	
endmodule
```

**alu.v**

```verilog
module alu (a,b,aluc,s,z);
   input [31:0] a,b;
   input [3:0] aluc;
   output [31:0] s;
   output        z;
   reg [31:0] s;
   reg        z;
   always @ (a or b or aluc) 
      begin                                   // event
         casex (aluc)
             4'bx000: s = a + b;              //x000 ADD
             4'bx100: s = a - b;              //x100 SUB
             4'bx001: s = a & b;              //x001 AND
             4'bx101: s = a | b;              //x101 OR
             4'bx010: s = a ^ b;              //x010 XOR
             4'bx110: s = b << 16;            //x110 LUI: imm << 16bit             
             4'b0011: s = b << a;             //0011 SLL: rd <- (rt << sa)
             4'b0111: s = b >> a;             //0111 SRL: rd <- (rt >> sa) (logical)
             4'b1111: s = $signed(b) >>> a;   //1111 SRA: rd <- (rt >> sa) (arithmetic)
             default: s = 0;
         endcase
         if (s == 0 )  z = 1;
            else z = 0;         
      end      
endmodule 
```

**pipeemreg.v**

```verilog
module pipeemreg(ewreg, em2reg,ewmem,ealu,eb,ern,ezero,clock,resetn,mwreg,mm2reg,mwmem,malu,mb,mrn,mzero);  
	input wire ewreg,em2reg,ewmem;
	input wire [31:0] ealu,eb;
	input wire [4:0] ern;
	input wire clock,resetn,ezero;
	
	output reg mwreg,mm2reg,mwmem;
	output reg [31:0] malu,mb;
	output reg [4:0] mrn;
	output reg mzero;
	
	always @(posedge clock)
	begin
		if(~resetn)
		begin
			mwreg <= 0;
			mm2reg <= 0;
			mwmem <= 0;
			malu <= 0;
			mb <= 0;
			mrn <= 0;
			mzero <= 0;
		end
		else 
		begin
			mwreg <= ewreg;
			mm2reg <= em2reg;
			mwmem <= ewmem;
			malu <= ealu;
			mb <= eb;
			mrn <= ern;
			mzero <= ezero;
		end
	end

endmodule
```

**pipemem.v**

```verilog
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
```

**pipemwreg.v**

```verilog
module pipemwreg(mwreg,mm2reg,mmo,malu,mrn,clock,resetn,wwreg,wm2reg,wmo,walu,wrn);
	input wire mwreg,mm2reg;
	input wire [31:0] mmo,malu;
	input wire [4:0] mrn;
	input wire clock,resetn;
	
	output reg wwreg, wm2reg;
	output reg [31:0] wmo,walu;
	output reg [4:0] wrn;
	always @(posedge clock)
	begin
		if(~resetn)
		begin
			wwreg <= 0;
			wm2reg <= 0;
			wmo <= 0;
			walu <= 0;
			wrn <= 0;
		end
		else begin
			wwreg <= mwreg;
			wm2reg <= mm2reg;
			wmo <= mmo;
			walu <= malu;
			wrn <= mrn;
		end
	end
	
endmodule
```

自己添加的代码主要如上，其他还可以在源码中仔细查看。



## 仿真结果

仿真结果和pdf中一致

### 实验一单周期波形测试

![](figure\1-0.PNG)

---

<img src="figure\1-1.PNG" alt="1-1" style="zoom:15%;" />    <img src="figure\1-2.PNG" alt="1-2" style="zoom:15%;" /> 

<img src="1-3.PNG" alt="1-3" style="zoom:15%;" />    <img src="figure\1-4.PNG" alt="1-4" style="zoom:15%;" /> 



### 实验二IO模块波形测试

![](figure\2-0.PNG)

---

<img src="figure\2-1.PNG" alt="2-1" style="zoom:15%;" />    <img src="figure\2-2.PNG" alt="2-2" style="zoom:15%;" /> 

<img src="figure\2-3.PNG" alt="2-3" style="zoom:15%;" />    <img src="figure\2-4.PNG" alt="2-4" style="zoom:15%;" /> 



## 实验感想

做完这次实验，感想quartus真是个非常难用的软件，调试bug都要靠波形仿真，一些错误也只报warning，非常考验心态。就是靠着耐心找出我代码中微小又致命的错误。

还有就是多多上网学习，看看其他的参考书，比自己闭门造车闷头去想要来的更好，这本身就是个学习的过程。