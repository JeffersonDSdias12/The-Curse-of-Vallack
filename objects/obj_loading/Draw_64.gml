var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _ouro  = make_color_rgb(255, 210, 90);
var _ouro2 = make_color_rgb(176, 141, 70);
var _num   = max(1, fase_numero(destino));

// ----- escurecer / clarear -----
if (fase == "inicio" or fase == "escurecer")
{
    draw_set_alpha(clamp(tempo / 45, 0, 1));
    draw_set_color(c_black);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    exit;
}
if (fase == "clarear")
{
    draw_set_alpha(1 - clamp(tempo / 40, 0, 1));
    draw_set_color(c_black);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    exit;
}

// ----- fundo preto com brilho vermelho amaldiçoado -----
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
var _pulso = 0.10 + 0.06 * sin(current_time / 400);
retangulo_gradiente(0, _gh * 0.45, _gw, _gh, make_color_rgb(90, 0, 10), 0, make_color_rgb(90, 0, 10), _pulso + 0.15);

// ----- TÍTULO DO CAPÍTULO (letra por letra, efeito amaldiçoado) -----
if (fase == "capitulo")
{
    var _sai = clamp((duracao_capitulo - tempo) / 30, 0, 1);
    var _a = min(clamp(tempo / 25, 0, 1), _sai);
    txt(_cx, _gh / 2 - 92, "CAPÍTULO " + string(_num), FONTE.MEDIA, _ouro, _a, fa_center, fa_middle);
    txt_amaldicoado(_cx, _gh / 2 - 30, fase_nome(_num), FONTE.GRANDE, c_white, tempo - 15, 3, min(1, (_gw * 0.9) / max(1, txt_largura(fase_nome(_num), FONTE.GRANDE))), _sai);
    desenhar_divisor(_cx, _gh / 2 + 22, 240, _a * clamp((tempo - 60) / 30, 0, 1));
    txt_bloco(_cx, _gh / 2 + 44, fase_sub(_num), FONTE.PEQUENA, make_color_rgb(210, 205, 205), _a * clamp((tempo - 70) / 30, 0, 1), min(_gw - 120, 820));
    desenho_resetar();
    exit;
}

// ----- CARREGANDO -----
var _titulo = (modo == "menu") ? "VOLTANDO AO MENU INICIAL" : "CARREGANDO  ·  CAPÍTULO " + string(_num);
var _sub    = (modo == "menu") ? JOGO_TITULO + "  ·  " + JOGO_SUBTITULO : fase_nome(_num);
var _ent = clamp(tempo / 20, 0, 1);
txt_sombra(_cx, _gh * 0.2, _titulo, FONTE.MEDIA, _ouro, _ent, fa_center, fa_middle);
txt(_cx, _gh * 0.2 + 36, _sub, FONTE.PEQUENA, make_color_rgb(200, 200, 205), _ent, fa_center, fa_middle);

// cartão da dica atual (troca com transição suave)
var _pw = min(_gw - 100, 860);
var _py = _gh * 0.36;
desenhar_painel(_cx - _pw / 2, _py, _cx + _pw / 2, _py + 150, 0, _ent);
var _fade_d = min(clamp(dica_tempo / 18, 0, 1), clamp((dica_duracao - dica_tempo) / 18, 0, 1));
var _desloca = (1 - clamp(dica_tempo / 18, 0, 1)) * 16;
txt(_cx, _py + 22, "DICA " + string(dica_atual + 1) + " DE " + string(array_length(dicas)), FONTE.MINI, _ouro2, _ent, fa_center, fa_top);
txt_bloco(_cx + _desloca, _py + 56, dicas[dica_atual], FONTE.PEQUENA, c_white, _ent * _fade_d, _pw - 80);
// pontinhos indicando as dicas
var _nd = array_length(dicas);
var _dx0 = _cx - (_nd - 1) * 7;
for (var _i = 0; _i < _nd; _i++)
{
    draw_set_alpha(_ent * ((_i == dica_atual) ? 1 : 0.3));
    draw_set_color((_i == dica_atual) ? _ouro : c_white);
    draw_circle(_dx0 + _i * 14, _py + 132, (_i == dica_atual) ? 3.5 : 2.5, false);
}
draw_set_alpha(1);

// barra de progresso
var _bw = min(_gw - 160, 640);
var _by = _gh * 0.72;
draw_set_color(make_color_rgb(30, 26, 26));
draw_rectangle(_cx - _bw / 2, _by, _cx + _bw / 2, _by + 16, false);
var _fim = _cx - _bw / 2 + _bw * progresso / 100;
draw_rectangle_color(_cx - _bw / 2, _by, _fim, _by + 16, make_color_rgb(150, 20, 25), make_color_rgb(255, 200, 80), make_color_rgb(255, 200, 80), make_color_rgb(150, 20, 25), false);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.5 + 0.3 * sin(current_time / 90));
draw_set_color(make_color_rgb(255, 140, 60));
draw_circle(_fim, _by + 8, 10, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(_ouro2);
draw_rectangle(_cx - _bw / 2 - 3, _by - 3, _cx + _bw / 2 + 3, _by + 19, true);
var _estado = (progresso >= 100) ? "PRONTO" : "Carregando...  " + string(floor(progresso)) + "%";
txt(_cx, _by + 44, _estado, FONTE.PEQUENA, (progresso >= 100) ? c_white : make_color_rgb(170, 170, 175), 1, fa_center, fa_middle);

// letreiro com todas as dicas passando no rodapé
fonte_usar(FONTE.MINI);
var _lw = txt_largura(letreiro, FONTE.MINI);
if (_lw > 0)
{
    if (letreiro_x < -_lw) letreiro_x += _lw;
    draw_set_alpha(0.55);
    draw_set_color(c_black);
    draw_rectangle(0, _gh - 40, _gw, _gh - 10, false);
    var _lx = letreiro_x;
    while (_lx < _gw)
    {
        txt(_lx, _gh - 25, letreiro, FONTE.MINI, make_color_rgb(230, 190, 120), 0.85, fa_left, fa_middle);
        _lx += _lw;
    }
}

desenho_resetar();
