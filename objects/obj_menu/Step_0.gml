var _dt = global.dt_real;
tempo += _dt;
tempo_total += _dt;
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;

// =====================================================================
// EFEITOS (brasas, relâmpagos, sangue do título)
// =====================================================================
var _max_f = (global.cfg_qualidade == 0) ? 25 : (global.cfg_qualidade == 1 ? 45 : 75);
if (array_length(faiscas) < _max_f and random(1) < 0.4 * _dt)
{
    array_push(faiscas, {
        x: random_range(10, _gw - 10), y: _gh + 4,
        vx: random_range(-0.35, 0.35), vy: random_range(-1.3, -0.35),
        vida: irandom_range(60, 170), vmax: 170, r: random_range(1.2, 2.6)
    });
}
for (var _fi = array_length(faiscas) - 1; _fi >= 0; _fi--)
{
    var _f = faiscas[_fi];
    _f.x += (_f.vx + sin(current_time / 500 + _fi) * 0.12) * _dt;
    _f.y += _f.vy * _dt;
    _f.vida -= _dt;
    if (_f.vida <= 0) array_delete(faiscas, _fi, 1);
}

// cinzas caindo devagar, levadas pelo vento
var _max_c = (global.cfg_qualidade == 0) ? 0 : (global.cfg_qualidade == 1 ? 30 : 55);
if (array_length(cinzas) < _max_c and random(1) < 0.5 * _dt)
    array_push(cinzas, { x: random_range(-40, _gw), y: -6, vx: random_range(0.15, 0.55), vy: random_range(0.35, 0.9), r: random_range(0.8, 2), s: random(6.28) });
for (var _ci = array_length(cinzas) - 1; _ci >= 0; _ci--)
{
    var _c = cinzas[_ci];
    _c.x += (_c.vx + sin(tempo_total / 60 + _c.s) * 0.25) * _dt;
    _c.y += _c.vy * _dt;
    if (_c.y > _gh + 6) array_delete(cinzas, _ci, 1);
}

if (relampago > 0) relampago -= _dt;
if (estado != "intro_video")
{
    proximo_relampago -= _dt;
    if (proximo_relampago <= 0)
    {
        relampago = 26;
        proximo_relampago = irandom_range(420, 900);
    }
}

for (var _gi = array_length(gotas) - 1; _gi >= 0; _gi--)
{
    var _g = gotas[_gi];
    _g.comp = min(_g.comp_max, _g.comp + 0.35 * _dt);
    if (_g.comp >= _g.comp_max) _g.queda += 2.2 * _dt;
    _g.vida -= _dt;
    if (_g.vida <= 0) array_delete(gotas, _gi, 1);
}

if (mensagem_tempo > 0) mensagem_tempo -= _dt;
if (estado != "intro_video" and estado != "intro_titulo") menu_aparece += _dt;

// =====================================================================
// ENTRADAS (teclado, controle e mouse)
// =====================================================================
var _bloq = instance_exists(obj_loading) or instance_exists(obj_cutscene) or instance_exists(obj_mapa) or instance_exists(obj_perfil);     // v1.17: mapa e perfil por cima
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _mexeu = (mouse_antes_x != -1) and (_mx != mouse_antes_x or _my != mouse_antes_y);
var _clique = mouse_check_button_pressed(mb_left);
var _clique_dir = mouse_check_button_pressed(mb_right);
mouse_antes_x = _mx;
mouse_antes_y = _my;
var _cima = global.nav_cima;
var _baixo = global.nav_baixo;
var _esq = global.nav_esq;
var _dir = global.nav_dir;
var _ok = global.nav_ok;
var _voltar = global.nav_voltar;
if (_bloq)
{
    _cima = false; _baixo = false; _esq = false; _dir = false; _ok = false; _voltar = false;
    _clique = false; _clique_dir = false; _mexeu = false;
}
// v1.17: o fogo do menu reage ao ponteiro (faíscas no rastro, explosão no clique)
if (estado == "menu" or estado == "pressione" or estado == "opcoes") menu_fogo_atualizar(_mx, _my, _mexeu, _clique, _dt);

// =====================================================================
// ESTADOS
// =====================================================================
switch (estado)
{
    // ----- ABERTURA 0: vídeo do estúdio (GAMBITECH STUDIO) -----
    // passa inteiro, sem como pular; termina quando o vídeo acaba (com uma
    // folga de segurança caso o computador não consiga tocá-lo)
    case "intro_video":
        var _vst = video_get_status();
        var _vdur = video_get_duration();
        var _acabou = (tempo > 30 and _vst == video_status_closed)
            or (tempo > 30 and _vdur > 0 and video_get_position() >= _vdur - 40);
        if (_acabou or tempo > 60 * 26)
        {
            video_close();
            global.video_intro_ativo = false;
            io_clear();
            estado = (img_aviso != -1) ? "intro_aviso" : "intro_titulo";
            tempo = 0;
            musica("bgm_main_menu", 3000);
        }
    break;

    // ----- ABERTURA 1: imagem de introdução ("este é um jogo fictício") -----
    // fica 6 s inteiros (entra em 0,7 s, fica e sai em 0,5 s)
    case "intro_aviso":
        // v1.8: não pula mais com tecla: o aviso de jogo fictício fica os 6 s inteiros
        if (tempo >= aviso_total)
        {
            if (img_aviso != -1 and sprite_exists(img_aviso)) sprite_delete(img_aviso);
            img_aviso = -1;
            estado = "intro_titulo";
            tempo = 0;
        }
    break;

    // ----- ABERTURA: nome do jogo (não pode ser pulado; fica 5 s na tela) -----
    case "intro_titulo":
        if (tempo - _dt < titulo_inicio and tempo >= titulo_inicio) som("tit_logo", 0.9, 0);     // a logo surge
        if (tempo > titulo_inicio + 60 and tempo < titulo_total - 60 and global.cfg_qualidade > 0
            and random(1) < 0.07 * _dt and array_length(gotas) < 16 and titulo_x2 > titulo_x1)
        {
            array_push(gotas, { x: random_range(titulo_x1 + 10, titulo_x2 - 10), y: titulo_base,
                comp: 0, comp_max: random_range(8, 26), queda: 0, vida: 170 });
        }
        if (tempo >= titulo_total)
        {
            global.intro_vista = true;
            gotas = [];
            mudar_estado("pressione", 0, false);
        }
    break;

    // ----- v1.14: "PRESSIONE QUALQUER BOTÃO" (depois da abertura) -----
    case "pressione":
        var _algum = _ok or _voltar or _clique or _cima or _baixo or _esq or _dir or keyboard_check_pressed(vk_anykey);
        if (!_algum and global.pad_slot >= 0)
            for (var _b = gp_face1; _b <= gp_padr; _b++) if (gamepad_button_check_pressed(global.pad_slot, _b)) { _algum = true; break; }
        if (tempo > 30 and _algum and !_bloq)
        {
            som("tit_start", 0.8, 0);
            mudar_estado("menu", 0, false);
            selecionado = 0;     // v1.20: abre em CONTINUAR quando há progresso
            menu_aparece = 0;
            io_clear();
        }
    break;

    // ----- MENU INICIAL -----
    case "menu":
        var _n = array_length(opcoes_menu);
        if (_cima)  selecionado = (selecionado + _n - 1) mod _n;
        if (_baixo) selecionado = (selecionado + 1) mod _n;
        var _escolheu = _ok;
        for (var _i = 0; _i < _n; _i++)
        {
            var _bx = menu_caixa(_i);
            if (point_in_rectangle(_mx, _my, _bx[0], _bx[1], _bx[2], _bx[3]))
            {
                if (_mexeu) selecionado = _i;
                if (_clique) { selecionado = _i; _escolheu = true; }
            }
        }
        if (_escolheu and tempo > 25)
        {
            switch (opcoes_menu[selecionado])
            {
                case "CONTINUAR":
                    // v1.20: direto para o save mais recente do perfil
                    var _sr = slot_recente();
                    if (_sr != -1 and carregar_slot(_sr))
                    {
                        som("tit_start", 0.9, 0);
                        var _lc = instance_create_depth(0, 0, -10000, obj_loading);
                        _lc.modo = "carregar";
                        _lc.destino = global.checkpoint_room;
                    }
                    else { aviso_menu("Nenhum jogo salvo ainda."); som("tit_negado", 0.7, 0); }
                break;
                case "NOVO JOGO":
                    // v1.17: na primeira vez, o PERFIL (o nome de quem joga, só para as
                    // conquistas); depois o MAPA (fase e dificuldade)
                    som("tit_selecao", 0.8, 0.02);
                    if (global.perfil.nome == "") { var _pf = instance_create_depth(0, 0, -10400, obj_perfil); _pf.modo = "primeiro"; }
                    else instance_create_depth(0, 0, -10400, obj_mapa);
                break;
                case "CARREGAR JOGO":
                    if (tem_save)
                    {
                        var _primeiro = 0;
                        for (var _s0 = 2; _s0 >= 0; _s0--) if (slots[_s0].existe) _primeiro = _s0;
                        mudar_estado("carregar", _primeiro);
                    }
                    else { aviso_menu("Nenhum jogo salvo ainda."); som("tit_negado", 0.7, 0); }
                break;
                case "CONQUISTAS": som("tit_selecao", 0.8, 0.02); instance_create_depth(0, 0, -10400, obj_perfil); break;     // v1.17: CONQUISTAS
                case "OPÇÕES": mudar_estado("opcoes", 0); break;
                case "SAIR": game_end(); break;
            }
        }
    break;

    // ----- NÍVEL DE DIFICULDADE (escolhido antes de iniciar o jogo) -----
    case "dificuldade":
        if (_voltar) { mudar_estado("menu", 0); break; }
        // « »: liga / desliga o tutorial da tela de carregamento (o mesmo de OPÇÕES)
        if (_esq or _dir) { global.cfg_tutorial = 1 - global.cfg_tutorial; config_salvar(); som("tit_alterar", 0.7, 0.03); }
        if (_cima)  selecionado = (selecionado + DIF.TOTAL - 1) mod DIF.TOTAL;
        if (_baixo) selecionado = (selecionado + 1) mod DIF.TOTAL;
        var _escolha = _ok;
        for (var _d = 0; _d < DIF.TOTAL; _d++)
        {
            var _dy2 = dif_y(_d);
            if (point_in_rectangle(_mx, _my, _cx - 260, _dy2 - 24, _cx + 260, _dy2 + 24))
            {
                if (_mexeu) selecionado = _d;
                if (_clique) { selecionado = _d; _escolha = true; }
            }
        }
        if (_escolha and tempo > 10)
        {
            global.dificuldade = selecionado;
            var _livre = slot_vazio_primeiro();
            if (_livre != -1) iniciar_jogo(_livre);
            else
            {
                mudar_estado("slot_novo", 0);
                aviso_menu("Os 3 slots estão ocupados. Escolha qual sobrescrever.");
            }
        }
    break;

    // ----- ESCOLHA DE SLOT (carregar / novo jogo com slots cheios) -----
    case "carregar":
    case "slot_novo":
        if (_voltar)
        {
            if (estado == "carregar") mudar_estado("menu", 1);
            else { mudar_estado("menu", 0); instance_create_depth(0, 0, -10400, obj_mapa); }     // v1.17: volta ao mapa
            break;
        }
        if (_esq or _cima)  { selecionado = (selecionado + 2) mod 3; confirmar_slot = -1; }
        if (_dir or _baixo) { selecionado = (selecionado + 1) mod 3; confirmar_slot = -1; }
        var _conf = _ok;
        var _cw = min(300, _gw * 0.23);
        for (var _s = 0; _s < 3; _s++)
        {
            var _sx = _gw * (_s + 1) / 4;
            if (point_in_rectangle(_mx, _my, _sx - _cw / 2, 250, _sx + _cw / 2, 470))
            {
                if (_mexeu and selecionado != _s) { selecionado = _s; confirmar_slot = -1; }
                if (_clique) { selecionado = _s; _conf = true; }
            }
        }
        if (_conf and tempo > 10)
        {
            if (estado == "carregar")
            {
                if (slots[selecionado].existe and carregar_slot(selecionado + 1))
                {
                    var _l = instance_create_depth(0, 0, -10000, obj_loading);
                    _l.modo = "carregar";
                    _l.destino = global.checkpoint_room;
                }
                else { aviso_menu("Este slot está vazio."); som("tit_negado", 0.7, 0); }
            }
            else
            {
                if (slots[selecionado].existe and confirmar_slot != selecionado)
                {
                    confirmar_slot = selecionado;
                    aviso_menu("Confirme de novo para SOBRESCREVER o slot " + string(selecionado + 1) + ".");
                }
                else iniciar_jogo(selecionado + 1);
            }
        }
    break;

    // ----- OPÇÕES -----
    case "opcoes":
        var _n2 = array_length(opcoes_cfg);
        if (_voltar) { config_salvar(); mudar_estado("menu", 3); break; }
        if (_cima)  selecionado = (selecionado + _n2 - 1) mod _n2;
        if (_baixo) selecionado = (selecionado + 1) mod _n2;
        var _passo = _dir - _esq;
        var _ativar = _ok;
        var _pw = min(_gw - 80, 860);
        for (var _q = 0; _q < _n2; _q++)
        {
            var _qy = cfg_y(_q);
            if (point_in_rectangle(_mx, _my, _cx - _pw / 2, _qy - 18, _cx + _pw / 2, _qy + 18))
            {
                if (_mexeu) selecionado = _q;
                if (_clique)     { selecionado = _q; if (_q <= CFG_ULTIMO_VALOR) _passo = 1; else _ativar = true; }
                if (_clique_dir) { selecionado = _q; if (_q <= CFG_ULTIMO_VALOR) _passo = -1; }
            }
        }
        if (selecionado <= CFG_ULTIMO_VALOR)
        {
            if (_passo != 0) alterar_opcao(selecionado, _passo);
            else if (_ativar) alterar_opcao(selecionado, 1);
        }
        else if (_ativar and tempo > 6)
        {
            if (selecionado == CFG_ULTIMO_VALOR + 1) mudar_estado("teclado", 0);
            else if (selecionado == CFG_ULTIMO_VALOR + 2) mudar_estado("controle", 0);
            else { config_salvar(); mudar_estado("menu", 3); }
        }
    break;

    // ----- REMAPEAMENTO: TECLADO / CONTROLE (2 colunas) -----
    case "teclado":
    case "controle":
        var _modo_pad = (estado == "controle");
        var _total = ACAO.TOTAL + 2;          // ações + RESTAURAR PADRÃO + VOLTAR
        if (!capturando)
        {
            if (_voltar) { config_validar_controles(); config_salvar(); mudar_estado("opcoes", CFG_ULTIMO_VALOR + (_modo_pad ? 2 : 1)); break; }
            if (_cima)  selecionado = map_navegar(selecionado, 0, -1);
            if (_baixo) selecionado = map_navegar(selecionado, 0, 1);
            if (_esq or _dir) selecionado = map_navegar(selecionado, _dir - _esq, 0);
            var _at = _ok;
            for (var _r = 0; _r < _total; _r++)
            {
                var _mp = map_pos(_r);
                if (point_in_rectangle(_mx, _my, _mp[0] - _mp[2] / 2, _mp[1] - 21, _mp[0] + _mp[2] / 2, _mp[1] + 21))
                {
                    if (_mexeu) selecionado = _r;
                    if (_clique) { selecionado = _r; _at = true; }
                }
            }
            if (_at and tempo > 6)
            {
                if (selecionado < ACAO.TOTAL)
                {
                    if (_modo_pad and global.pad_slot < 0) aviso_menu("Conecte um controle para remapear os botões.");
                    else { capturando = true; capture_wait = 10; captura_solto = false; mensagem = ""; }
                }
                else if (selecionado == ACAO.TOTAL)
                {
                    if (_modo_pad) global.botoes = botoes_padrao(); else global.teclas = teclas_padrao();
                    config_salvar();
                    aviso_menu("Controles restaurados para o padrão.");
                }
                else { config_validar_controles(); config_salvar(); mudar_estado("opcoes", CFG_ULTIMO_VALOR + (_modo_pad ? 2 : 1)); }
            }
        }
        else if (selecionado < 0 or selecionado >= ACAO.TOTAL) capturando = false;     // segurança: só ações podem ser remapeadas
        else
        {
            var _acao_sel = acoes_tela[selecionado];
            var _cancelar = keyboard_check_pressed(vk_escape)
                or (global.pad_slot >= 0 and gamepad_button_check_pressed(global.pad_slot, gp_start));
            if (capture_wait > 0) capture_wait -= _dt;
            else if (_cancelar) { capturando = false; aviso_menu("Remapeamento cancelado."); som("tit_voltar", 0.7, 0); }
            else if (!_modo_pad)
            {
                if (keyboard_check_pressed(vk_anykey))
                {
                    var _k = keyboard_lastkey;
                    if (tecla_reservada(_k)) { aviso_menu(nome_tecla(_k) + " é reservada do sistema. Escolha outra tecla."); som("tit_negado", 0.7, 0); }
                    else
                    {
                        // se a tecla já era usada por outra ação, as duas trocam de lugar
                        var _antiga = global.teclas[_acao_sel];
                        for (var _j = 0; _j < ACAO.TOTAL; _j++)
                        {
                            if (_j != _acao_sel and global.teclas[_j] == _k)
                            {
                                global.teclas[_j] = _antiga;
                                aviso_menu("Tecla trocada com " + acoes[_j] + ".");
                            }
                        }
                        global.teclas[_acao_sel] = _k;
                        capturando = false;
                        som("tit_selecao", 0.8, 0.02);
                        config_salvar();
                        }
                }
            }
            else
            {
                if (global.pad_slot < 0) { capturando = false; aviso_menu("Controle desconectado."); }
                else
                {
                    // aceita qualquer botão, gatilho ou direcional (também de controles genéricos)
                    var _lista = botoes_remapeaveis();
                    var _novo = -1;
                    for (var _b = 0; _b < array_length(_lista); _b++)
                    {
                        if (pad_entrada(global.pad_slot, _lista[_b])) { _novo = _lista[_b]; break; }
                    }
                    if (!captura_solto)
                    {
                        if (_novo == -1) captura_solto = true;      // espera soltar o botão que abriu a captura
                    }
                    else if (_novo != -1)
                    {
                        var _velho = global.botoes[_acao_sel];
                        for (var _j2 = 0; _j2 < ACAO.TOTAL; _j2++)
                        {
                            if (_j2 != _acao_sel and global.botoes[_j2] == _novo)
                            {
                                global.botoes[_j2] = _velho;
                                aviso_menu("Botão trocado com " + acoes[_j2] + ".");
                            }
                        }
                        global.botoes[_acao_sel] = _novo;
                        capturando = false;
                        som("tit_selecao", 0.8, 0.02);
                        config_salvar();
                            io_clear();
                    }
                }
            }
        }
    break;
}

// som de "mover" quando a seleção muda na mesma tela
if (estado == som_estado and selecionado != som_sel and !_bloq) som("tit_mover", 0.55, 0.03);
som_estado = estado;
som_sel = selecionado;

// =====================================================================
// ANIMAÇÃO DOS ITENS E FAÍSCAS AO TROCAR DE OPÇÃO
// =====================================================================
for (var _a = 0; _a < array_length(anim); _a++)
{
    anim[_a] = lerp_dt(anim[_a], (_a == selecionado) ? 1 : 0, 0.2);
}
if (estado == "menu" and selecionado != selecionado_antes and selecionado_antes != -1 and global.cfg_qualidade > 0)
{
    var _oy2 = menu_y(selecionado);
    repeat (10)
    {
        array_push(faiscas, {
            x: menu_x() + random_range(-20, 320), y: _oy2 + random_range(-10, 10),
            vx: random_range(-0.8, 0.8), vy: random_range(-1.6, -0.4),
            vida: irandom_range(25, 50), vmax: 50, r: random_range(1, 2.2)
        });
    }
}
selecionado_antes = selecionado;
