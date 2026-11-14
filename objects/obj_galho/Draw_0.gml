if (estado == "aviso")
{
    var _k = t / 60;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.15 + 0.35 * _k * (0.6 + 0.4 * sin(t / 3)));
    draw_set_color(make_color_rgb(190, 80, 255));
    draw_rectangle(min(x_base, x_fim), y_chao - 6, max(x_base, x_fim), y_chao + 2, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    gpu_set_texfilter(true);
    var _pa = 0.6 + 0.4 * sin(t / 4);
    txt_sombra(lerp(x_base, x_fim, 0.25), y_chao - 46, "!", FONTE.GRANDE, make_color_rgb(255, 120, 230), _pa, fa_center, fa_bottom, 0.9);
    txt_sombra(lerp(x_base, x_fim, 0.5), y_chao - 46, "!", FONTE.GRANDE, make_color_rgb(255, 120, 230), _pa, fa_center, fa_bottom, 0.9);
    txt_sombra(lerp(x_base, x_fim, 0.75), y_chao - 46, "!", FONTE.GRANDE, make_color_rgb(255, 120, 230), _pa, fa_center, fa_bottom, 0.9);
    gpu_set_texfilter(false);
    desenho_resetar();
    exit;
}
var _x1 = x_base;
var _x2 = ponta;
var _n = max(2, ceil(abs(_x2 - _x1) / 24));
for (var _i = 0; _i < _n; _i++)
{
    var _a = _i / _n;
    var _b = (_i + 1) / _n;
    var _xa = lerp(_x1, _x2, _a);
    var _xb = lerp(_x1, _x2, _b);
    var _wa = lerp(16, 6, _a);
    var _wb = lerp(16, 6, _b);
    var _ya = y_chao - alt * 0.45 + sin(_a * 9 + semente) * 3;
    var _yb = y_chao - alt * 0.45 + sin(_b * 9 + semente) * 3;
    draw_set_color(make_color_rgb(72, 46, 32));
    draw_triangle(_xa, _ya - _wa, _xa, _ya + _wa, _xb, _yb + _wb, false);
    draw_triangle(_xa, _ya - _wa, _xb, _yb - _wb, _xb, _yb + _wb, false);
    draw_set_color(make_color_rgb(116, 76, 50));
    draw_line(_xa, _ya - _wa * 0.5, _xb, _yb - _wb * 0.5);
    if (_i mod 2 == 0)
    {
        draw_set_color(make_color_rgb(50, 30, 20));
        draw_triangle(_xa, _ya - _wa, _xa + 4, _ya - _wa, _xa + 2, _ya - _wa - 8, false);
    }
}
gpu_set_blendmode(bm_add);
draw_set_alpha(0.5);
draw_set_color(make_color_rgb(180, 70, 255));
draw_circle(_x2, y_chao - alt * 0.45, 14, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
