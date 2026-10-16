// =====================================================================
//  obj_player — o herói (Twilight Vetrus)
// =====================================================================
event_inherited();
globais_iniciar();
if (!instance_exists(obj_sistema)) instance_create_depth(0, 0, 0, obj_sistema);

// ===== ESCALA, MÁSCARA E DIREÇÃO =====
// A escala é uniforme e o desenho é feito com draw_sprite_ext; a máscara
// nunca é espelhada nem esticada. O tamanho de cada sprite é igualado por
// sprite_fator() (scr_combate).
escala = 1.25;
image_xscale = 1;
image_yscale = 1;
mask_index = spr_mascara_player;     // retângulo simétrico 22x66 (corpo), base nos pés
facing = 1;                          // 1 = direita, -1 = esquerda

// ===== MOVIMENTO (valores por quadro de 60 FPS) =====
vel_correr = 3.6;      // Twilight sempre corre (não existe mais andar)
vel_agachado = 0.75;   // se arrastando agachado
grav       = 0.25;
vel_jump   = 7;
coyote     = 0;      // pequena tolerância para pular logo após sair da borda
buffer_pulo = 0;     // pulo apertado um pouco antes de tocar o chão
pouso      = 0;      // quadros da pose de aterrissagem
no_ar_tempo = 0;
tempo_fase = 0;      // tempo desde que o jogador assumiu o controle na fase
anim_passo = 0;      // a caminhada avança pela distância andada (sem "patinar")

// ===== VIDA =====
// v1.4: a vida não enche sozinha. Ela volta nos baús de vida, nos cristais
// dourados (menos no EXTREMO) e um pouco nos finalizadores.
vida_max = 100;
vida = vida_max;
if (global.vida_carregada > 0)
{
    vida = clamp(global.vida_carregada, 1, vida_max);
    global.vida_carregada = -1;
}
vida_atraso      = vida;
tempo_invencivel = 0;
tempo_sem_dano   = 0;
empurrao         = 0;
machucado        = false;
morto            = false;
tempo_morte      = 0;
cura_restante    = 0;        // cura aos poucos (baú de vida)
cura_fx          = 0;

// ===== COMBATE =====
// "atacando" vale para qualquer golpe (os inimigos à frente ficam atordoados);
// "especial" só para os 3 especiais.
atacando          = false;
especial          = false;
armadura          = false;   // especiais, fúria e finalizador não são interrompidos
bloqueando        = false;
agachado          = false;
golpe             = undefined;   // golpe em andamento (tabela de scr_combate)
golpe_i           = 0;           // quadro atual da tabela
golpe_t           = 0;           // tempo no quadro atual
golpe_grupo       = -1;          // grupo de acerto atual
cadeia            = "";          // letras dos golpes encadeados (combo)
cadeia_janela     = 0;           // tempo para continuar o combo depois do golpe
buffer_golpe      = "";          // golpe apertado antes da hora (entra assim que puder)
buffer_golpe_t    = 0;
atingidos         = [];          // inimigos já atingidos no grupo atual (1 acerto por golpe)
combo_nome        = "";          // "COMBO 1 · LÂMINA DE VALLACK" na tela
combo_nome_t      = 0;
sprite_defesa     = spr_player_defendendo;   // Twilight com o escudo mágico
defesa_fx         = 0;
barreira_aviso    = 0;
brilho_golpe      = 0;           // brilho da espada antes dos finalizadores
carga_fx          = 0;           // energia juntando (especial 3)
bloqueado_aviso   = 0;           // "especial bloqueado: evolua a espada"
bloqueado_txt     = "";

// ESQUIVA (rolagem): um instante sem levar dano
rolando           = false;
rolar_t           = 0;
rolar_dir         = 1;
rolar_recarga     = 0;
rolar_buffer      = 0;           // esquiva apertada um pouco antes de poder rolar (fim de golpe, pouso)
rolar_buffer_dir  = 0;           // lado do analógico direito no momento em que apertou
fantasmas        = [];          // imagens "fantasma" deixadas pela rolagem
// v1.8: TEIA da Mulher-Aranha (lento, sem pular e sem rolar; apertar botões solta)
enredado         = 0;
enredado_max     = 1;
enredado_fx      = 0;
teia_imune       = 0;           // logo depois de se soltar, a teia do chão não prende de novo
esquivou          = false;       // esta rolagem já desviou de um golpe
esquiva_fx        = 0;

// APARAR (parry): apertar a defesa na hora certa rebate o golpe
janela_aparar     = 0;           // quadros em que um golpe recebido é aparado
aparar_recarga    = 0;           // evita aparar apertando sem parar
aparar_fx         = 0;

// FINALIZADOR: inimigo atordoado + BOLA = golpe final
alvo_final        = noone;

// FÚRIA: enche ao bater nos inimigos; cheia, libera a Ira de Vallack
furia             = 0;
furia_cheia_fx    = 0;

// Especiais: uma barra de MAGIA que enche em 10 segundos. Cada especial
// gasta uma parte dela (Onda 40%, Tremor 60%, Queda 70%).
especial_carga = ESPECIAL_SEGUNDOS;
especial_pronto_fx = 0;

// interação (baús e cristal dourado)
alvo_interacao = noone;

// efeitos visuais
ondas = [];                  // ondas carmesim do especial 1
rastros = [];                // rastro da espada
debug_golpe = [];            // último retângulo de golpe (F1 mostra)

// ===== ANIMAÇÃO =====
image_speed = 1;
trocar_animacao = function(_spr, _vel)
{
    if (sprite_index != _spr)
    {
        sprite_index = _spr;
        image_index = 0;
    }
    image_speed = _vel;
};

// ---------------------------------------------------------------------
// GOLPES (a tabela de cada golpe fica em scr_combate)
// ---------------------------------------------------------------------
golpe_iniciar = function(_chave)
{
    var _g = golpe_criar(_chave);
    if (is_undefined(_g)) return false;
    golpe = _g;
    golpe_i = 0;
    golpe_t = 0;
    golpe_grupo = -1;
    atingidos = [];
    atacando = true;
    especial = _g.especial;
    armadura = _g.armadura;
    bloqueando = false;
    agachado = false;
    sprite_index = _g.spr;
    image_speed = 0;
    image_index = _g.seq[0].q;
    if (!_g.no_ar) velh = 0;
    if (_g.especial)
    {
        especial_carga = max(0, especial_carga - especial_custo(_g.acao_esp) * ESPECIAL_SEGUNDOS);
        global.camera_impact = max(global.camera_impact, 8);
    }
    else if (_g.chave != "ira" and _g.chave != "finalizador") global.attacks_total += 1;
    if (_g.combo > 0)
    {
        combo_nome = "COMBO " + string(_g.combo) + "  ·  " + _g.nome;
        combo_nome_t = 110;
    }
    // som do golpe (cada ataque tem o seu)
    var _som_g = golpe_som(_g.chave);
    if (_som_g != "") som(_som_g, _g.pesado ? 0.95 : 0.8);
    golpe_entrar_quadro();
    return true;
};

// Encerra o golpe atual (fim da animação, dano recebido ou queda do mapa)
golpe_cancelar = function()
{
    if (!is_undefined(golpe) and golpe.chave == "finalizador" and instance_exists(alvo_final))
    {
        with (alvo_final) executando = false;
    }
    golpe = undefined;
    atacando = false;
    especial = false;
    armadura = false;
    brilho_golpe = 0;
    carga_fx = 0;
    image_speed = 1;
    global.camera_zoom = 1;
};

// Ao entrar num quadro da tabela: eventos e mudança de grupo de acerto
golpe_entrar_quadro = function()
{
    var _e = golpe.seq[golpe_i];
    image_index = _e.q;
    var _gr = _e[$ "grupo"];
    if (is_undefined(_gr)) _gr = 0;
    if (!is_undefined(_e[$ "hit"]) and _gr != golpe_grupo)
    {
        golpe_grupo = _gr;
        atingidos = [];
        rastro_criar();
    }
    var _ev = _e[$ "ev"];
    if (!is_undefined(_ev)) golpe_evento(_ev);
    golpe_acertar();
};

// Aplica a área de acerto do quadro atual (cada inimigo 1x por grupo).
// Também quebra caixotes e paredes (obj_destrutivel).
golpe_acertar = function()
{
    if (is_undefined(golpe)) return;
    var _e = golpe.seq[golpe_i];
    var _h = _e[$ "hit"];
    if (is_undefined(_h)) return;
    var _dm = _e[$ "dm"];
    if (is_undefined(_dm)) _dm = 1;
    var _x1 = x + facing * _h[0];
    var _x2 = x + facing * _h[1];
    var _l = ds_list_create();
    var _n = collision_rectangle_list(min(_x1, _x2), y + _h[2], max(_x1, _x2), y + _h[3], obj_inimigo_base, false, true, _l, false);
    var _g = golpe;
    for (var _i = 0; _i < _n; _i++)
    {
        var _alvo = _l[| _i];
        if (array_tem(atingidos, _alvo)) continue;
        if (_alvo.morrendo or !_alvo.ativo) continue;
        array_push(atingidos, _alvo);
        golpe_ferir(_alvo, _g, _dm, x);
    }
    ds_list_clear(_l);
    var _nd = collision_rectangle_list(min(_x1, _x2), y + _h[2], max(_x1, _x2), y + _h[3], obj_destrutivel, false, true, _l, false);
    for (var _j = 0; _j < _nd; _j++)
    {
        var _d = _l[| _j];
        if (array_tem(atingidos, _d)) continue;
        array_push(atingidos, _d);
        with (_d) destrutivel_bater((_g.pesado or _g.especial or _g.chave == "ira") ? 2 : 1, other.x);
    }
    ds_list_destroy(_l);
    debug_golpe = [min(_x1, _x2), y + _h[2], max(_x1, _x2), y + _h[3], 6];
};

// Dano de um golpe num inimigo
golpe_ferir = function(_alvo, _g, _dm, _origem_x)
{
    var _dano = dano_golpe(_g, _alvo, _dm);
    var _lanca = _g.lanca;
    var _atord = _g.atordoa;
    var _forca = _g.forca;
    var _vida_antes = _alvo.vida;
    with (_alvo)
    {
        levar_dano(_dano, _origem_x, !_g.especial, _forca, other.id, _g);
        if (!morrendo and !eh_boss and _lanca > 0 and pode_lancar) velv = min(velv, -_lanca);
        if (!morrendo and !eh_boss and _atord > 0) inimigo_atordoar(_atord);
    }
    var _acertou = instance_exists(_alvo) and (_alvo.vida < _vida_antes or _alvo.morrendo);
    // impacto: pausa curtinha, faíscas, som e fúria
    var _cx = (_alvo.bbox_left + _alvo.bbox_right) / 2;
    var _cy = (_alvo.bbox_top + _alvo.bbox_bottom) / 2;
    var _px = lerp(x + facing * 20, _cx, 0.6);
    if (_acertou)
    {
        impacto(_g.pesado ? 6 : (_g.especial ? 4 : 3));
        if (_g.pesado or _g.especial) som("hit_pesado", _g.especial ? 0.8 : 1); else som_var("hit", 3, 0.85);
        fx_criar("faiscas_golpe", _px, _cy, _g.pesado ? 1.3 : 1);
        furia_ganhar(_g.especial ? 2 : (_g.pesado ? 6 : 4));
    }
    if (_g.combo > 0 or _g.especial) global.camera_impact = max(global.camera_impact, 9);
};

// Dano em área ao redor de um ponto (golpes que batem no chão)
golpe_area = function(_cx, _raio, _altura)
{
    if (is_undefined(golpe)) return;
    var _g = golpe;
    var _l = ds_list_create();
    var _n = collision_rectangle_list(_cx - _raio, y - _altura, _cx + _raio, y + 12, obj_inimigo_base, false, true, _l, false);
    for (var _i = 0; _i < _n; _i++)
    {
        var _alvo = _l[| _i];
        if (array_tem(atingidos, _alvo)) continue;
        if (_alvo.morrendo or !_alvo.ativo) continue;
        array_push(atingidos, _alvo);
        golpe_ferir(_alvo, _g, 1, _cx);
    }
    ds_list_clear(_l);
    var _nd = collision_rectangle_list(_cx - _raio, y - _altura, _cx + _raio, y + 12, obj_destrutivel, false, true, _l, false);
    for (var _j = 0; _j < _nd; _j++)
    {
        var _d = _l[| _j];
        if (array_tem(atingidos, _d)) continue;
        array_push(atingidos, _d);
        with (_d) destrutivel_bater(3, _cx);
    }
    ds_list_destroy(_l);
    debug_golpe = [_cx - _raio, y - _altura, _cx + _raio, y + 12, 20];
};

furia_ganhar = function(_n)
{
    if (furia >= 100) return;
    furia = min(100, furia + _n * furia_ganho_mult());
    if (furia >= 100) { furia_cheia_fx = 60; som("esp_carga", 0.5); }
};

// Eventos dos quadros (saltos, impactos, efeitos)
golpe_evento = function(_ev)
{
    switch (_ev)
    {
        case "zoom":
            global.camera_impact = max(global.camera_impact, 6);
        break;
        case "brilho":
            brilho_golpe = 14;
        break;
        case "salto":            // Salto do Carrasco
            velv = -6.0;
            velh = facing * 2.4;
            brilho_golpe = 10;
            som("sfx_pulo", 0.7);
        break;
        case "mergulho":         // golpe pesado no ar
            velv = max(velv, 8.5);
            velh = facing * 1.6;
        break;
        case "impacto_leve":
            global.camera_impact = max(global.camera_impact, 7);
            fx_criar("poeira", x + facing * 40, y, 0.8);
            som("sfx_pouso", 0.9);
        break;
        case "impacto_carrasco":
            velh = 0;
            global.camera_impact = max(global.camera_impact, 10);
            fx_criar("onda_chao", x + facing * 16, y, 0.75);
            fx_criar("poeira", x + facing * 16, y, 1);
            som("sfx_pouso", 1);
            som("sfx_impacto", 0.55);
        break;
        case "impacto_quebra":
            velh = 0;
            global.camera_impact = max(global.camera_impact, 16);
            fx_criar("onda_chao", x + facing * 16, y, 1.1);
            fx_criar("poeira", x + facing * 16, y, 1.4);
            fx_criar("rachaduras", x + facing * 16, y, 0.9);
            som("sfx_impacto", 0.8);
        break;
        case "onda":
        case "onda_baixa":
            global.camera_impact = max(global.camera_impact, 16);
            var _baixa = (_ev == "onda_baixa");
            array_push(ondas, {
                x0: x, dir: facing, dist: 30, dist_max: 132,
                y_topo: _baixa ? -46 : -80, y_base: -2,
                raio: _baixa ? 22 : 34,
                vida: 16, vmax: 16, atingidos: []
            });
            som("esp_onda", 1);
        break;
        case "salto_queda":      // especial 2: salta
            velv = -7.2;
            velh = facing * 1.3;
            som("sfx_pulo", 0.8);
        break;
        case "mergulho_queda":   // especial 2: desce cravando a espada
            velv = max(velv, 12);
            velh = 0;
        break;
        case "impacto_queda":    // especial 2: espada no chão, dano em área
            velh = 0;
            global.camera_impact = max(global.camera_impact, 20);
            global.terremoto = max(global.terremoto, 18);
            golpe_area(x + facing * 14, 130, 90);
            fx_criar("onda_chao", x + facing * 14, y, 1.3);
            fx_criar("poeira", x + facing * 14, y, 1.5);
            fx_criar("rachaduras", x + facing * 14, y, 1);
            som("esp_queda", 1);
        break;
        case "faiscas":          // especial 2: ao fim da animação, faíscas sobem pela tela
            fx_criar("faiscas_tela", x, y, 1);
        break;
        case "carga":            // especial 3: carrega uma vez
            carga_fx = 1;
            fx_criar("carga", x, y - 40, 1);
            som("esp_carga", 0.85);
        break;
        case "carga_max":
            carga_fx = 2;
            global.terremoto = max(global.terremoto, 10);
        break;
        case "impacto_tremor":   // especial 3: a terra treme
            carga_fx = 0;
            velh = 0;
            global.camera_impact = max(global.camera_impact, 22);
            global.terremoto = max(global.terremoto, 70);
            golpe_area(x, 250, 100);
            fx_criar("onda_chao", x + facing * 10, y, 2.2);
            fx_criar("rachaduras", x + facing * 10, y, 1.8);
            fx_criar("poeira", x + facing * 10, y, 2);
            fx_criar("pedras", x + facing * 10, y, 1);
            som("esp_tremor", 1);
        break;

        // ----- FINALIZADOR -----
        case "fin_inicio":
            tempo_invencivel = max(tempo_invencivel, 90);
            global.camera_zoom = 1.25;
            som("atk_pesado", 1);
        break;
        case "fin_golpe":
            global.camera_zoom = 1.3;
            impacto(12);
            camera_lenta(40, 0.35);
            global.camera_impact = max(global.camera_impact, 18);
            som("sfx_finalizador", 1);
            if (instance_exists(alvo_final))
            {
                var _a = alvo_final;
                var _cy = (_a.bbox_top + _a.bbox_bottom) / 2;
                fx_criar("sangue", _a.x, _cy, 1.6);
                fx_criar("faiscas_golpe", _a.x, _cy, 2);
                with (_a)
                {
                    executando = false;
                    finalizado = true;
                    levar_dano(inimigo_dano_finalizador(), other.x, false, 10, other.id, other.golpe);
                }
                vida = min(vida_max, vida + 6);
                furia_ganhar(10);
            }
        break;
        case "fin_fim":
            global.camera_zoom = 1;
            alvo_final = noone;
        break;

        // ----- FÚRIA: IRA DE VALLACK -----
        case "ira_carga":
            tempo_invencivel = max(tempo_invencivel, 80);
            furia = 0;
            global.camera_zoom = 1.2;
            camera_lenta(30, 0.5);
            global.camera_impact = max(global.camera_impact, 10);
            som("esp_furia", 1);
            fx_criar("carga", x, y - 40, 1.6);
            carga_fx = 2;
        break;
        case "ira_golpe":
            carga_fx = 0;
            global.camera_zoom = 1;
            impacto(10);
            global.camera_impact = max(global.camera_impact, 26);
            global.terremoto = max(global.terremoto, 40);
            global.last_hit_flash = 18;
            golpe_area(x, 320, 150);
            for (var _l = -1; _l <= 1; _l += 2)
            {
                array_push(ondas, { x0: x, dir: _l, dist: 30, dist_max: 300, y_topo: -96, y_base: -2, raio: 44, vida: 26, vmax: 26, atingidos: [], ira: true });
            }
            fx_criar("onda_chao", x, y, 2.6);
            fx_criar("faiscas_tela", x, y, 1);
            som("esp_furia_impacto", 1);
        break;
    }
};

// Efeito visual (obj_fx)
fx_criar = function(_tipo, _x, _y, _tam)
{
    var _f = instance_create_depth(_x, _y, depth - 2, obj_fx);
    _f.tipo = _tipo;
    _f.tam = _tam;
    _f.dir = facing;
    with (_f) fx_iniciar();
    return _f;
};

// Rastro da espada (arco) do golpe atual
rastro_criar = function()
{
    if (is_undefined(golpe) or is_undefined(golpe.arco)) return;
    var _a = golpe.arco;
    array_push(rastros, { x: x, y: y, dir: facing, a1: _a[0], a2: _a[1], r: _a[2], h: _a[3],
        cor: golpe.cor, forte: (golpe.combo > 0 or golpe.chave == "finalizador"), vida: 12, vmax: 12 });
};

// Inimigo que pode levar o finalizador (perto e à frente / dos lados)
alvo_finalizavel = function()
{
    var _melhor = noone;
    var _dist = 78;
    with (obj_inimigo_base)
    {
        if (!finalizavel or morrendo or !ativo or eh_boss) continue;
        var _d = abs(x - other.x);
        if (_d <= _dist and abs(y - other.y) < 50) { _dist = _d; _melhor = id; }
    }
    return _melhor;
};

// ===== POSIÇÃO INICIAL / CHECKPOINT =====
if (global.checkpoint_ativo and room == global.checkpoint_room)
{
    x = global.checkpoint_x;
    y = global.checkpoint_y;
}
spawn_x = x;
spawn_y = y;

global.capitulo = max(1, fase_numero(room));
global.camera_zoom = 1;
global.cam_snap = true;
global.ultimo_x = x;
global.ultimo_y = y;
global.ultima_vida = vida;
