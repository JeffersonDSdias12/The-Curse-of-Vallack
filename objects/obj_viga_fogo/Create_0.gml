// =====================================================================
//  obj_viga_fogo — viga em chamas que cai do telhado de uma casa
//  Colocada no ponto do chão onde cai. Quando Twilight se aproxima:
//  aviso (poeira e brasas caindo, sombra no chão) -> queda -> pegando
//  fogo no chão por alguns segundos -> apaga.
// =====================================================================
estado = "esperando";
t = 0;
y_chao = y;
y_viga = y - 320;
vy = 0;
ang = random_range(-10, 10);
atingidos = [];
queima = 0;               // tempo pegando fogo no chão
semente = random(100);
dist_ativar = 150;        // distância do jogador que derruba a viga
