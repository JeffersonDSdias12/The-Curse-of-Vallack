// =====================================================================
//  obj_muralha — muralha de pedra SÓLIDA (v1.11)
//  Na sala: origem embaixo à esquerda. Escala X = largura em pedras de
//  32 px; Escala Y = altura em pedras (3 x 2 = 3 pedras de largura e 2
//  de altura). Jogador e inimigos sobem e andam em cima. Não quebra.
//  Não conta como chão principal para a chuva (scr_globais).
// =====================================================================
cenario_medidas();
image_speed = 0;
depth = 155;            // atrás do mato e dos caixotes, na frente das muralhas do fundo
tom = c_white;
solido = solido_criar(x, y - 32 * linhas + 3, x + 32 * colunas, y);
