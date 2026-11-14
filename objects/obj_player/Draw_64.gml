// =====================================================================
//  HUD (interface com 720 de altura; a largura acompanha a proporção)
// =====================================================================
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _ouro   = make_color_rgb(255, 210, 90);
var _ouro2  = make_color_rgb(176, 141, 70);
var _escuro = make_color_rgb(10, 10, 12);
var _fase   = fase_numero(room);

// ----- MOLDURA GÓTICA (estilo Castlevania): brasão, placa e sub-arma -----
// brasão com o retrato de Twilight; a joia mostra o nível da espada
var _bx = 14;
var _by0 = 10;
var _bw = 96;
var _x0 = _bx + _bw + 10;          // início das barras
hud_placa(_bx + _bw - 14, _by0 + 2, _x0 + 318, _by0 + 92, 0.95);
hud_brasao(_bx, _by0, _bw, global.espada_nivel);

// nome e dificuldade
var _nome = string_upper(global.nome_guerreiro);
if (txt_largura(_nome, FONTE.PEQUENA) + 12 + txt_largura(dificuldade_nome(), FONTE.MINI) > 270) _nome = string_upper(NOME_CURTO);
txt_sombra(_x0 + 2, _by0 + 6, _nome, FONTE.PEQUENA, make_color_rgb(250, 240, 220), 1, fa_left, fa_top);
txt(_x0 + 2 + txt_largura(_nome, FONTE.PEQUENA) + 12, _by0 + 9, dificuldade_nome(), FONTE.MINI, dificuldade_cor(), 0.95, fa_left, fa_top);

// VIDA: barra vermelha em gomos (a parte clara mostra o dano recente)
vida_atraso = lerp_dt(vida_atraso, vida, 0.05);
var _pct = clamp(vida / vida_max, 0, 1);
var _hy = _by0 + 36;
var _c1 = (_pct <= 0.3) ? make_color_rgb(255, 96, 72) : make_color_rgb(232, 58, 50);
hud_barra(_x0, _hy, 280, 18, _pct, vida_atraso / vida_max, _c1, make_color_rgb(112, 10, 16), 1, false, 16);
txt_sombra(_x0 + 262, _hy + 9, string(ceil(vida)) + " / " + string(vida_max), FONTE.MINI, make_color_rgb(255, 242, 228), 1, fa_right, fa_middle, 0.95);

// MAGIA (os especiais gastam uma parte; marcas no custo de cada especial)
var _my = _hy + 27;
var _mw = 236;
var _pct_es = clamp(especial_carga / ESPECIAL_SEGUNDOS, 0, 1);
hud_barra(_x0, _my, _mw, 10, _pct_es, 0, make_color_rgb(120, 190, 255), make_color_rgb(24, 54, 160));
var _acoes_esp = [ACAO.ESPECIAL_3, ACAO.ESPECIAL, ACAO.ESPECIAL_2];
for (var _m = 0; _m < 3; _m++)
{
    var _am = _acoes_esp[_m];
    if (!especial_liberado(_am)) continue;
    var _mx = _x0 + _mw * especial_custo(_am);
    draw_set_alpha(0.95);
    draw_set_color((_pct_es >= especial_custo(_am)) ? make_color_rgb(247, 222, 158) : make_color_rgb(70, 56, 50));
    draw_rectangle(_mx - 1, _my - 3, _mx, _my + 12, false);
}
draw_set_alpha(1);
txt_sombra(_x0 + _mw + 14, _my + 5, "MAGIA", FONTE.MINI, make_color_rgb(160, 204, 255), 1, fa_left, fa_middle, 0.75);
if (especial_pronto_fx > 0)
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(clamp(especial_pronto_fx / 50, 0, 1) * 0.45);
    draw_set_color(make_color_rgb(120, 170, 255));
    draw_rectangle(_x0 - 4, _my - 4, _x0 + _mw + 8, _my + 14, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// FÚRIA (enche acertando; cheia, libera a Ira de Vallack)
var _fy = _my + 19;
var _fw = 200;
var _pf = clamp(furia / 100, 0, 1);
var _f1 = make_color_rgb(255, 140, 48);
if (furia_modo) _f1 = merge_color(make_color_rgb(255, 40, 20), make_color_rgb(255, 210, 160), 0.5 + 0.5 * sin(current_time / 50));
else if (_pf >= 1) _f1 = merge_color(make_color_rgb(255, 110, 40), c_white, 0.3 + 0.3 * sin(current_time / 70));
hud_barra(_x0, _fy, _fw, 7, _pf, 0, _f1, make_color_rgb(140, 24, 10));
if (furia_modo or _pf >= 1)
{
    var _fx = _x0 + _fw + 14;
    var _ftxt = furia_modo ? "MODO FÚRIA" : "IRA DE VALLACK!";
    if (!furia_modo) _fx += desenhar_icone_acao(_fx, _fy + 3, ACAO.FURIA, 16, 0.8 + 0.2 * sin(current_time / 90)) + 6;
    txt_sombra(_fx, _fy + 3, _ftxt, FONTE.MINI, merge_color(make_color_rgb(255, 90, 50), c_white, 0.4 + 0.4 * sin(current_time / 80)), 1, fa_left, fa_middle, 0.9);
}
else txt_sombra(_x0 + _fw + 14, _fy + 3, "FÚRIA", FONTE.MINI, make_color_rgb(255, 160, 100), 1, fa_left, fa_middle, 0.75);
if (furia_cheia_fx > 0)
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(furia_cheia_fx / 60 * 0.6);
    draw_set_color(make_color_rgb(255, 60, 30));
    draw_rectangle(_x0 - 4, _fy - 4, _x0 + _fw + 8, _fy + 11, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// SUB-ARMA (quadro ao lado da placa): agachado mostra a Chama de Sylla
var _sub_chama = agachado;
var _sub_pode = global.essencia >= subarma_custo(_sub_chama);
var _qx = _x0 + 334;
var _qy = _by0 + 4;
hud_quadro_subarma(_qx, _qy, 62, _sub_chama ? 1 : 0, _sub_pode, global.essencia, global.essencia_fx);
// tecla da sub-arma (e o custo) no canto do quadro
var _wk = icone_acao_largura(ACAO.INTERAGIR, 16);
desenhar_icone_acao(_qx + 62 - _wk + 4, _qy + 62 - 4, ACAO.INTERAGIR, 16, _sub_pode ? 1 : 0.45);
txt_sombra(_qx + 6, _qy + 10, string(subarma_custo(_sub_chama)), FONTE.MINI, make_color_rgb(165, 212, 255), 0.9, fa_left, fa_middle, 0.8);

// ORBS (pagam a evolução da espada), embaixo da placa
var _cy = _by0 + 112;
var _oe = 1 + 0.25 * clamp(global.orbs_fx / 20, 0, 1);
var _orbs_txt = string(global.orbs);
var _w_cont = 44 + txt_largura(_orbs_txt, FONTE.PEQUENA) * 0.85;
hud_forma(hud_barra_pts(_x0 - 4, _cy - 12, _w_cont, 24), _cy - 12, 24, make_color_rgb(10, 6, 7), make_color_rgb(10, 6, 7), 0.6);
hud_orbe(_x0 + 8, _cy, 7 * _oe);
txt_sombra(_x0 + 20, _cy, _orbs_txt, FONTE.PEQUENA, make_color_rgb(255, 150, 120), 1, fa_left, fa_middle, 0.85 * _oe);
// dá para evoluir: lembrete
var _prox_n = global.espada_nivel + 1;
if (_prox_n <= ESPADA_NIVEL_MAX and global.orbs >= espada_custo(_prox_n))
    txt_sombra(_x0 + _w_cont + 10, _cy, botao_menu_armas() + ": EVOLUIR A ESPADA", FONTE.MINI, _ouro, 0.6 + 0.4 * sin(current_time / 200), fa_left, fa_middle, 0.9);
// v1.14: a CHAVE DO PORTÃO, quando Twilight está com ela
if (variable_global_exists("chave_portao") and global.chave_portao and instance_exists(obj_portao_trancado) and obj_portao_trancado.estado == "trancado")
{
    var _ky = _cy + 30;
    hud_forma(hud_barra_pts(_x0 - 4, _ky - 12, 96, 24), _ky - 12, 24, make_color_rgb(10, 6, 7), make_color_rgb(10, 6, 7), 0.6);
    desenhar_chave(_x0 + 8, _ky - 1, 0.95, 1);
    txt_sombra(_x0 + 22, _ky, "CHAVE", FONTE.MINI, make_color_rgb(250, 210, 120), 0.8 + 0.2 * sin(current_time / 180), fa_left, fa_middle, 0.9);
}
// ----- AVISO: especial bloqueado / sem magia / sem fúria -----
if (bloqueado_aviso > 0 and bloqueado_txt != "")
{
    var _ba2 = clamp(bloqueado_aviso / 15, 0, 1);
    txt_sombra(_gw / 2, _gh * 0.62, bloqueado_txt, FONTE.PEQUENA, make_color_rgb(255, 140, 110), _ba2, fa_center, fa_middle, min(1, (_gw - 60) / max(1, txt_largura(bloqueado_txt, FONTE.PEQUENA))));
}

// ----- COMBO (canto direito) -----
// v1.12: a "taxa de acerto" saiu da tela (menos informação durante a luta)
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
        // v1.14: o portão trancado e a chave no baú do forte
        else if (variable_global_exists("arena_chave") and global.arena_chave) _obj = "Derrote os guardiões do baú";
        else if (variable_global_exists("portao_visto") and global.portao_visto and instance_exists(obj_portao_trancado) and obj_portao_trancado.estado == "trancado")
            _obj = global.chave_portao ? "Volte ao portão com a chave  »" : "Ache a chave do portão: suba ao forte de madeira";
    }
    if (_fase == 2)
    {
        var _vivos = 0;
        with (obj_inimigo_base) if (!morrendo) _vivos += 1;
        _obj = "INIMIGOS RESTANTES: " + string(_vivos);
    }
    // a faixa só aparece quando o objetivo muda (7 s) e some: menos coisa na
    // tela durante a luta, como nos Castlevania
    if (_obj != objetivo_txt)
    {
        // v1.16: objetivo novo toca a mensagem importante (a contagem de inimigos
        // da fase 2 só atualiza a faixa, sem som a cada inimigo)
        if (_obj != "" and (objetivo_txt == "" or _fase != 2)) som_mensagem();
        objetivo_txt = _obj;
        objetivo_t = 420;
    }
    objetivo_t = max(0, objetivo_t - global.dt_real);
    var _oa = clamp(objetivo_t / 40, 0, 1) * 0.95;
    if (_oa > 0.01)
    {
        // faixa gótica entre a moldura do herói e o combo; em telas estreitas (4:3)
        // ela desce para não cobrir a moldura
        var _cap = "CAPÍTULO " + string(_fase) + "  ·  " + fase_nome(_fase);
        var _esq = 548;
        var _dir = _gw - 230;
        var _wt = max(txt_largura(_cap, FONTE.MINI), txt_largura(_obj, FONTE.PEQUENA));
        var _oy = 8;
        if (_dir - _esq < _wt * 0.75 + 60) { _esq = 30; _dir = _gw - 30; _oy = 150; }
        var _wf = min(_dir - _esq, _wt + 120);
        var _e_txt = min(1, (_wf - 70) / max(1, _wt));
        var _cxb = clamp(_gw / 2, _esq + _wf / 2, _dir - _wf / 2);
        hud_faixa(_cxb - _wf / 2, _oy, _cxb + _wf / 2, _oy + 56, _oa);
        txt(_cxb, _oy + 17, _cap, FONTE.MINI, make_color_rgb(206, 164, 86), _oa, fa_center, fa_middle, _e_txt);
        txt_sombra(_cxb, _oy + 38, _obj, FONTE.PEQUENA, make_color_rgb(250, 240, 220), _oa, fa_center, fa_middle, _e_txt);
    }
}

// ----- BARREIRA DO GUARDIÃO -----
if (barreira_aviso > 0)
{
    var _ba = clamp(barreira_aviso / 20, 0, 1);
    txt_sombra(_gw / 2, _gh * 0.42, "Uma barreira amaldiçoada bloqueia o caminho.", FONTE.PEQUENA, make_color_rgb(255, 120, 100), _ba, fa_center, fa_middle);
    txt_sombra(_gw / 2, _gh * 0.42 + 28, "Derrote o guardião para seguir em frente.", FONTE.MINI, c_white, _ba, fa_center, fa_middle);
}

// ----- BOTÃO ABRIR: aparece sobre o baú quando Twilight está perto -----
if (alvo_interacao != noone and instance_exists(alvo_interacao) and alvo_interacao.object_index == obj_bau and view_camera[0] != -1)
{
    var _cam = view_camera[0];
    var _ax = (alvo_interacao.x - camera_get_view_x(_cam)) * _gw / camera_get_view_width(_cam);
    var _ay = (alvo_interacao.bbox_top - camera_get_view_y(_cam)) * _gh / camera_get_view_height(_cam);
    hud_botao_contexto(_ax, _ay - 18, "ABRIR", true);
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
    draw_set_alpha(min(0.2, global.last_hit_flash / 50));   // v1.18: mais fraco (em grupo a tela piscava branca sem parar)
    draw_set_color(c_white);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
}

desenho_resetar();
