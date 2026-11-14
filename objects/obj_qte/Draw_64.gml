// ===== SEQUÊNCIA DE GOLPES — interface (faixas de cinema, botões e o tempo) =====
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ouro = make_color_rgb(236, 186, 84);
var _n = array_length(seq);

// faixas pretas de cinema (entram na abertura e saem no fim)
var _fx = 1;
if (estado == "entrada") _fx = clamp(t / 14, 0, 1);
if (estado == "sucesso") _fx = clamp(1 - (t - 40) / 30, 0, 1);
if (estado == "falha") _fx = clamp(1 - (t - 26) / 24, 0, 1);
var _lb = _gh * 0.085 * _fx;
draw_set_alpha(0.92);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _lb, false);
draw_rectangle(0, _gh - _lb, _gw, _gh, false);
draw_set_alpha(1);

// título e as contas da sequência (douradas = feitas)
var _ty = _gh * 0.14;
txt_sombra(_gw / 2, _ty, "SEQUÊNCIA DE GOLPES", FONTE.MEDIA, _ouro, _fx, fa_center, fa_middle);
for (var _k = 0; _k < _n; _k++)
{
    var _px = _gw / 2 + (_k - (_n - 1) / 2) * 30;
    var _py = _ty + 34;
    draw_set_alpha(_fx);
    draw_set_color(make_color_rgb(40, 22, 18));
    draw_circle(_px, _py, 10, false);
    if (_k < i)
    {
        draw_set_color(_ouro);
        draw_circle(_px, _py, 7, false);
    }
    else if (_k == i and estado == "botao")
    {
        draw_set_color(make_color_rgb(255, 120, 80));
        draw_circle(_px, _py, 5 + 2 * sin(current_time / 90), false);
    }
    draw_set_color(_ouro);
    draw_circle(_px, _py, 10, true);
}
draw_set_alpha(1);

// o botão da vez, no centro, com o anel do tempo
var _cx = _gw / 2;
var _cy = _gh * 0.33;
if (estado == "botao" or estado == "entrada" or estado == "golpe")
{
    var _ai = (estado == "entrada") ? clamp(t / 20, 0, 1) : 1;
    var _acao = (estado == "golpe") ? seq[max(0, i - 1)] : seq[min(i, _n - 1)];
    var _frac = (estado == "botao") ? 1 - t / tempo_botao : 1;
    var _esc = (estado == "golpe") ? 1 + 0.35 * clamp(1 - t / 12, 0, 1) : 1 + 0.06 * sin(current_time / 70);
    // brilho em volta
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_ai * (0.25 + 0.15 * sin(current_time / 80)));
    draw_set_color((estado == "golpe") ? _ouro : make_color_rgb(255, 70, 40));
    draw_circle(_cx, _cy, 70 * _esc, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(_ai * 0.85);
    draw_set_color(make_color_rgb(18, 10, 10));
    draw_circle(_cx, _cy, 56 * _esc, false);
    // anel do tempo: dourado -> vermelho quando está acabando
    var _cor_anel = merge_color(make_color_rgb(255, 50, 30), _ouro, clamp(_frac * 1.6, 0, 1));
    desenhar_anel(_cx, _cy, 62 * _esc, 7, _frac, _cor_anel, _ai);
    var _ia = 52 * _esc;
    var _iw = icone_acao_largura(_acao, _ia);
    desenhar_icone_acao(_cx - _iw / 2, _cy, _acao, _ia, _ai);
    if (estado == "botao") txt_sombra(_cx, _cy + 92, "APERTE!", FONTE.PEQUENA, c_white, 0.7 + 0.3 * sin(current_time / 60), fa_center, fa_middle);
    if (acerto_fx > 0)
    {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(acerto_fx / 16);
        draw_set_color(_ouro);
        draw_circle(_cx, _cy, 64 + (16 - acerto_fx) * 3, true);
        draw_circle(_cx, _cy, 66 + (16 - acerto_fx) * 3, true);
        gpu_set_blendmode(bm_normal);
    }
}
if (estado == "sucesso")
{
    var _sa = clamp(t / 10, 0, 1) * clamp((70 - t) / 16, 0, 1);
    txt_sombra(_cx, _cy, "SEQUÊNCIA COMPLETA!", FONTE.GRANDE, _ouro, _sa, fa_center, fa_middle, 1 + 0.2 * clamp(1 - t / 10, 0, 1));
}
if (estado == "falha")
{
    var _fa = clamp(t / 6, 0, 1) * clamp((50 - t) / 14, 0, 1);
    txt_sombra(_cx, _cy - 8, "FALHOU!", FONTE.GRANDE, make_color_rgb(255, 60, 40), _fa, fa_center, fa_middle, 1 + 0.25 * clamp(1 - t / 8, 0, 1));
    txt_sombra(_cx, _cy + 48, "O inimigo se soltou: enfraqueça-o de novo", FONTE.PEQUENA, make_color_rgb(250, 230, 220), _fa, fa_center, fa_middle);
}
desenho_resetar();
