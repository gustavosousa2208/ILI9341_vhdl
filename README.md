# ILI9341_vhdl
Driver para display ILI9341, lê sprites a partir de frame buffer (bloco de RAM). Mostrando contagem de número BCD até um número máximo escolhido. 
Projeto criado como trabalho de conclusão da disciplina de Técnicas Avançadas em Eletrônica Digital (TAED), apenas parte do contador, fazendo uso do display, como sugerido pelo professor, pode ser aplicado para qualquer minigame com saída de número binário.

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
