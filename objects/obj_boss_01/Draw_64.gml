// ===== BARRA DE VIDA DO BOSS (parte de baixo da tela) =====
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
if (hud_alpha > 0.01)
{
    var _bw = min(_gw * 0.62, 820);
    var _bx = _gw / 2 - _bw / 2;
    var _by = _gh - 30;
    var _a = hud_alpha;
    vida_atraso = lerp_dt(vida_atraso, vida, 0.035);
    desenhar_painel(_bx - 16, _by - 34, _bx + _bw + 16, _by + 18, 0, _a * 0.92);
    txt_sombra(_bx, _by - 20, nome_boss, FONTE.PEQUENA, make_color_rgb(255, 120, 90), _a, fa_left, fa_middle);
    txt(_bx + _bw, _by - 20, string(ceil(vida)) + " / " + string(vida_max), FONTE.MINI, make_color_rgb(220, 210, 200), _a, fa_right, fa_middle);
    draw_set_alpha(_a);
    draw_set_color(make_color_rgb(18, 8, 8));
    draw_rectangle(_bx - 2, _by - 2, _bx + _bw + 2, _by + 12, false);
    draw_set_color(make_color_rgb(255, 235, 210));
    draw_rectangle(_bx, _by, _bx + _bw * clamp(vida_atraso / vida_max, 0, 1), _by + 10, false);
    var _c1 = make_color_rgb(235, 60, 40);
    var _c2 = make_color_rgb(110, 10, 20);
    draw_rectangle_color(_bx, _by, _bx + _bw * clamp(vida / vida_max, 0, 1), _by + 10, _c1, _c1, _c2, _c2, false);
    draw_set_color(make_color_rgb(18, 8, 8));
    for (var _s = 1; _s < 10; _s++) draw_line(_bx + _bw * _s / 10, _by, _bx + _bw * _s / 10, _by + 10);
    // marca da metade: ali a árvore se enfurece
    draw_set_color(furia ? make_color_rgb(255, 80, 40) : make_color_rgb(255, 210, 90));
    draw_rectangle(_bx + _bw * 0.5 - 1, _by - 5, _bx + _bw * 0.5 + 1, _by + 15, false);
    if (furia) txt(_bx + _bw / 2, _by - 20, "FÚRIA", FONTE.MINI, merge_color(make_color_rgb(255, 80, 40), c_white, 0.5 + 0.5 * sin(current_time / 100)), _a, fa_center, fa_middle);
    if (onda_numero > 0 and servos_vivos() > 0) txt(_bx + _bw / 2 + (furia ? 70 : 0), _by - 20, "SERVOS: " + string(servos_vivos()), FONTE.MINI, make_color_rgb(220, 200, 190), _a * 0.8, fa_left, fa_middle);
    draw_set_color(make_color_rgb(176, 141, 70));
    draw_rectangle(_bx - 2, _by - 2, _bx + _bw + 2, _by + 12, true);
    draw_set_alpha(1);
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
