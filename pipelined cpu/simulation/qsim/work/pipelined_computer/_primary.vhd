library verilog;
use verilog.vl_types.all;
entity pipelined_computer is
    port(
        resetn          : in     vl_logic;
        clock           : in     vl_logic;
        mem_clock       : out    vl_logic;
        opc             : out    vl_logic_vector(31 downto 0);
        oinst           : out    vl_logic_vector(31 downto 0);
        oins            : out    vl_logic_vector(31 downto 0);
        oealu           : out    vl_logic_vector(31 downto 0);
        omalu           : out    vl_logic_vector(31 downto 0);
        owalu           : out    vl_logic_vector(31 downto 0);
        onpc            : out    vl_logic_vector(31 downto 0);
        in_port0        : in     vl_logic_vector(5 downto 0);
        in_port1        : in     vl_logic_vector(5 downto 0);
        out_port0       : out    vl_logic_vector(31 downto 0);
        out_port1       : out    vl_logic_vector(31 downto 0);
        out_port2       : out    vl_logic_vector(31 downto 0);
        out_port3       : out    vl_logic_vector(31 downto 0)
    );
end pipelined_computer;
