-------------------------------------------------------------
-- 16QAM constellation map
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- February 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity qam_16 is
    port(
        data_i		: in  std_logic_vector(3 downto 0);
        i_o, q_o	: out std_logic_vector(15 downto 0)
    );
end entity;

architecture magic of qam_16 is
	type lut_arr is array(0 to 3) of std_logic_vector(15 downto 0);
	
	constant levels : lut_arr := (
        x"D2BF", x"F0EA", x"0F16", x"2D41"
	);
begin
	process(data_i)
	begin
		case data_i is
			when "0000" =>
				i_o <= levels(0);
				q_o <= levels(0);
			when "0001" =>
				i_o <= levels(0);
				q_o <= levels(1);
			when "0010" =>
				i_o <= levels(0);
				q_o <= levels(3);
			when "0011" =>
				i_o <= levels(0);
				q_o <= levels(2);
				
			when "0100" =>
				i_o <= levels(1);
				q_o <= levels(0);
			when "0101" =>
				i_o <= levels(1);
				q_o <= levels(1);
			when "0110" =>
				i_o <= levels(1);
				q_o <= levels(3);
			when "0111" =>
				i_o <= levels(1);
				q_o <= levels(2);
				
			when "1000" =>
				i_o <= levels(3);
				q_o <= levels(0);
			when "1001" =>
				i_o <= levels(3);
				q_o <= levels(1);
			when "1010" =>
				i_o <= levels(3);
				q_o <= levels(3);
			when "1011" =>
				i_o <= levels(3);
				q_o <= levels(2);
				
			when "1100" =>
				i_o <= levels(2);
				q_o <= levels(0);
			when "1101" =>
				i_o <= levels(2);
				q_o <= levels(1);
			when "1110" =>
				i_o <= levels(2);
				q_o <= levels(3);
			when "1111" =>
				i_o <= levels(2);
				q_o <= levels(2);
				
			when others =>
				i_o <= (others => '0'); -- should never happen
				q_o <= (others => '0');
		end case;
	end process;
end architecture;
