// =====================================================================
//  scr_combate: golpes do jogador, combos e especiais
//  * cada golpe é uma TABELA DE QUADROS: quadro da sprite, duração (em
//    quadros de 60 FPS), área de acerto, avanço e eventos. A animação é
//    tocada pelo código, então o tempo do golpe é exatamente o tempo da
//    animação e o dano só acontece nos quadros em que a lâmina acerta.
//  * combos no estilo God of War: apertar várias vezes encadeia golpes
//  * normalização do tamanho das sprites do personagem
// =====================================================================

// ---------------------------------------------------------------------
// TAMANHO DO PERSONAGEM
// As sprites do guerreiro vieram de artes diferentes, cada uma num
// tamanho (na spr_ataque_2 o tamanho muda até de um quadro para outro).
// Este fator deixa Twilight sempre do tamanho da spr_player_idle. A arte
// original não é alterada: a correção é feita no desenho, sem perder
// qualidade. Se trocar a arte de alguma sprite, ajuste o valor aqui.
// ---------------------------------------------------------------------
// ESQUIVA (rolagem): duração, quadros sem levar dano e velocidade inicial.
// A rolagem sai rápida e freia suave (~115 px); se o chão acabar, ela
// continua no ar até o fim (não para de repente na beirada).
#macro ROLAR_DURACAO    26
#macro ROLAR_INVENC_INI 2
#macro ROLAR_INVENC_FIM 19
#macro ROLAR_VEL        6.6
#macro ROLAR_BUFFER     14      // apertou um pouco antes de poder rolar: rola assim que der (v1.12: 10 -> 14)

// Ângulo do corpo na rolagem (gira rápido no começo e assenta no fim)
function rolar_angulo(_p)
{
    return -rolar_dir * 360 * (1 - power(1 - clamp(_p, 0, 1), 1.6));
}
// APARAR (parry): janela em quadros depois de apertar a defesa
#macro APARAR_JANELA    10
#macro APARAR_RECARGA   26

// A arte nova do Alex (ferramentas/importar_arte.ps1) já sai com o corpo do
// mesmo tamanho em todas as animações (a escala de cada folha foi medida pelo
// rosto do herói). Fica a função para um ajuste fino, se precisar.
function sprite_fator(_spr, _quadro = 0)
{
    return 1;
}

// ---------------------------------------------------------------------
// DANO DOS GOLPES
// v1.4 (balanceamento): cada especial tira uma parte da vida máxima do
// inimigo (Onda 30%, Tremor 35%, Queda 40%), +5% por nível da espada.
// No mini-boss vale 30% disso e no boss 15% (cerca de 5% da vida dele).
// A Fúria (golpe forte) derrota os inimigos comuns de uma vez.
// ---------------------------------------------------------------------
function dano_golpe(_g, _alvo, _dm)
{
    var _mini = (_alvo.object_index == obj_mini_boss);
    var _bruto = (_alvo.object_index == obj_porco);      // v1.8: o porco corrompido aguenta mais
    if (_g.chave == "ira")
    {
        if (_alvo.eh_boss) return max(1, round(_alvo.vida_max * 0.10));
        if (_mini) return max(1, round(_alvo.vida_max * 0.20));
        if (_bruto) return max(1, ceil(_alvo.vida_max * 0.5));
        if (_alvo.object_index == obj_inimigo_03) return max(1, ceil(_alvo.vida_max * 0.7));
        return _alvo.vida_max;
    }
    if (_g.especial)
    {
        var _p = _g.porcento * (1 + 0.05 * (global.espada_nivel - 1));
        if (_alvo.eh_boss) return max(1, round(_alvo.vida_max * _p * 0.15));
        if (_mini) return max(1, round(_alvo.vida_max * _p * 0.3));
        if (_bruto) return max(1, round(_alvo.vida_max * _p * 0.6));
        return max(1, ceil(_alvo.vida_max * _p));
    }
    // v1.12: CONTRA-ATAQUE depois de aparar: uma parte da vida máxima do inimigo
    var _fm = (object_index == obj_player and furia_modo) ? 1.5 : 1;     // MODO FÚRIA: golpes mais brutais
    if (_g.chave == "contra")
    {
        var _pc = 0.35;
        if (_alvo.eh_boss) _pc = 0.05; else if (_mini) _pc = 0.08; else if (_bruto) _pc = 0.15;
        return max(18, round(_alvo.vida_max * _pc * espada_dano_mult() * _fm));
    }
    return max(1, round(_g.dano * _dm * espada_dano_mult() * _fm));
}

// ---------------------------------------------------------------------
// GOLPES NOVOS DA v1.12
// ---------------------------------------------------------------------
function golpe_criar_v112(_chave)
{
    switch (_chave)
    {
        // LANÇADOR: PULAR + PESADO quase juntos (ou para cima + PESADO).
        // Um corte de baixo para cima que joga o inimigo no ar; Twilight sobe
        // junto e pode continuar com até 3 CORTES AÉREOS.
        case "lancador":
            return { nome: "LANÇADOR", spr: spr_ataque_2, pesado: true, no_ar: true, dano: 12, forca: 0.6, atordoa: 55, lanca: 0, cancel: 4,
                arco: [-70, 115, 58, 44], cor: make_color_rgb(255, 170, 110),
                seq: [
                    { q: 0, d: 3 },
                    { q: 1, d: 3 },
                    { q: 2, d: 4, ev: "lancar", hit: [-8, 54, -100, 2] },
                    { q: 3, d: 4, hit: [-8, 46, -120, -24] },
                    { q: 4, d: 4 },
                    { q: 5, d: 5 }
                ] };

        // CONTRA-ATAQUE: sai sozinho logo depois de um APARAR perfeito
        case "contra":
            return { nome: "CONTRA-ATAQUE", spr: spr_player_ataque, pesado: true, armadura: true, dano: 1, forca: 1.4, atordoa: 90, lanca: 0, cancel: 99,
                arco: [80, -50, 64, 38], cor: make_color_rgb(150, 210, 255),
                seq: [
                    { q: 1, d: 2, ev: "contra", av: 3.2 },
                    { q: 2, d: 3, hit: [0, 70, -70, 0], av: 2.4 },
                    { q: 3, d: 4, hit: [0, 86, -66, 0] },
                    { q: 4, d: 4, hit: [0, 60, -62, 0] },
                    { q: 5, d: 8 }
                ] };

        // SUB-ARMA: LÂMINA BUMERANGUE (custa 1 essência)
        case "arremesso":
            return { nome: "LÂMINA BUMERANGUE", spr: spr_player_ataque, dano: 0, forca: 0, atordoa: 0, lanca: 0, cancel: 3,
                seq: [
                    { q: 0, d: 3 },
                    { q: 2, d: 3, ev: "bumerangue" },
                    { q: 3, d: 4 },
                    { q: 5, d: 6 }
                ] };

        // SUB-ARMA: CHAMA DE SYLLA (agachado; custa 2 essências)
        case "arremesso_chama":
            return { nome: "CHAMA DE SYLLA", spr: spr_player_atacar_agaichado, dano: 0, forca: 0, atordoa: 0, lanca: 0, cancel: 4,
                seq: [
                    { q: 0, d: 3 },
                    { q: 1, d: 3 },
                    { q: 2, d: 4, ev: "chama" },
                    { q: 3, d: 4 },
                    { q: 5, d: 7 }
                ] };
    }
    return undefined;
}

// ---------------------------------------------------------------------
// COMBOS
//  Q = ATAQUE (quadrado)   T = GOLPE PESADO (triângulo)   C = RASTEIRA (bola)
//  COMBO 1  Q Q Q  -> Corte, Corte duplo, EXECUÇÃO
//  COMBO 2  Q Q T  -> Corte, Corte duplo, QUEBRA-ESCUDO (salto + impacto)
//  COMBO 3  Q Q C  -> Corte, Corte duplo, RASTEIRA SANGRENTA (lança ao ar)
// ---------------------------------------------------------------------
function combos_lista()
{
    return [
        { nome: "LÂMINA DE VALLACK",  seq: [ACAO.ATACAR, ACAO.ATACAR, ACAO.ATACAR, ACAO.ATACAR], desc: "Rápido, duplo, triplo e o ATAQUE FRENÉTICO: uma tempestade de cortes." },
        { nome: "QUEBRA-ESCUDO",      seq: [ACAO.ATACAR, ACAO.ATACAR, ACAO.ATAQUE_FORTE], desc: "Dois cortes e um salto que cai com um impacto em área." },
        { nome: "RASTEIRA SANGRENTA", seq: [ACAO.ATACAR, ACAO.ATACAR, ACAO.ATAQUE_SALTO], desc: "Dois cortes e uma rasteira que lança os inimigos ao ar." }
    ];
}

// Próximo golpe da cadeia. _cadeia = letras dos golpes já encadeados.
function combo_proximo(_cadeia, _botao, _no_ar, _agachado)
{
    if (_no_ar)
    {
        if (_botao == "Q") return "corte_aereo";
        if (_botao == "T") return "mergulho";
        return "";
    }
    if (_agachado and _botao == "Q") return "rasteira";
    // v1.17: a cadeia guarda as 3 últimas letras: Q, QQ, QQQ e o 4º Q = frenético
    var _n = string_length(_cadeia);
    var _ultima = (_n >= 1) ? string_char_at(_cadeia, _n) : "";
    var _f2 = (_n >= 2) ? string_copy(_cadeia, _n - 1, 2) : "";
    var _f3 = (_n >= 3) ? string_copy(_cadeia, _n - 2, 3) : "";
    if (_f3 == "QQQ" and _botao == "Q") return "frenetico";
    if (_f2 == "QQ" and _f3 != "QQQ")
    {
        // combos 2 e 3 só depois de evoluir a espada (tela de armas)
        if (_botao == "Q") return "corte3";
        if (_botao == "T" and combo_liberado(2)) return "quebra_escudo";
        if (_botao == "C" and combo_liberado(3)) return "rasteira_sangrenta";
    }
    if (_ultima == "Q" and _botao == "Q") return "corte2";
    if (_botao == "Q") return "corte1";
    if (_botao == "T") return "carrasco";
    if (_botao == "C") return "rasteira";
    return "";
}

// ---------------------------------------------------------------------
// TABELA DE GOLPES
// seq: lista de quadros { q: quadro da sprite, d: duração (quadros a 60 FPS),
//      hit: [frente_min, frente_max, y_topo, y_base] área de acerto (px do mundo,
//           relativa aos pés, "frente" segue a direção do guerreiro),
//      dm: multiplicador de dano do quadro, grupo: cada grupo acerta 1x por inimigo,
//      av: avanço por quadro, esp: só sai do quadro quando a condição for
//      verdadeira ("apice", "descendo", "chao"), ev: evento ao entrar no quadro }
// cancel: a partir deste índice o próximo golpe do combo já pode começar
// arco: rastro da espada [ângulo inicial, ângulo final, raio, altura do centro]
// ---------------------------------------------------------------------
// Som de cada ataque (o "corte" no ar). Os especiais tocam os seus sons
// nos eventos da animação (carga, onda, impacto, tremor, fúria).
function golpe_som(_chave)
{
    // v1.16: se existir um sfx_sword_slash.ogg, ele vira o som dos cortes de espada
    // (o tom varia ±0.05 a cada golpe, no som() do obj_player)
    if ((_chave == "corte1" or _chave == "corte2" or _chave == "corte_aereo" or _chave == "contra")
        and variable_global_exists("sfx") and !is_undefined(global.sfx[$ "sfx_sword_slash"])) return "sfx_sword_slash";
    switch (_chave)
    {
        case "corte1":             return "atk_corte_1";
        case "corte2":             return "atk_corte_2";
        case "corte_aereo":        return "atk_aereo";
        case "execucao":           return "atk_pesado";
        case "corte3":             return "atk_pesado";
        case "frenetico":          return "atk_pesado";
        case "carrasco":           return "atk_pesado";
        case "quebra_escudo":      return "atk_pesado";
        case "mergulho":           return "atk_mergulho";
        case "rasteira":           return "atk_rasteira";
        case "rasteira_sangrenta": return "atk_rasteira";
        case "lancador":           return "atk_pesado";
        case "contra":             return "atk_corte_2";
        case "arremesso":          return "atk_corte_1";
        case "arremesso_chama":    return "atk_rasteira";
    }
    return "";
}

function golpe_criar(_chave)
{
    var _g = undefined;
    switch (_chave)
    {
        // ===================== QUADRADO =====================
        // v1.17: a sequência do QUADRADO usa as animações novas da equipe:
        // 1 toque = ATAQUE RÁPIDO (estocada, meia-lua e estocada), 2º = ATAQUE DUPLO
        // (a segunda metade da animação), 3º = ATAQUE TRIPLO (o golpe que crava no
        // chão) e o 4º solta o ATAQUE FRENÉTICO inteiro (o combo LÂMINA DE VALLACK)
        case "corte1":
            _g = { nome: "ATAQUE RÁPIDO", spr: spr_player_ataque_rapido, dano: 8, forca: 2.2, atordoa: 30, lanca: 0, cancel: 3,
                arco: [70, -40, 50, 36], cor: make_color_rgb(255, 235, 220),
                seq: [
                    { q: 0, d: 2 },
                    { q: 1, d: 3, av: 0.8 },
                    { q: 2, d: 3, hit: [4, 58, -58, -34], av: 1.0, dm: 0.45 },
                    { q: 3, d: 4, hit: [4, 64, -70, -6], grupo: 1, dm: 0.6 },
                    { q: 4, d: 3, hit: [4, 64, -50, -24], grupo: 2, dm: 0.4 },
                    { q: 5, d: 6 }
                ] };
        break;

        case "corte2":
            _g = { nome: "ATAQUE DUPLO", spr: spr_player_ataque_duplo, dano: 12, forca: 2.5, atordoa: 32, lanca: 0, cancel: 3,
                arco: [80, -50, 52, 34], cor: make_color_rgb(255, 210, 160),
                seq: [
                    { q: 6, d: 3, hit: [4, 58, -62, -42], av: 1.2, dm: 0.45 },
                    { q: 7, d: 4, hit: [-24, 54, -80, -6], grupo: 1, dm: 0.6 },
                    { q: 8, d: 3, hit: [4, 56, -52, -18], grupo: 1 },
                    { q: 9, d: 3 },
                    { q: 10, d: 3, hit: [4, 66, -46, -26], grupo: 2, dm: 0.45, av: 1.0 },
                    { q: 11, d: 6 }
                ] };
        break;

        case "corte3":
            _g = { nome: "ATAQUE TRIPLO", spr: spr_player_ataque_triplo, pesado: true, dano: 18, forca: 5, atordoa: 50, lanca: 1, cancel: 4,
                arco: [110, -60, 58, 40], cor: make_color_rgb(255, 150, 100),
                seq: [
                    { q: 11, d: 3, av: 1.5 },
                    { q: 12, d: 4, hit: [-12, 62, -84, -4] },
                    { q: 13, d: 6, hit: [4, 58, -42, 6], grupo: 1, dm: 0.5, ev: "impacto_leve" },
                    { q: 14, d: 4 },
                    { q: 15, d: 4 },
                    { q: 16, d: 4 },
                    { q: 17, d: 5 }
                ] };
        break;

        case "frenetico":
            _g = { nome: "ATAQUE FRENÉTICO", spr: spr_player_ataque_frenetico, pesado: true, dano: 30, forca: 6, atordoa: 60, lanca: 2, cancel: 99,
                combo: 1, arco: [120, -60, 60, 40], cor: make_color_rgb(255, 90, 60),
                seq: [
                    { q: 0, d: 3, hit: [-30, 58, -64, -10], dm: 0.12, av: 1.2 },
                    { q: 1, d: 3, hit: [-40, 60, -80, -4], grupo: 1, dm: 0.12 },
                    { q: 2, d: 3 },
                    { q: 3, d: 3, hit: [-30, 60, -58, -14], grupo: 2, dm: 0.12, av: 0.8 },
                    { q: 4, d: 3 },
                    { q: 5, d: 3, hit: [-40, 52, -86, -4], grupo: 3, dm: 0.12 },
                    { q: 6, d: 3, hit: [4, 56, -62, -4], grupo: 4, dm: 0.1 },
                    { q: 7, d: 3, hit: [4, 60, -52, -32], grupo: 5, dm: 0.1, av: 1.0 },
                    { q: 8, d: 4, hit: [4, 74, -52, -22], grupo: 6, dm: 0.12, av: 2.4 },
                    { q: 9, d: 3 },
                    { q: 10, d: 3, hit: [-30, 60, -86, -4], grupo: 7, dm: 0.12 },
                    { q: 11, d: 3, hit: [4, 58, -82, -4], grupo: 8, dm: 0.1 },
                    { q: 12, d: 4, hit: [-8, 62, -98, 4], grupo: 9, dm: 0.3, ev: "impacto_leve" },
                    { q: 13, d: 6, hit: [-20, 66, -42, 6], grupo: 10, dm: 0.2 },
                    { q: 14, d: 4 },
                    { q: 15, d: 4 },
                    { q: 16, d: 4 },
                    { q: 17, d: 6 }
                ] };
        break;

        case "corte_aereo":
            // v1.12: cancel 3 = dá para encadear até 3 cortes no ar (combo aéreo)
            _g = { nome: "CORTE AÉREO", spr: spr_player_ataque_ar, dano: 10, forca: 1.2, atordoa: 30, lanca: 0, cancel: 3, no_ar: true,
                arco: [75, -45, 50, 36], cor: make_color_rgb(255, 235, 220),
                seq: [
                    { q: 0, d: 2 },
                    { q: 1, d: 3 },
                    { q: 2, d: 3, hit: [4, 46, -62, -4] },
                    { q: 3, d: 4, hit: [4, 60, -60, -4] },
                    { q: 4, d: 4, hit: [4, 38, -60, -4] },
                    { q: 5, d: 5 }
                ] };
        break;

        // COMBO 1: golpe por cima (spr_ataque_2 sem o salto)
        case "execucao":
            _g = { nome: "EXECUÇÃO", spr: spr_ataque_2, pesado: true, dano: 24, forca: 7, atordoa: 55, lanca: 2, cancel: 99,
                combo: 1, arco: [130, -35, 62, 40], cor: make_color_rgb(255, 120, 90),
                seq: [
                    { q: 1, d: 3 },
                    { q: 2, d: 4, hit: [-4, 30, -84, -24], dm: 0.4, grupo: 0 },
                    { q: 3, d: 4 },
                    { q: 4, d: 3 },
                    { q: 5, d: 3 },
                    { q: 6, d: 5, ev: "brilho" },
                    { q: 7, d: 3, hit: [4, 50, -72, -4], av: 3.0, grupo: 1 },
                    { q: 8, d: 7, hit: [4, 62, -46, 0], av: 1.8, grupo: 1, ev: "impacto_leve" },
                    { q: 9, d: 6 },
                    { q: 10, d: 5 },
                    { q: 11, d: 5 }
                ] };
        break;

        // ===================== TRIÂNGULO =====================
        // spr_ataque_2: Twilight salta e cai golpeando por cima dos inimigos
        case "carrasco":
        case "quebra_escudo":
            var _forte = (_chave == "quebra_escudo");
            _g = { nome: _forte ? "QUEBRA-ESCUDO" : "SALTO DO CARRASCO", spr: spr_ataque_2, pesado: true,
                dano: _forte ? 28 : 18, forca: _forte ? 8 : 6, atordoa: _forte ? 75 : 45, lanca: _forte ? 4 : 3, cancel: 99,
                combo: _forte ? 2 : 0, no_ar: true, arco: [140, -40, 60, 44], cor: _forte ? make_color_rgb(255, 90, 60) : make_color_rgb(255, 200, 150),
                seq: [
                    { q: 0, d: 4 },
                    { q: 1, d: 4 },
                    { q: 2, d: 4, ev: "salto", hit: [-6, 32, -92, -26], dm: 0.45, grupo: 0 },
                    { q: 3, d: 4 },
                    { q: 4, d: 4 },
                    { q: 5, d: 4 },
                    { q: 6, d: 3, esp: "descendo" },
                    { q: 7, d: 2, esp: "chao", hit: [0, 46, -72, 2], grupo: 1 },
                    { q: 8, d: 8, ev: _forte ? "impacto_quebra" : "impacto_carrasco", hit: _forte ? [-58, 86, -56, 6] : [-32, 64, -50, 6], grupo: 1 },
                    { q: 9, d: 6 },
                    { q: 10, d: 5 },
                    { q: 11, d: 5 }
                ] };
        break;

        // no ar: mergulho com a espada
        case "mergulho":
            _g = { nome: "MERGULHO", spr: spr_ataque_2, pesado: true, dano: 16, forca: 5, atordoa: 40, lanca: 2, cancel: 99, no_ar: true,
                arco: [100, -60, 52, 30], cor: make_color_rgb(255, 200, 150),
                seq: [
                    { q: 6, d: 4 },
                    { q: 7, d: 2, ev: "mergulho", esp: "chao", hit: [0, 42, -64, 2], grupo: 0 },
                    { q: 8, d: 7, ev: "impacto_carrasco", hit: [-28, 58, -46, 6], grupo: 1 },
                    { q: 9, d: 6 },
                    { q: 10, d: 5 },
                    { q: 11, d: 4 }
                ] };
        break;

        // ===================== BOLA =====================
        case "rasteira":
        case "rasteira_sangrenta":
            var _s = (_chave == "rasteira_sangrenta");
            var _m = _s ? 1.6 : 1;
            _g = { nome: _s ? "RASTEIRA SANGRENTA" : "RASTEIRA", spr: spr_player_atacar_agaichado,
                dano: _s ? 16 : 9, forca: _s ? 3 : 2, atordoa: _s ? 60 : 48, lanca: _s ? 4.5 : 0, cancel: 4,
                combo: _s ? 3 : 0, arco: [-70, -5, 54, 18], cor: _s ? make_color_rgb(230, 20, 40) : make_color_rgb(255, 225, 200),
                seq: [
                    { q: 0, d: 3, av: 1.5 * _m },
                    { q: 1, d: 3, av: 2.0 * _m },
                    { q: 2, d: 3, hit: [4, 47, -42, 0], av: 1.5 * _m },
                    { q: 3, d: 4, hit: [4, 56, -42, 0], av: 0.8 * _m },
                    { q: 4, d: 4, hit: [4, 45, -42, 0] },
                    { q: 5, d: 7 }
                ] };
        break;

        // ===================== ESPECIAIS =====================
        // ESPECIAL 1: ONDA CARMESIM (corte + onda que avança)
        case "onda":
            _g = { nome: "ONDA CARMESIM", spr: spr_player_especial, especial: true, porcento: 0.30, acao_esp: ACAO.ESPECIAL, armadura: true, dano: 0, forca: 10, atordoa: 60, lanca: 2, cancel: 99,
                seq: [
                    { q: 0, d: 7, ev: "zoom" },
                    { q: 1, d: 5, hit: [0, 47, -82, -2] },
                    { q: 2, d: 5, hit: [0, 74, -54, -2], ev: "onda" },
                    { q: 3, d: 5, hit: [0, 56, -76, -2] },
                    { q: 4, d: 5, hit: [0, 45, -70, -2] },
                    { q: 5, d: 10 }
                ] };
        break;

        case "onda_agachado":
            // o 7º quadro da sprite é defeituoso (faixas verticais) e não é usado
            _g = { nome: "ONDA CARMESIM", spr: spr_player_atacar_agaichado_especial, especial: true, porcento: 0.30, acao_esp: ACAO.ESPECIAL, armadura: true, dano: 0, forca: 9, atordoa: 60, lanca: 1, cancel: 99,
                seq: [
                    { q: 0, d: 5, ev: "zoom" },
                    { q: 1, d: 5 },
                    { q: 2, d: 4, hit: [0, 58, -46, -2], ev: "onda_baixa" },
                    { q: 3, d: 5, hit: [0, 50, -58, -2] },
                    { q: 4, d: 5, hit: [0, 41, -42, -2] },
                    { q: 5, d: 8 }
                ] };
        break;

        // ESPECIAL 2: QUEDA CARMESIM (spr_ataque_especial_2)
        // salta, crava a espada no chão (dano em área) e, no fim, levanta faíscas na tela
        case "queda":
            _g = { nome: "QUEDA CARMESIM", spr: spr_ataque_especial_2, especial: true, porcento: 0.40, acao_esp: ACAO.ESPECIAL_2, armadura: true, no_ar: true, dano: 0, forca: 8, atordoa: 70, lanca: 4, cancel: 99,
                seq: [
                    { q: 0, d: 6, ev: "zoom" },
                    { q: 1, d: 5, ev: "salto_queda" },
                    { q: 2, d: 5 },
                    { q: 3, d: 5 },
                    { q: 4, d: 3, esp: "apice" },
                    { q: 5, d: 2, ev: "mergulho_queda", esp: "chao" },
                    { q: 6, d: 9, ev: "impacto_queda" },
                    { q: 7, d: 24, ev: "faiscas" }
                ] };
        break;

        // ESPECIAL 3: TREMOR DE VALLACK (spr_ataque_03)
        // a animação carrega 1 vez ao apertar, crava a espada e faz a tela tremer
        case "tremor":
            _g = { nome: "TREMOR DE VALLACK", spr: spr_ataque_03, especial: true, porcento: 0.35, acao_esp: ACAO.ESPECIAL_3, armadura: true, dano: 0, forca: 9, atordoa: 80, lanca: 5, cancel: 99,
                seq: [
                    { q: 0, d: 5, ev: "zoom" },
                    { q: 1, d: 7, ev: "carga" },
                    { q: 2, d: 7 },
                    { q: 3, d: 7 },
                    { q: 4, d: 11, ev: "carga_max" },
                    { q: 5, d: 3 },
                    { q: 6, d: 8, ev: "impacto_tremor" },
                    { q: 7, d: 26 }
                ] };
        break;
        // ===================== FINALIZADOR =====================
        // com o inimigo atordoado (ícone da BOLA sobre ele): golpe final
        case "finalizador":
            _g = { nome: "FINALIZADOR", spr: spr_ataque_2, pesado: true, armadura: true, dano: 0, forca: 9, atordoa: 0, lanca: 0, cancel: 99,
                arco: [130, -35, 66, 40], cor: make_color_rgb(255, 60, 40),
                seq: [
                    { q: 0, d: 4, ev: "fin_inicio" },
                    { q: 1, d: 4 },
                    { q: 2, d: 5 },
                    { q: 3, d: 5 },
                    { q: 4, d: 4 },
                    { q: 5, d: 4 },
                    { q: 6, d: 9, ev: "brilho" },
                    { q: 7, d: 3, av: 2.0 },
                    { q: 8, d: 12, ev: "fin_golpe" },
                    { q: 9, d: 7 },
                    { q: 10, d: 6 },
                    { q: 11, d: 6, ev: "fin_fim" }
                ] };
        break;

        // ===================== FÚRIA =====================
        // barra de fúria cheia: golpe fortíssimo dos dois lados
        case "ira":
            _g = { nome: "IRA DE VALLACK", spr: spr_player_especial, armadura: true, dano: 0, forca: 12, atordoa: 90, lanca: 5, cancel: 99,
                seq: [
                    { q: 0, d: 30, ev: "ira_carga" },
                    { q: 1, d: 5 },
                    { q: 2, d: 6, ev: "ira_golpe" },
                    { q: 3, d: 6 },
                    { q: 4, d: 6 },
                    { q: 5, d: 16 }
                ] };
        break;
    }
    if (is_undefined(_g)) _g = golpe_criar_v112(_chave);
    if (is_undefined(_g)) return undefined;

    // valores padrão
    _g.chave = _chave;
    if (!variable_struct_exists(_g, "especial")) _g.especial = false;
    if (!variable_struct_exists(_g, "armadura")) _g.armadura = false;
    if (!variable_struct_exists(_g, "no_ar"))    _g.no_ar = false;
    if (!variable_struct_exists(_g, "combo"))    _g.combo = 0;
    if (!variable_struct_exists(_g, "arco"))     _g.arco = undefined;
    if (!variable_struct_exists(_g, "cor"))      _g.cor = c_white;
    if (!variable_struct_exists(_g, "pesado"))   _g.pesado = false;
    if (!variable_struct_exists(_g, "porcento")) _g.porcento = 0;
    if (!variable_struct_exists(_g, "acao_esp")) _g.acao_esp = -1;
    _g.duracao = 0;
    for (var _i = 0; _i < array_length(_g.seq); _i++) _g.duracao += _g.seq[_i].d;
    return _g;
}

// Letra do botão de cada ação de ataque (para a cadeia do combo)
function combo_letra(_acao)
{
    if (_acao == ACAO.ATACAR) return "Q";
    if (_acao == ACAO.ATAQUE_FORTE) return "T";
    if (_acao == ACAO.ATAQUE_SALTO) return "C";
    return "";
}
function combo_acao_da_letra(_l)
{
    if (_l == "T") return ACAO.ATAQUE_FORTE;
    if (_l == "C") return ACAO.ATAQUE_SALTO;
    return ACAO.ATACAR;
}
