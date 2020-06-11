library verilog;
use verilog.vl_types.all;
entity pipelined_computer_vlg_check_tst is
    port(
        mem_clock       : in     vl_logic;
        oealu           : in     vl_logic_vector(31 downto 0);
        oins            : in     vl_logic_vector(31 downto 0);
        oinst           : in     vl_logic_vector(31 downto 0);
        omalu           : in     vl_logic_vector(31 downto 0);
        onpc            : in     vl_logic_vector(31 downto 0);
        opc             : in     vl_logic_vector(31 downto 0);
        out_port0       : in     vl_logic_vector(31 downto 0);
        out_port1       : in     vl_logic_vector(31 downto 0);
        out_port2       : in     vl_logic_vector(31 downto 0);
        out_port3       : in     vl_logic_vector(31 downto 0);
        owalu           : in     vl_logic_vector(31 downto 0);
        sampler_rx      : in     vl_logic
    );
end pipelined_computer_vlg_check_tst;
