// =====================================================================
//  scr_cenario: cenário destrutível, baús de vida, armadilhas, arenas
//  e efeitos usados por vários objetos
// =====================================================================

#macro BAU_PARTICULAS 36     // gotas de magia que saem de um baú de vida

// Efeito visual (obj_fx) criado de qualquer lugar
function fx_em(_tipo, _x, _y, _tam = 1, _dir = 1, _prof = -110)
{
    var _f = instance_create_depth(_x, _y, _prof, obj_fx);
    _f.tipo = _tipo;
    _f.tam = _tam;
    _f.dir = _dir;
    with (_f) fx_iniciar();
    return _f;
}

// =====================================================================
// v1.19: FUMAÇA E BRASAS DE AMBIENTE (as casas em chamas da vila) no sistema
// de partículas do próprio GameMaker (C++). Antes cada sopro era um obj_fx com
// partículas em GML: ~130 instâncias vivas custavam ~5 ms por quadro (a metade
// do quadro!) e derrubavam o jogo dos 60 FPS. O visual é o mesmo: fumaça escura
// subindo e crescendo, brasas roxas da chama maldita.
// =====================================================================
#macro AMB_TETO 700          // partículas de ambiente vivas no máximo

function amb_particulas_iniciar()
{
    if (variable_global_exists("amb_ps") and part_system_exists(global.amb_ps)) return;
    global.amb_ps = part_system_create();
    part_system_depth(global.amb_ps, 395);
    part_system_automatic_update(global.amb_ps, false);     // anda pelo dt do jogo (amb_atualizar)
    global.amb_acc = 0;
    var _f = part_type_create();
    part_type_shape(_f, pt_shape_disk);
    part_type_color3(_f, make_color_rgb(60, 54, 54), make_color_rgb(40, 36, 38), make_color_rgb(30, 28, 30));
    part_type_alpha3(_f, 0, 0.3, 0);
    part_type_direction(_f, 78, 102, 0, 1);
    part_type_speed(_f, 0.5, 1.2, -0.002, 0);
    part_type_life(_f, 70, 120);
    global.amb_fumaca = _f;
    var _b = part_type_create();
    part_type_shape(_b, pt_shape_disk);
    part_type_blend(_b, true);
    part_type_color3(_b, make_color_rgb(235, 200, 255), make_color_rgb(190, 110, 255), make_color_rgb(150, 50, 255));
    part_type_alpha3(_b, 1, 0.8, 0);
    part_type_direction(_b, 70, 110, 0, 3);
    part_type_speed(_b, 0.9, 2.7, 0, 0);
    part_type_gravity(_b, 0.01, 90);
    part_type_life(_b, 40, 80);
    global.amb_brasa = _b;
}

// um sopro de fumaça ou um punhado de brasas (como fx_em, sem criar instância)
function amb_em(_tipo, _x, _y, _tam = 1)
{
    amb_particulas_iniciar();
    if (part_particles_count(global.amb_ps) >= AMB_TETO) return;
    var _q = global.cfg_qualidade;
    var _mult = (_q == 0) ? 0.4 : (_q == 1 ? 0.7 : 1);
    if (_tipo == "fumaca")
    {
        // o disco tem 64 px: tamanho 0,19..0,34 = raio de 6 a 11 px (vezes o tamanho da casa)
        part_type_size(global.amb_fumaca, 0.19 * _tam, 0.34 * _tam, 0.0035 * _tam, 0);
        repeat (max(1, round(3 * _tam * _mult)))
            part_particles_create(global.amb_ps, _x + random_range(-10, 10) * _tam, _y, global.amb_fumaca, 1);
    }
    else
    {
        part_type_size(global.amb_brasa, 0.03, 0.06, 0, 0);
        repeat (max(1, round(4 * _tam * _mult)))
            part_particles_create(global.amb_ps, _x + random_range(-16, 16) * _tam, _y, global.amb_brasa, 1);
    }
}

// avança as partículas de ambiente pelo dt do jogo (mesma velocidade a 30 e a 60
// FPS; param no impacto dos golpes como o resto do mundo)
function amb_atualizar()
{
    if (!variable_global_exists("amb_ps") or !part_system_exists(global.amb_ps)) return;
    global.amb_acc = min(global.amb_acc + global.dt, 3);
    while (global.amb_acc >= 1) { part_system_update(global.amb_ps); global.amb_acc -= 1; }
}

// =====================================================================
// v1.18: ORÇAMENTO DOS EFEITOS DE COMBATE
// Cada acerto criava faíscas + corte + explosão de fogo (+ corte em X, rajada,
// sangue) e um clarão. Acertando vários inimigos, ou em combos rápidos, tudo
// se empilhava no mesmo ponto: a tela ficava suja e o jogo engasgava.
//  * efeitos decorativos iguais quase no mesmo lugar e na mesma hora viram um só;
//  * quanto mais efeitos nos últimos instantes ("carga"), menos partículas cada
//    um solta; com a tela cheia, os decorativos são descartados;
//  * no máximo um clarão a cada FX_FLASH_MS.
// Os efeitos que AVISAM algo (aparar, escudo quebrando, ondas e rachaduras dos
// especiais, destrutíveis, ambiente da fase) nunca passam por aqui.
// =====================================================================
#macro FX_LIMITE     14     // carga a partir da qual as partículas começam a diminuir
#macro FX_MEIA_VIDA  350    // ms para a carga cair pela metade
#macro FX_PERTO      28     // px: dois efeitos iguais mais perto que isto viram um só...
#macro FX_PERTO_MS   90     // ...se nasceram com menos que isto de diferença
#macro FX_FLASH_MS   70
#macro FX_BASE       0.8    // menos partículas que antes mesmo com a tela vazia (poluição visual)

function fx_decorativo(_tipo)
{
    switch (_tipo)
    {
        case "faiscas_golpe": case "sangue": case "corte": case "corte_lua": case "corte_x":
        case "explosao_fogo": case "rajada": case "chamas_estouro": case "chamas_morte":
        case "fumaca_maldita_estouro": case "poeira":
            return true;
    }
    return false;    // chamas_corpo já tem limite próprio (scr_dano)
}

// Chamado no começo de obj_fx.fx_iniciar.
// Devolve o multiplicador de partículas do efeito; 0 = não criar.
function fx_orcamento(_tipo, _x, _y)
{
    if (!fx_decorativo(_tipo)) return 1;
    if (!variable_global_exists("fx_recentes"))
    {
        global.fx_recentes = [];
        global.fx_carga = 0;
        global.fx_carga_t = current_time;
        global.fx_flash_t = -1000;
    }
    var _agora = current_time;
    global.fx_carga *= power(0.5, (_agora - global.fx_carga_t) / FX_MEIA_VIDA);
    global.fx_carga_t = _agora;

    // repetido: mesmo tipo, mesmo lugar, agorinha (um golpe em vários alvos, multi-acerto)
    var _r = global.fx_recentes;
    for (var _i = array_length(_r) - 1; _i >= 0; _i--)
    {
        var _e = _r[_i];
        if (_agora - _e.t > FX_PERTO_MS) { array_delete(_r, _i, 1); continue; }
        if (_e.tipo == _tipo and abs(_e.x - _x) < FX_PERTO and abs(_e.y - _y) < FX_PERTO) return 0;
    }
    array_push(_r, { tipo: _tipo, x: _x, y: _y, t: _agora });
    global.fx_carga += 1;

    var _excesso = global.fx_carga / FX_LIMITE;
    // TODO(human): curva de corte. _excesso = 0 (tela calma) ... 1 (no limite) ... 2.5+ (lotada).
    // Hoje: partículas cheias até _excesso 1, caem até 30% e descarta acima de 2.5.
    if (_excesso >= 2.5) return 0;                      // tela cheia: só o essencial
    return FX_BASE * clamp(1.6 - 0.6 * _excesso, 0.3, 1);
}

// Clarões de impacto: um por vez (vários juntos estouravam a tela de branco)
function fx_flash_livre()
{
    if (!variable_global_exists("fx_flash_t")) global.fx_flash_t = -1000;
    if (current_time - global.fx_flash_t < FX_FLASH_MS) return false;
    global.fx_flash_t = current_time;
    return true;
}

// ---------------------------------------------------------------------
// BLOCO SÓLIDO de um objeto destrutível (caixote, parede, muralha mágica)
// O obj_solido é filho do obj_chao: jogador e inimigos sobem, andam e
// batem nele. Ele cobre exatamente a caixa de colisão do dono.
// ---------------------------------------------------------------------
function solido_criar(_x1, _y1, _x2, _y2)
{
    var _s = instance_create_depth(_x1, _y1, 0, obj_solido);
    _s.image_xscale = max(0.05, (_x2 - _x1) / 20);    // spr_chao tem 20 x 35
    _s.image_yscale = max(0.05, (_y2 - _y1) / 35);
    _s.dono = id;
    return _s;
}

// ---------------------------------------------------------------------
// TERRENO (estilo Castlevania): ABISMOS onde quem cai morre e PLATAFORMAS
// para pular por cima. A mesma tabela existe na versão Android (Godot).
//   chao: topo do chão da fase · abismos: [[x1, x2]] · plataformas: [[x1, x2, y_topo]]
// Vãos de até ~120 px (o pulo alcança ~200). Plataformas sobre chão ficam
// 88 px acima dele (o pulo cheio sobe ~98): por baixo sobram 72 px e o
// herói (66 px) passa sem enroscar.
// ---------------------------------------------------------------------
#macro PLATAFORMA_ALT 16
#macro DEGRAU_MAX 9          // degraus até esta altura são subidos andando (escadarias)
#macro PECA_ESC 0.7          // escala de desenho das peças do Alex (atlas pecas_fase1)

// v1.13 — FASE EM ANDARES (inspirada nas referências da equipe): além dos
// abismos e plataformas, a fase 1 ganhou caminhos por cima da rua:
//   escadas: [[x_chao, x_alto, y_alto]] degraus de madeira (8 px) que sobem andando do
//            chão (em x_chao) até y_alto (em x_alto; pode subir para a esquerda)
//   blocos:  [[x1, x2, y_topo]] torre de vigia de madeira (sólida) do topo até o chão
//   pontes:  [[x1, x2, y]] passarela de madeira de MÃO ÚNICA (obj_plataforma):
//            sobe-se pulando por baixo e desce-se com ▼ + PULO
//   ilhas:   [[x_centro, y_topo, "peça"]] ilha de terra flutuante (mão única)
//   plataformas: [[x1, x2, y, alto?]] laje sólida (alto = 1: andaime alto de madeira)
//   ruinas:  [["peça", x, espelho]] ruínas e pilares na frente das casas
//   mover:   [[objeto, x1, x2, x_novo, y_novo]] tira um inimigo da rua e põe no alto
//   caixotes: [[x, y]] caixotes com orbs nos caminhos de cima (recompensa)
//   arvores: [[x, espelho]] árvores assombradas (animadas) na estrada
//   remover: objetos de decoração que saem da fase (os pedaços de castelo)
function terreno_dados(_sala)
{
    if (_sala == Room1)
        return { chao: 693, madeira: true,
            abismos: [[1020, 1225], [4010, 4200]],             // v1.20: abismos maiores
            // v1.20: PONTES QUE DESABAM [x1, x2, "madeira" | "pedra"] e PISO FRÁGIL [x1, x2, y]
            pontes_queda: [[1335, 1545, "madeira"], [1785, 2122, "pedra"]],
            frageis: [[1062, 1104, 693], [1142, 1184, 693], [4050, 4092, 693], [4124, 4166, 693]],
            // (o forte de madeira 2120..2330 em y 360 é o chão da arena da chave)
            plataformas: [[1546, 1632, 605], [1700, 1776, 585], [950, 1250, 470, 1], [2120, 2330, 360]],
            escadas: [[318, 406, 605], [3442, 3530, 605]],
            blocos: [[3530, 3594, 605]],
            pontes: [[402, 700, 605], [3594, 3700, 605]],
            ilhas: [[775, 548, "chao15"], [890, 500, "chao17"], [1862, 540, "chao15"],
                    [3762, 585, "chao15"], [3862, 556, "chao17"]],
            // v1.14 — ESCALAR: [x, y do alto, y de baixo, "escada" | "corda" | "corrente",
            // saída no alto (-1 esquerda, 1 direita, 0 reto para cima)]
            escalar: [[1236, 470, 640, "corda", 0],            // corda pendurada no andaime (pula e agarra)
                      [2142, 590, 693, "escada", 1],           // sobe para as plataformas penduradas do forte
                      [2346, 360, 548, "corda", -1]],          // a corda até o alto do forte (a arena da chave)
            pontes_corda: [],                                  // v1.20: a ponte de corda deu lugar à ponte de madeira que desaba
            // plataformas penduradas: [x1, x2, y, y das cordas no alto, poste da forca (-1 = presa no forte)]
            suspensas: [[2142, 2212, 590, 376, -1], [2246, 2304, 540, 376, -1]],
            // a CHAVE DO PORTÃO: baú selado no alto do forte; ao chegar, os guardiões surgem
            chave: { bau: [2226, 360], arena: [2128, 2322, 360],
                     guardioes: [[obj_esqueleto, 2164], [obj_inimigo_01, 2296], [obj_aranha, 2250]] },
            portao: [2470],                                    // portão trancado no meio da fase
            ruinas: [],
            // v1.13: sem os pedaços de castelo espalhados pela vila (muralhas, torres,
            // colunas, balaustradas, portões em arco e as tochas presas neles)
            remover: [obj_muralha_fundo, obj_ruina_fundo, obj_coluna, obj_coluna_quebrada, obj_balaustrada, obj_portao, obj_tocha, obj_caverna],     // v1.19: sem o buraco de caverna
            // v1.14: inimigos espalhados pela fase (antes vinham em bandos de 3 a 5;
            // ninguém fica dentro das arenas do mini-chefe 2510..3150 e do chefe)
            mover: [[obj_inimigo_02, 3400, 3620, 3562, 584],
                    [obj_inimigo_01, 930, 940, 1600, 600], [obj_inimigo_01, 970, 980, 2200, 672], [obj_inimigo_01, 1985, 1995, 2300, 672],
                    [obj_besta_elite, 2060, 2080, 2380, 672], [obj_inimigo_03, 2150, 2170, 3740, 672],
                    [obj_estatua, 2250, 2275, 1738, 580], [obj_porco, 3180, 3192, 3250, 672],
                    [obj_esqueleto_elite, 3400, 3410, 3380, 672], [obj_esqueleto, 3280, 3292, 3930, 672],
                    [obj_aranha, 3445, 3460, 4270, 672]],
            caixotes: [[1090, 470], [1124, 470], [1180, 470]],
            arvores: [] };            // v1.13: sem árvores assombradas (pareciam outros chefes)
    if (_sala == Room2)
        return { chao: 682, madeira: false,
            abismos: [[1760, 1880], [3380, 3480], [3600, 3722]],
            plataformas: [[1792, 1848, 616], [2650, 2750, 594], [2790, 2880, 550], [3636, 3690, 620]],
            escalar: [[2786, 550, 682, "corrente", 1], [2646, 594, 682, "corrente", 1]],    // correntes do salão
            pontes_corda: [], suspensas: [], chave: undefined, portao: [], pontes_queda: [], frageis: [],
            escadas: [], blocos: [], pontes: [], ilhas: [], ruinas: [], mover: [], caixotes: [], arvores: [], remover: [] };
    return { chao: 0, madeira: false, abismos: [], plataformas: [], escadas: [], blocos: [], pontes: [], ilhas: [], ruinas: [], mover: [], caixotes: [], arvores: [], remover: [],
        escalar: [], pontes_corda: [], suspensas: [], chave: undefined, portao: [], pontes_queda: [], frageis: [] };
}

// Peças do Alex (paredes, ruínas, chão e ilhas): ferramentas/gerar_pecas.ps1
function pecas_carregar()
{
    if (variable_global_exists("pecas") and is_struct(global.pecas)) return true;
    if (!file_exists("pecas_fase1.json") or !file_exists("pecas_fase1.png")) return false;
    global.pecas_spr = sprite_add("pecas_fase1.png", 1, false, false, 0, 0);
    var _f = file_text_open_read("pecas_fase1.json");
    var _s = "";
    while (!file_text_eof(_f)) _s += file_text_readln(_f);
    file_text_close(_f);
    global.pecas = json_parse(_s).pecas;
    return true;
}

// [x, y, w, h] de uma peça no atlas (ou undefined)
function peca(_nome) { return global.pecas[$ _nome]; }

// desenha a peça com a base em (_x esquerda, _base); _esp espelha; _tom = cor
function peca_desenhar(_nome, _x, _base, _esp = false, _tom = c_white, _esc = PECA_ESC)
{
    var _p = peca(_nome);
    if (is_undefined(_p)) return;
    var _w = _p[2] * _esc, _h = _p[3] * _esc;
    if (_esp) draw_sprite_part_ext(global.pecas_spr, 0, _p[0], _p[1], _p[2], _p[3], _x + _w, _base - _h, -_esc, _esc, _tom, 1);
    else draw_sprite_part_ext(global.pecas_spr, 0, _p[0], _p[1], _p[2], _p[3], _x, _base - _h, _esc, _esc, _tom, 1);
}

// enche o retângulo com a peça repetida (alinhada ao mundo, para as peças
// vizinhas casarem); o fundo escuro vira a argamassa entre as pedras
function peca_encher(_nome, _x1, _y1, _x2, _y2, _tom = c_white)
{
    var _p = peca(_nome);
    if (is_undefined(_p) or _x2 <= _x1 or _y2 <= _y1) return;
    draw_set_color(make_color_rgb(30, 22, 22));
    draw_rectangle(_x1, _y1, _x2 - 1, _y2 - 1, false);
    var _tw = _p[2] * PECA_ESC, _th = _p[3] * PECA_ESC;
    var _gx = floor(_x1 / _tw) * _tw;
    for (var _x = _gx; _x < _x2; _x += _tw)
    {
        var _a = max(_x, _x1), _b = min(_x + _tw, _x2);
        if (_b <= _a) continue;
        for (var _y = _y1; _y < _y2; _y += _th)
        {
            var _hh = min(_th, _y2 - _y);
            draw_sprite_part_ext(global.pecas_spr, 0, _p[0] + (_a - _x) / PECA_ESC, _p[1], (_b - _a) / PECA_ESC, _hh / PECA_ESC, _a, _y, PECA_ESC, PECA_ESC, _tom, 1);
        }
    }
}

// tábuas verticais de madeira enchendo o retângulo (escadas e torre de vigia);
// _semente varia o tom das tábuas
function madeira_tabuas(_x1, _y1, _x2, _y2, _semente = 0)
{
    if (_x2 <= _x1 or _y2 <= _y1) return;
    draw_set_color(make_color_rgb(30, 20, 12));
    draw_rectangle(_x1, _y1, _x2 - 1, _y2 - 1, false);
    for (var _x = _x1; _x < _x2; _x += 8)
    {
        var _w = min(8, _x2 - _x);
        var _s = (floor(_x / 8) + _semente) mod 3;
        var _c = (_s == 0) ? make_color_rgb(92, 62, 38) : ((_s == 1) ? make_color_rgb(80, 54, 32) : make_color_rgb(100, 68, 42));
        var _c2 = merge_color(_c, c_black, 0.35);
        draw_rectangle_color(_x, _y1, _x + max(1, _w - 2), _y2 - 1, _c, _c, _c2, _c2, false);
    }
}
// ---------------------------------------------------------------------
// PLATAFORMAS DE MÃO ÚNICA (obj_plataforma): o herói sobe pulando por baixo,
// pousa em cima e desce com ▼ + PULO. O obj_plataforma NÃO é filho do
// obj_chao (não bate de lado nem por baixo); o topo é o y da instância.
// Os inimigos não usam (andam na rua).
// ---------------------------------------------------------------------
function plataforma_sob_pes()
{
    if (object_index != obj_player or atravessar_t > 0 or velv < 0) return noone;
    var _p = instance_place(x, y + 1, obj_plataforma);
    if (_p != noone and abs(y - _p.y) <= 1) return _p;
    return noone;
}

// plataforma onde o herói pousa ao cair _mv px neste passo (End Step do obj_entidade)
function plataforma_pouso(_mv)
{
    if (object_index != obj_player or _mv <= 0 or atravessar_t > 0) return noone;
    var _melhor = noone;
    var _l = bbox_left, _r = bbox_right, _y = y;
    with (obj_plataforma)
    {
        if (_r < bbox_left or _l > bbox_right) continue;
        if (_y <= y + 0.5 and _y + _mv >= y and (_melhor == noone or y < _melhor.y)) _melhor = id;
    }
    return _melhor;
}

function terreno_ponte(_x1, _x2, _y)
{
    var _b = instance_create_depth(_x1, _y, 0, obj_plataforma);
    _b.image_xscale = (_x2 - _x1) / 20;
    _b.image_yscale = 8 / 35;
    return _b;
}

// bloco sólido de _x1.._x2, de _y1 até _y2
function terreno_bloco(_x1, _x2, _y1, _y2)
{
    var _b = instance_create_depth(_x1, _y1, 0, obj_chao);
    _b.image_xscale = (_x2 - _x1) / 20;
    _b.image_yscale = (_y2 - _y1) / 35;
    return _b;
}

// degraus de 8 px do chão (_xa) até _y_alto (_xb)
function terreno_escada(_xa, _xb, _y_alto, _chao_y)
{
    var _n = max(1, round((_chao_y - _y_alto) / 8));
    var _lw = abs(_xb - _xa) / _n;
    for (var _k = 0; _k < _n; _k++)
    {
        var _x1 = (_xb > _xa) ? _xa + _k * _lw : _xa - (_k + 1) * _lw;
        terreno_bloco(_x1, _x1 + _lw, _chao_y - (_k + 1) * 8, _chao_y);
    }
}

// tira a decoração de chão que ficaria dentro de um bloco ou escada
function terreno_limpar(_x1, _x2)
{
    // os sólidos dos obstáculos (menos os caixotes, que continuam quebráveis)
    with (obj_solido) if (bbox_right > _x1 and bbox_left < _x2 and !(instance_exists(dono) and dono.object_index == obj_caixote)) instance_destroy();
    with (obj_mato) if (x > _x1 - 4 and x < _x2 + 4) instance_destroy(id, false);
    var _tipos = [obj_pedras, obj_tronco, obj_barril, obj_lampiao, obj_placa];
    for (var _k = 0; _k < array_length(_tipos); _k++)
        with (_tipos[_k]) if (x > _x1 - 10 and x < _x2 + 10) instance_destroy(id, false);
}

// Abre um abismo no chão entre _x1 e _x2: corta os blocos de chão (o do
// nível do chão e os de apoio embaixo) e tira a decoração que ficava ali
function terreno_abrir(_x1, _x2, _chao_y)
{
    var _cortar = [];
    with (obj_chao) if (object_index == obj_chao and image_xscale > 0 and y >= _chao_y - 4 and x < _x2 and x + 20 * image_xscale > _x1) array_push(_cortar, id);
    for (var _i = 0; _i < array_length(_cortar); _i++)
    {
        var _c = _cortar[_i];
        var _l = _c.x;
        var _r = _c.x + 20 * _c.image_xscale;
        var _t = _c.y;
        var _ys = _c.image_yscale;
        var _dep = _c.depth;
        instance_destroy(_c);
        if (_x1 > _l) { var _e = instance_create_depth(_l, _t, _dep, obj_chao); _e.image_xscale = (_x1 - _l) / 20; _e.image_yscale = _ys; }
        if (_r > _x2) { var _d = instance_create_depth(_x2, _t, _dep, obj_chao); _d.image_xscale = (_r - _x2) / 20; _d.image_yscale = _ys; }
    }
    // sólidos de obstáculos que ficavam no vão (pedras, troncos...)
    with (obj_solido) if (bbox_right > _x1 and bbox_left < _x2) instance_destroy();
    // mato e objetos de chão que ficariam flutuando sobre o abismo (sem soltar nada)
    with (obj_mato) if (x > _x1 - 6 and x < _x2 + 6) instance_destroy(id, false);
    var _tipos = [obj_pedras, obj_tronco, obj_barril, obj_lampiao, obj_placa];
    for (var _k = 0; _k < array_length(_tipos); _k++)
        with (_tipos[_k]) if (x > _x1 - 14 and x < _x2 + 14) instance_destroy(id, false);
}

// Bloco sólido de uma plataforma (pula-se nela; por baixo, bate a cabeça)
function terreno_plataforma(_x1, _x2, _y)
{
    var _b = instance_create_depth(_x1, _y, 0, obj_chao);
    _b.image_xscale = (_x2 - _x1) / 20;
    _b.image_yscale = PLATAFORMA_ALT / 35;
    return _b;
}

function solido_mover(_s, _x1, _y1)
{
    if (_s != noone and instance_exists(_s)) { _s.x = _x1; _s.y = _y1; }
}

function solido_remover(_s)
{
    if (_s != noone and instance_exists(_s)) instance_destroy(_s);
}

// ---------------------------------------------------------------------
// DESTRUTÍVEIS (executado na instância de obj_destrutivel)
// _forca: 1 golpe normal, 2 golpe pesado / onda, 3 especial em área
// ---------------------------------------------------------------------
function destrutivel_bater(_forca, _origem_x)
{
    if (quebrado or vida <= 0) return;
    if (!pode_bater()) return;
    vida -= _forca;
    tremor = 6;
    flash = 6;
    lado_golpe = sign(x - _origem_x);
    if (lado_golpe == 0) lado_golpe = 1;
    if (vida <= 0)
    {
        quebrado = true;
        ao_quebrar(lado_golpe);
    }
    else ao_bater(_forca);
}

// Caixote: o que tem dentro
//  "nada", "orbs" (orbs_valor) ou "bau" (um baú de vida escondido)
function caixote_quebrar(_lado)
{
    som_em("dest_madeira", x, y, 1);           // destruição: madeira
    fx_em("lascas", x, y - 16, 1.1, _lado);
    fx_em("poeira", x, y, 0.7, _lado);
    global.camera_impact = max(global.camera_impact, 3);
    if (conteudo == "orbs") orbs_soltar(x, y - 18, orbs_valor);
    if (random(1) < 0.2) essencia_soltar(x, y - 20, 1);       // v1.12: às vezes um cristal de essência
    if (bau != noone and instance_exists(bau)) with (bau) bau_revelar();
    solido_remover(solido);
    solido = noone;
    instance_destroy();
}

// ---------------------------------------------------------------------
// BAÚ DE VIDA (executado no obj_bau)
// ---------------------------------------------------------------------
function bau_revelar()
{
    if (visivel) return;
    visivel = true;
    revelar_t = 30;
    som_em("sfx_cura", x, y, 0.4);
}

// Twilight abre o baú: animação da tampa, depois a magia flui para ele
// v1.14: a CHAVE DO PORTÃO desenhada por código (argola, haste e dentes, dourada);
// _giro (-1..1) achata na horizontal para parecer que ela gira no ar
function desenhar_chave(_x, _y, _esc = 1, _giro = 1)
{
    var _sx = max(0.15, abs(_giro)) * _esc;
    var _ouro = make_color_rgb(236, 186, 70);
    draw_set_color(make_color_rgb(140, 92, 26));
    draw_ellipse(_x - 6 * _sx, _y - 12 * _esc, _x + 6 * _sx, _y - 1 * _esc, false);
    draw_set_color(_ouro);
    draw_ellipse(_x - 5 * _sx, _y - 11 * _esc, _x + 5 * _sx, _y - 2 * _esc, false);
    draw_set_color(make_color_rgb(40, 24, 10));
    draw_ellipse(_x - 2 * _sx, _y - 8 * _esc, _x + 2 * _sx, _y - 5 * _esc, false);
    draw_set_color(_ouro);
    draw_rectangle(_x - 1.2 * _sx, _y - 2 * _esc, _x + 1.2 * _sx, _y + 12 * _esc, false);
    draw_rectangle(_x + 1.2 * _sx, _y + 7 * _esc, _x + 5 * _sx, _y + 9 * _esc, false);
    draw_rectangle(_x + 1.2 * _sx, _y + 10.5 * _esc, _x + 4 * _sx, _y + 12 * _esc, false);
    draw_set_color(make_color_rgb(255, 240, 190));
    draw_line(_x - 3 * _sx, _y - 10 * _esc, _x - 1 * _sx, _y - 11 * _esc);
    draw_set_color(c_white);
}

function bau_abrir(_jogador)
{
    if (estado != "fechado" or !visivel) return;
    if (selado) { aviso_mostrar("O BAÚ ESTÁ SELADO  ·  DERROTE OS GUARDIÕES"); return; }
    if (conteudo == "chave") chave_voo = 0;
    estado = "abrindo";
    t = 0;
    alvo = _jogador;
    aberto_marcar(chave);
    som_em("sfx_bau", x, y, 1, 0);
    global.camera_impact = max(global.camera_impact, 3);
}

// ---------------------------------------------------------------------
// ARENA: muralhas mágicas que fecham uma área (mini-boss e boss)
// ---------------------------------------------------------------------
// Ergue as duas muralhas em _x1 e _x2. Retorna [esquerda, direita].
function arena_fechar(_x1, _x2, _y_chao, _dono)
{
    var _e = instance_create_depth(_x1, _y_chao, -60, obj_parede_magica);
    var _d = instance_create_depth(_x2, _y_chao, -60, obj_parede_magica);
    _e.dono = _dono; _e.lado = -1;
    _d.dono = _dono; _d.lado = 1;
    with (_e) parede_erguer();
    with (_d) parede_erguer();
    global.cam_lim_esq = _x1 - 30;
    global.cam_lim_dir = _x2 + 30;
    // v1.12: luta de chefe sem inimigos comuns. Quem estiver dentro da arena
    // se desfaz na fumaça da maldição (sem orbs e sem contar como derrotado).
    with (obj_inimigo_base)
    {
        if (id == _dono or eh_boss or morrendo or object_index == obj_mini_boss or x <= _x1 or x >= _x2) continue;
        fx_em("chamas_estouro", x, y - 30, 1);
        instance_destroy();
    }
    som("sfx_portal", 0.9, 0);
    global.camera_impact = max(global.camera_impact, 8);
    return [_e, _d];
}

function arena_abrir(_dono)
{
    with (obj_parede_magica) if (dono == _dono) parede_baixar();
    global.cam_lim_esq = 0;
    global.cam_lim_dir = room_width;
}

// Posição x mais próxima dentro da arena ativa do dono (ou _x se não houver)
function arena_limitar_x(_x, _margem = 30)
{
    var _r = _x;
    with (obj_parede_magica)
    {
        if (!ativa) continue;
        if (lado < 0) _r = max(_r, x + _margem);
        else _r = min(_r, x - _margem);
    }
    return _r;
}

// ---------------------------------------------------------------------
// LIMPEZA DA SALA AO VOLTAR DO CHECKPOINT
// Os inimigos que ficaram para trás do checkpoint não voltam (corpos e
// orbs não "renascem"); caixotes e segredos já usados também somem.
// ---------------------------------------------------------------------
function sala_limpar_checkpoint()
{
    if (!global.checkpoint_ativo or global.checkpoint_room != room) return;
    var _cx = global.checkpoint_x;
    with (obj_inimigo_base)
    {
        if (!eh_boss and !invocado and object_index != obj_mini_boss and x < _cx - 280) instance_destroy();
    }
    with (obj_mini_boss) if (x < _cx - 280) instance_destroy();
    with (obj_viga_fogo) if (x < _cx - 200) instance_destroy();
}

// ---------------------------------------------------------------------
// ARMADILHAS: ferem o jogador (não dá para defender) e também os inimigos
// _lista = inimigos já atingidos nesta ativação
// ---------------------------------------------------------------------
#macro ARMADILHA_FERE_INIMIGOS false
function armadilha_area(_x1, _y1, _x2, _y2, _dano_jogador, _dano_inimigo, _lista, _forca = 4)
{
    var _p = instance_find(obj_player, 0);
    if (_p != noone and !_p.morto and rectangle_in_rectangle(_x1, _y1, _x2, _y2, _p.bbox_left, _p.bbox_top, _p.bbox_right, _p.bbox_bottom))
    {
        var _antes = _p.vida;
        with (_p) levar_dano(max(1, round(_dano_jogador * dif_dano_inimigo())), (_x1 + _x2) / 2, false, _forca, noone);
        if (_p.vida < _antes and !_p.morto) _p.velv = min(_p.velv, -3);
    }
    // v1.12: as armadilhas não ferem mais os inimigos (pedido dos testes): elas
    // ficam em trechos próprios do mapa e não se misturam com as lutas.
    // Para voltar ao jeito antigo, troque ARMADILHA_FERE_INIMIGOS para true.
    if (_dano_inimigo <= 0 or !ARMADILHA_FERE_INIMIGOS) return;
    var _l = ds_list_create();
    var _n = collision_rectangle_list(_x1, _y1, _x2, _y2, obj_inimigo_base, false, true, _l, false);
    for (var _i = 0; _i < _n; _i++)
    {
        var _e = _l[| _i];
        if (_e.morrendo or !_e.ativo or _e.eh_boss or array_tem(_lista, _e)) continue;
        array_push(_lista, _e);
        with (_e) levar_dano(_dano_inimigo, (_x1 + _x2) / 2, false, 3, noone);
    }
    ds_list_destroy(_l);
}

// Chamas desenhadas por código (fogo no chão, vigas e casas)
// _larg = largura, _alt = altura das chamas, _t = tempo, _forca 0..1
// _paleta (v1.12): 0 = CHAMA MALDITA de Vallack (roxa: a chuva não apaga)
//                  1 = CHAMA DE SYLLA (dourada: a magia de Twilight)
//                  2 = fogo comum (laranja)
function chamas_cores(_paleta)
{
    switch (_paleta)
    {
        case 1:  return [make_color_rgb(200, 120, 10), make_color_rgb(255, 200, 60), make_color_rgb(255, 250, 200), make_color_rgb(255, 200, 80)];
        case 2:  return [make_color_rgb(200, 40, 10), make_color_rgb(255, 120, 30), make_color_rgb(255, 220, 120), make_color_rgb(255, 110, 30)];
    }
    return [make_color_rgb(110, 20, 170), make_color_rgb(190, 70, 255), make_color_rgb(240, 200, 255), make_color_rgb(160, 60, 255)];
}
// Cor da luz que a chama maldita joga nas paredes e no chão
function cor_chama_maldita() { return make_color_rgb(165, 80, 255); }

// ---------------------------------------------------------------------
// CENÁRIO DA FASE 1 desenhado por código (ferramentas/gerar_cenario.ps1):
// atlas cenario_fase1.png + cenario_fase1.json (peças, âncoras dos efeitos
// e disposição da fase). Carregado uma vez e guardado em global.cen.
// ---------------------------------------------------------------------
function cenario_carregar()
{
    if (variable_global_exists("cen") and is_struct(global.cen)) return true;
    if (!file_exists("cenario_fase1.json") or !file_exists("cenario_fase1.png")) return false;
    global.cen_spr = sprite_add("cenario_fase1.png", 1, false, false, 0, 0);
    var _f = file_text_open_read("cenario_fase1.json");
    var _s = "";
    while (!file_text_eof(_f)) _s += file_text_readln(_f);
    file_text_close(_f);
    global.cen = json_parse(_s);
    return true;
}

// desenha uma peça com a base (pé) em _base; _esp = espelhada; _s = escala
// (v1.17: as casas do cenário com o dobro do tamanho, pixel art nítida)
function cenario_peca(_p, _x, _base, _esp, _cor = c_white, _s = 1)
{
    var _y = _base - _p.h * _s;
    if (_esp) draw_sprite_part_ext(global.cen_spr, 0, _p.x, _p.y, _p.w, _p.h, _x + _p.w * _s, _y, -_s, _s, _cor, 1);
    else draw_sprite_part_ext(global.cen_spr, 0, _p.x, _p.y, _p.w, _p.h, _x, _y, _s, _s, _cor, 1);
}

// x de uma âncora da peça no mundo (respeita o espelho e a escala)
function cenario_ax(_p, _x, _esp, _ax, _s = 1) { return _esp ? _x + (_p.w - _ax) * _s : _x + _ax * _s; }

// faixa distante que se repete e anda mais devagar que a câmera (parallax)
//  _fx: 0 = presa à câmera, 1 = presa ao mundo · _deriva: deslocamento extra (nuvens)
function cenario_faixa(_p, _vx, _vw, _fx, _yb, _deriva = 0)
{
    var _ox = _vx * (1 - _fx) - _deriva;
    var _ini = _ox + floor((_vx - _ox) / _p.w) * _p.w;
    for (var _x = _ini; _x < _vx + _vw; _x += _p.w)
        draw_sprite_part_ext(global.cen_spr, 0, _p.x, _p.y, _p.w, _p.h, round(_x), round(_yb - _p.h), 1, 1, c_white, 1);
}

// =====================================================================
// v1.19: FOGO COM LÓGICA DE INCÊNDIO. Antes as chamas eram uma fileira de
// triângulos iguais sobre uma reta (um "pente" por cima de cada casa). Agora:
//  * cada chama é uma LÍNGUA (base larga, cintura, ponta torta que some no ar);
//  * as chamas nascem ao longo de uma LINHA da construção (beiral, água do
//    telhado, borda quebrada, escombros), saem dos ROMBOS e das JANELAS;
//  * a altura varia sem simetria ao longo da linha, o vento deita as pontas
//    para o mesmo lado e labaredas soltas sobem e se apagam.
// O mesmo em lib.gd (Android).
// =====================================================================
// hash 0..1 (a mesma fórmula no Godot)
function chama_hash(_a, _b)
{
    var _v = sin(_a * 12.9898 + _b * 78.233) * 43758.5453;
    return _v - floor(_v);
}

// uma língua de fogo dentro de draw_primitive_begin(pr_trianglelist): uma gota
// de 5 pontos em leque — a base fraca (funde com o que queima), a barriga larga
// e forte e a ponta torta que some no ar
function chama_lingua(_bx, _by, _w, _h, _lean, _cb, _ct, _a)
{
    var _x0 = _bx - _w * 0.9, _x1 = _bx + _w * 0.9;              // base (encosta na vizinha)
    var _yb = _by - _h * 0.28, _xb = _bx + _lean * 0.18;         // barriga
    var _xt = _bx + _lean, _yt = _by - _h;                       // ponta
    var _ab = _a * 0.5;
    // leque a partir da base esquerda: B0 B1 BarD Ponta BarE
    draw_vertex_colour(_x0, _by, _cb, _ab); draw_vertex_colour(_x1, _by, _cb, _ab); draw_vertex_colour(_xb + _w, _yb, _ct, _a);
    draw_vertex_colour(_x0, _by, _cb, _ab); draw_vertex_colour(_xb + _w, _yb, _ct, _a); draw_vertex_colour(_xt, _yt, _ct, 0);
    draw_vertex_colour(_x0, _by, _cb, _ab); draw_vertex_colour(_xt, _yt, _ct, 0); draw_vertex_colour(_xb - _w, _yb, _ct, _a);
}

// o fogo ao longo da linha (_x1,_y1)-(_x2,_y2); as chamas sempre sobem.
//  _tipo: 0 telhado / borda, 1 rombo (labareda), 2 janela (vão aceso + línguas
//  saindo da verga; a linha é o retângulo do vão), 3 escombros (baixas, com falhas)
//  _alt: altura já na escala do mundo · _esc: escala da peça (espaço e largura das línguas) · _lod: 0 completo, 1 sem a camada do meio, 2 também sem labaredas soltas
function chamas_linha(_x1, _y1, _x2, _y2, _alt, _t, _forca, _sem, _paleta = 0, _tipo = 0, _esc = 1, _lod = 0)
{
    if (_forca <= 0.01) return;
    var _pc = chamas_cores(_paleta);
    // v1.19: em LOTE (chamas_lote_desenhar) o blend aditivo e a primitiva já estão
    // abertos por quem chamou: tudo vira vértice de uma primitiva só
    var _lote = variable_global_exists("chamas_lote") and global.chamas_lote;
    if (!_lote) gpu_set_blendmode(bm_add);
    var _pulso = 1;
    if (_tipo == 2)
    {
        // o vão da janela: o fogo lá dentro ilumina de baixo, tremendo
        var _jx1 = min(_x1, _x2), _jx2 = max(_x1, _x2), _jw = _jx2 - _jx1, _jh = _y2 - _y1;
        var _fj = 0.6 + 0.4 * sin(_t * 0.31 + _sem) * sin(_t * 0.13 + _sem * 3);
        // escuro em cima, aceso embaixo (onde está o fogo)
        var _a1 = 0.3 * _forca * _fj, _a2 = 0.45 * _forca * _fj;
        if (!_lote) draw_primitive_begin(pr_trianglelist);
        draw_vertex_colour(_jx1, _y1, _pc[0], _a1); draw_vertex_colour(_jx2, _y1, _pc[0], _a1); draw_vertex_colour(_jx2, _y2, _pc[1], _a2);
        draw_vertex_colour(_jx1, _y1, _pc[0], _a1); draw_vertex_colour(_jx2, _y2, _pc[1], _a2); draw_vertex_colour(_jx1, _y2, _pc[1], _a2);
        // a chama dentro do cômodo, vista pelo vão
        if (_lod == 0) chama_lingua((_jx1 + _jx2) / 2, _y2, _jw * 0.28, _jh * (0.55 + 0.3 * _fj), _jh * 0.12, _pc[1], _pc[2], 0.4 * _forca);
        if (!_lote) draw_primitive_end();
        // e de vez em quando ela lambe para fora pela verga e sobe pela parede
        _pulso = clamp(sin(_t * 0.045 + _sem * 2.3) * 1.5 + 0.35, 0, 1);
        _y2 = _y1;
    }
    var _len = point_distance(_x1, _y1, _x2, _y2);
    var _passo = ((_tipo == 3) ? 6 : 9) * _esc * (1 + _lod * 0.5);
    var _n = (_tipo == 1) ? 3 : ((_tipo == 2) ? 1 : max(2, round(_len / _passo)));
    var _vel = (_tipo == 1) ? 1.5 : 1;
    if (!_lote) draw_primitive_begin(pr_trianglelist);
    if (_tipo == 1)
    {
        // o calor saindo do rombo: um brilho baixo, com a borda sumindo (leque de triângulos)
        var _gcx = (_x1 + _x2) / 2, _gcy = (_y1 + _y2) / 2 - _alt * 0.2;
        var _grx = _len / 2 + 5 * _esc, _gry = _alt * 0.32 + 2 * _esc;
        for (var _gs = 0; _gs < 10; _gs++)
        {
            var _a0 = _gs / 10 * 2 * pi, _a9 = (_gs + 1) / 10 * 2 * pi;
            draw_vertex_colour(_gcx, _gcy, _pc[3], 0.12 * _forca);
            draw_vertex_colour(_gcx + cos(_a0) * _grx, _gcy + sin(_a0) * _gry, _pc[3], 0);
            draw_vertex_colour(_gcx + cos(_a9) * _grx, _gcy + sin(_a9) * _gry, _pc[3], 0);
        }
    }
    if (_tipo != 2)
    {
        // a faixa em brasa ao longo da linha: as línguas brotam dela (não ficam soltas)
        var _hb = _alt * _forca * (0.22 + 0.06 * sin(_t * 0.17 + _sem));
        var _ex = (_tipo == 1) ? 2 * _esc : 0;
        draw_vertex_colour(_x1 - _ex, _y1 + _esc, _pc[1], 0.42 * _forca); draw_vertex_colour(_x2 + _ex, _y2 + _esc, _pc[1], 0.42 * _forca); draw_vertex_colour(_x2 + _ex, _y2 - _hb, _pc[0], 0);
        draw_vertex_colour(_x1 - _ex, _y1 + _esc, _pc[1], 0.42 * _forca); draw_vertex_colour(_x2 + _ex, _y2 - _hb, _pc[0], 0); draw_vertex_colour(_x1 - _ex, _y1 - _hb, _pc[0], 0);
    }
    for (var _i = 0; _i < _n; _i++)
    {
        var _h1 = chama_hash(_i + 1, _sem), _h2 = chama_hash(_i + 7, _sem * 1.7 + 0.3), _h3 = chama_hash(_i + 13, _sem * 0.3 + 0.7);
        if (_tipo == 3 and _h3 < 0.22) continue;          // escombros: falhas entre os focos
        var _u = clamp((_i + 0.5 + (_h1 - 0.5) * 0.7) / _n, 0, 1);
        var _bx = lerp(_x1, _x2, _u), _by = lerp(_y1, _y2, _u);
        // altura irregular ao longo da linha (sem simetria) e viva no tempo
        var _env = 0.55 + 0.45 * (0.5 + 0.5 * sin(_u * 5.3 + _sem * 1.3) * sin(_u * 2.1 + _sem * 0.7 + 1.1));
        var _ponta = min(1, min(_u, 1 - _u) * 5 + 0.35);   // nas pontas da linha o fogo é mais baixo
        if (_tipo == 1) { _env = (_i == 1) ? 1 : 0.6; _ponta = 1; }
        if (_tipo == 2) _ponta = 1;
        var _fl = 0.7 + 0.3 * (0.6 * sin(_t * 0.23 * _vel + _h1 * 6.28) + 0.4 * sin(_t * 0.57 * _vel + _h2 * 6.28));
        var _h = _alt * _forca * _env * _ponta * _fl * _pulso * (0.6 + 0.8 * _h2);     // _alt já vem na escala
        if (_h < 2) continue;
        var _w = ((_tipo == 1) ? _len / 2.4 + 2 * _esc : ((_tipo == 2) ? max(_len / 3, 2 * _esc) : _passo * 0.75)) * (0.7 + 0.6 * _h3);
        _w = min(_w, _h * 0.42);                                                  // chama é mais alta que larga
        var _lean = _h * (0.16 + 0.12 * sin(_t * 0.11 * _vel + _h1 * 9));     // o vento deita as pontas para a direita
        chama_lingua(_bx, _by + _esc, _w, _h, _lean, _pc[0], _pc[1], 0.62 * _forca);
        if (_lod == 0) chama_lingua(_bx, _by + _esc * 0.5, _w * 0.55, _h * 0.72, _lean * 0.7, _pc[1], _pc[2], 0.6 * _forca);
        // o miolo claro: um triângulo só; de longe nem aparece
        if (_lod < 2)
        {
            draw_vertex_colour(_bx - _w * 0.28, _by, _pc[2], 0.42 * _forca);
            draw_vertex_colour(_bx + _w * 0.28, _by, _pc[2], 0.42 * _forca);
            draw_vertex_colour(_bx + _lean * 0.3, _by - _h * 0.36, _pc[2], 0.42 * _forca);
        }
        // labareda que se solta da ponta, sobe e se apaga
        if (_lod < 2 and _h1 < 0.3 and _h > 10 * _esc)
        {
            var _ph = frac(_t * 0.018 * _vel + _h2);
            chama_lingua(_bx + _lean * (1 + _ph), _by - _h * (0.95 + _ph * 0.7), _w * 0.35 * (1 - _ph), _h * 0.3 * (1 - _ph), _lean * 0.2, _pc[1], _pc[2], 0.6 * _forca * (1 - _ph));
        }
    }
    if (_lote) return;
    draw_primitive_end();
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// v1.19: desenha uma fila de focos [x1,y1,x2,y2,alt,t,forca,sem,paleta,tipo,esc,lod]
// numa ÚNICA primitiva aditiva (antes: 2 a 3 lotes por foco, ~200 por quadro na vila)
function chamas_lote_desenhar(_fila)
{
    if (array_length(_fila) == 0) return;
    gpu_set_blendmode(bm_add);
    global.chamas_lote = true;
    draw_primitive_begin(pr_trianglelist);
    for (var _i = 0; _i < array_length(_fila); _i++)
    {
        var _a = _fila[_i];
        chamas_linha(_a[0], _a[1], _a[2], _a[3], _a[4], _a[5], _a[6], _a[7], _a[8], _a[9], _a[10], _a[11]);
    }
    draw_primitive_end();
    global.chamas_lote = false;
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// chamas numa faixa reta (fogo no chão, vigas, tochas, braseiros): as línguas
// novas, mais o brilho no chão
function desenhar_chamas(_x, _y, _larg, _alt, _t, _forca = 1, _semente = 0, _paleta = 0)
{
    if (_forca <= 0.01) return;
    var _pc = chamas_cores(_paleta);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.22 * _forca);
    draw_set_color(_pc[3]);
    draw_ellipse(_x - _larg * 0.7, _y - 6, _x + _larg * 0.7, _y + 4, false);
    chamas_linha(_x - _larg / 2, _y, _x + _larg / 2, _y, _alt * 1.25, _t, _forca, _semente, _paleta, 0, max(0.5, min(1.4, _larg / 40)));
}

// =====================================================================
// v1.11 — CENÁRIO MONTÁVEL
// Muralhas, colunas, portões, caverna, tochas, lampiões, placas, barris,
// troncos, pedras e balaustrada. As muralhas e colunas são desenhadas
// pedra por pedra (32 px): na sala, a Escala X / Escala Y diz quantas
// pedras de largura e de altura. Tudo é desenhado só quando está na tela.
// =====================================================================

// Tom das peças que ficam ao fundo (mais escuras que o plano do jogador)
function cenario_tom_fundo() { return make_color_rgb(150, 140, 138); }

// Medidas em pedras a partir da escala que a equipe pôs na sala
function cenario_medidas()
{
    colunas = max(1, round(abs(image_xscale)));
    linhas = max(1, round(abs(image_yscale)));
    semente = abs(round(x * 7 + y * 3)) mod 97;
}

// A faixa _x1.._x2 aparece na tela? (com folga)
function cenario_na_tela(_x1, _x2, _folga = 96)
{
    if (view_camera[0] == -1) return true;
    var _vx = camera_get_view_x(view_camera[0]);
    var _vw = camera_get_view_width(view_camera[0]);
    return (_x2 >= _vx - _folga and _x1 <= _vx + _vw + _folga);
}

// Distância do jogador até (_x, _y); muito grande se não houver jogador
function cenario_dist_jogador(_x, _y)
{
    var _p = instance_find(obj_player, 0);
    if (_p == noone) return 100000;
    return point_distance(_x, _y, _p.x, _p.y - 30);
}

// MURALHA (executado na instância). _tipo: "solida" (topo liso para andar),
// "fundo" (ameias; torres estreitas e altas ganham seteiras acesas; muretas
// de 1 ou 2 pedras ficam sem ameias) ou "ruina" (topo quebrado).
// Origem embaixo à esquerda.
function muralha_desenhar(_tipo, _cor)
{
    if (!cenario_na_tela(x, x + 32 * colunas)) return;
    for (var _c = 0; _c < colunas; _c++)
    {
        var _px = x + 32 * _c;
        for (var _r = 0; _r < linhas; _r++)
        {
            var _py = y - 32 * _r;
            if (_r == linhas - 1)
            {
                if (_tipo == "ruina")
                {
                    // topo quebrado (espelhado em colunas alternadas para não repetir)
                    if ((_c + semente) mod 2 == 1) draw_sprite_ext(spr_muralha, 4, _px + 32, _py, -1, 1, 0, _cor, 1);
                    else draw_sprite_ext(spr_muralha, 4, _px, _py, 1, 1, 0, _cor, 1);
                }
                else draw_sprite_ext(spr_muralha, 2, _px, _py, 1, 1, 0, _cor, 1);
            }
            else
            {
                var _f = ((_c * 7 + _r * 13 + semente) mod 5 == 0) ? 1 : 0;
                draw_sprite_ext(spr_muralha, _f, _px, _py, 1, 1, 0, _cor, 1);
            }
        }
        // ameias em cima da laje
        if (_tipo == "fundo" and linhas >= 3) draw_sprite_ext(spr_muralha, 3, _px, y - 32 * linhas + 3, 1, 1, 0, _cor, 1);
    }
    // seteiras acesas pelo incêndio (torres de até 3 pedras de largura e 6 ou mais de altura)
    if (_tipo == "fundo" and colunas <= 3 and linhas >= 6)
    {
        var _sx = x + 16 * colunas - 16;
        var _n = (linhas >= 9) ? 2 : 1;
        for (var _k = 0; _k < _n; _k++)
        {
            var _sy = y - 32 * (linhas - 3 - 3 * _k);
            draw_sprite_ext(spr_muralha, 5, _sx, _sy, 1, 1, 0, _cor, 1);
            gpu_set_blendmode(bm_add);
            draw_set_alpha(0.16 + 0.07 * sin(current_time / 170 + semente + _k * 2));
            draw_set_color(make_color_rgb(255, 120, 40));
            draw_ellipse(_sx + 2, _sy - 32, _sx + 30, _sy, false);
            gpu_set_blendmode(bm_normal);
            draw_set_alpha(1);
        }
    }
}

// COLUNA (origem embaixo no meio): base, fuste, capitel (ou topo quebrado)
function coluna_desenhar(_quebrada, _cor)
{
    if (!cenario_na_tela(x - 16, x + 16)) return;
    for (var _r = 0; _r < linhas; _r++)
    {
        var _f = 1;
        if (_r == 0) _f = 0;
        if (_r == linhas - 1) _f = _quebrada ? 3 : 2;
        if (linhas == 1) _f = _quebrada ? 3 : 0;
        draw_sprite_ext(spr_coluna, _f, x, y - 32 * _r, 1, 1, 0, _cor, 1);
    }
}

// Brilho de uma chama / lanterna (luz que pinta a parede em volta)
function cenario_luz(_x, _y, _raio, _forca, _cor)
{
    if (_forca <= 0.01) return;
    gpu_set_blendmode(bm_add);
    draw_set_color(_cor);
    draw_set_alpha(0.07 * _forca);
    draw_ellipse(_x - _raio, _y - _raio * 0.85, _x + _raio, _y + _raio * 0.85, false);
    draw_set_alpha(0.1 * _forca);
    draw_ellipse(_x - _raio * 0.55, _y - _raio * 0.45, _x + _raio * 0.55, _y + _raio * 0.45, false);
    draw_set_alpha(0.16 * _forca);
    draw_ellipse(_x - _raio * 0.22, _y - _raio * 0.2, _x + _raio * 0.22, _y + _raio * 0.2, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// PLACAS: o aviso de cada placa é o do ponto mais perto dela na lista.
// Para uma placa nova, acrescente [x, "texto"] aqui (\n quebra a linha).
function placa_texto(_x)
{
    var _lista = [
        [300,  "VILA DE SYLLA\nA maldição chegou com a tempestade."],
        [1456, "PERIGO!\nEspinhos e vigas em chamas adiante."],
        [2408, "PORTÃO DO BASTIÃO\nA chave ficou no forte de madeira, lá no alto."],
        [3640, "ESTRADA DE VALLACK\nA Árvore Amaldiçoada guarda o caminho."]
    ];
    var _melhor = "";
    var _dmin = 1000000;
    for (var _i = 0; _i < array_length(_lista); _i++)
    {
        var _d = abs(_lista[_i][0] - _x);
        if (_d < _dmin) { _dmin = _d; _melhor = _lista[_i][1]; }
    }
    return _melhor;
}

// Aviso em pergaminho acima da placa (_cx, _base = embaixo do pergaminho)
function placa_desenhar_aviso(_cx, _base, _texto, _alpha)
{
    if (_alpha <= 0.01 or _texto == "") return;
    var _e = fonte_escala(FONTE.MINI) * 0.5;
    fonte_usar(FONTE.MINI);
    var _s = texto_seguro(_texto);
    var _w = string_width(_s) * _e + 22;
    var _h = string_height(_s) * _e + 12;
    var _sobe = (1 - _alpha) * 8;
    var _x1 = _cx - _w / 2;
    var _x2 = _cx + _w / 2;
    var _y2 = _base - _sobe;
    var _y1 = _y2 - _h;
    // sombra, papel e borda
    draw_set_alpha(0.35 * _alpha);
    draw_set_color(c_black);
    draw_rectangle(_x1 + 3, _y1 + 3, _x2 + 3, _y2 + 3, false);
    retangulo_gradiente(_x1, _y1, _x2, _y2, make_color_rgb(236, 214, 168), _alpha, make_color_rgb(196, 160, 104), _alpha);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(92, 58, 26));
    draw_rectangle(_x1, _y1, _x2, _y2, true);
    // pontinha apontando para a placa
    draw_set_color(make_color_rgb(196, 160, 104));
    draw_triangle(_cx - 5, _y2, _cx + 5, _y2, _cx, _y2 + 6, false);
    gpu_set_texfilter(true);
    txt(_cx, (_y1 + _y2) / 2, _texto, FONTE.MINI, make_color_rgb(54, 30, 12), _alpha, fa_center, fa_middle, 0.5);
    gpu_set_texfilter(false);
    desenho_resetar();
}

// =====================================================================
// v1.20 — PONTES QUE DESABAM e PISO FRÁGIL (o mesmo da versão Android)
//  Ponte: tabuleiro sólido em PQ_TRECHOS trechos sobre um abismo fundo. Quando
//  o herói entra nela, um aviso (tremor, poeira, som) e a ponte começa a cair do
//  lado por onde ele entrou: a frente do desabamento corre um pouco mais
//  devagar que Twilight. Quem para, cai junto.
//  Piso frágil: laje de mão única sobre um buraco; treme enquanto o herói
//  está em cima e cai depois de FRAGIL_TEMPO quadros; volta mais tarde.
//  Todas estas funções rodam dentro do obj_terreno.
// =====================================================================
#macro PQ_TRECHOS 9
#macro PQ_AVISO 22
#macro PQ_FUNDO 250
#macro FRAGIL_TEMPO 34
#macro FRAGIL_VOLTA 170

// leva um objeto de chão (e o seu bloco sólido) para a beira do vão
function quedas_levar(_nx)
{
    var _dx = _nx - x;
    x = _nx;
    xstart = x;
    if (variable_instance_exists(id, "solido") and solido != noone and instance_exists(solido)) solido.x += _dx;
}

// antes de abrir os abismos: o que ficava em cima de um buraco novo vai para a beira
function quedas_preparar()
{
    var _cy = chao_y;
    var _tipos = [obj_bau, obj_caixote, obj_barril, obj_fogo_chao, obj_viga_fogo, obj_espinhos, obj_nevoa_veneno, obj_save_point];
    for (var _i = 0; _i < array_length(abismos); _i++)
    {
        var _a = abismos[_i];
        for (var _k = 0; _k < array_length(_tipos); _k++)
            with (_tipos[_k]) if (x > _a[0] - 20 and x < _a[1] + 20 and y > _cy - 60) quedas_levar(_a[0] - 50);
    }
    for (var _i = 0; _i < array_length(pontes_queda); _i++)
    {
        var _pq = pontes_queda[_i];
        for (var _k = 0; _k < array_length(_tipos); _k++)
            with (_tipos[_k]) if (x > _pq[0] - 24 and x < _pq[1] + 24 and y > _cy - 60) quedas_levar(_pq[0] - 60);
    }
}

function quedas_montar()
{
    global.cam_baixo_alvo = 0;
    for (var _i = 0; _i < array_length(pontes_queda); _i++)
    {
        var _pq = pontes_queda[_i];
        var _x1 = _pq[0], _x2 = _pq[1];
        terreno_abrir(_x1, _x2, chao_y);
        terreno_limpar(_x1, _x2);
        var _w = (_x2 - _x1) / PQ_TRECHOS;
        var _segs = [];
        for (var _k = 0; _k < PQ_TRECHOS; _k++)
        {
            var _b = terreno_bloco(_x1 + _k * _w, _x1 + (_k + 1) * _w, chao_y, chao_y + 10);
            array_push(_segs, { x: _x1 + _k * _w, w: _w, inst: _b, estado: "firme", t: 0, dy: 0, vy: 0, trem: 0 });
        }
        array_push(pontes_q, { x1: _x1, x2: _x2, tipo: _pq[2], estado: "inteira", t: 0, frente: _x1, dir: 1, segs: _segs });
    }
    for (var _i = 0; _i < array_length(frageis_dados); _i++)
    {
        var _fr = frageis_dados[_i];
        var _pl = terreno_ponte(_fr[0], _fr[1], _fr[2]);
        array_push(frageis, { x: _fr[0], w: _fr[1] - _fr[0], y: _fr[2], inst: _pl, estado: "firme", t: 0, dy: 0, vy: 0, trem: 0 });
    }
    if (array_length(pontes_q) > 0) cenario_carregar();
}

// um trecho de ponte: treme _espera quadros e despenca (o sólido some na hora da queda)
function quedas_trecho(_s, _dt, _espera, _pedra)
{
    if (_s.estado == "tremendo")
    {
        _s.t += _dt;
        _s.trem = random_range(-1.6, 1.6);
        if (random(1) < 0.5 * _dt) fx_em("poeira", _s.x + random(_s.w), chao_y + 8, 0.35);
        if (_s.t >= _espera)
        {
            _s.estado = "caindo";
            _s.vy = 0.8;
            _s.trem = 0;
            if (_s.inst != noone and instance_exists(_s.inst)) instance_destroy(_s.inst);
            _s.inst = noone;
            som_em(_pedra ? "dest_pedra" : "dest_madeira", _s.x + _s.w / 2, chao_y, 0.75);
            fx_em("poeira", _s.x + _s.w / 2, chao_y + 4, 0.9);
            if (_pedra) fx_em("lascas", _s.x + _s.w / 2, chao_y + 10, 0.8);
            global.camera_impact = max(global.camera_impact, 6);
        }
    }
    else if (_s.estado == "caindo")
    {
        _s.vy = min(_s.vy + 0.5 * _dt, 15);
        _s.dy += _s.vy * _dt;
        if (_s.dy > PQ_FUNDO + 120) _s.estado = "sumiu";
    }
}

function quedas_passo()
{
    var _dt = global.dt;
    var _p = instance_find(obj_player, 0);
    var _vivo = (_p != noone and !_p.morto);
    var _cam = 0;
    for (var _i = 0; _i < array_length(pontes_q); _i++)
    {
        var _pq = pontes_q[_i];
        var _x1 = _pq.x1, _x2 = _pq.x2;
        if (_p != noone and _p.x > _x1 - 190 and _p.x < _x2 + 190) _cam = 78;
        if (_pq.estado == "inteira")
        {
            if (_vivo and abs(_p.y - chao_y) < 4 and _p.x > _x1 + 30 and _p.x < _x2 - 30)
            {
                _pq.estado = "aviso";
                _pq.t = 0;
                // cai a partir do lado por onde o herói entrou
                _pq.dir = (_p.x < (_x1 + _x2) / 2) ? 1 : -1;
                _pq.frente = (_pq.dir > 0) ? _x1 : _x2;
                som("viga_aviso", 1, 0);
                som((_pq.tipo == "pedra") ? "pedra_desmorona" : "dest_viga", 0.7, 0);
                aviso_mostrar("A PONTE ESTÁ DESABANDO  ·  CORRA!");
                global.camera_impact = max(global.camera_impact, 9);
                global.terremoto = max(global.terremoto, 24);
            }
        }
        else if (_pq.estado == "aviso")
        {
            _pq.t += _dt;
            global.terremoto = max(global.terremoto, 8);
            if (random(1) < 0.6 * _dt) fx_em("poeira", _pq.frente + _pq.dir * random(80), chao_y + 6, 0.5);
            if (_pq.t >= PQ_AVISO) { _pq.estado = "caindo"; _pq.t = 0; }
        }
        else if (_pq.estado == "caindo")
        {
            _pq.t += _dt;
            // um pouco mais lenta que a corrida do herói (3,6) e vai apertando
            _pq.frente += _pq.dir * min(3.5, 3.05 + _pq.t * 0.004) * _dt;
            global.terremoto = max(global.terremoto, 7);
            var _resta = 0;
            for (var _k = 0; _k < array_length(_pq.segs); _k++)
            {
                var _s = _pq.segs[_k];
                if (_s.estado != "firme") continue;
                var _borda = (_pq.dir > 0) ? _s.x : _s.x + _s.w;
                if ((_pq.frente - _borda) * _pq.dir >= 0) { _s.estado = "tremendo"; _s.t = 0; }
                else _resta += 1;
            }
            if (_resta == 0) _pq.estado = "caida";
        }
        for (var _k = 0; _k < array_length(_pq.segs); _k++) quedas_trecho(_pq.segs[_k], _dt, 12, _pq.tipo == "pedra");
    }
    // ===== PISO FRÁGIL =====
    for (var _i = 0; _i < array_length(frageis); _i++)
    {
        var _f = frageis[_i];
        if (_f.estado == "firme")
        {
            var _em_cima = _vivo and abs(_p.y - _f.y) <= 1.5 and _p.velv >= 0 and _p.bbox_right >= _f.x and _p.bbox_left <= _f.x + _f.w;
            if (_em_cima)
            {
                if (_f.t <= 0) som_em("dest_quique", _f.x + _f.w / 2, _f.y, 0.7);
                _f.t += _dt;
                _f.trem = random_range(-1.2, 1.2) * min(1, _f.t / 12);
                if (random(1) < 0.4 * _dt) fx_em("poeira", _f.x + random(_f.w), _f.y + 8, 0.3);
                if (_f.t >= FRAGIL_TEMPO)
                {
                    _f.estado = "caindo";
                    _f.vy = 0.6;
                    _f.dy = 0;
                    _f.t = 0;
                    if (_f.inst != noone and instance_exists(_f.inst)) instance_destroy(_f.inst);
                    _f.inst = noone;
                    som_em("dest_pedra", _f.x + _f.w / 2, _f.y, 0.8);
                    fx_em("poeira", _f.x + _f.w / 2, _f.y + 6, 0.8);
                    global.camera_impact = max(global.camera_impact, 5);
                }
            }
            else
            {
                // saiu de cima a tempo: a laje se acalma devagar
                _f.t = max(0, _f.t - _dt * 0.5);
                _f.trem = 0;
            }
        }
        else if (_f.estado == "caindo")
        {
            _f.vy = min(_f.vy + 0.45 * _dt, 14);
            _f.dy += _f.vy * _dt;
            _f.t += _dt;
            var _perto = _vivo and _p.bbox_right >= _f.x - 4 and _p.bbox_left <= _f.x + _f.w + 4 and _p.y > _f.y - 4 and _p.y < _f.y + 90;
            if (_f.t >= FRAGIL_VOLTA and !_perto)
            {
                _f.estado = "voltando";
                _f.t = 0;
                _f.dy = 0;
                _f.inst = terreno_ponte(_f.x, _f.x + _f.w, _f.y);
                fx_em("poeira", _f.x + _f.w / 2, _f.y + 4, 0.5);
            }
        }
        else if (_f.estado == "voltando")
        {
            _f.t += _dt;
            if (_f.t >= 24) { _f.estado = "firme"; _f.t = 0; }
        }
    }
    if (_p != noone) global.cam_baixo_alvo = _cam;
}

function quedas_linha(_xa, _ya, _xb, _yb, _cor, _alfa, _larg)
{
    draw_set_color(_cor);
    draw_set_alpha(_alfa);
    draw_line_width(_xa, _ya, _xb, _yb, _larg);
}

function quedas_ret(_xa, _ya, _xb, _yb, _cor, _alfa)
{
    draw_set_color(_cor);
    draw_set_alpha(_alfa);
    draw_rectangle(_xa, _ya, _xb, _yb, false);          // 1 px de sobra: sem costura entre as faixas quando a câmera amplia
}

function quedas_grad(_xa, _ya, _xb, _yb, _cima, _baixo, _alfa)
{
    draw_set_alpha(_alfa);
    draw_rectangle_color(_xa, _ya, _xb, _yb, _cima, _cima, _baixo, _baixo, false);
}

function quedas_desenhar(_vx, _vw)
{
    var _fundo = room_height + PQ_FUNDO;
    var _tf = gpu_get_texfilter();
    for (var _i = 0; _i < array_length(pontes_q); _i++)
    {
        var _pq = pontes_q[_i];
        var _x1 = _pq.x1, _x2 = _pq.x2;
        if (_x2 < _vx - 60 or _x1 > _vx + _vw + 60) continue;
        var _pedra = (_pq.tipo == "pedra");
        // ===== A RAVINA: começa atrás da rua e desce no escuro =====
        var _topo = chao_y - 30;
        quedas_grad(_x1, _topo, _x2, chao_y + 70, make_color_rgb(26, 17, 22), make_color_rgb(12, 7, 10), 1);
        quedas_grad(_x1, chao_y + 70, _x2, _fundo, make_color_rgb(12, 7, 10), c_black, 1);
        // camadas de rocha na parede do fundo (dão a sensação de profundidade)
        for (var _k = 0; _k < 7; _k++)
        {
            var _yy = chao_y + 14 + _k * 30;
            var _enc = 6 + _k * 5;
            quedas_linha(_x1 + _enc, _yy, _x2 - _enc, _yy + sin(_k * 1.7) * 3, make_color_rgb(52, 38, 44), 0.5 - _k * 0.06, 2);
        }
        // paredões dos dois lados: pedra quebrada entrando no vão
        draw_set_alpha(1);
        for (var _k = 0; _k < 14; _k++)
        {
            var _yy2 = _topo + _k * 22;
            var _pk = 16 - _k * 0.8 + sin(_k * 2.3) * 5;
            draw_set_color((_k < 4) ? make_color_rgb(54, 42, 40) : make_color_rgb(30, 22, 24));
            draw_triangle(_x1, _yy2, _x1 + _pk, _yy2 + 9, _x1, _yy2 + 24, false);
            draw_triangle(_x2, _yy2, _x2 - _pk, _yy2 + 11, _x2, _yy2 + 24, false);
        }
        quedas_linha(_x1 - 2, _topo, _x1 + 8, _topo + 1, make_color_rgb(96, 82, 74), 1, 2);
        quedas_linha(_x2 - 8, _topo + 1, _x2 + 2, _topo, make_color_rgb(96, 82, 74), 1, 2);
        // lá no fundo: o clarão do incêndio, névoa e brasas subindo
        gpu_set_blendmode(bm_add);
        var _pulsa = 0.5 + 0.5 * sin(t / 34 + _x1);
        draw_set_color(make_color_rgb(255, 84, 26));
        draw_set_alpha(0.10 + 0.05 * _pulsa);
        draw_ellipse(_x1 + 10, _fundo - 150, _x2 - 10, _fundo - 30, false);
        draw_set_color(make_color_rgb(255, 150, 60));
        draw_set_alpha(0.10 + 0.04 * _pulsa);
        draw_ellipse(_x1 + 50, _fundo - 110, _x2 - 50, _fundo - 50, false);
        draw_set_color(make_color_rgb(120, 60, 150));
        draw_set_alpha(0.05);
        draw_ellipse(_x1 - 10, chao_y + 90, _x2 + 10, chao_y + 150, false);
        draw_set_color(make_color_rgb(255, 160, 70));
        for (var _k = 0; _k < 9; _k++)
        {
            var _f = frac(t / 260 + _k / 9);
            var _bx = lerp(_x1 + 14, _x2 - 14, frac(_k * 0.618)) + sin(t / 26 + _k) * 6;
            draw_set_alpha((1 - _f) * 0.7);
            draw_circle(_bx, _fundo - 60 - _f * 230, 1.4, false);
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);

        // ===== A PONTE =====
        if (_pedra) quedas_ponte_pedra(_pq);
        else quedas_ponte_madeira(_pq);
        // aviso: o tabuleiro racha em brasa pouco antes de ceder
        if (_pq.estado == "aviso")
        {
            gpu_set_blendmode(bm_add);
            var _ka = clamp(_pq.t / PQ_AVISO, 0, 1);
            quedas_ret(_x1, chao_y - 2, _x2, chao_y + 4, make_color_rgb(255, 120, 40), 0.25 * _ka * (0.6 + 0.4 * sin(t * 0.9)));
            gpu_set_blendmode(bm_normal);
        }
    }
    gpu_set_texfilter(_tf);
    // ===== PISO FRÁGIL: lajes de pedra rachada sobre os buracos =====
    for (var _i = 0; _i < array_length(frageis); _i++)
    {
        var _fl = frageis[_i];
        if (_fl.x + _fl.w < _vx - 30 or _fl.x > _vx + _vw + 30 or (_fl.estado == "caindo" and _fl.dy > 200)) continue;
        var _a = 1;
        if (_fl.estado == "caindo") _a = clamp(1 - _fl.dy / 200, 0, 1);
        else if (_fl.estado == "voltando") _a = clamp(_fl.t / 24, 0, 1);
        var _fx = _fl.x + _fl.trem;
        var _fy = _fl.y + _fl.dy;
        var _risco = (_fl.estado == "firme") ? clamp(_fl.t / FRAGIL_TEMPO, 0, 1) : 0;
        quedas_ret(_fx + 2, _fy + 3, _fx + _fl.w + 2, _fy + 13, c_black, 0.3 * _a);
        quedas_grad(_fx, _fy, _fx + _fl.w, _fy + 10, make_color_rgb(118, 108, 112), make_color_rgb(62, 54, 60), _a);
        quedas_ret(_fx, _fy, _fx + _fl.w, _fy + 2, make_color_rgb(150, 140, 142), _a);
        // rachaduras (ficam em brasa conforme a laje cede)
        var _cr = merge_color(make_color_rgb(30, 22, 26), make_color_rgb(255, 110, 40), _risco);
        quedas_linha(_fx + _fl.w * 0.28, _fy + 1, _fx + _fl.w * 0.36, _fy + 9, _cr, _a, 1);
        quedas_linha(_fx + _fl.w * 0.36, _fy + 5, _fx + _fl.w * 0.5, _fy + 3, _cr, _a, 1);
        quedas_linha(_fx + _fl.w * 0.66, _fy, _fx + _fl.w * 0.6, _fy + 9, _cr, _a, 1);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ponte de pedra: a peça "ponte" do cenário cortada em tiras, uma por trecho; cada
// tira treme e despenca com o seu trecho. O pilar do meio desce pelo abismo.
function quedas_ponte_pedra(_pq)
{
    if (!variable_global_exists("cen") or !is_struct(global.cen)) return;
    var _pc = global.cen.pecas[$ "ponte"];
    if (is_undefined(_pc)) return;
    var _pw = _pc.w, _ph = _pc.h;
    var _x1 = _pq.x1;
    var _n = array_length(_pq.segs);
    var _s = _pq.segs[0].w / (_pw / 10);          // cada trecho = 1/10 da peça (um arco a cada 5)
    var _y0 = chao_y - 4 * _s;                     // as ameias ficam acima do tabuleiro, atrás do herói
    gpu_set_texfilter(false);
    // pilares: o do meio e os dois encontros, descendo no escuro
    var _ks = [0, 5, _n];
    for (var _q = 0; _q < 3; _q++)
    {
        var _k = _ks[_q];
        var _seg = _pq.segs[clamp(_k, 0, _n - 1)];
        if (_seg.estado == "sumiu") continue;
        var _cxp = _x1 + _k * _seg.w;
        var _lw = (_k == 5) ? 13 * _s : 7 * _s;
        var _px1 = (_k == 5) ? _cxp - _lw / 2 : ((_k == 0) ? _cxp : _cxp - _lw);
        var _py = _y0 + _ph * _s - 2 + _seg.dy;
        var _ap = clamp(1 - _seg.dy / 220, 0, 1);
        quedas_grad(_px1, _py, _px1 + _lw, _py + 230, make_color_rgb(74, 72, 80), make_color_rgb(8, 6, 10), _ap);
        for (var _j = 0; _j < 6; _j++)
            quedas_linha(_px1, _py + 12 + _j * 22, _px1 + _lw, _py + 12 + _j * 22, make_color_rgb(40, 38, 46), 0.6 * _ap * (1 - _j / 7), 1);
    }
    draw_set_alpha(1);
    for (var _i = 0; _i < _n; _i++)
    {
        var _sg = _pq.segs[_i];
        if (_sg.estado == "sumiu") continue;
        var _a2 = clamp(1 - _sg.dy / 240, 0, 1);
        var _cor = (_sg.estado == "firme") ? c_white : make_color_rgb(255, 214, 196);
        draw_sprite_part_ext(global.cen_spr, 0, _pc.x + (_i mod 10) * _pw / 10, _pc.y, _pw / 10, _ph,
            _sg.x + _sg.trem, _y0 + _sg.dy, _s, _s, _cor, _a2);
    }
}

// ponte de madeira: tábuas, vigas por baixo e corrimão de corda; cada trecho cai com as suas
function quedas_ponte_madeira(_pq)
{
    var _x1 = _pq.x1, _x2 = _pq.x2;
    var _n = array_length(_pq.segs);
    // os dois postes das pontas ficam de pé
    var _postes = [_x1 - 3, _x2 + 3];
    for (var _q = 0; _q < 2; _q++)
    {
        quedas_ret(_postes[_q] - 3, chao_y - 30, _postes[_q] + 3, chao_y + 4, make_color_rgb(30, 20, 14), 1);
        quedas_ret(_postes[_q] - 2, chao_y - 30, _postes[_q] + 2, chao_y + 4, make_color_rgb(92, 62, 36), 1);
    }
    for (var _i = 0; _i < _n; _i++)
    {
        var _sg = _pq.segs[_i];
        if (_sg.estado == "sumiu") continue;
        var _sx = _sg.x + _sg.trem;
        var _sy = chao_y + _sg.dy;
        // a tábua gira um pouco enquanto cai
        var _torto = _sg.dy * 0.06 * ((_i mod 2 == 0) ? 1 : -1);
        // viga e escora por baixo
        quedas_ret(_sx + 2, _sy + 7, _sx + _sg.w - 2, _sy + 11, make_color_rgb(44, 28, 16), 1);
        if (_i mod 3 == 1) quedas_linha(_sx + _sg.w * 0.5, _sy + 11, _sx + _sg.w * 0.5 + _torto, _sy + 34, make_color_rgb(58, 38, 22), 1, 3);
        draw_set_alpha(1);
        madeira_tabuas(_sx, _sy + _torto * 0.3, _sx + _sg.w + 0.5, _sy + 8 + _torto * 0.3, _i * 2);
        quedas_linha(_sx, _sy, _sx + _sg.w, _sy + _torto * 0.3, make_color_rgb(150, 110, 66), 0.8, 1);
        // corrimão de corda (atrás do herói) com um montante a cada dois trechos
        var _cy = _sy - 24 + sin((_i + 0.5) / _n * pi) * 5;
        var _cy2 = _sy - 24 + sin((_i + 1.5) / _n * pi) * 5;
        quedas_linha(_sx, _cy, _sx + _sg.w, (_sg.estado == "firme") ? _cy2 : _cy + 6, make_color_rgb(150, 120, 78), 1, 1.5);
        if (_i mod 2 == 0) quedas_linha(_sx + _sg.w, _cy2, _sx + _sg.w, _sy, make_color_rgb(120, 92, 58), 1, 1.5);
    }
    draw_set_alpha(1);
}

// a câmera desce abaixo da sala perto das pontes: a terra cobre o que ficaria
// vazio lá embaixo (menos nos vãos dos abismos). Draw End do obj_terreno.
function quedas_terra_desenhar()
{
    if (!variable_global_exists("cam_baixo") or global.cam_baixo <= 0.5 or view_camera[0] == -1) return;
    var _vx = camera_get_view_x(view_camera[0]);
    var _vw = camera_get_view_width(view_camera[0]);
    var _topo = room_height;
    var _fundo = room_height + 260;
    var _xa = _vx - 4;
    var _xf = _vx + _vw + 4;
    for (var _i = 0; _i < array_length(vaos); _i++)
    {
        var _v = vaos[_i];
        if (_v[1] <= _xa or _v[0] >= _xf) continue;
        if (_v[0] > _xa)
        {
            quedas_grad(_xa, _topo, _v[0], _topo + 40, make_color_rgb(30, 24, 26), make_color_rgb(14, 10, 12), 1);
            quedas_ret(_xa, _topo + 40, _v[0], _fundo, make_color_rgb(14, 10, 12), 1);
        }
        _xa = max(_xa, _v[1]);
    }
    if (_xa < _xf)
    {
        quedas_grad(_xa, _topo, _xf, _topo + 40, make_color_rgb(30, 24, 26), make_color_rgb(14, 10, 12), 1);
        quedas_ret(_xa, _topo + 40, _xf, _fundo, make_color_rgb(14, 10, 12), 1);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}