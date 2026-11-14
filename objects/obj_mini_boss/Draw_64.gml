// ===== BARRA DE VIDA DO MINI-BOSS (embaixo, como a do boss) =====
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
if (hud_alpha > 0.01 and !morrendo)
{
    vida_atraso = lerp_dt(vida_atraso, vida, 0.04);
    // marca de 1/4: ali ele cai de joelhos; v1.12: marca de 60%: ali ele se enfurece (fase 2)
    var _ouro = make_color_rgb(255, 210, 90);
    var _marcas = [[0.25, _ouro], [0.6, enfurecido ? make_color_rgb(255, 80, 50) : _ouro]];
    // v1.19: quantas vidas ele ainda tem (a primeira sequência não o mata)
    var _rot = na_segunda_vida ? "ÚLTIMA VIDA" : (segunda_vida ? "MINI-BOSS  ·  2 VIDAS" : "MINI-BOSS");
    hud_barra_chefe(nome_boss, _rot, na_segunda_vida ? make_color_rgb(255, 110, 90) : make_color_rgb(220, 200, 180), vida / vida_max, vida_atraso / vida_max,
        make_color_rgb(230, 110, 40), make_color_rgb(120, 30, 10), _marcas, "", hud_alpha, 640);
}
if (titulo_tempo > 0)
{
    var _ta = min(clamp((200 - titulo_tempo) / 20, 0, 1), clamp(titulo_tempo / 30, 0, 1));
    var _esc = min(1, (_gw * 0.8) / max(1, txt_largura(nome_boss, FONTE.GRANDE)));
    txt_amaldicoado(_gw / 2, _gh * 0.30, nome_boss, FONTE.GRANDE, make_color_rgb(235, 90, 35), 200 - titulo_tempo, 3, _esc, _ta);
    txt(_gw / 2, _gh * 0.30 + 46, titulo_boss, FONTE.PEQUENA, make_color_rgb(255, 210, 90), _ta, fa_center, fa_middle);
}
desenho_resetar();
