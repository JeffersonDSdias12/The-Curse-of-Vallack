// ===== BARRA DE VIDA DO MINI-BOSS (embaixo, como a do boss) =====
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
if (hud_alpha > 0.01 and !morrendo)
{
    var _bw = min(_gw * 0.5, 640);
    var _bx = _gw / 2 - _bw / 2;
    var _by = _gh - 30;
    var _a = hud_alpha;
    vida_atraso = lerp_dt(vida_atraso, vida, 0.04);
    desenhar_painel(_bx - 16, _by - 34, _bx + _bw + 16, _by + 18, 0, _a * 0.92);
    txt_sombra(_bx, _by - 20, nome_boss, FONTE.PEQUENA, make_color_rgb(255, 150, 110), _a, fa_left, fa_middle);
    txt(_bx + _bw, _by - 20, "MINI-BOSS", FONTE.MINI, make_color_rgb(220, 200, 180), _a, fa_right, fa_middle);
    draw_set_alpha(_a);
    draw_set_color(make_color_rgb(18, 8, 8));
    draw_rectangle(_bx - 2, _by - 2, _bx + _bw + 2, _by + 12, false);
    draw_set_color(make_color_rgb(255, 235, 210));
    draw_rectangle(_bx, _by, _bx + _bw * clamp(vida_atraso / vida_max, 0, 1), _by + 10, false);
    var _c1 = make_color_rgb(230, 110, 40);
    var _c2 = make_color_rgb(120, 30, 10);
    draw_rectangle_color(_bx, _by, _bx + _bw * clamp(vida / vida_max, 0, 1), _by + 10, _c1, _c1, _c2, _c2, false);
    // marca de 1/4: ali ele cai de joelhos
    draw_set_color(make_color_rgb(255, 210, 90));
    draw_rectangle(_bx + _bw * 0.25 - 1, _by - 4, _bx + _bw * 0.25 + 1, _by + 14, false);
    draw_set_color(make_color_rgb(176, 141, 70));
    draw_rectangle(_bx - 2, _by - 2, _bx + _bw + 2, _by + 12, true);
    draw_set_alpha(1);
}
if (titulo_tempo > 0)
{
    var _ta = min(clamp((200 - titulo_tempo) / 20, 0, 1), clamp(titulo_tempo / 30, 0, 1));
    var _esc = min(1, (_gw * 0.8) / max(1, txt_largura(nome_boss, FONTE.GRANDE)));
    txt_amaldicoado(_gw / 2, _gh * 0.30, nome_boss, FONTE.GRANDE, make_color_rgb(235, 90, 35), 200 - titulo_tempo, 3, _esc, _ta);
    txt(_gw / 2, _gh * 0.30 + 46, titulo_boss, FONTE.PEQUENA, make_color_rgb(255, 210, 90), _ta, fa_center, fa_middle);
}
desenho_resetar();
