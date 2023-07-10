-------------------------------------------------------------
-- Unsigned 12-bit, 1024-entry sine/cosine look up table
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- February 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sincos_lut is
    port(
        theta_i		:   in  std_logic_vector(9 downto 0);
        sine_o		:   out std_logic_vector(11 downto 0);
		cosine_o	:   out std_logic_vector(11 downto 0)
    );
end entity;

architecture magic of sincos_lut is
	type lut_arr is array (integer range 0 to 256) of std_logic_vector (11 downto 0);
	
	constant sinlut : lut_arr := (
        x"800", x"80C", x"819", x"825",
        x"832", x"83E", x"84B", x"857",
        x"864", x"871", x"87D", x"88A",
        x"896", x"8A3", x"8AF", x"8BC",
        x"8C8", x"8D5", x"8E1", x"8EE",
        x"8FA", x"907", x"913", x"91F",
        x"92C", x"938", x"945", x"951",
        x"95E", x"96A", x"976", x"983",
        x"98F", x"99B", x"9A8", x"9B4",
        x"9C0", x"9CC", x"9D9", x"9E5",
        x"9F1", x"9FD", x"A09", x"A15",
        x"A22", x"A2E", x"A3A", x"A46",
        x"A52", x"A5E", x"A6A", x"A76",
        x"A82", x"A8E", x"A9A", x"AA5",
        x"AB1", x"ABD", x"AC9", x"AD5",
        x"AE0", x"AEC", x"AF8", x"B03",
        x"B0F", x"B1B", x"B26", x"B32",
        x"B3D", x"B49", x"B54", x"B60",
        x"B6B", x"B76", x"B82", x"B8D",
        x"B98", x"BA3", x"BAE", x"BBA",
        x"BC5", x"BD0", x"BDB", x"BE6",
        x"BF1", x"BFC", x"C06", x"C11",
        x"C1C", x"C27", x"C32", x"C3C",
        x"C47", x"C52", x"C5C", x"C67",
        x"C71", x"C7B", x"C86", x"C90",
        x"C9A", x"CA5", x"CAF", x"CB9",
        x"CC3", x"CCD", x"CD7", x"CE1",
        x"CEB", x"CF5", x"CFF", x"D09",
        x"D12", x"D1C", x"D26", x"D2F",
        x"D39", x"D42", x"D4C", x"D55",
        x"D5F", x"D68", x"D71", x"D7A",
        x"D83", x"D8C", x"D95", x"D9E",
        x"DA7", x"DB0", x"DB9", x"DC2",
        x"DCA", x"DD3", x"DDC", x"DE4",
        x"DED", x"DF5", x"DFD", x"E06",
        x"E0E", x"E16", x"E1E", x"E26",
        x"E2E", x"E36", x"E3E", x"E46",
        x"E4E", x"E55", x"E5D", x"E65",
        x"E6C", x"E74", x"E7B", x"E82",
        x"E8A", x"E91", x"E98", x"E9F",
        x"EA6", x"EAD", x"EB4", x"EBB",
        x"EC1", x"EC8", x"ECF", x"ED5",
        x"EDC", x"EE2", x"EE8", x"EEF",
        x"EF5", x"EFB", x"F01", x"F07",
        x"F0D", x"F13", x"F19", x"F1F",
        x"F24", x"F2A", x"F30", x"F35",
        x"F3A", x"F40", x"F45", x"F4A",
        x"F4F", x"F54", x"F59", x"F5E",
        x"F63", x"F68", x"F6D", x"F71",
        x"F76", x"F7A", x"F7F", x"F83",
        x"F87", x"F8C", x"F90", x"F94",
        x"F98", x"F9C", x"F9F", x"FA3",
        x"FA7", x"FAA", x"FAE", x"FB1",
        x"FB5", x"FB8", x"FBB", x"FBF",
        x"FC2", x"FC5", x"FC8", x"FCA",
        x"FCD", x"FD0", x"FD3", x"FD5",
        x"FD8", x"FDA", x"FDC", x"FDF",
        x"FE1", x"FE3", x"FE5", x"FE7",
        x"FE9", x"FEB", x"FEC", x"FEE",
        x"FF0", x"FF1", x"FF3", x"FF4",
        x"FF5", x"FF6", x"FF7", x"FF8",
        x"FF9", x"FFA", x"FFB", x"FFC",
        x"FFD", x"FFD", x"FFE", x"FFE",
        x"FFE", x"FFF", x"FFF", x"FFF",
        x"FFF"
	);
begin
	process(theta_i)
	begin
		if unsigned(theta_i)<=256 then
			sine_o   <= sinlut(to_integer(unsigned(theta_i)));
			cosine_o <= sinlut(to_integer(256-unsigned(theta_i)));
		elsif unsigned(theta_i)<=512 then
			sine_o   <= sinlut(to_integer(512-unsigned(theta_i)));
			cosine_o <= std_logic_vector(16#800#-unsigned(sinlut(to_integer(unsigned(theta_i)-256)))-16#800#-1);
		elsif unsigned(theta_i)<=768 then
			sine_o   <= std_logic_vector(16#800#-unsigned(sinlut(to_integer(unsigned(theta_i)-512)))-16#800#-1);
			cosine_o <= std_logic_vector(16#800#-unsigned(sinlut(to_integer(768-unsigned(theta_i))))-16#800#-1);
		else
			sine_o   <= std_logic_vector(16#800#-unsigned(sinlut(to_integer(1023-unsigned(theta_i)+1)))-16#800#-1);
			cosine_o <= std_logic_vector(unsigned(sinlut(to_integer(unsigned(theta_i)-768))));
		end if;
	end process;
end architecture;