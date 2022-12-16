# ILI9341_vhdl
Driver para display ILI9341, lendo sprites a partir de frame buffer. Mostrando número BCD até numero escolhido, para mostrar imagem maior. No Quartus, as funções de pontuação podem ser usadas ao ser criado um bloco adicional no arquivo .bdf, ou seja, no quartus o foco é somente mandar a imagem constantemente.

TODO:
- Melhorar a aparência do esquema no Quartus
- Remover pinos desnecessários
- Separar blocos de spi e comandos para serem reutilizados por fora
- Melhorar qualidade de sinais de clock, permitindo mais altas frequências, refazendo os divisores da forma mais adequada

O seguinte trecho no arquivo top_gowin_ide permite mudar a pontuação que ativa a tela de vitória

```vhdl
process (permit, sys_clk, s_entrada_pontuacao)
begin
    if rising_edge(sys_clk) then
        if s_entrada_pontuacao = 9 then
            s_saida_reset <= '1';
            s_entrada_fim_jogo <= '1';
        end if;
    end if;
end process;
```

IDE do Quartus: dependendo do FPGA a imagem pode não caber, além disso, ao trocar a resolução é necessário trocar a constante de linha no final do arquivo memoria_para_dsiaplay no trecho: 

```vhdl
-- mudar para o valor de linha ao redimensionar a imagem
-- no momento o modo é 120x160, então precisa colocar 120
signal constante_de_linha : integer range 320 downto 0 := 60;
```
O padrão deve ser 60, pois a resolução é 60x80, além disso, alterar escala no trecho:
```vhdl
-- seletor de escala com base no fim de jogo
escala <= 4 when (s_entrada_fim_jogo = '1') else 16;
```
