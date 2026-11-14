if (!cenario_na_tela(x - 40, x + 40)) exit;
draw_set_alpha(0.3);
draw_set_color(c_black);
draw_ellipse(x - 12, y - 3, x + 12, y + 3, false);
draw_set_alpha(1);
// a lanterna é de óleo, com vidro: luz amarela
cenario_luz(x + dir * 9, y - 28, 64, 0.8 + 0.1 * sin(current_time / 90), make_color_rgb(255, 190, 90));
draw_sprite_hd(sprite_index, image_index, x, y, dir, 1, 0, c_white, 1);
if (estado == "parado")
{
    gpu_set_texfilter(true);
    txt_sombra(x, y - 78, "!", FONTE.MEDIA, make_color_rgb(255, 230, 140), 0.6 + 0.4 * sin(current_time / 200), fa_center, fa_bottom, 0.7);
    gpu_set_texfilter(false);
}
desenho_resetar();
