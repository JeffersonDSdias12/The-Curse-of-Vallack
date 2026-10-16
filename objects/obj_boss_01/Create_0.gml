// =====================================================================
//  obj_boss_01 — ÁRVORE AMALDIÇOADA (boss da Fase 1)
//  dormindo -> despertar (a arena se fecha) -> parado <-> atacando /
//  invocando / raizes -> (metade da vida) enfurecer -> ... -> morrendo
//  * muralhas mágicas fecham a arena: ninguém entra nem sai
//  * 3,5 s depois de despertar invoca 10 bestas e 5 arqueiros; quando a
//    onda acaba, outra vem 3,5 s depois
//  * fase 2 (metade da vida): fúria, 3 bolas de fogo e raízes do chão
//  * ao morrer deixa o tronco queimado no mapa
// =====================================================================
event_inherited();          // obj_inimigo_base
eh_boss = true;
nome_boss = "ÁRVORE AMALDIÇOADA";
titulo_boss = "GUARDIÃ DA ESTRADA DE VALLACK";

// A instância foi aumentada na sala (≈3,7x). Usamos uma escala uniforme e a
// máscara (tronco) acompanha esse tamanho.
escala = max(abs(image_xscale), abs(image_yscale));
if (escala < 1) escala = 1;
image_xscale = escala;
image_yscale = escala;
mask_index = spr_mascara_boss;
dir = -1;                   // as sprites do boss olham para a ESQUERDA

// ===== VIDA E DANO (ajustados pela dificuldade) =====
vida_max = round(900 * dif_vida_boss());
vida = vida_max;
vida_atraso = vida;
dano_fogo = max(1, round(16 * dif_dano_inimigo()));
dano_raiz = max(1, round(14 * dif_dano_inimigo()));
recarga_max = dif_boss_recarga();       // tempo entre uma bola de fogo e outra
recarga = 70;

// ===== ALCANCES E ARENA =====
alcance_visao = 760;        // ataca o jogador dentro desta distância (e só se estiver na tela)
alcance_fogo = 600;         // a bola de fogo estoura ao percorrer isto
barreira_x = x + 130;       // muralha da direita (saída da fase)
arena_esq = x - 760;        // muralha da esquerda
arena_fechada = false;
y_chao = chao_abaixo(x, y - 160);

// ===== ONDAS DE SERVOS =====
onda_espera = 210;          // 3,5 s
onda_tempo = 0;
onda_numero = 0;
invocacao_feita = false;

// ===== FASE 2 (FÚRIA) =====
furia = false;
furia_fx = 0;
raiz_recarga = 240;
perto_tempo = 0;            // tempo do jogador colado no tronco
rajada = 0;                 // bolas de fogo restantes na rajada

// ===== ESTADO =====
estado_ia = "dormindo";
acordado = false;
golpe_lancado = false;
hud_alpha = 0;
titulo_tempo = 0;
tremor = 0;
afundar = 0;
explosoes_t = 0;
orbs_soltas = false;
sprite_index = spr_boss_01_parado;
image_index = 0;
image_speed = 0.35;
fala_t = 600;

despertar = function()
{
    if (acordado or estado_ia == "despertar" or morrendo) return;
    estado_ia = "despertar";
    sprite_index = spr_boss_01;          // olhos acendem, de frente
    image_index = 0;
    image_speed = 1.2;
    titulo_tempo = 210;
    global.camera_impact = max(global.camera_impact, 14);
    som("sfx_rugido", 1, 0);
    musica("mus_boss", 800);
    fala_dizer(id, "O nosso Sr. Vallack reinará!", make_color_rgb(150, 20, 10), true, 150);
    if (!arena_fechada)
    {
        arena_fechada = true;
        arena_fechar(arena_esq, barreira_x, y_chao, id);
    }
};

lancar_bola_fogo = function(_alvo, _desvio)
{
    // a bola sai da mão (quadro 6 da animação de ataque)
    var _sx = x + dir * 30 * escala;
    var _sy = y - 36 * escala;
    var _b = instance_create_depth(_sx, _sy, depth - 5, obj_bola_fogo);
    _b.dano = dano_fogo;
    _b.alcance = alcance_fogo;
    var _tx = _sx + dir * 400;
    var _ty = y_chao - 30;
    if (_alvo != noone and instance_exists(_alvo))
    {
        _tx = _alvo.x;
        _ty = _alvo.y - 34;
        // DIFÍCIL e EXTREMO: mira um pouco à frente de quem corre
        if (global.dificuldade >= DIF.DIFICIL) _tx += _alvo.velh * point_distance(_sx, _sy, _tx, _ty) / 4.6 * 0.7;
    }
    if (sign(_tx - _sx) != dir) _tx = _sx + dir * 160;    // nunca para trás
    var _ang = point_direction(_sx, _sy, _tx, _ty) + _desvio;
    var _vel = furia ? 5.4 : 4.6;
    _b.vx = lengthdir_x(_vel, _ang);
    _b.vy = lengthdir_y(_vel, _ang);
    global.camera_impact = max(global.camera_impact, 5);
    som_em("fogo_bola", x, y, 0.9);
};

// servos invocados ainda vivos
servos_vivos = function()
{
    var _n = 0;
    with (obj_inimigo_base) if (invocado and !morrendo and !eh_boss) _n += 1;
    return _n;
};

// ONDA: 10 bestas e 5 arqueiros surgem pelos portais, um depois do outro,
// sempre dentro da arena. v1.8: também esqueletos guerreiros e, a partir
// da segunda onda, mulheres-aranha (quantidade pela dificuldade)
invocar_servos = function()
{
    onda_numero += 1;
    var _lista = [];
    repeat (BOSS_ONDA_BESTAS) array_push(_lista, obj_inimigo_01);
    repeat (BOSS_ONDA_ARQUEIROS) array_push(_lista, obj_inimigo_02);
    repeat (dif_valor(BOSS_ONDA_ESQUELETOS)) array_push(_lista, obj_esqueleto);
    if (onda_numero >= 2) repeat (dif_valor(BOSS_ONDA_ARANHAS)) array_push(_lista, obj_aranha);
    var _p = instance_find(obj_player, 0);
    var _px = (_p != noone) ? _p.x : x - 300;
    for (var _i = 0; _i < array_length(_lista); _i++)
    {
        var _obj = _lista[_i];
        var _sx;
        if (_obj == obj_inimigo_02 or _obj == obj_aranha) _sx = arena_esq + 50 + random(160) + ((_i mod 2) * 420);   // arqueiros e aranhas nas pontas
        else _sx = arena_esq + 60 + random(barreira_x - arena_esq - 120);
        // não surge colado em Twilight
        if (abs(_sx - _px) < 70) _sx += (_sx < _px) ? -90 : 90;
        _sx = clamp(_sx, arena_esq + 40, barreira_x - 40);
        var _sy = chao_abaixo(_sx, y_chao - 120, 300);
        var _e = instance_create_depth(_sx, _sy, 100, _obj);
        _e.invocado = true;
        _e.surgir_agora = true;
        _e.surgir_atraso = _i * 9;       // os portais abrem um depois do outro
        _e.dir = sign(_px - _sx);
        if (_e.dir == 0) _e.dir = -1;
        // servos invocados são mais fracos (são muitos de uma vez)
        _e.vida_max = max(1, round(_e.vida_max * 0.7));
        _e.vida = _e.vida_max;
        _e.vida_atraso = _e.vida;
        if (_obj == obj_inimigo_02) { _e.recarga_max = 380; _e.recarga = irandom_range(90, 300); }
        if (_obj == obj_esqueleto) _e.reerguido = true;      // servos invocados não se levantam de novo
        if (_obj == obj_aranha) _e.recarga_teia = irandom_range(120, 260);
    }
    fala_dizer(id, choose("Servos, ergam-se!", "Ataquem o invasor!", "Pela glória de Vallack!"), make_color_rgb(150, 20, 10), true);
};

// Raízes saem do chão embaixo de Twilight (fase 2 ou quando ele fica colado no tronco)
raizes_lancar = function()
{
    var _p = instance_find(obj_player, 0);
    if (_p == noone) return;
    var _n = furia ? 3 : 1;
    for (var _i = 0; _i < _n; _i++)
    {
        var _rx = clamp(_p.x + (_i - (_n - 1) / 2) * 70, arena_esq + 30, barreira_x - 30);
        var _r = instance_create_depth(_rx, chao_abaixo(_rx, y_chao - 100, 300), depth - 2, obj_raiz);
        _r.dano = dano_raiz;
        _r.atraso = _i * 10;
    }
};

reagir_dano = function(_dano, _dir, _forca)
{
    tremor = 3;
    if (!acordado) despertar();
    if (vida <= 0) { boss_morrer(); return; }
    // FASE 2: metade da vida
    if (!furia and vida <= vida_max * 0.5) boss_enfurecer();
};

boss_enfurecer = function()
{
    furia = true;
    furia_fx = 90;
    recarga_max = round(dif_boss_recarga() * 0.62);
    raiz_recarga = 90;
    global.camera_impact = max(global.camera_impact, 20);
    global.terremoto = max(global.terremoto, 40);
    camera_lenta(40, 0.45);
    som("sfx_rugido", 1, 0);
    var _ff = falas_boss_furia();
    fala_dizer(id, _ff[irandom(array_length(_ff) - 1)], make_color_rgb(200, 20, 10), true, 150);
    aviso_mostrar("A ÁRVORE AMALDIÇOADA SE ENFURECEU!");
    // a próxima onda vem logo
    onda_tempo = max(onda_tempo, onda_espera - 60);
};

boss_morrer = function()
{
    morrendo = true;
    estado_ia = "morrendo";
    morte_tempo = 0;
    morte_t = 0;
    evaporar = 0;
    evaporar_tam = 4.2;          // fumaça da maldição bem maior (a árvore é enorme)
    sprite_index = spr_boss_01;
    image_index = 0;
    image_speed = 0.8;
    global.camera_impact = 26;
    global.inimigos_derrotados += 1;
    impacto(14);
    camera_lenta(90, 0.3);
    som("sfx_rugido", 1, 0);
    fala_dizer(id, "Vallack... vai... vingar...", make_color_rgb(150, 20, 10), true, 180);
    with (obj_raiz) instance_destroy();
    // os servos invocados se desfazem junto com o guardião
    with (obj_inimigo_base)
    {
        if (invocado and !morrendo and !eh_boss)
        {
            if (ativo) inimigo_morrer(1, false);
            else instance_destroy();
        }
    }
};
