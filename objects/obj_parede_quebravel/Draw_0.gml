var _tx = (tremor > 0) ? random_range(-tremor, tremor) * 0.35 : 0;
if (flash > 0)
{
    gpu_set_fog(true, make_color_rgb(255, 225, 200), 0, 0);
    draw_sprite_ext(sprite_index, image_index, x + _tx, y, image_xscale, image_yscale, 0, image_blend, 1);
    gpu_set_fog(false, c_white, 0, 0);
}
else draw_sprite_ext(sprite_index, image_index, x + _tx, y, image_xscale, image_yscale, 0, image_blend, 1);

// luz vermelha passando pelas rachaduras (dica de que dá para quebrar)
gpu_set_blendmode(bm_add);
draw_set_alpha((0.10 + 0.07 * sin(current_time / 300)) * (1 + image_index));
draw_set_color(segredo ? make_color_rgb(255, 60, 40) : make_color_rgb(255, 130, 60));
var _h = sprite_get_height(sprite_index) * image_yscale;
draw_ellipse(x - 14, y - _h * 0.75, x + 14, y - _h * 0.2, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
