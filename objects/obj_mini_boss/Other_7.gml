// ===== ANIMATION END =====
if (morrendo)
{
    if (sprite_index == spr_morrer) { image_index = image_number - 1; image_speed = 0; morte_fim = true; }
    exit;
}
if (estado_ia == "atacar" and sprite_index == spr_ia_ataque)
{
    acoes += 1;
    recarga = enfurecido ? 24 : 44;
    mudar("perseguir");
    trocar_sprite(spr_ia_parado, 1);
}
else if (estado_ia == "salto_pouso" and sprite_index == spr_ia_pular)
{
    recarga = enfurecido ? 20 : 36;
    mudar("perseguir");
    trocar_sprite(spr_ia_parado, 1);
}
