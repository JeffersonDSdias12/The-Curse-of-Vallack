// =====================================================================
//  scr_progresso: orbs, evolução da espada e estatísticas da partida
// =====================================================================

#macro ESPADA_NIVEL_MAX 5

// Orbs que cada inimigo solta ao morrer (iguais em todas as dificuldades)
#macro ORBS_BESTA        12
#macro ORBS_ARQUEIRO     8
#macro ORBS_ESCUDO       20
#macro ORBS_MINI_BOSS    150
#macro ORBS_BOSS         400
#macro ORBS_ESQUELETO    10      // v1.8: inimigos novos
#macro ORBS_ARANHA       14
#macro ORBS_ESTATUA      18
#macro ORBS_PORCO        45
#macro ORBS_SEGREDO      60
#macro ORBS_FINALIZADOR  1.5     // finalizador: o inimigo solta 50% a mais

// Boss da fase 1: cada onda de servos
#macro BOSS_ONDA_BESTAS    10
#macro BOSS_ONDA_ARQUEIROS 5
#macro BOSS_ONDA_ESQUELETOS [2, 3, 3, 4]   // v1.8: por dificuldade (dif_valor)
#macro BOSS_ONDA_ARANHAS    [1, 1, 2, 2]   // v1.8: a partir da 2ª onda

// Orbs para chegar a cada nível (índice = nível de destino)
function espada_custo(_nivel)
{
    var _c = [0, 0, 120, 280, 420, 520];
    return _c[clamp(_nivel, 0, ESPADA_NIVEL_MAX)];
}

function espada_nome() { return "LÂMINA DE SYLLA"; }

// O que cada nível libera (mostrado na tela de armas)
function espada_niveis()
{
    return [
        { nivel: 1, itens: [ { tipo: "combo", n: 1 }, { tipo: "especial", acao: ACAO.ESPECIAL_3 } ], texto: "O começo da jornada." },
        { nivel: 2, itens: [ { tipo: "especial", acao: ACAO.ESPECIAL } ],   texto: "+8% de dano." },
        { nivel: 3, itens: [ { tipo: "combo", n: 2 } ],                    texto: "+16% de dano." },
        { nivel: 4, itens: [ { tipo: "especial", acao: ACAO.ESPECIAL_2 } ], texto: "+24% de dano." },
        { nivel: 5, itens: [ { tipo: "combo", n: 3 } ],                    texto: "+32% de dano · fúria mais rápida" }
    ];
}

function espada_dano_mult() { return 1 + 0.08 * (global.espada_nivel - 1); }
function furia_ganho_mult() { return (global.espada_nivel >= 5) ? 1.35 : 1; }

// Combos: 1 desde o começo; 2 no nível 3; 3 no nível 5
function combo_nivel_req(_n) { return (_n >= 3) ? 5 : ((_n == 2) ? 3 : 1); }
function combo_liberado(_n) { return global.espada_nivel >= combo_nivel_req(_n); }

// Especiais: U (Tremor) desde o começo; L (Onda) no nível 2; O (Queda) no nível 4
function especial_nivel_req(_acao)
{
    if (_acao == ACAO.ESPECIAL) return 2;
    if (_acao == ACAO.ESPECIAL_2) return 4;
    return 1;
}
function especial_liberado(_acao) { return global.espada_nivel >= especial_nivel_req(_acao); }
function especial_nome(_acao)
{
    if (_acao == ACAO.ESPECIAL) return "ONDA CARMESIM";
    if (_acao == ACAO.ESPECIAL_2) return "QUEDA CARMESIM";
    return "TREMOR DE VALLACK";
}
// parte da barra de magia que cada especial gasta (0..1)
function especial_custo(_acao)
{
    if (_acao == ACAO.ESPECIAL) return 0.4;
    if (_acao == ACAO.ESPECIAL_2) return 0.7;
    return 0.6;
}

// ---------------------------------------------------------------------
// ORBS
// ---------------------------------------------------------------------
// Solta orbs num ponto: viram bolinhas que voam sozinhas até o jogador
function orbs_soltar(_x, _y, _total)
{
    _total = round(_total);
    if (_total <= 0) return;
    var _grandes = _total div 25;
    var _resto = _total - _grandes * 25;
    var _pequenos = _resto div 5;
    var _uns = _resto - _pequenos * 5;
    var _lista = [];
    repeat (_grandes) array_push(_lista, 25);
    repeat (_pequenos) array_push(_lista, 5);
    repeat (_uns) array_push(_lista, 1);
    for (var _i = 0; _i < array_length(_lista); _i++)
    {
        var _o = instance_create_depth(_x + random_range(-8, 8), _y + random_range(-8, 8), -120, obj_orb);
        _o.valor = _lista[_i];
        _o.vx = random_range(-2.6, 2.6);
        _o.vy = random_range(-4.2, -1.5);
        _o.espera = 18 + _i * 2;
    }
}

function orbs_ganhar(_n)
{
    global.orbs += _n;
    global.orbs_coletados += _n;
    global.orbs_fx = 20;      // o pote do HUD "pulsa"
}

// Valor de orbs de cada tipo de inimigo
function orbs_do_inimigo(_inst)
{
    switch (_inst.object_index)
    {
        case obj_inimigo_01: return ORBS_BESTA;
        case obj_inimigo_02: return ORBS_ARQUEIRO;
        case obj_inimigo_03: return ORBS_ESCUDO;
        case obj_mini_boss:  return ORBS_MINI_BOSS;
        case obj_boss_01:    return ORBS_BOSS;
        case obj_esqueleto:  return ORBS_ESQUELETO;
        case obj_aranha:     return ORBS_ARANHA;
        case obj_porco:      return ORBS_PORCO;
        case obj_estatua:    return ORBS_ESTATUA;
    }
    return 5;
}
