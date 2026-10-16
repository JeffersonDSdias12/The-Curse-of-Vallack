var _alpha = 1;
if (tempo < 20)  _alpha = tempo / 20;           // aparece devagar
if (tempo > 110) _alpha = (150 - tempo) / 40;   // some devagar
_alpha = clamp(_alpha, 0, 1);
var _gw = display_get_gui_width();
var _esc = min(1, (_gw - 110) / max(1, txt_largura(texto, FONTE.MEDIA)));
var _w = txt_largura(texto, FONTE.MEDIA, _esc) + 70;
draw_set_alpha(0.75 * _alpha);
draw_set_color(make_color_rgb(12, 9, 8));
draw_rectangle(_gw / 2 - _w / 2, 106, _gw / 2 + _w / 2, 154, false);
draw_set_color(make_color_rgb(176, 141, 70));
draw_rectangle(_gw / 2 - _w / 2, 106, _gw / 2 + _w / 2, 154, true);
txt_sombra(_gw / 2, 130, texto, FONTE.MEDIA, make_color_rgb(255, 210, 90), _alpha, fa_center, fa_middle, _esc);
desenho_resetar();
