// paliçada de troncos apontados, a grade de madeira com faixas de ferro, o
// cadeado em brasa (trancado) e duas tochas nos postes
var _tt = current_time / 16;
var _cam = view_camera[0];
if (_cam != -1 and (x + 60 < camera_get_view_x(_cam) or x - 60 > camera_get_view_x(_cam) + camera_get_view_width(_cam))) exit;
// troncos da paliçada (a passagem embaixo, no meio)
for (var _k = -4; _k <= 3; _k++)
{
    var _lx = x + _k * 7;
    var _c = merge_color(make_color_rgb(124, 86, 52), make_color_rgb(98, 66, 40), (abs(_k) mod 2) * 0.6);
    var _baixo = (_k >= -2 and _k <= 1) ? y - 112 : y;
    draw_set_color(_c);
    draw_rectangle(_lx, y_topo, _lx + 6, _baixo, false);
    draw_set_color(make_color_rgb(160, 116, 72));
    draw_line(_lx + 1, y_topo, _lx + 1, _baixo);
    draw_set_color(make_color_rgb(30, 20, 12));
    draw_line(_lx + 6, y_topo, _lx + 6, _baixo);
    draw_triangle(_lx, y_topo, _lx + 6, y_topo, _lx + 3, y_topo - 9, false);
}
// travessas de ferro na paliçada
draw_set_color(make_color_rgb(54, 52, 56));
draw_rectangle(x - 29, y - 168, x + 27, y - 162, false);
draw_rectangle(x - 29, y - 300, x + 27, y - 294, false);
// a grade (sobe ao abrir)
var _gy = y - 112 * sobe;
if (sobe < 1)
{
    var _gt = y - 110;
    for (var _k = 0; _k < 5; _k++)
    {
        var _bx = x - 14 + _k * 7;
        draw_set_color(make_color_rgb(86, 58, 36));
        draw_rectangle(_bx, max(_gt, _gt - 112 * sobe), _bx + 5, _gy, false);
        draw_set_color(make_color_rgb(30, 20, 12));
        draw_line(_bx + 5, max(_gt, _gt - 112 * sobe), _bx + 5, _gy);
        draw_triangle(_bx, _gy, _bx + 5, _gy, _bx + 2.5, _gy + 5, false);
    }
    draw_set_color(make_color_rgb(70, 68, 72));
    for (var _f = 0; _f < 3; _f++) { var _fy = _gy - 20 - _f * 32; if (_fy > _gt - 2) draw_rectangle(x - 16, _fy, x + 18, _fy + 4, false); }
}
// o cadeado em brasa (só trancado)
if (estado == "trancado")
{
    var _ly = y - 62;
    var _pul = 0.7 + 0.3 * sin(_tt / 9);
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(255, 120, 40));
    draw_set_alpha(0.22 * _pul);
    draw_circle(x + 2, _ly, 20, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(48, 44, 46));
    draw_ellipse(x - 5, _ly - 16, x + 9, _ly - 2, true);
    draw_ellipse(x - 4, _ly - 15, x + 8, _ly - 3, true);
    draw_set_color(make_color_rgb(150, 110, 50));
    draw_rectangle(x - 7, _ly - 6, x + 11, _ly + 10, false);
    draw_set_color(make_color_rgb(220, 170, 80));
    draw_line(x - 7, _ly - 6, x + 11, _ly - 6);
    draw_set_color(make_color_rgb(255, 150, 70));
    draw_set_alpha(_pul);
    draw_circle(x + 2, _ly + 1, 2, false);
    draw_rectangle(x + 1, _ly + 1, x + 3, _ly + 6, false);
    draw_set_alpha(1);
}
// tochas nos postes dos lados
for (var _s = -1; _s <= 1; _s += 2)
{
    var _tx = x + _s * 40;
    draw_set_color(make_color_rgb(60, 40, 26));
    draw_rectangle(_tx - 2, y - 150, _tx + 2, y, false);
    var _fl = 0.75 + 0.25 * sin(_tt / 5 + _s * 2) * sin(_tt / 13 + _s);
    cenario_luz(_tx, y - 156, 46, _fl, make_color_rgb(255, 150, 60));
    desenhar_chamas(_tx, y - 150, 9, 16, _tt + _s * 30, 0.9, _s * 7);
}
draw_set_color(c_white);
draw_set_alpha(1);