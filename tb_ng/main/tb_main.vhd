-----------------------------------------
-- toplevel testbench
--
-- Sebastien, ON4SEB
-----------------------------------------

-- Part of the testbench code inspired by
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License, please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/spi-fpga
-------------------------------------------

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
use work.apb_pkg.all;
use work.at86rf215_pkg.all;

--nse work.axi_stream_pkg.all;

entity tb_main is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_main is
  signal clk_i : std_logic;
  signal rst_i : std_logic;

  signal data_tx_o : std_logic_vector(1 downto 0);
  signal clk_rx09_i : std_logic;
  signal data_rx09_i : std_logic_vector(1 downto 0);
  signal clk_rx24_i : std_logic;
  signal data_rx24_i : std_logic_vector(1 downto 0);
  signal spi_ncs : std_logic;
  signal spi_miso : std_logic;
  signal spi_mosi : std_logic;
  signal spi_sck : std_logic;
  signal io0 : std_logic;
  signal io1 : std_logic;
  signal io2 : std_logic;
  signal io3 : std_logic;
  signal io4 : std_logic;
  signal io5 : std_logic;
  signal io6 : std_logic;

  constant rx_09_if : at86rf215_master_t := new_at86rf215_master;
  constant rx_09_if_stream : stream_master_t := as_stream(rx_09_if);
  constant rx_24_if : at86rf215_master_t := new_at86rf215_master;
  constant rx_24_if_stream : stream_master_t := as_stream(rx_24_if);

  function spi_write(increment : boolean; base : natural; offset: natural) return std_logic_vector is
    variable res : std_logic_vector(15 downto 0);
  begin
    res := X"8000";
    if increment then
      res := res or X"4000";
    end if;
    res(13 downto 13-APB_PSELID_BITS+1) := std_logic_vector(to_unsigned(base, APB_PSELID_BITS));
    res(13-APB_PSELID_BITS downto 0) := std_logic_vector(to_unsigned(offset, 14-APB_PSELID_BITS));
    return res;
  end function;

  function spi_read(increment : boolean; base : natural; offset: natural) return std_logic_vector is
    variable res : std_logic_vector(15 downto 0);
  begin
    res := X"0000";
    if increment then
      res := res or X"4000";
    end if;
    res(13 downto 13-APB_PSELID_BITS+1) := std_logic_vector(to_unsigned(base, APB_PSELID_BITS));
    res(13-APB_PSELID_BITS downto 0) := std_logic_vector(to_unsigned(offset, 14-APB_PSELID_BITS));
    return res;
  end function;

  COMPONENT PUR
  GENERIC (
          RST_PULSE : String := "1");
  PORT(
          PUR : IN std_logic := 'X');
  END COMPONENT;

  COMPONENT GSR
  GENERIC (
        SYNCMODE : String := "ASYNC");
  PORT(
        GSR_N : IN std_logic := 'X';
        CLK : IN std_logic := 'X');
  END COMPONENT;

  constant WORD_SIZE : positive := 16;
  constant SPI_PER : time := 82 ns;
  procedure SPI_MASTER (
    constant SPI_PER : time;
    constant SMM_MDI  : in  std_logic_vector(WORD_SIZE-1 downto 0);
    variable SMM_MDO  : out std_logic_vector(WORD_SIZE-1 downto 0);
    signal SMM_SCLK : out std_logic;
    signal SMM_CS_N : out std_logic;
    signal SMM_MOSI : out std_logic;
    signal SMM_MISO : in  std_logic;
    constant DEASSERT_CS : in boolean
) is
  constant DATA_OUT : std_logic_vector(WORD_SIZE-1 downto 0) := SMM_MDI(7 downto 0) & SMM_MDI(15 downto 8);
begin
    SMM_CS_N <= '0';
    for i in 0 to (WORD_SIZE-1) loop
        SMM_SCLK <= '0';
        SMM_MOSI <= DATA_OUT(WORD_SIZE-1-i);
        wait for SPI_PER/2;
        SMM_SCLK <= '1';
        SMM_MDO(WORD_SIZE-1-i) := SMM_MISO;
        wait for SPI_PER/2;
    end loop;
    SMM_SCLK <= '0';
    wait for SPI_PER/2;
    if DEASSERT_CS then
      SMM_CS_N <= '1';
    end if;
    wait for SPI_PER;
end procedure;


begin
  clk_p : process
  begin
    clk_i <= '0';
    wait for 8 ns;
    clk_i <= '1';
    wait for 8 ns;
  end process;

  main_all_inst : entity work.main_all
  port map (
    clk_i => clk_i,
    lock_i => '0',
    nrst => rst_i,
    data_tx_o => data_tx_o,
    clk_rx09_i => clk_rx09_i,
    data_rx09_i => data_rx09_i,
    clk_rx24_i => clk_rx24_i,
    data_rx24_i => data_rx24_i,
    spi_ncs => spi_ncs,
    spi_miso => spi_miso,
    spi_mosi => spi_mosi,
    spi_sck => spi_sck,
    io0 => io0,
    io1 => io1,
    io2 => io2,
    io3 => io3,
    io4 => io4,
    io5 => io5,
    io6 => io6
  );

  at86rf215_master_09_inst : entity work.at86rf215_master
  generic map (
    radio_if => rx_09_if
  )
  port map (
    ddr_clk => clk_rx09_i,
    ddr_data => data_rx09_i
  );

  at86rf215_master_24_inst : entity work.at86rf215_master
  generic map (
    radio_if => rx_24_if
  )
  port map (
    ddr_clk => clk_rx24_i,
    ddr_data => data_rx24_i
  );

  main : process
    variable rd_data : std_logic_vector(15 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_tx") then
          rst_i <= '0';
          spi_ncs <= '1';
          wait for 100 ns;
          rst_i <= '1';
          wait for 10 us;

          for i in 0 to 8 loop
              SPI_MASTER(SPI_PER, spi_read(false, i, 0), rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
              SPI_MASTER(SPI_PER, X"0001", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, true);
              wait for 10 us;
              wait until rising_edge(clk_i);
          end loop;

          for i in 0 to 8 loop
              SPI_MASTER(SPI_PER, spi_read(false, i, 0), rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
              SPI_MASTER(SPI_PER, X"5555", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
              SPI_MASTER(SPI_PER, X"FFFF", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
              SPI_MASTER(SPI_PER, X"5555", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
              SPI_MASTER(SPI_PER, X"FFFF", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
              SPI_MASTER(SPI_PER, X"0000", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, true);
              wait for 10 us;
              wait until rising_edge(clk_i);
          end loop;

          SPI_MASTER(SPI_PER, spi_write(false, 0, 4), rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
          for iterations in 1 to 4 loop
              for k in 1 to 2 loop
                SPI_MASTER(SPI_PER, X"7FFF", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
              end loop;
              for k in 1 to 2 loop
                SPI_MASTER(SPI_PER, X"8001", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, false);
              end loop;
          end loop;
          SPI_MASTER(SPI_PER, X"7FFF", rd_data, spi_sck, spi_ncs, spi_mosi, spi_miso, true);

          wait for 250 us;
      elsif run("test_rx") then
        rst_i <= '0';
        spi_ncs <= '1';
        wait for 100 ns;
        rst_i <= '1';
        wait for 10 us;

        push_stream(net, rx_09_if_stream, rf_iq(13x"0123", 13x"0456"));
        push_stream(net, rx_09_if_stream, rf_iq(13x"0555", 13x"0AAA"));
        push_stream(net, rx_09_if_stream, rf_iq(13x"0555", 13x"0AAA"));
        push_stream(net, rx_09_if_stream, rf_iq(13x"0555", 13x"0AAA"));

        wait for 250 us;
      end if;

    end loop;
    test_runner_cleanup(runner); -- Simulation ends here
  end process;

end architecture;
