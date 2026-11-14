if (pendente) exit;
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
// o jogo congelado ao fundo (os objetos estão desativados durante o diálogo)
if (foto != -1 and sprite_exists(foto)) draw_sprite_stretched(foto, 0, 0, 0, _gw, _gh);
var _e = 1 - power(1 - abre, 3);
retangulo_gradiente(0, _gh - 300, _gw, _gh, c_black, 0, c_black, 0.8 * _e);
if (array_length(falas) == 0) exit;
var _f = falas[i];
var _cor = dialogo_cor(_f.q);
var _bw = min(_gw - 80, 1100);
var _bx1 = (_gw - _bw) / 2;
var _bx2 = _bx1 + _bw;
var _sobe = (1 - _e) * 40;
var _by2 = _gh - 34 + _sobe;
var _by1 = _by2 - 176;
desenhar_painel(_bx1, _by1, _bx2, _by2, 0, 0.94 * _e);
// retrato de quem fala
var _rw = 150;
var _rx1 = _bx1 + 16;
var _ry1 = _by1 + 13;
var _rx2 = _rx1 + _rw;
var _ry2 = _by2 - 13;
draw_set_alpha(0.9 * _e);
draw_set_color(make_color_rgb(16, 12, 18));
draw_rectangle(_rx1, _ry1, _rx2, _ry2, false);
var _r = dialogo_retrato(_f.q);
if (_r[0] != -1)
{
    var _spr = _r[0];
    var _k = hd_escala(_spr);
    var _hw = sprite_get_height(_spr) / _k;
    var _ww = sprite_get_width(_spr) / _k;
    var _s = min((_ry2 - _ry1 - 14) / _hw, (_rw - 14) / _ww);
    var _ox = sprite_get_xoffset(_spr) / _k;
    var _oy = sprite_get_yoffset(_spr) / _k;
    var _cx = (_rx1 + _rx2) / 2 - (_ww / 2 - _ox) * _s;
    var _cy = _ry2 - 7 - (_hw - _oy) * _s;
    draw_sprite_hd(_spr, _r[1], _cx, _cy, _s, _s, 0, _r[2], _e);
}
draw_set_alpha(_e);
draw_set_color(_cor);
draw_rectangle(_rx1, _ry1, _rx2, _ry2, true);
// nome e fala
var _tx = _rx2 + 24;
var _tw = _bx2 - 26 - _tx;
txt(_tx, _by1 + 18, dialogo_nome(_f.q), FONTE.PEQUENA, _cor, _e, fa_left, fa_top);
txt_bloco(_tx, _by1 + 56, string_copy(_f.t, 1, floor(letras)), FONTE.PEQUENA, c_white, _e, _tw, fa_left, fa_top);
if (letras >= string_length(_f.t))
{
    var _pa = 0.5 + 0.5 * sin(current_time / 180);
    txt(_bx2 - 20, _by2 - 14, nome_confirmar() + "  »", FONTE.MINI, make_color_rgb(255, 210, 90), _e * _pa, fa_right, fa_bottom);
}
txt(_bx1 + 20, _by2 - 14, nome_voltar() + ": PULAR", FONTE.MINI, make_color_rgb(150, 140, 130), _e * 0.8, fa_left, fa_bottom);
desenho_resetar();
