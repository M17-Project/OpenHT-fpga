-----------------------------------------
-- FIR rational resampler testbench
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

library osvvm;
use osvvm.RandomPkg.all;

use work.axi_stream_pkg.all;
use work.openht_utils_pkg.all;
use work.apb_pkg.all;
use work.apb_test_pkg.all;

entity tb_fir_rational_resample is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_fir_rational_resample is
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
    
    variable acc_i : accum_t;
    variable acc_q : accum_t;
    variable subfilter : natural;

  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
        if run("test_real") then
            tstrb_out := X"C";
            rst_i <= '0';
            wait for 100 ns;
            rst_i <= '1';

            wait until rising_edge(clk_i);
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0004", X"0001");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0006", X"0001");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0002", X"03FF");
            for i in 0 to 513 loop
                apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", std_logic_vector(to_unsigned((i * 4) + 1, 16)));
            end loop;

            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000C", X"0017");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0000", X"0001");
            wait for 100 ns;

            acc_i(0) := (others => '0');
            for i in 0 to 513 loop
                acc_i(0) := acc_i(0) + (i*4) + 1;
                push_axi_stream(net, master_axi_stream, x"00010000", tstrb => tstrb_out, tlast => '0');
                pop_axi_stream(net, slave_axi_stream, data_in, tlast_in, tkeep_in, tstrb_in, tid_in, tdest_in, tuser_in);
                check_equal(signed(data_in(31 downto 16)), acc_i(0)(18 downto 3));
            end loop;
            wait for 100 ns;

        elsif run("test_duplicate_real") then
            tstrb_out := X"C";
            rst_i <= '0';
            wait for 100 ns;
            rst_i <= '1';

            wait until rising_edge(clk_i);
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0004", X"0001");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0006", X"0001");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0002", X"007F");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0008", X"0000");
            for i in 0 to 127 loop
                apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", std_logic_vector(to_unsigned((i * 5) + 1, 16)));
            end loop;
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0008", X"0200");
            for i in 0 to 127 loop
                apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", std_logic_vector(to_unsigned((i * 3) + 1, 16)));
            end loop;

            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000C", X"0017");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000E", X"0017");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0000", X"0003");
            wait for 100 ns;

            acc_i(0) := (others => '0');
            acc_q(0) := (others => '0');
            for i in 0 to 127 loop
                acc_i(0) := acc_i(0) + (i*5) + 1;
                acc_q(0) := acc_q(0) + (i*3) + 1;
                push_axi_stream(net, master_axi_stream, x"00010000", tstrb => tstrb_out, tlast => '0');
                pop_axi_stream(net, slave_axi_stream, data_in, tlast_in, tkeep_in, tstrb_in, tid_in, tdest_in, tuser_in);
                check_equal(signed(data_in(31 downto 16)), acc_i(0)(18 downto 3));
                check_equal(signed(data_in(15 downto 0)), acc_q(0)(18 downto 3));
            end loop;
            wait for 100 ns;

        elsif run("test_iq") then
            tstrb_out := X"F";
            rst_i <= '0';
            wait for 100 ns;
            rst_i <= '1';

            wait until rising_edge(clk_i);
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0004", X"0001");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0006", X"0001");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0002", X"007F");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0008", X"0000");
            for i in 0 to 127 loop
                apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", std_logic_vector(to_unsigned((i * 5) + 1, 16)));
            end loop;
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0008", X"0200");
            for i in 0 to 127 loop
                apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", std_logic_vector(to_unsigned((i * 3) + 1, 16)));
            end loop;

            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000C", X"0014");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000E", X"0014");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0000", X"0001");
            wait for 100 ns;

            acc_i(0) := (others => '0');
            acc_q(0) := (others => '0');
            for i in 0 to 127 loop
                acc_i(0) := acc_i(0) + ((i*5) + 1) * 2;
                acc_q(0) := acc_q(0) + ((i*3) + 1) * 5;
                push_axi_stream(net, master_axi_stream, x"00020005", tstrb => tstrb_out, tlast => '0');
                pop_axi_stream(net, slave_axi_stream, data_in, tlast_in, tkeep_in, tstrb_in, tid_in, tdest_in, tuser_in);
                check_equal(signed(data_in(31 downto 16)), acc_i(0)(21 downto 6));
                check_equal(signed(data_in(15 downto 0)), acc_q(0)(21 downto 6));
            end loop;
            wait for 100 ns;

        elsif run("test_iq_interpolate") then
            tstrb_out := X"F";
            rst_i <= '0';
            wait for 100 ns;
            rst_i <= '1';

            wait until rising_edge(clk_i);
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0004", X"0004");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0006", X"0001");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0002", X"007F");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0008", X"0000");
            for i in 0 to 127 loop
                apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", std_logic_vector(to_unsigned((i * 4), 16)));
            end loop;
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0008", X"0200");
            for i in 0 to 127 loop
                apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", std_logic_vector(to_unsigned((i * 8), 16)));
            end loop;

            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000C", X"0014");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000E", X"0014");
            apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0000", X"0001");
            wait for 100 ns;
            
            acc_i := (others => (others => '0'));
            acc_q := (others => (others => '0'));
            for i in 0 to 31 loop
                push_axi_stream(net, master_axi_stream, x"00020005", tstrb => tstrb_out, tlast => '0');
                for k in 0 to 3 loop
                    acc_i(k) := acc_i(k) + ((i*4+k)*4) * 2;
                    acc_q(k) := acc_q(k) + ((i*4+k)*8) * 5;
                    pop_axi_stream(net, slave_axi_stream, data_in, tlast_in, tkeep_in, tstrb_in, tid_in, tdest_in, tuser_in);
                    check_equal(signed(data_in(31 downto 16)), acc_i(k)(21 downto 6));
                    check_equal(signed(data_in(15 downto 0)), acc_q(k)(21 downto 6));
                end loop;
            end loop;
            wait for 100 ns;

          elsif run("test_bypass") then
            for i in 0 to 1023 loop
              tstrb_out := rv.RandSlv(4);
              data_out := rv.RandSlv(32);
              push_axi_stream(net, master_axi_stream, data_out, tstrb => tstrb_out, tlast => '0');
              pop_axi_stream(net, slave_axi_stream, data_in, tlast_in, tkeep_in, tstrb_in, tid_in, tdest_in, tuser_in);
              --check_equal(tstrb_in, tstrb_out);
              check_equal(data_in, data_out);
            end loop;      
        end if;
      -- rst_i <= '0';
      -- wait for 100 ns;
      --   rst_i <= '1';

      --   set_timeout(runner, 150 us);

      --   wait until rising_edge(clk_i);
      --   apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0004", X"0001");
      --   apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0006", X"0001");
      --   apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0002", X"000F");
      --   for i in 0 to 15 loop
      --     apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", std_logic_vector(to_unsigned(i * 256, 16)));
      --   end loop;
      --   apb_write(clk_i, 0, s_apb_i, s_apb_o, X"0000", X"0001");
      --   apb_write(clk_i, 0, s_apb_i, s_apb_o, X"000A", X"0100");

      --   wait for 100 ns;

      --   for m in 1 to 2 loop
      --     for iterations in 1 to 10 loop
      --       for l in 1 to 4 loop
      --         for k in 1 to iterations loop
      --           push_axi_stream(net, master_axi_stream, x"7FFF0000", tstrb => tstrb_out, tlast => '0');
      --         end loop;
      --           for k in 1 to iterations loop
      --             push_axi_stream(net, master_axi_stream, x"80010000", tstrb => tstrb_out, tlast => '0');
      --           end loop;
      --           end loop;
      --           end loop;
      --           end loop;

      --             for loop_var in 0 to 4000 loop
      --               pop_axi_stream(net, slave_axi_stream, data_in, tlast_in, tkeep_in, tstrb_in, tid_in, tdest_in, tuser_in);
      --             end loop;
      --   wait for 20 us;
    end loop;

        test_runner_cleanup(runner); -- Simulation ends here
  end process;

  fir_rational_resample_inst : entity work.fir_rational_resample
  generic map (
    PSEL_ID => 0
  )
  port map (
    clk_i => clk_i,
    s_apb_i => s_apb_i,
    s_apb_o => s_apb_o,
    s_axis_i => s_axis_i,
    s_axis_o => s_axis_o,
    m_axis_o => m_axis_o,
    m_axis_i => m_axis_i
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

  axi_stream_slave_inst : entity vunit_lib.axi_stream_slave
  generic map(
    slave => slave_axi_stream)
  port map(
    aclk     => clk_i,
    areset_n => rst_i,
    tvalid   => m_axis_o.tvalid,
    tready   => m_axis_i.tready,
    tdata    => m_axis_o.tdata);

  axi_stream_protocol_checker_inst : entity vunit_lib.axi_stream_protocol_checker
  generic map(
    protocol_checker => protocol_checker)
  port map(
    aclk     => clk_i,
    areset_n => rst_i,
    tvalid   => m_axis_o.tvalid,
    tready   => m_axis_i.tready,
    tdata    => m_axis_o.tdata
  );

end architecture;
