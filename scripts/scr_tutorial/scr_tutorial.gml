// =====================================================================
//  scr_tutorial: tutorial em PERGAMINHO (como no God of War)
//  * na fase 1 os pergaminhos aparecem na hora certa, pausam o jogo e
//    só fecham com ENTER ou X (cruz do controle)
//  * o botão TUTORIAL do menu inicial (e COMANDOS na pausa) abre todos
//    eles como um livro
//  * ícones de teclas e botões do controle (mudam conforme o que está em uso)
// =====================================================================

enum TUT { INICIO, ACOES, COMBOS, COMBATE, ESPECIAIS, ORBS, FURIA, FINALIZADOR, ESCUDO, CENARIO, ARQUEIRO, ESQUELETO, ARANHA, ESTATUA, PORCO, GUARDIAO, TOTAL }

// ---------------------------------------------------------------------
// CONTEÚDO DAS PÁGINAS
// linhas: { ic: [ações], n: "NOME", t: "descrição" }   ícones + nome + texto
//         { seq: [ações], n: "NOME", t: "descrição" }  sequência de combo
//         { t: "texto" }                                parágrafo
// ---------------------------------------------------------------------
function tutorial_pagina(_i)
{
    switch (_i)
    {
        // ----- TUTORIAL RÁPIDO (início da fase 1): 3 páginas -----
        case TUT.INICIO:
            return { titulo: "TUTORIAL RÁPIDO  ·  MOVIMENTO", sub: "Capítulo I  ·  A caminho do castelo", linhas: [
                { ic: [ACAO.ESQUERDA, ACAO.DIREITA], n: "CORRER", t: "Twilight está sempre correndo: é só apertar para o lado." },
                { ic: [ACAO.PULAR], n: "PULAR", t: "Salta obstáculos e sobe em caixotes. No ar também dá para atacar." },
                { ic: [ACAO.ESQUIVA], n: "ESQUIVA (ROLAGEM)", t: "Rola para o lado: no meio da rolagem nada acerta Twilight. No controle, o analógico direito também rola." },
                { ic: [ACAO.AGACHAR], n: "AGACHAR", t: "Abaixa o corpo. Agachado, o ataque vira uma rasteira." },
                { ic: [ACAO.INTERAGIR], n: "INTERAGIR", t: "Abre baús de vida e salva no cristal dourado (início e meio da fase)." }
            ] };

        case TUT.ACOES:
            return { titulo: "TUTORIAL RÁPIDO  ·  COMBATE", sub: "Botões de ataque, defesa e fúria", linhas: [
                { ic: [ACAO.ATACAR, ACAO.ATAQUE_FORTE, ACAO.ATAQUE_SALTO], n: "ATAQUE  ·  PESADO  ·  RASTEIRA", t: "Os três golpes da espada. Encadeados no ritmo, viram combos." },
                { ic: [ACAO.DEFENDER], n: "DEFESA E APARAR", t: "Segure para defender. Aperte NA HORA do golpe para aparar: o inimigo fica atordoado." },
                { ic: [ACAO.ATAQUE_SALTO], n: "FINALIZADOR", t: "Inimigo atordoado com o ícone sobre a cabeça: aperte para o golpe final." },
                { ic: [ACAO.ESPECIAL_3], n: "ESPECIAL", t: "Gasta magia. Novos especiais e combos chegam ao evoluir a espada." },
                { ic: [ACAO.FURIA], n: "FÚRIA", t: "Com a barra de fúria cheia, libera a Ira de Vallack." }
            ] };

        case TUT.COMBOS:
            var _c = combos_lista();
            return { titulo: "COMBOS", sub: "Aperte no ritmo: cada golpe começa logo depois do anterior", linhas: [
                { seq: _c[0].seq, n: "COMBO 1  ·  " + _c[0].nome, t: _c[0].desc + " Desde o início." },
                { seq: _c[1].seq, n: "COMBO 2  ·  " + _c[1].nome, t: _c[1].desc + " Espada nível " + string(combo_nivel_req(2)) + "." },
                { seq: _c[2].seq, n: "COMBO 3  ·  " + _c[2].nome, t: _c[2].desc + " Espada nível " + string(combo_nivel_req(3)) + "." },
                { t: "Evolua a espada com orbs na tela de ARMAS (" + botao_menu_armas() + "). O nome do combo aparece na tela quando ele sai." }
            ] };

        case TUT.COMBATE:
            return { titulo: "A ARTE DA LÂMINA", sub: "Os servos da maldição surgem de portais de magia", linhas: [
                { t: "Enquanto você ataca, os inimigos à sua frente ficam atordoados. Golpes marcados com QUEBRA-GUARDA atravessam a defesa." },
                { ic: [ACAO.DEFENDER], n: "APARAR", t: "Aperte a defesa no instante do golpe: o ataque é rebatido e o inimigo fica tonto por 2 segundos." },
                { ic: [ACAO.ESQUIVA], n: "ESQUIVA", t: "Role por dentro do golpe. No meio da rolagem nada acerta Twilight." },
                { ic: [ACAO.ATACAR, ACAO.ATAQUE_FORTE], n: "NO AR", t: "Corte aéreo. O golpe pesado no ar faz Twilight mergulhar com a espada." }
            ] };

        case TUT.ESPECIAIS:
            return { titulo: "PODERES AMALDIÇOADOS", sub: "Os especiais gastam a barra de MAGIA, que enche em " + string(ESPECIAL_SEGUNDOS) + " segundos", linhas: [
                { ic: [ACAO.ESPECIAL_3], n: especial_nome(ACAO.ESPECIAL_3) + "  ·  " + string(round(especial_custo(ACAO.ESPECIAL_3) * 100)) + "% DA MAGIA", t: "Carrega a força e golpeia o chão: a terra treme em volta de Twilight. Desde o início." },
                { ic: [ACAO.ESPECIAL], n: especial_nome(ACAO.ESPECIAL) + "  ·  " + string(round(especial_custo(ACAO.ESPECIAL) * 100)) + "% DA MAGIA", t: "Onda vermelha que avança (agachado, sai rente ao chão). Espada nível " + string(especial_nivel_req(ACAO.ESPECIAL)) + "." },
                { ic: [ACAO.ESPECIAL_2], n: especial_nome(ACAO.ESPECIAL_2) + "  ·  " + string(round(especial_custo(ACAO.ESPECIAL_2) * 100)) + "% DA MAGIA", t: "Salta e crava a espada no chão, levantando faíscas. Espada nível " + string(especial_nivel_req(ACAO.ESPECIAL_2)) + "." },
                { t: "Cada especial tira 30% a 40% da vida dos inimigos comuns; no boss, bem menos. Durante um especial Twilight não é interrompido." }
            ] };

        case TUT.ORBS:
            return { titulo: "ORBS DE ALMA", sub: "Cada inimigo derrotado liberta orbs vermelhas", linhas: [
                { t: "As orbs voam sozinhas até Twilight e enchem o pote no canto da tela. Finalizadores rendem 50% a mais." },
                { t: "Caixotes, paredes rachadas e segredos escondidos também guardam orbs." },
                { n: "EVOLUIR A ESPADA", ic: [], t: "Na tela de ARMAS (" + botao_menu_armas() + ") gaste orbs para evoluir a " + espada_nome() + ": cada nível dá mais dano e libera um combo ou especial." }
            ] };

        case TUT.FURIA:
            return { titulo: "A IRA DE VALLACK", sub: "A barra de fúria está cheia!", linhas: [
                { t: "A fúria enche quando Twilight acerta, apara e também quando é ferido." },
                { ic: [ACAO.FURIA], n: "LIBERAR A FÚRIA", t: "Um golpe devastador em volta de Twilight, que derrota os inimigos comuns de uma vez. Ele não é interrompido." }
            ] };

        case TUT.FINALIZADOR:
            return { titulo: "FINALIZADOR", sub: "O inimigo está atordoado e fraco", linhas: [
                { ic: [ACAO.ATAQUE_SALTO], n: "GOLPE FINAL", t: "Quando o ícone aparecer sobre um inimigo, chegue perto e aperte: Twilight executa o golpe final." },
                { t: "Aparar um golpe ou quebrar um escudo também deixa o inimigo pronto para o finalizador. Ele rende mais orbs e recupera um pouco de vida." }
            ] };

        case TUT.ESCUDO:
            return { titulo: "BESTAS ESCUDEIRAS", sub: "Um escudo de ferro protege a frente", linhas: [
                { t: "Golpes de frente batem no escudo. Continue golpeando: a guarda quebra e a besta fica atordoada." },
                { ic: [ACAO.ATAQUE_FORTE], n: "GOLPES PESADOS", t: "Contam em dobro para quebrar o escudo. Especiais e a Fúria quebram na hora." },
                { ic: [ACAO.ESQUIVA], n: "PELAS COSTAS", t: "Role para trás dela: pelas costas o escudo não protege." }
            ] };

        case TUT.CENARIO:
            return { titulo: "A ESTRADA EM CHAMAS", sub: "A vila foi atacada pelos servos de Vallack", linhas: [
                { t: "Caixotes quebram com golpes e às vezes escondem orbs ou um BAÚ DE VIDA. Dá para subir e correr em cima deles." },
                { t: "Paredes rachadas escondem segredos. Golpes pesados e especiais derrubam mais rápido." },
                { t: "Cuidado com espinhos, vigas em chamas que caem do alto e fogo no chão. A vida não volta sozinha: use os baús." }
            ] };

        case TUT.ARQUEIRO:
            return { titulo: "ARQUEIROS ESQUELETO", sub: "Também surgem dos portais de magia", linhas: [
                { t: "Atiram de longe e fogem quando você chega perto; se você se afasta demais, eles voltam para a distância de tiro." },
                { ic: [ACAO.DEFENDER], n: "DEFESA E APARAR", t: "A defesa segura as flechas. Aparada na hora certa, a flecha volta contra quem atirou." },
                { ic: [ACAO.ESPECIAL], n: "ONDA CARMESIM", t: "A onda alcança os arqueiros que tentam fugir." }
            ] };

        case TUT.ESQUELETO:
            return { titulo: "ESQUELETOS GUERREIROS", sub: "Rápidos, com golpe duplo... e teimosos", linhas: [
                { t: "Atacam com dois golpes seguidos: um corte largo e uma estocada. Defenda ou apare os dois." },
                { n: "REERGUER", ic: [], t: "Derrubado por golpes comuns, ele desmonta numa pilha de ossos e se levanta com metade da vida. Golpeie a pilha antes que ele se erga!" },
                { ic: [ACAO.ESPECIAL_3, ACAO.FURIA], n: "DE UMA VEZ", t: "Especiais, a Fúria e o finalizador acabam com ele na hora." }
            ] };

        case TUT.ARANHA:
            return { titulo: "MULHER-ARANHA", sub: "Ágil e traiçoeira: luta de longe e de perto", linhas: [
                { t: "Cospe TEIA em arco. Preso na teia, Twilight fica lento e não pula nem rola. Teia caída no chão também prende." },
                { ic: [ACAO.PULAR, ACAO.ATACAR], n: "SOLTE-SE", t: "Aperte os botões várias vezes para rasgar a teia mais rápido." },
                { ic: [ACAO.DEFENDER], n: "DEFESA E APARAR", t: "A defesa segura a teia; aparada na hora certa, ela volta e prende a própria aranha." },
                { t: "De perto ela ataca com as garras; de média distância dá o BOTE, saltando sobre você." }
            ] };

        case TUT.ESTATUA:
            return { titulo: "ESTÁTUA ENFEITIÇADA", sub: "Pedra que desperta quando você se aproxima", linhas: [
                { t: "Enquanto dorme ela é PEDRA: golpes comuns só tiram faíscas." },
                { n: "OLHOS ACESOS", ic: [], t: "Quando os olhos brilham ela carrega um orbe que persegue Twilight. Só agora (e logo depois do disparo) ela pode ser ferida." },
                { ic: [ACAO.DEFENDER], n: "APARAR O ORBE", t: "Aparado na hora certa, o orbe volta, racha a estátua e a deixa vulnerável." },
                { ic: [ACAO.ESPECIAL_3, ACAO.FURIA], n: "ESPECIAIS", t: "Especiais e a Fúria ferem a estátua mesmo em forma de pedra." }
            ] };

        case TUT.PORCO:
            return { titulo: "PORCO CORROMPIDO", sub: "Um brutamontes da maldição", linhas: [
                { t: "Pesado: golpes comuns não o atordoam. Apare os golpes dele ou use especiais. Um em cada três cortes QUEBRA a guarda." },
                { ic: [ACAO.PULAR, ACAO.ESQUIVA], n: "SALTO E CORTE ROXO", t: "A onda de choque do salto e a onda roxa correm pelo chão e não dá para defender: pule por cima ou role através delas." },
                { n: "FÚRIA", ic: [], t: "Com metade da vida ele ruge, invoca esqueletos pelos portais de magia e fica mais rápido." }
            ] };

        case TUT.GUARDIAO:
            return { titulo: "A ÁRVORE AMALDIÇOADA", sub: "Guardiã da estrada de Vallack", linhas: [
                { t: "Muralhas mágicas fecham a arena: ninguém entra nem sai até o fim da luta." },
                { t: "A cada onda ela invoca 10 bestas, 5 arqueiros e esqueletos guerreiros pelos portais de magia; a partir da segunda onda, também mulheres-aranha." },
                { t: "Com metade da vida ela se enfurece: lança três bolas de fogo e ergue raízes do chão." },
                { ic: [ACAO.DEFENDER], n: "APARAR", t: "Uma bola de fogo aparada na hora certa volta contra a árvore." }
            ] };
    }
    return { titulo: "", sub: "", linhas: [] };
}

// Todas as páginas, na ordem do livro (pausa e menu)
function tutorial_todas()
{
    var _r = [];
    for (var _i = 0; _i < TUT.TOTAL; _i++) array_push(_r, _i);
    return _r;
}

// Rótulo do botão da tela de armas
function botao_menu_armas()
{
    if (global.usando_pad and global.pad_slot >= 0) return (pad_estilo() == "ps") ? "OPTIONS" : "START";
    return "TAB";
}

// Mostra um pergaminho no jogo (uma única vez por partida).
// Se algo estiver na frente (pausa, carregamento...), tenta de novo depois.
function tutorial_mostrar(_tut)
{
    if (!global.cfg_tutorial) return false;          // tutorial desligado no menu
    if (global.tut_visto[_tut]) return false;
    // o primeiro pergaminho da fase 1 sempre vem antes dos outros
    if (_tut != TUT.INICIO and room == Room1 and !global.tut_visto[TUT.INICIO]) return false;
    if (instance_exists(obj_pergaminho) or instance_exists(obj_pausa) or instance_exists(obj_save_menu)
        or instance_exists(obj_loading) or instance_exists(obj_game_over) or instance_exists(obj_final)
        or instance_exists(obj_menu_armas) or instance_exists(obj_resultado)) return false;
    var _p = instance_find(obj_player, 0);
    if (_p == noone or _p.morto) return false;
    // não interrompe um golpe especial / finalizador no meio
    if (!is_undefined(_p.golpe) and _p.golpe.armadura) return false;
    global.tut_visto[_tut] = true;
    var _g = instance_create_depth(0, 0, -10500, obj_pergaminho);
    _g.paginas = [_tut];
    // tutorial rápido: movimento, combate e combos de uma vez
    if (_tut == TUT.INICIO)
    {
        _g.paginas = [TUT.INICIO, TUT.ACOES, TUT.COMBOS];
        global.tut_visto[TUT.ACOES] = true;
        global.tut_visto[TUT.COMBOS] = true;
    }
    return true;
}

// ---------------------------------------------------------------------
// DESENHO DO PERGAMINHO
// ---------------------------------------------------------------------
function pergaminho_tamanho()
{
    var _gw = display_get_gui_width();
    return [min(_gw - 60, 880), 600];
}

// Rolo de madeira/pergaminho enrolado (em cima e embaixo)
function pergaminho_rolo(_cx, _y, _w, _alpha)
{
    var _x1 = _cx - _w / 2;
    var _x2 = _cx + _w / 2;
    var _c_esc = make_color_rgb(118, 82, 42);
    var _c_luz = make_color_rgb(232, 204, 150);
    retangulo_gradiente(_x1, _y - 13, _x2, _y, _c_esc, _alpha, _c_luz, _alpha);
    retangulo_gradiente(_x1, _y, _x2, _y + 13, _c_luz, _alpha, _c_esc, _alpha);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(80, 52, 24));
    draw_rectangle(_x1, _y - 13, _x2, _y + 13, true);
    // pontas de madeira
    for (var _l = -1; _l <= 1; _l += 2)
    {
        var _px = (_l < 0) ? _x1 - 9 : _x2 + 9;
        draw_set_color(make_color_rgb(70, 38, 18));
        draw_ellipse(_px - 11, _y - 16, _px + 11, _y + 16, false);
        draw_set_color(make_color_rgb(150, 98, 46));
        draw_ellipse(_px - 7, _y - 11, _px + 5, _y + 7, false);
        draw_set_color(make_color_rgb(205, 160, 80));
        draw_circle(_px - 2, _y - 4, 3, false);
    }
}

// Altura de um texto com quebra de linha
function txt_bloco_altura(_s, _fonte, _largura)
{
    fonte_usar(_fonte);
    var _e = fonte_escala(_fonte);
    return string_height_ext(texto_seguro(_s), -1, _largura / _e) * _e;
}

// _abre: 0..1 (desenrola)  ·  _rodape: texto do botão de continuar
// _indice: "2 / 6" no modo livro ("" no jogo)
function pergaminho_desenhar(_cx, _cy, _w, _h, _abre, _pag, _alpha, _rodape, _indice = "", _rodape_alpha = 1)
{
    var _ab = clamp(_abre, 0, 1);
    var _ease = 1 - power(1 - _ab, 3);
    var _hh = max(10, _h * _ease);
    var _x1 = _cx - _w / 2;
    var _x2 = _cx + _w / 2;
    var _y1 = _cy - _hh / 2;
    var _y2 = _cy + _hh / 2;
    var _papel  = make_color_rgb(238, 222, 182);
    var _papel2 = make_color_rgb(203, 172, 118);
    var _queim  = make_color_rgb(92, 56, 26);

    // sombra
    draw_set_alpha(0.5 * _alpha);
    draw_set_color(c_black);
    draw_rectangle(_x1 + 12, _y1 + 16, _x2 + 12, _y2 + 16, false);

    // papel envelhecido (mais claro no meio)
    retangulo_gradiente_h(_x1, _y1, _cx, _y2, _papel2, _alpha, _papel, _alpha);
    retangulo_gradiente_h(_cx, _y1, _x2, _y2, _papel, _alpha, _papel2, _alpha);
    retangulo_gradiente(_x1, _y1, _x2, _y1 + 46, _queim, 0.32 * _alpha, _queim, 0);
    retangulo_gradiente(_x1, _y2 - 46, _x2, _y2, _queim, 0, _queim, 0.32 * _alpha);

    // manchas
    draw_set_color(make_color_rgb(150, 110, 60));
    for (var _m = 0; _m < 7; _m++)
    {
        var _mx = _x1 + _w * (0.12 + 0.76 * frac(sin(_m * 12.9898) * 43758.5453));
        var _my = _y1 + _hh * (0.15 + 0.7 * frac(sin(_m * 78.233) * 12345.678));
        var _mr = 14 + 26 * frac(sin(_m * 3.17) * 999.1);
        draw_set_alpha(0.07 * _alpha);
        draw_ellipse(_mx - _mr, _my - _mr * 0.6, _mx + _mr, _my + _mr * 0.6, false);
    }

    // bordas laterais rasgadas e queimadas
    draw_set_color(_queim);
    var _passo = 9;
    for (var _yy = _y1; _yy < _y2; _yy += _passo)
    {
        var _k = (_yy - _y1);
        var _r1 = 3 + 6 * abs(sin(_k * 0.37 + 1.3));
        var _r2 = 3 + 6 * abs(sin(_k * 0.23 + 4.1));
        var _yb = min(_y2, _yy + _passo);
        draw_set_alpha(0.6 * _alpha);
        draw_triangle(_x1, _yy, _x1 + _r1, (_yy + _yb) / 2, _x1, _yb, false);
        draw_triangle(_x2, _yy, _x2 - _r2, (_yy + _yb) / 2, _x2, _yb, false);
    }
    draw_set_alpha(0.75 * _alpha);
    draw_rectangle(_x1, _y1, _x2, _y2, true);

    // rolos
    pergaminho_rolo(_cx, _y1, _w + 30, _alpha);
    pergaminho_rolo(_cx, _y2, _w + 30, _alpha);

    if (_ease < 0.9) { desenho_resetar(); return; }
    var _ca = _alpha * clamp((_ease - 0.9) / 0.1, 0, 1);
    var _vermelho = make_color_rgb(128, 18, 16);
    var _tinta    = make_color_rgb(54, 32, 16);
    var _tinta2   = make_color_rgb(96, 64, 34);

    // título
    var _ty = _y1 + 46;
    txt(_cx, _ty, _pag.titulo, FONTE.MEDIA, _vermelho, _ca, fa_center, fa_middle, min(1.15, (_w - 120) / max(1, txt_largura(_pag.titulo, FONTE.MEDIA))));
    txt(_cx, _ty + 30, _pag.sub, FONTE.MINI, _tinta2, _ca, fa_center, fa_middle, min(1, (_w - 120) / max(1, txt_largura(_pag.sub, FONTE.MINI))));
    // ornamento
    draw_set_alpha(_ca);
    draw_set_color(_tinta2);
    draw_line_width(_cx - 200, _ty + 50, _cx - 14, _ty + 50, 2);
    draw_line_width(_cx + 14, _ty + 50, _cx + 200, _ty + 50, 2);
    draw_set_color(_vermelho);
    draw_triangle(_cx - 9, _ty + 50, _cx, _ty + 43, _cx + 9, _ty + 50, false);
    draw_triangle(_cx - 9, _ty + 50, _cx, _ty + 57, _cx + 9, _ty + 50, false);

    // linhas
    var _xi = _x1 + 56;                 // coluna dos ícones
    var _xt = _x1 + 56 + 150;           // coluna do texto
    var _lt = _x2 - 56 - _xt;           // largura do texto
    var _y = _ty + 76;
    for (var _l = 0; _l < array_length(_pag.linhas); _l++)
    {
        var _ln = _pag.linhas[_l];
        var _ic = _ln[$ "ic"];
        var _sq = _ln[$ "seq"];
        var _nm = _ln[$ "n"];
        if (is_undefined(_ic) and is_undefined(_sq))
        {
            // parágrafo: ocupa a largura toda
            draw_set_alpha(_ca * 0.5);
            draw_set_color(_vermelho);
            draw_circle(_xi + 4, _y + 9, 3, false);
            txt_bloco(_xi + 16, _y, _ln.t, FONTE.MINI, _tinta, _ca, _x2 - 56 - _xi - 16, fa_left, fa_top);
            _y += txt_bloco_altura(_ln.t, FONTE.MINI, _x2 - 56 - _xi - 16) + 18;
            continue;
        }
        // ícones (ou sequência do combo)
        var _cx_ic = _xi;
        var _lista = is_undefined(_sq) ? _ic : _sq;
        for (var _k2 = 0; _k2 < array_length(_lista); _k2++)
        {
            if (_k2 > 0)
            {
                draw_set_alpha(_ca);
                draw_set_color(_tinta2);
                if (!is_undefined(_sq)) draw_triangle(_cx_ic + 1, _y + 11, _cx_ic + 7, _y + 16, _cx_ic + 1, _y + 21, false);
                else txt(_cx_ic + 4, _y + 16, "/", FONTE.MINI, _tinta2, _ca, fa_center, fa_middle);
                _cx_ic += 10;
            }
            _cx_ic += desenhar_icone_acao(_cx_ic, _y + 16, _lista[_k2], 28, _ca) + 2;
        }
        if (!is_undefined(_nm)) txt(_xt, _y, _nm, FONTE.PEQUENA, _vermelho, _ca, fa_left, fa_top, min(1, _lt / max(1, txt_largura(_nm, FONTE.PEQUENA))));
        txt_bloco(_xt, _y + 24, _ln.t, FONTE.MINI, _tinta, _ca, _lt, fa_left, fa_top);
        _y += max(38, 24 + txt_bloco_altura(_ln.t, FONTE.MINI, _lt)) + 18;
    }

    // selo de cera
    var _sx = _x2 - 64;
    var _sy = _y2 - 52;
    draw_set_alpha(_ca * 0.9);
    draw_set_color(make_color_rgb(110, 10, 12));
    draw_circle(_sx, _sy, 25, false);
    draw_set_color(make_color_rgb(160, 24, 22));
    draw_circle(_sx - 1, _sy - 1, 20, false);
    draw_set_color(make_color_rgb(95, 6, 8));
    draw_circle(_sx, _sy, 17, true);
    txt(_sx, _sy, "V", FONTE.MEDIA, make_color_rgb(230, 120, 100), _ca * 0.9, fa_center, fa_middle, 0.9);

    // número da página (livro)
    if (_indice != "") txt(_cx, _y2 - 70, _indice, FONTE.MINI, _tinta2, _ca, fa_center, fa_middle);

    // continuar: [X] / [ENTER]
    if (_rodape != "" and _rodape_alpha > 0)
    {
        var _ra = _ca * _rodape_alpha;
        var _wt = txt_largura(_rodape, FONTE.PEQUENA);
        var _w_ic = 28 + 18 + desenhar_tecla_largura("ENTER", 28);
        var _rx = _cx - (_w_ic + 12 + _wt) / 2;
        var _ry = _y2 - 40;
        _rx += desenhar_icone_pad(_rx, _ry, gp_face1, 28, _ra);
        txt(_rx + 9, _ry, "/", FONTE.PEQUENA, _tinta2, _ra, fa_center, fa_middle);
        _rx += 18;
        _rx += desenhar_tecla(_rx, _ry, "ENTER", 28, _ra);
        txt(_rx + 12, _ry, _rodape, FONTE.PEQUENA, _vermelho, _ra, fa_left, fa_middle);
    }
    desenho_resetar();
}

// ---------------------------------------------------------------------
// ÍCONES DE TECLAS E BOTÕES
// _x = borda esquerda, _y = centro vertical, _a = altura. Retornam a largura.
// ---------------------------------------------------------------------
function desenhar_icone_acao(_x, _y, _acao, _a = 30, _alpha = 1)
{
    if (global.usando_pad and global.pad_slot >= 0) return desenhar_icone_pad(_x, _y, global.botoes[_acao], _a, _alpha);
    return desenhar_tecla(_x, _y, nome_tecla(global.teclas[_acao]), _a, _alpha);
}

// Largura que o ícone de uma ação vai ocupar (para alinhar à direita)
function icone_acao_largura(_acao, _a = 30)
{
    if (global.usando_pad and global.pad_slot >= 0) return icone_pad_largura(global.botoes[_acao], _a);
    return desenhar_tecla_largura(nome_tecla(global.teclas[_acao]), _a);
}

function icone_pad_largura(_b, _a = 30)
{
    if (_b < 0) return max(_a * 1.3, txt_largura("ANALÓGICO", FONTE.MINI, min(1, (_a * 0.6) / 15)) + 16);
    if (_b == gp_face1 or _b == gp_face2 or _b == gp_face3 or _b == gp_face4) return _a;
    if (_b == gp_padu or _b == gp_padd or _b == gp_padl or _b == gp_padr or (_b >= PAD_HAT_BASE and _b < PAD_HAT_BASE + 16)) return _a;
    if (_b == gp_stickl or _b == gp_stickr) return _a;
    var _ps = (pad_estilo() == "ps");
    var _nome = string(_b);
    switch (_b)
    {
        case gp_shoulderl:  _nome = _ps ? "L1" : "LB"; break;
        case gp_shoulderr:  _nome = _ps ? "R1" : "RB"; break;
        case gp_shoulderlb: _nome = _ps ? "L2" : "LT"; break;
        case gp_shoulderrb: _nome = _ps ? "R2" : "RT"; break;
        case gp_select:     _nome = _ps ? "SELECT" : "BACK"; break;
        case gp_start:      _nome = _ps ? "OPTIONS" : "START"; break;
    }
    var _e = min(1, (_a * 0.6) / 15);
    return max(_a * 1.3, txt_largura(_nome, FONTE.MINI, _e) + 16);
}

function desenhar_tecla_largura(_texto, _a)
{
    var _e = min(1, (_a * 0.62) / 15);
    return max(_a, txt_largura(_texto, FONTE.MINI, _e) + 16);
}

function desenhar_tecla(_x, _y, _texto, _a = 30, _alpha = 1)
{
    var _e = min(1, (_a * 0.62) / 15);
    var _w = desenhar_tecla_largura(_texto, _a);
    var _y1 = _y - _a / 2;
    var _y2 = _y + _a / 2;
    draw_set_alpha(_alpha * 0.55);
    draw_set_color(c_black);
    draw_roundrect_ext(_x + 1, _y1 + 3, _x + _w + 1, _y2 + 3, 8, 8, false);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(58, 46, 36));
    draw_roundrect_ext(_x, _y1, _x + _w, _y2, 8, 8, false);
    draw_set_color(make_color_rgb(236, 228, 210));
    draw_roundrect_ext(_x + 2, _y1 + 2, _x + _w - 2, _y2 - 4, 6, 6, false);
    txt(_x + _w / 2, _y - 1, _texto, FONTE.MINI, make_color_rgb(40, 28, 18), _alpha, fa_center, fa_middle, _e);
    return _w;
}

function desenhar_icone_pad(_x, _y, _b, _a = 30, _alpha = 1)
{
    var _ps = (pad_estilo() == "ps");
    var _r = _a / 2;
    var _cx = _x + _r;
    var _fundo = make_color_rgb(30, 28, 32);
    var _borda = make_color_rgb(150, 145, 140);

    // botões redondos (X, bola, quadrado, triângulo / A, B, X, Y)
    if (_b == gp_face1 or _b == gp_face2 or _b == gp_face3 or _b == gp_face4)
    {
        draw_set_alpha(_alpha * 0.5);
        draw_set_color(c_black);
        draw_circle(_cx + 1, _y + 2, _r, false);
        draw_set_alpha(_alpha);
        draw_set_color(_fundo);
        draw_circle(_cx, _y, _r, false);
        draw_set_color(_borda);
        draw_circle(_cx, _y, _r, true);
        var _s = _r * 0.46;
        if (_ps)
        {
            switch (_b)
            {
                case gp_face1:
                    draw_set_color(make_color_rgb(130, 180, 255));
                    draw_line_width(_cx - _s, _y - _s, _cx + _s, _y + _s, 3);
                    draw_line_width(_cx - _s, _y + _s, _cx + _s, _y - _s, 3);
                break;
                case gp_face2:
                    draw_set_color(make_color_rgb(255, 100, 100));
                    for (var _i = 0; _i < 3; _i++) draw_circle(_cx, _y, _s + 1 - _i, true);
                break;
                case gp_face3:
                    draw_set_color(make_color_rgb(245, 145, 215));
                    for (var _i2 = 0; _i2 < 3; _i2++) draw_rectangle(_cx - _s + _i2, _y - _s + _i2, _cx + _s - _i2, _y + _s - _i2, true);
                break;
                case gp_face4:
                    draw_set_color(make_color_rgb(95, 230, 175));
                    var _ty1 = _y - _s * 1.05;
                    var _ty2 = _y + _s * 0.8;
                    draw_line_width(_cx, _ty1, _cx - _s * 1.1, _ty2, 3);
                    draw_line_width(_cx - _s * 1.1, _ty2, _cx + _s * 1.1, _ty2, 3);
                    draw_line_width(_cx + _s * 1.1, _ty2, _cx, _ty1, 3);
                break;
            }
        }
        else
        {
            var _letra = "A";
            var _cor = make_color_rgb(110, 210, 90);
            if (_b == gp_face2) { _letra = "B"; _cor = make_color_rgb(240, 80, 70); }
            if (_b == gp_face3) { _letra = "X"; _cor = make_color_rgb(80, 150, 255); }
            if (_b == gp_face4) { _letra = "Y"; _cor = make_color_rgb(245, 200, 60); }
            txt(_cx, _y, _letra, FONTE.PEQUENA, _cor, _alpha, fa_center, fa_middle, min(1, _a / 30));
        }
        desenho_resetar();
        return _a;
    }

    // direcional (D-pad ou "hat" de controle genérico)
    var _dir = -1;
    if (_b == gp_padu or _b == PAD_HAT_BASE + 1) _dir = 0;
    if (_b == gp_padr or _b == PAD_HAT_BASE + 2) _dir = 1;
    if (_b == gp_padd or _b == PAD_HAT_BASE + 4) _dir = 2;
    if (_b == gp_padl or _b == PAD_HAT_BASE + 8) _dir = 3;
    if (_dir >= 0)
    {
        var _t = _a * 0.34;
        draw_set_alpha(_alpha);
        draw_set_color(_borda);
        draw_rectangle(_cx - _t / 2 - 1, _y - _r - 1, _cx + _t / 2 + 1, _y + _r + 1, false);
        draw_rectangle(_cx - _r - 1, _y - _t / 2 - 1, _cx + _r + 1, _y + _t / 2 + 1, false);
        draw_set_color(_fundo);
        draw_rectangle(_cx - _t / 2, _y - _r, _cx + _t / 2, _y + _r, false);
        draw_rectangle(_cx - _r, _y - _t / 2, _cx + _r, _y + _t / 2, false);
        draw_set_color(make_color_rgb(255, 210, 90));
        switch (_dir)
        {
            case 0: draw_rectangle(_cx - _t / 2 + 1, _y - _r + 1, _cx + _t / 2 - 1, _y - _t / 2, false); break;
            case 1: draw_rectangle(_cx + _t / 2, _y - _t / 2 + 1, _cx + _r - 1, _y + _t / 2 - 1, false); break;
            case 2: draw_rectangle(_cx - _t / 2 + 1, _y + _t / 2, _cx + _t / 2 - 1, _y + _r - 1, false); break;
            case 3: draw_rectangle(_cx - _r + 1, _y - _t / 2 + 1, _cx - _t / 2, _y + _t / 2 - 1, false); break;
        }
        desenho_resetar();
        return _a;
    }

    // ombros, gatilhos, analógicos e botões de menu: pílula com o nome
    var _nome = "";
    switch (_b)
    {
        case gp_shoulderl:  _nome = _ps ? "L1" : "LB"; break;
        case gp_shoulderr:  _nome = _ps ? "R1" : "RB"; break;
        case gp_shoulderlb: _nome = _ps ? "L2" : "LT"; break;
        case gp_shoulderrb: _nome = _ps ? "R2" : "RT"; break;
        case gp_stickl:     _nome = "L3"; break;
        case gp_stickr:     _nome = "R3"; break;
        case gp_select:     _nome = _ps ? "SELECT" : "BACK"; break;
        case gp_start:      _nome = _ps ? "OPTIONS" : "START"; break;
        default:            _nome = (_b < 0) ? "ANALÓGICO" : string(_b);
    }
    var _e = min(1, (_a * 0.6) / 15);
    var _w = max(_a * 1.3, txt_largura(_nome, FONTE.MINI, _e) + 16);
    var _redondo = (_b == gp_stickl or _b == gp_stickr);
    if (_redondo) _w = _a;
    draw_set_alpha(_alpha * 0.5);
    draw_set_color(c_black);
    draw_roundrect_ext(_x + 1, _y - _r + 2, _x + _w + 1, _y + _r + 2, _r, _r, false);
    draw_set_alpha(_alpha);
    draw_set_color(_fundo);
    draw_roundrect_ext(_x, _y - _r, _x + _w, _y + _r, _redondo ? _r : 9, _redondo ? _r : 9, false);
    draw_set_color(_borda);
    draw_roundrect_ext(_x, _y - _r, _x + _w, _y + _r, _redondo ? _r : 9, _redondo ? _r : 9, true);
    txt(_x + _w / 2, _y, _nome, FONTE.MINI, c_white, _alpha, fa_center, fa_middle, _e);
    desenho_resetar();
    return _w;
}
