var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ouro = make_color_rgb(255, 210, 90);
var _a = min(1, tempo / 12);
if (confirmado) _a = 1;

draw_set_alpha(0.93 * _a);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
desenhar_vinheta(_gw, _gh, 0.5 * _a, make_color_rgb(50, 0, 6));

txt_sombra(_gw / 2, 150, (modo == "salvar") ? "SALVAR JOGO" : "CARREGAR JOGO", FONTE.GRANDE, _ouro, _a, fa_center, fa_middle);
desenhar_divisor(_gw / 2, 192, 220, _a);
txt(_gw / 2, 240, "Escolha um dos três slots", FONTE.PEQUENA, c_white, _a, fa_center, fa_middle);

var _cartao = min(300, _gw * 0.23);
for (var _i = 0; _i < 3; _i++)
{
    var _x = _gw * (_i + 1) / 4;
    var _sel = (selecionado == _i) ? 1 : 0;
    var _info = slots[_i];
    desenhar_painel(_x - _cartao / 2, 300, _x + _cartao / 2, 500, _sel, _a);
    txt(_x, 334, "SLOT " + string(_i + 1), FONTE.MEDIA, _ouro, _a, fa_center, fa_middle);
    if (_info.existe)
    {
        txt(_x, 372, string_upper(_info.nome), FONTE.PEQUENA, c_white, _a, fa_center, fa_middle, min(1, (_cartao - 24) / max(1, txt_largura(string_upper(_info.nome), FONTE.PEQUENA))));
        txt(_x, 396, dificuldade_nome(_info.dificuldade), FONTE.MINI, dificuldade_cor(_info.dificuldade), _a, fa_center, fa_middle);
        txt(_x, 422, "CAPÍTULO " + string(_info.fase), FONTE.MINI, make_color_rgb(176, 141, 70), _a, fa_center, fa_middle);
        txt_bloco(_x, 436, fase_nome(_info.fase), FONTE.MINI, make_color_rgb(215, 210, 205), _a, _cartao - 24);
        if (_info.data != "") txt(_x, 484, _info.data, FONTE.MINI, make_color_rgb(140, 140, 145), _a, fa_center, fa_middle, 0.85);
    }
    else txt(_x, 410, "VAZIO", FONTE.PEQUENA, make_color_rgb(140, 140, 145), _a, fa_center, fa_middle);
}

if (confirmado) txt_sombra(_gw / 2, 552, "JOGO SALVO NO SLOT " + string(selecionado + 1), FONTE.MEDIA, make_color_rgb(140, 255, 150), 1, fa_center, fa_middle);
txt_bloco(_gw / 2, _gh - 104, "DICA  ·  " + dicas[dica_atual], FONTE.MINI, _ouro, _a, min(_gw - 120, 900));
txt(_gw / 2, _gh - 40, "« » escolhe   ·   " + nome_confirmar() + " confirma   ·   " + nome_voltar() + " cancela", FONTE.MINI, make_color_rgb(190, 190, 190), _a, fa_center, fa_middle);
desenho_resetar();
