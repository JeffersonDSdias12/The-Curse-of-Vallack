// ===== ANIMATION END =====
if (morrendo)
{
    image_index = image_number - 1;
    image_speed = 0;
    exit;
}
switch (estado_ia)
{
    case "despertar":
        estado_ia = "parado";
        acordado = true;
        recarga = 50;
        onda_tempo = 0;
        sprite_index = spr_parado;
        image_index = 0;
        image_speed = 1;
    break;
    case "atacando":
    case "invocando":
    case "raizes":
    case "galho":
    case "chuva":
    case "transicao":
        if (estado_ia == "atacando") recarga = recarga_max;     // tempo até a próxima bola de fogo
        else recarga = max(recarga, (fase >= 3) ? 20 : ((fase == 2) ? 30 : 40));   // v1.19: menos respiro nas fases 2 e 3
        estado_ia = "parado";
        sprite_index = spr_parado;
        image_index = 0;
        image_speed = 1;
    break;
}
