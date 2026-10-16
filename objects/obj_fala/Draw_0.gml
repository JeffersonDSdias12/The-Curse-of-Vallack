// balão: aparece com um "pulo", flutua e some
var _in = clamp(t / 8, 0, 1);
var _out = clamp(vida / 12, 0, 1);
var _a = min(_in, _out);
var _esc = 0.42 * (0.8 + 0.2 * (1 - power(1 - _in, 3)));
gpu_set_texfilter(true);
var _w = txt_largura(texto, FONTE.PEQUENA, _esc) + 12;
var _h = 18;
var _bx = ax;
var _by = ay - 16 - t * 0.04;
// não sai da tela pelos lados
if (view_camera[0] != -1)
{
    var _cvx = camera_get_view_x(view_camera[0]);
    var _cvw = camera_get_view_width(view_camera[0]);
    _bx = clamp(_bx, _cvx + _w / 2 + 4, _cvx + _cvw - _w / 2 - 4);
}
draw_set_alpha(_a * 0.55);
draw_set_color(c_black);
draw_roundrect_ext(_bx - _w / 2 + 2, _by - _h + 2, _bx + _w / 2 + 2, _by + 2, 8, 8, false);
draw_set_alpha(_a * 0.92);
draw_set_color(make_color_rgb(236, 222, 190));
draw_roundrect_ext(_bx - _w / 2, _by - _h, _bx + _w / 2, _by, 8, 8, false);
draw_triangle(ax - 4, _by - 1, ax + 4, _by - 1, ax, _by + 6, false);
draw_set_color(make_color_rgb(90, 40, 30));
draw_roundrect_ext(_bx - _w / 2, _by - _h, _bx + _w / 2, _by, 8, 8, true);
txt(_bx, _by - _h / 2, texto, FONTE.PEQUENA, cor, _a, fa_center, fa_middle, _esc);
gpu_set_texfilter(false);
desenho_resetar();
