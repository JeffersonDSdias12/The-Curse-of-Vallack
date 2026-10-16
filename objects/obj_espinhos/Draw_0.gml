// fendas no chão (sempre visíveis: o jogador aprende onde estão)
draw_set_color(make_color_rgb(20, 14, 12));
draw_set_alpha(0.8);
draw_rectangle(x - 15, y - 1, x + 15, y + 1, false);
draw_set_alpha(1);
if (sobe <= 0.01) exit;
// só a parte acima do chão aparece
var _h = sprite_get_height(sprite_index);
var _vis = clamp(round(_h * sobe), 1, _h);
draw_sprite_part(sprite_index, 0, 0, 0, sprite_get_width(sprite_index), _vis, x - sprite_get_xoffset(sprite_index), y - _vis);
if (estado == "alto" and sobe > 0.6)
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.15);
    draw_set_color(make_color_rgb(255, 60, 40));
    draw_rectangle(x - 15, y - _vis, x + 15, y, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
if (global.debug_hitbox)
{
    draw_set_color(c_red);
    draw_rectangle(x - 15, y - 13 * sobe, x + 15, y, true);
}
