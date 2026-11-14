var _a = clamp(min(t / 10, (vida - t) / 40), 0, 1);
draw_set_alpha(0.75 * _a);
draw_set_color(make_color_rgb(40, 90, 30));
draw_ellipse(x - larg, y - 5, x + larg, y + 3, false);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.3 * _a);
draw_set_color(make_color_rgb(110, 220, 70));
draw_ellipse(x - larg * 0.8, y - 4, x + larg * 0.8, y + 2, false);
for (var _k = 0; _k < 4; _k++)
{
    var _f = frac(t / 70 + _k / 4 + semente);
    draw_set_alpha((1 - _f) * 0.5 * _a);
    draw_circle(x + sin(_k * 2.7 + semente) * larg * 0.6, y - 2 - _f * 26, 1.5 + 2 * (1 - _f), false);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
