var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _ouro = make_color_rgb(255, 210, 90);
var _ouro2 = make_color_rgb(176, 141, 70);

// escurecendo sobre o jogo
var _esc = (fase == "escurecer") ? clamp(tempo / 110, 0, 1) : 1;
draw_set_alpha(_esc * ((fase == "resultado") ? 0.88 : 1));
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
draw_set_alpha(1);

if (fase == "resultado")
{
    desenhar_vinheta(_gw, _gh, 0.7, make_color_rgb(50, 0, 0));
    var _a0 = clamp(mostrar_t / 30, 0, 1);
    txt_amaldicoado(_cx, 92, "CAPÍTULO I CONCLUÍDO", FONTE.GRANDE, make_color_rgb(235, 45, 35), mostrar_t, 3, min(1, (_gw * 0.85) / max(1, txt_largura("CAPÍTULO I CONCLUÍDO", FONTE.GRANDE))), _a0);
    txt(_cx, 146, "A CAMINHO DO CASTELO  ·  RESULTADO", FONTE.PEQUENA, _ouro, _a0, fa_center, fa_middle);
    desenhar_divisor(_cx, 172, 240, _a0);
    var _pw = min(_gw - 120, 640);
    for (var _i = 0; _i < array_length(linhas); _i++)
    {
        var _ln = linhas[_i];
        var _k = clamp((mostrar_t - 40 - _i * 26) / 22, 0, 1);
        if (_k <= 0) continue;
        var _y = 216 + _i * 62;
        desenhar_painel(_cx - _pw / 2 + (1 - _k) * 60, _y - 24, _cx + _pw / 2 + (1 - _k) * 60, _y + 24, 0, _k);
        txt(_cx - _pw / 2 + 24 + (1 - _k) * 60, _y, _ln.nome, FONTE.PEQUENA, c_white, _k, fa_left, fa_middle);
        var _v = _ln.valor * clamp((mostrar_t - 40 - _i * 26) / 40, 0, 1);    // contagem subindo
        var _s = "";
        switch (_ln.tipo)
        {
            case "tempo": _s = tempo_texto(_v); break;
            case "num":   _s = string(round(_v)); break;
            case "nivel": _s = string(round(_v)) + " / " + string(ESPADA_NIVEL_MAX); break;
            case "pct":   _s = string(round(_v)) + "%"; break;
            case "dif":   _s = dificuldade_nome(); break;
        }
        txt(_cx + _pw / 2 - 24 + (1 - _k) * 60, _y, _s, FONTE.MEDIA, (_ln.tipo == "dif") ? dificuldade_cor() : _ouro, _k, fa_right, fa_middle);
    }
    if (pode_continuar)
    {
        var _ra = 0.7 + 0.3 * sin(current_time / 160);
        var _ry = _gh - 46;
        var _w = 28 + 18 + desenhar_tecla_largura("ENTER", 28) + 12 + txt_largura("CONTINUAR", FONTE.PEQUENA);
        var _rx = _cx - _w / 2;
        _rx += desenhar_icone_pad(_rx, _ry, gp_face1, 28, _ra);
        txt(_rx + 9, _ry, "/", FONTE.PEQUENA, _ouro2, _ra, fa_center, fa_middle);
        _rx += 18;
        _rx += desenhar_tecla(_rx, _ry, "ENTER", 28, _ra);
        txt(_rx + 12, _ry, "CONTINUAR", FONTE.PEQUENA, _ouro, _ra, fa_left, fa_middle);
    }
}

if (fase == "obrigado" or fase == "sair")
{
    var _a = (fase == "obrigado") ? min(clamp(tempo / 50, 0, 1), 1) : max(0, 1 - tempo / 50);
    desenhar_vinheta(_gw, _gh, 0.8, make_color_rgb(40, 0, 0));
    var _txt = "Obrigado por jogar nossa Demo.";
    txt_amaldicoado(_cx, _gh * 0.44, _txt, FONTE.GRANDE, make_color_rgb(240, 225, 200), (fase == "obrigado") ? tempo : 999, 2, min(1, (_gw * 0.88) / max(1, txt_largura(_txt, FONTE.GRANDE))), _a);
    txt(_cx, _gh * 0.44 + 62, JOGO_TITULO + "  ·  " + JOGO_SUBTITULO, FONTE.PEQUENA, _ouro, _a * clamp((tempo - 60) / 40, 0, 1), fa_center, fa_middle);
    txt(_cx, _gh * 0.44 + 96, "Jefferson Dias  ·  Eduardo  ·  Isaac  ·  Alex  ·  Aldreon  —  Faculdade FAPAN", FONTE.MINI, make_color_rgb(200, 190, 180), _a * clamp((tempo - 90) / 40, 0, 1), fa_center, fa_middle);
    txt(_cx, _gh * 0.44 + 124, "A jornada continua em breve...", FONTE.MINI, make_color_rgb(230, 120, 100), _a * clamp((tempo - 140) / 40, 0, 1), fa_center, fa_middle);
}

// brasas
gpu_set_blendmode(bm_add);
for (var _b = 0; _b < array_length(brasas); _b++)
{
    var _br = brasas[_b];
    var _p = _br.vida / _br.vmax;
    draw_set_alpha(min(1, _p * 1.4) * 0.8);
    draw_set_color(make_color_rgb(255, 90 + 110 * _p, 40));
    draw_circle(_br.x + sin((_br.y + _b * 20) / 30) * 6, _br.y, 2.2, false);
}
gpu_set_blendmode(bm_normal);
desenho_resetar();
