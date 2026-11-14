if (atraso > 0) exit;
var _tt = current_time / 16;
if (estado == "aviso")
{
    // v1.12: coluna de luz roxa onde a raiz vai sair + rachadura + "!"
    var _k = clamp(t / aviso_t, 0, 1);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.12 + 0.25 * _k);
    draw_set_color(make_color_rgb(150, 40, 255));
    draw_rectangle(x - meia * (0.5 + 0.5 * _k), y - alt * 1.3, x + meia * (0.5 + 0.5 * _k), y, false);
    draw_set_alpha(0.4 + 0.5 * _k);
    draw_set_color(make_color_rgb(200, 90, 255));
    draw_ellipse(x - 22 * _k - 6, y - 4, x + 22 * _k + 6, y + 3, false);
    draw_line_width(x - 20, y - 1, x + 20, y, 2);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    var _pa = 0.6 + 0.4 * sin(_tt * 0.6);
    gpu_set_texfilter(true);
    txt_sombra(x, y - alt * 1.3 - 4, "!", FONTE.GRANDE, make_color_rgb(230, 120, 255), _pa, fa_center, fa_bottom, 0.7 + 0.2 * _k);
    gpu_set_texfilter(false);
    exit;
}
// raiz retorcida (vários segmentos afinando para cima)
var _h = alt * sobe;
var _seg = 9;
for (var _i = 0; _i < _seg; _i++)
{
    var _a1 = _i / _seg;
    var _a2 = (_i + 1) / _seg;
    var _ox1 = sin(_a1 * 5 + semente) * 7 * _a1;
    var _ox2 = sin(_a2 * 5 + semente) * 7 * _a2;
    var _w1 = meia * (1 - _a1 * 0.85);
    var _w2 = meia * (1 - _a2 * 0.85);
    var _y1 = y - _h * _a1;
    var _y2 = y - _h * _a2;
    draw_set_color(make_color_rgb(58, 34, 24));
    draw_triangle(x + _ox1 - _w1, _y1, x + _ox1 + _w1, _y1, x + _ox2 + _w2, _y2, false);
    draw_triangle(x + _ox1 - _w1, _y1, x + _ox2 - _w2, _y2, x + _ox2 + _w2, _y2, false);
    draw_set_color(make_color_rgb(110, 66, 40));
    draw_line(x + _ox1 - _w1 * 0.4, _y1, x + _ox2 - _w2 * 0.4, _y2);
}
// contorno roxo da maldição (para destacar a raiz do fundo escuro)
gpu_set_blendmode(bm_add);
draw_set_alpha(0.35 * sobe);
draw_set_color(make_color_rgb(150, 40, 255));
draw_rectangle(x - meia - 2, y - _h, x + meia + 2, y, true);
draw_set_alpha(0.7 * sobe);
draw_set_color(make_color_rgb(200, 90, 255));
draw_circle(x + sin(5 + semente) * 7, y - _h, 5 + sin(_tt / 4), false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
