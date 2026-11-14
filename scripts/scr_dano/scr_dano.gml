// =====================================================================
//  scr_dano: dano, defesa mágica, aparar, esquiva, escudo e atordoamento
// =====================================================================

// Executado DENTRO da instância que recebe o golpe (use com "with").
//  _dano       quantidade de vida perdida
//  _origem_x   x de quem bateu (define o lado do empurrão e da defesa)
//  _bloqueavel false = golpe QUEBRA-GUARDA / especial / armadilha
//  _forca      força do empurrão
//  _atacante   instância que bateu corpo a corpo (pode ser aparada / ricocheteia na defesa)
//  _golpe      golpe do jogador (struct de scr_combate) que causou o dano
function levar_dano(_dano, _origem_x = undefined, _bloqueavel = true, _forca = 4, _atacante = noone, _golpe = undefined)
{
    if (vida <= 0) return;
    if (is_undefined(_origem_x)) _origem_x = x;

    var _dir = sign(x - _origem_x);
    if (_dir == 0) _dir = 1;
    var _cy = (bbox_top + bbox_bottom) / 2;

    // =================================================================
    // JOGADOR
    // =================================================================
    if (object_index == obj_player)
    {
        if (morto or global.transicao_fase or instance_exists(obj_final) or instance_exists(obj_resultado)) return;

        // ----- ESQUIVA: no meio da rolagem nada acerta Twilight -----
        if (jogador_intangivel())
        {
            if (!esquivou)
            {
                esquivou = true;
                esquiva_fx = 18;
                camera_lenta(16, 0.55);
            }
            return;
        }
        if (tempo_invencivel > 0) return;

        var _de_frente = (_origem_x == x) or (sign(_origem_x - x) == facing);

        // ----- APARAR (parry): defesa apertada na hora certa -----
        if (janela_aparar > 0 and _de_frente and _atacante != noone and instance_exists(_atacante))
        {
            jogador_aparou(_atacante);
            return;
        }

        // ----- DEFESA MÁGICA -----
        if (bloqueando and _bloqueavel and _de_frente)
        {
            jogador_bloqueou(_origem_x);
            // quem bateu no escudo é arremessado para trás por alguns quadros
            if (_atacante != noone and instance_exists(_atacante))
            {
                with (_atacante) inimigo_ricochete(sign(x - other.x));
            }
            return;
        }

        // v1.12: MODO FÚRIA = super armadura (metade do dano e nada interrompe Twilight)
        if (furia_modo) _dano = max(1, round(_dano * 0.5));
        vida = max(0, vida - _dano);
        global.dano_na_luta += _dano;    // v1.17: conquista INTOCÁVEL (zera quando o Carrasco acorda)
        tempo_invencivel = 60;           // v1.4: 1 s sem levar outro golpe (menos dano em sequência)
        tempo_sem_dano = 0;
        global.combo = 0;
        global.combo_tempo = 0;
        global.last_hit_flash = 12;
        global.last_hit_damage = _dano;
        global.camera_impact = 8;
        impacto(6);
        camera_empurrar((_dir == 0) ? -facing : _dir, 5, 0.2);   // a pancada empurra a tela junto
        som("sfx_dano", 0.9);
        furia_ganhar(2);                  // apanhar também enche um pouco a fúria

        var _sangue = instance_create_depth(x, _cy, -100, obj_fagulha);
        _sangue.cor = make_color_rgb(255, 60, 50);

        // durante especiais, fúria e finalizador Twilight não é interrompido (só perde a vida)
        if ((armadura or furia_modo) and vida > 0)
        {
            tempo_invencivel = 30;
            return;
        }

        // qualquer ação em andamento é interrompida
        empurrao = _dir * _forca;
        golpe_cancelar();
        cadeia = "";
        buffer_golpe = "";
        bloqueando = false;
        rolando = false;
        recuando = false;
        contra_t = 0;

        if (vida <= 0)
        {
            morto = true;
            machucado = false;
            tempo_invencivel = 0;
            cura_restante = 0;
            sprite_index = spr_player_morte;
            image_index = 0;
            image_speed = 1;
            camera_lenta(50, 0.4);
        }
        else
        {
            machucado = true;
            sprite_index = spr_player_dano;
            image_index = 0;
            image_speed = 1;
        }
        return;
    }

    // =================================================================
    // INIMIGOS (filhos de obj_inimigo_base): parte comum
    // =================================================================
    if (morrendo or !ativo) return;
    if (em_qte) return;              // v1.17: na sequência de golpes quem tira a vida é a sequência
    if (tempo_invencivel > 0) return;
    // durante o finalizador só o golpe final acerta este inimigo
    if (executando and (is_undefined(_golpe) or _golpe.chave != "finalizador")) return;

    // ----- ESCUDO (inimigo 03): segura golpes de frente até a guarda quebrar -----
    if (escudo_vida > 0 and !is_undefined(_golpe))
    {
        var _frente = (sign(_origem_x - x) == dir) or (_origem_x == x);
        var _quebra_tudo = _golpe.especial or _golpe.chave == "ira" or _golpe.chave == "finalizador";
        if (_quebra_tudo) escudo_quebrar(_dir);
        else if (_frente and atordoado <= 0)
        {
            escudo_bater(_golpe.pesado ? 2 : 1, _dir);
            return;
        }
    }

    // ----- DEFESA PRÓPRIA (v1.8: a estátua enfeitiçada em forma de pedra) -----
    if (bloquear_golpe(_golpe, _origem_x)) return;

    if (barra_tempo <= 0) vida_atraso = vida;
    vida = max(0, vida - _dano);
    tempo_invencivel = 6;
    barra_tempo = 180;
    flash_dano = eh_boss ? 4 : 8;

    global.combo += 1;
    global.combo_tempo = 120;
    perfil_maximo("maior_combo", global.combo);     // v1.17: conquista TEMPESTADE DE AÇO (20)
    global.hits_total += 1;
    global.last_hit_flash = 5;
    global.last_hit_damage = _dano;
    global.camera_impact = max(global.camera_impact, 4);

    var _faisca = instance_create_depth(x, _cy, -100, obj_fagulha);
    _faisca.cor = c_white;

    // reação própria de cada inimigo (atordoar, animação de dano, morrer...)
    ultimo_golpe = _golpe;
    reagir_dano(_dano, _dir, _forca);
}

// Twilight caiu num abismo: morte na hora (nem a rolagem nem a fúria salvam)
function jogador_cair_abismo()
{
    if (morto) return;
    rolando = false;
    recuando = false;
    tempo_invencivel = 0;
    levar_dano(vida + 9999, x, false, 0);
    som("sfx_derrota", 0.7, 0);
}

// A rolagem está no trecho em que nada acerta Twilight?
function jogador_intangivel()
{
    return (rolando and rolar_t >= ROLAR_INVENC_INI and rolar_t <= ROLAR_INVENC_FIM)
        or (recuando and recuar_t <= RECUAR_INVENC);          // v1.12: backdash
}

// O jogador segurou um golpe/projétil na defesa mágica
function jogador_bloqueou(_origem_x)
{
    with (obj_player)
    {
        var _d = sign(x - _origem_x);
        if (_d == 0) _d = -facing;
        empurrao = _d * 1.8;
        tempo_invencivel = 12;
        defesa_fx = 16;
        global.camera_impact = max(global.camera_impact, 5);
        var _cy = (bbox_top + bbox_bottom) / 2;
        var _faisca = instance_create_depth(x + facing * 22, _cy, -100, obj_fagulha);
        _faisca.cor = make_color_rgb(140, 200, 255);
        som("sfx_bloqueio", 0.8);
    }
}

// APARAR: o golpe é rebatido e quem bateu fica atordoado (pronto para o finalizador)
function jogador_aparou(_atacante)
{
    with (obj_player)
    {
        janela_aparar = 0;
        aparar_recarga = 0;
        machucado = false;               // v1.12: (segurança) aparar nunca deixa Twilight preso na animação de dano
        aparar_fx = 24;
        defesa_fx = 16;
        tempo_invencivel = max(tempo_invencivel, 24);
        bloqueando = false;
        impacto(9);
        camera_lenta(34, 0.35);
        global.camera_impact = max(global.camera_impact, 10);
        global.last_hit_flash = 8;
        som("sfx_aparar", 1);
        perfil_somar("aparos");          // v1.17: conquista LÂMINA DE ESPELHO
        var _cy = (bbox_top + bbox_bottom) / 2;
        fx_criar("aparar", x + facing * 20, _cy - 6, 1);
        furia_ganhar(6);
        trocar_animacao(spr_player_defendendo, 1);
        image_index = 2;
        // v1.12: CONTRA-ATAQUE: 8 quadros depois do aparar, Twilight revida sozinho
        if (instance_exists(_atacante) and object_is_ancestor(_atacante.object_index, obj_inimigo_base) and abs(_atacante.x - x) < 140)
        {
            contra_t = 8;
            contra_alvo = _atacante;
        }
    }
    if (instance_exists(_atacante))
    {
        with (_atacante) inimigo_aparado(sign(x - obj_player.x));
    }
}

// ---------------------------------------------------------------------
// ATORDOAMENTO (executado no inimigo)
// ---------------------------------------------------------------------
// Deixa o inimigo atordoado por _quadros (no mínimo).
function inimigo_atordoar(_quadros, _forcar = false)
{
    if (morrendo or !ativo or eh_boss) return;
    if (resiste_atordoar and !_forcar) return;          // mini-boss: só aparar / exaustão
    if (imune_atordoar > 0 and !_forcar) return;        // acabou de se libertar: não pode ser travado de novo
    _quadros = round(_quadros * dif_atordoamento());
    if (elite and !_forcar) _quadros = round(_quadros * 0.6);   // v1.12: elites se recuperam mais rápido
    if (atordoado <= 0) atordoado_anim = 0;
    atordoado = max(atordoado, _quadros);
    // cancela ataque, mira ou preparação de pulo em andamento
    if (estado_ia == "atacar" or estado_ia == "atirar" or estado_ia == "pular_preparo" or estado_ia == "pular_pouso" or estado_ia == "investida")
    {
        estado_ia = "perseguir";
        golpe_dado = false;
    }
}

// Regra pedida no projeto:
//   SE o jogador está atacando ENTÃO os inimigos atingíveis ficam atordoados
//   SENÃO os inimigos atacam.
// A zona é só à FRENTE do jogador e dentro do alcance da lâmina.
function inimigo_regra_atordoamento(_p)
{
    if (_p == noone or !instance_exists(_p)) return;
    if (_p.morto or !(_p.atacando or _p.especial)) return;
    if (escudo_vida > 0) return;                        // o escudo segura (é preciso quebrar a guarda)
    var _frente = (x - _p.x) * _p.facing;          // > 0: o inimigo está à frente
    if (_frente >= -16 and _frente <= 72 and abs(y - _p.y) <= 70) inimigo_atordoar(10);
}

// Controle do atordoamento a cada quadro. Retorna true enquanto atordoado.
// Limite: após 2,5 s seguidos atordoado, o inimigo se liberta e fica 1,3 s
// imune (nunca mais fica "travado" na animação). Aparado não conta.
function inimigo_atordoamento_step(_dt)
{
    if (imune_atordoar > 0) imune_atordoar -= _dt;
    if (aparado_t > 0) aparado_t = max(0, aparado_t - _dt);
    if (atordoado <= 0)
    {
        atordoado_acumulado = max(0, atordoado_acumulado - _dt * 2);
        return false;
    }
    atordoado -= _dt;
    atordoado_anim += _dt;
    // v1.17: o Carrasco de joelhos (exausto) espera a sequência de golpes o tempo todo
    if (aparado_t <= 0 and estado_ia != "exausto") atordoado_acumulado += _dt;
    if (atordoado_acumulado >= 150)
    {
        atordoado = 0;
        atordoado_acumulado = 0;
        imune_atordoar = 80;
        libertou_fx = 20;
        recarga = 0;                     // contra-ataca na hora
    }
    if (atordoado <= 0) { atordoado = 0; return false; }
    return true;
}

// Golpe batendo na defesa mágica: o inimigo é arremessado e fica tonto
function inimigo_ricochete(_dir)
{
    if (morrendo or !ativo or eh_boss) return;
    if (_dir == 0) _dir = -dir;
    empurrao = _dir * (resiste_atordoar ? 2.2 : 3.6);        // v1.12: era 3 / 6.5 (ficava longe do combo)
    velv = min(velv, -2.2);
    imune_atordoar = 0;
    inimigo_atordoar(24);
    flash_dano = 6;
}

// O golpe foi APARADO: atordoado por 2 s e pronto para o finalizador
function inimigo_aparado(_dir)
{
    if (morrendo or !ativo) return;
    if (eh_boss)
    {
        // o guardião não cai, mas recua e perde a investida
        tremor = 4;
        flash_dano = 8;
        recarga = max(recarga, 60);
        return;
    }
    if (_dir == 0) _dir = -dir;
    empurrao = _dir * 1.8;           // v1.12: era 3.2 (fica perto para o contra-ataque)
    imune_atordoar = 0;
    atordoado_acumulado = 0;
    aparado_t = resiste_atordoar ? 70 : 120;
    inimigo_atordoar(aparado_t, true);
    flash_dano = 8;
    golpe_dado = true;
}

// Inimigo que pode levar o finalizador (ícone sobre a cabeça)
// Chamado a cada quadro pelos inimigos. Retorna true enquanto está preso
// no finalizador (a IA não roda).
function inimigo_finalizador_step()
{
    // v1.17: SEQUÊNCIA DE GOLPES: o chefe fica preso nela e os outros inimigos esperam
    if (em_qte or (global.qte_alvo != noone and global.qte_alvo != id and instance_exists(global.qte_alvo)))
    {
        finalizavel = false;
        velh = 0;
        empurrao = 0;
        return true;
    }
    if (executando)
    {
        finalizavel = false;
        velh = 0;
        empurrao = 0;
        if (!instance_exists(obj_player) or is_undefined(obj_player.golpe) or obj_player.golpe.chave != "finalizador") executando = false;
        return executando;
    }
    var _fraco = (vida <= vida_max * (resiste_atordoar ? 0.25 : 0.34));
    // v1.12: ELITES e inimigos de muita vida, quase mortos, podem ser EXECUTADOS
    // mesmo sem estar atordoados (contorno vermelho piscando + ícone)
    var _executavel = !resiste_atordoar and (elite or object_index == obj_porco or object_index == obj_inimigo_03 or object_index == obj_estatua)
        and vida <= vida_max * 0.25;
    finalizavel = ativo and !morrendo and !eh_boss and ((atordoado > 0 and (aparado_t > 0 or escudo_quebrado_t > 0 or _fraco)) or _executavel);
    if (escudo_quebrado_t > 0) escudo_quebrado_t = max(0, escudo_quebrado_t - global.dt);
    return false;
}

// Dano do finalizador: derrota os comuns; no mini-boss tira 25% da vida máxima
function inimigo_dano_finalizador()
{
    if (resiste_atordoar) return max(1, round(vida_max * 0.25));
    return vida;
}

// ---------------------------------------------------------------------
// ESCUDO (inimigo 03)
// ---------------------------------------------------------------------
function escudo_bater(_forca, _dir)
{
    escudo_vida = max(0, escudo_vida - _forca);
    escudo_fx = 10;
    som("sfx_bloqueio", 0.9);
    impacto(2);
    var _f = instance_create_depth(x + dir * 20, y - 40, -100, obj_fagulha);
    _f.cor = make_color_rgb(255, 220, 140);
    // quem bate no escudo é empurrado um pouco
    with (obj_player) { empurrao = -facing * 1.6; }
    empurrao = _dir * 0.8;
    recarga = min(recarga, 14);          // contra-ataca logo depois de segurar
    if (random(1) < 0.2) fala_aleatoria(id, falas_escudo(), make_color_rgb(70, 60, 30), 1);
    if (escudo_vida <= 0) escudo_quebrar(_dir);
}

function escudo_quebrar(_dir)
{
    if (escudo_vida <= 0 and escudo_quebrado) return;
    escudo_vida = 0;
    escudo_quebrado = true;
    escudo_quebrado_t = 150;
    som("sfx_escudo_quebra", 1);
    impacto(6);
    global.camera_impact = max(global.camera_impact, 8);
    imune_atordoar = 0;
    atordoado_acumulado = 0;
    inimigo_atordoar(110, true);
    empurrao = _dir * 1.6;
    repeat (6)
    {
        var _f = instance_create_depth(x + dir * 18, y - 40, -100, obj_fagulha);
        _f.cor = choose(make_color_rgb(190, 190, 200), make_color_rgb(255, 220, 140));
    }
    var _pd = instance_create_depth(x + dir * 18, y - 38, depth - 1, obj_fx);
    _pd.tipo = "escudo_quebrado";
    _pd.tam = 1;
    _pd.dir = dir;
    with (_pd) fx_iniciar();
}

// ---------------------------------------------------------------------
// MORTE (executado no inimigo): o corpo fica no mapa e solta orbs
// ---------------------------------------------------------------------
function inimigo_morrer(_dir, _soltar_orbs = true)
{
    if (!morrendo)
    {
        global.inimigos_derrotados += 1;
        // v1.17: números do PERFIL (conquistas)
        perfil_somar("inimigos");
        if (object_index == obj_porco) perfil_somar("javalis");
        if (_soltar_orbs)
        {
            var _total = invocado ? 3 : orbs_do_inimigo(id);
            if (finalizado) _total *= ORBS_FINALIZADOR;
            orbs_soltar(x, y - 30, _total);
            // v1.12: cristais de essência (sub-armas)
            var _ess = essencia_do_inimigo(id);
            if (_ess > 0) essencia_soltar(x, y - 34, _ess);
        }
        // v1.12: o sangue do monstro voa para a lâmina e enche a FÚRIA
        var _sg = sangue_do_inimigo(id);
        if (_sg > 0) sangue_soltar(x, y - 30, _sg);
        // GOLPE FATAL: pausa, câmera lenta e o monstro explode em chamas
        var _alt = max(20, bbox_bottom - bbox_top);
        golpe_fatal(x, (bbox_top + bbox_bottom) / 2, (_dir == 0) ? 1 : sign(_dir), clamp(_alt / 64, 0.8, 2.4));
        camera_soco((inimigos_vivos() > 1) ? 0.07 : 0.12);     // v1.20: o último do grupo fecha mais a câmera
    }
    morrendo = true;
    pulando = false;
    atordoado = 0;
    finalizavel = false;
    executando = false;
    estado_ia = "morrendo";
    velh = _dir * 1.6;          // escorrega um pouco com o golpe final
    velv = min(velv, 0);
    empurrao = 0;
    morte_fim = false;
    morte_tempo = 0;
    morte_t = 0;
    evaporar = 0;
    sprite_index = spr_morrer;
    image_index = 0;
    image_speed = 1;
    global.camera_impact = max(global.camera_impact, 7);
    repeat (global.cfg_qualidade == 0 ? 2 : 5)
    {
        var _f = instance_create_depth(x + random_range(-14, 14), y - random_range(14, 50), -100, obj_fagulha);
        _f.cor = make_color_rgb(200, 30, 30);
    }
}

// Corpo no chão (Step dos inimigos que morreram): para de deslizar e,
// 3 s depois da morte, EVAPORA numa fumaça negra amaldiçoada e some do mapa.
function inimigo_corpo_step(_dt)
{
    velh = lerp_dt(velh, 0, 0.12);
    if (!place_meeting(x, y + 1, obj_chao)) velv += grav_ia * _dt;
    else if (velv > 0) velv = 0;
    if (morte_fim) morte_tempo += _dt;
    if (inimigo_evaporar(_dt, EVAPORAR_INI, EVAPORAR_FIM)) instance_destroy();
}

// ---------------------------------------------------------------------
// MALDIÇÃO: o corpo escurece até virar uma silhueta negra, solta fumaça
// preta com brasas roxas e se desfaz subindo nela (v1.10)
// ---------------------------------------------------------------------
#macro EVAPORAR_INI 70       // quadros depois da morte em que a fumaça começa a consumir o corpo
#macro EVAPORAR_FIM 180      // 3 s depois da morte o corpo some do mapa

// Avança a evaporação e solta a fumaça. Retorna true quando o corpo sumiu.
function inimigo_evaporar(_dt, _ini, _fim)
{
    morte_t += _dt;
    var _e = clamp((morte_t - _ini) / max(1, _fim - _ini), 0, 1);
    var _comecou = (evaporar <= 0 and _e > 0);
    evaporar = _e;
    if (_e <= 0) return false;
    var _tam = (evaporar_tam > 0) ? evaporar_tam : clamp((bbox_bottom - bbox_top) / 62, 0.7, 2.5);
    var _alt = 62 * _tam;
    var _larg = 34 * _tam;
    if (_comecou) som_em((_tam >= 1.8) ? "maldicao_grande" : "maldicao_evaporar", x, y, 0.9);
    evaporar_fx -= _dt;
    if (evaporar_fx <= 0)
    {
        // fumaça discreta: poucos sopros (antes 5 / 8 quadros e até 140 na tela poluíam o cenário)
        evaporar_fx = (global.cfg_qualidade == 0) ? 20 : 13;
        // muita fumaça na tela (uma onda inteira morrendo junto): solta menos
        // v1.17: o corpo ARDE em chamas (antes: fumaça negra, uma mancha escura na tela)
        var _n = 0;
        with (obj_fx) if (tipo == "chamas_corpo") _n += 1;
        if (_n < 36 or random(1) < 0.15)
            fx_em("chamas_corpo", x + random_range(-_larg, _larg) * 0.5, y - random(_alt * (1 - 0.35 * _e)), _tam * (0.7 + 0.5 * _e));
    }
    if (morte_t >= _fim)
    {
        // último lampejo: o que sobrou do corpo vira brasa e some
        fx_em("chamas_estouro", x, y - _alt * 0.45, _tam);
        return true;
    }
    return false;
}

// Desenha o corpo; morto, ele escurece até virar uma silhueta negra com brilho
// roxo nas bordas, treme e se desfaz subindo na fumaça.
function inimigo_corpo_desenhar(_spr, _img, _x, _y, _xs, _ys, _rot, _cor, _alpha)
{
    if (!morrendo or evaporar <= 0)
    {
        // v1.12: ELITE: brilho vermelho em volta do corpo
        if (elite and !morrendo)
        {
            gpu_set_blendmode(bm_add);
            gpu_set_fog(true, make_color_rgb(200, 30, 20), 0, 0);
            var _ea = _alpha * (0.22 + 0.08 * sin(current_time / 160));
            draw_sprite_hd(_spr, _img, _x - 2, _y, _xs, _ys, _rot, c_white, _ea);
            draw_sprite_hd(_spr, _img, _x + 2, _y, _xs, _ys, _rot, c_white, _ea);
            gpu_set_fog(false, c_white, 0, 0);
            gpu_set_blendmode(bm_normal);
        }
        // v1.12: pode ser executado: contorno vermelho piscando
        if (finalizavel and !morrendo)
        {
            var _pa = _alpha * (0.55 + 0.45 * sin(current_time / 70));
            gpu_set_fog(true, make_color_rgb(255, 40, 30), 0, 0);
            draw_sprite_hd(_spr, _img, _x - 3, _y, _xs, _ys, _rot, c_white, _pa);
            draw_sprite_hd(_spr, _img, _x + 3, _y, _xs, _ys, _rot, c_white, _pa);
            draw_sprite_hd(_spr, _img, _x, _y - 3, _xs, _ys, _rot, c_white, _pa);
            draw_sprite_hd(_spr, _img, _x, _y + 2, _xs, _ys, _rot, c_white, _pa);
            gpu_set_fog(false, c_white, 0, 0);
        }
        draw_sprite_hd(_spr, _img, _x, _y, _xs, _ys, _rot, _cor, _alpha);
        // v1.12: PETRIFICAÇÃO (Modo Fúria): o corpo vai virando pedra cinza
        if (petrif > 0 and !morrendo)
        {
            gpu_set_fog(true, make_color_rgb(130, 128, 120), 0, 0);
            draw_sprite_hd(_spr, _img, _x, _y, _xs, _ys, _rot, c_white, _alpha * (petrificado ? 0.85 : 0.22 * petrif));
            gpu_set_fog(false, c_white, 0, 0);
        }
        return;
    }
    var _e = evaporar;
    var _sai = clamp((_e - 0.4) / 0.6, 0, 1);          // depois de escurecer, se desfaz
    var _a = _alpha * (1 - _sai * (2 - _sai));
    if (_a <= 0.01) return;
    var _k = max(1, evaporar_tam);
    var _tr = random_range(-1.2, 1.2) * _e * _k;
    var _xx = _x + _tr;
    var _yy = _y - 14 * _k * _sai;
    var _sx = _xs * (1 - 0.3 * _sai);
    var _sy = _ys * (1 + 0.22 * _sai);
    // v1.17: o corpo ARDE em brasa (antes virava uma silhueta negra: a "mancha
    // preta" na tela). Escurece só um pouco (carbonizando) e brilha em laranja.
    draw_sprite_hd(_spr, _img, _xx, _yy, _sx, _sy, _rot, merge_color(_cor, make_color_rgb(120, 46, 30), min(1, _e * 1.6)), _a);
    var _g = _a * (0.3 + 0.5 * sin(pi * min(1, _e * 1.2)));
    if (_g > 0.02)
    {
        gpu_set_blendmode(bm_add);
        gpu_set_fog(true, merge_color(make_color_rgb(255, 70, 20), make_color_rgb(255, 170, 60), _e), 0, 0);
        draw_sprite_hd(_spr, _img, _xx, _yy, _sx, _sy, _rot, c_white, _g * 0.75);
        draw_sprite_hd(_spr, _img, _xx, _yy - 2 * _k, _sx, _sy, _rot, c_white, _g * 0.35);
        gpu_set_fog(false, c_white, 0, 0);
        gpu_set_blendmode(bm_normal);
    }
}

// Sombra no chão some junto com o corpo
function inimigo_sombra_alpha()
{
    return morrendo ? (1 - evaporar) : 1;
}

// Quantos inimigos ainda estão vivos (corpos não contam)
function inimigos_vivos()
{
    var _n = 0;
    with (obj_inimigo_base) if (!morrendo) _n += 1;
    return _n;
}

// ---------------------------------------------------------------------
// FALAS DOS INIMIGOS (balão sobre a cabeça)
// ---------------------------------------------------------------------
// Fala de um inimigo; _chance = probabilidade; respeita uma espera global
// para não falarem todos ao mesmo tempo.
// v1.12: os balões de fala saíram das lutas (pedido dos testes: a atenção fica
// na jogabilidade). Os chefes falam nas caixas de diálogo (scr_v112).
// Para trazer os balões de volta, troque FALAS_LIGADAS para true.
#macro FALAS_LIGADAS false
function fala_dizer(_inst, _texto, _cor = c_white, _forcar = false, _dur = 110)
{
    if (!FALAS_LIGADAS) return noone;
    if (!instance_exists(_inst)) return noone;
    if (!_forcar)
    {
        if (!variable_global_exists("fala_espera")) global.fala_espera = 0;
        if (global.fala_espera > 0) return noone;
    }
    global.fala_espera = 100;
    return fala_balao(_inst, _texto, _cor, _dur);
}

// cria o balão (obj_fala) preso ao inimigo
function fala_balao(_inst, _texto, _cor, _dur)
{
    with (obj_fala) if (alvo == _inst) instance_destroy();
    var _f = instance_create_depth(_inst.x, _inst.y, -150, obj_fala);
    _f.alvo = _inst;
    _f.texto = _texto;
    _f.cor = _cor;
    _f.vida = _dur;
    _f.vida_max = _dur;
    return _f;
}

function fala_aleatoria(_inst, _lista, _cor, _chance = 0.35)
{
    if (random(1) > _chance) return noone;
    return fala_dizer(_inst, _lista[irandom(array_length(_lista) - 1)], _cor);
}

// v1.18: os balões voltaram SÓ no começo dos ataques (pedido do jogador): o
// inimigo grita uma frase curta de vez em quando, avisando o golpe. Funciona
// mesmo com FALAS_LIGADAS = false (as outras falas, ao apanhar ou surgir,
// continuam desligadas). Um balão de ataque por vez na tela inteira.
#macro FALA_ATAQUE_ESPERA 190     // quadros (~3,2 s) entre dois balões de ataque
#macro FALA_ATAQUE_DUR    80      // curto: some antes do próximo golpe
function fala_ataque(_inst, _lista, _cor, _chance = 0.35)
{
    if (!instance_exists(_inst) or array_length(_lista) == 0) return noone;
    if (!variable_global_exists("fala_espera")) global.fala_espera = 0;
    if (global.fala_espera > 0) return noone;
    if (random(1) > _chance) return noone;
    global.fala_espera = FALA_ATAQUE_ESPERA;
    return fala_balao(_inst, _lista[irandom(array_length(_lista) - 1)], _cor, FALA_ATAQUE_DUR);
}

function falas_besta()     { return ["Atacaaarrr!", "Grrraaah!", "Carne fresca!", "Pela maldição!", "Daqui não passa!"]; }
function falas_arqueiro()  { return ["Fogo!", "Na mira...", "Hehehe!", "Flechas!", "Fique longe!"]; }
function falas_escudo()    { return ["Atrás do escudo!", "Ninguém passa!", "Formação!", "Meu escudo não cai!"]; }
function falas_boss()      { return ["O nosso Sr. Vallack reinará!", "Esta estrada pertence a Vallack!", "Servos, ergam-se!", "Queime, invasor!"]; }
function falas_boss_furia(){ return ["Sinta a fúria da floresta!", "Vallack reinará para sempre!", "Minhas raízes vão te esmagar!"]; }

// ---------------------------------------------------------------------
// PORTAL DE MAGIA: bestas e arqueiros surgem do chão (executado no inimigo)
// ---------------------------------------------------------------------
#macro SURGIR_SUBIDA 60     // quadros escalando para fora do buraco (era 42, subida reta)
#macro SURGIR_PUXOES 3      // quantos puxões até sair
#macro SURGIR_GRITO  26     // quadros gritando antes de atacar

// progresso da escalada (0 = enterrado, 1 = fora): cada puxão sobe rápido
// e segura um instante, como alguém se içando pela borda
function surgir_progresso(_t)
{
    var _seg = SURGIR_SUBIDA / SURGIR_PUXOES;
    var _i = min(SURGIR_PUXOES - 1, floor(_t / _seg));
    var _f = clamp((_t - _i * _seg) / (_seg * 0.6), 0, 1);
    return (_i + 1 - power(1 - _f, 3)) / SURGIR_PUXOES;
}

function inimigo_portal_iniciar()
{
    ativo = false;
    surgir_fase = "escondido";   // escondido -> portal -> subindo -> grito -> ativo
    surgir_puxao = -1;
    surgir_t = 0;
    surgir_agora = false;        // o boss liga isto ao invocar
    surgir_atraso = 0;
    distancia_surgir = 420;      // o portal abre quando o ponto entra na tela e o jogador está a até 420 px (v1.12: era 520; os grupos chegam um de cada vez)
    portal_raio = 0;
}

// Retorna true enquanto o inimigo ainda está escondido / surgindo
function inimigo_portal_step(_dt)
{
    if (ativo)
    {
        if (portal_raio > 0) portal_raio = max(0, portal_raio - 0.04 * _dt);   // o portal se fecha
        return false;
    }
    var _pj = instance_find(obj_player, 0);
    switch (surgir_fase)
    {
        case "escondido":
            var _abrir = false;
            if (surgir_agora)
            {
                surgir_atraso -= _dt;              // invocação do boss: um portal depois do outro
                _abrir = (surgir_atraso <= 0);
            }
            else if (_pj != noone and !_pj.morto and abs(_pj.x - x) <= distancia_surgir and abs(_pj.y - y) <= 200)
            {
                // o portal abre quando o ponto já aparece na tela (vale para 16:9, 4:3 e 21:9)
                if (view_camera[0] != -1)
                {
                    var _cvx = camera_get_view_x(view_camera[0]);
                    var _cvw = camera_get_view_width(view_camera[0]);
                    _abrir = (x > _cvx + 24 and x < _cvx + _cvw - 24);
                }
                else _abrir = true;
            }
            if (_abrir)
            {
                surgir_fase = "portal";
                surgir_t = 0;
                som_em("sfx_portal", x, y, 0.45);
                // v1.19: a primeira leva da fase -> Twilight fala antes da luta
                if (!surgir_agora and _pj != noone and global.fala_batalha_room != room)
                {
                    global.fala_batalha_room = room;
                    fala_balao(_pj, "Servos de Vallack... irão pagar com a vida!", make_color_rgb(150, 20, 20), 170);
                    global.grito_espera = max(global.grito_espera, 40);
                }
            }
        break;
        case "portal":
            surgir_t += _dt;
            portal_raio = min(1, surgir_t / 24);
            if (surgir_t >= 30)
            {
                surgir_fase = "subindo";
                surgir_t = 0;
                surgir_puxao = -1;
                if (_pj != noone and _pj.x != x) dir = sign(_pj.x - x);
            }
        break;
        case "subindo":
            // v1.19: escala para fora do submundo em puxões (SURGIR_PUXOES),
            // cada puxão solta terra na borda do buraco
            surgir_t += _dt;
            var _px = min(SURGIR_PUXOES - 1, floor(surgir_t / (SURGIR_SUBIDA / SURGIR_PUXOES)));
            if (_px != surgir_puxao)
            {
                surgir_puxao = _px;
                fx_em("pedras", x + random_range(-14, 14), y - 2, 0.6);
                fx_em("poeira", x, y - 2, 0.7);
            }
            if (surgir_t >= SURGIR_SUBIDA)
            {
                surgir_fase = "grito";
                surgir_t = 0;
                // o grito: rugido, tremida e um balão curto (um por leva)
                global.camera_impact = max(global.camera_impact, 3);
                if (global.grito_espera <= 0)
                {
                    global.grito_espera = 45;
                    som_em("sfx_rugido", x, y, 0.5);
                    var _gritos = ["GRRAAAH!", "RAAARGH!", "AAARGH!", "HRRAAA!"];
                    fala_balao(id, _gritos[irandom(array_length(_gritos) - 1)], make_color_rgb(120, 10, 10), 40);
                }
            }
        break;
        case "grito":
            surgir_t += _dt;
            if (surgir_t >= SURGIR_GRITO)
            {
                surgir_fase = "ativo";
                ativo = true;
                if (estado_ao_surgir != "") estado_ia = estado_ao_surgir;
                else estado_ia = (object_index == obj_inimigo_02) ? "parado" : "perseguir";
                if (variable_instance_exists(id, "alertado")) alertado = true;
                alerta_fx = 40;
                recarga = max(recarga, 24);
                global.camera_impact = max(global.camera_impact, 2);
            }
        break;
    }
    velh = 0;
    if (!place_meeting(x, y + 1, obj_chao)) velv += grav_ia * _dt;
    else if (velv > 0) velv = 0;
    return true;
}

// Desenha o portal e o inimigo saindo do buraco (só a parte acima do chão)
// _esc = escala do inimigo no mundo (a sprite HD é desenhada com 1/k)
function inimigo_portal_desenhar(_spr, _esc, _cor_final = c_white)
{
    if (surgir_fase == "escondido") return;
    desenhar_portal(x, y, portal_raio, current_time / 16);
    if (surgir_fase == "subindo" or surgir_fase == "grito")
    {
        var _grito = (surgir_fase == "grito");
        var _ease = _grito ? 1 : surgir_progresso(surgir_t);
        var _k = hd_escala(_spr);                 // pixels da sprite por pixel do mundo
        var _e = _esc / _k;
        var _h = sprite_get_height(_spr);
        var _ox = sprite_get_xoffset(_spr);
        var _oy = sprite_get_yoffset(_spr);
        var _sobe = (1 - _ease) * _h;           // ainda enterrado este tanto (px da sprite)
        var _vis = clamp(_oy - _sobe, 0, _h);   // linhas acima do chão
        // balanço lateral da escalada / tremor do grito
        var _bx = _grito ? random_range(-1, 1) : sin(surgir_t * 0.35) * 2 * (1 - _ease);
        var _sy = 1;
        if (_grito) _sy = 1 + 0.08 * sin(clamp(surgir_t / SURGIR_GRITO, 0, 1) * pi);   // estufa ao gritar
        if (_vis >= 1)
        {
            gpu_set_texfilter(_k > 1);
            draw_sprite_part_ext(_spr, 0, 0, 0, sprite_get_width(_spr), _vis,
                x + _bx - dir * _ox * _e, y + (_sobe - _oy) * _e * _sy, dir * _e, _e * _sy,
                merge_color(make_color_rgb(200, 120, 255), _cor_final, _ease), 1);
            gpu_set_texfilter(false);
        }
        if (_grito)
        {
            // ondas do grito saindo da boca
            var _cy = y - _oy * _e * 0.75;
            gpu_set_blendmode(bm_add);
            draw_set_color(make_color_rgb(255, 80, 60));
            for (var _o = 0; _o < 2; _o++)
            {
                var _f = frac(surgir_t / 16 + _o * 0.5);
                draw_set_alpha(0.45 * (1 - _f));
                draw_circle(x + dir * 10, _cy, 8 + _f * 34, true);
            }
            gpu_set_blendmode(bm_normal);
            draw_set_alpha(1);
            return;
        }
        // brilho na borda do portal por cima
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.6 * (1 - _ease));
        draw_set_color(make_color_rgb(220, 90, 255));
        draw_ellipse(x - 30, y - 6, x + 30, y + 6, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
}
