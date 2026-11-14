// =====================================================================
//  scr_v117 — v1.17
//   * SEQUÊNCIA DE GOLPES (QTE, como no God of War) no Carrasco e na Árvore
//   * ORBES DE VIDA (verdes) do Carrasco
//   * EFEITOS DE ESPADA: lua crescente, cortes em X, estrela de impacto,
//     raios de tinta e rajada (6 estilos de lâmina, ganhos nas conquistas)
//   * PERFIL DO JOGADOR: nome (só nas conquistas), CONQUISTAS e RECOMPENSAS
//   * o MAPA das 18 fases e as DICAS da tela de carregamento
//  O mesmo da versão Android (Godot: src/core/v117.gd).
// =====================================================================

global.qte_alvo = noone;            // o chefe preso na sequência (os outros inimigos esperam)
global.conquistas_fila = [];        // avisos de conquista na tela (um de cada vez)
global.dano_na_luta = 0;            // dano que Twilight levou desde que o Carrasco acordou

// ---------------------------------------------------------------------
// SEQUÊNCIA DE GOLPES (QTE)
// ---------------------------------------------------------------------
// Quantos botões tem a sequência e quantos quadros (60 = 1 s) o jogador tem
// para apertar cada um. _eh_boss: a Árvore (true) ou o Carrasco (false).
// Retorna [quantidade de botões, quadros por botão].
function qte_parametros(_eh_boss)
{
    // v1.17: curva nivelada: cada nível acrescenta um botão e tira ~15% do tempo,
    // sem descer de 48 quadros (0,8 s): menos que isso não dá para reagir no toque
    if (_eh_boss) return [dif_valor([5, 6, 7, 8]), dif_valor([90, 72, 60, 50])];
    return [dif_valor([3, 4, 5, 5]), dif_valor([100, 84, 70, 60])];
}

// v1.19: cada sequência completada cura Twilight (fração da vida máxima).
// Soma com os 8% que o golpe finalizador já devolve.
#macro QTE_CURA 0.30
// v1.19: chuva de brasas da Árvore (obj_boss_01): quadros de aviso no chão
// antes da primeira brasa e entre uma brasa e a seguinte
#macro CHUVA_AVISO     46
#macro CHUVA_INTERVALO 9
#macro CHUVA_VEL       5.4
function qte_curar(_p)
{
    if (!instance_exists(_p) or _p.morto) return;
    var _ganho = min(_p.vida_max - _p.vida, round(_p.vida_max * QTE_CURA));
    with (_p) { vida += _ganho; cura_fx = max(cura_fx, 45); }
    som("sfx_cura", 0.9, 0);
    if (_ganho > 0) aviso_mostrar("SEQUÊNCIA COMPLETA  ·  +" + string(_ganho) + " DE VIDA");
}

// Botões que aparecem na sequência: os 4 que existem em todo lugar (teclado,
// controle e os botões fixos do toque no celular)
function qte_acoes() { return [ACAO.ATACAR, ACAO.ATAQUE_FORTE, ACAO.PULAR, ACAO.DEFENDER]; }

// Abre a sequência num chefe pronto (exausto / cambaleando)
function qte_iniciar(_alvo)
{
    if (instance_exists(obj_qte) or !instance_exists(_alvo)) return noone;
    var _q = instance_create_depth(0, 0, -10050, obj_qte);
    _q.alvo = _alvo;
    var _par = qte_parametros(_alvo.eh_boss);
    var _n = max(2, round(_par[0]));
    _q.tempo_botao = max(20, _par[1]);
    var _ac = qte_acoes();
    var _seq = [];
    for (var _k = 0; _k < _n; _k++)
    {
        var _a = _ac[irandom(array_length(_ac) - 1)];
        // nunca o mesmo botão 3 vezes seguidas
        if (_k >= 2 and _seq[_k - 1] == _a and _seq[_k - 2] == _a) _a = _ac[(array_get_index(_ac, _a) + 1 + irandom(2)) mod array_length(_ac)];
        array_push(_seq, _a);
    }
    _q.seq = _seq;
    with (_alvo) { em_qte = true; finalizavel = false; qte_pronto = false; velh = 0; empurrao = 0; }
    with (obj_aviso) instance_destroy();     // a tela fica limpa para os botões
    global.qte_alvo = _alvo;
    som("sfx_finalizador", 0.8, 0);
    return _q;
}

// Onde Twilight fica durante a sequência: colado na borda do chefe, do lado em que está
function qte_x_frente(_alvo, _px)
{
    var _lado = sign(_px - _alvo.x);
    if (_lado == 0) _lado = -1;
    return (_lado > 0) ? _alvo.bbox_right + 18 : _alvo.bbox_left - 18;
}

// Anel do tempo de cada botão (_frac: quanto ainda resta, de 1 a 0)
function desenhar_anel(_x, _y, _r, _esp, _frac, _cor, _alpha)
{
    var _n = 48;
    var _m = max(1, round(_n * clamp(_frac, 0, 1)));
    draw_set_color(_cor);
    draw_set_alpha(_alpha);
    draw_primitive_begin(pr_trianglestrip);
    for (var _i = 0; _i <= _m; _i++)
    {
        var _a = 90 + 360 * _i / _n;
        draw_vertex(_x + lengthdir_x(_r, _a), _y + lengthdir_y(_r, _a));
        draw_vertex(_x + lengthdir_x(_r - _esp, _a), _y + lengthdir_y(_r - _esp, _a));
    }
    draw_primitive_end();
    draw_set_alpha(1);
}

// ---------------------------------------------------------------------
// ORBES DE VIDA (verdes): voam até Twilight e curam ao chegar
// ---------------------------------------------------------------------
function orbs_vida_soltar(_x, _y, _n, _cura = 6)
{
    for (var _i = 0; _i < _n; _i++)
    {
        var _o = instance_create_depth(_x + random_range(-10, 10), _y + random_range(-10, 10), -121, obj_orb);
        _o.tipo = "vida";
        _o.valor = _cura;
        _o.vx = random_range(-3, 3);
        _o.vy = random_range(-4.8, -1.8);
        _o.espera = 26 + _i * 3;
    }
}

// ---------------------------------------------------------------------
// EFEITOS DE ESPADA (inspirados nos jogos de ação que você mandou)
// ---------------------------------------------------------------------
// Estilos da lâmina: carmesim é o de sempre; os outros saem das conquistas
function espada_estilos()
{
    return [
        { id: "carmesim",  nome: "LÂMINA CARMESIM",     brilho: make_color_rgb(255, 46, 36),  meio: make_color_rgb(255, 120, 70),  miolo: make_color_rgb(255, 238, 214) },
        { id: "violeta",   nome: "LUA VIOLETA",         brilho: make_color_rgb(140, 60, 255), meio: make_color_rgb(255, 90, 210),  miolo: make_color_rgb(214, 232, 255) },
        { id: "glacial",   nome: "LÂMINA GLACIAL",      brilho: make_color_rgb(30, 140, 255), meio: make_color_rgb(120, 222, 255), miolo: c_white },
        { id: "dourada",   nome: "FÚRIA DOURADA",       brilho: make_color_rgb(255, 120, 10), meio: make_color_rgb(255, 196, 50),  miolo: make_color_rgb(255, 250, 200) },
        { id: "esmeralda", nome: "RELÂMPAGO ESMERALDA", brilho: make_color_rgb(70, 220, 30),  meio: make_color_rgb(196, 255, 70),  miolo: make_color_rgb(240, 255, 214) },
        { id: "sombria",   nome: "CHAMA SOMBRIA",       brilho: make_color_rgb(150, 20, 90),  meio: make_color_rgb(210, 60, 200),  miolo: make_color_rgb(255, 205, 255) }     // v1.17: fogo do inferno (sem tinta preta)
    ];
}

function espada_estilo(_id)
{
    var _l = espada_estilos();
    for (var _i = 0; _i < array_length(_l); _i++) if (_l[_i].id == _id) return _l[_i];
    return _l[0];
}

function espada_estilo_atual()
{
    if (!variable_global_exists("perfil")) perfil_carregar();
    return espada_estilo(global.perfil.espada_fx);
}

// O estilo já foi ganho? (carmesim sempre; os outros pela conquista que o dá)
function espada_estilo_liberado(_id)
{
    if (_id == "carmesim") return true;
    var _l = conquistas_lista();
    for (var _i = 0; _i < array_length(_l); _i++)
        if (_l[_i].rtipo == "espada" and _l[_i].rval == _id) return conquista_tem(_l[_i].id);
    return false;
}

// Lua crescente no arco do golpe (sai a cada corte; o arco vem da tabela do golpe)
function espada_fx_corte(_x, _y, _dir, _a1, _a2, _r, _forte)
{
    var _f = instance_create_depth(_x, _y, -128, obj_fx);
    _f.tipo = "corte_lua";
    _f.dir = _dir;
    _f.a1 = _a1;
    _f.a2 = _a2;
    _f.raio = _r;
    _f.forte = _forte;
    _f.tam = _forte ? 1.25 : 1;
    with (_f) fx_iniciar();
    return _f;
}

// Losango de luz entre dois pontos (os riscos do corte em X), com a cor/alfa atuais
function fx_losango(_x1, _y1, _x2, _y2, _w)
{
    var _ang = point_direction(_x1, _y1, _x2, _y2) + 90;
    var _mx = (_x1 + _x2) / 2;
    var _my = (_y1 + _y2) / 2;
    var _nx = lengthdir_x(_w, _ang);
    var _ny = lengthdir_y(_w, _ang);
    draw_triangle(_x1, _y1, _mx + _nx, _my + _ny, _mx - _nx, _my - _ny, false);
    draw_triangle(_x2, _y2, _mx + _nx, _my + _ny, _mx - _nx, _my - _ny, false);
}

// Amostra animada de um estilo de lâmina (a lua crescente girando) — tela de LÂMINAS
function lamina_amostra(_x, _y, _r, _e, _t, _alpha)
{
    var _n = 18;
    var _ini = (_t * 4) mod 360;
    var _larg = 13;
    var _cam = [[1.9, _e.brilho, 0.3, true], [1, _e.meio, 0.7, true], [0.32, _e.miolo, 0.95, true]];
    for (var _c = 0; _c < 3; _c++)
    {
        gpu_set_blendmode(_cam[_c][3] ? bm_add : bm_normal);
        draw_primitive_begin(pr_trianglestrip);
        for (var _s = 0; _s <= _n; _s++)
        {
            var _f = _s / _n;
            var _ang = _ini - 150 * _f;
            var _gr = _larg * _cam[_c][0] * power(sin(pi * _f), 0.8);
            var _al = _alpha * _cam[_c][2] * (0.25 + 0.75 * (1 - _f));
            var _rf = (_c == 2) ? _r + _larg * 0.35 : _r + _gr * 0.35;
            var _rd = (_c == 2) ? _rf - _gr : _r - _gr * 0.65;
            draw_vertex_color(_x + lengthdir_x(_rf, _ang), _y + lengthdir_y(_rf, _ang), _cam[_c][1], _al);
            draw_vertex_color(_x + lengthdir_x(_rd, _ang), _y + lengthdir_y(_rd, _ang), _cam[_c][1], _al * 0.35);
        }
        draw_primitive_end();
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// Impacto do golpe: _nivel 0 comum, 1 pesado / crítico, 2 finalizador / sequência / combo
// v1.17: a lâmina em chamas explode em fogo no ponto do golpe (sem a tinta preta)
function espada_fx_impacto(_x, _y, _dir, _nivel, _rajada = false)
{
    fx_em("explosao_fogo", _x, _y, (_nivel == 0) ? 0.75 : ((_nivel == 1) ? 1.05 : 1.45), _dir, -131);
    if (_nivel >= 1) fx_em("corte_x", _x, _y, (_nivel == 1) ? 1 : 1.3, _dir, -132);
    if (_rajada) fx_em("rajada", _x - _dir * 70, _y, 1, _dir, -130);
}

// ---------------------------------------------------------------------
// RASTRO DE FOGO DA ESPADA (v1.17)
// A lâmina de cada quadro dos golpes vem de scr_lamina (ferramentas/
// gerar_lamina.ps1). Nos quadros do corte, a lâmina é interpolada (girando
// em volta do cabo) entre o quadro anterior e o atual: o rastro desenha o
// caminho que a espada percorreu, em chamas, e solta línguas de fogo.
// ---------------------------------------------------------------------
// Lâmina deste quadro no mundo: [cabo_x, cabo_y, ponta_x, ponta_y] ou undefined
function lamina_mundo(_spr, _img, _x, _y, _xs, _ys)
{
    var _d = lamina_dados()[$ sprite_get_name(_spr)];
    if (is_undefined(_d)) return undefined;
    var _q = _d[clamp(floor(_img), 0, array_length(_d) - 1)];
    var _k = hd_escala(_spr);
    return [_x + _q[0] * _xs / _k, _y + _q[1] * _ys / _k, _x + _q[2] * _xs / _k, _y + _q[3] * _ys / _k];
}

// Este quadro do golpe faz parte do CORTE (a lâmina percorre o caminho do dano)?
function golpe_quadro_fogo(_g, _i)
{
    if (is_undefined(_g) or _i < 0 or _i >= array_length(_g.seq)) return false;
    switch (_g.chave)
    {
        case "tremor":      return (_i == 5 or _i == 6);       // desce a espada e crava no chão
        case "queda":       return (_i == 5 or _i == 6);
        case "finalizador": return (_i == 7 or _i == 8);       // o golpe final por cima
        case "ira":         return (_i >= 2 and _i <= 4);
        case "arremesso":
        case "arremesso_chama": return false;                  // arremessos não cortam
    }
    return !is_undefined(_g.seq[_i][$ "hit"]);
}

// cor do fogo pela idade (k: 1 = acabou de nascer, 0 = apagando)
function fogo_cor(_e, _k)
{
    if (_k > 0.55) return merge_color(_e.meio, _e.miolo, (_k - 0.55) / 0.45);
    return merge_color(_e.brilho, _e.meio, _k / 0.55);
}

// A fita de fogo: cada amostra é { cx, cy, px, py, t, vmax, ini } (cabo, ponta,
// idade). Três camadas aditivas: brilho largo, o corpo da chama (com a borda
// tremendo e subindo com o calor) e o miolo quase branco perto do fio.
function fogo_rastro_desenhar(_r, _e)
{
    var _n = array_length(_r);
    if (_n < 2) return;
    var _tt = current_time / 45;
    gpu_set_blendmode(bm_add);
    var _i0 = 0;
    while (_i0 < _n)
    {
        var _i1 = _i0 + 1;
        while (_i1 < _n and !_r[_i1].ini) _i1++;
        if (_i1 - _i0 >= 2)
        {
            for (var _cam = 0; _cam < 3; _cam++)
            {
                draw_primitive_begin(pr_trianglestrip);
                for (var _i = _i0; _i < _i1; _i++)
                {
                    var _s = _r[_i];
                    var _f = clamp(1 - _s.t / _s.vmax, 0, 1);
                    var _dx = _s.px - _s.cx, _dy = _s.py - _s.cy;
                    var _sobe = (1 - _f) * 7;
                    var _trem = 0.06 + 0.09 * (0.5 + 0.5 * sin(_tt + _i * 1.7));
                    var _de, _ate, _ci, _co, _ai, _ao;
                    switch (_cam)
                    {
                        case 0: _de = 0.25; _ate = 1.14 + _trem; _ci = _e.brilho; _co = _e.meio; _ai = 0.12 * _f; _ao = 0.55 * _f; break;
                        case 1: _de = 0.45; _ate = 1.05 + _trem; _ci = _e.meio; _co = fogo_cor(_e, _f); _ai = 0.3 * _f; _ao = _f; break;
                        default: _de = 0.78; _ate = 1.0; _ci = fogo_cor(_e, _f); _co = _e.miolo; _ai = 0.7 * power(_f, 1.2); _ao = power(_f, 1.2); break;
                    }
                    draw_vertex_color(_s.cx + _dx * _de, _s.cy + _dy * _de - _sobe * 0.4, _ci, _ai);
                    draw_vertex_color(_s.cx + _dx * _ate, _s.cy + _dy * _ate - _sobe, _co, _ao);
                }
                draw_primitive_end();
            }
        }
        _i0 = _i1;
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// Línguas de fogo soltas pelo rastro: { x, y, vx, vy, v, vmax, r, s }
function fogo_chamas_desenhar(_c, _e)
{
    var _n = array_length(_c);
    if (_n == 0) return;
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < _n; _i++)
    {
        var _p = _c[_i];
        var _k = clamp(_p.v / _p.vmax, 0, 1);
        var _a = min(1, (_p.vmax - _p.v) / 3) * min(1, _k * 1.7);
        var _r = _p.r * (0.5 + 0.5 * _k);
        var _bal = sin(current_time / 70 + _p.s) * _r * 0.55;
        draw_set_color(fogo_cor(_e, _k));
        draw_set_alpha(0.4 * _a);
        draw_circle(_p.x, _p.y, _r * 1.6, false);
        draw_set_alpha(0.9 * _a);
        draw_triangle(_p.x - _r, _p.y, _p.x + _r, _p.y, _p.x + _bal, _p.y - _r * 2.9, false);
        draw_circle(_p.x, _p.y, _r, false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ---------------------------------------------------------------------
// PERFIL DO JOGADOR: o nome de quem joga (aparece só nas conquistas; o
// herói continua sendo Twilight Vetrus), conquistas, recompensas e os
// números da carreira. Fica em perfil.ini, fora dos slots de save.
// ---------------------------------------------------------------------
#macro PERFIL_ARQ "perfil.ini"
#macro PERFIL_NOME_MAX 14

function perfil_stats_nomes() { return ["inimigos", "javalis", "execucoes", "aparos", "orbs", "segredos", "sequencias", "fases", "maior_combo"]; }

function perfil_carregar()
{
    global.perfil = { nome: "", espada_fx: "carmesim", titulo: "", conquistas: {}, stats: {}, sujo: false, ultimo_slot: 0, fase_max: 1 };
    var _st = perfil_stats_nomes();
    for (var _j = 0; _j < array_length(_st); _j++) global.perfil.stats[$ _st[_j]] = 0;
    if (!file_exists(PERFIL_ARQ)) return;
    ini_open(PERFIL_ARQ);
    global.perfil.nome = string_copy(ini_read_string("perfil", "nome", ""), 1, PERFIL_NOME_MAX);
    global.perfil.espada_fx = ini_read_string("perfil", "espada", "carmesim");
    global.perfil.titulo = ini_read_string("perfil", "titulo", "");
    global.perfil.ultimo_slot = round(ini_read_real("perfil", "ultimo_slot", 0));     // v1.20: o progresso é do perfil
    global.perfil.fase_max = round(ini_read_real("perfil", "fase_max", 1));
    var _l = conquistas_lista();
    for (var _i = 0; _i < array_length(_l); _i++)
    {
        var _d = ini_read_string("conquistas", _l[_i].id, "");
        if (_d != "") global.perfil.conquistas[$ _l[_i].id] = _d;
    }
    for (var _k = 0; _k < array_length(_st); _k++) global.perfil.stats[$ _st[_k]] = ini_read_real("stats", _st[_k], 0);
    ini_close();
    if (!espada_estilo_liberado(global.perfil.espada_fx)) global.perfil.espada_fx = "carmesim";
}

function perfil_salvar()
{
    if (!variable_global_exists("perfil")) return;
    ini_open(PERFIL_ARQ);
    ini_write_string("perfil", "nome", global.perfil.nome);
    ini_write_string("perfil", "espada", global.perfil.espada_fx);
    ini_write_string("perfil", "titulo", global.perfil.titulo);
    ini_write_real("perfil", "ultimo_slot", global.perfil.ultimo_slot);
    ini_write_real("perfil", "fase_max", global.perfil.fase_max);
    var _nomes = variable_struct_get_names(global.perfil.conquistas);
    for (var _i = 0; _i < array_length(_nomes); _i++) ini_write_string("conquistas", _nomes[_i], global.perfil.conquistas[$ _nomes[_i]]);
    var _st = perfil_stats_nomes();
    for (var _k = 0; _k < array_length(_st); _k++) ini_write_real("stats", _st[_k], global.perfil.stats[$ _st[_k]]);
    ini_close();
    global.perfil.sujo = false;
}

// Salva só se algum número mudou (chamado nos checkpoints, no fim da fase e no menu)
function perfil_salvar_se_mudou()
{
    if (variable_global_exists("perfil") and global.perfil.sujo) perfil_salvar();
}

function perfil_nome_exibir()
{
    if (!variable_global_exists("perfil")) perfil_carregar();
    return (global.perfil.nome == "") ? "JOGADOR" : global.perfil.nome;
}

// Soma um número da carreira e confere as conquistas ligadas a ele
function perfil_somar(_stat, _n = 1)
{
    if (!variable_global_exists("perfil")) perfil_carregar();
    var _v = global.perfil.stats[$ _stat];
    if (is_undefined(_v)) _v = 0;
    _v += _n;
    global.perfil.stats[$ _stat] = _v;
    global.perfil.sujo = true;
    switch (_stat)
    {
        case "inimigos":   if (_v >= 1) conquista("primeiro_sangue"); if (_v >= 100) conquista("ceifador"); break;
        case "javalis":    if (_v >= 10) conquista("javalis"); break;
        case "execucoes":  if (_v >= 10) conquista("executor"); break;
        case "aparos":     if (_v >= 15) conquista("aparar"); break;
        case "orbs":       if (_v >= 3000) conquista("colecionador"); break;
        case "segredos":   if (_v >= 1) conquista("segredo"); break;
        case "sequencias": if (_v >= 1) conquista("sequencia"); break;
    }
}

// Guarda o maior valor (o combo mais longo)
function perfil_maximo(_stat, _v)
{
    if (!variable_global_exists("perfil")) perfil_carregar();
    var _a = global.perfil.stats[$ _stat];
    if (is_undefined(_a) or _v > _a) { global.perfil.stats[$ _stat] = _v; global.perfil.sujo = true; }
    if (_stat == "maior_combo" and _v >= 20) conquista("combo20");
}

// ---------------------------------------------------------------------
// CONQUISTAS E RECOMPENSAS
// rtipo: "orbs" (entram na hora na partida), "espada" (um estilo de lâmina
// para escolher no PERFIL) ou "titulo" (aparece ao lado do nome)
// ---------------------------------------------------------------------
function conquistas_lista()
{
    return [
        { id: "primeiro_sangue", nome: "PRIMEIRO SANGUE",          desc: "Derrote o primeiro inimigo.",                          rtipo: "orbs",   rval: 100 },
        { id: "ceifador",        nome: "CEIFADOR DE VALLACK",      desc: "Derrote 100 inimigos (somando todas as partidas).",    rtipo: "espada", rval: "sombria" },
        { id: "javalis",         nome: "CAÇADOR DE JAVALIS",       desc: "Derrote 10 javalis de guerra.",                        rtipo: "orbs",   rval: 150 },
        { id: "escalador",       nome: "ALÉM DA PALIÇADA",         desc: "Suba ao forte de madeira da vila.",                    rtipo: "orbs",   rval: 80 },
        { id: "chave",           nome: "CHAVE DO BASTIÃO",         desc: "Abra o portão trancado.",                              rtipo: "orbs",   rval: 150 },
        { id: "segredo",         nome: "OLHOS DE CAÇADOR",         desc: "Encontre um muro secreto.",                            rtipo: "orbs",   rval: 100 },
        { id: "furia",           nome: "IRA DESPERTA",             desc: "Ative o Modo Fúria.",                                  rtipo: "orbs",   rval: 100 },
        { id: "combo20",         nome: "TEMPESTADE DE AÇO",        desc: "Faça um combo de 20 golpes.",                          rtipo: "espada", rval: "glacial" },
        { id: "aparar",          nome: "LÂMINA DE ESPELHO",        desc: "Apare 15 golpes.",                                     rtipo: "espada", rval: "esmeralda" },
        { id: "executor",        nome: "EXECUTOR",                 desc: "Execute 10 inimigos com o finalizador.",               rtipo: "titulo", rval: "O EXECUTOR" },
        { id: "carrasco",        nome: "O CARRASCO CAIU",          desc: "Derrote o Carrasco de Vallack.",                       rtipo: "espada", rval: "dourada" },
        { id: "intocavel",       nome: "INTOCÁVEL",                desc: "Derrote o Carrasco sem levar dano.",                   rtipo: "titulo", rval: "O INTOCÁVEL" },
        { id: "sequencia",       nome: "MÃOS DE AÇO",              desc: "Complete uma sequência de golpes.",                    rtipo: "orbs",   rval: 200 },
        { id: "arvore",          nome: "RAÍZES EM CINZAS",         desc: "Derrote a Árvore Amaldiçoada.",                        rtipo: "espada", rval: "violeta" },
        { id: "perfeita",        nome: "SEQUÊNCIA PERFEITA",       desc: "Derrote a Árvore sem errar a sequência de golpes.",    rtipo: "titulo", rval: "O IMPLACÁVEL" },
        { id: "espada_max",      nome: "AÇO LENDÁRIO",             desc: "Evolua a espada até o nível máximo.",                  rtipo: "orbs",   rval: 300 },
        { id: "fase1",           nome: "A VILA FOI VINGADA",       desc: "Conclua a fase 1.",                                    rtipo: "titulo", rval: "HERÓI DA VILA" },
        { id: "veloz",           nome: "CORRIDA CONTRA A MALDIÇÃO", desc: "Conclua a fase 1 em menos de 15 minutos.",            rtipo: "orbs",   rval: 250 },
        { id: "dificil",         nome: "SANGUE DE AÇO",            desc: "Conclua a fase 1 no DIFÍCIL ou no EXTREMO.",           rtipo: "titulo", rval: "SANGUE DE AÇO" },
        { id: "extremo",         nome: "LENDA DE VALLACK",         desc: "Conclua a fase 1 no EXTREMO.",                         rtipo: "titulo", rval: "LENDA DE VALLACK" },
        { id: "colecionador",    nome: "ALMAS SEM FIM",            desc: "Colete 3000 orbs (somando todas as partidas).",        rtipo: "titulo", rval: "COLECIONADOR DE ALMAS" }
    ];
}

function conquista_dados(_id)
{
    var _l = conquistas_lista();
    for (var _i = 0; _i < array_length(_l); _i++) if (_l[_i].id == _id) return _l[_i];
    return undefined;
}

function conquista_tem(_id)
{
    if (!variable_global_exists("perfil")) perfil_carregar();
    return !is_undefined(global.perfil.conquistas[$ _id]);
}

function conquistas_feitas()
{
    if (!variable_global_exists("perfil")) perfil_carregar();
    return array_length(variable_struct_get_names(global.perfil.conquistas));
}

function recompensa_texto(_c)
{
    switch (_c.rtipo)
    {
        case "orbs":   return "+" + string(_c.rval) + " ORBS";
        case "espada": return "NOVA LÂMINA: " + espada_estilo(_c.rval).nome;
        case "titulo": return "TÍTULO: " + _c.rval;
    }
    return "";
}

// Títulos ganhos (o jogador escolhe um no PERFIL)
function titulos_liberados()
{
    var _r = [];
    var _l = conquistas_lista();
    for (var _i = 0; _i < array_length(_l); _i++) if (_l[_i].rtipo == "titulo" and conquista_tem(_l[_i].id)) array_push(_r, _l[_i].rval);
    return _r;
}

function conquista_data_hoje()
{
    var _d = date_current_datetime();
    return string_replace_all(string_format(date_get_day(_d), 2, 0), " ", "0") + "/" + string_replace_all(string_format(date_get_month(_d), 2, 0), " ", "0") + "/" + string(date_get_year(_d));
}

// Desbloqueia (uma vez só): grava no perfil, dá a recompensa e mostra o aviso
function conquista(_id)
{
    if (!variable_global_exists("perfil")) perfil_carregar();
    if (conquista_tem(_id)) return false;
    var _c = conquista_dados(_id);
    if (is_undefined(_c)) return false;
    global.perfil.conquistas[$ _id] = conquista_data_hoje();
    if (_c.rtipo == "orbs" and room != rm_menu) { global.orbs += _c.rval; global.orbs_fx = 20; }
    if (_c.rtipo == "titulo" and global.perfil.titulo == "") global.perfil.titulo = _c.rval;
    array_push(global.conquistas_fila, { id: _id, t: 0 });
    som("sfx_important_message", 0.75, 0);
    // v1.18: TRAVADAS — gravar no meio da luta engasgava (e um combo libera
    // várias de uma vez). Agora grava uma vez só, 2 s depois (obj_sistema),
    // ou ao fechar o jogo (obj_sistema, Game End).
    global.perfil.sujo = true;
    global.perfil_salvar_t = 120;
    return true;
}

// Emblema dourado das conquistas (escudo com uma estrela de 5 pontas)
function conquista_emblema(_x, _y, _r, _alpha, _t, _apagado = false)
{
    var _ouro = _apagado ? make_color_rgb(90, 80, 74) : make_color_rgb(236, 186, 84);
    var _esc = _apagado ? make_color_rgb(34, 30, 30) : make_color_rgb(92, 24, 18);
    if (!_apagado)
    {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_alpha * (0.18 + 0.08 * sin(_t / 9)));
        draw_set_color(make_color_rgb(255, 150, 60));
        draw_circle(_x, _y, _r * 1.45, false);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_alpha(_alpha);
    draw_set_color(_ouro);
    draw_circle(_x, _y, _r, false);
    draw_set_color(_esc);
    draw_circle(_x, _y, _r * 0.8, false);
    draw_set_color(_ouro);
    for (var _k = 0; _k < 5; _k++)
    {
        var _a = 90 + _k * 72;
        draw_triangle(_x, _y, _x + lengthdir_x(_r * 0.66, _a), _y + lengthdir_y(_r * 0.66, _a), _x + lengthdir_x(_r * 0.27, _a + 36), _y + lengthdir_y(_r * 0.27, _a + 36), false);
        draw_triangle(_x, _y, _x + lengthdir_x(_r * 0.66, _a), _y + lengthdir_y(_r * 0.66, _a), _x + lengthdir_x(_r * 0.27, _a - 36), _y + lengthdir_y(_r * 0.27, _a - 36), false);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// Aviso de conquista no canto direito (chamado pelo obj_sistema no Draw GUI End)
function conquistas_toast_desenhar()
{
    if (!variable_global_exists("conquistas_fila") or array_length(global.conquistas_fila) == 0) return;
    var _c = global.conquistas_fila[0];
    _c.t += global.dt_real;
    var _dur = 280;
    if (_c.t >= _dur) { array_delete(global.conquistas_fila, 0, 1); return; }
    var _d = conquista_dados(_c.id);
    if (is_undefined(_d)) { array_delete(global.conquistas_fila, 0, 1); return; }
    var _gw = display_get_gui_width();
    var _k = min(clamp(_c.t / 18, 0, 1), clamp((_dur - _c.t) / 18, 0, 1));
    var _e = 1 - power(1 - _k, 3);
    var _w = 500;
    var _h = 108;
    var _x2 = _gw - 18 + (1 - _e) * (_w + 40);
    var _x1 = _x2 - _w;
    var _y1 = 120;
    var _y2 = _y1 + _h;
    hud_faixa(_x1, _y1, _x2, _y2, 0.97 * _k);
    conquista_emblema(_x1 + 56, (_y1 + _y2) / 2, 30, _k, current_time / 16);
    var _ouro = make_color_rgb(236, 186, 84);
    txt(_x1 + 100, _y1 + 22, "CONQUISTA DESBLOQUEADA", FONTE.MINI, _ouro, _k, fa_left, fa_middle);
    txt(_x2 - 18, _y1 + 22, perfil_nome_exibir(), FONTE.MINI, make_color_rgb(200, 180, 170), _k, fa_right, fa_middle, min(1, 150 / max(1, txt_largura(perfil_nome_exibir(), FONTE.MINI))));
    txt_sombra(_x1 + 100, _y1 + 52, _d.nome, FONTE.PEQUENA, make_color_rgb(252, 244, 230), _k, fa_left, fa_middle, min(1, (_w - 120) / max(1, txt_largura(_d.nome, FONTE.PEQUENA))));
    txt(_x1 + 100, _y1 + 82, recompensa_texto(_d), FONTE.MINI, make_color_rgb(255, 140, 100), _k, fa_left, fa_middle);
    desenho_resetar();
}

// ---------------------------------------------------------------------
// O MAPA: 18 fases num caminho em chamas. Só a primeira está aberta; as
// outras estão trancadas "EM DESENVOLVIMENTO". A última é o covil do dragão.
// img: a foto do cenário (datafiles/fase_NN.png, ferramentas/gerar_mapa.ps1)
// ---------------------------------------------------------------------
#macro MAPA_FASES 18

function fases_mapa()
{
    return [
        { nome: "A CAMINHO DO CASTELO",      desc: "A vila de Twilight arde na maldição de Vallack. Atravesse as ruas em chamas, enfrente o Carrasco e derrube a Árvore Amaldiçoada que guarda a estrada." },
        { nome: "O SALÃO REAL EM RUÍNAS",    desc: "No coração do castelo, a maldição aguarda. O salão do rei virou ninho de monstros." },
        { nome: "AS MURALHAS DE VALLACK",    desc: "As muralhas tomadas por esqueletos e arqueiros. Escale as torres sob a chuva de flechas." },
        { nome: "O PÂNTANO DOS AFOGADOS",    desc: "Névoa venenosa e almas presas na lama. Nada sob a água está realmente morto." },
        { nome: "A FLORESTA DE ESPINHOS",    desc: "Árvores que sangram e raízes que caçam. Dizem que a maldição nasceu aqui." },
        { nome: "AS MINAS DE CINZA",         desc: "Túneis de carvão em brasa, onde os mineiros nunca pararam de cavar." },
        { nome: "A CATEDRAL PARTIDA",        desc: "Vitrais quebrados e um coro de mortos. A fé de Vallack virou pó." },
        { nome: "O CEMITÉRIO DOS REIS",      desc: "Tumbas abertas e reis sem descanso, ainda de coroa." },
        { nome: "A PONTE DO ABISMO",         desc: "Uma ponte de correntes sobre o nada. Cada passo acorda o que mora embaixo." },
        { nome: "AS TERRAS QUEIMADAS",       desc: "Campos de batalha que ainda ardem. O vento traz os gritos de guerras antigas." },
        { nome: "A FORJA DOS CONDENADOS",    desc: "Ferreiros acorrentados forjam, dia e noite, as armas da maldição." },
        { nome: "O LAGO DE GELO NEGRO",      desc: "Gelo escuro sobre um lago sem fundo. Os afogados olham de baixo." },
        { nome: "A TORRE DO ALQUIMISTA",     desc: "Frascos, venenos e experimentos que escaparam das jaulas." },
        { nome: "O LABIRINTO DE OSSOS",      desc: "Corredores erguidos com os restos de um exército inteiro." },
        { nome: "O PORTO FANTASMA",          desc: "Navios sem tripulação atracados na névoa. Os sinos tocam sozinhos." },
        { nome: "O SANTUÁRIO DE SYLLA",      desc: "O templo da chama sagrada, agora corrompida pela maldição." },
        { nome: "O TRONO DE VALLACK",        desc: "O salão do rei que trouxe a maldição. Ele ainda espera." },
        { nome: "O COVIL DO DRAGÃO",         desc: "Além do trono, sob o céu em chamas, o dragão de Vallack desperta. O chefão de toda a maldição." }
    ];
}

function fase_mapa_livre(_i) { return _i == 0; }

function romano(_n)
{
    var _v = [10, 9, 5, 4, 1];
    var _s = ["X", "IX", "V", "IV", "I"];
    var _r = "";
    for (var _i = 0; _i < 5; _i++) while (_n >= _v[_i]) { _r += _s[_i]; _n -= _v[_i]; }
    return _r;
}

// Moldura dourada (gótica) em volta de uma foto
function moldura_dourada(_x1, _y1, _x2, _y2, _alpha, _brilho = 0)
{
    var _ouro = make_color_rgb(196, 150, 70);
    var _esc = make_color_rgb(40, 22, 16);
    draw_set_alpha(_alpha);
    draw_set_color(_esc);
    draw_rectangle(_x1 - 7, _y1 - 7, _x2 + 7, _y2 + 7, false);
    draw_set_color(_ouro);
    draw_rectangle(_x1 - 5, _y1 - 5, _x2 + 5, _y2 + 5, true);
    draw_rectangle(_x1 - 2, _y1 - 2, _x2 + 2, _y2 + 2, true);
    var _cs = [[_x1, _y1], [_x2, _y1], [_x1, _y2], [_x2, _y2]];
    for (var _k = 0; _k < 4; _k++)
    {
        draw_set_color(_ouro);
        draw_rectangle(_cs[_k][0] - 8, _cs[_k][1] - 8, _cs[_k][0] + 8, _cs[_k][1] + 8, false);
        draw_set_color(_esc);
        draw_rectangle(_cs[_k][0] - 4, _cs[_k][1] - 4, _cs[_k][0] + 4, _cs[_k][1] + 4, false);
    }
    if (_brilho > 0)
    {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_alpha * _brilho * 0.5);
        draw_set_color(make_color_rgb(255, 120, 40));
        draw_rectangle(_x1 - 10, _y1 - 10, _x2 + 10, _y2 + 10, true);
        draw_rectangle(_x1 - 12, _y1 - 12, _x2 + 12, _y2 + 12, true);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_alpha(1);
}

// Cadeado grande (fases trancadas do mapa)
function cadeado_grande(_x, _y, _esc, _alpha)
{
    var _ouro = make_color_rgb(206, 166, 84);
    var _esc_c = make_color_rgb(34, 24, 18);
    draw_set_alpha(_alpha);
    // alça
    draw_set_color(_esc_c);
    draw_circle(_x, _y - 10 * _esc, 13 * _esc, false);
    draw_set_color(_ouro);
    draw_circle(_x, _y - 10 * _esc, 13 * _esc, true);
    draw_circle(_x, _y - 10 * _esc, 10 * _esc, true);
    draw_set_color(_esc_c);
    draw_circle(_x, _y - 10 * _esc, 8 * _esc, false);
    // corpo
    draw_set_color(_esc_c);
    draw_roundrect_ext(_x - 17 * _esc, _y - 4 * _esc, _x + 17 * _esc, _y + 22 * _esc, 5 * _esc, 5 * _esc, false);
    draw_set_color(_ouro);
    draw_roundrect_ext(_x - 15 * _esc, _y - 2 * _esc, _x + 15 * _esc, _y + 20 * _esc, 4 * _esc, 4 * _esc, false);
    draw_set_color(make_color_rgb(150, 108, 46));
    draw_rectangle(_x - 15 * _esc, _y + 12 * _esc, _x + 15 * _esc, _y + 20 * _esc, false);
    // fechadura
    draw_set_color(_esc_c);
    draw_circle(_x, _y + 5 * _esc, 3.5 * _esc, false);
    draw_rectangle(_x - 1.5 * _esc, _y + 5 * _esc, _x + 1.5 * _esc, _y + 13 * _esc, false);
    draw_set_alpha(1);
}

// O DRAGÃO de Vallack (silhueta animada, voando ao lado da última fase).
// _dir 1 = olhando para a direita. _fogo 0..1 = baforada de fogo.
function dragao_desenhar(_x, _y, _esc, _dir, _t, _fogo = 0)
{
    var _corpo = make_color_rgb(30, 10, 14);
    var _membrana = make_color_rgb(58, 14, 20);
    var _bater = sin(_t * 0.16);
    var _s = _esc;
    var _d = _dir;
    // helper de ponto relativo: (x local, y local) -> mundo
    // asa de trás (mais escura)
    var _ombro_x = _x + _d * 2 * _s;
    var _ombro_y = _y - 8 * _s;
    var _pontas = [[-34, -58], [-6, -70], [22, -52]];
    for (var _asa = 0; _asa < 2; _asa++)
    {
        var _k = (_asa == 0) ? 0.8 : 1;
        var _flap = (_asa == 0) ? _bater * 0.85 : _bater;
        var _cor = (_asa == 0) ? merge_color(_membrana, c_black, 0.45) : _membrana;
        var _ox = _ombro_x + ((_asa == 0) ? _d * 6 * _s : 0);
        var _oy = _ombro_y - ((_asa == 0) ? 3 * _s : 0);
        var _cotovelo_x = _ox + _d * (-10) * _s * _k;
        var _cotovelo_y = _oy + (-34 - 22 * _flap) * _s * _k;
        draw_set_color(_cor);
        draw_set_alpha(1);
        var _ant_x = _ox + _d * 26 * _s;
        var _ant_y = _oy + 6 * _s;
        for (var _p = 0; _p < 3; _p++)
        {
            var _px = _cotovelo_x + _d * _pontas[_p][0] * 0.6 * _s * _k;
            var _py = _cotovelo_y + (_pontas[_p][1] * 0.45 - 40 * _flap * (0.4 + 0.3 * _p)) * _s * _k + 30 * _s * _k;
            draw_triangle(_cotovelo_x, _cotovelo_y, _px, _py, _ant_x, _ant_y, false);
            draw_set_color(_corpo);
            draw_line_width(_cotovelo_x, _cotovelo_y, _px, _py, 2 * _s);
            draw_set_color(_cor);
            _ant_x = _px;
            _ant_y = _py;
        }
        draw_triangle(_cotovelo_x, _cotovelo_y, _ant_x, _ant_y, _ox - _d * 30 * _s, _oy + 4 * _s, false);
        draw_set_color(_corpo);
        draw_line_width(_ox, _oy, _cotovelo_x, _cotovelo_y, 4 * _s);
        if (_asa == 0)
        {
            // corpo, pescoço, cabeça e cauda entre as duas asas
            draw_set_color(_corpo);
            draw_ellipse(_x - 38 * _s, _y - 13 * _s, _x + 34 * _s, _y + 11 * _s, false);
            // cauda ondulando
            var _cx = _x - _d * 34 * _s;
            var _cy = _y;
            for (var _c = 1; _c <= 9; _c++)
            {
                var _nx = _x - _d * (34 + _c * 9) * _s;
                var _ny = _y + sin(_t * 0.12 + _c * 0.65) * _c * 1.5 * _s;
                draw_line_width(_cx, _cy, _nx, _ny, (9 - _c * 0.8) * _s);
                _cx = _nx;
                _cy = _ny;
            }
            draw_triangle(_cx, _cy, _cx - _d * 12 * _s, _cy - 7 * _s, _cx - _d * 10 * _s, _cy + 7 * _s, false);
            // pescoço e cabeça
            var _hx = _x + _d * 30 * _s;
            var _hy = _y - 4 * _s;
            for (var _c2 = 1; _c2 <= 4; _c2++)
            {
                var _nx2 = _x + _d * (30 + _c2 * 8) * _s;
                var _ny2 = _y - (4 + _c2 * 5 + sin(_t * 0.1) * 2) * _s;
                draw_line_width(_hx, _hy, _nx2, _ny2, (11 - _c2 * 1.4) * _s);
                _hx = _nx2;
                _hy = _ny2;
            }
            draw_ellipse(_hx - 8 * _s, _hy - 6 * _s, _hx + 8 * _s, _hy + 5 * _s, false);
            draw_triangle(_hx + _d * 4 * _s, _hy - 4 * _s, _hx + _d * 22 * _s, _hy + 1 * _s, _hx + _d * 4 * _s, _hy + 5 * _s, false);
            draw_triangle(_hx - _d * 2 * _s, _hy - 4 * _s, _hx - _d * 14 * _s, _hy - 14 * _s, _hx - _d * 6 * _s, _hy - 1 * _s, false);
            // olho em brasa
            gpu_set_blendmode(bm_add);
            draw_set_color(make_color_rgb(255, 170, 50));
            draw_set_alpha(0.9);
            draw_circle(_hx + _d * 5 * _s, _hy - 2 * _s, 1.8 * _s, false);
            draw_set_alpha(0.3);
            draw_circle(_hx + _d * 5 * _s, _hy - 2 * _s, 5 * _s, false);
            // baforada de fogo
            if (_fogo > 0)
            {
                var _bx = _hx + _d * 20 * _s;
                var _by = _hy + 2 * _s;
                var _L = 120 * _s * _fogo;
                var _cores = [make_color_rgb(200, 40, 10), make_color_rgb(255, 130, 30), make_color_rgb(255, 230, 140)];
                for (var _f = 0; _f < 3; _f++)
                {
                    var _w = (26 - _f * 8) * _s * _fogo;
                    draw_set_color(_cores[_f]);
                    draw_set_alpha(0.55 + 0.15 * _f);
                    draw_triangle(_bx, _by, _bx + _d * _L * (1 - _f * 0.2), _by - _w + sin(_t * 0.7 + _f) * 4 * _s, _bx + _d * _L * (1 - _f * 0.2), _by + _w + sin(_t * 0.9 + _f) * 4 * _s, false);
                }
            }
            gpu_set_blendmode(bm_normal);
            draw_set_alpha(1);
        }
    }
    // contorno de luz vermelha (a chama do covil por trás)
    draw_set_alpha(1);
    draw_set_color(c_white);
}
function fase_mapa_img(_i) { return "fase_" + string_replace_all(string_format(_i + 1, 2, 0), " ", "0") + ".png"; }

// ---------------------------------------------------------------------
// MENU INICIAL MAIS VIVO (executado no obj_menu): tochas ao lado da lista,
// braseiros embaixo, faíscas seguindo o ponteiro / o dedo, explosão de fogo
// no clique / toque e o cenário acompanhando o ponteiro (paralaxe)
// ---------------------------------------------------------------------
function menu_braseiros()
{
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    return [[_gw * 0.57, _gh - 50], [_gw * 0.95, _gh - 50]];     // na frente do busto de Twilight
}

function menu_tochas()
{
    var _mx = max(70, display_get_gui_width() * 0.075);
    return [[_mx - 42, 352], [_mx + 372, 352]];
}

function menu_fogo_atualizar(_mx, _my, _mexeu, _clique, _dt)
{
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _q = global.cfg_qualidade;
    var _max = (_q == 0) ? 60 : ((_q == 1) ? 130 : 220);
    ponteiro_x = lerp(ponteiro_x, _mx, 1 - power(0.92, _dt));
    ponteiro_y = lerp(ponteiro_y, _my, 1 - power(0.92, _dt));
    paralaxe_x = clamp((ponteiro_x - _gw / 2) / (_gw / 2), -1, 1);
    paralaxe_y = clamp((ponteiro_y - _gh / 2) / (_gh / 2), -1, 1);
    var _cores = [make_color_rgb(255, 200, 90), make_color_rgb(255, 130, 40), make_color_rgb(255, 70, 30)];
    if (_mexeu and array_length(fogo_part) < _max)
        repeat (2) array_push(fogo_part, { x: _mx + random_range(-5, 5), y: _my + random_range(-5, 5), vx: random_range(-0.8, 0.8), vy: random_range(-2.2, -0.6), v: random_range(24, 48), vmax: 48, r: random_range(1.2, 2.6), cor: _cores[irandom(2)] });
    if (_clique)
    {
        array_push(fogo_ondas, { x: _mx, y: _my, t: 0 });
        repeat ((_q == 0) ? 10 : 24)
        {
            var _ang = random(360);
            var _v = random_range(1.5, 6);
            array_push(fogo_part, { x: _mx, y: _my, vx: lengthdir_x(_v, _ang), vy: lengthdir_y(_v, _ang) - 1, v: random_range(30, 60), vmax: 60, r: random_range(1.4, 3), cor: _cores[irandom(2)] });
        }
    }
    var _bras = menu_braseiros();
    for (var _b = 0; _b < array_length(_bras); _b++)
        if (random(1) < 0.45 * _dt and array_length(fogo_part) < _max)
            array_push(fogo_part, { x: _bras[_b][0] + random_range(-20, 20), y: _bras[_b][1] - 26, vx: random_range(-0.5, 0.5), vy: random_range(-2.8, -1.1), v: random_range(50, 100), vmax: 100, r: random_range(1, 2.3), cor: _cores[irandom(2)] });
    for (var _i = array_length(fogo_part) - 1; _i >= 0; _i--)
    {
        var _p = fogo_part[_i];
        _p.x += (_p.vx + sin(current_time / 300 + _i) * 0.15) * _dt;
        _p.y += _p.vy * _dt;
        _p.vy -= 0.012 * _dt;
        _p.vx *= power(0.98, _dt);
        _p.v -= _dt;
        if (_p.v <= 0) array_delete(fogo_part, _i, 1);
    }
    for (var _o = array_length(fogo_ondas) - 1; _o >= 0; _o--)
    {
        fogo_ondas[_o].t += _dt;
        if (fogo_ondas[_o].t > 30) array_delete(fogo_ondas, _o, 1);
    }
}

function menu_fogo_desenhar(_a, _t, _com_tochas)
{
    if (_a <= 0) return;
    // braseiros de ferro com fogo alto
    var _bras = menu_braseiros();
    for (var _b = 0; _b < array_length(_bras); _b++)
    {
        var _bx = _bras[_b][0];
        var _by = _bras[_b][1];
        var _fl = 0.8 + 0.2 * sin(_t / 7 + _b) * sin(_t / 17 + _b * 2);
        gpu_set_blendmode(bm_add);
        draw_set_color(make_color_rgb(255, 110, 30));
        for (var _cl = 0; _cl < 5; _cl++) { draw_set_alpha(0.045 * _fl * _a); draw_circle(_bx, _by - 36, 130 - _cl * 24, false); }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(_a);
        draw_set_color(make_color_rgb(22, 14, 12));
        draw_line_width(_bx - 26, _by + 4, _bx - 36, _by + 46, 4);
        draw_line_width(_bx + 26, _by + 4, _bx + 36, _by + 46, 4);
        draw_line_width(_bx, _by + 4, _bx, _by + 46, 4);
        desenhar_chamas(_bx, _by - 6, 30, 62 + 8 * sin(_t / 11 + _b), _t + _b * 40, _a, _b * 7, 2);
        draw_set_alpha(_a);
        draw_set_color(make_color_rgb(34, 22, 18));
        draw_ellipse(_bx - 40, _by - 12, _bx + 40, _by + 14, false);
        draw_set_color(make_color_rgb(70, 50, 40));
        draw_ellipse(_bx - 40, _by - 12, _bx + 40, _by + 2, true);
        draw_set_color(make_color_rgb(255, 120, 40));
        draw_set_alpha(0.7 * _a);
        draw_ellipse(_bx - 34, _by - 9, _bx + 34, _by - 1, false);
    }
    // tochas de parede ao lado da lista do menu
    if (_com_tochas)
    {
        var _to = menu_tochas();
        for (var _k = 0; _k < array_length(_to); _k++)
        {
            var _tx = _to[_k][0];
            var _ty = _to[_k][1];
            var _f2 = 0.8 + 0.2 * sin(_t / 5 + _k * 3) * sin(_t / 13 + _k);
            gpu_set_blendmode(bm_add);
            draw_set_color(make_color_rgb(255, 120, 40));
            for (var _cl2 = 0; _cl2 < 5; _cl2++) { draw_set_alpha(0.04 * _f2 * _a); draw_circle(_tx, _ty - 36, 115 - _cl2 * 21, false); }
            gpu_set_blendmode(bm_normal);
            draw_set_alpha(_a);
            draw_set_color(make_color_rgb(26, 20, 18));
            draw_rectangle(_tx - 10, _ty + 26, _tx + 10, _ty + 34, false);
            draw_line_width(_tx, _ty + 30, _tx, _ty + 4, 3);
            draw_set_color(make_color_rgb(92, 58, 32));
            draw_triangle(_tx - 6, _ty - 26, _tx + 6, _ty - 26, _tx + 3, _ty + 12, false);
            draw_triangle(_tx - 6, _ty - 26, _tx + 3, _ty + 12, _tx - 3, _ty + 12, false);
            draw_set_color(make_color_rgb(60, 40, 30));
            draw_rectangle(_tx - 8, _ty - 30, _tx + 8, _ty - 22, false);
            desenhar_chamas(_tx, _ty - 28, 11, 34 + 6 * sin(_t / 7 + _k), _t + _k * 25, _a, 3 + _k, 2);
        }
    }
    // faíscas do ponteiro, dos braseiros e dos cliques; anéis de fogo
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < array_length(fogo_part); _i++)
    {
        var _p = fogo_part[_i];
        draw_set_color(_p.cor);
        draw_set_alpha(clamp(_p.v / (_p.vmax * 0.5), 0, 1) * 0.9 * _a);
        draw_circle(_p.x, _p.y, _p.r, false);
    }
    for (var _o = 0; _o < array_length(fogo_ondas); _o++)
    {
        var _on = fogo_ondas[_o];
        var _ko = _on.t / 30;
        draw_set_color(make_color_rgb(255, 140, 50));
        draw_set_alpha((1 - _ko) * 0.7 * _a);
        draw_circle(_on.x, _on.y, 8 + 60 * _ko, true);
        draw_circle(_on.x, _on.y, 7 + 56 * _ko, true);
        draw_set_alpha((1 - _ko) * 0.25 * _a);
        draw_circle(_on.x, _on.y, 20 * (1 - _ko), false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ---------------------------------------------------------------------
// DICAS DA TELA DE CARREGAMENTO (passam embaixo, uma de cada vez)
// ---------------------------------------------------------------------
function dicas_carregamento()
{
    var _l = [];
    var _cb = combos_lista();
    for (var _i = 0; _i < array_length(_cb); _i++) array_push(_l, { ic: _cb[_i].seq, n: "COMBO  ·  " + _cb[_i].nome, t: _cb[_i].desc });
    array_push(_l, { ic: [ACAO.PULAR, ACAO.ATAQUE_FORTE], n: "LANÇADOR", t: "Quase juntos: o inimigo voa e Twilight sobe junto para o combo aéreo." });
    array_push(_l, { ic: [ACAO.ATACAR], n: "CORTE AÉREO", t: "No ar, até 3 cortes seguidos seguram o inimigo lá em cima." });
    array_push(_l, { ic: [ACAO.ATAQUE_FORTE], n: "MERGULHO", t: "PESADO no ar: Twilight despenca com a espada e abre o chão." });
    array_push(_l, { ic: [ACAO.ATAQUE_SALTO], n: "RASTEIRA", t: "Desliza por baixo dos golpes e joga os inimigos para cima." });
    array_push(_l, { ic: [ACAO.DEFENDER], n: "APARAR E CONTRA-ATACAR", t: "Defenda na hora exata do golpe: o inimigo fica tonto e Twilight revida sozinho." });
    array_push(_l, { ic: [ACAO.INTERAGIR], n: "EXECUÇÃO", t: "Inimigo com contorno vermelho: execute-o para recuperar vida e ganhar mais orbs." });
    array_push(_l, { ic: qte_acoes(), n: "SEQUÊNCIA DE GOLPES", t: "Chefe cambaleando: execute e aperte cada botão na hora. Errou? Ele se solta e volta a atacar." });
    array_push(_l, { ic: [ACAO.ESQUIVA], n: "ESQUIVA", t: "No meio da rolagem nada acerta Twilight. Parado, ela vira um salto para trás." });
    array_push(_l, { ic: [ACAO.FURIA], n: "MODO FÚRIA", t: "Fúria cheia: golpes mais rápidos, metade do dano recebido e roubo de vida." });
    array_push(_l, { ic: [ACAO.ESPECIAL_3], n: "MAGIA", t: "Os especiais gastam a barra azul e quebram qualquer guarda." });
    array_push(_l, { ic: [ACAO.ATACAR], n: "GOLPE CRÍTICO", t: "Acertar com a ponta da espada causa dano crítico." });
    return _l;
}
