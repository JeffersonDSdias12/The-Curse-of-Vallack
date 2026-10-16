var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _ouro   = make_color_rgb(255, 210, 90);
var _ouro2  = make_color_rgb(176, 141, 70);
var _cinza  = make_color_rgb(175, 172, 178);
var _q      = global.cfg_qualidade;

// =====================================================================
// FUNDO ANIMADO DO MENU (panorama em movimento, névoa, tom amaldiçoado,
// relâmpagos e tochas)
// =====================================================================
var _fundo_a = 1;
if (estado == "intro_creditos" or estado == "intro_aviso") _fundo_a = 0;
else if (estado == "intro_titulo") _fundo_a = clamp((tempo - (titulo_total - 45)) / 45, 0, 1);

draw_set_alpha(1);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);

if (_fundo_a > 0)
{
    var _sw = sprite_get_width(spr_fundo);
    var _sh = sprite_get_height(spr_fundo);
    var _esc = max(_gw / _sw, _gh / _sh) * 1.12;
    var _bw = _sw * _esc;
    var _bh = _sh * _esc;
    var _px = -(_bw - _gw) * (0.5 + 0.5 * sin(tempo_total / 1400));
    var _py = -(_bh - _gh) * 0.5 + sin(tempo_total / 900) * 4;
    // suavizado (a imagem é ampliada para a tela)
    gpu_set_texfilter(global.cfg_fundo_hd == 1);
    draw_sprite_ext(spr_fundo, 0, _px, _py, _esc, _esc, 0, make_color_rgb(150, 118, 124), _fundo_a);
    gpu_set_texfilter(false);

    // névoa passando
    if (_q > 0)
    {
        gpu_set_blendmode(bm_add);
        for (var _n = 0; _n < 5; _n++)
        {
            var _fx = ((tempo_total * (0.22 + _n * 0.07) + _n * 420) mod (_gw + 700)) - 350;
            var _fy = _gh * (0.52 + 0.08 * _n);
            draw_set_alpha(0.035 * _fundo_a);
            draw_set_color(make_color_rgb(150, 140, 165));
            draw_ellipse(_fx - 330, _fy - 60, _fx + 330, _fy + 60, false);
        }
        gpu_set_blendmode(bm_normal);
    }

    // tom vermelho da maldição, pulsando
    draw_set_alpha((0.16 + 0.06 * sin(tempo_total / 160)) * _fundo_a);
    draw_set_color(make_color_rgb(110, 0, 10));
    draw_rectangle(0, 0, _gw, _gh, false);
    retangulo_gradiente(0, _gh * 0.32, _gw, _gh, c_black, 0, c_black, 0.78 * _fundo_a);
    desenhar_vinheta(_gw, _gh, 0.85 * _fundo_a);

    // relâmpago
    if (relampago > 0)
    {
        var _ra = (relampago > 20) ? (26 - relampago) / 6 : relampago / 20;
        draw_set_alpha(clamp(_ra, 0, 1) * 0.3 * _fundo_a);
        draw_set_color(make_color_rgb(255, 205, 205));
        draw_rectangle(0, 0, _gw, _gh, false);
    }

    // tochas nas laterais
    if (_gw >= 900)
    {
        desenhar_tocha(_gw * 0.085, _gh * 0.6, _fundo_a);
        desenhar_tocha(_gw * 0.915, _gh * 0.6, _fundo_a);
    }
    draw_set_alpha(1);
}

// =====================================================================
// ABERTURA 0: IMAGEM DE INTRODUÇÃO ("este é um jogo fictício")
// =====================================================================
if (estado == "intro_aviso")
{
    var _av = clamp(min(tempo / 40, (aviso_total - tempo) / 30), 0, 1);
    imagem_desenhar_ajustada(img_aviso, 0, 0, _gw, _gh, _av);
    if (tempo > 60)
    {
        var _pa = _av * (0.55 + 0.25 * sin(current_time / 200));
        txt(_gw - 24, _gh - 22, nome_confirmar() + "  continua", FONTE.MINI, make_color_rgb(200, 190, 175), _pa, fa_right, fa_middle);
    }
}

// =====================================================================
// ABERTURA 1: CRÉDITOS
// =====================================================================
else if (estado == "intro_creditos")
{
    retangulo_gradiente(0, _gh * 0.5, _gw, _gh, make_color_rgb(70, 0, 8), 0, make_color_rgb(70, 0, 8), 0.25 + 0.08 * sin(current_time / 400));
    var _saida = clamp((creditos_total - tempo) / 50, 0, 1);
    for (var _c = 0; _c < array_length(creditos); _c++)
    {
        var _cr = creditos[_c];
        var _ta = tempo - _cr.t;
        if (_ta <= 0) continue;
        var _a = clamp(_ta / 40, 0, 1) * _saida;
        var _sobe = (1 - clamp(_ta / 40, 0, 1)) * 14;
        var _escf = min(1, (_gw * 0.9) / max(1, txt_largura(_cr.texto, _cr.f)));
        txt_sombra(_cx, _gh * _cr.y + _sobe, _cr.texto, _cr.f, _cr.cor, _a, fa_center, fa_middle, _escf);
    }
}

// =====================================================================
// ABERTURA 2: NOME DO JOGO (horizontal, grande, letra por letra, amaldiçoado)
// =====================================================================
else if (estado == "intro_titulo")
{
    var _t = tempo;
    var _saida_t = clamp((titulo_total - _t) / 45, 0, 1);
    var _ent = clamp((_t - 10) / 40, 0, 1);

    // aura vermelha atrás do nome
    gpu_set_blendmode(bm_add);
    draw_set_alpha((0.18 + 0.08 * sin(current_time / 260)) * _ent * _saida_t);
    draw_set_color(make_color_rgb(120, 0, 15));
    draw_ellipse(_cx - _gw * 0.48, _gh * 0.40 - 160, _cx + _gw * 0.48, _gh * 0.40 + 160, false);
    gpu_set_blendmode(bm_normal);

    var _esc_t = min(1, (_gw * 0.92) / max(1, txt_largura(JOGO_TITULO, FONTE.TITULO)));
    var _ty = _gh * 0.40;
    var _tremor = (_t > titulo_inicio and _t < sub_inicio) ? 2.5 : 0.6;
    var _ox = random_range(-_tremor, _tremor) * _saida_t;
    if (global.logo_img != -1 and sprite_exists(global.logo_img))
    {
        // a LOGO surge: cresce um pouco, treme e fica com uma aura vermelha
        var _lk = clamp((_t - titulo_inicio) / 70, 0, 1);
        var _le = 1 - power(1 - _lk, 3);
        var _lh = min(_gh * 0.50, _gw * 0.62) * (1.10 - 0.10 * _le);
        _ty = _gh * 0.36;
        logo_desenhar(_cx + _ox * (1 - _le * 0.7), _ty, _lh, _lk * _saida_t);
        if (_lk > 0 and _lk < 1)
        {
            gpu_set_blendmode(bm_add);
            logo_desenhar(_cx, _ty, _lh * (1 + 0.15 * (1 - _lk)), (1 - _lk) * 0.6 * _saida_t);
            gpu_set_blendmode(bm_normal);
        }
        titulo_x1 = _cx - _lh * 0.40;
        titulo_x2 = _cx + _lh * 0.40;
        titulo_base = _ty - _lh / 2 + _lh * 0.655;      // pé das letras de "VALLACK"
        var _sub_y = _ty + min(_gh * 0.50, _gw * 0.62) / 2 + 30;     // o subtítulo fica logo abaixo da logo
    }
    else
    {
        txt_amaldicoado(_cx + _ox, _ty, JOGO_TITULO, FONTE.TITULO, make_color_rgb(225, 35, 35), _t - titulo_inicio, titulo_intervalo, _esc_t, _saida_t);
        var _tw = txt_largura(JOGO_TITULO, FONTE.TITULO, _esc_t);
        titulo_x1 = _cx - _tw / 2;
        titulo_x2 = _cx + _tw / 2;
        titulo_base = _ty + txt_altura("A", FONTE.TITULO, _esc_t) * 0.30;
        var _sub_y = _ty + 88 * _esc_t + 14;
    }

    // sangue escorrendo das letras
    for (var _gi = 0; _gi < array_length(gotas); _gi++)
    {
        var _g = gotas[_gi];
        var _ga = clamp(_g.vida / 40, 0, 1) * _saida_t;
        draw_set_alpha(_ga);
        draw_set_color(make_color_rgb(120, 6, 14));
        draw_line_width(_g.x, _g.y, _g.x, _g.y + _g.comp, 2.5);
        draw_circle(_g.x, _g.y + _g.comp + _g.queda, 2.6, false);
    }
    draw_set_alpha(1);

    var _esc_s = min(1, (_gw * 0.8) / max(1, txt_largura(JOGO_SUBTITULO, FONTE.GRANDE)));
    txt_amaldicoado(_cx, _sub_y, JOGO_SUBTITULO, FONTE.GRANDE, _ouro, _t - sub_inicio, sub_intervalo, _esc_s * 0.85, _saida_t);
    var _dv = max(_gh * 0.70, _sub_y + 42);          // créditos abaixo do subtítulo

    var _da = clamp((_t - devs_inicio) / 40, 0, 1) * _saida_t;
    desenhar_divisor(_cx, _dv, 220, _da);
    txt(_cx, _dv + _gh * 0.045, "UM JOGO DE", FONTE.MINI, _ouro2, _da, fa_center, fa_middle);
    var _devs = "JEFFERSON DIAS  ·  EDUARDO  ·  ISAAC  ·  ALEX  ·  ALDREON";
    txt_sombra(_cx, _dv + _gh * 0.095, _devs, FONTE.PEQUENA, c_white, _da, fa_center, fa_middle, min(1, (_gw * 0.9) / max(1, txt_largura(_devs, FONTE.PEQUENA))));
    txt(_cx, _dv + _gh * 0.15, "FACULDADE FAPAN", FONTE.MINI, _cinza, _da, fa_center, fa_middle);
}

// =====================================================================
// MENU E TELAS DE OPÇÕES
// =====================================================================
else
{
    var _ma = clamp(menu_aparece / 30, 0, 1);

    // ----- cabeçalho -----
    if (estado == "tutorial")
    {
        // o pergaminho ocupa a tela; sem cabeçalho
    }
    else if (estado == "menu" and global.logo_img != -1 and sprite_exists(global.logo_img))
    {
        // LOGO do jogo no topo do menu, com uma aura que pulsa
        var _lh2 = min(244, _gw * 0.3);
        var _ly = 132 + sin(tempo_total / 90) * 2;
        gpu_set_blendmode(bm_add);
        logo_desenhar(_cx, _ly, _lh2 * 1.04, _ma * (0.10 + 0.06 * sin(tempo_total / 120)));
        gpu_set_blendmode(bm_normal);
        logo_desenhar(_cx, _ly, _lh2, _ma);
    }
    else if (estado == "menu")
    {
        var _esc_m = min(1.25, (_gw * 0.86) / max(1, txt_largura(JOGO_TITULO, FONTE.GRANDE)));
        var _glitch = (irandom(90) == 0) ? random_range(-6, 6) : 0;
        var _brilho = 0.45 + 0.25 * sin(tempo_total / 120);
        gpu_set_blendmode(bm_add);
        txt(_cx - 3 + _glitch, 112, JOGO_TITULO, FONTE.GRANDE, make_color_rgb(150, 8, 20), _ma * _brilho, fa_center, fa_middle, _esc_m * 1.02);
        txt(_cx + 3 + _glitch, 112, JOGO_TITULO, FONTE.GRANDE, make_color_rgb(150, 8, 20), _ma * _brilho, fa_center, fa_middle, _esc_m * 1.02);
        gpu_set_blendmode(bm_normal);
        txt(_cx + 4, 116, JOGO_TITULO, FONTE.GRANDE, c_black, _ma * 0.8, fa_center, fa_middle, _esc_m);
        txt(_cx + _glitch, 112, JOGO_TITULO, FONTE.GRANDE, make_color_rgb(230, 40, 40), _ma, fa_center, fa_middle, _esc_m);
        txt_sombra(_cx, 172, JOGO_SUBTITULO, FONTE.MEDIA, _ouro, _ma, fa_center, fa_middle);
        desenhar_divisor(_cx, 208, 250, _ma);
    }
    else
    {
        var _cab = "";
        switch (estado)
        {
            case "dificuldade": _cab = "DIFICULDADE"; break;
            case "carregar":  _cab = "CARREGAR JOGO"; break;
            case "slot_novo": _cab = "ESCOLHA UM SLOT"; break;
            case "opcoes":    _cab = "OPÇÕES"; break;
            case "teclado":   _cab = "TECLADO"; break;
            case "controle":  _cab = "CONTROLE"; break;
        }
        txt(_cx, 46, JOGO_TITULO + "  ·  " + JOGO_SUBTITULO, FONTE.MINI, make_color_rgb(200, 70, 60), _ma * 0.9, fa_center, fa_middle);
        txt_sombra(_cx, 96, _cab, FONTE.GRANDE, _ouro, _ma, fa_center, fa_middle);
        desenhar_divisor(_cx, 134, 260, _ma);
    }

    // ----- conteúdo de cada tela -----
    switch (estado)
    {
        // ================= MENU INICIAL =================
        case "menu":
            for (var _o = 0; _o < array_length(opcoes_menu); _o++)
            {
                var _oy = menu_y(_o);
                var _e = clamp((menu_aparece - 12 - _o * 7) / 20, 0, 1);
                var _ease = 1 - power(1 - _e, 3);
                var _off = (1 - _ease) * 90 * ((_o mod 2 == 0) ? -1 : 1);
                var _a = anim[_o];
                var _dim = (_o == 1 and !tem_save) ? 0.45 : 1;
                desenhar_painel(_cx - 230 + _off, _oy - 27, _cx + 230 + _off, _oy + 27, _a, _ease);
                var _tx_cor = merge_color(c_white, _ouro, _a);
                txt_sombra(_cx + _off, _oy, opcoes_menu[_o], FONTE.MEDIA, _tx_cor, _ease * _dim, fa_center, fa_middle, 1 + 0.08 * _a);
                if (_a > 0.05)
                {
                    draw_set_alpha(_a * _ease);
                    desenhar_espada(_cx - 230 - 64 + 24 * _a + _off, _oy, 1);
                    desenhar_espada(_cx + 230 + 64 - 24 * _a + _off, _oy, -1);
                    draw_set_alpha(1);
                }
            }
            var _fd = min(clamp(dica_tempo / 20, 0, 1), clamp((220 - dica_tempo) / 20, 0, 1)) * _ma;
            txt_bloco(_cx, _gh - 98, "DICA  ·  " + dicas[dica_atual], FONTE.MINI, _ouro, _fd, min(_gw - 120, 900));
            txt(_cx, _gh - 44, "Setas / WASD / D-pad + ENTER   ·   Mouse   ·   F11 tela cheia   ·   Controle: " + gamepad_descricao_conectado(), FONTE.MINI, _cinza, _ma * 0.9, fa_center, fa_middle, min(1, (_gw - 40) / max(1, txt_largura("Setas / WASD / D-pad + ENTER   ·   Mouse   ·   F11 tela cheia   ·   Controle: " + gamepad_descricao_conectado(), FONTE.MINI))));
            txt(_gw - 18, _gh - 16, JOGO_VERSAO, FONTE.MINI, make_color_rgb(110, 105, 110), _ma, fa_right, fa_middle);
        break;

        // ================= DIFICULDADE =================
        case "dificuldade":
            for (var _d = 0; _d < DIF.TOTAL; _d++)
            {
                var _dy2 = dif_y(_d);
                var _ad = anim[_d];
                desenhar_painel(_cx - 260, _dy2 - 24, _cx + 260, _dy2 + 24, _ad, 1);
                var _cd = dificuldade_cor(_d);
                if (_d == DIF.EXTREMO) _cd = merge_color(_cd, c_white, 0.15 + 0.15 * sin(current_time / 90));
                txt_sombra(_cx, _dy2, dificuldade_nome(_d), FONTE.MEDIA, merge_color(c_white, _cd, 0.55 + 0.45 * _ad), 1, fa_center, fa_middle, 1 + 0.06 * _ad);
                if (_ad > 0.05)
                {
                    draw_set_alpha(_ad);
                    desenhar_espada(_cx - 260 - 62 + 22 * _ad, _dy2, 1);
                    desenhar_espada(_cx + 260 + 62 - 22 * _ad, _dy2, -1);
                    draw_set_alpha(1);
                }
            }
            var _pw4 = min(_gw - 100, 720);
            desenhar_painel(_cx - _pw4 / 2, 452, _cx + _pw4 / 2, 600, 0, 1);
            var _desc = dificuldade_descricao(selecionado);
            txt(_cx, 474, string_upper(NOME_GUERREIRO) + "  ·  " + dificuldade_nome(selecionado), FONTE.PEQUENA, dificuldade_cor(selecionado), 1, fa_center, fa_middle);
            for (var _l2 = 0; _l2 < array_length(_desc); _l2++)
                txt(_cx, 508 + _l2 * 27, _desc[_l2], FONTE.MINI, c_white, 1, fa_center, fa_middle, min(1, (_pw4 - 30) / max(1, txt_largura(_desc[_l2], FONTE.MINI))));
            // tutorial na fase: liga / desliga com « » (o mesmo de OPÇÕES)
            var _tut_txt = "«  TUTORIAL NA FASE: " + (global.cfg_tutorial ? "LIGADO" : "DESLIGADO") + "  »";
            txt_sombra(_cx, 628, _tut_txt, FONTE.PEQUENA, global.cfg_tutorial ? _ouro : make_color_rgb(190, 150, 140), 1, fa_center, fa_middle);
            txt(_cx, _gh - 40, nome_setas() + " escolhem   ·   « » tutorial   ·   " + nome_confirmar() + " começa a jornada   ·   " + nome_voltar() + " volta", FONTE.MINI, _cinza, 1, fa_center, fa_middle, min(1, (_gw - 40) / max(1, txt_largura(nome_setas() + " escolhem   ·   « » tutorial   ·   " + nome_confirmar() + " começa a jornada   ·   " + nome_voltar() + " volta", FONTE.MINI))));
        break;

        // ================= SLOTS =================
        case "carregar":
        case "slot_novo":
            var _cw = min(300, _gw * 0.23);
            for (var _s = 0; _s < 3; _s++)
            {
                var _sx = _gw * (_s + 1) / 4;
                var _sel = (selecionado == _s) ? 1 : 0;
                var _info = slots[_s];
                desenhar_painel(_sx - _cw / 2, 250, _sx + _cw / 2, 470, _sel, 1);
                if (estado == "slot_novo" and confirmar_slot == _s)
                {
                    draw_set_color(make_color_rgb(255, 60, 50));
                    draw_rectangle(_sx - _cw / 2 - 4, 246, _sx + _cw / 2 + 4, 474, true);
                    draw_rectangle(_sx - _cw / 2 - 5, 245, _sx + _cw / 2 + 5, 475, true);
                }
                txt(_sx, 284, "SLOT " + string(_s + 1), FONTE.MEDIA, _ouro, 1, fa_center, fa_middle);
                if (_info.existe)
                {
                    txt(_sx, 324, string_upper(_info.nome), FONTE.PEQUENA, c_white, 1, fa_center, fa_middle, min(1, (_cw - 24) / max(1, txt_largura(string_upper(_info.nome), FONTE.PEQUENA))));
                    txt(_sx, 350, dificuldade_nome(_info.dificuldade), FONTE.MINI, dificuldade_cor(_info.dificuldade), 1, fa_center, fa_middle);
                    txt(_sx, 378, "CAPÍTULO " + string(_info.fase), FONTE.MINI, _ouro2, 1, fa_center, fa_middle);
                    txt_bloco(_sx, 392, fase_nome(_info.fase), FONTE.MINI, make_color_rgb(220, 215, 210), 1, _cw - 24);
                    if (_info.data != "") txt(_sx, 452, _info.data, FONTE.MINI, make_color_rgb(140, 140, 145), 1, fa_center, fa_middle, 0.85);
                }
                else txt(_sx, 370, "VAZIO", FONTE.PEQUENA, make_color_rgb(140, 140, 145), 1, fa_center, fa_middle);
                if (estado == "slot_novo" and confirmar_slot == _s)
                    txt(_sx, 500, "SOBRESCREVER?", FONTE.PEQUENA, make_color_rgb(255, 90, 70), 0.7 + 0.3 * sin(current_time / 90), fa_center, fa_middle);
            }
            if (estado == "carregar")
            {
                var _fd2 = min(clamp(dica_tempo / 20, 0, 1), clamp((220 - dica_tempo) / 20, 0, 1));
                txt_bloco(_cx, _gh - 100, "DICA  ·  " + dicas[dica_atual], FONTE.MINI, _ouro, _fd2, min(_gw - 120, 900));
            }
            txt(_cx, _gh - 44, "« » escolhe o slot   ·   " + nome_confirmar() + " confirma   ·   " + nome_voltar() + " volta", FONTE.MINI, _cinza, 1, fa_center, fa_middle);
        break;

        // ================= OPÇÕES =================
        case "opcoes":
            var _pw2 = min(_gw - 80, 860);
            for (var _r = 0; _r < array_length(opcoes_cfg); _r++)
            {
                var _ry = cfg_y(_r);
                var _ar = anim[_r];
                desenhar_painel(_cx - _pw2 / 2, _ry - 17, _cx + _pw2 / 2, _ry + 17, _ar, 1);
                if (_r == array_length(opcoes_cfg) - 1)
                {
                    txt(_cx, _ry, opcoes_cfg[_r], FONTE.PEQUENA, merge_color(c_white, _ouro, _ar), 1, fa_center, fa_middle);
                    continue;
                }
                txt(_cx - _pw2 / 2 + 24, _ry, opcoes_cfg[_r], FONTE.PEQUENA, merge_color(c_white, _ouro, _ar), 1, fa_left, fa_middle);
                var _val = valor_opcao(_r);
                if (_r <= CFG_ULTIMO_VALOR) _val = "«  " + _val + "  »";
                var _cor_v = _ouro;
                if (_r == 3 and global.cfg_tela_cheia) _cor_v = make_color_rgb(190, 170, 120);
                var _vx = _cx + _pw2 / 2 - 24;
                if (_r >= 5 and _r <= 7)
                {
                    // barra de volume
                    var _vol = (_r == 5) ? global.cfg_volume : ((_r == 6) ? global.cfg_vol_musica : global.cfg_vol_efeitos);
                    var _bx2 = _vx - 120;
                    draw_set_color(make_color_rgb(40, 34, 30));
                    draw_rectangle(_bx2 - 140, _ry - 4, _bx2 - 20, _ry + 4, false);
                    draw_set_color(_ouro);
                    draw_rectangle(_bx2 - 140, _ry - 4, _bx2 - 140 + 120 * _vol, _ry + 4, false);
                }
                txt(_vx, _ry, _val, FONTE.PEQUENA, _cor_v, 1, fa_right, fa_middle, min(1, (_pw2 * 0.5) / max(1, txt_largura(_val, FONTE.PEQUENA))));
            }
            txt_bloco(_cx, _gh - 104, descricao_opcao(selecionado), FONTE.MINI, make_color_rgb(215, 210, 205), 1, _pw2);
            txt(_cx, _gh - 34, (usando_controle() ? (nome_setas() + " escolhem   ·   « » altera   ·   " + nome_voltar() + " volta") : "Setas escolhem   ·   « » ou clique altera (botão direito diminui)   ·   ESC volta"), FONTE.MINI, _cinza, 1, fa_center, fa_middle);
        break;

        // ================= REMAPEAMENTO (2 colunas) =================
        case "teclado":
        case "controle":
            var _modo_pad = (estado == "controle");
            var _mp0 = map_pos(0);
            var _mp7 = map_pos(MAP_COL1);
            txt(_mp0[0], 146, "MOVIMENTO", FONTE.MINI, _ouro2, 1, fa_center, fa_middle);
            txt(_mp7[0], 146, "COMBATE", FONTE.MINI, _ouro2, 1, fa_center, fa_middle);
            for (var _l = 0; _l < ACAO.TOTAL + 2; _l++)
            {
                var _mp = map_pos(_l);
                var _lx1 = _mp[0] - _mp[2] / 2;
                var _lx2 = _mp[0] + _mp[2] / 2;
                var _ly = _mp[1];
                var _al = anim[_l];
                desenhar_painel(_lx1, _ly - 21, _lx2, _ly + 21, _al, 1);
                if (_l == ACAO.TOTAL)
                {
                    txt(_mp[0], _ly, "RESTAURAR PADRÃO", FONTE.PEQUENA, merge_color(make_color_rgb(230, 150, 130), _ouro, _al), 1, fa_center, fa_middle);
                    continue;
                }
                if (_l == ACAO.TOTAL + 1)
                {
                    txt(_mp[0], _ly, "VOLTAR", FONTE.PEQUENA, merge_color(c_white, _ouro, _al), 1, fa_center, fa_middle);
                    continue;
                }
                var _ac = acoes_tela[_l];
                // tecla / botão atual (ícone + nome)
                var _wv = 0;
                if (capturando and selecionado == _l)
                {
                    var _pisca = 0.55 + 0.45 * sin(current_time / 90);
                    var _msg = _modo_pad ? "APERTE UM BOTÃO..." : "APERTE UMA TECLA...";
                    _wv = txt_largura(_msg, FONTE.MINI);
                    txt(_lx2 - 16, _ly, _msg, FONTE.MINI, make_color_rgb(255, 120, 90), _pisca, fa_right, fa_middle);
                }
                else if (_modo_pad)
                {
                    var _bt = global.botoes[_ac];
                    var _nm = nome_pad(_bt);
                    var _wn = txt_largura(_nm, FONTE.MINI);
                    txt(_lx2 - 16, _ly, _nm, FONTE.MINI, _ouro, 1, fa_right, fa_middle);
                    var _ix0 = _lx2 - 16 - _wn - 8;
                    var _wic = icone_pad_largura(_bt, 26);
                    desenhar_icone_pad(_ix0 - _wic, _ly, _bt, 26, 1);
                    _wv = _wn + 8 + _wic;
                }
                else
                {
                    var _nk = nome_tecla(global.teclas[_ac]);
                    _wv = desenhar_tecla_largura(_nk, 26);
                    desenhar_tecla(_lx2 - 16 - _wv, _ly, _nk, 26, 1);
                }
                var _nome_a = acoes[_ac];
                var _esc_a = min(1, (_mp[2] - 40 - _wv) / max(1, txt_largura(_nome_a, FONTE.PEQUENA)));
                txt(_lx1 + 16, _ly, _nome_a, FONTE.PEQUENA, merge_color(c_white, _ouro, _al), 1, fa_left, fa_middle, _esc_a);
            }
            // informações do controle
            if (_modo_pad)
            {
                var _info = "CONTROLE: " + gamepad_descricao_conectado();
                if (global.pad_slot >= 0)
                {
                    _info += "   ·   " + ((global.pad_slot < 4 and os_type == os_windows) ? "XINPUT" : "DIRECTINPUT / GENÉRICO") + "   ·   " + string(global.pad_botoes) + " BOTÕES";
                    if (global.pad_botoes <= 0) _info += "   ·   SEM MAPEAMENTO";
                }
                txt(_cx, 622, _info, FONTE.MINI, (global.pad_slot >= 0) ? make_color_rgb(150, 210, 140) : make_color_rgb(230, 140, 120), 1, fa_center, fa_middle, min(1, (_gw - 60) / max(1, txt_largura(_info, FONTE.MINI))));
            }
            else txt(_cx, 622, "As setas também funcionam para correr, pular e agachar, se não estiverem em uso.", FONTE.MINI, make_color_rgb(190, 185, 180), 1, fa_center, fa_middle, min(1, (_gw - 60) / max(1, txt_largura("As setas também funcionam para correr, pular e agachar, se não estiverem em uso.", FONTE.MINI))));
            var _rod = capturando
                ? (_modo_pad ? "Aperte o novo botão (ou gatilho / direcional)   ·   START cancela" : "Aperte a nova tecla   ·   ESC cancela")
                : (usando_controle() ? (nome_setas() + " escolhem   ·   " + nome_confirmar() + " altera   ·   " + nome_voltar() + " volta") : "Setas escolhem   ·   ENTER ou clique para alterar   ·   ESC volta");
            txt(_cx, _gh - 34, _rod, FONTE.MINI, _cinza, 1, fa_center, fa_middle);
        break;

        // ================= TUTORIAL (livro de pergaminhos) =================
        case "tutorial":
            var _tam = pergaminho_tamanho();
            var _pg = tutorial_pagina(livro_pag);
            var _ind = "«  " + string(livro_pag + 1) + " / " + string(TUT.TOTAL) + "  »";
            var _rodp = (livro_pag < TUT.TOTAL - 1) ? "PRÓXIMA PÁGINA" : "VOLTAR AO MENU";
            pergaminho_desenhar(_cx, _gh / 2 - 6, _tam[0], _tam[1], livro_abre, _pg, _ma, _rodp, _ind, 0.8 + 0.2 * sin(current_time / 160));
            txt(_cx, _gh - 22, "«  »  trocam de página   ·   " + nome_voltar() + " volta ao menu", FONTE.MINI, _cinza, _ma, fa_center, fa_middle);
        break;
    }

    // ----- mensagens (aparecem por cima da linha de ajuda do rodapé) -----
    if (mensagem_tempo > 0 and mensagem != "")
    {
        var _ma2 = clamp(mensagem_tempo / 20, 0, 1);
        var _mw = min(_gw - 40, txt_largura(mensagem, FONTE.PEQUENA) + 60);
        draw_set_alpha(0.95 * _ma2);
        draw_set_color(make_color_rgb(34, 8, 8));
        draw_rectangle(_cx - _mw / 2, _gh - 60, _cx + _mw / 2, _gh - 16, false);
        draw_set_color(make_color_rgb(150, 50, 40));
        draw_rectangle(_cx - _mw / 2, _gh - 60, _cx + _mw / 2, _gh - 16, true);
        draw_set_alpha(1);
        txt(_cx, _gh - 38, mensagem, FONTE.PEQUENA, make_color_rgb(255, 180, 150), _ma2, fa_center, fa_middle, min(1, (_gw - 80) / max(1, txt_largura(mensagem, FONTE.PEQUENA))));
    }
}

// =====================================================================
// BRASAS (em todas as telas)
// =====================================================================
gpu_set_blendmode(bm_add);
for (var _i = 0; _i < array_length(faiscas); _i++)
{
    var _f = faiscas[_i];
    var _fa = clamp(_f.vida / _f.vmax, 0, 1);
    draw_set_alpha(_fa * 0.8);
    draw_set_color(make_color_rgb(230, 70 + 80 * _fa, 30));
    draw_circle(_f.x, _f.y, _f.r, false);
    if (_q == 2)
    {
        draw_set_alpha(_fa * 0.2);
        draw_circle(_f.x, _f.y, _f.r * 3, false);
    }
}
gpu_set_blendmode(bm_normal);
desenho_resetar();
