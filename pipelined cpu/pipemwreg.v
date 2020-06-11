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