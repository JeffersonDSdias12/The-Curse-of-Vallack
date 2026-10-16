var _a = (estado == "voando" or estado == "refletida") ? 1 : clamp(vida / max(1, vida_max) * 1.5, 0, 1);
if (estado == "refletida")
{
    // brilho azul: a flecha agora é de Twilight
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.5);
    draw_set_color(make_color_rgb(110, 180, 255));
    draw_circle(x, y, 7, false);
    draw_line_width(x, y, x - vx * 4, y - vy * 4, 3);
    gpu_set_blendmode(bm_normal);
}
var _c = 12 * escala;
var _tx = x - lengthdir_x(_c, ang);
var _ty = y - lengthdir_y(_c, ang);
var _hx = x + lengthdir_x(_c, ang);
var _hy = y + lengthdir_y(_c, ang);
draw_set_alpha(_a);
// rastro
if (estado == "voando")
{
    draw_set_alpha(0.25);
    draw_set_color(make_color_rgb(255, 220, 200));
    draw_line_width(_tx - lengthdir_x(10, ang), _ty - lengthdir_y(10, ang), _tx, _ty, 1);
    draw_set_alpha(_a);
}
// haste
draw_set_color(make_color_rgb(215, 196, 160));
draw_line_width(_tx, _ty, _hx, _hy, 2);
// ponta
draw_set_color(make_color_rgb(150, 150, 160));
draw_triangle(_hx + lengthdir_x(5 * escala, ang), _hy + lengthdir_y(5 * escala, ang),
              _hx + lengthdir_x(2.5 * escala, ang + 90), _hy + lengthdir_y(2.5 * escala, ang + 90),
              _hx + lengthdir_x(2.5 * escala, ang - 90), _hy + lengthdir_y(2.5 * escala, ang - 90), false);
// penas
draw_set_color(make_color_rgb(200, 40, 40));
draw_triangle(_tx, _ty, _tx - lengthdir_x(5 * escala, ang - 25), _ty - lengthdir_y(5 * escala, ang - 25),
              _tx + lengthdir_x(4 * escala, ang), _ty + lengthdir_y(4 * escala, ang), false);
draw_triangle(_tx, _ty, _tx - lengthdir_x(5 * escala, ang + 25), _ty - lengthdir_y(5 * escala, ang + 25),
              _tx + lengthdir_x(4 * escala, ang), _ty + lengthdir_y(4 * escala, ang), false);
draw_set_alpha(1);
draw_set_color(c_white);
