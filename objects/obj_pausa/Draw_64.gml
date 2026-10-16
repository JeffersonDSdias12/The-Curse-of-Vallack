var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _ouro  = make_color_rgb(255, 210, 90);
var _ab = clamp(abre, 0, 1);
var _ease = 1 - power(1 - _ab, 3);
var _fade = _ease;

// foto do jogo parado, escurecida
if (foto != -1 and sprite_exists(foto)) draw_sprite_stretched(foto, 0, 0, 0, _gw, _gh);
draw_set_alpha(0.74 * _fade);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
desenhar_vinheta(_gw, _gh, 0.6 * _fade, make_color_rgb(40, 0, 4));

// efeito de abrir/fechar: um corte carmesim atravessa a tela e as opções descem
var _corte = fechando ? (1 - _ab) : _ab;
if (_corte < 1)
{
    gpu_set_blendmode(bm_add);
    var _lx = lerp(-80, _gw + 80, _corte);
    draw_set_alpha(0.55 * (1 - _corte));
    draw_set_color(make_color_rgb(220, 30, 30));
    draw_triangle(_lx - 220, _gh * 0.62, _lx + 40, _gh * 0.18, _lx + 60, _gh * 0.2, false);
    draw_set_color(make_color_rgb(255, 210, 160));
    draw_line_width(_lx - 200, _gh * 0.6, _lx + 50, _gh * 0.19, 2);
    gpu_set_blendmode(bm_normal);
}
var _desce = (1 - _ease) * -26;

txt_sombra(_cx, _gh * 0.17 + _desce, "PAUSADO", FONTE.GRANDE, _ouro, _fade, fa_center, fa_middle, 1.2);
desenhar_divisor(_cx, _gh * 0.17 + 46 + _desce, 220, _fade);
txt(_cx, _gh * 0.17 + 72 + _desce, "CAPÍTULO " + string(max(1, fase_numero(room))) + "  ·  " + fase_nome(max(1, fase_numero(room))) + "  ·  " + dificuldade_nome(), FONTE.MINI, make_color_rgb(190, 170, 130), _fade, fa_center, fa_middle);

for (var _o = 0; _o < array_length(opcoes); _o++)
{
    // cada linha entra com um pequeno atraso
    var _ao = clamp(_ease * 1.6 - _o * 0.09, 0, 1);
    var _oy = opcao_y(_o) + (1 - _ao) * 18;
    var _a = anim[_o];
    desenhar_painel(_cx - 250, _oy - 24, _cx + 250, _oy + 24, _a, _ao);
    var _texto = opcoes[_o];
    var _cor = merge_color(c_white, _ouro, _a);
    if (_o == PAUSA_MUSICA or _o == PAUSA_EFEITOS)
    {
        var _vol = (_o == PAUSA_MUSICA) ? global.cfg_vol_musica : global.cfg_vol_efeitos;
        txt_sombra(_cx - 230, _oy, _texto, FONTE.PEQUENA, _cor, _ao, fa_left, fa_middle);
        var _bx1 = _cx + 20;
        var _bx2 = _cx + 200;
        draw_set_alpha(_ao);
        draw_set_color(make_color_rgb(34, 26, 24));
        draw_rectangle(_bx1 - 2, _oy - 7, _bx2 + 2, _oy + 7, false);
        var _c1 = make_color_rgb(255, 120, 60);
        var _c2 = make_color_rgb(150, 20, 20);
        if (_vol > 0) draw_rectangle_color(_bx1, _oy - 5, _bx1 + (_bx2 - _bx1) * _vol, _oy + 5, _c2, _c1, _c1, _c2, false);
        draw_set_color(make_color_rgb(176, 141, 70));
        draw_rectangle(_bx1 - 2, _oy - 7, _bx2 + 2, _oy + 7, true);
        for (var _m = 1; _m < 10; _m++)
        {
            var _mx2 = _bx1 + (_bx2 - _bx1) * _m / 10;
            draw_set_color(make_color_rgb(20, 14, 12));
            draw_line(_mx2, _oy - 5, _mx2, _oy + 5);
        }
        txt(_cx + 236, _oy, string(round(_vol * 100)) + "%", FONTE.MINI, _ouro, _ao, fa_right, fa_middle);
        if (_a > 0.5)
        {
            txt(_bx1 - 14, _oy, "«", FONTE.PEQUENA, _ouro, _ao * _a, fa_center, fa_middle);
        }
        draw_set_alpha(1);
    }
    else
    {
        if (confirmar == _o) { _texto = "CONFIRMAR?  (progresso não salvo será perdido)"; _cor = make_color_rgb(255, 120, 90); }
        var _esc = min(1 + 0.06 * _a, 450 / max(1, txt_largura(_texto, FONTE.MEDIA)));
        txt_sombra(_cx, _oy, _texto, (confirmar == _o) ? FONTE.PEQUENA : FONTE.MEDIA, _cor, _ao, fa_center, fa_middle, (confirmar == _o) ? min(1, 460 / max(1, txt_largura(_texto, FONTE.PEQUENA))) : _esc);
    }
    if (_a > 0.05)
    {
        draw_set_alpha(_a * _ao);
        desenhar_espada(_cx - 250 - 62 + 22 * _a, _oy, 1);
        desenhar_espada(_cx + 250 + 62 - 22 * _a, _oy, -1);
        draw_set_alpha(1);
    }
}

var _rod = (usando_controle() ? (nome_pausa() + " / " + nome_voltar()) : "ESC") + " continua   ·   « » muda o volume   ·   " + botao_menu_armas() + " no jogo abre as ARMAS";
txt(_cx, _gh - 30, _rod, FONTE.MINI, make_color_rgb(170, 170, 175), _fade, fa_center, fa_middle, min(1, (_gw - 40) / max(1, txt_largura(_rod, FONTE.MINI))));

gpu_set_blendmode(bm_add);
for (var _i = 0; _i < array_length(faiscas); _i++)
{
    var _f = faiscas[_i];
    var _p = _f.vida / _f.vmax;
    draw_set_alpha(min(1, _p * 1.5));
    draw_set_color(make_color_rgb(255, 120 + 120 * _p, 40));
    draw_circle(_f.x, _f.y, 2.5, false);
}
gpu_set_blendmode(bm_normal);
desenho_resetar();
