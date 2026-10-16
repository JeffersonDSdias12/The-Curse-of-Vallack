var _dt = global.dt_real;
tempo += _dt;
tempo_total += _dt;
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;

// =====================================================================
// EFEITOS (brasas, relâmpagos, sangue do título, dicas)
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

if (relampago > 0) relampago -= _dt;
if (estado != "intro_creditos")
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

// as dicas mostram teclas ou botões, conforme o que está sendo usado
if (global.usando_pad != usando_pad_antes) { usando_pad_antes = global.usando_pad; dicas = dicas_tutorial(); dica_atual = dica_atual mod array_length(dicas); }

dica_tempo += _dt;
if (dica_tempo >= 220)
{
    dica_tempo = 0;
    dica_atual = (dica_atual + 1) mod array_length(dicas);
}
if (mensagem_tempo > 0) mensagem_tempo -= _dt;
if (estado != "intro_creditos" and estado != "intro_titulo") menu_aparece += _dt;

// =====================================================================
// ENTRADAS (teclado, controle e mouse)
// =====================================================================
var _bloq = instance_exists(obj_loading) or instance_exists(obj_cutscene);
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

// =====================================================================
// ESTADOS
// =====================================================================
switch (estado)
{
    // ----- ABERTURA 0: imagem de introdução ("este é um jogo fictício") -----
    // fica 6 s inteiros (entra em 0,7 s, fica e sai em 0,5 s)
    case "intro_aviso":
        // v1.8: não pula mais com tecla: o aviso de jogo fictício fica os 6 s inteiros
        if (tempo >= aviso_total)
        {
            if (img_aviso != -1 and sprite_exists(img_aviso)) sprite_delete(img_aviso);
            img_aviso = -1;
            estado = "intro_creditos";
            tempo = 0;
        }
    break;

    // ----- ABERTURA: créditos (não pode ser pulada) -----
    case "intro_creditos":
        if (tempo >= creditos_total)
        {
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
            mudar_estado("menu", 0, false);
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
            var _oy = menu_y(_i);
            if (point_in_rectangle(_mx, _my, _cx - 230, _oy - 27, _cx + 230, _oy + 27))
            {
                if (_mexeu) selecionado = _i;
                if (_clique) { selecionado = _i; _escolheu = true; }
            }
        }
        if (_escolheu and tempo > 25)
        {
            switch (selecionado)
            {
                case 0:
                    // o herói é Twilight Vetrus: escolhe-se só o nível de dificuldade
                    mudar_estado("dificuldade", global.dificuldade);
                break;
                case 1:
                    if (tem_save)
                    {
                        var _primeiro = 0;
                        for (var _s0 = 2; _s0 >= 0; _s0--) if (slots[_s0].existe) _primeiro = _s0;
                        mudar_estado("carregar", _primeiro);
                    }
                    else { aviso_menu("Nenhum jogo salvo ainda."); som("tit_negado", 0.7, 0); }
                break;
                case 2:
                    // livro com todos os pergaminhos do tutorial
                    livro_pag = 0;
                    livro_abre = 0;
                    mudar_estado("tutorial", 2);
                break;
                case 3: mudar_estado("opcoes", 0); break;
                case 4: game_end(); break;
            }
        }
    break;

    // ----- TUTORIAL: pergaminhos com todos os comandos e combos -----
    case "tutorial":
        livro_abre = min(1, livro_abre + _dt / 22);
        if (tempo < 18) break;
        if (_voltar or _clique_dir) { mudar_estado("menu", 2); break; }
        if (_esq and livro_pag > 0)                { livro_pag -= 1; livro_abre = 0.55; }
        if (_dir and livro_pag < TUT.TOTAL - 1)    { livro_pag += 1; livro_abre = 0.55; }
        if (_ok or _clique)
        {
            if (livro_pag < TUT.TOTAL - 1) { livro_pag += 1; livro_abre = 0.55; }
            else mudar_estado("menu", 2);
        }
    break;

    // ----- NÍVEL DE DIFICULDADE (escolhido antes de iniciar o jogo) -----
    case "dificuldade":
        if (_voltar) { mudar_estado("menu", 0); break; }
        // « »: liga / desliga o tutorial da fase (o mesmo de OPÇÕES)
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
            else mudar_estado("dificuldade", global.dificuldade);
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
                    dicas = dicas_tutorial();
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
                        dicas = dicas_tutorial();
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
                        dicas = dicas_tutorial();
                        io_clear();
                    }
                }
            }
        }
    break;
}

// som de "mover" quando a seleção (ou a página do livro) muda na mesma tela
if (estado == som_estado and (selecionado != som_sel or livro_pag != som_pag) and !_bloq) som("tit_mover", 0.55, 0.03);
som_estado = estado;
som_sel = selecionado;
som_pag = livro_pag;

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
            x: _cx + random_range(-200, 200), y: _oy2 + random_range(-10, 10),
            vx: random_range(-0.8, 0.8), vy: random_range(-1.6, -0.4),
            vida: irandom_range(25, 50), vmax: 50, r: random_range(1, 2.2)
        });
    }
}
selecionado_antes = selecionado;
