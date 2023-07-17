-------------------------------------------------------------
-- Complex frequency modulator
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

entity fm_modulator is
	generic(
		SINCOS_RES 		: natural := 16;			-- CORDIC resolution, default - 16 bits
		SINCOS_ITER		: natural := 14;			-- CORDIC iterations, default - 14
		SINCOS_COEFF	: signed := x"4DB9"			-- CORDIC scaling coefficient
	);
	port(
		clk_i	: in std_logic;											-- main clock in
		nrst_i	: in std_logic;											-- reset
		nw_i	: in std_logic;											-- narrow/wide selector, N=0, W=1
		s_axis_mod_i : in axis_in_mod_t;
		m_axis_iq_o : out axis_in_iq_t
	);
end fm_modulator;

architecture magic of fm_modulator is
	signal phase	: std_logic_vector(20 downto 0) := (others => '0');
	signal theta	: unsigned(15 downto 0) := (others => '0');
	signal phase_vld : std_logic := '0';
	signal cordic_vld : std_logic := '0';
begin
	-- sincos
	theta <= unsigned(phase(20 downto 20-16+1));
	sincos: entity work.cordic generic map(
        RES_WIDTH => SINCOS_RES,
        ITER_NUM => SINCOS_ITER,
        COMP_COEFF => SINCOS_COEFF
    )
	port map(
		clk_i => clk_i,
		phase_i => theta,
		phase_valid_i => phase_vld,
		std_logic_vector(sin_o) => m_axis_iq_o.tdata(15 downto 0), -- Q
		std_logic_vector(cos_o) => m_axis_iq_o.tdata(31 downto 16), -- I
		valid_o => cordic_vld
	);
	
	m_axis_iq_o.tvalid <= cordic_vld and phase_vld; -- TODO: we need to make the CORDIC one-shot
	
	process(clk_i)
	begin
		if nrst_i='0' then
			phase <= (others => '0');
		elsif rising_edge(clk_i) then
			phase_vld <= s_axis_mod_i.tvalid;
			if s_axis_mod_i.tvalid then
				if nw_i='0' then -- narrow FM
					phase <= std_logic_vector(unsigned(phase) + unsigned(resize(signed(s_axis_mod_i.tdata), 21))); -- update phase accumulator
				else -- wide FM
					phase <= std_logic_vector(unsigned(phase) + unsigned(resize(signed(s_axis_mod_i.tdata & '0'), 21))); -- update phase accumulator
				end if;
			end if;
		end if;
	end process;

	m_axis_iq_o.tlast <= '0';
end magic;
