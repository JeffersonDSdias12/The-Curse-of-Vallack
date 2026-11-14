if (!cenario_na_tela(x - 90, x + 90)) exit;
var _t = current_time / 16;
if (luz > 0)
{
    var _pisca = 0.85 + 0.15 * sin(_t / 3.1 + semente) * sin(_t / 7.7 + semente * 3);
    cenario_luz(x, y - 10, 92 * (0.6 + 0.4 * luz), luz * _pisca, cor_chama_maldita());
}
draw_sprite(sprite_index, 0, x, y);
if (luz > 0) desenhar_chamas(x, y + 1, 10, 18 * (0.4 + 0.6 * luz), _t + semente * 10, luz, semente);
else
{
    // apagada: só uma brasa
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.4 + 0.2 * sin(_t / 9 + semente));
    draw_set_color(make_color_rgb(170, 60, 255));
    draw_circle(x, y, 2, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
