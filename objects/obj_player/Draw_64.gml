// =====================================================================
//  HUD (interface com 720 de altura; a largura acompanha a proporção)
// =====================================================================
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ouro   = make_color_rgb(255, 210, 90);
var _ouro2  = make_color_rgb(176, 141, 70);
var _escuro = make_color_rgb(10, 10, 12);
var _fase   = fase_numero(room);

// ----- PAINEL DO GUERREIRO -----
var _x = 34;
var _y = 24;
var _larg = 312;
desenhar_painel(_x - 14, _y - 12, _x + _larg + 14, _y + 122, 0, 0.9);
// nome completo (TWILIGHT VETRUS); se não couber ao lado da dificuldade e da vida, só o primeiro nome
var _nome = string_upper(global.nome_guerreiro);
var _vida_txt = string(ceil(vida)) + " / " + string(vida_max);
if (txt_largura(_nome, FONTE.PEQUENA) + 12 + txt_largura(dificuldade_nome(), FONTE.MINI) + 18 + txt_largura(_vida_txt, FONTE.MINI) > _larg) _nome = string_upper(NOME_CURTO);
txt_sombra(_x, _y - 2, _nome, FONTE.PEQUENA, c_white, 1, fa_left, fa_top);
txt(_x + txt_largura(_nome, FONTE.PEQUENA) + 12, _y + 1, dificuldade_nome(), FONTE.MINI, dificuldade_cor(), 0.95, fa_left, fa_top);
txt(_x + _larg, _y, _vida_txt, FONTE.MINI, make_color_rgb(225, 225, 225), 1, fa_right, fa_top);

// barra de vida (a parte branca mostra o dano recente)
var _by = _y + 26;
var _alt = 14;
vida_atraso = lerp_dt(vida_atraso, vida, 0.05);
var _pct   = clamp(vida / vida_max, 0, 1);
var _pct_r = clamp(vida_atraso / vida_max, 0, 1);
var _c1 = (_pct <= 0.3) ? make_color_rgb(240, 90, 70) : make_color_rgb(120, 220, 90);
var _c2 = (_pct <= 0.3) ? make_color_rgb(120, 20, 20) : make_color_rgb(30, 110, 40);
draw_set_color(_escuro);
draw_rectangle(_x - 2, _by - 2, _x + _larg + 2, _by + _alt + 2, false);
draw_set_color(c_white);
draw_rectangle(_x, _by, _x + _larg * _pct_r, _by + _alt, false);
draw_rectangle_color(_x, _by, _x + _larg * _pct, _by + _alt, _c1, _c1, _c2, _c2, false);
draw_set_color(_ouro2);
draw_rectangle(_x - 2, _by - 2, _x + _larg + 2, _by + _alt + 2, true);

// ----- MAGIA (os especiais gastam uma parte; enche em 10 s) -----
var _ey = _by + _alt + 30;
var _pct_es = clamp(especial_carga / ESPECIAL_SEGUNDOS, 0, 1);
txt(_x, _ey - 6, "MAGIA", FONTE.MINI, make_color_rgb(140, 190, 255), 1, fa_left, fa_bottom);
// ícones dos 3 especiais (cadeado = evolua a espada; apagado = falta magia)
var _ix = _x + txt_largura("MAGIA", FONTE.MINI) + 10;
var _acoes_esp = [ACAO.ESPECIAL_3, ACAO.ESPECIAL, ACAO.ESPECIAL_2];
for (var _ie = 0; _ie < 3; _ie++)
{
    var _ae = _acoes_esp[_ie];
    var _lib = especial_liberado(_ae);
    var _da = _lib and (_pct_es >= especial_custo(_ae));
    var _wi = desenhar_icone_acao(_ix, _ey - 15, _ae, 18, _da ? 1 : 0.4);
    if (!_lib) desenhar_cadeado(_ix + _wi / 2, _ey - 15, 0.9);
    _ix += _wi + 5;
}
draw_set_color(_escuro);
draw_rectangle(_x - 2, _ey - 2, _x + _larg + 2, _ey + 10, false);
var _ca = make_color_rgb(110, 170, 255);
var _cb = make_color_rgb(30, 50, 140);
draw_rectangle_color(_x, _ey, _x + _larg * _pct_es, _ey + 8, _ca, _ca, _cb, _cb, false);
// marcas do custo de cada especial liberado
for (var _m = 0; _m < 3; _m++)
{
    var _am = _acoes_esp[_m];
    if (!especial_liberado(_am)) continue;
    var _mx = _x + _larg * especial_custo(_am);
    draw_set_color((_pct_es >= especial_custo(_am)) ? c_white : make_color_rgb(200, 120, 100));
    draw_rectangle(_mx - 1, _ey - 3, _mx + 1, _ey + 11, false);
}
draw_set_color(_ouro2);
draw_rectangle(_x - 2, _ey - 2, _x + _larg + 2, _ey + 10, true);
if (especial_pronto_fx > 0)
{
    var _fa = clamp(especial_pronto_fx / 50, 0, 1);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_fa * 0.5);
    draw_set_color(make_color_rgb(120, 170, 255));
    draw_rectangle(_x - 6, _ey - 6, _x + _larg + 6, _ey + 14, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ----- FÚRIA (enche acertando; cheia, libera a Ira de Vallack) -----
var _fy = _ey + 36;
var _pf = clamp(furia / 100, 0, 1);
var _cheia = (_pf >= 1);
txt(_x, _fy - 6, "FÚRIA", FONTE.MINI, make_color_rgb(255, 110, 70), 1, fa_left, fa_bottom);
if (_cheia)
{
    var _wf = desenhar_icone_acao(_x + txt_largura("FÚRIA", FONTE.MINI) + 10, _fy - 15, ACAO.FURIA, 18, 0.7 + 0.3 * sin(current_time / 90));
    txt(_x + txt_largura("FÚRIA", FONTE.MINI) + 18 + _wf, _fy - 6, "IRA DE VALLACK!", FONTE.MINI, merge_color(make_color_rgb(255, 80, 50), c_white, 0.5 + 0.5 * sin(current_time / 90)), 1, fa_left, fa_bottom);
}
draw_set_color(_escuro);
draw_rectangle(_x - 2, _fy - 2, _x + _larg + 2, _fy + 8, false);
var _f1 = _cheia ? merge_color(make_color_rgb(255, 80, 40), c_white, 0.3 + 0.3 * sin(current_time / 70)) : make_color_rgb(255, 90, 40);
var _f2 = make_color_rgb(130, 10, 10);
draw_rectangle_color(_x, _fy, _x + _larg * _pf, _fy + 6, _f1, _f1, _f2, _f2, false);
draw_set_color(_cheia ? _ouro : _ouro2);
draw_rectangle(_x - 2, _fy - 2, _x + _larg + 2, _fy + 8, true);
if (furia_cheia_fx > 0)
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(furia_cheia_fx / 60 * 0.6);
    draw_set_color(make_color_rgb(255, 60, 30));
    draw_rectangle(_x - 6, _fy - 6, _x + _larg + 6, _fy + 12, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ----- POTE DE ORBS (embaixo do painel) -----
var _pox = _x + 10;
var _poy = _y + 160;
desenhar_painel(_pox - 24, _poy - 22, _pox + 110, _poy + 24, 0, 0.85);
desenhar_pote_orbs(_pox, _poy + 2, 1, 1, global.orbs_fx);
var _oesc = 1 + 0.25 * clamp(global.orbs_fx / 20, 0, 1);
txt_sombra(_pox + 24, _poy - 5, string(global.orbs), FONTE.PEQUENA, make_color_rgb(255, 120, 100), 1, fa_left, fa_middle, _oesc);
txt(_pox + 24, _poy + 13, "ESPADA NV " + string(global.espada_nivel), FONTE.MINI, _ouro2, 1, fa_left, fa_middle, 0.85);
// dá para evoluir: lembrete
var _prox_n = global.espada_nivel + 1;
if (_prox_n <= ESPADA_NIVEL_MAX and global.orbs >= espada_custo(_prox_n))
{
    var _la = 0.6 + 0.4 * sin(current_time / 200);
    txt(_pox - 24, _poy + 36, botao_menu_armas() + ": EVOLUIR A ESPADA", FONTE.MINI, _ouro, _la, fa_left, fa_middle);
}

// ----- AVISO: especial bloqueado / sem magia / sem fúria -----
if (bloqueado_aviso > 0 and bloqueado_txt != "")
{
    var _ba2 = clamp(bloqueado_aviso / 15, 0, 1);
    txt_sombra(_gw / 2, _gh * 0.62, bloqueado_txt, FONTE.PEQUENA, make_color_rgb(255, 140, 110), _ba2, fa_center, fa_middle, min(1, (_gw - 60) / max(1, txt_largura(bloqueado_txt, FONTE.PEQUENA))));
}

// ----- TAXA DE ACERTO E COMBO (canto direito) -----
var _taxa = global.attacks_total > 0 ? (global.hits_total / global.attacks_total) * 100 : 0;
txt_sombra(_gw - 34, 26, "TAXA DE ACERTO  " + string_format(min(_taxa, 999), 1, 0) + "%", FONTE.PEQUENA, _ouro, 1, fa_right, fa_top);
if (global.combo >= 2)
{
    var _pulo = 1 + 0.12 * clamp(global.combo_tempo - 100, 0, 20) / 20;
    txt_sombra(_gw - 34, 58, string(global.combo) + " GOLPES", FONTE.MEDIA, make_color_rgb(255, 120, 70), 1, fa_right, fa_top, _pulo);
}
// sequência do combo em andamento (ícones dos botões apertados)
if (cadeia != "" and (cadeia_janela > 0 or !is_undefined(golpe)))
{
    var _nc = string_length(cadeia);
    var _cxr = _gw - 34;
    for (var _ci = _nc; _ci >= 1; _ci--)
    {
        var _ac = combo_acao_da_letra(string_char_at(cadeia, _ci));
        var _wi = icone_acao_largura(_ac, 26);
        _cxr -= _wi;
        desenhar_icone_acao(_cxr, 112, _ac, 26, 0.95);
        _cxr -= 8;
    }
    txt_sombra(_cxr - 4, 112, "COMBO", FONTE.MINI, _ouro2, 0.9, fa_right, fa_middle);
}

// ----- NOME DO COMBO (finalizadores) -----
if (combo_nome_t > 0 and combo_nome != "")
{
    var _cn = clamp(combo_nome_t / 20, 0, 1) * clamp((110 - combo_nome_t) / 8, 0, 1);
    var _ce = 1 + 0.25 * clamp((combo_nome_t - 95) / 15, 0, 1);
    gpu_set_blendmode(bm_add);
    txt(_gw / 2, _gh * 0.27, combo_nome, FONTE.MEDIA, make_color_rgb(160, 10, 10), _cn * 0.8, fa_center, fa_middle, _ce * 1.08);
    gpu_set_blendmode(bm_normal);
    txt_sombra(_gw / 2, _gh * 0.27, combo_nome, FONTE.MEDIA, make_color_rgb(255, 205, 120), _cn, fa_center, fa_middle, _ce);
}

// ----- OBJETIVO DA FASE (centro, no topo) -----
if (_fase > 0)
{
    var _obj = fase_objetivo(_fase);
    if (_fase == 1)
    {
        var _boss = instance_find(obj_boss_01, 0);
        var _mini = instance_find(obj_mini_boss, 0);
        if (_boss == noone) _obj = "O caminho está livre: siga para o castelo  »";
        else if (_boss.acordado or _boss.estado_ia == "despertar") _obj = "Derrote a " + _boss.nome_boss;
        else if (_mini != noone and _mini.acordado and !_mini.morrendo) _obj = "Derrote " + _mini.nome_boss;
    }
    if (_fase == 2)
    {
        var _vivos = 0;
        with (obj_inimigo_base) if (!morrendo) _vivos += 1;
        _obj = "INIMIGOS RESTANTES: " + string(_vivos);
    }
    // em telas estreitas (4:3) o objetivo desce para não cobrir o painel do guerreiro
    var _oy = (_gw >= 1180) ? 22 : 156;
    txt_sombra(_gw / 2, _oy, "CAPÍTULO " + string(_fase) + "  ·  " + fase_nome(_fase), FONTE.MINI, _ouro2, 0.95, fa_center, fa_top);
    txt_sombra(_gw / 2, _oy + 20, _obj, FONTE.PEQUENA, c_white, 0.95, fa_center, fa_top);
}

// ----- BARREIRA DO GUARDIÃO -----
if (barreira_aviso > 0)
{
    var _ba = clamp(barreira_aviso / 20, 0, 1);
    txt_sombra(_gw / 2, _gh * 0.42, "Uma barreira amaldiçoada bloqueia o caminho.", FONTE.PEQUENA, make_color_rgb(255, 120, 100), _ba, fa_center, fa_middle);
    txt_sombra(_gw / 2, _gh * 0.42 + 28, "Derrote o guardião para seguir em frente.", FONTE.MINI, c_white, _ba, fa_center, fa_middle);
}

// ----- POUCA VIDA: vinheta vermelha pulsando -----
if (_pct <= 0.3 and vida > 0)
{
    var _p = 0.35 + 0.25 * (0.5 + 0.5 * sin(current_time / 150));
    desenhar_vinheta(_gw, _gh, _p, make_color_rgb(170, 0, 0));
}

// ----- FLASH DE IMPACTO -----
if (global.last_hit_flash > 0)
{
    draw_set_alpha(global.last_hit_flash / 26);
    draw_set_color(c_white);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
}

desenho_resetar();
