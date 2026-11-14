if (!cenario_na_tela(x - larg * 2, x + larg * 2)) exit;
for (var _i = 0; _i < 14; _i++)
{
    var _fy = y - (_i / 13) * alt;
    var _ox = sin(t / 30 + _i * 1.3) * larg * 0.35;
    var _r = larg * (0.7 + 0.25 * sin(t / 40 + _i));
    draw_set_alpha(0.16);
    draw_set_color(make_color_rgb(60, 130, 45));
    draw_circle(x + _ox, _fy, _r, false);
}
gpu_set_blendmode(bm_add);
draw_set_alpha(0.12);
draw_set_color(make_color_rgb(120, 255, 90));
draw_ellipse(x - larg * 1.2, y - alt, x + larg * 1.2, y + 4, false);
for (var _k = 0; _k < 6; _k++)
{
    var _f = frac(t / 120 + _k / 6);
    draw_set_alpha(0.5 * (1 - _f));
    draw_circle(x + sin(_k * 2.3 + t / 50) * larg * 0.6, y - _f * alt, 1.5 + 2.5 * (1 - _f), true);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
desenho_resetar();
