// =====================================================================
//  scr_menu: configurações, sistema de vídeo (resolução / proporção /
//  tela cheia), fontes e funções de desenho da interface.
// =====================================================================

// ---------------------------------------------------------------------
// LISTAS DE VÍDEO
// ---------------------------------------------------------------------
// opções do menu: linhas 0..8 têm valor (« »); 9 TECLADO, 10 CONTROLE, 11 VOLTAR
#macro CFG_ULTIMO_VALOR 9
// linhas de volume do menu de pausa
#macro PAUSA_MUSICA  1
#macro PAUSA_EFEITOS 2

function config_nomes_proporcao() { return ["AUTOMÁTICA", "16:9", "16:10", "4:3", "21:9"]; }
function config_nomes_qualidade() { return ["BAIXA", "MÉDIA", "ALTA"]; }
function config_nomes_fps()       { return ["30 FPS", "60 FPS"]; }

// Proporção nativa do monitor em texto ("16:9", "16:10"...)
function config_nome_aspecto(_w, _h)
{
    var _a = _w / max(1, _h);
    var _lista = [[16/9, "16:9"], [16/10, "16:10"], [4/3, "4:3"], [5/4, "5:4"], [21/9, "21:9"], [32/9, "32:9"], [3/2, "3:2"]];
    var _melhor = "";
    var _dif = 999;
    for (var _i = 0; _i < array_length(_lista); _i++)
    {
        var _d = abs(_lista[_i][0] - _a);
        if (_d < _dif) { _dif = _d; _melhor = _lista[_i][1]; }
    }
    if (_dif > 0.04) _melhor = string_format(_a, 1, 2) + ":1";
    return _melhor;
}

// Lista de resoluções [largura, altura] para a proporção escolhida
function config_lista_resolucoes(_prop)
{
    switch (clamp(round(_prop), 0, 4))
    {
        case 1: return [[1280,720], [1366,768], [1600,900], [1920,1080], [2560,1440]];
        case 2: return [[1280,800], [1440,900], [1680,1050], [1920,1200], [2560,1600]];
        case 3: return [[960,720], [1024,768], [1280,960], [1440,1080]];
        case 4: return [[1680,720], [2560,1080], [3440,1440]];
    }
    // AUTOMÁTICA: segue a proporção do monitor
    var _dw = max(640, display_get_width());
    var _dh = max(480, display_get_height());
    var _a = _dw / _dh;
    var _alturas = [720, 900, 1080, 1440];
    var _lista = [];
    for (var _i = 0; _i < array_length(_alturas); _i++)
    {
        if (_alturas[_i] < _dh) array_push(_lista, [round(_alturas[_i] * _a / 2) * 2, _alturas[_i]]);
    }
    array_push(_lista, [_dw, _dh]);   // nativa
    return _lista;
}

function config_tamanho_resolucao(_prop, _res)
{
    var _lista = config_lista_resolucoes(_prop);
    return _lista[clamp(round(_res), 0, array_length(_lista) - 1)];
}

// ---------------------------------------------------------------------
// CARREGAR / SALVAR / APLICAR
// ---------------------------------------------------------------------
// nomes das ações no config.ini (mesma ordem do enum ACAO)
function config_chaves_controles()
{
    return ["left", "right", "jump", "attack", "special", "block", "interact", "crouch", "heavy", "sweep", "special2", "special3", "dodge", "rage"];
}
// a v1.4 mudou o esquema de botões (esquiva, fúria, interagir, START/SELECT):
// controles salvos por versões antigas são trocados pelo novo padrão
#macro CONTROLES_VERSAO 4

function config_carregar()
{
    var _chaves_t = config_chaves_controles();
    if (file_exists("config.ini"))
    {
        ini_open("config.ini");
        global.cfg_tela_cheia = ini_read_real("video", "tela_cheia", global.cfg_tela_cheia);
        // "proporcao2" é o formato novo (0 = automática). Configurações antigas
        // tinham 0=16:9 1=16:10 2=4:3 3=21:9 em "proporcao".
        if (ini_key_exists("video", "proporcao2")) global.cfg_proporcao = ini_read_real("video", "proporcao2", 0);
        else if (ini_key_exists("video", "proporcao")) global.cfg_proporcao = ini_read_real("video", "proporcao", 0) + 1;
        global.cfg_resolucao = ini_read_real("video", "resolucao", global.cfg_resolucao);
        global.cfg_qualidade = ini_read_real("video", "qualidade", global.cfg_qualidade);
        global.cfg_fps       = ini_read_real("video", "fps", global.cfg_fps);
        global.cfg_volume    = ini_read_real("audio", "volume", global.cfg_volume);
        global.cfg_fundo_hd  = ini_read_real("video", "fundo_hd", global.cfg_fundo_hd);
        global.cfg_tutorial  = ini_read_real("jogo", "tutorial", global.cfg_tutorial);
        global.cfg_vol_musica  = ini_read_real("audio", "musica", global.cfg_vol_musica);
        global.cfg_vol_efeitos = ini_read_real("audio", "efeitos", global.cfg_vol_efeitos);
        if (ini_read_real("controles", "versao", 0) >= CONTROLES_VERSAO)
        {
            for (var _i = 0; _i < ACAO.TOTAL; _i++)
            {
                global.teclas[_i] = ini_read_real("teclado",  _chaves_t[_i], global.teclas[_i]);
                global.botoes[_i] = ini_read_real("controle", _chaves_t[_i], global.botoes[_i]);
            }
        }
        ini_close();
    }
    config_validar_controles();
    config_aplicar();
}

function config_salvar()
{
    var _chaves_t = config_chaves_controles();
    ini_open("config.ini");
    ini_write_real("video", "tela_cheia", global.cfg_tela_cheia);
    ini_write_real("video", "proporcao2", global.cfg_proporcao);
    ini_write_real("video", "resolucao",  global.cfg_resolucao);
    ini_write_real("video", "qualidade",  global.cfg_qualidade);
    ini_write_real("video", "fps",        global.cfg_fps);
    ini_write_real("audio", "volume",     global.cfg_volume);
    ini_write_real("video", "fundo_hd",   global.cfg_fundo_hd);
    ini_write_real("jogo", "tutorial",    global.cfg_tutorial);
    ini_write_real("audio", "musica",     global.cfg_vol_musica);
    ini_write_real("audio", "efeitos",    global.cfg_vol_efeitos);
    ini_write_real("controles", "versao", CONTROLES_VERSAO);
    for (var _i = 0; _i < ACAO.TOTAL; _i++)
    {
        ini_write_real("teclado",  _chaves_t[_i], global.teclas[_i]);
        ini_write_real("controle", _chaves_t[_i], global.botoes[_i]);
    }
    ini_close();
}

// Corrige teclas inválidas, reservadas ou repetidas vindas de um config.ini antigo
function config_validar_controles()
{
    var _tp = teclas_padrao();
    var _bp = botoes_padrao();
    var _remap = botoes_remapeaveis();
    for (var _i = 0; _i < ACAO.TOTAL; _i++)
    {
        if (tecla_reservada(global.teclas[_i])) global.teclas[_i] = _tp[_i];
        if (!array_tem(_remap, global.botoes[_i]) and global.botoes[_i] != -1) global.botoes[_i] = _bp[_i];
        for (var _j = 0; _j < _i; _j++)
        {
            if (global.teclas[_j] == global.teclas[_i]) { global.teclas[_i] = _tp[_i]; global.teclas[_j] = _tp[_j]; }
            if (global.botoes[_j] == global.botoes[_i] and global.botoes[_i] != -1) { global.botoes[_i] = _bp[_i]; global.botoes[_j] = _bp[_j]; }
        }
    }
}

function config_aplicar()
{
    global.cfg_tela_cheia = clamp(round(global.cfg_tela_cheia), 0, 1);
    global.cfg_proporcao  = clamp(round(global.cfg_proporcao), 0, 4);
    global.cfg_resolucao  = clamp(round(global.cfg_resolucao), 0, array_length(config_lista_resolucoes(global.cfg_proporcao)) - 1);
    global.cfg_qualidade  = clamp(round(global.cfg_qualidade), 0, 2);
    global.cfg_fps        = clamp(round(global.cfg_fps), 0, 1);
    global.cfg_volume     = clamp(global.cfg_volume, 0, 1);
    global.cfg_vol_musica  = clamp(global.cfg_vol_musica, 0, 1);
    global.cfg_vol_efeitos = clamp(global.cfg_vol_efeitos, 0, 1);
    global.cfg_fundo_hd   = clamp(round(global.cfg_fundo_hd), 0, 1);
    global.cfg_tutorial   = clamp(round(global.cfg_tutorial), 0, 1);

    var _tam = config_tamanho_resolucao(global.cfg_proporcao, global.cfg_resolucao);
    global.cfg_window_width  = _tam[0];
    global.cfg_window_height = _tam[1];

    // O tamanho da janela é aplicado pelo tela_atualizar() (espera a troca
    // de tela cheia terminar antes de redimensionar).
    global.tela_redimensionar = true;

    game_set_speed(global.cfg_fps == 0 ? 30 : 60, gamespeed_fps);
    audio_master_gain(global.cfg_volume);
}

// ---------------------------------------------------------------------
// SISTEMA DE VÍDEO
// Regras:
//  * JANELA: a janela tem o tamanho/proporção escolhidos (reduzida se não
//    couber no monitor). O jogo ocupa 100% da janela.
//  * TELA CHEIA: o jogo ocupa 100% do monitor, sem barras e sem distorção,
//    usando a proporção nativa do monitor. A resolução escolhida vira a
//    resolução interna de renderização.
//  * A câmera, a application surface, o viewport e a GUI seguem SEMPRE a
//    proporção real da janela — por isso nenhum canto fica descoberto.
// ---------------------------------------------------------------------
function config_redimensionar_janela()
{
    var _max_w = max(320, display_get_width()  - 40);
    var _max_h = max(240, display_get_height() - 100);
    var _escala = min(1, _max_w / global.cfg_window_width, _max_h / global.cfg_window_height);
    window_set_size(floor(global.cfg_window_width * _escala), floor(global.cfg_window_height * _escala));
    global.tela_centralizar = 2;   // centraliza depois que o sistema aplicar o novo tamanho
}

function tela_atualizar()
{
    var _cheia = (global.cfg_tela_cheia == 1);

    // 1) Entrar / sair da tela cheia
    if (window_get_fullscreen() != _cheia and global.tela_trocando <= 0)
    {
        window_set_fullscreen(_cheia);
        global.tela_trocando = 10;           // o GameMaker leva alguns quadros para trocar
        global.tela_redimensionar = true;
    }
    if (global.tela_trocando > 0) global.tela_trocando -= 1;

    // 2) Tamanho da janela (só no modo janela, depois da troca terminar)
    if (!_cheia and global.tela_trocando <= 0 and global.tela_redimensionar and !window_get_fullscreen())
    {
        global.tela_redimensionar = false;
        config_redimensionar_janela();
    }
    if (_cheia) global.tela_redimensionar = false;
    if (global.tela_centralizar > 0)
    {
        global.tela_centralizar -= 1;
        if (global.tela_centralizar == 0 and !window_get_fullscreen()) window_center();
    }

    var _ww = window_get_width();
    var _wh = window_get_height();
    if (_ww <= 0 or _wh <= 0) return;      // janela minimizada
    var _aspecto = _ww / _wh;
    global.tela_aspecto = _aspecto;

    // 3) Resolução interna (application surface) — mesma proporção da janela
    var _rw = _ww;
    var _rh = _wh;
    if (window_get_fullscreen())
    {
        _rh = clamp(global.cfg_window_height, 360, _wh);
        _rw = round(_rh * _aspecto);
    }
    _rw = clamp(_rw, 2, 8192);
    _rh = clamp(_rh, 2, 8192);
    if (surface_exists(application_surface))
    {
        if (surface_get_width(application_surface) != _rw or surface_get_height(application_surface) != _rh)
            surface_resize(application_surface, _rw, _rh);
    }

    // 4) Viewport ocupa a surface inteira
    if (view_enabled)
    {
        view_visible[0] = true;
        if (view_xport[0] != 0) view_xport[0] = 0;
        if (view_yport[0] != 0) view_yport[0] = 0;
        if (view_wport[0] != _rw) view_wport[0] = _rw;
        if (view_hport[0] != _rh) view_hport[0] = _rh;
    }

    // 5) Interface: altura fixa de 720, largura conforme a proporção, mapeada
    //    na janela INTEIRA (sem deslocamento e sem barras).
    var _gw = round(GUI_ALTURA * _aspecto);
    if (_ww != global.tela_janela_w or _wh != global.tela_janela_h or display_get_gui_width() != _gw)
    {
        global.tela_janela_w = _ww;
        global.tela_janela_h = _wh;
        display_set_gui_maximize(_ww / _gw, _wh / GUI_ALTURA, 0, 0);
    }
}

// Desenha a application surface esticada na janela inteira (evento Post Draw)
function tela_desenhar_surface()
{
    if (!surface_exists(application_surface)) return;
    gpu_set_blendenable(false);
    draw_surface_stretched(application_surface, 0, 0, window_get_width(), window_get_height());
    gpu_set_blendenable(true);
}

// ---------------------------------------------------------------------
// FONTES (arquivos em datafiles / Included Files)
// A fonte padrão do GameMaker não tem acentos: "CAPÍTULO" virava "CAPTULO".
// ---------------------------------------------------------------------
// Largura da letra "H" (em unidades de "em") de cada arquivo de fonte.
// Serve para medir o tamanho real gerado pelo font_add (que pode usar 72 ou
// 96 DPI conforme a versão do GameMaker) e normalizar: o layout fica igual.
function fonte_avanco_h(_arquivo)
{
    if (_arquivo == "TeXGyreBonum-Bold.otf") return 0.82;
    if (_arquivo == "DejaVuSerif-Bold.ttf") return 0.9448;
    if (_arquivo == "DejaVuSerifCondensed-Bold.ttf") return 0.8501;
    return 0.85;
}

// Tenta cada arquivo da lista. _em = tamanho desejado da letra (px da GUI).
function fonte_adicionar(_arquivos, _em)
{
    for (var _i = 0; _i < array_length(_arquivos); _i++)
    {
        if (!file_exists(_arquivos[_i])) continue;
        var _f = -1;
        try { _f = font_add(_arquivos[_i], round(_em * global.fonte_super), false, false, 32, 255); }
        catch (_e) { _f = -1; }
        if (_f != -1 and font_exists(_f))
        {
            draw_set_font(_f);
            var _w = string_width("HHHHHHHHHH");
            draw_set_font(-1);
            var _em_real = _w / (10 * fonte_avanco_h(_arquivos[_i]));
            return { f: _f, esc: (_em_real > 0) ? (_em / _em_real) : (1 / global.fonte_super) };
        }
    }
    return { f: -1, esc: 1 };
}

function fontes_carregar()
{
    if (global.fonte_ok) return;
    // As fontes são geradas maiores e desenhadas reduzidas: ficam nítidas
    // mesmo quando a interface (720 de altura) é ampliada para 1080p.
    global.fonte_super = 1.5;
    var _titulo = ["TeXGyreBonum-Bold.otf", "DejaVuSerif-Bold.ttf"];
    var _texto  = ["DejaVuSerifCondensed-Bold.ttf", "DejaVuSerif-Bold.ttf"];
    var _ems  = [92, 46, 27, 19, 15];                     // TITULO, GRANDE, MEDIA, PEQUENA, MINI
    var _arqs = [_titulo, _titulo, _titulo, _texto, _texto];
    global.fonte_ok = true;
    for (var _i = 0; _i < FONTE.TOTAL; _i++)
    {
        var _r = fonte_adicionar(_arqs[_i], _ems[_i]);
        global.fontes[_i] = _r.f;
        global.fonte_esc[_i] = _r.esc;
        if (_r.f == -1) global.fonte_ok = false;
    }
    if (!global.fonte_ok)
    {
        // Sem os arquivos: fonte padrão do GameMaker, ampliada até o tamanho desejado
        draw_set_font(-1);
        var _h = max(1, string_height("M"));
        for (var _j = 0; _j < FONTE.TOTAL; _j++) global.fonte_esc[_j] = (_ems[_j] * 1.15) / _h;
        show_debug_message("AVISO: fontes não encontradas em datafiles; usando a fonte padrão sem acentos.");
    }
}

// Sem as fontes, troca acentos por letras simples (a fonte padrão não os tem)
function texto_seguro(_s)
{
    if (global.fonte_ok) return _s;
    var _de = ["Á","À","Â","Ã","É","Ê","Í","Ó","Ô","Õ","Ú","Ç","á","à","â","ã","é","ê","í","ó","ô","õ","ú","ç","·","«","»","´"];
    var _pa = ["A","A","A","A","E","E","I","O","O","O","U","C","a","a","a","a","e","e","i","o","o","o","u","c","-","<",">","'"];
    for (var _i = 0; _i < array_length(_de); _i++) _s = string_replace_all(_s, _de[_i], _pa[_i]);
    return _s;
}

// _fonte é um valor do enum FONTE (TITULO, GRANDE, MEDIA, PEQUENA, MINI)
function fonte_escala(_fonte)
{
    return global.fonte_esc[clamp(_fonte, 0, FONTE.TOTAL - 1)];
}

function fonte_usar(_fonte)
{
    draw_set_font(global.fonte_ok ? global.fontes[clamp(_fonte, 0, FONTE.TOTAL - 1)] : -1);
}

// Texto com fonte, cor, transparência, alinhamento e escala
function txt(_x, _y, _s, _fonte, _cor = c_white, _alpha = 1, _ha = fa_left, _va = fa_top, _esc = 1)
{
    fonte_usar(_fonte);
    draw_set_halign(_ha);
    draw_set_valign(_va);
    draw_set_color(_cor);
    draw_set_alpha(_alpha);
    var _e = _esc * fonte_escala(_fonte);
    draw_text_transformed(_x, _y, texto_seguro(_s), _e, _e, 0);
}

// Texto com sombra escura (melhor leitura sobre o cenário)
function txt_sombra(_x, _y, _s, _fonte, _cor = c_white, _alpha = 1, _ha = fa_left, _va = fa_top, _esc = 1)
{
    txt(_x + 2, _y + 2, _s, _fonte, c_black, _alpha * 0.75, _ha, _va, _esc);
    txt(_x, _y, _s, _fonte, _cor, _alpha, _ha, _va, _esc);
}

// Texto com quebra de linha automática
function txt_bloco(_x, _y, _s, _fonte, _cor, _alpha, _largura, _ha = fa_center, _va = fa_top)
{
    fonte_usar(_fonte);
    draw_set_halign(_ha);
    draw_set_valign(_va);
    draw_set_color(_cor);
    draw_set_alpha(_alpha);
    var _e = fonte_escala(_fonte);
    draw_text_ext_transformed(_x, _y, texto_seguro(_s), -1, _largura / _e, _e, _e, 0);
}

function txt_largura(_s, _fonte, _esc = 1)
{
    fonte_usar(_fonte);
    return string_width(texto_seguro(_s)) * fonte_escala(_fonte) * _esc;
}

function txt_altura(_s, _fonte, _esc = 1)
{
    fonte_usar(_fonte);
    return string_height(texto_seguro(_s)) * fonte_escala(_fonte) * _esc;
}

function desenho_resetar()
{
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);
    gpu_set_fog(false, c_white, 0, 0);
}

// ---------------------------------------------------------------------
// ELEMENTOS VISUAIS
// ---------------------------------------------------------------------
// Retângulo com degradê vertical de cor e transparência
function retangulo_gradiente(_x1, _y1, _x2, _y2, _c1, _a1, _c2, _a2)
{
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_color(_x1, _y1, _c1, _a1);
    draw_vertex_color(_x2, _y1, _c1, _a1);
    draw_vertex_color(_x1, _y2, _c2, _a2);
    draw_vertex_color(_x2, _y2, _c2, _a2);
    draw_primitive_end();
}

// Retângulo com degradê horizontal
function retangulo_gradiente_h(_x1, _y1, _x2, _y2, _c1, _a1, _c2, _a2)
{
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_color(_x1, _y1, _c1, _a1);
    draw_vertex_color(_x2, _y1, _c2, _a2);
    draw_vertex_color(_x1, _y2, _c1, _a1);
    draw_vertex_color(_x2, _y2, _c2, _a2);
    draw_primitive_end();
}

// Vinheta escura nas bordas da tela (GUI)
function desenhar_vinheta(_gw, _gh, _forca, _cor = c_black)
{
    var _b = _gh * 0.28;
    retangulo_gradiente(0, 0, _gw, _b, _cor, _forca, _cor, 0);
    retangulo_gradiente(0, _gh - _b, _gw, _gh, _cor, 0, _cor, _forca);
    retangulo_gradiente_h(0, 0, _b, _gh, _cor, _forca, _cor, 0);
    retangulo_gradiente_h(_gw - _b, 0, _gw, _gh, _cor, 0, _cor, _forca);
}

// Painel escuro com moldura dourada
function desenhar_painel(_x1, _y1, _x2, _y2, _sel = 0, _alpha = 1)
{
    var _ouro = make_color_rgb(255, 210, 90);
    draw_set_alpha((0.72 + 0.15 * _sel) * _alpha);
    draw_set_color(merge_color(make_color_rgb(14, 11, 10), make_color_rgb(58, 30, 18), _sel));
    draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_alpha(_alpha);
    draw_set_color(merge_color(make_color_rgb(78, 64, 46), _ouro, _sel));
    draw_rectangle(_x1, _y1, _x2, _y2, true);
    if (_sel > 0.05)
    {
        draw_set_alpha(_alpha * _sel * 0.5);
        draw_rectangle(_x1 - 3, _y1 - 3, _x2 + 3, _y2 + 3, true);
    }
    // cantos ornamentados
    draw_set_alpha(_alpha);
    draw_set_color(merge_color(make_color_rgb(120, 96, 60), _ouro, _sel));
    var _c = 7;
    draw_triangle(_x1, _y1, _x1 + _c, _y1, _x1, _y1 + _c, false);
    draw_triangle(_x2, _y1, _x2 - _c, _y1, _x2, _y1 + _c, false);
    draw_triangle(_x1, _y2, _x1 + _c, _y2, _x1, _y2 - _c, false);
    draw_triangle(_x2, _y2, _x2 - _c, _y2, _x2, _y2 - _c, false);
    draw_set_alpha(1);
}

// Divisor ornamental (linha dourada com losango no centro)
function desenhar_divisor(_cx, _y, _meia, _alpha = 1)
{
    var _ouro2 = make_color_rgb(176, 141, 70);
    draw_set_alpha(_alpha);
    draw_set_color(_ouro2);
    draw_line_width(_cx - _meia, _y, _cx - 14, _y, 2);
    draw_line_width(_cx + 14, _y, _cx + _meia, _y, 2);
    draw_triangle(_cx - 10, _y, _cx, _y - 7, _cx + 10, _y, false);
    draw_triangle(_cx - 10, _y, _cx, _y + 7, _cx + 10, _y, false);
    draw_set_alpha(1);
}

function desenhar_espada(_x, _y, _dir)
{
    draw_set_color(make_color_rgb(205, 210, 220));
    draw_line_width(_x, _y, _x + _dir * 34, _y, 6);
    draw_triangle(_x + _dir * 34, _y - 3, _x + _dir * 34, _y + 3, _x + _dir * 46, _y, false);
    draw_set_color(make_color_rgb(255, 210, 90));
    draw_line_width(_x, _y - 12, _x, _y + 12, 5);
    draw_set_color(make_color_rgb(110, 60, 30));
    draw_line_width(_x - _dir * 16, _y, _x, _y, 4);
    draw_set_color(make_color_rgb(255, 210, 90));
    draw_circle(_x - _dir * 19, _y, 4, false);
}

function desenhar_tocha(_x, _y, _alpha = 1)
{
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(40, 40, 46));
    draw_rectangle(_x - 12, _y - 4, _x + 12, _y + 10, false);
    draw_set_color(make_color_rgb(80, 48, 24));
    draw_rectangle(_x - 5, _y + 10, _x + 5, _y + 120, false);
    var _f = sin(current_time / 80) * 2 + random_range(-1.5, 1.5);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.06 * _alpha);
    draw_set_color(make_color_rgb(255, 130, 30));
    for (var _i = 1; _i <= 7; _i++) draw_circle(_x, _y - 24, 12 * _i + _f, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(255, 110, 20));
    draw_circle(_x, _y - 6, 11, false);
    draw_triangle(_x - 12, _y - 4, _x + 12, _y - 4, _x + _f, _y - 54 + _f, false);
    draw_set_color(make_color_rgb(255, 200, 70));
    draw_triangle(_x - 7, _y - 4, _x + 7, _y - 4, _x + _f * 0.6, _y - 36, false);
    draw_set_color(make_color_rgb(255, 245, 190));
    draw_triangle(_x - 3, _y - 4, _x + 3, _y - 4, _x, _y - 20, false);
    draw_set_alpha(1);
}

// Texto "amaldiçoado": aparece letra por letra, com tremor, brilho vermelho
// e falhas (glitch). _t = tempo desde o início; _intervalo = quadros entre letras.
// Retorna o tempo em que a última letra termina de surgir.
function txt_amaldicoado(_cx, _cy, _s, _fonte, _cor, _t, _intervalo, _esc = 1, _alpha = 1)
{
    var _n = string_length(_s);
    var _larg = txt_largura(_s, _fonte, _esc);
    var _x = _cx - _larg / 2;
    var _vermelho = make_color_rgb(150, 8, 20);
    var _glitch = (irandom(70) == 0);
    for (var _i = 1; _i <= _n; _i++)
    {
        var _c = string_char_at(_s, _i);
        var _w = txt_largura(_c, _fonte, _esc);
        var _ti = _t - (_i - 1) * _intervalo;
        if (_ti > 0 and _c != " ")
        {
            var _a = clamp(_ti / 14, 0, 1);
            if (_ti < 22 and irandom(3) == 0) _a *= 0.35;               // tremeluz ao surgir
            var _treme = max(0, 1 - _ti / 30) * 6;
            var _ox = random_range(-_treme, _treme) + (_glitch ? random_range(-5, 5) : 0);
            var _oy = random_range(-_treme, _treme) + max(0, 1 - _ti / 18) * -10;
            var _e  = _esc * (1 + max(0, 1 - _ti / 16) * 0.6);
            var _lx = _x + _w / 2 + _ox;
            // brilho vermelho (aditivo)
            gpu_set_blendmode(bm_add);
            var _pulso = 0.45 + 0.25 * sin(current_time / 140 + _i);
            txt(_lx - 3, _cy + _oy, _c, _fonte, _vermelho, _a * _pulso * _alpha, fa_center, fa_middle, _e * 1.04);
            txt(_lx + 3, _cy + _oy, _c, _fonte, _vermelho, _a * _pulso * _alpha, fa_center, fa_middle, _e * 1.04);
            gpu_set_blendmode(bm_normal);
            // sombra + letra
            txt(_lx + 4, _cy + _oy + 4, _c, _fonte, c_black, _a * 0.8 * _alpha, fa_center, fa_middle, _e);
            var _cor_l = (_ti < 8) ? c_white : _cor;
            txt(_lx, _cy + _oy, _c, _fonte, _cor_l, _a * _alpha, fa_center, fa_middle, _e);
        }
        _x += _w;
    }
    desenho_resetar();
    return (_n - 1) * _intervalo + 30;
}

// ---------------------------------------------------------------------
// IMAGENS EXTERNAS (datafiles): logo, imagem de introdução e cutscene.
// Se o arquivo faltar ou não abrir, retorna -1 e o jogo segue sem ela.
// ---------------------------------------------------------------------
function imagem_carregar(_arq)
{
    if (!file_exists(_arq)) { show_debug_message("Imagem não encontrada: " + _arq); return -1; }
    var _s = -1;
    try { _s = sprite_add(_arq, 1, false, false, 0, 0); }
    catch (_erro) { _s = -1; }
    if (_s == -1) show_debug_message("Imagem não carregada: " + _arq);
    return _s;
}

// Desenha a imagem inteira dentro do retângulo, centralizada, sem cortar e sem distorcer
function imagem_desenhar_ajustada(_spr, _x, _y, _w, _h, _alpha = 1, _zoom = 1)
{
    if (_spr == -1 or !sprite_exists(_spr)) return;
    var _sw = sprite_get_width(_spr);
    var _sh = sprite_get_height(_spr);
    var _e = min(_w / _sw, _h / _sh) * _zoom;
    var _f = gpu_get_texfilter();
    gpu_set_texfilter(true);
    draw_sprite_ext(_spr, 0, _x + (_w - _sw * _e) / 2, _y + (_h - _sh * _e) / 2, _e, _e, 0, c_white, _alpha);
    gpu_set_texfilter(_f);
}

// Logo do jogo centralizada em (_cx, _cy) com a altura pedida
function logo_desenhar(_cx, _cy, _altura, _alpha = 1)
{
    if (global.logo_img == -1 or !sprite_exists(global.logo_img)) return false;
    var _e = _altura / sprite_get_height(global.logo_img);
    var _f = gpu_get_texfilter();
    gpu_set_texfilter(true);
    draw_sprite_ext(global.logo_img, 0, _cx - sprite_get_width(global.logo_img) * _e / 2, _cy - _altura / 2, _e, _e, 0, c_white, _alpha);
    gpu_set_texfilter(_f);
    return true;
}
