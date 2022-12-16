--- lenda_da_flash_para_tela
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memoria_para_display is 
	generic (spi_input_clock : integer := 27_000_000;
			spi_output_clock : integer := 13_500_000);
	port (flash_address : out std_logic_vector(14 downto 0);
			flash_data : in std_logic_vector(17 downto 0);
			f_clk_in : in std_logic;
			enable, comando_escreve, entrada_fim_jogo : in std_logic;
			flash_oe, flash_we, flash_reset : out std_logic;
			f_mosi, f_cs, f_sck, f_dc : out std_logic;
            input_offset_x, input_offset_y : in integer);
end memoria_para_display;

architecture rtl_flash of memoria_para_display is

	component divisor is 
        generic(input_clock : integer := spi_input_clock; output_clock : integer := spi_output_clock);
        port(clk_in : in std_logic; clk_out : out std_logic);
	end component;

	-- controle de memoria flash
	signal s_flash_data : std_logic_vector (17 downto 0) := (others => '0');
	signal s_flash_address : integer := 0;

	-- controle posicao linha e coluna
	signal linha : integer range 511 downto 0:= 0;
	signal coluna : integer range 511 downto 0 := 0;

	-- maquina de estados do SPI
	type t_estados is (parado, enviando);
	signal estado : t_estados := parado;
	signal estado_atual : t_estados := parado;

	-- controle de buffer de saida SPI
	signal spi_out_enable_pixels : std_logic := '0';
	signal spi_out_enable_command : std_logic := '0';
	signal s_mosi_comando : std_logic := '0';
	signal s_mosi_pixels : std_logic := '0';
	signal s_dc : std_logic := '0';

	-- travas de processo
	signal lock : std_logic := '0';
	signal GO : std_logic := '0';
	signal comando : std_logic := '0'; -- registrador para iniciar tudo
    signal comando_terminado : std_logic := '0'; -- indica fim do comando, inicio da escrita de pixels

	-- constantes e parametros gerais
	signal clk_div : std_logic;
	constant constante_comando_escrever_vram : std_logic_vector (7 downto 0) := "00101100";
    signal escala : integer := 16;
	signal s_offset_y : integer := 0;
	signal s_offset_x : integer := 0;
    signal s_entrada_fim_jogo : std_logic;
    -- mudar para o valor de linha ao redimensionar a imagem
    -- no momento o modo é 120x160, então precisa colocar 120
    signal constante_de_linha : integer range 320 downto 0 := 120;

	
begin
	div0 : divisor generic map (input_clock => spi_input_clock, output_clock => spi_input_clock)
    				port map (clk_in => f_clk_in, clk_out => clk_div);

	-- maquina de estados atualizada o mais rapido possivel
	-- evita depender do clock do divisor e ter mais tempo por causa de intervalos
	passador_spi: process (f_clk_in) 
	begin
		if rising_edge(f_clk_in) then
			estado_atual <= estado;
		end if;
	end process;

	-- registrador de uso unico para enviar comando de escrita
    iniciar_comando_de_escrita_de : process (comando_escreve, comando)
	begin
		if rising_edge(comando_escreve) then
			comando <= '1';
		else
			comando <= comando;
		end if;
	end process;
	
	-- o mesmo para os dados apos envio do comando
	iniciar_escrita_pixels : process (comando_terminado, GO, f_clk_in)
	begin
        if rising_edge(f_clk_in) then
            if comando_terminado = '1' then
                GO <= '1';
            else        
                GO <= GO;
            end if;
        end if;
	end process;
	
	enviar_comando_inicial : process (clk_div, comando_escreve)
		variable conta_comando : integer := 8;
	begin
		if falling_edge(clk_div) then
			if comando = '1' then
				-- isso e um comando
				s_dc <= '0';
				-- habilita saido do clock
				spi_out_enable_command <= '1';
				
				-- evita erro de indice 
				if conta_comando > 0 then
					s_mosi_comando <= constante_comando_escrever_vram(conta_comando - 1);
				end if;
				

				if conta_comando = 0 then
					-- chegando em zero preparamos para enviar os pixels
					s_dc <= '1';
					spi_out_enable_command <= '0'; -- desabilita saida do clock
                    comando_terminado <= '1'; -- sinaliza fim do comando
				else 
					-- decrementa contador
					conta_comando := conta_comando - 1;
				end if;
			end if;
		end if;
	end process;
	
	enviar_pixels : process(clk_div,s_flash_data,comando_terminado,lock)
		variable conta_local : integer := 8;
		variable conta_byte : integer := 1;
		variable p1, p2, p3 : std_logic_vector(7 downto 0) := (others => '0');
	begin
		if falling_edge(clk_div) then
			-- separa 18 bits em 3 bytes de 6 bits + 00
            p1 := s_flash_data(17 downto 12) & "00";
			p2 := s_flash_data(11 downto 6) & "00";
			p3 := s_flash_data(5 downto 0) & "00";

			if GO = '1' then -- and lock = '0' then
				case estado_atual is
				when parado =>
					-- sempre que enable = 1 transmitimos, isso depende do top
					if enable = '1' then
						estado <= enviando;
					else
						estado <= estado;
					end if;
				when enviando =>
					-- habilita saida do clock
					spi_out_enable_pixels <= '1';
					
					-- evita erro de indice, seleciona o byte a ser enviado, envia bit a bit dele
					if conta_local > 0 then
						case conta_byte is
						when 1 => -- R
							s_mosi_pixels <= p1(conta_local - 1);
						when 2 => -- G
							s_mosi_pixels <= p2(conta_local - 1);
						when 3 => -- B
							s_mosi_pixels <= p3(conta_local - 1);
						end case;
					end if;

					if conta_local = 0 then
						-- enquanto preparamos o proximo byte, desabilitamos a saida do clock
						spi_out_enable_pixels <= '0';
						conta_local := 8;
                        if conta_byte < 3 then
							-- conta_local zerou, proximo byte
                            conta_byte := conta_byte + 1;
                        else
							-- redefine conta_byte
							-- aumenta coluna 240 por 320 linhas
                            conta_byte := 1;
                            if coluna < 239 then
                                coluna <= coluna + 1;
                            else 
								coluna <= 0;
								if linha < 319 then
									linha <= linha + 1;
								else 
									-- ao acabar linhas e colunas, volta ao estado parado e reseta variaveis
									estado <= parado;
									conta_byte := 1;
									conta_local := 8;
									linha <= 0;
									coluna <= 0;
								end if;
                            end if;
                        end if;
					else
						-- decrementa bit a ser mandado
						conta_local := conta_local - 1;
					end if;
				end case;
			end if;
		end if;
	end process;
	
	-- a ideia era usar memoria flash, no entando os sinais sao similares às memórias pROM da Gowin
	flash_oe <= '0';
	flash_we <= '1';
	flash_reset <= '1';
	
	-- sinais foram definidos,depois associados as entradas e saidas, sempre permitindo existir esse 
	-- sumário no final com informações importantes

	-- arbitragem de bus para cada processo
	f_cs <= '0' when estado_atual = enviando or comando_terminado = '0' else '1';
	f_dc <= s_dc;
	f_mosi <= s_mosi_pixels when (estado = enviando and spi_out_enable_command = '0') else
				s_mosi_comando when spi_out_enable_command = '1' else '0';
	f_sck <= clk_div when (estado = enviando and spi_out_enable_pixels = '1') or spi_out_enable_command = '1' else '0';

	-- maior segredo do codigo, escrevemos menos pixels em mais pixels
	s_flash_data <= flash_data; --recebemos da entrada de dados da memoria flash
	-- o endereço tem uma escala para zoom e offset para movimentação
	-- como vhdl vai arredondar para baixo, para sair de 0 a 1 numa escala de 2, temos que contar dois endereços
	-- isso faz o zoom
	flash_address <= std_logic_vector(to_unsigned(((coluna/escala) + s_offset_x) + constante_de_linha*((linha/escala) + s_offset_y), 15));

    s_entrada_fim_jogo <= entrada_fim_jogo;

	-- seletor de escala com base no fim de jogo
    escala <= 2 when (s_entrada_fim_jogo = '1') else 16;

	-- seletor de offset com base no fim de jogo, recebendo entrada de offset diretamente do top
    s_offset_x <= input_offset_x when s_entrada_fim_jogo = '0' else 0;
    s_offset_y <= input_offset_y when s_entrada_fim_jogo = '0' else 0;

end architecture;