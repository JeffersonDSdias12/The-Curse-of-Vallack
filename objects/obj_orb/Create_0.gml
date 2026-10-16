// =====================================================================
//  obj_orb — orb vermelha de alma (solta por inimigos, caixotes e segredos)
//  Salta um pouco e depois voa sozinha até Twilight.
// =====================================================================
valor = 1;
vx = 0;
vy = -3;
espera = 20;               // quadros quicando antes de voar até o jogador
t = 0;
fase = random(100);
rastro = [];
