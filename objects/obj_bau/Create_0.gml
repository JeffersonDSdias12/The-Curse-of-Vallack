// =====================================================================
//  obj_bau — BAÚ DE VIDA
//  * INTERAGIR perto dele: a tampa abre, sai um brilho e a magia flui
//    do baú até Twilight, curando aos poucos
//  * pode ficar escondido dentro de um caixote (aparece quando ele quebra)
//  * abre uma única vez (fica gravado no save)
// =====================================================================
sprite_index = spr_bau;
image_speed = 0;
image_index = 0;
estado = "fechado";        // fechado -> abrindo -> aberto
visivel = true;
revelar_t = 0;
t = 0;
alvo = noone;
magia = [];                // partículas de magia indo até o jogador
magia_soltas = 0;
cura_total = dif_valor([70, 55, 45, 35]);
chave = aberto_chave("bau", xstart, ystart);
if (aberto_tem(chave))
{
    estado = "aberto";
    image_index = 3;
}
