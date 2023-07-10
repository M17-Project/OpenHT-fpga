--sincos_lut test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity sincos_lut_test is
	--
end sincos_lut_test;

architecture sim of sincos_lut_test is
	component sincos_lut is
        generic(
            LUT_SIZE    : natural;
            WORD_SIZE   : natural
        );
        port(
            clk_i		: in std_logic;
            theta_i		: in  std_logic_vector;
            sine_o		: out std_logic_vector;
            cosine_o	: out std_logic_vector
        );
	end component;

	signal theta_i : std_logic_vector(9 downto 0) := (others => '0');
	signal sine_o, cosine_o : std_logic_vector(15 downto 0) := (others => '0');
	signal clk : std_logic := '0';
begin
	dut: sincos_lut generic map(
        LUT_SIZE => 256*4,
        WORD_SIZE => 16
	)
	port map(
        clk_i => clk,
		theta_i	=> theta_i,
		sine_o => sine_o,
		cosine_o => cosine_o
	);

	process
	begin
		wait for 0.1 ms;
		theta_i <= std_logic_vector(unsigned(theta_i)+1);
	end process;

	process
	begin
		wait for 0.01 ms;
		clk <= not clk;
	end process;
end sim;
