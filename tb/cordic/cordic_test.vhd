--cordic test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity cordic_test is
	--
end cordic_test;

architecture sim of cordic_test is
	component cordic is
        generic(
            RES_WIDTH   : natural;
            ITER_NUM    : natural;
            COMP_COEFF  : signed
        );
		port(
            clk_i       : in std_logic;    -- clock in
            phase_i     : in unsigned;     -- phase word in
            sin_o       : out signed;      -- sine out
            cos_o       : out signed;      -- cosine out
            trig_o      : out std_logic    -- data ready
		);
	end component;

	signal clk_i, trig_o : std_logic := '0';
	signal phase_i : unsigned(15 downto 0) := (others => '0');
	signal sin_o, cos_o : signed(15 downto 0) := (others => '0');
begin
	dut: cordic generic map(
        RES_WIDTH => 16,
        ITER_NUM => 20,
        COMP_COEFF => x"4DB9"
	)
	port map(
        clk_i => clk_i,
        phase_i => phase_i,
        sin_o => sin_o,
        cos_o => cos_o,
        trig_o => trig_o
	);

	process
	begin
        wait for 4400 us;
		phase_i <= phase_i + 16#2000#;--to_unsigned(integer(round(real(1)/real(360)*real(16#10000#))), 16);
	end process;

	process
	begin
		wait for 0.1 ms;
		clk_i <= not clk_i;
	end process;
end sim;
