// ===== BARRA DE VIDA DO BOSS (parte de baixo da tela) =====
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
if (hud_alpha > 0.01)
{
    vida_atraso = lerp_dt(vida_atraso, vida, 0.035);
    // v1.12: marcas das fases (66% e 33%): ali a árvore muda de fase
    var _roxo = make_color_rgb(190, 80, 255);
    var _ouro = make_color_rgb(255, 210, 90);
    var _marcas = [[0.66, (fase >= 2) ? _roxo : _ouro], [0.33, (fase >= 3) ? _roxo : _ouro]];
    var _ft = "FASE " + ((fase == 1) ? "I" : ((fase == 2) ? "II" : "III"));
    var _cor_ft = (fase >= 2) ? merge_color(_roxo, c_white, 0.4 + 0.4 * sin(current_time / 100)) : _ouro;
    hud_barra_chefe(nome_boss, _ft, _cor_ft, vida / vida_max, vida_atraso / vida_max,
        make_color_rgb(235, 60, 40), make_color_rgb(110, 10, 20), _marcas, string(ceil(vida)) + " / " + string(vida_max), hud_alpha, 820);
}

// ===== APRESENTAÇÃO DO BOSS =====
if (titulo_tempo > 0)
{
    var _ta = min(clamp((210 - titulo_tempo) / 20, 0, 1), clamp(titulo_tempo / 30, 0, 1));
    var _esc = min(1, (_gw * 0.8) / max(1, txt_largura(nome_boss, FONTE.GRANDE)));
    txt_amaldicoado(_gw / 2, _gh * 0.30, nome_boss, FONTE.GRANDE, make_color_rgb(235, 45, 35), 210 - titulo_tempo, 3, _esc, _ta);
    txt(_gw / 2, _gh * 0.30 + 46, titulo_boss, FONTE.PEQUENA, make_color_rgb(255, 210, 90), _ta, fa_center, fa_middle);
}
desenho_resetar();
