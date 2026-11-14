// =====================================================================
//  obj_boss_01 — ÁRVORE AMALDIÇOADA (boss da Fase 1)
//  dormindo -> despertar (diálogo; a arena se fecha) -> parado <-> atacando /
//  raizes / galho -> (66% e 33% da vida) nova fase -> ... -> morrendo
//  * muralhas mágicas fecham a arena: ninguém entra nem sai
//  * v1.12: SEM HORDAS. A luta é só Twilight contra a árvore, em 3 FASES,
//    cada uma com uma sequência fixa de ataques e avisos claros:
//      fase 1: bola de fogo, bola de fogo, raiz
//      fase 2: galho varredor, 2 bolas de fogo, 3 raízes
//      fase 3: galho mais rápido, onda de 5 raízes, 3 bolas de fogo em leque
//    Avisos: a mão brilha antes da bola de fogo, o chão brilha antes da raiz
//    e o chão inteiro da arena brilha antes do galho.
//  * ao morrer evapora na fumaça negra da maldição (v1.10)
// =====================================================================
event_inherited();          // obj_inimigo_base
eh_boss = true;
nome_boss = "ÁRVORE AMALDIÇOADA";
titulo_boss = "GUARDIÃ DA ESTRADA DE VALLACK";

// Escala uniforme; a máscara (tronco) acompanha esse tamanho.
// v1.13: tamanho fixo (o mesmo da versão Android): com a câmera mais perto, a
// árvore inteira cabe na tela; antes vinha da escala da instância na sala
escala = 2.4;
image_xscale = escala;
image_yscale = escala;
mask_index = spr_mascara_boss;
dir = -1;                   // as sprites do boss olham para a ESQUERDA
// v1.13: a MESMA árvore em todos os estados (antes ela virava outra árvore ao
// atacar e parecia sumir); na fase 3 a chama de Vallack toma a árvore
spr_parado = spr_boss_01_parado;
spr_acao = spr_boss_01;
spr_ataque = spr_boss_01_atacando;

// ===== VIDA E DANO (ajustados pela dificuldade) =====
vida_max = round(1900 * dif_vida_boss());       // v1.12: 900 -> 1200 · v1.17: 1900 (não morre fácil)
vida = vida_max;
vida_atraso = vida;
// v1.17: com 12% da vida ela CAMBALEIA e só cai pela SEQUÊNCIA DE GOLPES.
// Errou ou demorou: ela se recupera (25% da vida), empurra Twilight e volta a atacar.
usa_qte = true;
vulneravel_t = 0;
VULNERAVEL_PCT = 0.12;
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

// ===== ONDAS DE SERVOS (v1.12: desligadas; invocar_servos() continua aqui para outras fases) =====
onda_espera = 210;
onda_tempo = 0;
onda_numero = 0;
invocacao_feita = false;

// ===== FASES (v1.12) =====
fase = 1;
ataque_n = 0;               // posição na sequência de ataques da fase
rajada_desvios = [0];
dialogo_fim_feito = false;
furia = false;              // true a partir da fase 2 (cor e aura mais fortes)
furia_fx = 0;
raiz_recarga = 240;
perto_tempo = 0;            // tempo do jogador colado no tronco
rajada = 0;                 // bolas de fogo restantes na rajada

// ===== v1.19: INVOCAÇÃO CONTRA QUEM SE APROVEITA DA LUTA =====
// colado no tronco batendo sem parar, ou parado num canto onde os ataques não
// chegam ("procurando um bug"): a árvore abre portais e chama seus servos
golpeada_t = 0;             // > 0: levou golpe há pouco
acampar_t = 0;              // tempo de Twilight colado batendo no tronco
canto_t = 0;                // tempo de Twilight parado no mesmo lugar sem levar dano
canto_x = -10000;
canto_y = -10000;
vida_jogador_ant = -1;
invocar_recarga = 600;      // a primeira invocação só depois de ~10 s de luta
invocacao_motivo = "perto";
INVOCAR_PERTO = 240;        // 4 s colado batendo
INVOCAR_CANTO = 480;        // 8 s parado sem levar dano

// ===== v1.19: CHUVA DE FOGO (momentos marcados da luta) =====
// ao passar de 85%, 50% e 22% da vida, e de tempos em tempos, a árvore faz
// chover bolas de fogo na arena inteira (uma varredura da árvore para a esquerda)
chuva_marcos = [0.85, 0.5, 0.22];
chuva_marco_i = 0;
chuva_grande_t = 1800;      // a primeira por tempo: 30 s depois de acordar

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
sprite_index = spr_parado;
image_index = 0;
image_speed = 0.35;
fala_t = 600;

despertar = function()
{
    if (acordado or estado_ia == "despertar" or morrendo) return;
    estado_ia = "despertar";
    sprite_index = spr_acao;          // olhos acendem, de frente
    image_index = 0;
    image_speed = 1.2;
    titulo_tempo = 210;
    global.camera_impact = max(global.camera_impact, 14);
    som("sfx_rugido", 1, 0);
    musica("bgm_final_boss_phase1", 1500);   // v1.16: trilha do chefe final da fase 1
    if (!arena_fechada)
    {
        arena_fechada = true;
        arena_fechar(arena_esq, barreira_x, y_chao, id);
    }
    dialogo_iniciar("arvore_inicio");        // v1.12: caixa de diálogo
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
    var _vels = [4.6, 5.0, 5.5];
    var _vel = _vels[clamp(fase - 1, 0, 2)];
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
};

// v1.19: GUARDAS DA RAIZ — poucos servos, escalando pelos portais perto de Twilight.
// "perto" (colado batendo no tronco): bestas e esqueleto dos dois lados dele;
// "canto" (parado onde os ataques não chegam): arqueiros, que alcançam o alto, e uma besta
invocar_guardas = function(_motivo)
{
    var _p = instance_find(obj_player, 0);
    if (_p == noone) return;
    var _lista;
    if (_motivo == "canto") _lista = [obj_inimigo_02, obj_inimigo_01, obj_inimigo_02];
    else _lista = [obj_inimigo_01, obj_esqueleto];
    if (fase >= 2) array_push(_lista, (_motivo == "canto") ? obj_inimigo_01 : obj_aranha);
    if (global.dificuldade >= DIF.DIFICIL) array_push(_lista, obj_inimigo_01);
    for (var _i = 0; _i < array_length(_lista); _i++)
    {
        var _obj = _lista[_i];
        var _lado = (_i mod 2 == 0) ? -1 : 1;
        var _sx = _p.x + _lado * (130 + 50 * floor(_i / 2) + random(40));
        // não nasce dentro do tronco: do lado da árvore, vai para o outro lado
        if (_sx > x - 110) _sx = _p.x - (150 + 40 * _i);
        _sx = clamp(_sx, arena_esq + 40, barreira_x - 60);
        var _sy = chao_abaixo(_sx, y_chao - 120, 300);
        var _e = instance_create_depth(_sx, _sy, 100, _obj);
        _e.invocado = true;
        _e.surgir_agora = true;
        _e.surgir_atraso = 10 + _i * 14;     // os portais abrem um depois do outro
        _e.dir = sign(_p.x - _sx);
        if (_e.dir == 0) _e.dir = 1;
        _e.vida_max = max(1, round(_e.vida_max * 0.8));
        _e.vida = _e.vida_max;
        _e.vida_atraso = _e.vida;
        if (_obj == obj_inimigo_02) { _e.recarga_max = 260; _e.recarga = irandom_range(60, 140); }
        if (_obj == obj_esqueleto) _e.reerguido = true;      // servos invocados não se levantam de novo
        if (_obj == obj_aranha) _e.recarga_teia = irandom_range(120, 220);
    }
};

// v1.19: CHUVA DE FOGO na arena inteira: as marcas acendem da árvore para a
// esquerda (dá para ler e correr) e as duas últimas caem em cima de Twilight
chuva_grande = function()
{
    var _n = 9 + fase * 3;
    var _x1 = arena_esq + 40, _x2 = barreira_x - 40;
    for (var _i = 0; _i < _n; _i++)
    {
        var _cx = _x1 + (_i + 0.5) / _n * (_x2 - _x1) + random_range(-14, 14);
        array_push(chuva_fila, [_cx, CHUVA_AVISO + 16 + (_n - 1 - _i) * 5, chao_abaixo(_cx, y_chao - 60, 160)]);
    }
    var _p = instance_find(obj_player, 0);
    if (_p != noone)
        for (var _k = 0; _k < 2; _k++)
        {
            var _cx2 = clamp(_p.x + ((_k == 0) ? 0 : random_range(-50, 50)), _x1, _x2);
            array_push(chuva_fila, [_cx2, CHUVA_AVISO + 16 + _n * 5 + _k * 22, chao_abaixo(_cx2, y_chao - 60, 160)]);
        }
    som("sfx_rugido", 0.9, 0);
    som_em("boss_carga", x, y, 1);
    global.camera_impact = max(global.camera_impact, 12);
    global.terremoto = max(global.terremoto, 40);
    aviso_mostrar("CHUVA DE FOGO!  ·  FIQUE LONGE DAS MARCAS");
};

// Raízes saem do chão embaixo de Twilight. _n = quantas (1, 3 ou 5).
// Com 5 é uma ONDA: nascem uma depois da outra, da árvore para a esquerda.
raizes_lancar = function(_n = 1)
{
    var _p = instance_find(obj_player, 0);
    if (_p == noone) return;
    var _onda = (_n >= 5);
    for (var _i = 0; _i < _n; _i++)
    {
        var _rx = _onda ? (_p.x + 160 - _i * 80) : (_p.x + (_i - (_n - 1) / 2) * 76);
        _rx = clamp(_rx, arena_esq + 30, barreira_x - 30);
        var _r = instance_create_depth(_rx, chao_abaixo(_rx, y_chao - 100, 300), depth - 2, obj_raiz);
        _r.dano = dano_raiz;
        _r.atraso = _onda ? _i * 12 : _i * 8;
    }
};

// GALHO VARREDOR (fases 2 e 3): varre a arena rente ao chão. Pule ou role.
galho_lancar = function()
{
    var _xb = x - 40 * escala / 3.7;
    var _g = instance_create_depth(_xb, y_chao, depth - 3, obj_galho);
    _g.dono = id;
    _g.dir = -1;
    _g.x_base = _xb;
    _g.ponta = _xb;
    _g.x_fim = arena_esq + 20;
    _g.y_chao = y_chao;
    _g.vel = (fase >= 3) ? 18 : 14;          // v1.19: era 16 / 13
    _g.dano = max(1, round(15 * dif_dano_inimigo()));
};

// v1.19: CHUVA DE BRASAS (fases 2 e 3): bolas de fogo caem do céu em volta de
// Twilight; uma marca brilha no chão antes de cada uma (chuva_fila: [x, espera, y do chão])
chuva_fila = [];
chuva_lancar = function(_n)
{
    var _p = instance_find(obj_player, 0);
    var _px = (_p != noone) ? _p.x : x - 300;
    for (var _i = 0; _i < _n; _i++)
    {
        // uma em cima de Twilight, as outras espalhadas dos dois lados
        var _off = (_i == 0) ? 0 : ((_i mod 2 == 1) ? 1 : -1) * (60 + 70 * floor((_i - 1) / 2)) + random_range(-14, 14);
        var _cx = clamp(_px + _off, arena_esq + 30, barreira_x - 30);
        array_push(chuva_fila, [_cx, CHUVA_AVISO + _i * CHUVA_INTERVALO, chao_abaixo(_cx, y_chao - 60, 160)]);
    }
    som_em("boss_carga", x, y, 0.9);
};

// Próximo ataque da sequência da fase atual
// v1.19: luta mais intensa: sequências mais longas e a chuva de brasas
boss_proximo_ataque = function()
{
    var _seq;
    switch (fase)
    {
        case 1:  _seq = ["fogo", "fogo2", "raiz1", "fogo", "raiz3"]; break;
        case 2:  _seq = ["galho", "fogo2", "raiz3", "chuva", "fogo3"]; break;
        default: _seq = ["galho", "raiz5", "fogo3", "chuva", "galho", "fogo3"]; break;
    }
    var _a = _seq[ataque_n mod array_length(_seq)];
    ataque_n += 1;
    return _a;
};

reagir_dano = function(_dano, _dir, _forca)
{
    tremor = 3;
    golpeada_t = 150;           // v1.19: Twilight está batendo (conta para a invocação)
    if (!acordado) despertar();
    // v1.17: só morre pela SEQUÊNCIA DE GOLPES (o finalizador dela é o golpe final)
    if (vida <= 0 and qte_vencido) { boss_morrer(); return; }
    vida = max(1, vida);
    if (estado_ia == "vulneravel") return;
    if (vida <= vida_max * VULNERAVEL_PCT) { boss_vulneravel(); return; }
    // v1.12: FASES em 66% e 33% da vida
    if (fase == 1 and vida <= vida_max * 0.66) boss_fase(2);
    else if (fase == 2 and vida <= vida_max * 0.33) boss_fase(3);
};

// v1.17: CAMBALEANDO: os ataques param, a árvore treme e espera a sequência de golpes
boss_vulneravel = function()
{
    estado_ia = "vulneravel";
    vulneravel_t = 0;
    finalizavel = true;
    qte_pronto = true;
    chuva_fila = [];
    with (obj_raiz) instance_destroy();
    with (obj_galho) instance_destroy();
    with (obj_bola_fogo) if (!explodindo) instance_destroy();
    sprite_index = spr_acao;
    image_index = 0;
    image_speed = 0.35;
    tremor = 4;
    global.camera_impact = max(global.camera_impact, 16);
    camera_lenta(30, 0.45);
    som("sfx_rugido", 0.8, 0);
    aviso_mostrar("A ÁRVORE CAMBALEIA  ·  EXECUTE A SEQUÊNCIA DE GOLPES!");
};

// v1.17: a árvore se recupera (o jogador errou a sequência ou demorou):
// volta com 25% da vida, solta uma onda que empurra Twilight e ataca de novo
boss_recuperar = function()
{
    finalizavel = false;
    qte_pronto = false;
    vida = max(vida, round(vida_max * 0.25));
    vida_atraso = vida;
    estado_ia = "transicao";
    sprite_index = spr_acao;
    image_index = 0;
    image_speed = 1;
    recarga = 40;
    tempo_invencivel = 60;
    furia = true;
    furia_fx = 90;
    global.camera_impact = max(global.camera_impact, 20);
    global.terremoto = max(global.terremoto, 30);
    som("sfx_rugido", 1, 0);
    fx_em("onda_chao", x - 60, y_chao, 2);
    var _p = instance_find(obj_player, 0);
    if (_p != noone and !_p.morto)
    {
        var _forte = (abs(_p.x - x) < 420);
        with (_p) levar_dano(_forte ? other.dano_raiz : 1, other.x, false, _forte ? 12 : 6, other.id);
    }
    aviso_mostrar("A ÁRVORE SE RECUPEROU!");
};
qte_falhou = function() { boss_recuperar(); };

// Troca de fase: rugido, os ataques em andamento somem e a árvore fica
// invulnerável enquanto ruge (o jogador tem um respiro)
boss_fase = function(_n)
{
    fase = _n;
    furia = true;
    furia_fx = 90;
    ataque_n = 0;
    recarga_max = round(dif_boss_recarga() * ((_n >= 3) ? 0.5 : 0.66));     // v1.19: era 0,62 / 0,8
    raiz_recarga = 200;
    chuva_fila = [];
    perto_tempo = 0;
    with (obj_raiz) instance_destroy();
    with (obj_galho) instance_destroy();
    with (obj_bola_fogo) if (!explodindo) instance_destroy();
    estado_ia = "transicao";
    if (_n >= 3) { spr_parado = spr_boss_fogo_parado; spr_acao = spr_boss_fogo; spr_ataque = spr_boss_fogo_atacando; }
    sprite_index = spr_acao;
    image_index = 0;
    image_speed = 1;
    tempo_invencivel = 90;
    global.camera_impact = max(global.camera_impact, 20);
    global.terremoto = max(global.terremoto, 40);
    camera_lenta(40, 0.45);
    som("sfx_rugido", 1, 0);
    aviso_mostrar((_n == 2) ? "A ÁRVORE AMALDIÇOADA SE ENFURECEU!" : "A CHAMA DE VALLACK TOMA A ÁRVORE!");
    dialogo_iniciar((_n == 2) ? "arvore_fase2" : "arvore_fase3");
};
boss_enfurecer = function() { boss_fase(2); };      // nome antigo (compatibilidade)

boss_morrer = function()
{
    morrendo = true;
    estado_ia = "morrendo";
    morte_tempo = 0;
    morte_t = 0;
    evaporar = 0;
    evaporar_tam = 4.2;          // fumaça da maldição bem maior (a árvore é enorme)
    sprite_index = spr_acao;
    image_index = 0;
    image_speed = 0.8;
    global.camera_impact = 26;
    global.inimigos_derrotados += 1;
    impacto(14);
    camera_lenta(90, 0.3);
    som("sfx_rugido", 1, 0);
    musica("", 2500);            // v1.16: chefe derrotado: a trilha some (fade-out)
    conquista("arvore");         // v1.17
    finalizavel = false;
    qte_pronto = false;
    chuva_fila = [];
    with (obj_raiz) instance_destroy();
    with (obj_galho) instance_destroy();
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
