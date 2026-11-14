if (!cenario_na_tela(x - 88, x + 88)) exit;
draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, 0, tom, 1);
// brilho roxo da maldição lá dentro (pulsando)
var _p = 0.7 + 0.3 * sin(current_time / 420 + semente);
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(150, 40, 220));
draw_set_alpha(0.14 * _p);
draw_ellipse(x - 38, y - 60, x + 38, y - 4, false);
draw_set_alpha(0.1 * _p);
draw_ellipse(x - 22, y - 36, x + 22, y - 8, false);
draw_set_color(make_color_rgb(220, 40, 90));
draw_set_alpha(0.06 * _p);
draw_ellipse(x - 60, y - 100, x + 60, y + 10, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
