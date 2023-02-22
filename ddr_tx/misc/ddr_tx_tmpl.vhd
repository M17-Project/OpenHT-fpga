component ddr_tx is
    port(
        rst_i: in std_logic;
        data_i: in std_logic_vector(1 downto 0);
        clk_i: in std_logic;
        data_o: out std_logic_vector(0 to 0);
        clk_o: out std_logic
    );
end component;

__: ddr_tx port map(
    rst_i=>,
    data_i=>,
    clk_i=>,
    data_o=>,
    clk_o=>
);
