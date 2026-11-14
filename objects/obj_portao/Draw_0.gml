if (!cenario_na_tela(x - 72, x + 72)) exit;
draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, 0, tom, 1);
// luz do incêndio lá dentro, vazando pela grade
var _p = 0.75 + 0.25 * sin(current_time / 140 + semente) * sin(current_time / 330 + semente * 2);
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(150, 60, 255));          // v1.12: incêndio maldito lá dentro
draw_set_alpha(0.1 * _p);
draw_ellipse(x - 40, y - 70, x + 40, y + 6, false);
draw_set_alpha(0.08 * _p);
draw_ellipse(x - 26, y - 40, x + 26, y + 2, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
