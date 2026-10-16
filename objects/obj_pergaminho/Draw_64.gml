var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _n = array_length(paginas);

// fundo: o jogo congelado, escurecido
var _ft = (foto_externa != -1 and sprite_exists(foto_externa)) ? foto_externa : foto;
if (_ft != -1 and sprite_exists(_ft)) draw_sprite_stretched(_ft, 0, 0, 0, _gw, _gh);
var _fa = clamp(fechando ? abre : tempo / 14, 0, 1);
draw_set_alpha(0.62 * _fa);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
desenhar_vinheta(_gw, _gh, 0.7 * _fa, make_color_rgb(30, 4, 2));

var _tam = pergaminho_tamanho();
var _pag = tutorial_pagina(paginas[pagina]);
var _ind = modo_livro ? ("«  " + string(pagina + 1) + " / " + string(_n) + "  »") : "";
var _rod = (pagina < _n - 1) ? "PRÓXIMA PÁGINA" : (modo_livro ? "FECHAR" : "CONTINUAR");
var _ra = clamp((tempo - 26) / 16, 0, 1) * (0.75 + 0.25 * sin(current_time / 160));
pergaminho_desenhar(_gw / 2, _gh / 2, _tam[0], _tam[1], abre, _pag, 1, _rod, _ind, _ra);

if (modo_livro and !fechando)
    txt(_gw / 2, _gh - 22, "«  »  trocam de página   ·   " + nome_voltar() + " fecha", FONTE.MINI, make_color_rgb(200, 190, 175), _fa, fa_center, fa_middle);
desenho_resetar();
