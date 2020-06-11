library verilog;
use verilog.vl_types.all;
entity pipelined_computer_vlg_sample_tst is
    port(
        clock           : in     vl_logic;
        in_port0        : in     vl_logic_vector(5 downto 0);
        in_port1        : in     vl_logic_vector(5 downto 0);
        resetn          : in     vl_logic;
        sampler_tx      : out    vl_logic
    );
end pipelined_computer_vlg_sample_tst;
