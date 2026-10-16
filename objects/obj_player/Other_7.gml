// ===== ANIMATION END =====
// Os golpes não usam este evento: a animação deles é tocada pela tabela de
// quadros (scr_combate), que termina o golpe no tempo exato.
if (sprite_index == spr_player_dano)
{
    machucado = false;
    trocar_animacao(spr_player_idle, 1);
}
else if (sprite_index == spr_player_morte)
{
    image_index = image_number - 1;
    image_speed = 0;
}
