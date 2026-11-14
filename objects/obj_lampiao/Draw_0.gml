if (!cenario_na_tela(x - 60, x + 60)) exit;
var _tx = (tremor > 0) ? random_range(-tremor, tremor) * 0.25 : 0;
// ponto do gancho no braço do poste
var _hx = x + 12 + _tx;
var _hy = y - 93;
// centro da lanterna (11 px abaixo do gancho, girando com ela)
var _lx = _hx + lengthdir_x(11, ang - 90);
var _ly = _hy + lengthdir_y(11, ang - 90);
var _forca = 1;
if (pisca > 0) _forca = (floor(pisca / 3) mod 2 == 0) ? 0.35 : 1.2;
_forca *= 0.9 + 0.1 * sin(current_time / 90 + semente);
cenario_luz(_lx, _ly, 80, _forca, make_color_rgb(255, 190, 90));
// mancha de luz no chão, embaixo da lanterna
gpu_set_blendmode(bm_add);
draw_set_alpha(0.1 * _forca);
draw_set_color(make_color_rgb(255, 170, 80));
draw_ellipse(_lx - 34, y - 6, _lx + 34, y + 4, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_sprite(sprite_index, 0, x + _tx, y);
if (flash > 0)
{
    gpu_set_fog(true, make_color_rgb(255, 230, 190), 0, 0);
    draw_sprite_ext(spr_lampiao_luz, 0, _hx, _hy, 1, 1, ang, c_white, 1);
    gpu_set_fog(false, c_white, 0, 0);
}
else draw_sprite_ext(spr_lampiao_luz, 0, _hx, _hy, 1, 1, ang, c_white, 1);
