-------------------------------------------------------------
-- RSSI estimator
--
--
-- Frédéric Druppel, ON4PFD, fredcorp.cc
-- Sebastien, ON4SEB
-- M17 Project
-- November 2023
--
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

    s_axis_o : in axis_out_iq_t;       -- slave out, to upstream entity (ready)                       -- This entity's ready to receive flag (tready)
    s_axis_i : in axis_in_iq_t          -- slave in, from upstream entity (data and valid)            -- IQ signal (tdata), valid (tvalid)
  );
end entity;

architecture magic of RSSI_estimator is
  signal I_0           : signed(15 downto 0) := (others => '0');
  signal Q_0           : signed(15 downto 0) := (others => '0');
  signal max_1         : signed(15 downto 0) := (others => '0');
  signal min_1         : signed(15 downto 0) := (others => '0');
  signal magnitude_2   : signed(15 downto 0) := (others => '0');
  signal magnitude_o_3 : signed(15 downto 0) := (others => '0');
  signal magnitude_rst : std_logic := '0';

  signal valid_1       : std_logic := '0';
  signal valid_2       : std_logic := '0';

  signal hold         : signed(15 downto 0) := (others => '0');
  signal attack       : signed(15 downto 0) := (others => '0');
  signal decay        : signed(15 downto 0) := (others => '0');
  signal hold_config  : signed(15 downto 0) := (others => '0');

begin

  -- APB
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      s_apb_o.pready <= '0';
      s_apb_o.prdata <= (others => '0');
      magnitude_rst <= '0';
      if s_apb_i.PSEL(PSEL_ID) then
        if s_apb_i.PENABLE and s_apb_i.PWRITE then
          case s_apb_i.PADDR(3 downto 1) is
            when "000" =>
              magnitude_rst <= s_apb_i.PWDATA(0);
            when "001" =>
              attack <= signed(s_apb_i.PWDATA);
            when "010" =>
              decay <= signed(s_apb_i.PWDATA);
            when "011" =>
              hold_config <= signed(s_apb_i.PWDATA);
            when others =>
              null;
          end case;
        end if;

        if not s_apb_i.PENABLE then
          s_apb_o.pready <= '1';
          case s_apb_i.PADDR(3 downto 1) is
            when "001" =>
              s_apb_o.prdata <= std_logic_vector(attack);
            when "010" =>
              s_apb_o.prdata <= std_logic_vector(decay);
            when "011" =>
              s_apb_o.prdata <= std_logic_vector(hold_config);
            when "100" =>
              s_apb_o.prdata <= std_logic_vector(magnitude_o_3);
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
      magnitude_2 <= (others => '0');
      magnitude_o_3 <= (others => '0');

    elsif rising_edge(clk_i) then
      valid_1 <= '0';
      if s_axis_i.tvalid and s_axis_o.tready then
        -- α*max(I,Q)+β*min(I,Q), with α=15/16 and β=15/32
        if I_0 > Q_0 then
          max_1 <= I_0;
          min_1 <= Q_0;
        else
          max_1 <= Q_0;
          min_1 <= I_0;
        end if;
        valid_1 <= '1';
      end if;

      valid_2 <= valid_1;
      magnitude_2 <= resize(15*max_1/16, 16) + resize(15*min_1/32, 16);

      if not magnitude_rst then
        if valid_2 then
          if magnitude_2 > magnitude_o_3 then
            magnitude_o_3 <= minimum(magnitude_2, magnitude_o_3 + attack);
            hold <= hold_config;
          else
            if hold > 0 then
              hold <= hold-1;
            else 
              magnitude_o_3 <= magnitude_o_3 - decay;
            end if;
          end if;
        end if;
      else
        magnitude_o_3 <= (others => '0');
        magnitude_2 <= (others => '0');
      end if;
    end if;
  end process;
  I_0 <= abs(signed(s_axis_i.tdata(31 downto 16)));
  Q_0 <= abs(signed(s_axis_i.tdata(15 downto 0)));
end architecture;