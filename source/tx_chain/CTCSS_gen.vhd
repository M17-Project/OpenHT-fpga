-------------------------------------------------------------
-- CTCSS/AFSK modulator
--
-- Sebastien, ON4SEB
-- M17 Project
-- October 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;

use work.cordic_pkg.all;
use work.apb_pkg.all;

entity ctcss_gen is
	generic (
        PSEL_ID : natural
    );
	port(
		clk_i	: in std_logic;											-- main clock in
		nrst_i	: in std_logic;											-- reset
		s_apb_in : in apb_in_t;
        s_apb_out : out apb_out_t;
		s_axis_i : in axis_in_iq_t;
		s_axis_o : out axis_out_iq_t;
		m_axis_i : in axis_out_iq_t;
		m_axis_o : out axis_in_iq_t
	);
end ctcss_gen;

architecture magic of ctcss_gen is
	signal phase	: signed(15 downto 0) := (others => '0');
	signal phase_vld : std_logic := '0';

	signal ready : std_logic := '0';
	signal output_valid : std_logic := '0';
	signal cordic_busy : std_logic;

	type mod_state_t is (IDLE, COMPUTE, DONE);
	signal mod_state : mod_state_t := IDLE;

	signal enabled : std_logic := '0'; -- Enabled
	signal in_mode : std_logic := '0'; -- Input from constant (0) or stream(1)
	signal add_pass : std_logic := '0'; -- Add with incoming signal (0), replace(1)
	signal tuning_w : signed(15 downto 0) := (others => '0');
	signal amplitude : signed(15 downto 0) := (others => '0');
	signal sin_output : signed(15 downto 0);

begin
	-- sincos
	sincos: entity work.cordic_sincos generic map(
		SIZE => 16,
		ITERATIONS => 16,
		TRUNC_SIZE => 16,
        RESET_ACTIVE_LEVEL => '0',
		ROUND_ENABLE => false
    )
	port map(
		Clock => clk_i,
		Reset => nrst_i,

		Data_valid => phase_vld,
		Busy       => cordic_busy,
		Result_valid => output_valid,
		Mode => cordic_rotate,

		X => amplitude,
		Y => 16x"0000",
        Z => phase,

		Y_result => sin_output
	);

	process(clk_i)
	begin
		if nrst_i='0' then
			phase <= (others => '0');
			m_axis_o.tvalid <= '0';
		elsif rising_edge(clk_i) then
			-- Store a new transaction when ready
			ready <= '0';
			case mod_state is
				when COMPUTE =>
					phase_vld <= '0';
					if output_valid then
						mod_state <= DONE;
						m_axis_o.tvalid <= '1';
						if add_pass then
							m_axis_o.tdata <= std_logic_vector(sin_output + signed(s_axis_i.tdata));
						else
							m_axis_o.tdata <= std_logic_vector(sin_output);
						end if;
					end if;

				when DONE =>
					if m_axis_i.tready and m_axis_o.tvalid then
						mod_state <= IDLE;
						m_axis_o.tvalid <= '0';
						ready <= '1';
					end if;

				when others => -- IDLE, safe
					m_axis_o.tvalid <= '0';
					ready <= '1';
					if s_axis_i.tvalid and not cordic_busy then
						ready <= '0';
						if enabled then
							phase_vld <= '1';
							mod_state <= COMPUTE;

							if in_mode then
								phase <= phase + signed(s_axis_i.tdata);
							else
								phase <= phase + tuning_w;
							end if;
						else
							mod_state <= DONE;
							m_axis_o.tdata <= s_axis_i.tdata;
							m_axis_o.tvalid <= '1';
							phase <= (others => '0');
						end if;
					end if;

			end case;
		end if;
	end process;

	s_axis_o.tready <= ready;

	process (clk_i)
    begin
        if rising_edge(clk_i) then
            s_apb_out.pready <= '0';
            s_apb_out.prdata <= (others => '0');

            if s_apb_in.PSEL(PSEL_ID) then
                if s_apb_in.PENABLE and s_apb_in.PWRITE then
                    case s_apb_in.paddr(2 downto 1) is
                        when "00" => -- Mode reg
                            enabled <= s_apb_in.pwdata(0);
							in_mode <= s_apb_in.pwdata(1);
							add_pass <= s_apb_in.pwdata(2);

						when "01" =>
							amplitude <= signed(s_apb_in.pwdata);

						when "10" =>
							tuning_w <= signed(s_apb_in.pwdata);

                        when others =>
                            null;
                    end case;
                end if;

                if not s_apb_in.PENABLE then
                    s_apb_out.pready <= '1';
                    case s_apb_in.paddr(2 downto 1) is
                        when "00" => -- Mode reg
							s_apb_out.prdata(0) <= enabled;
							s_apb_out.prdata(1) <= in_mode;
							s_apb_out.prdata(2) <= add_pass;

						when "01" =>
							s_apb_out.prdata <= std_logic_vector(amplitude);

						when "10" =>
							s_apb_out.prdata <= std_logic_vector(tuning_w);

                        when others =>
                            null;
                    end case;
                end if;
            end if;

        end if;
    end process;

end magic;
