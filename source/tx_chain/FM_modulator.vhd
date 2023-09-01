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

use work.cordic_pkg.all;

entity fm_modulator is
	port(
		clk_i	: in std_logic;											-- main clock in
		nrst_i	: in std_logic;											-- reset
		nw_i	: in std_logic;											-- narrow/wide selector, N=0, W=1
		s_axis_mod_i : in axis_in_mod_t;
		s_axis_mod_o : out axis_out_mod_t;
		m_axis_iq_i : in axis_out_iq_t;
		m_axis_iq_o : out axis_in_iq_t
	);
end fm_modulator;

architecture magic of fm_modulator is
	signal phase	: signed(20 downto 0) := (others => '0');
	signal phase_vld : std_logic := '0';

	signal ready : std_logic;
	signal output_valid : std_logic := '0';

	constant gain_scaling : real := 1.75; -- TODO: explain this param and increase the dynamic range

	type mod_state_t is (IDLE, COMPUTE, DONE);
	signal mod_state : mod_state_t := IDLE;

begin
	-- sincos
	sincos: entity work.cordic_sincos generic map(
		SIZE => 21,
		ITERATIONS => 21,
		TRUNC_SIZE => 16,
        RESET_ACTIVE_LEVEL => '0'
    )
	port map(
		Clock => clk_i,
		Reset => nrst_i,

		Data_valid => phase_vld,
		Busy       => open,
		Result_valid => output_valid,
		Mode => cordic_rotate,

		X => to_signed(integer(1.0/cordic_gain(21) * gain_scaling * 2.0 ** 19) , 21),
		Y => 21x"000000",
        Z => phase,

		std_logic_vector(X_result) => m_axis_iq_o.tdata(31 downto 16), -- I
		std_logic_vector(Y_result) => m_axis_iq_o.tdata(15 downto 0) -- Q
	);

	process(clk_i)
	begin
		if nrst_i='0' then
			phase <= (others => '0');
		elsif rising_edge(clk_i) then
			-- Store a new transaction when ready
			ready <= '0';
			case mod_state is
				when COMPUTE =>
					phase_vld <= '0';
					if output_valid then
						mod_state <= DONE;
					end if;

				when DONE =>
					m_axis_iq_o.tvalid <= '1';
					if m_axis_iq_i.tready and m_axis_iq_o.tvalid then
						mod_state <= IDLE;
						m_axis_iq_o.tvalid <= '0';
					end if;

				when others => -- IDLE, safe
					m_axis_iq_o.tvalid <= '0';
					ready <= m_axis_iq_i.tready;
					if s_axis_mod_i.tvalid and ready then
						ready <= '0';
						phase_vld <= '1';
						mod_state <= COMPUTE;

						if nw_i='0' then -- narrow FM
							phase <= phase + resize(signed(s_axis_mod_i.tdata), 21); -- update phase accumulator
						else -- wide FM
							phase <= phase + resize(signed(s_axis_mod_i.tdata & '0'), 21); -- update phase accumulator
						end if;

					end if;

			end case;
		end if;
	end process;

	s_axis_mod_o.tready <= ready and not m_axis_iq_o.tvalid;
end magic;
