library ieee;
use ieee.std_logic_1164.all;

entity principal is 
	port(clk_in, free_buffer : in std_logic;
		top_dc, top_mosi, top_cs, top_sck, data_enable : out std_logic;
		comando_dc, comando_cs, comando_sck, comando_mosi : in std_logic;
		dado_dc, dado_cs, dado_sck, dado_mosi : in std_logic
		);
end entity;

architecture rtl of principal is
	
begin
	
	top_dc <= comando_dc when free_buffer = '0' else dado_dc;
	top_cs <= comando_cs when free_buffer = '0' else dado_cs;
	top_sck <= comando_sck when free_buffer = '0' else dado_sck;
	top_mosi <= comando_mosi when free_buffer = '0' else dado_mosi;
	
	data_enable <= '1';
end architecture;