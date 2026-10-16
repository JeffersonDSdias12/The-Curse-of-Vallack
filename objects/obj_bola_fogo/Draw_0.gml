var _e = explodindo ? escala * 1.35 : escala;
gpu_set_blendmode(bm_add);
if (!explodindo)
{
    draw_set_alpha(0.35);
    draw_set_color(make_color_rgb(255, 110, 30));
    draw_circle(x, y, 15, false);
}
else
{
    // mostra a área de dano da explosão
    var _p = clamp((image_index - 7) / 3, 0, 1);
    draw_set_alpha(0.45 * (1 - _p));
    draw_set_color(make_color_rgb(255, 120, 40));
    draw_circle(x, y, raio_explosao * (0.4 + 0.6 * _p), false);
    draw_set_alpha(0.8 * (1 - _p));
    draw_circle(x, y, raio_explosao * (0.4 + 0.6 * _p), true);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_sprite_ext(sprite_index, image_index, x, y, _e, _e, explodindo ? 0 : ang, c_white, 1);
if (global.debug_hitbox)
{
    draw_set_color(c_orange);
    draw_circle(x, y, raio_explosao, true);
}
draw_set_color(c_white);
