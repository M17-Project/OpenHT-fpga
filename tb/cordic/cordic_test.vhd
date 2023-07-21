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
            clk_i           : in std_logic;     -- clock in
            phase_i         : in unsigned;      -- phase word in
            phase_valid_i   : in std_logic;     -- phase input valid?
            sin_o           : out signed;       -- sine out
            cos_o           : out signed;       -- cosine out
            valid_o         : out std_logic     -- data outp valid?
		);
	end component;

	signal clk_i, valid_o : std_logic := '0';
	signal phase_r : unsigned(23 downto 0) := (others => '0');
	signal phase_i : unsigned(15 downto 0) := (others => '0');
	signal sin_r, cos_r : signed(23 downto 0) := (others => '0');
	signal sin_o, cos_o : signed(15 downto 0) := (others => '0');
begin
	dut: cordic generic map(
        RES_WIDTH => 24,
        ITER_NUM => 20,
        COMP_COEFF => 24x"4DBA74" -- 16x"4DB9"
	)
	port map(
        clk_i => clk_i,
        phase_i => phase_r,
        phase_valid_i => '1',
        sin_o => sin_r,
        cos_o => cos_r,
        valid_o => valid_o
	);
	sin_o <= sin_r(23 downto 23-16+1);
	cos_o <= cos_r(23 downto 23-16+1);
	phase_r <= phase_i & x"00";

	process
	begin
        wait for 4.4 ms;
		phase_i <= phase_i + 1;
		assert abs(real(to_integer(sin_o)) - (sin(real(to_integer(phase_i))/real(16#8000#)*math_pi) * real(16#7FFF#))) < real(1.15) -- LSBs
            report "Fuckup!" & lf &
                "phase=" & integer'image(to_integer(phase_i)) & lf &
                "sin_calc=" & real'image(real(to_integer(sin_o))) & lf &
                "sin_true=" & real'image(sin(real(to_integer(phase_i))/real(16#8000#)*math_pi) * real(16#7FFF#))
            severity failure;
	end process;

	process
	begin
		wait for 0.1 ms;
		clk_i <= not clk_i;
	end process;
end sim;
