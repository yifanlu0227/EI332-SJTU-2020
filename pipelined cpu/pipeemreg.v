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