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
	//wire [31:0] epc8 = epc4+4;
	assign ern = ern0 | {5{ejal}};  //if jal, then ern is 111111 refers to $31
	mux2x32 a_mux(ea,esa,eshift,a);
	mux2x32 b_mux(eb,eimm,ealuimm,b);
	mux2x32 ealu_mux(r,epc4,ejal,ealu);
	alu al_unit(a,b,ealuc,r,ezero);
	
	
endmodule