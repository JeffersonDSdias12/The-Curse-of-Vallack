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
// v1.14: o baú do forte guarda a CHAVE DO PORTÃO e fica selado (correntes de magia)
// até os guardiões caírem (obj_terreno)
conteudo = "vida";         // "vida" ou "chave"
selado = false;
selo_quebra = 0;           // brilho quando o selo se parte
chave_voo = -1;            // a chave subindo do baú e voando até Twilight (quadros)
chave = aberto_chave("bau", xstart, ystart);
if (aberto_tem(chave))
{
    estado = "aberto";
    image_index = 3;
}
