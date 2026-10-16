draw_set_alpha(0.25 * alpha);
draw_set_color(c_black);
draw_ellipse(x - 7, y - 2, x + 7, y + 2, false);
draw_set_alpha(1);
draw_sprite_ext(sprite_index, image_index, x, y, dir, 1, 0, make_color_rgb(190, 175, 170), alpha);
