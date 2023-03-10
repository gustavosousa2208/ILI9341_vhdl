--Copyright (C)2014-2022 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--GOWIN Version: V1.9.8.07
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9C
--Created Time: Thu Dec 15 15:30:16 2022

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component sprites
    port (
        dout: out std_logic_vector(1 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        ad: in std_logic_vector(14 downto 0)
    );
end component;

your_instance_name: sprites
    port map (
        dout => dout_o,
        clk => clk_i,
        oce => oce_i,
        ce => ce_i,
        reset => reset_i,
        ad => ad_i
    );

----------Copy end-------------------
