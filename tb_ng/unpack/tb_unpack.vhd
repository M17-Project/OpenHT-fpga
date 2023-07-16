-----------------------------------------
-- Unpack testbench
--
-- Sebastien, ON4SEB
-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.data_types_context;

use vunit_lib.axi_stream_pkg.all;
use vunit_lib.stream_master_pkg.all;

use work.axi_stream_pkg.all;

entity tb_unpack is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_unpack is
  signal clk_i : std_logic;
  signal rst_i : std_logic;
  signal s_axis_iq_i : axis_in_iq_t;
  signal s_axis_iq_o : axis_out_iq_t;
  signal data_o : std_logic_vector(1 downto 0);

  constant master_stall_config : stall_config_t := new_stall_config(stall_probability => 0.2, min_stall_cycles => 2, max_stall_cycles => 10);
  constant master_axi_stream : axi_stream_master_t := new_axi_stream_master(data_length => 32, 
    stall_config => master_stall_config);

begin
  clk_p : process
  begin
    clk_i <= '0';
    wait for 5 ns;
    clk_i <= '1';
    wait for 5 ns;
  end process;

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    rst_i <= '0';
    wait for 100 ns;
    rst_i <= '1';

    for loop_var in 0 to 40 loop
        push_axi_stream(net, master_axi_stream, x"7FFF8000", tlast => '0');
    end loop;
    wait for 10 us;

    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  unpack_inst : entity work.unpack
  port map (
    clk_i => clk_i,
    nrst_i => rst_i,
    s_axis_iq_i => s_axis_iq_i,
    s_axis_iq_o => s_axis_iq_o,
    data_o => data_o
  );

  axi_stream_master_bfm: entity vunit_lib.axi_stream_master
    generic map (
      master => master_axi_stream)
    port map (
      aclk   => clk_i,
      tvalid => s_axis_iq_i.tvalid,
      tready => s_axis_iq_o.tready,
      tlast => s_axis_iq_i.tlast,
      tdata  => s_axis_iq_i.tdata);

end architecture;
