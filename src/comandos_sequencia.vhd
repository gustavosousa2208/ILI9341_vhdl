-- comandos_sequencia
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comandos_sequencia is
    generic (spi_master_clock_in : integer := 27_000_000;
                spi_master_clock_out : integer := 13_500_000);
	port (spi_clk_in, seq_enable : in std_logic;
			cs_out : buffer std_logic;
			sck, mosi, dc,out_btn_on, free_buffer, reset : out std_logic);
end entity;

architecture rtl of comandos_sequencia is

	component spi_transmissao_byte is 
		generic (clock_in : integer := spi_master_clock_in;
				clock_out : integer := spi_master_clock_out);
		port(sck : out std_logic; mosi : out std_logic; dc : out std_logic; 
			reset : out std_logic; cs_out : out std_logic; btn_on : in std_logic; sys_clk : in std_logic;
			command_to_send : in std_logic_vector (8 downto 0);
			enable : in  std_logic);
	end component;
	
	type t_commands is array (natural range<>) of integer range 0 to 511;
	constant startup_sequence : t_commands (12 downto 0) := (17, 19, 32, 81, 383, 38, 257, 58, 358, 55, 256, 256, 41);
	
	signal command_to_send : std_logic_vector (8 downto 0);
	signal btn_on : std_logic := '1';
	signal started : boolean := false;
	signal lock, GO : boolean := false;
	
begin
	spi0 : spi_transmissao_byte generic map (clock_in => spi_master_clock_in, clock_out => spi_master_clock_out)
    port map(command_to_send => command_to_send, enable => '1', cs_out => cs_out, btn_on => btn_on, sys_clk => spi_clk_in, sck => sck, mosi => mosi, dc => dc);
	
	troca_comando : process (spi_clk_in, cs_out, GO)
		variable count : integer range 13 downto 0 := 13;
	begin
		if (rising_edge(spi_clk_in) and GO = true) then
			if (cs_out = '1' and lock = false) then
				if (count > 0) then
					command_to_send <= std_logic_vector(to_unsigned(startup_sequence(count - 1),9));
				end if;
				if (started = false) then
					btn_on <='0';
					started <= true;
					if (count = 0) then
						count := startup_sequence'length;
						lock <= true;
						btn_on <= '1';
					else 
						count := count - 1;
					end if;
				else 
					btn_on <='1';
				end if;
			elsif (cs_out = '0') then
				btn_on <= '1';
				started <= false;
			end if;
		end if;
	end process;
	
	process (seq_enable, GO) 
	begin
		if rising_edge(seq_enable) then
			GO <= true;
		else 
			GO <= GO;
		end if;
	end process;
	
	
	reset <= '1';
	out_btn_on <= '0' when GO = true else '1';
	free_buffer <= '1' when lock = true else '0';
end architecture;