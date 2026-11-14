var _f = clamp(min(t / 10, (vida - t) / 30), 0, 1);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.2 * _f);
draw_set_color(make_color_rgb(255, 200, 90));
draw_ellipse(min(x, x + dir * 90) - 24, y - 8, max(x, x + dir * 90) + 24, y + 4, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
for (var _i = 0; _i < 4; _i++) desenhar_chamas(x + dir * _i * 30, y, 26, 30 + 6 * sin(t / 9 + _i), current_time / 16 + _i * 13, _f, semente + _i, 1);
