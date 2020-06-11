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