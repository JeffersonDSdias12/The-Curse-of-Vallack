// =====================================================================
//  obj_magia — projéteis de magia dos inimigos novos (v1.8)
//  tipo "orbe"  Estátua Enfeitiçada: persegue Twilight por um instante;
//               a defesa segura, aparar devolve (racha a estátua)
//  tipo "teia"  Mulher-Aranha: voa em arco e PRENDE Twilight; no chão
//               vira uma armadilha pegajosa; aparar devolve (prende a aranha)
//  tipo "onda"  Porco Corrompido: corte roxo rente ao chão; não dá para
//               defender (pule por cima ou role através dela)
// =====================================================================
tipo = "orbe";
vx = 0;
vy = 0;
dano = 5;
dono = noone;
alcance = 900;
dist = 0;
t = 0;
ang = 180;
escala = 0.8;
refletida = false;
estado = "voando";       // voando, chao (teia grudada), fim (estourando)
fim_t = 0;
vida_chao = 0;
atingiu = false;         // a onda acerta Twilight uma vez só
image_speed = 0;

estourar = function()
{
    if (estado == "fim") return;
    estado = "fim";
    fim_t = 0;
    vx = 0;
    vy = 0;
    if (tipo == "orbe") som_em("fogo_explosao", x, y, 0.45);
    else if (tipo == "onda") fx_em("poeira", x, y, 0.5);
};
