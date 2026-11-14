// =====================================================================
//  obj_muralha_fundo — muralha do castelo AO FUNDO, sem colisão (v1.11)
//  Mesmo jeito de usar da obj_muralha (origem embaixo à esquerda, escala
//  = pedras). Com 3 ou mais pedras de altura ganha ameias; torres de até
//  3 pedras de largura e 6 ou mais de altura ganham seteiras acesas.
//  Com 1 ou 2 pedras de altura vira uma mureta (sem ameias).
// =====================================================================
cenario_medidas();
image_speed = 0;
depth = 252;
tom = cenario_tom_fundo();
tipo = "fundo";
