-- spi_master
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_transmissao_byte is 
	generic (clock_in : integer := 27_000_000;
				clock_out : integer := 13_500_000);
	port(sck : out std_logic; mosi : out std_logic; dc : out std_logic; 
        reset : out std_logic; cs_out : out std_logic; btn_on : in std_logic; sys_clk : in std_logic;
		command_to_send : in std_logic_vector (8 downto 0);
		enable : in  std_logic);
end entity;

architecture rtl of spi_transmissao_byte is
	-- declaracao de coponente
	component divisor is 
        generic(input_clock : integer := clock_in; output_clock : integer := clock_out);
        port(clk_in : in std_logic; clk_out : out std_logic);
	end component;
	
	signal sck_on : std_logic := '0';
	signal cs : std_logic := '1';
	
	type t_states is (parado, enviando);								-- definicao do tipo de estados
	signal estados : t_states := parado;								-- estado da maquina de estados
	signal sck_div : std_logic;											-- sianal de clock dividido (SPI) como definido no generic
	signal s_mosi : std_logic := '0';									-- sinal de saida do mosi
	
	signal cmd : std_logic_vector (8 downto 0) := (others => '0');		-- sinakl de comando a ser enviado
	
begin

	div0 : divisor generic map (input_clock => clock_in, output_clock => clock_out) 
    port map (clk_in => sys_clk, clk_out => sck_div);
	
	-- maquina de estados, registra o comando a enviar sempre que o botao for pressionado
	-- o botao e ativo baixo
	passa_comando : process(btn_on, command_to_send,estados,enable)
	begin
		if (estados = parado) then
			if (falling_edge(btn_on)) then
				cmd <= command_to_send;
			end if;
		end if;
	end process;

	comando : process (btn_on,sck_div,estados,command_to_send,enable)
		variable count : integer range 8 downto 0 := 8;
	begin
		if(enable = '1') then
			if (btn_on = '0') then
				-- no mesmo tempo do primeiro processo, aqui mudamos o estado para enviando
				if (estados = parado) then
					estados <= enviando;
				end if;
			elsif (falling_edge(sck_div)) then
				if (estados = enviando) then
					case count is 
					-- oito pulsos para enviar bit a bit, sempre trocamos na falling edge para 
					-- ser registrado no display no rising edge
					when 8 downto 1 =>
						cs <= '0'; -- inicia transmissao
						sck_on <= '1'; -- habilita clock da saida
						s_mosi <= cmd(count - 1); -- envia bit a bit, variando pela contagem
						count := count - 1; -- decrementa a contagem, MSB -> LSB
					when 0 =>
						sck_on <= '0'; -- desliga saida do clock
						estados <= parado; -- volta para o estado parado
						count := 8; -- reseta a contagem
						cs <= '1'; -- termina transmissao
					end case;
				end if;
			end if;
		end if;
	end process;

	-- buffers de saida, habilita saida dos sinais somente quando o processo estiver enviando os 8 bits
	-- assim evita adiantar o clock em relacao ao sinal, o que pode causar problemas
	sck <= sck_div when sck_on = '1' else '0';
	cs_out <= cs when estados = enviando else '1';
	mosi <= s_mosi when estados = enviando else 'Z';
	-- definimos a frame como 9 bits, ou seja, um indica que é dado ou comando
	-- se for dado, será 256 + dado, indicado pelo bit MSB, é um controle assincrono
	-- sempre que o dado for registrado, temos se o dc é um ou zero
	-- além disso, evita complexidade no processo de envio
	dc <= cmd(8);
end rtl;