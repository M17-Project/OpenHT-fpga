-------------------------------------------------------------
-- Modulation resampler
--
-- Wojciech Kaczmarski, SP5WWP
-- Sebastien, ON4SEB
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.axi_stream_pkg.all;
use work.openht_utils_pkg.all;

entity mod_resampler is
	generic(
		C_TAPS_5_8K : taps_mod_t := (
			x"0011", x"0000", x"fffd", x"fffa", x"fff8", 
			x"fff8", x"fffb", x"ffff", x"0002", x"0006", 
			x"0006", x"0004", x"0000", x"fffa", x"fff6", 
			x"fff5", x"fff9", x"0000", x"0007", x"000c", 
			x"000d", x"0008", x"0000", x"fff7", x"fff0", 
			x"ffef", x"fff5", x"0000", x"000b", x"0014", 
			x"0014", x"000d", x"0000", x"fff2", x"ffe8", 
			x"ffe7", x"fff0", x"0000", x"0011", x"001d", 
			x"001f", x"0013", x"0000", x"ffeb", x"ffdc", 
			x"ffdb", x"ffe9", x"0000", x"0019", x"002a", 
			x"002c", x"001c", x"0000", x"ffe2", x"ffce", 
			x"ffcc", x"ffdf", x"0000", x"0023", x"003b", 
			x"003d", x"0027", x"0000", x"ffd7", x"ffbb", 
			x"ffb9", x"ffd3", x"0000", x"0030", x"0051", 
			x"0053", x"0035", x"0000", x"ffc8", x"ffa3", 
			x"ffa0", x"ffc3", x"0000", x"0040", x"006b", 
			x"006e", x"0046", x"0000", x"ffb6", x"ff85", 
			x"ff81", x"ffb0", x"0000", x"0054", x"008d", 
			x"0090", x"005b", x"0000", x"ffa0", x"ff60", 
			x"ff5c", x"ff98", x"0000", x"006d", x"00b6", 
			x"00bb", x"0076", x"0000", x"ff84", x"ff32", 
			x"ff2d", x"ff7a", x"0000", x"008c", x"00e9", 
			x"00ef", x"0097", x"0000", x"ff61", x"fef9", 
			x"fef2", x"ff55", x"0000", x"00b3", x"0129", 
			x"0130", x"00c0", x"0000", x"ff36", x"feb2", 
			x"fea9", x"ff27", x"0000", x"00e3", x"0179", 
			x"0182", x"00f4", x"0000", x"ff00", x"fe57", 
			x"fe4c", x"feec", x"0000", x"0122", x"01e1", 
			x"01ed", x"0138", x"0000", x"feb8", x"fde0", 
			x"fdd2", x"fe9e", x"0000", x"0174", x"026b", 
			x"027b", x"0193", x"0000", x"fe57", x"fd3d", 
			x"fd29", x"fe32", x"0000", x"01e9", x"032e", 
			x"0347", x"0216", x"0000", x"fdc9", x"fc4d", 
			x"fc2e", x"fd90", x"0000", x"029b", x"045d", 
			x"0485", x"02e5", x"0000", x"fce1", x"fac0", 
			x"fa89", x"fc7b", x"0000", x"03d7", x"0681", 
			x"06d2", x"046e", x"0000", x"fb15", x"f793", 
			x"f70f", x"fa1e", x"0000", x"06c0", x"0bca", 
			x"0ccb", x"08a3", x"0000", x"f56a", x"ecb6", 
			x"e9ee", x"f013", x"0000", x"17ec", x"33a2", 
			x"4d7a", x"5fc9", x"6666", x"5fc9", x"4d7a", 
			x"33a2", x"17ec", x"0000", x"f013", x"e9ee", 
			x"ecb6", x"f56a", x"0000", x"08a3", x"0ccb", 
			x"0bca", x"06c0", x"0000", x"fa1e", x"f70f", 
			x"f793", x"fb15", x"0000", x"046e", x"06d2", 
			x"0681", x"03d7", x"0000", x"fc7b", x"fa89", 
			x"fac0", x"fce1", x"0000", x"02e5", x"0485", 
			x"045d", x"029b", x"0000", x"fd90", x"fc2e", 
			x"fc4d", x"fdc9", x"0000", x"0216", x"0347", 
			x"032e", x"01e9", x"0000", x"fe32", x"fd29", 
			x"fd3d", x"fe57", x"0000", x"0193", x"027b", 
			x"026b", x"0174", x"0000", x"fe9e", x"fdd2", 
			x"fde0", x"feb8", x"0000", x"0138", x"01ed", 
			x"01e1", x"0122", x"0000", x"feec", x"fe4c", 
			x"fe57", x"ff00", x"0000", x"00f4", x"0182", 
			x"0179", x"00e3", x"0000", x"ff27", x"fea9", 
			x"feb2", x"ff36", x"0000", x"00c0", x"0130", 
			x"0129", x"00b3", x"0000", x"ff55", x"fef2", 
			x"fef9", x"ff61", x"0000", x"0097", x"00ef", 
			x"00e9", x"008c", x"0000", x"ff7a", x"ff2d", 
			x"ff32", x"ff84", x"0000", x"0076", x"00bb", 
			x"00b6", x"006d", x"0000", x"ff98", x"ff5c", 
			x"ff60", x"ffa0", x"0000", x"005b", x"0090", 
			x"008d", x"0054", x"0000", x"ffb0", x"ff81", 
			x"ff85", x"ffb6", x"0000", x"0046", x"006e", 
			x"006b", x"0040", x"0000", x"ffc3", x"ffa0", 
			x"ffa3", x"ffc8", x"0000", x"0035", x"0053", 
			x"0051", x"0030", x"0000", x"ffd3", x"ffb9", 
			x"ffbb", x"ffd7", x"0000", x"0027", x"003d", 
			x"003b", x"0023", x"0000", x"ffdf", x"ffcc", 
			x"ffce", x"ffe2", x"0000", x"001c", x"002c", 
			x"002a", x"0019", x"0000", x"ffe9", x"ffdb", 
			x"ffdc", x"ffeb", x"0000", x"0013", x"001f", 
			x"001d", x"0011", x"0000", x"fff0", x"ffe7", 
			x"ffe8", x"fff2", x"0000", x"000d", x"0014", 
			x"0014", x"000b", x"0000", x"fff5", x"ffef", 
			x"fff0", x"fff7", x"0000", x"0008", x"000d", 
			x"000c", x"0007", x"0000", x"fff9", x"fff5", 
			x"fff6", x"fffa", x"0000", x"0004", x"0006", 
			x"0006", x"0002", x"ffff", x"fffb", x"fff8", 
			x"fff8", x"fffa", x"fffd", x"0000", x"0011"
		);

		C_TAPS_5_40K : taps_mod_t := (
			x"ffff", x"0000", x"0000", x"0000", x"0000", 
			x"0000", x"0000", x"0001", x"0002", x"0003", 
			x"0005", x"0006", x"0007", x"0008", x"0009", 
			x"0008", x"0008", x"0006", x"0003", x"0000", 
			x"fffb", x"fff6", x"fff0", x"ffea", x"ffe3", 
			x"ffde", x"ffda", x"ffd7", x"ffd7", x"ffda", 
			x"ffe0", x"ffe9", x"fff6", x"0004", x"0017", 
			x"002b", x"003f", x"0054", x"0066", x"0075", 
			x"007f", x"0083", x"007f", x"0073", x"005d", 
			x"003f", x"0018", x"ffeb", x"ffb7", x"ff80", 
			x"ff4a", x"ff16", x"feea", x"fec8", x"feb4", 
			x"feb1", x"fec2", x"fee7", x"ff23", x"ff72", 
			x"ffd5", x"0045", x"00c0", x"0140", x"01bd", 
			x"022f", x"028f", x"02d5", x"02f9", x"02f6", 
			x"02c7", x"0269", x"01dc", x"0122", x"0041", 
			x"ff41", x"fe2b", x"fd0c", x"fbf5", x"faf4", 
			x"fa1c", x"f97e", x"f929", x"f92d", x"f997", 
			x"fa6e", x"fbba", x"fd7c", x"ffaf", x"024b", 
			x"0545", x"088c", x"0c0a", x"0fa7", x"134a", 
			x"16d5", x"1a2e", x"1d3a", x"1fde", x"2204", 
			x"239c", x"2496", x"24ea", x"2496", x"239c", 
			x"2204", x"1fde", x"1d3a", x"1a2e", x"16d5", 
			x"134a", x"0fa7", x"0c0a", x"088c", x"0545", 
			x"024b", x"ffaf", x"fd7c", x"fbba", x"fa6e", 
			x"f997", x"f92d", x"f929", x"f97e", x"fa1c", 
			x"faf4", x"fbf5", x"fd0c", x"fe2b", x"ff41", 
			x"0041", x"0122", x"01dc", x"0269", x"02c7", 
			x"02f6", x"02f9", x"02d5", x"028f", x"022f", 
			x"01bd", x"0140", x"00c0", x"0045", x"ffd5", 
			x"ff72", x"ff23", x"fee7", x"fec2", x"feb1", 
			x"feb4", x"fec8", x"feea", x"ff16", x"ff4a", 
			x"ff80", x"ffb7", x"ffeb", x"0018", x"003f", 
			x"005d", x"0073", x"007f", x"0083", x"007f", 
			x"0075", x"0066", x"0054", x"003f", x"002b", 
			x"0017", x"0004", x"fff6", x"ffe9", x"ffe0", 
			x"ffda", x"ffd7", x"ffd7", x"ffda", x"ffde", 
			x"ffe3", x"ffea", x"fff0", x"fff6", x"fffb", 
			x"0000", x"0003", x"0006", x"0008", x"0008", 
			x"0009", x"0008", x"0007", x"0006", x"0005", 
			x"0003", x"0002", x"0001", x"0000", x"0000", 
			x"0000", x"0000", x"0000", x"0000", x"ffff"
		);

		C_TAPS_2_200K : taps_mod_t := (
			x"0000", x"ffff", x"fffe", x"fffc", x"fff8", x"fff4", x"ffef", x"ffe9", 
			x"ffe3", x"ffdf", x"ffdc", x"ffde", x"ffe6", x"fff5", x"000c", x"002d", 
			x"0057", x"0088", x"00bc", x"00ef", x"011a", x"0136", x"013a", x"011d", 
			x"00d9", x"0069", x"ffcd", x"ff06", x"fe1d", x"fd20", x"fc24", x"fb41", 
			x"fa93", x"fa3a", x"fa55", x"faff", x"fc50", x"fe56", x"0114", x"0487", 
			x"0898", x"0d28", x"120b", x"170d", x"1bf4", x"2082", x"247c", x"27ac", 
			x"29e6", x"2b0c", x"2b0c", x"29e6", x"27ac", x"247c", x"2082", x"1bf4", 
			x"170d", x"120b", x"0d28", x"0898", x"0487", x"0114", x"fe56", x"fc50", 
			x"faff", x"fa55", x"fa3a", x"fa93", x"fb41", x"fc24", x"fd20", x"fe1d", 
			x"ff06", x"ffcd", x"0069", x"00d9", x"011d", x"013a", x"0136", x"011a", 
			x"00ef", x"00bc", x"0088", x"0057", x"002d", x"000c", x"fff5", x"ffe6", 
			x"ffde", x"ffdc", x"ffdf", x"ffe3", x"ffe9", x"ffef", x"fff4", x"fff8", 
			x"fffc", x"fffe", x"ffff", x"0000"
		)
	);
	port(
		clk_i        : in std_logic;
		s_axis_mod_i : in axis_in_mod_t;
		s_axis_mod_o : out axis_out_mod_t;
		m_axis_mod_o : out axis_in_mod_t;
		m_axis_mod_i : in axis_out_mod_t
	);
end mod_resampler;

architecture magic of mod_resampler is
	signal interp0_axis_in		: axis_out_mod_t;
	signal interp0_axis_out		: axis_in_mod_t;
	signal interp1_axis_in		: axis_out_mod_t;
	signal interp1_axis_out		: axis_in_mod_t;
begin
	interpol0: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 205,
		L		=> 5,
		C_TAPS	=> C_TAPS_5_40K,
		C_OUT_SHIFT => 0
	)
	port map(
		clk_i			=> clk_i,
		s_axis_mod_i	=> s_axis_mod_i,
		s_axis_mod_o	=> s_axis_mod_o,
		m_axis_mod_o	=> interp0_axis_out,
		m_axis_mod_i 	=> interp0_axis_in
	);

	interpol1: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 205,
		L		=> 5,
		C_TAPS	=> C_TAPS_5_40K,
		C_OUT_SHIFT => 1
	)
	port map(
		clk_i			=> clk_i,
		s_axis_mod_i	=> interp0_axis_out,
		s_axis_mod_o	=> interp0_axis_in,
		m_axis_mod_o	=> interp1_axis_out,
		m_axis_mod_i 	=> interp1_axis_in
	);

	interpol2: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 100,
		L		=> 2,
		C_TAPS	=> C_TAPS_2_200K,
		C_OUT_SHIFT => 2
	)
	port map(
		clk_i			=> clk_i,
		s_axis_mod_i	=> interp1_axis_out,
		s_axis_mod_o	=> interp1_axis_in,
		m_axis_mod_o	=> m_axis_mod_o,
		m_axis_mod_i 	=> m_axis_mod_i
	);
end magic;
