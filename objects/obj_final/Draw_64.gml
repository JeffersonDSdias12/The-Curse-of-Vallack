var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;

if (fase == "escurecer")
{
    draw_set_alpha(clamp(tempo / 150, 0, 1));
    draw_set_color(c_black);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    exit;
}

// tela preta
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);

var _sai = (fase == "sair") ? 1 - clamp(tempo / 50, 0, 1) : 1;
var _t = (fase == "continua") ? tempo : duracao_texto;

// brilho vermelho pulsando atrás do texto
var _pulso = 0.2 + 0.1 * sin(current_time / 300);
gpu_set_blendmode(bm_add);
draw_set_alpha(_pulso * _sai * clamp(_t / 60, 0, 1));
draw_set_color(make_color_rgb(110, 0, 12));
draw_ellipse(_cx - _gw * 0.35, _gh / 2 - 120, _cx + _gw * 0.35, _gh / 2 + 120, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

// "CONTINUA..." letra por letra
var _esc = min(1.15, (_gw * 0.85) / max(1, txt_largura("CONTINUA...", FONTE.TITULO)));
txt_amaldicoado(_cx, _gh / 2 - 10, "CONTINUA...", FONTE.TITULO, make_color_rgb(235, 40, 40), _t - 20, 9, _esc, _sai);

// frase final
var _fa = clamp((_t - 160) / 40, 0, 1) * _sai;
txt(_cx, _gh / 2 + 78, "A maldição de Vallack ainda não foi quebrada.", FONTE.PEQUENA, make_color_rgb(200, 195, 195), _fa, fa_center, fa_middle);
var _fb = clamp((_t - 230) / 40, 0, 1) * _sai;
txt(_cx, _gh / 2 + 112, "A jornada de Twilight continua.  Obrigado por jogar!", FONTE.MINI, make_color_rgb(255, 210, 90), _fb, fa_center, fa_middle);

// brasas
gpu_set_blendmode(bm_add);
for (var _i = 0; _i < array_length(brasas); _i++)
{
    var _b = brasas[_i];
    draw_set_alpha(clamp(_b.vida / _b.vmax, 0, 1) * 0.7 * _sai);
    draw_set_color(make_color_rgb(220, 50, 30));
    draw_circle(_b.x, _b.y, 1.8, false);
}
gpu_set_blendmode(bm_normal);
desenho_resetar();
