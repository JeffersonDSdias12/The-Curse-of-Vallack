if (atraso > 0) exit;
var _tt = current_time / 16;
if (estado == "aviso")
{
    // rachadura brilhando no chão
    var _k = t / 44;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.3 + 0.5 * _k);
    draw_set_color(make_color_rgb(255, 70, 30));
    draw_ellipse(x - 18 * _k - 4, y - 3, x + 18 * _k + 4, y + 2, false);
    draw_line_width(x - 16, y - 1, x + 16, y, 2);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    exit;
}
// raiz retorcida (vários segmentos afinando para cima)
var _h = 64 * sobe;
var _seg = 8;
for (var _i = 0; _i < _seg; _i++)
{
    var _a1 = _i / _seg;
    var _a2 = (_i + 1) / _seg;
    var _ox1 = sin(_a1 * 5 + semente) * 5 * _a1;
    var _ox2 = sin(_a2 * 5 + semente) * 5 * _a2;
    var _w1 = 12 * (1 - _a1 * 0.85);
    var _w2 = 12 * (1 - _a2 * 0.85);
    var _y1 = y - _h * _a1;
    var _y2 = y - _h * _a2;
    draw_set_color(make_color_rgb(58, 34, 24));
    draw_triangle(x + _ox1 - _w1, _y1, x + _ox1 + _w1, _y1, x + _ox2 + _w2, _y2, false);
    draw_triangle(x + _ox1 - _w1, _y1, x + _ox2 - _w2, _y2, x + _ox2 + _w2, _y2, false);
    draw_set_color(make_color_rgb(92, 56, 36));
    draw_line(x + _ox1 - _w1 * 0.4, _y1, x + _ox2 - _w2 * 0.4, _y2);
}
// brasas na ponta
gpu_set_blendmode(bm_add);
draw_set_alpha(0.6 * sobe);
draw_set_color(make_color_rgb(255, 90, 30));
draw_circle(x + sin(5 + semente) * 5, y - _h, 4 + sin(_tt / 4), false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
