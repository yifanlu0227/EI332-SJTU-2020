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