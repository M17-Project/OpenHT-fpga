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

entity tb_axis_mod_fifo_if is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_axis_mod_fifo_if is
  signal clk_i : std_logic;
  signal rst_i : std_logic;

  constant g_WIDTH : natural := 16;
  constant g_DEPTH : integer := 32;
  constant g_AE_THRESH : integer := g_DEPTH/2-1;
  signal i_wr_en : std_logic := '0';
  signal i_wr_data : std_logic_vector(g_WIDTH-1 downto 0);
  signal o_full : std_logic;
  signal i_rd_en : std_logic := '0';
  signal o_rd_data : std_logic_vector(g_WIDTH-1 downto 0);
  signal o_ae : std_logic;
  signal o_empty : std_logic;

  signal m_axis_mod_i : axis_out_mod_t;
  signal m_axis_mod_o : axis_in_mod_t;

  constant slave_stall_config : stall_config_t := new_stall_config(stall_probability => 0.2, min_stall_cycles => 2, max_stall_cycles => 10);
  constant slave_axi_stream : axi_stream_slave_t := new_axi_stream_slave(
    data_length => 16);

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
	wait for 100 ns;

	for k in 1 to 20 loop
		wait until rising_edge(clk_i);
		for i in 0 to 30 loop
			i_wr_en <= '1';
			i_wr_data <= std_logic_vector(to_unsigned(4*(k+i+1), 16));
			wait until rising_edge(clk_i);
		end loop;
		i_wr_en <= '0';

		for loop_var in 0 to 30 loop
			pop_axi_stream(net, slave_axi_stream, data_in, tlast_in);
			check(to_integer(unsigned(data_in)) = 4*(k+loop_var+1));
		end loop;
		wait for 1 us;
	end loop;

    test_runner_cleanup(runner); -- Simulation ends here
  end process;

  fifo_simple_inst : entity work.fifo_simple
  generic map (
    g_WIDTH => g_WIDTH,
    g_DEPTH => g_DEPTH,
    g_AE_THRESH => g_AE_THRESH
  )
  port map (
    i_rstn_async => rst_i,
    i_clk => clk_i,
    i_wr_en => i_wr_en,
    i_wr_data => i_wr_data,
    o_full => o_full,
    i_rd_en => i_rd_en,
    o_rd_data => o_rd_data,
    o_ae => o_ae,
    o_empty => o_empty
  );

  axis_mod_fifo_if_inst : entity work.axis_mod_fifo_if
  generic map (
    G_DATA_SIZE => 16
  )
  port map (
    clk => clk_i,
    nrst => rst_i,
    fifo_rd_en => i_rd_en,
    fifo_rd_data => o_rd_data,
    fifo_ae => o_ae,
    fifo_empty => o_empty,
    m_axis_mod_o => m_axis_mod_o,
    m_axis_mod_i => m_axis_mod_i
  );

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
