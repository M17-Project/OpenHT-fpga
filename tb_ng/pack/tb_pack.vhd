-----------------------------------------
-- Pack testbench
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

entity tb_pack is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_pack is
  signal clk_i : std_logic;
  signal rst_i : std_logic;
  signal m_axis_iq_i : axis_in_iq_t;
  signal m_axis_iq_o : axis_out_iq_t;
  signal data_o : std_logic_vector(1 downto 0);
  
  signal ddr_clk : std_logic;
  signal ddr_data : std_logic_vector(1 downto 0);

  constant protocol_checker : axi_stream_protocol_checker_t := new_axi_stream_protocol_checker(
    data_length => 32,
    logger      => get_logger("protocol_checker"),
    max_waits   => 64
  );

  constant slave_stall_config : stall_config_t := new_stall_config(stall_probability => 0.2, min_stall_cycles => 2, max_stall_cycles => 40);
  constant slave_axi_stream : axi_stream_slave_t := new_axi_stream_slave(
    data_length => 32);

begin
  clk_p : process
  begin
    clk_i <= '0';
    wait for 5 ns;
    clk_i <= '1';
    wait for 5 ns;
  end process;

  main : process
    variable data_in : std_logic_vector(31 downto 0);
    variable tlast_in : std_logic;
  begin
    test_runner_setup(runner, runner_cfg);
    rst_i <= '0';
    wait for 100 ns;
    rst_i <= '1';
    for i in 0 to 49 loop
      pop_axi_stream(net, slave_axi_stream, data_in, tlast_in);
    end loop;

    wait for 10 us;

    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  data_p : process
    type ddr_data_t is array (natural range<>) of std_logic_vector(1 downto 0);
    constant ddr_dat : ddr_data_t(0 to 63) := ("00", "00", "00", "00", "00", "00", "00", "00",
    "00", "00", "00", "00", "00", "00", "00", "00",
    "10", "11", "01", "00", "11", "10", "00", "01",
    "01", "00", "11", "01", "00", "00", "11", "00",
    "00", "00", "00", "00", "00", "00", "00", "00",
    "00", "00", "00", "00", "00", "00", "00", "00",
  --  "01", "00", "11", "01", "10", "00", "11", "00",
    "10", "11", "01", "00", "11", "10", "00", "01",
    "01", "00", "11", "01", "00", "00", "11", "00"
 --   "00", "00", "00", "00", "00", "00", "00", "00",
 --   "10", "11", "01", "00", "11", "10", "00", "01",
 --   "01", "00", "11", "01", "00", "00", "11", "00"
    );
    variable idx : natural := 0;
  begin
    ddr_data <= (others => '0');
    wait until rising_edge(rst_i);
    wait for 100 ns;
    loop
      ddr_clk <= '0';
      wait for 7.8125 ns;
      ddr_data <= ddr_dat(idx)(0) & ddr_dat(idx)(1);
      ddr_clk <= '1';
      wait for 7.8125 ns;
      idx := idx + 1;
      if idx > ddr_dat'length-1 then
        idx := 0;
      end if;
    end loop;
  end process;

  ddr_pack_inst : entity work.ddr_pack
  port map (
    clk_i => clk_i,
    nrst_i => rst_i,
    ddr_din => ddr_data,
    ddr_clkin => ddr_clk,
    m_axis_iq_o => m_axis_iq_i,
    m_axis_iq_i => m_axis_iq_o
  );

  axi_stream_slave_inst : entity vunit_lib.axi_stream_slave
  generic map(
    slave => slave_axi_stream)
  port map(
    aclk     => clk_i,
    areset_n => rst_i,
    tvalid   => m_axis_iq_i.tvalid,
    tready   => m_axis_iq_o.tready,
    tdata    => m_axis_iq_i.tdata);

  axi_stream_protocol_checker_inst : entity vunit_lib.axi_stream_protocol_checker
  generic map(
    protocol_checker => protocol_checker)
  port map(
    aclk     => clk_i,
    areset_n => rst_i,
    tvalid   => m_axis_iq_i.tvalid,
    tready   => m_axis_iq_o.tready,
    tdata    => m_axis_iq_i.tdata
  );

end architecture;
