// obj_poca_veneno — poça de veneno (v1.12): queima quem pisa nela (4 de
// dano por segundo) por 4 s. Rolando, Twilight passa sem se ferir.
vida = 240;
t = 0;
larg = 34;
dano = max(1, round(4 * dif_dano_inimigo()));
semente = random(100);
