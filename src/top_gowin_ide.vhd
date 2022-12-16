library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_gowin_ide is
    generic (SYSTEM_CLK_IN : integer := 27_000_000;
            PLL_CLK_OUT : integer := 100_000_000;
            DATA_WRITE_CLK_OUT : integer := 13_500_000);
    port (sys_clk, start, vram_write_cmd : in std_logic;
			led_setup, led_writing, led_done, top_led_sck, top_led_mosi : out std_logic;
			top_mosi, top_cs, top_sck, top_dc, led_idle : out std_logic;
            entrada_pontuacao : std_logic_vector (3 downto 0);
            saida_reset : out std_logic);
end top_gowin_ide;

architecture rtl of top_gowin_ide is
    component comandos_sequencia is
        generic (spi_master_clock_in : integer := 27_000_000;
                spi_master_clock_out : integer := 13_500_000);
        port (spi_clk_in, seq_enable : in std_logic;
            cs_out : buffer std_logic;
            sck, mosi, dc,out_btn_on, free_buffer, reset : out std_logic);
    end component;

    signal cmd_clk, cmd_cs, cmd_sck, cmd_mosi, cmd_dc, cmd_out_btn_on, cmd_free_buffer, cmd_reset : std_logic;
    signal cmd_seq_enable : std_logic := '0';
    component memoria_para_display is 
	generic (spi_input_clock : integer := 27_000_000;
			spi_output_clock : integer := 13_500_000);
	port (flash_address : out std_logic_vector(14 downto 0);
			flash_data : in std_logic_vector(17 downto 0);
			f_clk_in : in std_logic;
			enable, comando_escreve, entrada_fim_jogo : in std_logic;
			flash_oe, flash_we, flash_reset : out std_logic;
			f_mosi, f_cs, f_sck, f_dc : out std_logic;
            input_offset_x, input_offset_y : in integer);
    end component;

    signal s_flash_address : std_logic_vector(14 downto 0);
    signal s_flash_data : std_logic_vector(17 downto 0);
    signal s_enable, s_comando_escreve : std_logic := '0';
    signal s_flash_oe, s_flash_we, s_flash_reset, s_led_mosi, s_led_cs, s_led_sck, s_led_dc, s_led_lock : std_logic;
    signal s_f_mosi, s_f_cs, s_f_sck, s_f_dc : std_logic;
    signal s_f_clk_in : std_logic;
    signal s_input_offset_x, s_input_offset_y : integer;
    signal s_entrada_fim_jogo : std_logic := '0';

    component Gowin_rPLL
        port (
            clkout: out std_logic;
            clkin: in std_logic
        );
    end component;

    signal pll_clkout : std_logic;
    
    component gato_colorido is
        port (
            dout: out std_logic_vector(17 downto 0);
            clk: in std_logic;
            oce: in std_logic;
            ce: in std_logic;
            reset: in std_logic;
            ad: in std_logic_vector(14 downto 0)
        );
    end component;

    signal s_saida_imagem : std_logic_vector(17 downto 0);
    signal s_imagem_clk, s_imagem_ce, s_imagem_oce, s_imagem_reset : std_logic;
    signal s_imagem_ad : std_logic_vector (14 downto 0);

    component  sprites is
        port (
            dout: out std_logic_vector(1 downto 0);
            clk: in std_logic;
            oce: in std_logic;
            ce: in std_logic;
            reset: in std_logic;
            ad: in std_logic_vector(14 downto 0)
        );
    end component;

    signal s_dout : std_logic_vector(1 downto 0);
    signal s_clk, s_ce, s_oce, s_reset : std_logic;
    signal s_ad : std_logic_vector(14 downto 0);

    signal s_entrada_pontuacao : integer := 0;
    signal permit : std_logic := '1';
    signal s_saida_reset : std_logic := '0';

    -- preferi colocar s_ na frente de cada porta de componente, depois só liguei as portas de cada componente
    -- depois trabalho com esses sinais seja para entrada ou pra saida
begin
    pll : Gowin_rPLL port map (clkout => pll_clkout, clkin => sys_clk);

    cmd : comandos_sequencia generic map (spi_master_clock_in => SYSTEM_CLK_IN, spi_master_clock_out => DATA_WRITE_CLK_OUT)
        port map (spi_clk_in => cmd_clk, seq_enable => cmd_seq_enable, cs_out => cmd_cs, sck => cmd_sck, mosi => cmd_mosi, dc => cmd_dc, out_btn_on => cmd_out_btn_on, free_buffer => cmd_free_buffer, reset => cmd_reset);
    
    data : memoria_para_display generic map (spi_input_clock => PLL_CLK_OUT, spi_output_clock => PLL_CLK_OUT) 
        port map (entrada_fim_jogo => s_entrada_fim_jogo, input_offset_y => s_input_offset_y, input_offset_x => s_input_offset_x, flash_address => s_flash_address, flash_data => s_flash_data, f_clk_in => s_f_clk_in, enable => s_enable, comando_escreve => s_comando_escreve, flash_oe => s_flash_oe, flash_we => s_flash_we, flash_reset => s_flash_reset, f_mosi => s_f_mosi, f_cs => s_f_cs, f_sck => s_f_sck, f_dc => s_f_dc);
    
    gato : gato_colorido port map (dout => s_saida_imagem, clk => s_imagem_clk, oce => s_imagem_oce, ce => s_imagem_ce, reset => s_imagem_reset, ad => s_imagem_ad);

    sprites0 : sprites port map (dout => s_dout, clk => s_clk, oce => s_oce, ce => s_ce, reset => s_reset, ad => s_ad);

    -- clock comandos
    cmd_clk <= sys_clk; -- when cmd_free_buffer = '0' else '0';
    -- clock dados
    s_f_clk_in <= pll_clkout; -- when cmd_free_buffer = '1' else '0';

    -- parametros da rom de sprites
    s_clk <= pll_clkout;
    s_oce <= '0';
    s_ce <= '1';
    s_reset <= '0';
    s_ad <= s_flash_address;

    -- parametros da rom de imagem
    s_imagem_clk <= pll_clkout;
    s_imagem_ce <= '1';
    s_imagem_oce <= '0';
    s_imagem_reset <= '0';
    s_imagem_ad <= s_flash_address;

    -- interface para botao de iniciar setup do display, ative se quiser o botao
    -- cmd_seq_enable <= start;
    -- interface para iniciar escrita de pixels apos liberacao do buffer
    s_comando_escreve <= cmd_free_buffer;

    process (sys_clk)
        variable conta : integer range SYSTEM_CLK_IN downto 0:= 1;
    begin
        if rising_edge(sys_clk) then
            if conta = SYSTEM_CLK_IN then
                cmd_seq_enable <= '1';
                conta := SYSTEM_CLK_IN;
                led_idle <= '0';
            else
                cmd_seq_enable <= '0';
                led_idle <= '1';
                conta := conta + 1;
            end if;
        end if;
    end process;

    -- controle de buffer
    top_cs <= cmd_cs when cmd_free_buffer = '0' else s_f_cs;
    top_mosi <= cmd_mosi when cmd_free_buffer = '0' else s_f_mosi;
    top_sck <= cmd_sck when cmd_free_buffer = '0' else s_f_sck;
    top_dc <= cmd_dc when cmd_free_buffer = '0' else s_f_dc;

    -- sinalização externa
    led_setup <= cmd_free_buffer;
    top_led_sck <= not cmd_sck when cmd_free_buffer = '0' else not s_f_sck;
    top_led_mosi <= not cmd_mosi when cmd_free_buffer = '0' else not s_f_mosi;
    -- aqui voce pode apertar para enviar outra frame, é um sinal ativo alto
    -- no entanto, optamos por deixar sendo escrito constatemente
    s_enable <= '1'; -- vram_write_cmd; 


    -- decode para reduzir memoria,o labirinto tem no maximo 3 cores
    s_flash_data <= "111111111111111111" when s_dout = "11" and s_entrada_fim_jogo = '0' else
                "000000000000000000" when s_dout = "00" and s_entrada_fim_jogo = '0' else 
                s_saida_imagem when s_entrada_fim_jogo = '1';

    -- IO para pontuação e fim de jogo
    saida_reset <= s_saida_reset;
    s_entrada_pontuacao <= to_integer(unsigned(entrada_pontuacao));

    -- limite de pontuação
    process (permit, sys_clk, s_entrada_pontuacao)
    begin
        if rising_edge(sys_clk) then
            if s_entrada_pontuacao = 9 then
                s_saida_reset <= '1';
                s_entrada_fim_jogo <= '1';
            end if;
        end if;
    end process;

    -- decode para offset dos sprites referente ao numero BCD
    process (s_entrada_pontuacao, s_input_offset_x, s_input_offset_y)
    begin
        case s_entrada_pontuacao is
        when 0 => 
            s_input_offset_x <= 0;
            s_input_offset_y <= 0;
        when 1 =>
            s_input_offset_x <= 16;
            s_input_offset_y <= 0;
        when 2 =>
            s_input_offset_x <= 32;
            s_input_offset_y <= 0;
        when 3 =>
            s_input_offset_x <= 48;
            s_input_offset_y <= 0;
        when 4 =>
            s_input_offset_x <= 64;
            s_input_offset_y <= 0;
        when 5 =>
            s_input_offset_x <= 80;
            s_input_offset_y <= 0;
        when 7 =>
            s_input_offset_x <= 0;
            s_input_offset_y <= 20;
        when 8 =>
            s_input_offset_x <= 16;
            s_input_offset_y <= 20;
        when 9 =>
            s_input_offset_x <= 32;
            s_input_offset_y <= 20;
        when 6 =>
            s_input_offset_x <= 48;
            s_input_offset_y <= 20;
        when others =>
            null;
        end case;
    end process;
end architecture;