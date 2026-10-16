var _r = (valor >= 25) ? 5 : ((valor >= 5) ? 3.6 : 2.4);
var _pul = 1 + 0.15 * sin((current_time / 16 + fase) / 5);
gpu_set_blendmode(bm_add);
// rastro
for (var _i = 0; _i < array_length(rastro); _i++)
{
    var _k = (_i + 1) / array_length(rastro);
    draw_set_alpha(0.25 * _k);
    draw_set_color(make_color_rgb(255, 40, 30));
    draw_circle(rastro[_i][0], rastro[_i][1], _r * _k, false);
}
draw_set_alpha(0.35);
draw_set_color(make_color_rgb(220, 20, 20));
draw_circle(x, y, _r * 2.2 * _pul, false);
draw_set_alpha(0.95);
draw_set_color(make_color_rgb(255, 70, 50));
draw_circle(x, y, _r * _pul, false);
draw_set_color(make_color_rgb(255, 210, 180));
draw_circle(x - _r * 0.25, y - _r * 0.25, _r * 0.4, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
