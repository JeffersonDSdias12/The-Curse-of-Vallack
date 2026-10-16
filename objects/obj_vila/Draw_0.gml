// incêndio nas casas do fundo (só as que aparecem na tela)
var _vx = 0;
var _vw = 2000;
if (view_camera[0] != -1) { _vx = camera_get_view_x(view_camera[0]); _vw = camera_get_view_width(view_camera[0]); }
var _t = current_time / 16;
for (var _i = 0; _i < array_length(casas); _i++)
{
    var _c = casas[_i];
    if (_c.x < _vx - _c.l or _c.x > _vx + _vw + _c.l) continue;
    var _pisca = 0.75 + 0.25 * sin(_t / 4 + _c.semente) * sin(_t / 9.3 + _c.semente * 2);
    // brilho do incêndio na casa e no céu
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.13 * _pisca);
    draw_set_color(make_color_rgb(255, 90, 20));
    draw_ellipse(_c.x - _c.l * 0.9, _c.y - 90, _c.x + _c.l * 0.9, _c.y + 110, false);
    draw_set_alpha(0.2 * _pisca);
    draw_set_color(make_color_rgb(255, 120, 40));
    draw_ellipse(_c.x - _c.l * 0.55, _c.y - 10, _c.x + _c.l * 0.55, _c.y + 80, false);
    // janelas acesas por dentro (faixa do andar de cima)
    draw_set_alpha(0.35 * _pisca);
    draw_set_color(make_color_rgb(255, 150, 50));
    draw_rectangle(_c.x - _c.l * 0.38, _c.y + 40, _c.x + _c.l * 0.38, _c.y + 52, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    // chamas no telhado
    desenhar_chamas(_c.x - _c.l * 0.12, _c.y + 18, _c.l * 0.62, 34, _t, 0.9, _c.semente);
    desenhar_chamas(_c.x + _c.l * 0.22, _c.y + 24, _c.l * 0.4, 26, _t + 37, 0.8, _c.semente + 5);
}
