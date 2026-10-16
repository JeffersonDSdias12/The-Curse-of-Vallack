var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ouro = make_color_rgb(255, 210, 90);
var _ouro2 = make_color_rgb(176, 141, 70);
var _cinza = make_color_rgb(150, 145, 140);
var _ab = clamp(abre, 0, 1);
var _e = 1 - power(1 - _ab, 3);
var _t = current_time / 16;

// fundo: o jogo parado, avermelhado
if (foto != -1 and sprite_exists(foto)) draw_sprite_stretched(foto, 0, 0, 0, _gw, _gh);
draw_set_alpha(0.8 * _e);
draw_set_color(make_color_rgb(14, 4, 4));
draw_rectangle(0, 0, _gw, _gh, false);
desenhar_vinheta(_gw, _gh, 0.75 * _e, make_color_rgb(70, 0, 0));
// névoa vermelha subindo
gpu_set_blendmode(bm_add);
for (var _n = 0; _n < 6; _n++)
{
    var _nx = (_gw * frac(_n * 0.37 + _t / 1400)) ;
    draw_set_alpha(0.05 * _e);
    draw_set_color(make_color_rgb(200, 30, 20));
    draw_ellipse(_nx - 260, _gh - 260 - _n * 30, _nx + 260, _gh + 40, false);
}
gpu_set_blendmode(bm_normal);

// corte carmesim na abertura
var _corte = fechando ? (1 - _ab) : _ab;
if (_corte < 1)
{
    gpu_set_blendmode(bm_add);
    var _ly = lerp(-40, _gh + 40, _corte);
    draw_set_alpha(0.7 * (1 - _corte));
    draw_set_color(make_color_rgb(230, 40, 30));
    draw_rectangle(0, _ly - 3, _gw, _ly + 3, false);
    gpu_set_blendmode(bm_normal);
}

var _desl = (1 - _e) * 220;
// ----- TÍTULO -----
txt_sombra(_gw / 2, 44 - (1 - _e) * 40, "ARMAS", FONTE.GRANDE, _ouro, _e, fa_center, fa_middle, 1.05);
desenhar_divisor(_gw / 2, 80 - (1 - _e) * 40, 200, _e);

// ----- PAINEL DA ESPADA (esquerda) -----
var _px1 = 36 - _desl;
var _px2 = _px1 + min(420, _gw * 0.32);
var _pcx = (_px1 + _px2) / 2;
desenhar_painel(_px1, 104, _px2, _gh - 110, 0, _e * 0.95);
txt_sombra(_pcx, 132, espada_nome(), FONTE.MEDIA, c_white, _e, fa_center, fa_middle, min(1, (_px2 - _px1 - 30) / max(1, txt_largura(espada_nome(), FONTE.MEDIA))));
txt(_pcx, 162, "NÍVEL " + string(global.espada_nivel) + " / " + string(ESPADA_NIVEL_MAX), FONTE.PEQUENA, _ouro, _e, fa_center, fa_middle);
// a espada (desenhada) com runas que acendem por nível
var _sy1 = 190;
var _sy2 = _gh - 230;
var _bri = (evoluiu_fx > 0) ? evoluiu_fx / 90 : 0;
desenhar_espada_grande(_pcx, _sy1, _sy2, global.espada_nivel, _e, _bri, _t);
// bônus
var _by = _gh - 200;
txt(_pcx, _by, "DANO  +" + string(round((espada_dano_mult() - 1) * 100)) + "%", FONTE.PEQUENA, c_white, _e, fa_center, fa_middle);
txt(_pcx, _by + 26, "ESPECIAIS  +" + string(round(5 * (global.espada_nivel - 1))) + "%", FONTE.MINI, make_color_rgb(230, 210, 200), _e, fa_center, fa_middle);
if (global.espada_nivel >= 5) txt(_pcx, _by + 48, "FÚRIA ENCHE 35% MAIS RÁPIDO", FONTE.MINI, make_color_rgb(255, 140, 90), _e, fa_center, fa_middle);

// ----- NÍVEIS (meio) -----
var _mx1 = _px2 + 24 + _desl * 0.3;
var _mx2 = _mx1 + min(470, _gw * 0.36);
// tela estreita (4:3): sem a coluna da direita, os níveis ocupam o espaço
if ((_gw - 36) - (_mx2 + 24) <= 220) _mx2 = _gw - 36;
var _niv = espada_niveis();
var _lh = 86;
var _ly0 = 112;
for (var _i = 0; _i < array_length(_niv); _i++)
{
    var _nv = _niv[_i];
    var _y1 = _ly0 + _i * (_lh + 6);
    var _ao = clamp(_e * 1.5 - _i * 0.1, 0, 1);
    var _tem = (global.espada_nivel >= _nv.nivel);
    var _prox = (global.espada_nivel + 1 == _nv.nivel);
    desenhar_painel(_mx1, _y1, _mx2, _y1 + _lh, _prox ? 1 : 0, _ao * (_tem or _prox ? 0.95 : 0.6));
    // joia do nível
    var _jx = _mx1 + 34;
    var _jy = _y1 + _lh / 2;
    var _jc = _tem ? make_color_rgb(230, 40, 30) : (_prox ? make_color_rgb(130, 50, 40) : make_color_rgb(60, 50, 50));
    draw_set_alpha(_ao);
    draw_set_color(_ouro2);
    draw_triangle(_jx, _jy - 20, _jx + 17, _jy, _jx, _jy + 20, false);
    draw_triangle(_jx, _jy - 20, _jx - 17, _jy, _jx, _jy + 20, false);
    draw_set_color(_jc);
    draw_triangle(_jx, _jy - 15, _jx + 12, _jy, _jx, _jy + 15, false);
    draw_triangle(_jx, _jy - 15, _jx - 12, _jy, _jx, _jy + 15, false);
    if (_tem)
    {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_ao * (0.3 + 0.2 * sin(_t / 10 + _i)));
        draw_circle(_jx, _jy, 22, false);
        gpu_set_blendmode(bm_normal);
    }
    txt(_jx, _jy, string(_nv.nivel), FONTE.PEQUENA, _tem ? c_white : _cinza, _ao, fa_center, fa_middle);
    // o que libera
    var _tx = _mx1 + 66;
    var _desc = "";
    for (var _k = 0; _k < array_length(_nv.itens); _k++)
    {
        var _it = _nv.itens[_k];
        _desc += ((_k > 0) ? "  +  " : "") + ((_it.tipo == "combo") ? ("COMBO " + string(_it.n)) : especial_nome(_it.acao));
    }
    // 1ª linha: o que libera (largura toda); 2ª linha: bônus à esquerda e custo à direita
    txt(_tx, _y1 + 24, _desc, FONTE.PEQUENA, _tem ? _ouro : (_prox ? c_white : _cinza), _ao, fa_left, fa_middle, min(1, (_mx2 - _tx - 16) / max(1, txt_largura(_desc, FONTE.PEQUENA))));
    var _st = _tem ? "OBTIDO" : (string(espada_custo(_nv.nivel)) + " ORBS");
    var _sc = _tem ? make_color_rgb(140, 220, 120) : ((global.orbs >= espada_custo(_nv.nivel) and _prox) ? _ouro : make_color_rgb(220, 120, 100));
    var _wst = txt_largura(_st, FONTE.PEQUENA);
    txt(_tx, _y1 + 58, _nv.texto, FONTE.MINI, _tem ? make_color_rgb(225, 215, 205) : _cinza, _ao, fa_left, fa_middle, min(1, (_mx2 - _tx - _wst - 32) / max(1, txt_largura(_nv.texto, FONTE.MINI))));
    txt(_mx2 - 16, _y1 + 58, _st, FONTE.PEQUENA, _sc, _ao, fa_right, fa_middle);
    // barra de evolução (segurando)
    if (_prox and segurar > 0)
    {
        draw_set_alpha(_ao);
        draw_set_color(make_color_rgb(255, 60, 40));
        draw_rectangle(_mx1 + 4, _y1 + _lh - 7, _mx1 + 4 + (_mx2 - _mx1 - 8) * segurar, _y1 + _lh - 3, false);
    }
}
draw_set_alpha(1);

// ----- GOLPES (direita) -----
var _rx1 = _mx2 + 24 + _desl;
var _rx2 = _gw - 36 + _desl;
if (_rx2 - _rx1 > 220)
{
    desenhar_painel(_rx1, 104, _rx2, _gh - 110, 0, _e * 0.95);
    var _rcx = (_rx1 + _rx2) / 2;
    txt(_rcx, 128, "COMBOS", FONTE.PEQUENA, _ouro, _e, fa_center, fa_middle);
    var _cb = combos_lista();
    var _yy = 156;
    for (var _c = 0; _c < 3; _c++)
    {
        var _lib = combo_liberado(_c + 1);
        var _xx = _rx1 + 18;
        for (var _s = 0; _s < array_length(_cb[_c].seq); _s++)
        {
            _xx += desenhar_icone_acao(_xx, _yy + 12, _cb[_c].seq[_s], 22, _e * (_lib ? 1 : 0.4)) + 4;
        }
        txt(_xx + 6, _yy + 12, _lib ? _cb[_c].nome : ("NÍVEL " + string(combo_nivel_req(_c + 1))), FONTE.MINI, _lib ? c_white : _cinza, _e, fa_left, fa_middle, min(1, (_rx2 - _xx - 16) / max(1, txt_largura(_cb[_c].nome, FONTE.MINI))));
        _yy += 40;
    }
    _yy += 12;
    txt(_rcx, _yy, "ESPECIAIS (MAGIA)", FONTE.PEQUENA, _ouro, _e, fa_center, fa_middle);
    _yy += 28;
    var _esps = [ACAO.ESPECIAL_3, ACAO.ESPECIAL, ACAO.ESPECIAL_2];
    for (var _q = 0; _q < 3; _q++)
    {
        var _ac = _esps[_q];
        var _lb = especial_liberado(_ac);
        var _w = desenhar_icone_acao(_rx1 + 18, _yy + 12, _ac, 24, _e * (_lb ? 1 : 0.4));
        var _nm = especial_nome(_ac);
        txt(_rx1 + 28 + _w, _yy + 4, _nm, FONTE.MINI, _lb ? c_white : _cinza, _e, fa_left, fa_middle, min(1, (_rx2 - _rx1 - 40 - _w) / max(1, txt_largura(_nm, FONTE.MINI))));
        txt(_rx1 + 28 + _w, _yy + 22, _lb ? (string(round(especial_custo(_ac) * 100)) + "% da magia") : ("bloqueado: nível " + string(especial_nivel_req(_ac))), FONTE.MINI, _lb ? make_color_rgb(150, 200, 255) : make_color_rgb(200, 110, 100), _e * 0.9, fa_left, fa_middle, 0.85);
        _yy += 46;
    }
    _yy += 6;
    txt(_rcx, _yy, "FÚRIA", FONTE.PEQUENA, _ouro, _e, fa_center, fa_middle);
    var _wf = desenhar_icone_acao(_rx1 + 18, _yy + 30, ACAO.FURIA, 24, _e);
    txt(_rx1 + 28 + _wf, _yy + 30, "Ira de Vallack (barra cheia)", FONTE.MINI, c_white, _e, fa_left, fa_middle, min(1, (_rx2 - _rx1 - 44 - _wf) / max(1, txt_largura("Ira de Vallack (barra cheia)", FONTE.MINI))));
}

// ----- POTE DE ORBS e instrução (embaixo) -----
var _oy = _gh - 64;
var _ox = _gw / 2 - 200;
desenhar_pote_orbs(_ox, _oy, 1.3, _e, global.orbs_fx);
txt_sombra(_ox + 40, _oy, string(round(orbs_vis)), FONTE.MEDIA, make_color_rgb(255, 120, 100), _e, fa_left, fa_middle);
txt(_ox + 40, _oy + 26, "ORBS", FONTE.MINI, _ouro2, _e, fa_left, fa_middle);
var _proxn = global.espada_nivel + 1;
var _msg;
if (_proxn > ESPADA_NIVEL_MAX) _msg = "A LÂMINA ESTÁ NO NÍVEL MÁXIMO";
else if (global.orbs >= espada_custo(_proxn)) _msg = "SEGURE  PARA EVOLUIR AO NÍVEL " + string(_proxn);
else _msg = "FALTAM " + string(espada_custo(_proxn) - global.orbs) + " ORBS PARA O NÍVEL " + string(_proxn);
var _mc = (negado_fx > 0) ? make_color_rgb(255, 90, 70) : c_white;
var _mxp = _gw / 2 + 10;
if (_proxn <= ESPADA_NIVEL_MAX and global.orbs >= espada_custo(_proxn))
{
    var _wi = (global.usando_pad and global.pad_slot >= 0) ? desenhar_icone_pad(_mxp, _oy, gp_face1, 28, _e) : desenhar_tecla(_mxp, _oy, "ENTER", 28, _e);
    _mxp += _wi + 10;
}
txt_sombra(_mxp, _oy, _msg, FONTE.PEQUENA, _mc, _e * (0.85 + 0.15 * sin(_t / 8)), fa_left, fa_middle, min(1, (_gw - _mxp - 30) / max(1, txt_largura(_msg, FONTE.PEQUENA))));
txt(_gw / 2, _gh - 22, botao_menu_armas() + " / " + nome_voltar() + " fecha", FONTE.MINI, _cinza, _e, fa_center, fa_middle);

// orbs voando do pote até a espada
gpu_set_blendmode(bm_add);
for (var _f2 = 0; _f2 < array_length(fluxo); _f2++)
{
    var _o = fluxo[_f2];
    var _k = _o.t;
    var _fx = lerp(_ox + _o.ox, _pcx, _k);
    var _fy = lerp(_oy + _o.oy, (_sy1 + _sy2) / 2, _k) - sin(_k * pi) * 120;
    draw_set_alpha(0.9 * (1 - _k * 0.5));
    draw_set_color(make_color_rgb(255, 60, 40));
    draw_circle(_fx, _fy, 5, false);
    draw_set_color(make_color_rgb(255, 210, 180));
    draw_circle(_fx, _fy, 2, false);
}
// faíscas da evolução
for (var _f3 = 0; _f3 < array_length(faiscas); _f3++)
{
    var _fz = faiscas[_f3];
    draw_set_alpha(_fz.vida / _fz.vmax);
    draw_set_color(make_color_rgb(255, 160 + 80 * (_fz.vida / _fz.vmax), 60));
    draw_circle(_pcx - 250 + _fz.x, _fz.y, 3, false);
}
gpu_set_blendmode(bm_normal);

// evoluiu!
if (evoluiu_fx > 0)
{
    var _ea = clamp(evoluiu_fx / 20, 0, 1) * clamp((90 - evoluiu_fx) / 8, 0, 1);
    var _esc = 1 + 0.2 * clamp((evoluiu_fx - 75) / 15, 0, 1);
    draw_set_alpha(_ea * 0.6);
    draw_set_color(c_black);
    draw_rectangle(0, _gh / 2 - 44, _gw, _gh / 2 + 44, false);
    txt_sombra(_gw / 2, _gh / 2, evoluiu_txt, FONTE.MEDIA, _ouro, _ea, fa_center, fa_middle, min(_esc, (_gw - 80) / max(1, txt_largura(evoluiu_txt, FONTE.MEDIA))));
}
desenho_resetar();
