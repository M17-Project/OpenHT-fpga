-------------------------------------------------------------
-- Flexible, signed sine/cosine look up table
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity sincos_lut is
    generic(
        LUT_SIZE    : natural;
        WORD_SIZE   : natural
    );
    port(
		clk_i		: in std_logic;
        theta_i		: in  std_logic_vector(integer(ceil(log2(real(LUT_SIZE))))-1 downto 0);
        sine_o		: out std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');
		cosine_o	: out std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0')
    );
end entity;

architecture magic of sincos_lut is
	type lut_arr is array (integer range 0 to LUT_SIZE/4) of std_logic_vector (WORD_SIZE-1 downto 0);
	signal sinlut : lut_arr;
	--constant sinlut : lut_arr := (
	    --x"0000", x"00C9", x"0192", x"025B",
        --x"0324", x"03ED", x"04B6", x"057F",
        --x"0648", x"0711", x"07D9", x"08A2",
        --x"096A", x"0A33", x"0AFB", x"0BC4",
        --x"0C8C", x"0D54", x"0E1C", x"0EE3",
        --x"0FAB", x"1072", x"113A", x"1201",
        --x"12C8", x"138F", x"1455", x"151C",
        --x"15E2", x"16A8", x"176E", x"1833",
        --x"18F9", x"19BE", x"1A82", x"1B47",
        --x"1C0B", x"1CCF", x"1D93", x"1E57",
        --x"1F1A", x"1FDD", x"209F", x"2161",
        --x"2223", x"22E5", x"23A6", x"2467",
        --x"2528", x"25E8", x"26A8", x"2767",
        --x"2826", x"28E5", x"29A3", x"2A61",
        --x"2B1F", x"2BDC", x"2C99", x"2D55",
        --x"2E11", x"2ECC", x"2F87", x"3041",
        --x"30FB", x"31B5", x"326E", x"3326",
        --x"33DF", x"3496", x"354D", x"3604",
        --x"36BA", x"376F", x"3824", x"38D9",
        --x"398C", x"3A40", x"3AF2", x"3BA5",
        --x"3C56", x"3D07", x"3DB8", x"3E68",
        --x"3F17", x"3FC5", x"4073", x"4121",
        --x"41CE", x"427A", x"4325", x"43D0",
        --x"447A", x"4524", x"45CD", x"4675",
        --x"471C", x"47C3", x"4869", x"490F",
        --x"49B4", x"4A58", x"4AFB", x"4B9D",
        --x"4C3F", x"4CE0", x"4D81", x"4E20",
        --x"4EBF", x"4F5D", x"4FFB", x"5097",
        --x"5133", x"51CE", x"5268", x"5302",
        --x"539B", x"5432", x"54C9", x"5560",
        --x"55F5", x"568A", x"571D", x"57B0",
        --x"5842", x"58D3", x"5964", x"59F3",
        --x"5A82", x"5B0F", x"5B9C", x"5C28",
        --x"5CB3", x"5D3E", x"5DC7", x"5E4F",
        --x"5ED7", x"5F5D", x"5FE3", x"6068",
        --x"60EB", x"616E", x"61F0", x"6271",
        --x"62F1", x"6370", x"63EE", x"646C",
        --x"64E8", x"6563", x"65DD", x"6656",
        --x"66CF", x"6746", x"67BC", x"6832",
        --x"68A6", x"6919", x"698B", x"69FD",
        --x"6A6D", x"6ADC", x"6B4A", x"6BB7",
        --x"6C23", x"6C8E", x"6CF8", x"6D61",
        --x"6DC9", x"6E30", x"6E96", x"6EFB",
        --x"6F5E", x"6FC1", x"7022", x"7083",
        --x"70E2", x"7140", x"719D", x"71F9",
        --x"7254", x"72AE", x"7307", x"735E",
        --x"73B5", x"740A", x"745F", x"74B2",
        --x"7504", x"7555", x"75A5", x"75F3",
        --x"7641", x"768D", x"76D8", x"7722",
        --x"776B", x"77B3", x"77FA", x"783F",
        --x"7884", x"78C7", x"7909", x"794A",
        --x"7989", x"79C8", x"7A05", x"7A41",
        --x"7A7C", x"7AB6", x"7AEE", x"7B26",
        --x"7B5C", x"7B91", x"7BC5", x"7BF8",
        --x"7C29", x"7C59", x"7C88", x"7CB6",
        --x"7CE3", x"7D0E", x"7D39", x"7D62",
        --x"7D89", x"7DB0", x"7DD5", x"7DFA",
        --x"7E1D", x"7E3E", x"7E5F", x"7E7E",
        --x"7E9C", x"7EB9", x"7ED5", x"7EEF",
        --x"7F09", x"7F21", x"7F37", x"7F4D",
        --x"7F61", x"7F74", x"7F86", x"7F97",
        --x"7FA6", x"7FB4", x"7FC1", x"7FCD",
        --x"7FD8", x"7FE1", x"7FE9", x"7FF0",
        --x"7FF5", x"7FF9", x"7FFD", x"7FFE",
        --x"7FFF"
	--);
	constant offs : unsigned := to_unsigned(2**WORD_SIZE-1, WORD_SIZE);
begin
    generate_lut: for n in 0 to LUT_SIZE/4 generate
        sinlut(n) <= std_logic_vector(to_signed(integer(real(2**(WORD_SIZE-1)-1)*sin(real(n)/real(LUT_SIZE/4)*real(MATH_PI)/real(2))), 16));
	end generate generate_lut;

	-- synchronous
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if unsigned(theta_i)<=LUT_SIZE/4 then
				sine_o   <= sinlut(to_integer(unsigned(theta_i)));
				cosine_o <= sinlut(to_integer(LUT_SIZE/4-unsigned(theta_i)));
			elsif unsigned(theta_i)<=LUT_SIZE/2 then
				sine_o   <= sinlut(to_integer(LUT_SIZE/2-unsigned(theta_i)));
				cosine_o <= std_logic_vector(offs-unsigned(sinlut(to_integer(unsigned(theta_i)-LUT_SIZE/4)))-offs-1);
			elsif unsigned(theta_i)<=3*LUT_SIZE/4 then
				sine_o   <= std_logic_vector(offs-unsigned(sinlut(to_integer(unsigned(theta_i)-LUT_SIZE/2)))-offs-1);
				cosine_o <= std_logic_vector(offs-unsigned(sinlut(to_integer(3*LUT_SIZE/4-unsigned(theta_i))))-offs-1);
			else
				sine_o   <= std_logic_vector(offs-unsigned(sinlut(to_integer(LUT_SIZE-1-unsigned(theta_i)+1)))-offs-1);
				cosine_o <= std_logic_vector(unsigned(sinlut(to_integer(unsigned(theta_i)-3*LUT_SIZE/4))));
			end if;
		end if;
	end process;

	-- combinational
	--sine_o   <= sinlut(to_integer(unsigned(theta_i))) when unsigned(theta_i)<=LUT_SIZE/4 else
        --sinlut(to_integer(LUT_SIZE/2-unsigned(theta_i))) when unsigned(theta_i)<=LUT_SIZE/2 else
        --std_logic_vector(offs-unsigned(sinlut(to_integer(unsigned(theta_i)-LUT_SIZE/2)))-offs-1) when unsigned(theta_i)<=3*LUT_SIZE/4 else
        --std_logic_vector(offs-unsigned(sinlut(to_integer(LUT_SIZE-1-unsigned(theta_i)+1)))-offs-1);

    --cosine_o <= sinlut(to_integer(LUT_SIZE/4-unsigned(theta_i))) when unsigned(theta_i)<=LUT_SIZE/4 else
        --std_logic_vector(offs-unsigned(sinlut(to_integer(unsigned(theta_i)-LUT_SIZE/4)))-offs-1) when unsigned(theta_i)<=LUT_SIZE/2 else
        --std_logic_vector(offs-unsigned(sinlut(to_integer(3*LUT_SIZE/4-unsigned(theta_i))))-offs-1) when unsigned(theta_i)<=3*LUT_SIZE/4 else
        --std_logic_vector(unsigned(sinlut(to_integer(unsigned(theta_i)-3*LUT_SIZE/4))));
end architecture;
