var _tx = (tremor > 0) ? random_range(-tremor, tremor) * 0.3 : 0;
if (flash > 0)
{
    gpu_set_fog(true, make_color_rgb(255, 230, 190), 0, 0);
    draw_sprite_ext(sprite_index, image_index, x + _tx, y, 1, 1, 0, c_white, 1);
    gpu_set_fog(false, c_white, 0, 0);
}
else draw_sprite_ext(sprite_index, image_index, x + _tx, y, 1, 1, 0, c_white, 1);
// brilho dourado nas frestas: tem um baú de vida dentro
if (conteudo == "bau")
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.25 + 0.15 * sin(current_time / 220));
    draw_set_color(make_color_rgb(255, 190, 80));
    draw_rectangle(x - 13, y - 17, x + 13, y - 15, false);
    draw_rectangle(x - 13, y - 8, x + 13, y - 7, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
