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
	//由于后面补充了将IR清零的代码，所以这里的ebubble可以不用了。因为指令就是0，也产生不了什么控制信号了
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