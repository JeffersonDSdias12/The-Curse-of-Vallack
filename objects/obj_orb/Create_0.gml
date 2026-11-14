// =====================================================================
//  obj_orb — orb vermelha de alma (solta por inimigos, caixotes e segredos)
//  Salta um pouco e depois voa sozinha até Twilight.
// =====================================================================
valor = 1;
tipo = "alma";             // v1.17: "alma" (vermelha, orbs) ou "vida" (verde, cura ao chegar)
vx = 0;
vy = -3;
espera = 20;               // quadros quicando antes de voar até o jogador
t = 0;
fase = random(100);
rastro = [];
