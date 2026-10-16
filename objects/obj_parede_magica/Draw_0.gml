if (sobe <= 0) exit;
var _tt = current_time / 16;
var _topo = y - altura * sobe;
var _a = sobe * (0.8 + 0.2 * sin(_tt / 7)) + choque / 12 * 0.5;
desenhar_barreira(x, _topo, y, min(1, _a), _tt + lado * 40);
// runas subindo pela muralha
gpu_set_blendmode(bm_add);
for (var _i = 0; _i < 6; _i++)
{
    var _f = frac(_tt / 160 + _i / 6);
    var _ry = y - _f * altura * sobe;
    draw_set_alpha(sobe * (1 - abs(_f - 0.5) * 2) * 0.9);
    draw_set_color(make_color_rgb(255, 120, 200));
    draw_circle(x, _ry, 4, true);
    draw_line(x - 5, _ry, x + 5, _ry);
    draw_line(x, _ry - 5, x, _ry + 5);
}
if (choque > 0)
{
    draw_set_alpha(choque / 12);
    draw_set_color(make_color_rgb(255, 200, 220));
    draw_rectangle(x - 6, _topo, x + 6, y, false);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
