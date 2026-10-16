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
        tutorial_mostrar(TUT.GUARDIAO);
        recarga = 50;
        onda_tempo = 0;              // 3,5 s até a primeira onda
        sprite_index = spr_boss_01_parado;
        image_index = 0;
        image_speed = 1;
    break;
    case "atacando":
    case "invocando":
    case "raizes":
        if (estado_ia == "atacando") recarga = recarga_max;     // tempo até a próxima bola de fogo
        else recarga = max(recarga, 40);
        estado_ia = "parado";
        sprite_index = spr_boss_01_parado;
        image_index = 0;
        image_speed = 1;
    break;
}
