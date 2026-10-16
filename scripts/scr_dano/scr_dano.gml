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

        vida = max(0, vida - _dano);
        tempo_invencivel = 60;           // v1.4: 1 s sem levar outro golpe (menos dano em sequência)
        tempo_sem_dano = 0;
        global.combo = 0;
        global.combo_tempo = 0;
        global.last_hit_flash = 12;
        global.last_hit_damage = _dano;
        global.camera_impact = 6;
        impacto(4);
        som("sfx_dano", 0.9);
        furia_ganhar(4);                  // apanhar também enche um pouco a fúria

        var _sangue = instance_create_depth(x, _cy, -100, obj_fagulha);
        _sangue.cor = make_color_rgb(255, 60, 50);

        // durante especiais, fúria e finalizador Twilight não é interrompido (só perde a vida)
        if (armadura and vida > 0)
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

// A rolagem está no trecho em que nada acerta Twilight?
function jogador_intangivel()
{
    return rolando and rolar_t >= ROLAR_INVENC_INI and rolar_t <= ROLAR_INVENC_FIM;
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
        aparar_fx = 24;
        defesa_fx = 16;
        tempo_invencivel = max(tempo_invencivel, 24);
        bloqueando = false;
        impacto(9);
        camera_lenta(34, 0.35);
        global.camera_impact = max(global.camera_impact, 10);
        global.last_hit_flash = 8;
        som("sfx_aparar", 1);
        var _cy = (bbox_top + bbox_bottom) / 2;
        fx_criar("aparar", x + facing * 20, _cy - 6, 1);
        furia_ganhar(12);
        trocar_animacao(spr_player_defendendo, 1);
        image_index = 2;
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
    if (aparado_t <= 0) atordoado_acumulado += _dt;
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
    empurrao = _dir * (resiste_atordoar ? 3 : 6.5);
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
    empurrao = _dir * 3.2;
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
    if (executando)
    {
        finalizavel = false;
        velh = 0;
        empurrao = 0;
        if (!instance_exists(obj_player) or is_undefined(obj_player.golpe) or obj_player.golpe.chave != "finalizador") executando = false;
        return executando;
    }
    var _fraco = (vida <= vida_max * (resiste_atordoar ? 0.25 : 0.34));
    finalizavel = ativo and !morrendo and !eh_boss and atordoado > 0 and (aparado_t > 0 or escudo_quebrado_t > 0 or _fraco);
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
    empurrao = _dir * 2.5;
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
        if (_soltar_orbs)
        {
            var _total = invocado ? 3 : orbs_do_inimigo(id);
            if (finalizado) _total *= ORBS_FINALIZADOR;
            orbs_soltar(x, y - 30, _total);
        }
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
        evaporar_fx = (global.cfg_qualidade == 0) ? 5 : 3;
        // muita fumaça na tela (uma onda inteira morrendo junto): solta menos
        var _n = 0;
        with (obj_fx) if (tipo == "fumaca_maldita") _n += 1;
        if (_n < 140 or random(1) < 0.3)
            fx_em("fumaca_maldita", x + random_range(-_larg, _larg) * 0.5, y - random(_alt * (1 - 0.35 * _e)), _tam * (0.7 + 0.5 * _e));
    }
    if (morte_t >= _fim)
    {
        // último sopro: a maldição leva o que sobrou do corpo
        fx_em("fumaca_maldita_estouro", x, y - _alt * 0.45, _tam);
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
        draw_sprite_hd(_spr, _img, _x, _y, _xs, _ys, _rot, _cor, _alpha);
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
    draw_sprite_hd(_spr, _img, _xx, _yy, _sx, _sy, _rot, _cor, _a);
    // silhueta negra da maldição tomando o corpo
    gpu_set_fog(true, make_color_rgb(10, 0, 14), 0, 0);
    draw_sprite_hd(_spr, _img, _xx, _yy, _sx, _sy, _rot, c_white, _a * min(1, _e * 2.2));
    gpu_set_fog(false, c_white, 0, 0);
    // brilho roxo nas bordas (mais forte no meio da evaporação)
    var _g = _a * 0.6 * sin(pi * _e);
    if (_g > 0.02)
    {
        gpu_set_blendmode(bm_add);
        gpu_set_fog(true, make_color_rgb(150, 20, 110), 0, 0);
        draw_sprite_hd(_spr, _img, _xx - 2 * _k, _yy, _sx, _sy, _rot, c_white, _g);
        draw_sprite_hd(_spr, _img, _xx + 2 * _k, _yy - 1, _sx, _sy, _rot, c_white, _g);
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
function fala_dizer(_inst, _texto, _cor = c_white, _forcar = false, _dur = 110)
{
    if (!instance_exists(_inst)) return noone;
    if (!_forcar)
    {
        if (!variable_global_exists("fala_espera")) global.fala_espera = 0;
        if (global.fala_espera > 0) return noone;
    }
    global.fala_espera = 100;
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

function falas_besta()     { return ["Atacaaarrr!", "Grrraaah!", "Carne fresca!", "Pela maldição!", "Daqui não passa!"]; }
function falas_arqueiro()  { return ["Fogo!", "Na mira...", "Hehehe!", "Flechas!", "Fique longe!"]; }
function falas_escudo()    { return ["Atrás do escudo!", "Ninguém passa!", "Formação!", "Meu escudo não cai!"]; }
function falas_boss()      { return ["O nosso Sr. Vallack reinará!", "Esta estrada pertence a Vallack!", "Servos, ergam-se!", "Queime, invasor!"]; }
function falas_boss_furia(){ return ["Sinta a fúria da floresta!", "Vallack reinará para sempre!", "Minhas raízes vão te esmagar!"]; }

// ---------------------------------------------------------------------
// PORTAL DE MAGIA: bestas e arqueiros surgem do chão (executado no inimigo)
// ---------------------------------------------------------------------
function inimigo_portal_iniciar()
{
    ativo = false;
    surgir_fase = "escondido";   // escondido -> portal -> subindo -> ativo
    surgir_t = 0;
    surgir_agora = false;        // o boss liga isto ao invocar
    surgir_atraso = 0;
    distancia_surgir = 520;      // o portal abre quando o ponto entra na tela e o jogador está a até 520 px
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
            }
        break;
        case "portal":
            surgir_t += _dt;
            portal_raio = min(1, surgir_t / 24);
            if (surgir_t >= 30)
            {
                surgir_fase = "subindo";
                surgir_t = 0;
                if (_pj != noone and _pj.x != x) dir = sign(_pj.x - x);
            }
        break;
        case "subindo":
            // primeira vez que um inimigo surge: pergaminho do tutorial
            var _tut = inimigo_tutorial(object_index);
            if (_tut != -1 and (room == Room1 or _tut != TUT.COMBATE)) tutorial_mostrar(_tut);
            surgir_t += _dt;
            if (surgir_t >= 42)
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

// Pergaminho do tutorial de cada tipo de inimigo
function inimigo_tutorial(_obj)
{
    switch (_obj)
    {
        case obj_inimigo_02: return TUT.ARQUEIRO;
        case obj_inimigo_03: return TUT.ESCUDO;
        case obj_esqueleto:  return TUT.ESQUELETO;
        case obj_aranha:     return TUT.ARANHA;
        case obj_porco:      return TUT.PORCO;
        case obj_estatua:    return TUT.ESTATUA;
    }
    return TUT.COMBATE;
}

// Desenha o portal e o inimigo saindo do buraco (só a parte acima do chão)
// _esc = escala do inimigo no mundo (a sprite HD é desenhada com 1/k)
function inimigo_portal_desenhar(_spr, _esc, _cor_final = c_white)
{
    if (surgir_fase == "escondido") return;
    desenhar_portal(x, y, portal_raio, current_time / 16);
    if (surgir_fase == "subindo")
    {
        var _t = clamp(surgir_t / 42, 0, 1);
        var _ease = 1 - power(1 - _t, 3);
        var _k = hd_escala(_spr);                 // pixels da sprite por pixel do mundo
        var _e = _esc / _k;
        var _h = sprite_get_height(_spr);
        var _ox = sprite_get_xoffset(_spr);
        var _oy = sprite_get_yoffset(_spr);
        var _sobe = (1 - _ease) * _h;           // ainda enterrado este tanto (px da sprite)
        var _vis = clamp(_oy - _sobe, 0, _h);   // linhas acima do chão
        if (_vis >= 1)
        {
            gpu_set_texfilter(_k > 1);
            draw_sprite_part_ext(_spr, 0, 0, 0, sprite_get_width(_spr), _vis,
                x - dir * _ox * _e, y + (_sobe - _oy) * _e, dir * _e, _e,
                merge_color(make_color_rgb(200, 120, 255), _cor_final, _ease), 1);
            gpu_set_texfilter(false);
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
