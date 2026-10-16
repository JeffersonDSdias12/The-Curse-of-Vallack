var _p = clamp(tempo / 14, 0, 1);
var _n = (global.cfg_qualidade == 0) ? 3 : (global.cfg_qualidade == 1 ? 5 : 8);
gpu_set_blendmode(bm_add);
draw_set_alpha(1 - _p);
draw_set_color(cor);
draw_circle(x, y, 6 + 26 * _p, true);
for (var _i = 0; _i < _n; _i++)
{
    var _ang = _i * (360 / _n) + 22;
    draw_line_width(
        x + lengthdir_x(8 + 22 * _p, _ang), y + lengthdir_y(8 + 22 * _p, _ang),
        x + lengthdir_x(14 + 34 * _p, _ang), y + lengthdir_y(14 + 34 * _p, _ang), 2);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
