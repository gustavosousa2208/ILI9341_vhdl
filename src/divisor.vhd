library ieee;
use ieee.std_logic_1164.all;

-- #REUTILIZAVEL

entity divisor is 
	generic(
		input_clock : integer := 27_000_000;
		output_clock : integer := 13_500_000
	);
	port(
		clk_in : in std_logic;
		clk_out : out std_logic
	);
end divisor;

architecture rtl of divisor is
	signal s_clock : std_logic := '0';
	constant count_to : integer := (input_clock/output_clock);
begin
	process(clk_in)
		variable counter : integer range 0 to count_to := 0;
	begin
		if (rising_edge(clk_in)) then
			if (counter = count_to) then
				counter := 0;
				s_clock <= not s_clock;
			else 
				counter := counter + 1;
			end if;
		end if;
	end process;
	
	clk_out <= s_clock;
	
end architecture;