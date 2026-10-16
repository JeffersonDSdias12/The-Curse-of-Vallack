// ===== CRISTAL DOURADO DE SALVAMENTO =====
var _t = current_time / 16;
var _cy = y - 40 + sin(current_time / 400) * 4;   // flutua
desenhar_cristal(x, _cy, 11, make_color_rgb(235, 175, 60), make_color_rgb(255, 215, 110), perto ? 1 : 0.65, _t);

// onda dourada quando vira o checkpoint
if (marcado_fx > 0)
{
    var _k = 1 - marcado_fx / 45;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(1 - _k);
    draw_set_color(make_color_rgb(255, 200, 90));
    draw_circle(x, _cy, 10 + 70 * _k, true);
    draw_circle(x, _cy, 8 + 50 * _k, true);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// dica (mostra a tecla configurada)
if (perto)
{
    gpu_set_texfilter(true);
    var _acao = dif_cristal_cura() ? " SALVAR E RECUPERAR VIDA" : " SALVAR";
    txt(x, _cy - 30, rotulo_acao(ACAO.INTERAGIR) + _acao, FONTE.MINI, c_white, 1, fa_center, fa_bottom, 0.55);
    gpu_set_texfilter(false);
}
desenho_resetar();
