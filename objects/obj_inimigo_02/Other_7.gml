// ===== ANIMATION END =====
if (!ativo) exit;
if (morrendo)
{
    if (sprite_index == spr_morrer)
    {
        image_index = image_number - 1;
        image_speed = 0;
        morte_fim = true;
    }
    exit;
}

if (estado_ia == "atirar" and sprite_index == spr_ia_ataque)
{
    estado_ia = "parado";
    recarga = recarga_max;            // 5 s até a próxima flecha
    trocar_sprite(spr_ia_parado, 1);
    exit;
}

if (sprite_index == spr_ia_dano and atordoado <= 0)
{
    trocar_sprite(spr_ia_parado, 1);
}
