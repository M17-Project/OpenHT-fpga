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
use vunit_lib.stream_slave_pkg.all;

use work.axi_stream_pkg.all;
use work.openht_utils_pkg.all;

entity tb_mod_interpolator is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_mod_interpolator is
  signal clk_i : std_logic;
  signal rst_i : std_logic;

  signal s_axis_mod_i : axis_in_mod_t;
  signal s_axis_mod_o : axis_out_mod_t;

  signal m_axis_mod_i : axis_out_mod_t;
  signal m_axis_mod_o : axis_in_mod_t;

  constant master_stall_config : stall_config_t := new_stall_config(stall_probability => 0.2, min_stall_cycles => 2, max_stall_cycles => 10);
  constant master_axi_stream : axi_stream_master_t := new_axi_stream_master(data_length => 16,
    stall_config => master_stall_config);

  constant slave_stall_config : stall_config_t := new_stall_config(stall_probability => 0.2, min_stall_cycles => 2, max_stall_cycles => 10);
  constant slave_axi_stream : axi_stream_slave_t := new_axi_stream_slave(
    data_length => 16);

  constant INTERP_TAPS : taps_mod_t(0 to 404) := (
	x"0014", x"000C", x"0000", x"FFF4", x"FFEC", 
	x"FFEC", x"FFF3", x"0000", x"000D", x"0016", 
	x"0016", x"000E", x"0000", x"FFF2", x"FFE8", 
	x"FFE7", x"FFF0", x"0000", x"0010", x"001B", 
	x"001C", x"0012", x"0000", x"FFED", x"FFE1", 
	x"FFE0", x"FFEC", x"0000", x"0016", x"0024", 
	x"0025", x"0018", x"0000", x"FFE7", x"FFD6", 
	x"FFD4", x"FFE4", x"0000", x"001E", x"0031", 
	x"0033", x"0020", x"0000", x"FFDD", x"FFC6", 
	x"FFC5", x"FFDA", x"0000", x"0028", x"0043", 
	x"0045", x"002C", x"0000", x"FFD1", x"FFB2", 
	x"FFB0", x"FFCD", x"0000", x"0036", x"005A", 
	x"005D", x"003B", x"0000", x"FFC1", x"FF98", 
	x"FF95", x"FFBC", x"0000", x"0048", x"0077", 
	x"007B", x"004E", x"0000", x"FFAE", x"FF77", 
	x"FF74", x"FFA7", x"0000", x"005E", x"009C", 
	x"00A0", x"0065", x"0000", x"FF96", x"FF50", 
	x"FF4B", x"FF8D", x"0000", x"0078", x"00C8", 
	x"00CC", x"0081", x"0000", x"FF78", x"FF1F", 
	x"FF1A", x"FF6E", x"0000", x"0099", x"00FD", 
	x"0103", x"00A4", x"0000", x"FF54", x"FEE4", 
	x"FEDD", x"FF48", x"0000", x"00C0", x"013E", 
	x"0146", x"00CE", x"0000", x"FF29", x"FE9C", 
	x"FE93", x"FF1A", x"0000", x"00F1", x"018F", 
	x"0198", x"0102", x"0000", x"FEF3", x"FE42", 
	x"FE38", x"FEE0", x"0000", x"012D", x"01F3", 
	x"01FE", x"0142", x"0000", x"FEAF", x"FDD1", 
	x"FDC4", x"FE97", x"0000", x"017B", x"0273", 
	x"0282", x"0196", x"0000", x"FE56", x"FD3E", 
	x"FD2D", x"FE36", x"0000", x"01E1", x"031E", 
	x"0332", x"0207", x"0000", x"FDDE", x"FC75", 
	x"FC5D", x"FDB1", x"0000", x"0271", x"040F", 
	x"042D", x"02A8", x"0000", x"FD2E", x"FB4D", 
	x"FB27", x"FCE8", x"0000", x"034D", x"0586", 
	x"05B7", x"03A9", x"0000", x"FC10", x"F961", 
	x"F91C", x"FB91", x"0000", x"04D5", x"082E", 
	x"0892", x"0590", x"0000", x"F9D3", x"F56E", 
	x"F4C9", x"F89F", x"0000", x"0876", x"0EC4", 
	x"1004", x"0AD0", x"0000", x"F2C1", x"E7DE", 
	x"E466", x"EC15", x"0000", x"1DE9", x"408D", 
	x"60DA", x"77BC", x"7FFF", x"77BC", x"60DA", 
	x"408D", x"1DE9", x"0000", x"EC15", x"E466", 
	x"E7DE", x"F2C1", x"0000", x"0AD0", x"1004", 
	x"0EC4", x"0876", x"0000", x"F89F", x"F4C9", 
	x"F56E", x"F9D3", x"0000", x"0590", x"0892", 
	x"082E", x"04D5", x"0000", x"FB91", x"F91C", 
	x"F961", x"FC10", x"0000", x"03A9", x"05B7", 
	x"0586", x"034D", x"0000", x"FCE8", x"FB27", 
	x"FB4D", x"FD2E", x"0000", x"02A8", x"042D", 
	x"040F", x"0271", x"0000", x"FDB1", x"FC5D", 
	x"FC75", x"FDDE", x"0000", x"0207", x"0332", 
	x"031E", x"01E1", x"0000", x"FE36", x"FD2D", 
	x"FD3E", x"FE56", x"0000", x"0196", x"0282", 
	x"0273", x"017B", x"0000", x"FE97", x"FDC4", 
	x"FDD1", x"FEAF", x"0000", x"0142", x"01FE", 
	x"01F3", x"012D", x"0000", x"FEE0", x"FE38", 
	x"FE42", x"FEF3", x"0000", x"0102", x"0198", 
	x"018F", x"00F1", x"0000", x"FF1A", x"FE93", 
	x"FE9C", x"FF29", x"0000", x"00CE", x"0146", 
	x"013E", x"00C0", x"0000", x"FF48", x"FEDD", 
	x"FEE4", x"FF54", x"0000", x"00A4", x"0103", 
	x"00FD", x"0099", x"0000", x"FF6E", x"FF1A", 
	x"FF1F", x"FF78", x"0000", x"0081", x"00CC", 
	x"00C8", x"0078", x"0000", x"FF8D", x"FF4B", 
	x"FF50", x"FF96", x"0000", x"0065", x"00A0", 
	x"009C", x"005E", x"0000", x"FFA7", x"FF74", 
	x"FF77", x"FFAE", x"0000", x"004E", x"007B", 
	x"0077", x"0048", x"0000", x"FFBC", x"FF95", 
	x"FF98", x"FFC1", x"0000", x"003B", x"005D", 
	x"005A", x"0036", x"0000", x"FFCD", x"FFB0", 
	x"FFB2", x"FFD1", x"0000", x"002C", x"0045", 
	x"0043", x"0028", x"0000", x"FFDA", x"FFC5", 
	x"FFC6", x"FFDD", x"0000", x"0020", x"0033", 
	x"0031", x"001E", x"0000", x"FFE4", x"FFD4", 
	x"FFD6", x"FFE7", x"0000", x"0018", x"0025", 
	x"0024", x"0016", x"0000", x"FFEC", x"FFE0", 
	x"FFE1", x"FFED", x"0000", x"0012", x"001C", 
	x"001B", x"0010", x"0000", x"FFF0", x"FFE7", 
	x"FFE8", x"FFF2", x"0000", x"000E", x"0016", 
	x"0016", x"000D", x"0000", x"FFF3", x"FFEC", 
	x"FFEC", x"FFF4", x"0000", x"000C", x"0014"
  );

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
    variable data_in : std_logic_vector(15 downto 0);

  begin
    test_runner_setup(runner, runner_cfg);
    rst_i <= '0';
    wait for 100 ns;
    rst_i <= '1';

    for loop_var in 0 to 200 loop
        push_axi_stream(net, master_axi_stream, x"1000", tlast => '0');
        pop_axi_stream(net, slave_axi_stream, data_in, tlast_in);
    end loop;
    wait for 10 us;

    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  mod_interpolator_inst : entity work.mod_interpolator
  generic map (
    N_TAPS => 405,
    L => 5,
    C_TAPS => INTERP_TAPS
  )
  port map (
    clk_i => clk_i,
    s_axis_mod_i => s_axis_mod_i,
    s_axis_mod_o => s_axis_mod_o,
    m_axis_mod_o => m_axis_mod_o,
    m_axis_mod_i => m_axis_mod_i
  );

  axi_stream_master_bfm: entity vunit_lib.axi_stream_master
    generic map (
      master => master_axi_stream)
    port map (
      aclk   => clk_i,
      areset_n => rst_i,
      tvalid => s_axis_mod_i.tvalid,
      tready => s_axis_mod_o.tready,
      tlast => s_axis_mod_i.tlast,
      tdata  => s_axis_mod_i.tdata);

      axi_stream_slave_inst : entity vunit_lib.axi_stream_slave
      generic map(
        slave => slave_axi_stream)
      port map(
        aclk     => clk_i,
        areset_n => rst_i,
        tvalid   => m_axis_mod_o.tvalid,
        tready   => m_axis_mod_i.tready,
        tdata    => m_axis_mod_o.tdata,
        tlast    => m_axis_mod_o.tlast);

end architecture;
