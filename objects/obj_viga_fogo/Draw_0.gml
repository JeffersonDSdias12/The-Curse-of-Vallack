var _tt = current_time / 16;
if (estado == "esperando") exit;
if (estado == "aviso" or estado == "caindo")
{
    // sombra crescendo no chão
    var _k = (estado == "aviso") ? t / 48 : 1;
    draw_set_alpha(0.25 + 0.3 * _k);
    draw_set_color(c_black);
    draw_ellipse(x - 40 * _k, y_chao - 3, x + 40 * _k, y_chao + 3, false);
    draw_set_alpha(1);
    if (estado == "aviso")
    {
        var _pa = 0.6 + 0.4 * sin(_tt * 0.5);
        gpu_set_texfilter(true);
        txt(x, y_chao - 70, "!", FONTE.MEDIA, make_color_rgb(255, 120, 50), _pa, fa_center, fa_middle, 0.9);
        gpu_set_texfilter(false);
    }
}
var _fogo = 1;
if (estado == "cinzas") _fogo = max(0, 1 - t / 120);
else if (estado == "queimando") _fogo = clamp(1.2 - queima / 360, 0.15, 1);
var _cor = (estado == "cinzas") ? merge_color(c_white, make_color_rgb(70, 60, 60), clamp(t / 60, 0, 1)) : c_white;
if (estado != "aviso")
{
    draw_sprite_ext(spr_viga, 0, x, y_viga, 1, 1, ang, _cor, (estado == "cinzas") ? max(0, 1 - t / 200) : 1);
    desenhar_chamas(x, y_viga - 2, 70, (estado == "caindo") ? 22 : 30, _tt, _fogo, semente);
}
if (estado == "cinzas" and t >= 200) instance_destroy();
