// =====================================================================
//  obj_galho — GALHO VARREDOR da Árvore Amaldiçoada (v1.12, fases 2 e 3)
//  aviso (1 s: o chão da arena brilha e aparecem os "!") -> o galho varre
//  a arena rente ao chão -> recolhe. Não dá para defender: PULE ou ROLE.
// =====================================================================
dono = noone;
dir = -1;
x_base = x;
x_fim = x - 600;
ponta = x;
estado = "aviso";
t = 0;
vel = 13;
dano = 14;
atingiu = false;
y_chao = y;
alt = 34;
semente = random(100);
som_em("galho_aviso", x, y, 1);
