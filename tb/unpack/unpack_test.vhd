--unpack test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity unpack_test is
	--
end unpack_test;

architecture sim of unpack_test is
	component unpack is
		port(
            clk_i	: in std_logic;
            i_i		: in std_logic_vector(15 downto 0);						-- 16-bit signed, sign at the MSB
            q_i		: in std_logic_vector(15 downto 0);						-- 16-bit signed, sign at the MSB
            req_o	: out std_logic := '0';									-- data request
            data_o	: out std_logic_vector(1 downto 0) := (others => '0')	-- dibit data out for DDR
		);
	end component;

	signal clk_i : std_logic := '0';
	signal i_i, q_i : std_logic_vector(15 downto 0) := (others => '1');
	signal req_o : std_logic := '0';
	signal data_o : std_logic_vector(1 downto 0) := (others => '0');
begin
	dut: unpack port map(
		clk_i => clk_i,
		i_i => i_i,
		q_i => q_i,
		req_o => req_o,
		data_o => data_o
	);

	--process
	--begin
		--
	--end process;

	process
	begin
		wait for 0.05 ms;
		clk_i <= not clk_i;
	end process;
end sim;
