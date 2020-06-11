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