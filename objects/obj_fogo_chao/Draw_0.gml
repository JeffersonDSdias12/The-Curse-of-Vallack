// brasas e carvão no chão
draw_set_color(make_color_rgb(30, 18, 14));
draw_set_alpha(0.85);
draw_ellipse(x - larg / 2 - 4, y - 4, x + larg / 2 + 4, y + 3, false);
draw_set_alpha(1);
desenhar_chamas(x, y, larg, 48, current_time / 16, forte, semente);
if (global.debug_hitbox)
{
    draw_set_color(c_orange);
    draw_rectangle(x - larg / 2, y - 40 * forte, x + larg / 2, y, true);
}
