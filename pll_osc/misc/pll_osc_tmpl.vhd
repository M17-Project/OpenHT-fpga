component pll_osc is
    port(
        clki_i: in std_logic;
        clkop_o: out std_logic;
        clkos_o: out std_logic;
        clkos2_o: out std_logic
    );
end component;

__: pll_osc port map(
    clki_i=>,
    clkop_o=>,
    clkos_o=>,
    clkos2_o=>
);
