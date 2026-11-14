// =====================================================================
//  obj_morador — morador da vila (v1.12)
//  Quando Twilight chega perto, conversa com ele (pede ajuda e explica o
//  fogo roxo de Vallack) e foge para a ponte do norte. Assim a vila fica
//  sem civis no meio das lutas. A conversa acontece uma vez (fica no save).
// =====================================================================
sprite_index = spr_morador_parado;
image_speed = 1;
estado = "parado";          // parado -> conversando -> fugindo
dir = 1;
depth = 120;
chave = aberto_chave("morador", xstart, ystart);
if (aberto_tem(chave)) { instance_destroy(); exit; }
