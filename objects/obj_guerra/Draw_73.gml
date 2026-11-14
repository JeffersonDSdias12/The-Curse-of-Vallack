// FRENTE: brasas (fase 1) e cinzas (fase 2) por cima da cena (atrás do HUD)
if (view_camera[0] == -1) exit;
var _vx = camera_get_view_x(view_camera[0]);
var _vy = camera_get_view_y(view_camera[0]);
if (fase1)
{
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < array_length(brasas); _i++)
    {
        var _b = brasas[_i];
        var _a = clamp(_b.vida / 60, 0, 1) * clamp((_b.vmax - _b.vida) / 30, 0, 1);
        var _piscar = 0.6 + 0.4 * sin(t / 6 + _b.fase * 3);
        draw_set_color(make_color_rgb(255, 150, 60));
        draw_set_alpha(0.85 * _a * _piscar);
        draw_circle(_vx + _b.x, _vy + _b.y, _b.r, false);
        draw_set_color(make_color_rgb(255, 90, 30));
        draw_set_alpha(0.15 * _a);
        draw_circle(_vx + _b.x, _vy + _b.y, _b.r * 3, false);
    }
    gpu_set_blendmode(bm_normal);
}
else
{
    draw_set_color(make_color_rgb(170, 160, 156));
    for (var _i = 0; _i < array_length(brasas); _i++)
    {
        var _b = brasas[_i];
        draw_set_alpha(0.5 * clamp(_b.vida / 80, 0, 1) * clamp((_b.vmax - _b.vida) / 40, 0, 1));
        draw_circle(_vx + _b.x, _vy + _b.y, _b.r, false);
    }
}
draw_set_alpha(1);
draw_set_color(c_white);
