// =====================================================================
//  obj_parede_magica — muralha mágica que fecha a arena do mini-boss e
//  do boss. Ninguém entra nem sai: quem encosta é jogado de volta.
//  Criada por arena_fechar() (scr_cenario).
// =====================================================================
dono = noone;
lado = -1;                // -1 = muralha da esquerda, 1 = da direita
ativa = false;
estado = "parada";        // subindo -> ativa -> descendo
sobe = 0;
altura = 300;
solido = noone;
choque = 0;               // brilho quando alguém bate nela
t = 0;

parede_erguer = function()
{
    estado = "subindo";
    ativa = true;
    if (solido == noone) solido = solido_criar(x - 9, y - altura, x + 9, y);
};
parede_baixar = function()
{
    if (estado == "descendo") return;
    estado = "descendo";
    ativa = false;
    solido_remover(solido);
    solido = noone;
};
