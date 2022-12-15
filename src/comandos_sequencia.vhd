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
	
	-- sequencia de comandos para inicializar o display, na ordem 12 -> 0
	type t_commands is array (natural range<>) of integer range 0 to 511;
	constant startup_sequence : t_commands (12 downto 0) := (17, 19, 32, 81, 383, 38, 257, 58, 358, 55, 256, 256, 41);
	
	-- para armazenar valor do comando a ser enviado
	signal command_to_send : std_logic_vector (8 downto 0);
	-- controle de processo
	signal btn_on : std_logic := '1';
	signal started : boolean := false;
	signal lock, GO : boolean := false;
	
begin
	spi0 : spi_transmissao_byte generic map (clock_in => spi_master_clock_in, clock_out => spi_master_clock_out)
    port map(command_to_send => command_to_send, enable => '1', cs_out => cs_out, btn_on => btn_on, sys_clk => spi_clk_in, sck => sck, mosi => mosi, dc => dc);
	
	-- registrador de uso único para mandar todos comandos em sequencia e parar
	process (seq_enable, GO) 
	begin
		if rising_edge(seq_enable) then
			GO <= true;
		else 
			GO <= GO;
		end if;
	end process;

	-- OBS: desabilitar modulo SPI, nao desabilita realmente, ele precisa de um pulso em baixo para iniciar
	-- o envio do comando, no entanto se mantermos a entrada alta, o modulo envia o que estiver enviando
	-- depois fica inativo
	troca_comando : process (spi_clk_in, cs_out, GO)
		variable count : integer range startup_sequence'length downto 0 := startup_sequence'length;
	begin
		-- havendo sido iniciado processo pelo registrador GO seguimos em frente
		if (rising_edge(spi_clk_in) and GO = true) then
			-- sempre que cs esta alto, podemos enviar outro comando, se a trava estiver desabilitada
			if (cs_out = '1' and lock = false) then
				-- a contagem começa do 13, um numero é desperdiçado para controle de inicio
				-- evitamos colocar indice fora do permitido
				if (count > 0) then
					-- define comando a ser enviado agora
					command_to_send <= std_logic_vector(to_unsigned(startup_sequence(count - 1),9));
				end if;
				-- se nao ha comandos sendo enviados, mandamos pulso para mandar este comando
				if (started = false) then
					btn_on <='0';							-- manda um pulso baixo momentaneamente para habilitar o modulo spi
					started <= true;						-- habilita flag de inicio
					if (count = 0) then
						count := startup_sequence'length; 	-- restaura contagem
						lock <= true;						-- habilita trava previnindo rodar novamente
						btn_on <= '1';						-- mantem o modulo spi desabilitado
					else 
						count := count - 1;					-- proximo comando
					end if;
				else 
					btn_on <='1';							-- mantem o modulo spi desabilitado
				end if;
			elsif (cs_out = '0') then
				btn_on <= '1';								-- mantem o modulo spi desabilitado
				started <= false;							-- desabilita flag de inicio
			end if;
		end if;
	end process;
	
	reset <= '1'; -- não foi usado, permanece em alto por segurança
	out_btn_on <= '0' when GO = true else '1'; -- indica se o processo foi iniciado
	free_buffer <= '1' when lock = true else '0'; -- indica se o processo foi terminado, podemos liberar o buffer
end architecture;