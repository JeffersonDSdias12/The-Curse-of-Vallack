var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _n = array_length(imagens);

// fundo preto (a imagem é mostrada inteira, sem cortar, com barras se precisar)
draw_set_alpha(1);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
if (_n == 0 or fase == "fim") exit;

var _i = min(indice, _n - 1);
var _a = 1;
if (fase == "entrando") _a = clamp(tempo / 50, 0, 1);
else if (fase == "saindo") _a = clamp(1 - tempo / 45, 0, 1);
imagem_desenhar_ajustada(imagens[_i], 0, 0, _gw, _gh, _a);
if (fase == "trocando" and _i + 1 < _n) imagem_desenhar_ajustada(imagens[_i + 1], 0, 0, _gw, _gh, clamp(troca, 0, 1));

// canto de cima: página e botões
if (fase == "mostrando" or fase == "trocando")
{
    var _ha = (fase == "mostrando") ? clamp((tempo - 20) / 20, 0, 1) : 0.6;
    var _pisca = 0.75 + 0.25 * sin(current_time / 180);
    var _conf = usando_controle() ? nome_confirmar() : "X / ENTER";
    var _txt = _conf + "  continua   ·   " + nome_voltar() + "  pula";
    var _pag = string(min(_i + 1 + ((fase == "trocando") ? 1 : 0), _n)) + " / " + string(_n);
    var _w = txt_largura(_txt, FONTE.MINI) + txt_largura(_pag, FONTE.MINI) + 60;
    draw_set_alpha(0.55 * _ha);
    draw_set_color(c_black);
    draw_roundrect_ext(_gw - _w - 18, 10, _gw - 10, 42, 10, 10, false);
    draw_set_alpha(1);
    txt(_gw - 30, 26, _txt, FONTE.MINI, make_color_rgb(235, 220, 190), _ha * _pisca, fa_right, fa_middle);
    txt(_gw - _w - 4, 26, _pag, FONTE.MINI, make_color_rgb(255, 210, 90), _ha, fa_left, fa_middle);
}
desenho_resetar();
