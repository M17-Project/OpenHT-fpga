-------------------------------------------------------------
-- RSSI estimator
--
--
-- Frédéric Druppel, ON4PFD, fredcorp.cc
-- Sebastien, ON4SEB
-- M17 Project
-- November 2023
--
-- TODO : Verify if ready can be trusted
--
-------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;
use work.apb_pkg.all;

entity RSSI_estimator is
  generic  (
    PSEL_ID : natural
  );
  port (
    clk_i    : in std_logic;            -- Clock, from upstream
    nrst_i   : in std_logic;            -- Reset, from upstream

    s_apb_o  : out apb_out_t;           -- slave apb interface out, to upstream
    s_apb_i  : in apb_in_t;             -- slave apb interface in, from upstream

    s_axis_o : out axis_out_iq_t;       -- slave out, to upstream entity (ready)                      -- This entity's ready to receive flag (tready)
    s_axis_i : in axis_in_iq_t          -- slave in, from upstream entity (data and valid)            -- IQ signal (tdata), valid (tvalid)
  );
end entity;

architecture magic of RSSI_estimator is
  signal I            : signed(15 downto 0) := (others => '0');
  signal Q            : signed(15 downto 0) := (others => '0');
  signal max          : signed(15 downto 0) := (others => '0');
  signal min          : signed(15 downto 0) := (others => '0');
  signal magnitude    : signed(15 downto 0) := (others => '0');
  signal magnitude_o  : signed(15 downto 0) := (others => '0');

  signal ready        : std_logic := '0';

  signal hold         : std_logic_vector(15 downto 0) := (others => '0');
  signal attack       : std_logic_vector(15 downto 0) := (others => '0');
  signal decay        : std_logic_vector(15 downto 0) := (others => '0');
  signal hold_config  : std_logic_vector(15 downto 0) := (others => '0');

begin

  -- APB
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      s_apb_o.pready <= '0';
      s_apb_o.prdata <= (others => '0');
      if s_apb_i.PSEL(PSEL_ID) then
        if s_apb_i.PENABLE and s_apb_i.PWRITE then
          case s_apb_i.PADDR is
            when "01" =>
              attack <= s_apb_i.PWDATA;
            when "10" =>
              decay <= s_apb_i.PWDATA;
            when "11" =>
              hold_config <= s_apb_i.PWDATA;
            when others =>
              null;
          end case;
        end if;

        if not s_apb_i.PENABLE then
          s_apb_o.pready <= '1';
          case s_apb_i.PADDR is
            when "00" =>
              s_apb_o.prdata <= magnitude_o;
            when "01" =>
              s_apb_o.prdata <= attack;
            when "10" =>
              s_apb_o.prdata <= decay;
            when others =>
              s_apb_o.prdata <= (others => '0');
          end case;
        end if;
      end if;
    end if;
  end process;

  -- RSSI calculation
  process(clk_i)
  begin
    if nrst_i = '0' then
      magnitude <= (others => '0');
    
    elsif rising_edge(clk_i) then
      ready <= '1';             -- Isn't the block always ready to receive new data ?
      if s_axis_i.tvalid then
        ready <= '0';           -- Isn't the block always ready to receive new data ?
        -- α*max(I,Q)+β*min(I,Q), with α=15/16 and β=15/32
        if I > Q then
          max <= I;
          min <= Q;
        else
          max <= Q;
          min <= I;
        end if;
        magnitude <= 15*max(15 downto 3) + 15*min(15 downto 4);
        if magnitude > magnitude_o then
          magnitude_o <= minimum(magnitude, magnitude_o+attack);
          hold <= hold_config;
        else
          if hold > 0 then
            hold <= hold-1;
          else
            magnitude_o <= magnitude_o-decay;
          end if;
        end if;
      end if;
    end if;
  end process;
  I <= abs(signed(s_axis_i.tdata(31 downto 16)));
  Q <= abs(signed(s_axis_i.tdata(15 downto 0)));

  -- AXI Stream
  s_axis_o.tready <= ready;     -- Isn't the block always ready to receive new data ?
end architecture;