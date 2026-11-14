// ===== O MAPA DE VALLACK — desenho (interface, 720 de altura) =====
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ouro = make_color_rgb(236, 186, 84);
var _tt = t;
var _q = global.cfg_qualidade;

// ----- céu de brasa e montanhas ao longe (paralaxe) -----
retangulo_gradiente(0, 0, _gw, _gh, make_color_rgb(14, 6, 10), 1, make_color_rgb(46, 12, 8), 1);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.22 + 0.05 * sin(_tt / 40));
draw_set_color(make_color_rgb(190, 50, 20));
draw_ellipse(-_gw * 0.2, _gh * 0.42, _gw * 1.2, _gh * 0.95, false);
gpu_set_blendmode(bm_normal);
for (var _cam = 0; _cam < 2; _cam++)
{
    var _par = (_cam == 0) ? 0.18 : 0.4;
    var _base = (_cam == 0) ? 330 : 400;
    draw_set_color((_cam == 0) ? make_color_rgb(28, 10, 14) : make_color_rgb(18, 6, 8));
    draw_set_alpha(1);
    draw_primitive_begin(pr_trianglestrip);
    for (var _sx = -40; _sx <= _gw + 40; _sx += 40)
    {
        var _wx = _sx + cam_x * _par + _cam * 900;
        var _h = 70 + sin(_wx * 0.0042) * 44 + sin(_wx * 0.0113 + 1.3) * 26 + abs(sin(_wx * 0.021)) * 20;
        draw_vertex(_sx, _base - _h);
        draw_vertex(_sx, _gh);
    }
    draw_primitive_end();
}

// ----- o caminho em chamas -----
var _vis1 = cam_x - 60;
var _vis2 = cam_x + _gw + 60;
var _np = array_length(caminho);
draw_set_color(make_color_rgb(26, 8, 6));
draw_set_alpha(1);
for (var _i = 1; _i < _np; _i++)
{
    var _a = caminho[_i - 1];
    var _b = caminho[_i];
    if (_b[0] < _vis1 or _a[0] > _vis2) continue;
    draw_line_width(_a[0] - cam_x, _a[1], _b[0] - cam_x, _b[1], 26);
}
gpu_set_blendmode(bm_add);
for (var _i = 1; _i < _np; _i++)
{
    var _a = caminho[_i - 1];
    var _b = caminho[_i];
    if (_b[0] < _vis1 or _a[0] > _vis2) continue;
    var _fl = 0.75 + 0.25 * sin(_tt / 6 + _a[2]);
    draw_set_color(make_color_rgb(255, 90, 20));
    draw_set_alpha(0.55 * _fl);
    draw_line_width(_a[0] - cam_x, _a[1], _b[0] - cam_x, _b[1], 12);
    draw_set_color(make_color_rgb(255, 210, 120));
    draw_set_alpha(0.7 * _fl);
    draw_line_width(_a[0] - cam_x, _a[1], _b[0] - cam_x, _b[1], 3);
}
gpu_set_blendmode(bm_normal);
var _passo = (_q == 0) ? 6 : 4;
for (var _i = 0; _i < _np; _i += _passo)
{
    var _c = caminho[_i];
    if (_c[0] < _vis1 or _c[0] > _vis2) continue;
    desenhar_chamas(_c[0] - cam_x, _c[1] + 4, 9, 18 + 8 * sin(_tt / 13 + _c[2]), _tt + _c[2] * 10, 0.9, _c[2], 2);
}

// ----- as fases -----
var _esc_foto = FOTO_W / 320;
for (var _i = 0; _i < n; _i++)
{
    var _nx = no_x(_i) - cam_x;
    if (_nx < -FOTO_W or _nx > _gw + FOTO_W) continue;
    var _ny = no_y(_i);
    var _livre = fase_mapa_livre(_i);
    var _e = (_i == sel) ? 1.1 + 0.02 * sin(_tt / 12) : 1;
    var _w = FOTO_W * _e;
    var _h = FOTO_H * _e;
    var _x1 = _nx - _w / 2;
    var _y1 = _ny - _h / 2;
    var _a = entrada;
    moldura_dourada(_x1, _y1, _x1 + _w, _y1 + _h, _a, (_i == sel) ? 0.6 + 0.4 * sin(_tt / 8) : 0);
    if (img != -1 and sprite_exists(img))
    {
        var _cor = _livre ? c_white : make_color_rgb(175, 165, 168);
        draw_sprite_part_ext(img, 0, (_i mod 6) * 320, (_i div 6) * 180, 320, 180, _x1, _y1, _esc_foto * _e, _esc_foto * _e, _cor, _a);
    }
    else
    {
        draw_set_color(make_color_rgb(30, 14, 14));
        draw_set_alpha(_a);
        draw_rectangle(_x1, _y1, _x1 + _w, _y1 + _h, false);
    }
    if (!_livre)
    {
        draw_set_color(c_black);
        draw_set_alpha(0.28 * _a);
        draw_rectangle(_x1, _y1, _x1 + _w, _y1 + _h, false);
        cadeado_grande(_nx, _ny - 18, 1.2 * _e, _a);
        txt_sombra(_nx, _ny + 36 * _e, "EM DESENVOLVIMENTO", FONTE.MINI, make_color_rgb(255, 196, 150), _a, fa_center, fa_middle);
    }
    else
    {
        // a fase aberta: anel de fogo pulsando e "DISPONÍVEL"
        txt_sombra(_nx, _y1 + _h - 14, "DISPONÍVEL", FONTE.MINI, make_color_rgb(140, 255, 140), _a * (0.7 + 0.3 * sin(_tt / 10)), fa_center, fa_middle);
    }
    // marco no caminho com o número romano e o nome da fase
    var _my = _ny + 96;
    draw_set_alpha(_a);
    draw_set_color(make_color_rgb(30, 12, 8));
    draw_circle(_nx, _my, 19, false);
    draw_set_color(_livre ? _ouro : make_color_rgb(150, 120, 90));
    draw_circle(_nx, _my, 19, true);
    draw_circle(_nx, _my, 16, true);
    txt(_nx, _my, romano(_i + 1), FONTE.MINI, _livre ? _ouro : make_color_rgb(190, 160, 130), _a, fa_center, fa_middle, min(1, 26 / max(1, txt_largura(romano(_i + 1), FONTE.MINI))));
    txt_sombra(_nx, _y1 - 18, fases[_i].nome, FONTE.MINI, (_i == sel) ? c_white : make_color_rgb(210, 190, 180), _a, fa_center, fa_middle, min(1, (FOTO_W + 50) / max(1, txt_largura(fases[_i].nome, FONTE.MINI))));
}

// ----- o dragão voando ao lado da última fase (o covil do chefão) -----
var _dxn = no_x(n - 1) - cam_x;
if (_dxn > -400 and _dxn < _gw + 400)
{
    var _ang = _tt * 0.018;
    var _drx = _dxn + 250 + sin(_ang) * 95;
    var _dry = no_y(n - 1) - 10 + sin(_ang * 2) * 44;
    var _ddir = (cos(_ang) >= 0) ? 1 : -1;
    var _ciclo = _tt mod 420;
    var _fogo = (_ciclo > 330) ? sin(pi * (_ciclo - 330) / 90) : 0;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.22);
    draw_set_color(make_color_rgb(255, 60, 20));
    draw_circle(_drx, _dry, 120, false);
    draw_set_alpha(0.18);
    draw_circle(_drx, _dry, 60, false);
    gpu_set_blendmode(bm_normal);
    dragao_desenhar(_drx, _dry, 1.7, _ddir, _tt, _fogo);
}

// brasas
gpu_set_blendmode(bm_add);
for (var _b = 0; _b < array_length(brasas); _b++)
{
    var _br = brasas[_b];
    draw_set_alpha(clamp(_br.v / 50, 0, 1) * 0.9);
    draw_set_color(choose(make_color_rgb(255, 160, 60), make_color_rgb(255, 90, 30)));
    draw_circle(_br.x - cam_x, _br.y, _br.r, false);
}
gpu_set_blendmode(bm_normal);

// ----- topo: título e VOLTAR -----
retangulo_gradiente(0, 0, _gw, 96, c_black, 0.85, c_black, 0);
txt_sombra(_gw / 2, 36, "MAPA DE VALLACK", FONTE.MEDIA, _ouro, entrada, fa_center, fa_middle);
txt(_gw / 2, 68, "Escolha a fase e a dificuldade   ·   arraste para ver o caminho", FONTE.MINI, make_color_rgb(210, 190, 180), entrada, fa_center, fa_middle);
hud_faixa(24, 22, 170, 66, 0.9 * entrada);
txt(97, 44, "VOLTAR", FONTE.MINI, c_white, entrada, fa_center, fa_middle);

// ----- painel de baixo: a fase escolhida, a dificuldade e JOGAR -----
var _py = _gh - 196;
retangulo_gradiente(0, _py - 30, _gw, _gh, c_black, 0, c_black, 0.92);
hud_faixa(30, _py, _gw - 30, _gh - 16, 0.95 * entrada);
var _f = fases[sel];
var _livre_sel = fase_mapa_livre(sel);
txt(64, _py + 30, "FASE " + romano(sel + 1), FONTE.MINI, _ouro, entrada, fa_left, fa_middle);
var _larg_txt = _gw - 64 - 520;
txt_sombra(64, _py + 62, _f.nome, FONTE.MEDIA, c_white, entrada, fa_left, fa_middle, min(1, _larg_txt / max(1, txt_largura(_f.nome, FONTE.MEDIA))));
txt_bloco(64, _py + 92, _f.desc, FONTE.MINI, make_color_rgb(220, 205, 195), entrada, _larg_txt, fa_left, fa_top);
if (!_livre_sel)
{
    cadeado_grande(64 + 14, _py + 150, 0.8, entrada);
    txt(64 + 40, _py + 156, "EM DESENVOLVIMENTO", FONTE.PEQUENA, make_color_rgb(255, 170, 120), entrada, fa_left, fa_middle);
}
// dificuldade (« »)
var _dcx = _gw - 260;
txt(_dcx, _py + 26, "DIFICULDADE", FONTE.MINI, _ouro, entrada, fa_center, fa_middle);
txt(_gw - 445, _py + 65, "«", FONTE.MEDIA, c_white, entrada, fa_center, fa_middle);
txt(_gw - 75, _py + 65, "»", FONTE.MEDIA, c_white, entrada, fa_center, fa_middle);
txt_sombra(_dcx, _py + 65, dificuldade_nome(dif), FONTE.MEDIA, dificuldade_cor(dif), entrada, fa_center, fa_middle);
var _dd = dificuldade_descricao(dif);
txt(_dcx, _py + 98, _dd[0], FONTE.MINI, make_color_rgb(200, 185, 175), entrada, fa_center, fa_middle, min(1, 360 / max(1, txt_largura(_dd[0], FONTE.MINI))));
// JOGAR
var _bj = [_gw - 300, _py + 118, _gw - 50, _py + 172];
var _pul = 0.75 + 0.25 * sin(_tt / 9);
draw_set_alpha(entrada);
draw_set_color(_livre_sel ? make_color_rgb(120, 20, 14) : make_color_rgb(50, 40, 40));
draw_roundrect_ext(_bj[0], _bj[1], _bj[2], _bj[3], 10, 10, false);
draw_set_color(_livre_sel ? merge_color(_ouro, c_white, 0.2 * _pul) : make_color_rgb(110, 100, 96));
draw_roundrect_ext(_bj[0], _bj[1], _bj[2], _bj[3], 10, 10, true);
txt_sombra((_bj[0] + _bj[2]) / 2, (_bj[1] + _bj[3]) / 2, _livre_sel ? "JOGAR" : "TRANCADA", FONTE.PEQUENA, _livre_sel ? c_white : make_color_rgb(170, 160, 156), entrada, fa_center, fa_middle);

// aviso (fase trancada)
if (aviso_t > 0)
{
    var _aa = clamp(aviso_t / 20, 0, 1);
    txt_sombra(_gw / 2, _py - 26, aviso_txt, FONTE.PEQUENA, make_color_rgb(255, 160, 120), _aa, fa_center, fa_middle, min(1, (_gw - 80) / max(1, txt_largura(aviso_txt, FONTE.PEQUENA))));
}

// v1.19: a entrada é revelada pelo véu (transicao_revelar no Create); ao jogar,
// a cortina em brasa fecha a tela da esquerda para a direita
if (saindo >= 0)
{
    var _ks = clamp(saindo / 30, 0, 1);
    transicao_cortina_desenhar(_ks * _ks * (3 - 2 * _ks));
}
desenho_resetar();
