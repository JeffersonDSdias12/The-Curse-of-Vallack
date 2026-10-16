var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;

draw_set_alpha(alpha * 0.82);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
desenhar_vinheta(_gw, _gh, alpha * 0.8, make_color_rgb(90, 0, 0));

txt_amaldicoado(_cx, _gh / 2 - 60, "VOCÊ MORREU", FONTE.TITULO, make_color_rgb(210, 20, 20), tempo - 10, 5, min(0.9, (_gw * 0.8) / max(1, txt_largura("VOCÊ MORREU", FONTE.TITULO))), alpha);

var _ba = clamp((tempo - 40) / 20, 0, 1);
for (var _i = 0; _i < 2; _i++)
{
    var _by = botao_y(_i);
    desenhar_painel(_cx - 190, _by - 24, _cx + 190, _by + 24, anim[_i], _ba);
    txt(_cx, _by, opcoes[_i], FONTE.MEDIA, merge_color(c_white, make_color_rgb(255, 210, 90), anim[_i]), _ba, fa_center, fa_middle);
}
var _cp = (global.checkpoint_ativo and room == global.checkpoint_room) ? "Você voltará ao último checkpoint." : "Você voltará ao início da fase.";
txt(_cx, botao_y(1) + 56, _cp, FONTE.MINI, make_color_rgb(170, 170, 175), _ba, fa_center, fa_middle);
desenho_resetar();
