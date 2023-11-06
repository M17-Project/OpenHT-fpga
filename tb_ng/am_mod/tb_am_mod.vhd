-----------------------------------------
-- AM modulator testbench
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
use vunit_lib.stream_slave_pkg.all;

use work.axi_stream_pkg.all;

entity tb_am_mod is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_am_mod is
  signal clk_i : std_logic;
  signal rst_i : std_logic;

  signal s_axis_mod_i : axis_in_iq_t;
  signal s_axis_mod_o : axis_out_iq_t;

  signal m_axis_iq_i : axis_out_iq_t;
  signal m_axis_iq_o : axis_in_iq_t;
  signal data_o : std_logic_vector(1 downto 0);

  constant protocol_checker : axi_stream_protocol_checker_t := new_axi_stream_protocol_checker(
    data_length => 32,
    logger      => get_logger("protocol_checker"),
    max_waits   => 64
  );

  constant master_stall_config : stall_config_t := new_stall_config(stall_probability => 0.0, min_stall_cycles => 2, max_stall_cycles => 40);
  constant master_axi_stream : axi_stream_master_t := new_axi_stream_master(data_length => 32,
    stall_config => master_stall_config);

  constant slave_stall_config : stall_config_t := new_stall_config(stall_probability => 0.2, min_stall_cycles => 2, max_stall_cycles => 40);
  constant slave_axi_stream : axi_stream_slave_t := new_axi_stream_slave(
    data_length => 32, stall_config => slave_stall_config);

begin
  clk_p : process
  begin
    clk_i <= '0';
    wait for 5 ns;
    clk_i <= '1';
    wait for 5 ns;
  end process;

  main : process
    variable tlast_in : std_logic;
    variable data_in : std_logic_vector(31 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);
    rst_i <= '0';
    wait for 100 ns;
    rst_i <= '1';

    for loop_var in 0 to 200 loop
        push_axi_stream(net, master_axi_stream, std_logic_vector(to_unsigned(loop_var, 16)) & X"0000", tlast => '0');
    end loop;

    for loop_var in 0 to 200 loop
        pop_axi_stream(net, slave_axi_stream, data_in, tlast_in);
        null;
    end loop;

    wait for 10 us;

    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  am_modulator_inst : entity work.am_modulator
  port map (
    clk_i => clk_i,
    s_axis_mod_i => s_axis_mod_i,
    s_axis_mod_o => s_axis_mod_o,
    m_axis_iq_o => m_axis_iq_o,
    m_axis_iq_i => m_axis_iq_i
  );

  axi_stream_master_bfm: entity vunit_lib.axi_stream_master
    generic map (
      master => master_axi_stream)
    port map (
      aclk   => clk_i,
      areset_n => rst_i,
      tvalid => s_axis_mod_i.tvalid,
      tready => s_axis_mod_o.tready,
      tdata  => s_axis_mod_i.tdata);

  axi_stream_slave_inst : entity vunit_lib.axi_stream_slave
  generic map(
    slave => slave_axi_stream)
  port map(
    aclk     => clk_i,
    areset_n => rst_i,
    tvalid   => m_axis_iq_o.tvalid,
    tready   => m_axis_iq_i.tready,
    tdata    => m_axis_iq_o.tdata);

  axi_stream_protocol_checker_inst : entity vunit_lib.axi_stream_protocol_checker
  generic map(
    protocol_checker => protocol_checker)
  port map(
    aclk     => clk_i,
    areset_n => rst_i,
    tvalid   => m_axis_iq_o.tvalid,
    tready   => m_axis_iq_i.tready,
    tdata    => m_axis_iq_o.tdata
  );

end architecture;
