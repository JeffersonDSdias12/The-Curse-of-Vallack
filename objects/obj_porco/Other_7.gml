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

switch (estado_ia)
{
    case "atacar":
        if (sprite_index == spr_ia_ataque)
        {
            estado_ia = "perseguir";
            golpe_dado = false;
            recarga = round(recarga_max * (furioso ? 0.7 : 1)) + irandom(20);
            trocar_sprite(spr_ia_parado, 1);
        }
    break;

    case "onda":
        if (sprite_index == spr_porco_roxo)
        {
            estado_ia = "perseguir";
            recarga_onda = round(recarga_onda_max * (furioso ? 0.7 : 1)) + irandom(60);
            recarga = max(recarga, 30);
            trocar_sprite(spr_ia_parado, 1);
        }
    break;

    case "salto_pouso":
        if (sprite_index == spr_porco_salto)
        {
            estado_ia = "perseguir";
            recarga_salto = round(recarga_salto_max * (furioso ? 0.7 : 1)) + irandom(60);
            recarga = min(recarga, 10);
            trocar_sprite(spr_ia_parado, 1);
        }
    break;

    case "salto_prep":
    case "salto_ar":
        if (sprite_index == spr_porco_salto) image_index = 5;
    break;

    case "rugir":
        if (sprite_index == spr_porco_furia)
        {
            estado_ia = "invocar";
            sprite_index = spr_porco_invocar;
            image_index = 0;
            image_speed = 0.8;
        }
    break;

    case "invocar":
        if (sprite_index == spr_porco_invocar)
        {
            if (!invocou) { invocou = true; porco_invocar(); }
            // em fúria: mais rápido e com menos espera entre os golpes
            furioso = true;
            vel_correr = 2.5;
            estado_ia = "perseguir";
            recarga = 10;
            trocar_sprite(spr_ia_parado, 1);
        }
    break;
}
