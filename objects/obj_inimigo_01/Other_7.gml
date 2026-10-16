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

// fim do golpe: volta a perseguir e espera a recarga
if (estado_ia == "atacar" and sprite_index == spr_ia_ataque)
{
    estado_ia = "perseguir";
    golpe_dado = false;
    recarga = recarga_max + irandom(24);
    trocar_sprite(spr_ia_parado, 1);
    exit;
}

// fim da aterrissagem do pulo: se caiu perto, ataca logo em seguida
if (sprite_index == spr_ia_pular)
{
    if (estado_ia == "pular_pouso")
    {
        estado_ia = "perseguir";
        recarga = min(recarga, 6);
        trocar_sprite(spr_ia_parado, 1);
    }
    else if (estado_ia == "pular_ar") image_index = 5;
}
