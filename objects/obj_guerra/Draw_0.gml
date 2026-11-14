// FUNDO: céu de guerra atrás do chão e dos personagens
if (!fase1 or view_camera[0] == -1) exit;
var _cam = view_camera[0];
var _vx = camera_get_view_x(_cam);
var _vy = camera_get_view_y(_cam);
var _vw = camera_get_view_width(_cam);
var _vh = camera_get_view_height(_cam);
gpu_set_blendmode(bm_add);

// incêndios distantes: brilho pulsando perto do horizonte
draw_set_color(make_color_rgb(255, 90, 30));
for (var _k = 0; _k < 3; _k++)
{
    var _gx = _vx + _vw * (0.18 + 0.32 * _k) + sin(t / 300 + _k) * 20;
    var _pulso = 0.5 + 0.5 * sin(t / (38 + _k * 9) + _k * 2);
    draw_set_alpha(0.05 + 0.04 * _pulso);
    draw_ellipse(_gx - 120, _vy + _vh * 0.47, _gx + 120, _vy + _vh * 0.62, false);
}
// clarões das bolas de catapulta caindo atrás das colinas
for (var _i = 0; _i < array_length(claroes); _i++)
{
    var _c = claroes[_i];
    var _p = _c.vida / _c.vmax;
    draw_set_color(make_color_rgb(255, 150, 70));
    draw_set_alpha(0.35 * _p);
    draw_ellipse(_vx + _c.x - 140, _vy + _vh * 0.42, _vx + _c.x + 140, _vy + _vh * 0.66, false);
    draw_set_color(make_color_rgb(255, 230, 180));
    draw_set_alpha(0.4 * _p);
    draw_ellipse(_vx + _c.x - 50, _vy + _vh * 0.5, _vx + _c.x + 50, _vy + _vh * 0.6, false);
}
// flechas incendiárias: risco claro com rastro de fogo
for (var _i = 0; _i < array_length(flechas); _i++)
{
    var _f = flechas[_i];
    var _px = _vx + _f.x;
    var _py = _vy + _f.y;
    var _len = max(0.001, point_distance(0, 0, _f.vx, _f.vy));
    var _ddx = _f.vx / _len;
    var _ddy = _f.vy / _len;
    draw_set_color(make_color_rgb(255, 120, 40));
    draw_set_alpha(0.45);
    draw_line_width(_px - _ddx * 16, _py - _ddy * 16, _px, _py, 1.6);
    draw_set_color(make_color_rgb(255, 236, 190));
    draw_set_alpha(0.9);
    draw_line_width(_px - _ddx * 5, _py - _ddy * 5, _px + _ddx * 2, _py + _ddy * 2, 1.2);
    draw_set_color(make_color_rgb(255, 170, 70));
    draw_set_alpha(0.6);
    draw_circle(_px, _py, 2.2, false);
}
// bolas de fogo de catapulta
for (var _i = 0; _i < array_length(bolas); _i++)
{
    var _b = bolas[_i];
    var _bx = _vx + _b.x;
    var _by = _vy + _b.y;
    var _len2 = max(0.001, point_distance(0, 0, _b.vx, _b.vy));
    var _d2x = _b.vx / _len2;
    var _d2y = _b.vy / _len2;
    for (var _k = 0; _k < 5; _k++)
    {
        draw_set_color(make_color_rgb(255, 110 + _k * 10, 40));
        draw_set_alpha(0.5 - _k * 0.08);
        draw_circle(_bx - _d2x * _k * 5, _by - _d2y * _k * 5, 5.5 - _k, false);
    }
    draw_set_color(make_color_rgb(255, 240, 200));
    draw_set_alpha(0.9);
    draw_circle(_bx, _by, 3, false);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
