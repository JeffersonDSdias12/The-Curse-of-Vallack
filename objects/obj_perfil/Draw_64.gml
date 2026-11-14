// ===== PERFIL, CONQUISTAS E RECOMPENSAS — desenho =====
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ouro = make_color_rgb(236, 186, 84);
var _claro = make_color_rgb(250, 240, 228);
var _cinza = make_color_rgb(190, 175, 168);
var _a = entrada;

retangulo_gradiente(0, 0, _gw, _gh, make_color_rgb(16, 6, 8), 1, make_color_rgb(40, 12, 10), 1);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.12 + 0.04 * sin(t / 30));
draw_set_color(make_color_rgb(200, 60, 20));
draw_ellipse(-_gw * 0.1, _gh * 0.55, _gw * 1.1, _gh * 1.4, false);
gpu_set_blendmode(bm_normal);

// ----- cabeçalho: emblema, nome, título e o progresso -----
var _feitas = conquistas_feitas();
var _total = array_length(lista);
conquista_emblema(86, 72, 40, _a, t);
txt_sombra(146, 50, "CONQUISTAS DE " + perfil_nome_exibir(), FONTE.MEDIA, _claro, _a, fa_left, fa_middle, min(1, (_gw - 520) / max(1, txt_largura("CONQUISTAS DE " + perfil_nome_exibir(), FONTE.MEDIA))));
txt(146, 88, (global.perfil.titulo != "") ? global.perfil.titulo : "Sem título ainda", FONTE.PEQUENA, _ouro, _a, fa_left, fa_middle);
var _bx2 = _gw - 40;
var _bx1 = _bx2 - 300;
txt(_bx2, 52, string(_feitas) + " / " + string(_total), FONTE.MEDIA, _ouro, _a, fa_right, fa_middle);
draw_set_alpha(_a);
draw_set_color(make_color_rgb(30, 14, 12));
draw_rectangle(_bx1, 80, _bx2, 92, false);
draw_set_color(make_color_rgb(200, 60, 30));
draw_rectangle(_bx1, 80, _bx1 + (_bx2 - _bx1) * _feitas / max(1, _total), 92, false);
draw_set_color(_ouro);
draw_rectangle(_bx1, 80, _bx2, 92, true);

// ----- abas -----
var _nomes_aba = ["CONQUISTAS", "LÂMINAS", "PERFIL"];
for (var _i = 0; _i < 3; _i++)
{
    var _tx = _gw / 2 + (_i - 1) * 250;
    var _ativa = (aba == _i);
    draw_set_alpha(_a);
    draw_set_color(_ativa ? make_color_rgb(110, 22, 16) : make_color_rgb(34, 16, 14));
    draw_roundrect_ext(_tx - 115, 128, _tx + 115, 170, 8, 8, false);
    draw_set_color(_ativa ? _ouro : make_color_rgb(110, 90, 80));
    draw_roundrect_ext(_tx - 115, 128, _tx + 115, 170, 8, 8, true);
    txt(_tx, 149, _nomes_aba[_i], FONTE.PEQUENA, _ativa ? c_white : _cinza, _a, fa_center, fa_middle);
}

switch (aba)
{
    // ----- as 21 conquistas, em 2 colunas -----
    case 0:
        for (var _i = 0; _i < array_length(lista); _i++)
        {
            var _cp = card_pos(_i);
            var _y1 = _cp[1];
            if (_y1 + _cp[3] < 170 or _y1 > _gh - 50) continue;
            var _fa = _a * clamp((_y1 - 166) / 26, 0, 1) * clamp((_gh - 50 - (_y1 + _cp[3])) / 26, 0, 1);
            if (_fa <= 0.01) continue;
            var _c = lista[_i];
            var _tem = conquista_tem(_c.id);
            hud_faixa(_cp[0], _y1, _cp[0] + _cp[2], _y1 + _cp[3], 0.92 * _fa);
            if (_i == sel)
            {
                draw_set_alpha(_fa);
                draw_set_color(_ouro);
                draw_rectangle(_cp[0] - 2, _y1 - 2, _cp[0] + _cp[2] + 2, _y1 + _cp[3] + 2, true);
            }
            conquista_emblema(_cp[0] + 38, _y1 + 36, 22, _fa, t + _i * 7, !_tem);
            var _lt = _cp[2] - 180;
            txt_sombra(_cp[0] + 72, _y1 + 18, _c.nome, FONTE.PEQUENA, _tem ? _claro : make_color_rgb(150, 136, 130), _fa, fa_left, fa_middle, min(1, _lt / max(1, txt_largura(_c.nome, FONTE.PEQUENA))));
            txt(_cp[0] + 72, _y1 + 40, _c.desc, FONTE.MINI, _tem ? _cinza : make_color_rgb(120, 110, 106), _fa, fa_left, fa_middle, min(1, (_cp[2] - 90) / max(1, txt_largura(_c.desc, FONTE.MINI))));
            txt(_cp[0] + 72, _y1 + 60, recompensa_texto(_c), FONTE.MINI, _tem ? make_color_rgb(255, 150, 100) : make_color_rgb(130, 96, 84), _fa, fa_left, fa_middle);
            txt(_cp[0] + _cp[2] - 14, _y1 + 18, _tem ? global.perfil.conquistas[$ _c.id] : "BLOQUEADA", FONTE.MINI, _tem ? _ouro : make_color_rgb(120, 104, 98), _fa, fa_right, fa_middle);
        }
    break;

    // ----- os estilos de lâmina (efeito da espada) -----
    case 1:
        for (var _i = 0; _i < array_length(estilos); _i++)
        {
            var _lp = lamina_pos(_i);
            var _e = estilos[_i];
            var _lib = espada_estilo_liberado(_e.id);
            var _equip = (global.perfil.espada_fx == _e.id);
            hud_faixa(_lp[0], _lp[1], _lp[0] + _lp[2], _lp[1] + _lp[3], 0.94 * _a);
            if (_i == sel or _equip)
            {
                draw_set_alpha(_a);
                draw_set_color(_equip ? _ouro : make_color_rgb(200, 120, 80));
                draw_rectangle(_lp[0] - 2, _lp[1] - 2, _lp[0] + _lp[2] + 2, _lp[1] + _lp[3] + 2, true);
                if (_i == sel) draw_rectangle(_lp[0] - 4, _lp[1] - 4, _lp[0] + _lp[2] + 4, _lp[1] + _lp[3] + 4, true);
            }
            var _cx = _lp[0] + _lp[2] / 2;
            lamina_amostra(_cx, _lp[1] + 92, 46, _e, t + _i * 20, _a * (_lib ? 1 : 0.35));
            if (!_lib) cadeado_grande(_cx, _lp[1] + 82, 0.9, _a);
            txt_sombra(_cx, _lp[1] + 156, _e.nome, FONTE.PEQUENA, _lib ? _claro : make_color_rgb(140, 128, 124), _a, fa_center, fa_middle, min(1, (_lp[2] - 20) / max(1, txt_largura(_e.nome, FONTE.PEQUENA))));
            var _st = _equip ? "EQUIPADA" : (_lib ? "ESCOLHER" : "BLOQUEADA");
            if (!_lib)
            {
                for (var _k = 0; _k < array_length(lista); _k++) if (lista[_k].rtipo == "espada" and lista[_k].rval == _e.id) _st = "CONQUISTA: " + lista[_k].nome;
            }
            txt(_cx, _lp[1] + 182, _st, FONTE.MINI, _equip ? _ouro : (_lib ? _cinza : make_color_rgb(150, 110, 96)), _a, fa_center, fa_middle, min(1, (_lp[2] - 16) / max(1, txt_largura(_st, FONTE.MINI))));
        }
    break;

    // ----- o perfil: nome, título e os números da carreira -----
    case 2:
        var _bn = [_gw / 2 - 160, 214, _gw / 2 + 160, 262];
        var _bt = [_gw / 2 - 260, 300, _gw / 2 + 260, 348];
        txt(_gw / 2, 196, "Seu nome aparece só nas conquistas: o herói continua sendo Twilight Vetrus.", FONTE.MINI, _cinza, _a, fa_center, fa_middle);
        for (var _b = 0; _b < 2; _b++)
        {
            var _bb = (_b == 0) ? _bn : _bt;
            draw_set_alpha(_a);
            draw_set_color((sel == _b) ? make_color_rgb(110, 22, 16) : make_color_rgb(34, 16, 14));
            draw_roundrect_ext(_bb[0], _bb[1], _bb[2], _bb[3], 8, 8, false);
            draw_set_color((sel == _b) ? _ouro : make_color_rgb(110, 90, 80));
            draw_roundrect_ext(_bb[0], _bb[1], _bb[2], _bb[3], 8, 8, true);
        }
        txt(_gw / 2, 238, "ALTERAR NOME  ·  " + perfil_nome_exibir(), FONTE.PEQUENA, c_white, _a, fa_center, fa_middle, min(1, 300 / max(1, txt_largura("ALTERAR NOME  ·  " + perfil_nome_exibir(), FONTE.PEQUENA))));
        var _tit = (global.perfil.titulo != "") ? global.perfil.titulo : "(nenhum)";
        txt(_gw / 2, 324, "TÍTULO:  «  " + _tit + "  »", FONTE.PEQUENA, _ouro, _a, fa_center, fa_middle, min(1, 500 / max(1, txt_largura("TÍTULO:  «  " + _tit + "  »", FONTE.PEQUENA))));
        var _st = global.perfil.stats;
        var _linhas = [
            ["INIMIGOS DERROTADOS", _st.inimigos], ["JAVALIS DE GUERRA", _st.javalis],
            ["ORBS COLETADAS", _st.orbs], ["EXECUÇÕES", _st.execucoes],
            ["APAROS", _st.aparos], ["MAIOR COMBO", _st.maior_combo],
            ["SEQUÊNCIAS DE GOLPES", _st.sequencias], ["FASES CONCLUÍDAS", _st.fases]
        ];
        for (var _l = 0; _l < array_length(_linhas); _l++)
        {
            var _lx = _gw / 2 + ((_l mod 2 == 0) ? -300 : 40);
            var _ly = 400 + (_l div 2) * 50;
            txt(_lx, _ly, _linhas[_l][0], FONTE.MINI, _cinza, _a, fa_left, fa_middle);
            txt(_lx + 260, _ly, string(round(_linhas[_l][1])), FONTE.PEQUENA, _claro, _a, fa_right, fa_middle);
            draw_set_alpha(_a * 0.4);
            draw_set_color(_ouro);
            draw_line(_lx, _ly + 18, _lx + 260, _ly + 18);
        }
    break;
}

// ----- rodapé -----
txt(_gw / 2, _gh - 24, "ESQUERDA / DIREITA  abas    ·    CIMA / BAIXO  escolher    ·    " + nome_confirmar() + "  confirmar    ·    " + nome_voltar() + "  voltar", FONTE.MINI, _cinza, _a * 0.9, fa_center, fa_middle);
if (mensagem_t > 0) txt_sombra(_gw / 2, _gh - 62, mensagem, FONTE.PEQUENA, _ouro, clamp(mensagem_t / 20, 0, 1), fa_center, fa_middle);

// ===================== NOME (por cima de tudo) =====================
if (estado == "nome")
{
    draw_set_color(c_black);
    draw_set_alpha(0.86);
    draw_rectangle(0, 0, _gw, _gh, false);
    txt_sombra(_gw / 2, 120, (modo == "primeiro") ? "CRIE SEU PERFIL" : "ALTERAR NOME", FONTE.MEDIA, _ouro, 1, fa_center, fa_middle);
    txt(_gw / 2, 160, "Seu nome aparece só nas conquistas. O herói continua sendo Twilight Vetrus.", FONTE.MINI, _cinza, 1, fa_center, fa_middle);
    var _fx1 = _gw / 2 - 270;
    var _fx2 = _gw / 2 + 270;
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(24, 12, 10));
    draw_roundrect_ext(_fx1, 210, _fx2, 280, 10, 10, false);
    draw_set_color(_ouro);
    draw_roundrect_ext(_fx1, 210, _fx2, 280, 10, 10, true);
    var _cursor = ((t div 30) mod 2 == 0) ? "_" : " ";
    txt_sombra(_gw / 2, 245, nome_edit + _cursor, FONTE.MEDIA, c_white, 1, fa_center, fa_middle);
    for (var _i = 0; _i < array_length(teclas); _i++)
    {
        var _tp = tecla_pos(_i);
        var _s = (_i == tecla_sel);
        draw_set_alpha(1);
        draw_set_color(_s ? make_color_rgb(130, 26, 18) : make_color_rgb(38, 18, 16));
        draw_roundrect_ext(_tp[0], _tp[1], _tp[0] + _tp[2], _tp[1] + _tp[3], 8, 8, false);
        draw_set_color(_s ? _ouro : make_color_rgb(110, 84, 70));
        draw_roundrect_ext(_tp[0], _tp[1], _tp[0] + _tp[2], _tp[1] + _tp[3], 8, 8, true);
        txt(_tp[0] + _tp[2] / 2, _tp[1] + _tp[3] / 2, teclas[_i], (_i >= 40) ? FONTE.PEQUENA : FONTE.MEDIA, _s ? c_white : _claro, 1, fa_center, fa_middle);
    }
    txt(_gw / 2, _gh - 24, "Digite no teclado ou toque nas letras    ·    ENTER confirma    ·    " + nome_voltar() + " volta", FONTE.MINI, _cinza, 0.9, fa_center, fa_middle);
}
desenho_resetar();
