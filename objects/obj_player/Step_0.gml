// =====================================================================
//  obj_player — Step
//  (o movimento/colisão acontece no End Step do pai obj_entidade)
// =====================================================================
var _dt = global.dt;
var _chao = place_meeting(x, y + 1, obj_chao);

// ----- ENTRADAS (teclado + controle + analógico, já mapeados) -----
var _livre    = !instance_exists(obj_final) and !instance_exists(obj_loading) and !instance_exists(obj_resultado) and global.bloqueio_input <= 0;
var _left     = _livre and input_segurado(ACAO.ESQUERDA);
var _right    = _livre and input_segurado(ACAO.DIREITA);
var _jump     = _livre and input_apertado(ACAO.PULAR);
var _abaixar  = _livre and input_segurado(ACAO.AGACHAR);
var _bloqueio = _livre and input_segurado(ACAO.DEFENDER);
var _aparar   = _livre and input_apertado(ACAO.DEFENDER);
var _interagir = _livre and input_apertado(ACAO.INTERAGIR);
var _esquiva  = _livre and (input_apertado(ACAO.ESQUIVA) or global.esquiva_stick != 0);
var _furia_btn = _livre and input_apertado(ACAO.FURIA);
// botões de ataque: QUADRADO, TRIÂNGULO e BOLA
var _botao = "";
if (_livre)
{
    if (input_apertado(ACAO.ATACAR))       _botao = "Q";
    if (input_apertado(ACAO.ATAQUE_FORTE)) _botao = "T";
    if (input_apertado(ACAO.ATAQUE_SALTO)) _botao = "C";
}
// especiais (os 3 usam a mesma barra de magia)
var _esp = -1;
if (_livre)
{
    if (input_apertado(ACAO.ESPECIAL))   _esp = ACAO.ESPECIAL;
    if (input_apertado(ACAO.ESPECIAL_2)) _esp = ACAO.ESPECIAL_2;
    if (input_apertado(ACAO.ESPECIAL_3)) _esp = ACAO.ESPECIAL_3;
}

// ----- Twilight SEMPRE CORRE: não existe mais "andar" nem botão de correr -----
var _dir_agora = _right - _left;

// ----- MENUS: ESC / SELECT = pausa (opções) · TAB / START = armas e evolução -----
if (_livre and !morto and !instance_exists(obj_pausa) and !instance_exists(obj_save_menu) and !instance_exists(obj_menu_armas))
{
    if (input_pausa_apertada())
    {
        instance_create_depth(0, 0, -10000, obj_pausa);
        exit;
    }
    if (input_armas_apertado())
    {
        instance_create_depth(0, 0, -10000, obj_menu_armas);
        exit;
    }
}

// ----- INTERAGIR: cristal dourado (salvar) e baús de vida -----
alvo_interacao = noone;
if (!morto and _chao and is_undefined(golpe) and !rolando)
{
    var _bau = instance_nearest(x, y, obj_bau);
    if (_bau != noone and _bau.estado == "fechado" and _bau.visivel and abs(_bau.x - x) < 46 and abs(_bau.y - y) < 40) alvo_interacao = _bau;
    else
    {
        var _sp = instance_nearest(x, y, obj_save_point);
        if (_sp != noone and point_distance(x, y, _sp.x, _sp.y) < 70) alvo_interacao = _sp;
    }
}
if (_interagir and alvo_interacao != noone and !instance_exists(obj_save_menu) and !instance_exists(obj_pausa))
{
    if (alvo_interacao.object_index == obj_bau)
    {
        facing = sign(alvo_interacao.x - x);
        if (facing == 0) facing = 1;
        with (alvo_interacao) bau_abrir(other.id);
        velh = 0;
    }
    else
    {
        // perto do cristal dourado: salva (e recupera a vida, menos no EXTREMO)
        if (dif_cristal_cura()) { vida = vida_max; vida_atraso = vida; }
        var _menu_salvar = instance_create_depth(0, 0, -10000, obj_save_menu);
        _menu_salvar.modo = "salvar";
        exit;
    }
}

// ----- TEMPORIZADORES -----
if (tempo_invencivel > 0) tempo_invencivel = max(0, tempo_invencivel - _dt);
if (buffer_pulo > 0) buffer_pulo -= _dt;
if (buffer_golpe_t > 0) { buffer_golpe_t -= _dt; if (buffer_golpe_t <= 0) buffer_golpe = ""; }
if (cadeia_janela > 0) { cadeia_janela -= _dt; if (cadeia_janela <= 0 and is_undefined(golpe)) cadeia = ""; }
if (combo_nome_t > 0) combo_nome_t -= _dt;
if (brilho_golpe > 0) brilho_golpe -= _dt;
if (pouso > 0) pouso -= _dt;
if (especial_pronto_fx > 0) especial_pronto_fx -= _dt;
if (defesa_fx > 0) defesa_fx -= _dt;
if (barreira_aviso > 0) barreira_aviso -= _dt;
if (bloqueado_aviso > 0) bloqueado_aviso -= _dt;
if (rolar_recarga > 0) rolar_recarga -= _dt;
if (janela_aparar > 0) janela_aparar -= _dt;
if (aparar_recarga > 0) aparar_recarga -= _dt;
if (aparar_fx > 0) aparar_fx -= _dt;
if (esquiva_fx > 0) esquiva_fx -= global.dt_real;
if (furia_cheia_fx > 0) furia_cheia_fx -= _dt;
if (cura_fx > 0) cura_fx -= _dt;
if (global.combo_tempo > 0)
{
    global.combo_tempo -= _dt;
    if (global.combo_tempo <= 0) global.combo = 0;
}
if (global.last_hit_flash > 0) global.last_hit_flash = max(0, global.last_hit_flash - global.dt_real);
if (global.camera_impact > 0) global.camera_impact = max(0, global.camera_impact - global.dt_real);
if (global.terremoto > 0) global.terremoto = max(0, global.terremoto - global.dt_real);
if (array_length(debug_golpe) > 4)
{
    debug_golpe[4] -= _dt;
    if (debug_golpe[4] <= 0) debug_golpe = [];
}
for (var _r = array_length(rastros) - 1; _r >= 0; _r--)
{
    rastros[_r].vida -= _dt;
    if (rastros[_r].vida <= 0) array_delete(rastros, _r, 1);
}
for (var _fa = array_length(fantasmas) - 1; _fa >= 0; _fa--)
{
    fantasmas[_fa].vida -= _dt;
    if (fantasmas[_fa].vida <= 0) array_delete(fantasmas, _fa, 1);
}

// ----- CURA AOS POUCOS (magia do baú entrando em Twilight) -----
if (cura_restante > 0 and !morto)
{
    var _c = min(cura_restante, 0.55 * _dt);
    vida = min(vida_max, vida + _c);
    cura_restante -= _c;
    if (vida >= vida_max) cura_restante = 0;
}

// ----- TUTORIAL EM PERGAMINHO (fase 1) -----
if (_livre and !morto) tempo_fase += _dt;
if (room == Room1 and !morto)
{
    if (tempo_fase > 20) tutorial_mostrar(TUT.INICIO);
    if (global.inimigos_derrotados >= 2) tutorial_mostrar(TUT.ESPECIAIS);
    if (global.orbs_coletados > 0) tutorial_mostrar(TUT.ORBS);
    if (furia >= 100) tutorial_mostrar(TUT.FURIA);
    if (alvo_finalizavel() != noone) tutorial_mostrar(TUT.FINALIZADOR);
    var _cx_perto = instance_nearest(x, y, obj_destrutivel);
    if (_cx_perto != noone and abs(_cx_perto.x - x) < 170) tutorial_mostrar(TUT.CENARIO);
}

// ----- BARRA DE MAGIA DOS ESPECIAIS: enche em 10 segundos -----
if (!especial and especial_carga < ESPECIAL_SEGUNDOS)
{
    var _antes = especial_carga;
    especial_carga = min(ESPECIAL_SEGUNDOS, especial_carga + _dt / 60);
    if (especial_carga >= ESPECIAL_SEGUNDOS and _antes < ESPECIAL_SEGUNDOS) especial_pronto_fx = 50;
}

// zoom dramático durante os especiais (finalizador e fúria controlam o próprio zoom)
if (is_undefined(golpe) or (golpe.chave != "finalizador" and golpe.chave != "ira")) global.camera_zoom = especial ? 1.14 : 1;

if (!morto) tempo_sem_dano += _dt;

// ----- CAIU DO MAPA: volta ao checkpoint -----
if (!morto and y > room_height + 160)
{
    var _rx = spawn_x;
    var _ry = spawn_y;
    if (global.checkpoint_ativo and room == global.checkpoint_room) { _rx = global.checkpoint_x; _ry = global.checkpoint_y; }
    x = _rx; y = _ry; velh = 0; velv = 0; empurrao = 0;
    tempo_invencivel = 60;
    machucado = false; bloqueando = false; rolando = false;
    golpe_cancelar();
    cadeia = "";
    trocar_animacao(spr_player_idle, 1);
    global.cam_snap = true;
}

// ----- FIM DA FASE 1: chegou ao fim do caminho depois de vencer o boss -----
// DEMO: mostra o resultado e "Obrigado por jogar nossa Demo." e volta ao menu.
if (!morto and _livre and room == Room1 and x >= room_width - 100 and !global.transicao_fase and instance_number(obj_boss_01) == 0)
{
    global.transicao_fase = true;
    if (DEMO_FIM_NA_FASE_1)
    {
        instance_create_depth(0, 0, -10500, obj_resultado);
    }
    else
    {
        global.capitulo = 2;
        global.checkpoint_ativo = false;
        som("fase_concluida", 1, 0);           // som de passar de fase
        var _load = instance_create_depth(0, 0, -10000, obj_loading);
        _load.modo = "transicao";
        _load.destino = Room2;
    }
}

// ----- FIM DO JOGO NA FASE 2: não resta nenhum inimigo vivo -----
if (!morto and _livre and room == Room2 and !global.transicao_fase and inimigos_vivos() == 0)
{
    instance_create_depth(0, 0, -10500, obj_final);
}

// =====================================================================
// MORTE
// =====================================================================
if (morto)
{
    velh = 0;
    if (!_chao) velv += grav * _dt;
    tempo_morte += _dt;
    if (tempo_morte >= 90 and !instance_exists(obj_game_over)) instance_create_depth(0, 0, -10000, obj_game_over);
    exit;
}

// ----- DANO RECEBIDO: fica parado até a animação terminar -----
if (machucado) velh = 0;
var _pode_agir = !machucado;

// ----- TEIA DA MULHER-ARANHA: lento, sem pulo e sem rolagem -----
if (teia_imune > 0) teia_imune = max(0, teia_imune - _dt);
if (enredado_fx > 0) enredado_fx = max(0, enredado_fx - _dt);
if (enredado > 0)
{
    enredado = max(0, enredado - _dt);
    // apertar os botões rasga a teia mais rápido
    if (_jump or _esquiva or _botao != "" or _furia_btn) { enredado = max(0, enredado - 13); enredado_fx = 6; }
    _jump = false;
    _esquiva = false;
    rolar_buffer = 0;
    buffer_pulo = 0;
    if (enredado <= 0)
    {
        teia_imune = 40;
        som("teia_disparo", 0.35);
    }
}

// =====================================================================
// ESQUIVA (rolagem): quadros 2-19 de 26 sem levar dano
// =====================================================================
if (rolando)
{
    var _t_antes = rolar_t;
    rolar_t += _dt;
    var _p = clamp(rolar_t / ROLAR_DURACAO, 0, 1);
    // sai rápida e freia suave no fim
    velh = rolar_dir * ROLAR_VEL * (1 - 0.72 * _p);
    // rastro: um "fantasma" a cada 3 quadros (também a 30 FPS)
    if (floor(_t_antes / 3) != floor(rolar_t / 3)) array_push(fantasmas, { x: x, y: y, ang: rolar_angulo(_p), dir: rolar_dir, vida: 12, vmax: 12 });
    if (_chao and floor(_t_antes / 7) != floor(rolar_t / 7)) fx_criar("poeira", x - rolar_dir * 10, y, 0.35);
    if (rolar_t >= ROLAR_DURACAO)
    {
        rolando = false;
        rolar_recarga = 8;
        if (_chao) fx_criar("poeira", x, y, 0.6);
        trocar_animacao(spr_player_idle, 1);
    }
    // saiu da beirada: continua rolando no ar (cai com a gravidade)
    if (!_chao) velv += grav * _dt;
    else if (velv > 0) velv = 0;
    exit;
}
// esquiva apertada um pouco antes (fim de um golpe, no ar, na recarga): guarda o comando
if (_esquiva) { rolar_buffer = ROLAR_BUFFER; rolar_buffer_dir = global.esquiva_stick; }
else if (rolar_buffer > 0) rolar_buffer -= _dt;
var _pode_rolar = _chao and _pode_agir and rolar_recarga <= 0 and (is_undefined(golpe) or (!golpe.armadura and golpe_i >= golpe.cancel));
if (rolar_buffer > 0 and _pode_rolar)
{
    rolar_buffer = 0;
    golpe_cancelar();
    cadeia = "";
    buffer_golpe = "";
    rolando = true;
    rolar_t = 0;
    esquivou = false;
    rolar_dir = (rolar_buffer_dir != 0) ? rolar_buffer_dir : ((_dir_agora != 0) ? _dir_agora : facing);
    facing = rolar_dir;
    bloqueando = false;
    agachado = false;
    sprite_index = spr_player_agaichar;
    image_speed = 0;
    som("sfx_esquiva", 0.9);
    fx_criar("poeira", x - rolar_dir * 10, y, 0.5);
    exit;
}

// ----- APARAR: apertar a defesa na hora certa (janela curta) -----
if (_aparar and _chao and _pode_agir and aparar_recarga <= 0 and is_undefined(golpe))
{
    janela_aparar = APARAR_JANELA;
    aparar_recarga = APARAR_RECARGA;
}

// =====================================================================
// GOLPES: botão apertado vira golpe (ou espera no buffer do combo)
// =====================================================================
if (_botao != "") { buffer_golpe = _botao; buffer_golpe_t = 18; }

var _livre_para_golpe = is_undefined(golpe) or (!golpe.armadura and !especial and golpe_i >= golpe.cancel);

// ----- FINALIZADOR: BOLA perto de um inimigo atordoado (ícone sobre ele) -----
if (buffer_golpe == "C" and _chao and _pode_agir and _livre_para_golpe)
{
    var _fin = alvo_finalizavel();
    if (_fin != noone)
    {
        facing = sign(_fin.x - x);
        if (facing == 0) facing = 1;
        golpe_cancelar();
        alvo_final = _fin;
        with (_fin) { executando = true; finalizavel = false; velh = 0; empurrao = 0; }
        golpe_iniciar("finalizador");
        cadeia = "";
        buffer_golpe = "";
        _livre_para_golpe = false;
    }
}

// ----- FÚRIA: barra cheia + botão de fúria -----
if (_furia_btn and furia >= 100 and _chao and _pode_agir and _livre_para_golpe)
{
    golpe_cancelar();
    golpe_iniciar("ira");
    cadeia = "";
    buffer_golpe = "";
    _livre_para_golpe = false;
}
else if (_furia_btn and furia < 100 and _livre) { bloqueado_txt = "A FÚRIA AINDA NÃO ESTÁ CHEIA"; bloqueado_aviso = 70; som("sfx_negado", 0.6, 0); }

// ----- ESPECIAIS (no chão; gastam parte da barra; liberados ao evoluir a espada) -----
if (_esp != -1 and _pode_agir and (is_undefined(golpe) or (!especial and !golpe.armadura and golpe_i >= golpe.cancel)))
{
    if (!especial_liberado(_esp))
    {
        bloqueado_txt = especial_nome(_esp) + ": EVOLUA A ESPADA ATÉ O NÍVEL " + string(especial_nivel_req(_esp)) + "  (" + botao_menu_armas() + ")";
        bloqueado_aviso = 110;
        som("sfx_negado", 0.6, 0);
    }
    else if (especial_carga < especial_custo(_esp) * ESPECIAL_SEGUNDOS)
    {
        bloqueado_txt = "MAGIA INSUFICIENTE";
        bloqueado_aviso = 60;
        som("sfx_negado", 0.5, 0);
    }
    else if (_chao)
    {
        var _ch = "tremor";
        if (_esp == ACAO.ESPECIAL) _ch = _abaixar ? "onda_agachado" : "onda";
        if (_esp == ACAO.ESPECIAL_2) _ch = "queda";
        if (_right != _left) facing = _right ? 1 : -1;
        golpe_cancelar();
        golpe_iniciar(_ch);
        cadeia = "";
        buffer_golpe = "";
    }
}

// ----- ATAQUES: QUADRADO / TRIÂNGULO / BOLA e os combos -----
var _pode_golpear = _pode_agir and !bloqueando;
if (buffer_golpe != "" and _pode_golpear)
{
    var _livre_golpe = is_undefined(golpe);
    // durante um golpe: o próximo do combo entra a partir do quadro "cancel"
    if (!_livre_golpe and !especial and !golpe.armadura and golpe_i >= golpe.cancel) _livre_golpe = true;
    if (_livre_golpe)
    {
        var _cad = (cadeia_janela > 0 or !is_undefined(golpe)) ? cadeia : "";
        var _prox = combo_proximo(_cad, buffer_golpe, !_chao, _abaixar and _chao);
        if (_prox != "")
        {
            if (_right != _left) facing = _right ? 1 : -1;
            golpe_cancelar();
            golpe_iniciar(_prox);
            // a cadeia do combo: finalizadores e golpes no ar encerram a sequência
            var _letra = (_prox == "rasteira" and buffer_golpe == "Q") ? "C" : buffer_golpe;
            cadeia = (golpe.combo > 0 or !_chao) ? "" : string_copy(_cad + _letra, max(1, string_length(_cad + _letra) - 1), 2);
            buffer_golpe = "";
        }
    }
}

// =====================================================================
// GOLPE EM ANDAMENTO: a animação segue a tabela de quadros
// =====================================================================
if (!is_undefined(golpe))
{
    var _g = golpe;
    var _e = _g.seq[golpe_i];
    // golpes no chão param Twilight; os saltos mantêm o impulso no ar
    if (!_g.no_ar or _chao) velh = 0;

    // avanço do golpe (para frente), parando em paredes pelo End Step
    var _av = _e[$ "av"];
    if (!is_undefined(_av)) velh = facing * _av;

    // finalizador: o inimigo fica preso na frente de Twilight
    if (_g.chave == "finalizador" and instance_exists(alvo_final))
    {
        with (alvo_final) { if (!morrendo) { x = lerp(x, other.x + other.facing * 34, 0.25); velh = 0; } }
    }

    golpe_t += _dt;
    var _seguro = 0;
    while (!is_undefined(golpe) and _seguro < 8)
    {
        _seguro += 1;
        _e = golpe.seq[golpe_i];
        if (golpe_t < _e.d) break;
        // condição para sair do quadro (salto: espera o ápice / o chão)
        var _cond = _e[$ "esp"];
        var _ok = true;
        if (!is_undefined(_cond))
        {
            var _no_chao = place_meeting(x, y + 1, obj_chao) and velv >= 0;
            if (_cond == "apice")    _ok = (velv >= 0);
            if (_cond == "descendo") _ok = (velv >= 0) or _no_chao;
            if (_cond == "chao")     _ok = _no_chao;
        }
        if (!_ok) { golpe_t = _e.d; break; }
        golpe_t -= _e.d;
        golpe_i += 1;
        if (golpe_i >= array_length(golpe.seq))
        {
            // fim da animação = fim do golpe (tempo exato)
            golpe_cancelar();
            cadeia_janela = 16;
            trocar_animacao(_chao ? spr_player_idle : spr_player_fall, 1);
            break;
        }
        golpe_entrar_quadro();
    }
    if (!is_undefined(golpe)) golpe_acertar();
}

// ----- ONDAS (especial Onda Carmesim e Ira de Vallack) -----
for (var _o = array_length(ondas) - 1; _o >= 0; _o--)
{
    var _on = ondas[_o];
    var _ira = variable_struct_exists(_on, "ira");
    _on.dist = min(_on.dist_max, _on.dist + (_ira ? 12 : 8) * _dt);
    _on.vida -= _dt;
    var _ox1 = _on.x0 + _on.dir * (_on.dist - 20);
    var _ox2 = _on.x0 + _on.dir * (_on.dist + 10);
    var _lst = ds_list_create();
    var _qt = collision_rectangle_list(min(_ox1, _ox2), y + _on.y_topo, max(_ox1, _ox2), y + _on.y_base, obj_inimigo_base, false, true, _lst, false);
    var _gw = _ira ? { chave: "ira", especial: false, pesado: true, porcento: 0, dano: 0, combo: 0 } : { chave: "onda", especial: true, pesado: false, porcento: 0.30, dano: 0, combo: 0 };
    for (var _q = 0; _q < _qt; _q++)
    {
        var _alvo = _lst[| _q];
        if (array_tem(_on.atingidos, _alvo) or array_tem(atingidos, _alvo) or _alvo.morrendo or !_alvo.ativo) continue;
        array_push(_on.atingidos, _alvo);
        array_push(atingidos, _alvo);
        var _de = dano_golpe(_gw, _alvo, 1);
        with (_alvo)
        {
            levar_dano(_de, other.x, false, 9, other.id, _gw);
            if (!morrendo and !eh_boss) inimigo_atordoar(60);
        }
        impacto(3);
        fx_criar("faiscas_golpe", _alvo.x, (_alvo.bbox_top + _alvo.bbox_bottom) / 2, 1);
    }
    ds_list_clear(_lst);
    var _nd = collision_rectangle_list(min(_ox1, _ox2), y + _on.y_topo, max(_ox1, _ox2), y + _on.y_base, obj_destrutivel, false, true, _lst, false);
    for (var _qd = 0; _qd < _nd; _qd++)
    {
        var _d = _lst[| _qd];
        if (array_tem(_on.atingidos, _d)) continue;
        array_push(_on.atingidos, _d);
        with (_d) destrutivel_bater(2, other.x);
    }
    ds_list_destroy(_lst);
    if (_on.vida <= 0) array_delete(ondas, _o, 1);
}

// =====================================================================
// DEFESA E AGACHAR (sem golpe em andamento)
// =====================================================================
var _em_golpe = !is_undefined(golpe);
bloqueando = (_bloqueio or janela_aparar > 0) and _chao and !_em_golpe and _pode_agir;
if (bloqueando)
{
    velh = 0;
    trocar_animacao(sprite_defesa, 1);       // escudo mágico animado
}
agachado = _abaixar and _chao and !_em_golpe and _pode_agir and !bloqueando;

// =====================================================================
// MOVIMENTO
// =====================================================================
if (_chao) coyote = 6; else coyote = max(0, coyote - _dt);
if (_jump) buffer_pulo = 8;
if (!_chao) no_ar_tempo += _dt;
else
{
    if (no_ar_tempo > 14) { pouso = 7; som("sfx_pouso", 0.45); }
    no_ar_tempo = 0;
}

if (!_em_golpe and !machucado and !bloqueando)
{
    var _mov = _right - _left;
    var _v = vel_correr;                       // sempre correndo
    if (agachado) _v = vel_agachado;
    if (enredado > 0) _v *= 0.35;              // preso na teia: arrasta os pés
    velh = _mov * _v;
    if (_mov != 0) { facing = _mov; pouso = 0; }

    if (buffer_pulo > 0 and coyote > 0 and !_abaixar)
    {
        velv = -vel_jump;
        buffer_pulo = 0;
        coyote = 0;
        _chao = false;
        pouso = 0;
        sprite_index = spr_player_jump;
        image_index = 1;
        som("sfx_pulo", 0.5);
    }

    if (_chao)
    {
        if (agachado) trocar_animacao(spr_player_agaichar, 0);
        else if (velh != 0)
        {
            // a corrida avança a animação pela distância percorrida:
            // os pés acompanham o chão (sem "patinar")
            if (sprite_index != spr_player_run) { sprite_index = spr_player_run; anim_passo = 0; }
            image_speed = 0;
            anim_passo += abs(velh) * _dt;
            var _ciclo = 92;                          // px corridos por ciclo completo (2 passadas)
            image_index = (anim_passo mod _ciclo) / _ciclo * sprite_get_number(sprite_index);
        }
        else if (pouso > 0)
        {
            sprite_index = spr_player_fall;
            image_index = 3;
            image_speed = 0;
        }
        else trocar_animacao(spr_player_idle, 1);
    }
    else
    {
        if (velv < 0)
        {
            if (sprite_index != spr_player_jump) { sprite_index = spr_player_jump; image_index = 1; }
            image_speed = 1.4;
            if (image_index >= 4.9) image_index = 4;      // segura a pose do alto do pulo
        }
        else
        {
            if (sprite_index != spr_player_fall) { sprite_index = spr_player_fall; image_index = 0; }
            image_speed = 1;
            if (image_index >= 2.9) image_index = 0;      // queda em loop (quadros 0-2)
        }
    }
}

// ----- EMPURRÃO E GRAVIDADE -----
velh += empurrao;
empurrao = lerp_dt(empurrao, 0, 0.12);
if (abs(empurrao) < 0.2) empurrao = 0;

if (!_chao) velv += grav * _dt;
else if (velv > 0) velv = 0;
