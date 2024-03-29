-----------------------------------------
-- RSSI Estimator testbench
--
-- Frédéric Druppel, ON4PFD, fredcorp.cc
--
-- TODO : add arbitrary RSSI calculation
--        with variable attack, decay
--        and hold cycles
--
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

library osvvm;
use osvvm.RandomPkg.all;

use work.axi_stream_pkg.all;
use work.openht_utils_pkg.all;
use work.apb_pkg.all;
use work.apb_test_pkg.all;

entity tb_RSSI_estimator is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_RSSI_estimator is
  signal clk_i : std_logic;
  signal rst_i : std_logic;

  signal s_apb_i : apb_in_t;
  signal s_apb_o : apb_out_t;

  signal s_axis_i : axis_in_iq_t;
  signal s_axis_o : axis_out_iq_t;

  signal m_axis_i : axis_out_iq_t;
  signal m_axis_o : axis_in_iq_t;

  constant protocol_checker : axi_stream_protocol_checker_t := new_axi_stream_protocol_checker(
    data_length => 32,
    logger      => get_logger("protocol_checker"),
    max_waits   => 64
  );

  constant master_stall_config : stall_config_t := new_stall_config(stall_probability => 0.2, min_stall_cycles => 2, max_stall_cycles => 10);
  constant master_axi_stream : axi_stream_master_t := new_axi_stream_master(data_length => 32,
    stall_config => master_stall_config);

  constant slave_stall_config : stall_config_t := new_stall_config(stall_probability => 0.2, min_stall_cycles => 2, max_stall_cycles => 10);
  constant slave_axi_stream : axi_stream_slave_t := new_axi_stream_slave(
    data_length => 32, stall_config => slave_stall_config);

  shared variable rv : RandomPType;
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
    variable tkeep_in : std_logic_vector(3 downto 0);
    variable tstrb_in : std_logic_vector(3 downto 0);
    variable tid_in : std_logic_vector(0 downto 1);
    variable tdest_in : std_logic_vector(0 downto 1);
    variable tuser_in : std_logic_vector(0 downto 1);

    variable tstrb_out : std_logic_vector(3 downto 0) := X"C";
    variable data_out : std_logic_vector(31 downto 0);
    type accum_t is array (0 to 3) of signed(41 downto 0);

    variable apb_out : std_logic_vector(15 downto 0);
    
    variable acc_i : accum_t;
    variable acc_q : accum_t;
    variable subfilter : natural;

  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("test_APB_registers") then
        tstrb_out := X"F";
        rst_i <= '0';
        wait for 100 ns;
        rst_i <= '1';

        wait until rising_edge(clk_i);

        apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0001", "0000000000000000");    -- enable block
        apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0002", x"02AC");               -- set attack
        apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0004", x"340D");               -- set decay
        apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0006", x"0005");               -- set hold cycles

        wait until rising_edge(clk_i);

        apb_read(clk_i, 0, s_apb_i, s_apb_o, X"0001", apb_out);                -- read RSSI
        check_equal(signed(apb_out), x"0000", "RSSI out");

        apb_read(clk_i, 0, s_apb_i, s_apb_o, X"0002", apb_out);                -- read attack
        check_equal(signed(apb_out), x"02AC", "attack out");

        apb_read(clk_i, 0, s_apb_i, s_apb_o, X"0004", apb_out);                -- read decay
        check_equal(signed(apb_out), x"340D", "decay out");

        apb_read(clk_i, 0, s_apb_i, s_apb_o, X"0006", apb_out);                -- read hold cycles
        check_equal(signed(apb_out), x"0005", "hold cycles out");

      elsif run("test_calculation") then
        tstrb_out := X"F";
        rst_i <= '0';
        wait for 100 ns;
        rst_i <= '1';

        wait until rising_edge(clk_i);

        apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0001", "0000000000000000");    -- enable block
        apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0002", x"2000");               -- set attack to 8192
        apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0004", x"2000");               -- set decay to 8192
        apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0006", x"0005");               -- set hold cycles to 5

        wait until rising_edge(clk_i);

        push_axi_stream(net, master_axi_stream, x"04E912CC", tstrb => tstrb_out, tlast => '0');

        for i in 0 to 3 loop
          wait until rising_edge(clk_i);
        end loop;

        apb_read(clk_i, 0, s_apb_i, s_apb_o, X"0001", apb_out);    -- read RSSI


        check_equal(signed(apb_out), 5100, "apb out"); -- 15*x"12CC"/16 + 15*x"04E9"/32 = 5100  (real magnitude = 4973)

      end if;
    end loop;

    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  tb_APFM_demodulator_inst : entity work.RSSI_estimator
  generic map (
    PSEL_ID => 0
  )
  port map (
    clk_i => clk_i,
    nrst_i => rst_i,
    s_apb_i => s_apb_i,
    s_apb_o => s_apb_o,
    s_axis_i => s_axis_i,
    s_axis_o => s_axis_o
  );

  axi_stream_master_bfm: entity vunit_lib.axi_stream_master
    generic map (
      master => master_axi_stream)
    port map (
      aclk   => clk_i,
      areset_n => rst_i,
      tvalid => s_axis_i.tvalid,
      tready => s_axis_o.tready,
      tdata  => s_axis_i.tdata,
      tstrb => s_axis_i.tstrb);

  s_axis_o.tready <= '1';

end architecture;
