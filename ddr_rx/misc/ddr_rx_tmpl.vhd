component ddr_rx is
    port(
        rst_i: in std_logic;
        data_i: in std_logic_vector(0 to 0);
        clk_i: in std_logic;
        data_o: out std_logic_vector(1 downto 0);
        sclk_o: out std_logic
    );
end component;

__: ddr_rx port map(
    rst_i=>,
    data_i=>,
    clk_i=>,
    data_o=>,
    sclk_o=>
);
