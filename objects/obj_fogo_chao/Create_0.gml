// =====================================================================
//  obj_fogo_chao — fogo no chão (destroços da vila queimando)
//  Sempre queima baixo; de tempos em tempos as chamas sobem (mais dano).
//  image_xscale da instância na sala = largura em blocos de 32 px.
// =====================================================================
larg = 32 * max(1, image_xscale);
image_xscale = 1;
t = (x mod 131);
forte = 0;
atingidos = [];
semente = random(100);
visible = true;
