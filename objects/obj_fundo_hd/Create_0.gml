// =====================================================================
//  obj_fundo_hd — fundo da fase 1 em alta definição
//  A camada de tiles "fundo" (16x16, ampliada ~2,6x na tela) ficava
//  serrilhada. A spr_fundo_hd é a mesma imagem ampliada 1,25x com filtro
//  Lanczos e nitidez, desenhada por cima da camada original com suavização.
//  Ela cobre a faixa que a câmera mostra (y >= 280); acima disso continua a
//  camada original, que nunca foi apagada.
//  OPÇÕES > FUNDO HD desliga e volta ao fundo original.
// =====================================================================
escala_hd = 1.25;      // a spr_fundo_hd é 1,25x maior que o mundo
y0 = 280;              // primeira linha do mundo coberta pela spr_fundo_hd
margem = 2;            // px extras de cada lado dos quadros (sem emendas)
larg_q = sprite_get_width(spr_fundo_hd) - 2 * margem;

if (!global.cfg_fundo_hd) instance_destroy();
