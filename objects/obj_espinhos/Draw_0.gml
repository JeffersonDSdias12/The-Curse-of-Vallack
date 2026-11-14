// v1.12: espinhos maiores (escala 1,6) e mais visíveis
var _e = ESPINHOS_ESCALA;
// fendas no chão (sempre visíveis: o jogador aprende onde estão)
draw_set_color(make_color_rgb(20, 14, 12));
draw_set_alpha(0.85);
draw_rectangle(x - 24, y - 2, x + 24, y + 1, false);
draw_set_alpha(1);
// aviso: a fenda brilha antes de subir
if (estado == "aviso")
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.35 + 0.25 * sin(t * 0.8));
    draw_set_color(make_color_rgb(255, 80, 50));
    draw_rectangle(x - 24, y - 3, x + 24, y + 1, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
if (sobe <= 0.01) exit;
// só a parte acima do chão aparece
var _h = sprite_get_height(sprite_index);
var _vis = clamp(round(_h * sobe), 1, _h);
draw_sprite_part_ext(sprite_index, 0, 0, 0, sprite_get_width(sprite_index), _vis, x - sprite_get_xoffset(sprite_index) * _e, y - _vis * _e, _e, _e, c_white, 1);
if (estado == "alto" and sobe > 0.6)
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.2);
    draw_set_color(make_color_rgb(255, 60, 40));
    draw_rectangle(x - 24, y - _vis * _e, x + 24, y, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
if (global.debug_hitbox)
{
    draw_set_color(c_red);
    draw_rectangle(x - 24, y - 22 * sobe, x + 24, y, true);
}
