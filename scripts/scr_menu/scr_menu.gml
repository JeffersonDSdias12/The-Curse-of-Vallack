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

    var _vel = (global.cfg_fps == 0) ? 30 : 60;
    game_set_speed(_vel, gamespeed_fps);
    // v1.19: FLUIDEZ — VSync quando o monitor bate com a velocidade do jogo
    // (60/120/240 Hz): sem "rasgos" na imagem e quadros em ritmo regular. Em
    // 75/144 Hz fica desligado (o VSync faria os quadros alternarem 1 e 2 telas).
    var _hz = display_get_frequency();
    var _vs = (_hz >= _vel - 1 and abs(_hz / _vel - round(_hz / _vel)) < 0.05);
    if (!variable_global_exists("vsync_atual") or global.vsync_atual != _vs)
    {
        global.vsync_atual = _vs;
        display_reset(0, _vs);
    }
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
    // v1.19: IMAGEM LISA E NÍTIDA ("sharp bilinear"). Nas fases a câmera mostra
    // 280 px do mundo; numa tela de 768 isso é 2,74x — cada pixel da arte virava
    // ora 2, ora 3 pixels e tremia ao andar. Agora o mundo é desenhado numa escala
    // INTEIRA (280 -> 840, todos os pixels iguais) e reduzido para a janela com
    // filtro suave (tela_desenhar_surface): nítido e sem tremulação.
    if (room != rm_menu and view_enabled and !variable_global_exists("tp_sem_nitidez"))
    {
        var _kz = max(1, ceil(_rh / CAMERA_ALTURA - 0.02));
        _rh = CAMERA_ALTURA * _kz;
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

// Desenha a application surface esticada na janela inteira (evento Post Draw).
// Nas fases passa pelo PÓS-PROCESSAMENTO (sh_pos): contraste, saturação,
// sombras frias, luzes quentes e vinheta. O HUD (Draw GUI) vem depois, sem
// efeito. Desligado no menu (que tem o próprio visual) e na qualidade BAIXA.
function tela_desenhar_surface()
{
    if (!surface_exists(application_surface)) return;
    var _pos = global.cfg_qualidade > 0 and room != rm_menu and shader_is_compiled(sh_pos);
    if (_pos)
    {
        shader_set(sh_pos);
        shader_set_uniform_f(shader_get_uniform(sh_pos, "u_proporcao"), window_get_width() / max(1, window_get_height()));
        // fase 2 (salão em chamas) um pouco mais quente; fase 1 (tempestade) mais fria
        // sombras: fase 2 (salão em chamas) um pouco quentes; fase 1 (tempestade) azul-petróleo
        if (room == Room2) shader_set_uniform_f(shader_get_uniform(sh_pos, "u_sombra"), 0.020, 0.010, 0.006);
        else shader_set_uniform_f(shader_get_uniform(sh_pos, "u_sombra"), 0.004, 0.012, 0.024);
    }
    gpu_set_blendenable(false);
    // v1.19: a imagem do mundo (escala inteira) é reduzida para a janela com filtro suave
    var _tf = gpu_get_texfilter();
    gpu_set_texfilter(surface_get_height(application_surface) != window_get_height());
    draw_surface_stretched(application_surface, 0, 0, window_get_width(), window_get_height());
    gpu_set_texfilter(_tf);
    gpu_set_blendenable(true);
    if (_pos) shader_reset();
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

// Painel ornamentado: fundo escuro em degradê, moldura dupla dourada com
// cantos chanfrados e losangos; selecionado ganha brilho carmesim por dentro
function desenhar_painel(_x1, _y1, _x2, _y2, _sel = 0, _alpha = 1)
{
    if (_alpha <= 0.01) return;
    var _ouro_cl = make_color_rgb(247, 222, 158);
    var _ouro = make_color_rgb(206, 164, 86);
    var _ouro_esc = make_color_rgb(104, 74, 36);
    var _c = min(10, (_y2 - _y1) * 0.25);
    // sombra
    draw_set_alpha(0.45 * _alpha);
    draw_set_color(c_black);
    draw_rectangle(_x1 + 3, _y1 + 5, _x2 + 3, _y2 + 5, false);
    // fundo: degradê vertical (mais claro em cima), carmesim quando selecionado
    var _topo = merge_color(make_color_rgb(30, 22, 22), make_color_rgb(92, 30, 22), _sel);
    var _base = merge_color(make_color_rgb(10, 7, 8), make_color_rgb(40, 10, 10), _sel);
    retangulo_gradiente(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, _topo, (0.86 + 0.1 * _sel) * _alpha, _base, (0.9 + 0.08 * _sel) * _alpha);
    if (_sel > 0.05)
    {
        var _verm = make_color_rgb(255, 60, 30);
        gpu_set_blendmode(bm_add);
        retangulo_gradiente_h(_x1, _y1, (_x1 + _x2) / 2, _y2, _verm, 0, _verm, 0.14 * _sel * _alpha);
        retangulo_gradiente_h((_x1 + _x2) / 2, _y1, _x2, _y2, _verm, 0.14 * _sel * _alpha, _verm, 0);
        gpu_set_blendmode(bm_normal);
    }
    // moldura externa (cantos chanfrados) e filete interno
    draw_set_alpha(_alpha);
    draw_set_color(merge_color(merge_color(_ouro_esc, _ouro, 0.4), _ouro_cl, _sel));
    draw_line_width(_x1 + _c, _y1, _x2 - _c, _y1, 2);
    draw_line_width(_x1 + _c, _y2, _x2 - _c, _y2, 2);
    draw_line_width(_x1, _y1 + _c, _x1, _y2 - _c, 2);
    draw_line_width(_x2, _y1 + _c, _x2, _y2 - _c, 2);
    draw_line_width(_x1, _y1 + _c, _x1 + _c, _y1, 2);
    draw_line_width(_x2 - _c, _y1, _x2, _y1 + _c, 2);
    draw_line_width(_x1, _y2 - _c, _x1 + _c, _y2, 2);
    draw_line_width(_x2 - _c, _y2, _x2, _y2 - _c, 2);
    draw_set_alpha(_alpha * (0.35 + 0.4 * _sel));
    draw_set_color(_ouro);
    draw_rectangle(_x1 + 4, _y1 + 4, _x2 - 4, _y2 - 4, true);
    // losangos nos cantos e no meio dos lados
    draw_set_alpha(_alpha);
    draw_set_color(merge_color(_ouro, _ouro_cl, _sel));
    var _r = 3.5 + 1.5 * _sel;
    var _pts = [
        [_x1 + _c * 0.5, _y1 + _c * 0.5], [_x2 - _c * 0.5, _y1 + _c * 0.5],
        [_x1 + _c * 0.5, _y2 - _c * 0.5], [_x2 - _c * 0.5, _y2 - _c * 0.5],
        [_x1, (_y1 + _y2) / 2], [_x2, (_y1 + _y2) / 2]
    ];
    for (var _i = 0; _i < 6; _i++)
    {
        var _px = _pts[_i][0];
        var _py = _pts[_i][1];
        draw_triangle(_px - _r, _py, _px, _py - _r, _px + _r, _py, false);
        draw_triangle(_px - _r, _py, _px, _py + _r, _px + _r, _py, false);
    }
    // brilho externo quando selecionado
    if (_sel > 0.05)
    {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(_alpha * _sel * 0.35);
        draw_set_color(make_color_rgb(255, 170, 90));
        draw_rectangle(_x1 - 3, _y1 - 3, _x2 + 3, _y2 + 3, true);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_alpha(1);
}

// Divisor ornamental (filete dourado que some nas pontas, losango no centro)
function desenhar_divisor(_cx, _y, _meia, _alpha = 1)
{
    var _ouro = make_color_rgb(206, 164, 86);
    retangulo_gradiente_h(_cx - _meia, _y - 1, _cx - 14, _y + 1, _ouro, 0, _ouro, _alpha);
    retangulo_gradiente_h(_cx + 14, _y - 1, _cx + _meia, _y + 1, _ouro, _alpha, _ouro, 0);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(247, 222, 158));
    draw_triangle(_cx - 10, _y, _cx, _y - 7, _cx + 10, _y, false);
    draw_triangle(_cx - 10, _y, _cx, _y + 7, _cx + 10, _y, false);
    draw_set_color(make_color_rgb(150, 26, 20));
    draw_triangle(_cx - 5, _y, _cx, _y - 3.5, _cx + 5, _y, false);
    draw_triangle(_cx - 5, _y, _cx, _y + 3.5, _cx + 5, _y, false);
    draw_set_alpha(1);
}

// ---------------------------------------------------------------------
// HUD GÓTICO (estilo Castlevania): brasão com o retrato, placa de ferro com
// moldura dourada, barras com ponta, quadro da sub-arma e barra do chefe
// ---------------------------------------------------------------------
// contorno de uma barra: ponta à direita (e à esquerda, se pedido)
function hud_barra_pts(_x, _y, _w, _h, _ponta_esq = false)
{
    var _p = min(_h * 0.5, _w * 0.5);
    var _q = max(_x, _x + _w - _p);
    if (_ponta_esq)
    {
        var _q0 = min(_q, _x + _p);
        return [[_q0, _y], [_q, _y], [_x + _w, _y + _h / 2], [_q, _y + _h], [_q0, _y + _h], [_x, _y + _h / 2]];
    }
    return [[_x, _y], [_q, _y], [_x + _w, _y + _h / 2], [_q, _y + _h], [_x, _y + _h]];
}

// preenche um polígono convexo com degradê vertical (c1 em cima, c2 embaixo)
function hud_forma(_pts, _y, _h, _c1, _c2, _alpha)
{
    if (_alpha <= 0) return;
    var _n = array_length(_pts);
    draw_primitive_begin(pr_trianglelist);
    for (var _i = 1; _i < _n - 1; _i++)
    {
        var _tri = [_pts[0], _pts[_i], _pts[_i + 1]];
        for (var _k = 0; _k < 3; _k++)
        {
            var _v = _tri[_k];
            draw_vertex_color(_v[0], _v[1], merge_color(_c1, _c2, clamp((_v[1] - _y) / max(1, _h), 0, 1)), _alpha);
        }
    }
    draw_primitive_end();
}

// barra com moldura dourada; pct_atraso mostra em claro o dano recente;
// _segmentos > 0 desenha os gomos da barra (como no Castlevania)
function hud_barra(_x, _y, _w, _h, _pct, _pct_atraso, _c1, _c2, _alpha = 1, _ponta_esq = false, _segmentos = 0)
{
    var _pe = _ponta_esq ? 3 : 0;
    hud_forma(hud_barra_pts(_x - 3 - _pe, _y - 3, _w + 7 + _pe * 2, _h + 6, _ponta_esq), _y - 3, _h + 6, make_color_rgb(8, 5, 6), make_color_rgb(8, 5, 6), 0.9 * _alpha);
    hud_forma(hud_barra_pts(_x - 1.5 - _pe * 0.5, _y - 1.5, _w + 3.5 + _pe, _h + 3, _ponta_esq), _y - 1.5, _h + 3, make_color_rgb(247, 222, 158), make_color_rgb(104, 74, 36), _alpha);
    hud_forma(hud_barra_pts(_x, _y, _w, _h, _ponta_esq), _y, _h, make_color_rgb(14, 9, 10), make_color_rgb(36, 25, 27), _alpha);
    var _pa = clamp(_pct_atraso, 0, 1);
    var _pp = clamp(_pct, 0, 1);
    if (_pa > _pp + 0.002) hud_forma(hud_barra_pts(_x, _y, _w * _pa, _h, _ponta_esq), _y, _h, make_color_rgb(255, 244, 222), make_color_rgb(214, 196, 170), 0.9 * _alpha);
    if (_pp > 0.002)
    {
        hud_forma(hud_barra_pts(_x, _y, _w * _pp, _h, _ponta_esq), _y, _h, _c1, _c2, _alpha);
        // brilho na metade de cima
        var _hb = _h * 0.38;
        hud_forma(hud_barra_pts(_x + (_ponta_esq ? _h * 0.5 : 0), _y + 1, max(0, _w * _pp - _h * (_ponta_esq ? 1 : 0.5)), _hb), _y + 1, _hb, c_white, c_white, 0.16 * _alpha);
    }
    if (_segmentos > 1)
    {
        draw_set_alpha(0.55 * _alpha);
        draw_set_color(make_color_rgb(10, 4, 5));
        for (var _s = 1; _s < _segmentos; _s++)
        {
            var _sx = _x + _w * _s / _segmentos;
            if (_sx > _x + _w - _h * 0.5) break;
            draw_rectangle(_sx, _y + 1, _sx + 1, _y + _h - 1, false);
        }
        draw_set_alpha(1);
    }
}

// placa de ferro escuro com moldura dourada dupla e ponta gótica à direita
function hud_placa(_x1, _y1, _x2, _y2, _alpha = 1)
{
    var _h = _y2 - _y1;
    var _p = min(26, _h * 0.4);
    var _pts = [[_x1, _y1], [_x2 - _p, _y1], [_x2, _y1 + _h / 2], [_x2 - _p, _y2], [_x1, _y2]];
    // sombra
    var _sombra = [[_x1 + 3, _y1 + 5], [_x2 - _p + 3, _y1 + 5], [_x2 + 3, _y1 + _h / 2 + 5], [_x2 - _p + 3, _y2 + 5], [_x1 + 3, _y2 + 5]];
    hud_forma(_sombra, _y1, _h, c_black, c_black, 0.45 * _alpha);
    // moldura dourada (forma maior) e o ferro por dentro
    var _fora = [[_x1 - 2, _y1 - 2], [_x2 - _p - 1, _y1 - 2], [_x2 + 2.5, _y1 + _h / 2], [_x2 - _p - 1, _y2 + 2], [_x1 - 2, _y2 + 2]];
    hud_forma(_fora, _y1 - 2, _h + 4, make_color_rgb(247, 222, 158), make_color_rgb(104, 74, 36), _alpha);
    hud_forma(_pts, _y1, _h, make_color_rgb(34, 24, 26), make_color_rgb(10, 7, 8), 0.94 * _alpha);
    // filete interno
    draw_set_alpha(0.45 * _alpha);
    draw_set_color(make_color_rgb(206, 164, 86));
    draw_line(_x1 + 4, _y1 + 4, _x2 - _p - 2, _y1 + 4);
    draw_line(_x1 + 4, _y2 - 4, _x2 - _p - 2, _y2 - 4);
    draw_line(_x2 - _p - 2, _y1 + 4, _x2 - 5, _y1 + _h / 2);
    draw_line(_x2 - _p - 2, _y2 - 4, _x2 - 5, _y1 + _h / 2);
    // joia carmesim na ponta
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(247, 222, 158));
    var _jx = _x2 - _p * 0.55;
    var _jy = _y1 + _h / 2;
    draw_triangle(_jx - 5, _jy, _jx, _jy - 5, _jx + 5, _jy, false);
    draw_triangle(_jx - 5, _jy, _jx, _jy + 5, _jx + 5, _jy, false);
    draw_set_color(make_color_rgb(150, 20, 18));
    draw_triangle(_jx - 3, _jy, _jx, _jy - 3, _jx + 3, _jy, false);
    draw_triangle(_jx - 3, _jy, _jx, _jy + 3, _jx + 3, _jy, false);
    draw_set_alpha(1);
}

// brasão com o rosto do herói; o número na joia é o nível da espada
function hud_brasao(_x, _y, _w, _nivel, _alpha = 1)
{
    var _k = _w / 200;
    var _tf = gpu_get_texfilter();
    gpu_set_texfilter(true);
    draw_sprite_ext(spr_hud_brasao_fundo, 0, _x, _y, _k, _k, 0, c_white, _alpha);
    // retrato: cabeça e ombros do quadro 0 da spr_player_idle (arte HD)
    var _e = (124 * _k) / 54;
    draw_sprite_part_ext(spr_player_idle, 0, 22, 2, 54, 54, _x + 38 * _k, _y + 30 * _k, _e, _e, c_white, _alpha);
    draw_sprite_ext(spr_hud_brasao, 0, _x, _y, _k, _k, 0, c_white, _alpha);
    gpu_set_texfilter(_tf);
    txt_sombra(_x + 100 * _k, _y + 206 * _k, string(_nivel), FONTE.PEQUENA, make_color_rgb(250, 240, 220), _alpha, fa_center, fa_middle, 0.9);
}

// ícone da sub-arma: 0 = Lâmina Bumerangue, 1 = Chama de Sylla
function hud_icone_subarma(_cx, _cy, _r, _tipo, _alpha = 1)
{
    if (_tipo == 0)
    {
        // lâmina girando (como no jogo), inclinada
        var _c = dcos(45);
        var _s = -dsin(45);
        var _tx = _cx + _c * _r;
        var _ty = _cy + _s * _r;
        var _hx = _cx - _c * _r * 0.55;
        var _hy = _cy - _s * _r * 0.55;
        var _nx = -_s * _r * 0.2;
        var _ny = _c * _r * 0.2;
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.25 * _alpha);
        draw_set_color(make_color_rgb(255, 210, 120));
        draw_circle(_cx, _cy, _r * 0.95, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(_alpha);
        draw_set_color(make_color_rgb(225, 230, 240));
        draw_triangle(_cx + _nx, _cy + _ny, _cx - _nx, _cy - _ny, _tx, _ty, false);
        draw_set_color(make_color_rgb(150, 160, 175));
        draw_line(_cx, _cy, _tx, _ty);
        draw_set_color(make_color_rgb(205, 165, 60));
        draw_line_width(_cx - _nx * 1.8, _cy - _ny * 1.8, _cx + _nx * 1.8, _cy + _ny * 1.8, max(2, _r * 0.14));
        draw_line_width(_cx, _cy, _hx, _hy, max(2, _r * 0.17));
        draw_circle(_hx, _hy, max(1.5, _r * 0.12), false);
    }
    else
    {
        // chama amaldiçoada (gota de fogo roxa com miolo claro)
        var _cores = [cor_chama_maldita(), make_color_rgb(220, 150, 255), make_color_rgb(255, 240, 255)];
        var _escs = [1, 0.62, 0.3];
        var _tre = sin(current_time / 90) * _r * 0.08;
        gpu_set_blendmode(bm_add);
        for (var _i = 0; _i < 3; _i++)
        {
            var _rr = _r * 0.5 * _escs[_i];
            var _base = _cy + _r * 0.45;
            draw_set_alpha(_alpha * (0.6 + 0.15 * _i));
            draw_set_color(_cores[_i]);
            draw_circle(_cx, _base - _rr, _rr, false);
            draw_triangle(_cx - _rr, _base - _rr, _cx + _rr, _base - _rr, _cx + _tre, _base - _rr - _r * 1.2 * _escs[_i], false);
        }
        gpu_set_blendmode(bm_normal);
    }
    draw_set_alpha(1);
}

// quadro da sub-arma (como o do Castlevania): moldura dourada com cantos em
// losango, ícone no centro e o contador de essência embaixo
function hud_quadro_subarma(_x, _y, _tam, _tipo, _pode, _essencia, _essencia_fx, _alpha = 1)
{
    var _x2 = _x + _tam;
    var _y2 = _y + _tam;
    draw_set_alpha(0.45 * _alpha);
    draw_set_color(c_black);
    draw_rectangle(_x + 3, _y + 5, _x2 + 3, _y2 + 5, false);
    hud_forma([[_x - 2, _y - 2], [_x2 + 2, _y - 2], [_x2 + 2, _y2 + 2], [_x - 2, _y2 + 2]], _y - 2, _tam + 4, make_color_rgb(247, 222, 158), make_color_rgb(104, 74, 36), _alpha);
    hud_forma([[_x + 1, _y + 1], [_x2 - 1, _y + 1], [_x2 - 1, _y2 - 1], [_x + 1, _y2 - 1]], _y, _tam, make_color_rgb(46, 16, 16), make_color_rgb(12, 6, 7), 0.96 * _alpha);
    // brilho carmesim por dentro quando dá para usar
    if (_pode)
    {
        gpu_set_blendmode(bm_add);
        draw_set_alpha((0.10 + 0.05 * sin(current_time / 200)) * _alpha);
        draw_set_color(make_color_rgb(255, 60, 30));
        draw_circle(_x + _tam / 2, _y + _tam / 2, _tam * 0.42, false);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_alpha(0.5 * _alpha);
    draw_set_color(make_color_rgb(206, 164, 86));
    draw_rectangle(_x + 4, _y + 4, _x2 - 4, _y2 - 4, true);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(247, 222, 158));
    var _cs = [[_x, _y], [_x2, _y], [_x, _y2], [_x2, _y2]];
    for (var _i = 0; _i < 4; _i++)
    {
        var _px = _cs[_i][0];
        var _py = _cs[_i][1];
        draw_triangle(_px - 4, _py, _px, _py - 4, _px + 4, _py, false);
        draw_triangle(_px - 4, _py, _px, _py + 4, _px + 4, _py, false);
    }
    hud_icone_subarma(_x + _tam / 2, _y + _tam / 2, _tam * 0.36, _tipo, _alpha * (_pode ? 1 : 0.4));
    // essência (os "corações" do Castlevania)
    var _ek = 1 + 0.35 * clamp(_essencia_fx / 20, 0, 1);
    var _ex = _x + 10;
    var _ey = _y2 + 16;
    var _kr = 7 * _ek;
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(10, 18, 40));
    draw_triangle(_ex, _ey - _kr - 1.5, _ex + _kr * 0.7 + 1.5, _ey, _ex - _kr * 0.7 - 1.5, _ey, false);
    draw_triangle(_ex, _ey + _kr + 1.5, _ex + _kr * 0.7 + 1.5, _ey, _ex - _kr * 0.7 - 1.5, _ey, false);
    draw_set_color(make_color_rgb(140, 200, 255));
    draw_triangle(_ex, _ey - _kr, _ex + _kr * 0.7, _ey, _ex - _kr * 0.7, _ey, false);
    draw_set_color(make_color_rgb(50, 110, 220));
    draw_triangle(_ex, _ey + _kr, _ex + _kr * 0.7, _ey, _ex - _kr * 0.7, _ey, false);
    txt_sombra(_ex + 12, _ey, string(_essencia), FONTE.PEQUENA, make_color_rgb(165, 212, 255), _alpha, fa_left, fa_middle, 0.85 * _ek);
    draw_set_alpha(1);
}

// faixa escura com filetes dourados que somem nas pontas (objetivo, avisos)
function hud_faixa(_x1, _y1, _x2, _y2, _alpha = 1)
{
    var _fade = min(70, (_x2 - _x1) * 0.25);
    var _cf = make_color_rgb(10, 6, 7);
    var _ouro = make_color_rgb(206, 164, 86);
    retangulo_gradiente_h(_x1, _y1, _x1 + _fade, _y2, _cf, 0, _cf, 0.72 * _alpha);
    draw_set_alpha(0.72 * _alpha);
    draw_set_color(_cf);
    draw_rectangle(_x1 + _fade, _y1, _x2 - _fade, _y2, false);
    retangulo_gradiente_h(_x2 - _fade, _y1, _x2, _y2, _cf, 0.72 * _alpha, _cf, 0);
    var _ys = [_y1, _y2];
    for (var _i = 0; _i < 2; _i++)
    {
        retangulo_gradiente_h(_x1, _ys[_i] - 1, (_x1 + _x2) / 2, _ys[_i], _ouro, 0, _ouro, 0.85 * _alpha);
        retangulo_gradiente_h((_x1 + _x2) / 2, _ys[_i] - 1, _x2, _ys[_i], _ouro, 0.85 * _alpha, _ouro, 0);
    }
    var _cx = (_x1 + _x2) / 2;
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(247, 222, 158));
    draw_triangle(_cx - 7, _y2, _cx, _y2 - 5, _cx + 7, _y2, false);
    draw_triangle(_cx - 7, _y2, _cx, _y2 + 5, _cx + 7, _y2, false);
    draw_set_alpha(1);
}

// orbe vermelha pequena (contador de orbs do HUD)
function hud_orbe(_cx, _cy, _r, _alpha = 1)
{
    draw_set_alpha(0.8 * _alpha);
    draw_set_color(make_color_rgb(20, 6, 6));
    draw_circle(_cx, _cy, _r + 1.5, false);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(170, 24, 20));
    draw_circle(_cx, _cy, _r, false);
    draw_set_color(make_color_rgb(240, 70, 50));
    draw_circle(_cx - _r * 0.15, _cy - _r * 0.15, _r * 0.7, false);
    draw_set_alpha(0.9 * _alpha);
    draw_set_color(make_color_rgb(255, 210, 190));
    draw_circle(_cx - _r * 0.35, _cy - _r * 0.4, _r * 0.28, false);
    draw_set_alpha(1);
}

// barra de vida do chefe EMBAIXO da tela, numa placa gótica
// _marcas: [[posição 0..1, cor], ...]
function hud_barra_chefe(_nome, _direita, _cor_dir, _pct, _pct_atraso, _c1, _c2, _marcas, _valor, _alpha, _larg_max = 820)
{
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _bw = min(_gw * 0.6, _larg_max);
    var _bx = _gw / 2 - _bw / 2;
    var _by = _gh - 34;
    hud_faixa(_bx - 70, _by - 40, _bx + _bw + 70, _by + 24, _alpha);
    txt_sombra(_bx + 6, _by - 18, _nome, FONTE.PEQUENA, make_color_rgb(255, 132, 104), _alpha, fa_left, fa_middle, min(0.95, (_bw * 0.62) / max(1, txt_largura(_nome, FONTE.PEQUENA))));
    txt_sombra(_bx + _bw - 6, _by - 18, _direita, FONTE.MINI, _cor_dir, _alpha, fa_right, fa_middle);
    hud_barra(_bx, _by, _bw, 14, _pct, _pct_atraso, _c1, _c2, _alpha, true, 20);
    for (var _m = 0; _m < array_length(_marcas); _m++)
    {
        var _mx = _bx + _bw * _marcas[_m][0];
        draw_set_alpha(_alpha);
        draw_set_color(_marcas[_m][1]);
        draw_rectangle(_mx - 1, _by - 4, _mx + 1, _by + 18, false);
    }
    if (_valor != "") txt_sombra(_bx + _bw - 14, _by + 7, _valor, FONTE.MINI, make_color_rgb(255, 240, 228), _alpha, fa_right, fa_middle, 0.8);
    draw_set_alpha(1);
}

// BOTÃO CONTEXTUAL (ex.: ABRIR o baú): placa ornamentada pulsando sobre o
// objeto, com a tecla/botão de INTERAGIR e uma seta apontando para ele.
// (_cx, _by) = ponto logo acima do objeto, em coordenadas da GUI
function hud_botao_contexto(_cx, _by, _rotulo, _com_tecla = true, _alpha = 1)
{
    var _pulso = 0.5 + 0.5 * sin(current_time / 140);
    var _sobe = 4 * sin(current_time / 220);
    var _wt = txt_largura(_rotulo, FONTE.PEQUENA);
    var _wk = _com_tecla ? icone_acao_largura(ACAO.INTERAGIR, 26) + 10 : 0;
    var _w = _wt + _wk + 36;
    var _y2 = _by - 12 + _sobe;
    var _y1 = _y2 - 42;
    var _x1 = clamp(_cx - _w / 2, 8, display_get_gui_width() - _w - 8);
    // brilho dourado pulsando por trás
    gpu_set_blendmode(bm_add);
    draw_set_alpha((0.16 + 0.14 * _pulso) * _alpha);
    draw_set_color(make_color_rgb(255, 170, 60));
    draw_ellipse(_x1 - 16, _y1 - 12, _x1 + _w + 16, _y2 + 12, false);
    gpu_set_blendmode(bm_normal);
    desenhar_painel(_x1, _y1, _x1 + _w, _y2, 0.55 + 0.45 * _pulso, _alpha);
    // seta apontando o objeto
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(247, 222, 158));
    draw_triangle(_cx - 9, _y2 + 3, _cx + 9, _y2 + 3, _cx, _y2 + 13, false);
    var _tx = _x1 + 18;
    var _ty = (_y1 + _y2) / 2;
    if (_com_tecla) { desenhar_icone_acao(_tx, _ty, ACAO.INTERAGIR, 26, _alpha); _tx += _wk; }
    txt_sombra(_tx, _ty, _rotulo, FONTE.PEQUENA, merge_color(make_color_rgb(255, 225, 150), c_white, 0.4 * _pulso), _alpha, fa_left, fa_middle);
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

// =====================================================================
// v1.19: TRANSIÇÕES ENTRE TELAS — uma cortina escura, em diagonal, com a
// borda em brasa (faixas de luz vermelha e faíscas subindo pela borda).
// Usada pelo carregamento das fases (entra pela esquerda, sai pela direita)
// e pelo véu que revela a tela nova no menu, no mapa e no perfil.
// =====================================================================
// cobre _k (0..1) da tela; _da_direita = a cortina fica presa ao lado direito
function transicao_cortina_desenhar(_k, _da_direita = false)
{
    if (_k <= 0) return;
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _s  = _gh * 0.35;                                  // inclinação da borda
    var _e  = -_s / 2 + clamp(_k, 0, 1) * (_gw + _s);      // meio da borda
    var _sx = _da_direita ? -1 : 1;                        // espelho: x na tela = _ox + _sx * x
    var _ox = _da_direita ? _gw : 0;
    var _x0 = _ox + _sx * (-_s);
    var _xt = _ox + _sx * (_e + _s / 2);                   // borda no alto
    var _xb = _ox + _sx * (_e - _s / 2);                   // borda embaixo
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_triangle(_x0, 0, _xt, 0, _xb, _gh, false);
    draw_triangle(_x0, 0, _xb, _gh, _x0, _gh, false);
    if (_k >= 1) return;
    // a brasa: faixas de luz à frente da borda, cada vez mais fracas
    var _t = current_time / 16.67;
    var _bd = [0, 5, 14, 28, 46];
    var _ba = [0.55, 0.32, 0.18, 0.08];
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < 4; _i++)
    {
        var _d1 = _sx * _bd[_i], _d2 = _sx * _bd[_i + 1];
        draw_set_color(merge_color(make_color_rgb(255, 120, 40), make_color_rgb(150, 10, 10), _i / 3));
        draw_set_alpha(_ba[_i]);
        draw_triangle(_xt + _d1, 0, _xt + _d2, 0, _xb + _d2, _gh, false);
        draw_triangle(_xt + _d1, 0, _xb + _d2, _gh, _xb + _d1, _gh, false);
    }
    draw_set_alpha(0.9);
    draw_set_color(make_color_rgb(255, 190, 110));
    draw_line_width(_xt, 0, _xb, _gh, 2);
    // faíscas soltando da borda e subindo
    for (var _f = 0; _f < 22; _f++)
    {
        var _fq = frac(_f * 0.6180339 - _t * 0.006 * (1 + _f mod 3));     // frac() mantém o sinal
        var _fy = ((_fq < 0) ? _fq + 1 : _fq) * _gh;
        var _vida = frac(_f * 0.37 + _t * 0.013);
        var _fx = lerp(_xt, _xb, _fy / _gh) + _sx * (4 + _vida * 46);
        draw_set_alpha((1 - _vida) * 0.9);
        draw_set_color((_f mod 4 == 0) ? make_color_rgb(255, 230, 160) : make_color_rgb(255, 120, 40));
        draw_circle(_fx, _fy, 1.5 + (_f mod 3) * 0.8, false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// a tela acabou de mudar: a cortina cobre tudo e sai para a direita revelando a nova
function transicao_revelar(_dur = 24)
{
    global.veu_dur = _dur;
    global.veu_t = 0;
}

// desenhado pelo obj_sistema no Draw GUI End (por cima de toda a interface)
function transicao_veu_desenhar()
{
    if (!variable_global_exists("veu_dur") or global.veu_t >= global.veu_dur) return;
    var _p = clamp(global.veu_t / max(1, global.veu_dur), 0, 1);
    transicao_cortina_desenhar(power(1 - _p, 3), true);    // sai rápido e freia no fim
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

// =====================================================================
// CRÉDITOS do fim da demo (depois do "Obrigado por jogar nossa Demo.")
// Os nomes da equipe saíram da abertura e passam aqui, subindo pela tela.
// =====================================================================
#macro CREDITOS_VEL 1.15     // pixels por quadro (60 FPS)

function creditos_lista()
{
    var _ouro = make_color_rgb(255, 210, 90);
    var _branco = make_color_rgb(242, 232, 214);
    var _cinza = make_color_rgb(190, 184, 178);
    return [
        { logo: true, h: 250 },
        { t: "UMA JORNADA SOBRE FORÇA, ESCOLHA E LEGADO", f: FONTE.PEQUENA, c: _ouro, h: 96 },
        { t: "DESENVOLVIDO POR", f: FONTE.MINI, c: _cinza, h: 34 },
        { t: "JEFFERSON DIAS", f: FONTE.GRANDE, c: _branco, h: 110 },
        { t: "DESENVOLVIMENTO", f: FONTE.MINI, c: _ouro, h: 34 },
        { t: "EDUARDO  ·  ISAAC  ·  ALEX  ·  ALDREON", f: FONTE.MEDIA, c: _branco, h: 96 },
        { t: "DESIGN", f: FONTE.MINI, c: _ouro, h: 34 },
        { t: "ALEX  ·  I.A. CLAUDE", f: FONTE.MEDIA, c: _branco, h: 96 },
        { t: "ROTEIRO", f: FONTE.MINI, c: _ouro, h: 34 },
        { t: "ISAAC  ·  EDUARDO  ·  I.A. CLAUDE", f: FONTE.MEDIA, c: _branco, h: 120 },
        { t: "UM PROJETO ACADÊMICO", f: FONTE.MINI, c: _cinza, h: 34 },
        { t: "FACULDADE FAPAN", f: FONTE.MEDIA, c: _branco, h: 130 },
        { t: "GAMBITECH STUDIO", f: FONTE.GRANDE, c: make_color_rgb(235, 120, 70), h: 170 },
        { t: "A jornada continua em breve...", f: FONTE.PEQUENA, c: make_color_rgb(230, 120, 100), h: 60 }
    ];
}

function creditos_altura()
{
    var _l = creditos_lista();
    var _h = 0;
    for (var _i = 0; _i < array_length(_l); _i++) _h += _l[_i].h;
    return _h;
}

// tempo (quadros) até a última linha chegar ao meio da tela
function creditos_duracao()
{
    var _gh = display_get_gui_height();
    return (_gh + creditos_altura() - _gh * 0.5) / CREDITOS_VEL;
}

function creditos_desenhar(_t, _alpha = 1)
{
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _cx = _gw / 2;
    var _y = _gh + 40 - _t * CREDITOS_VEL;
    _y = max(_y, _gh * 0.5 - creditos_altura() + 60);     // a última linha para no meio da tela
    var _l = creditos_lista();
    for (var _i = 0; _i < array_length(_l); _i++)
    {
        var _e = _l[_i];
        var _meio = _y + _e.h * 0.5;
        if (_meio > -120 and _meio < _gh + 120)
        {
            // some suavemente perto das bordas de cima e de baixo
            var _borda = clamp(min(_meio, _gh - _meio) / 110, 0, 1) * _alpha;
            if (variable_struct_exists(_e, "logo"))
            {
                if (!logo_desenhar(_cx, _meio, _e.h * 0.92, _borda))
                    txt_sombra(_cx, _meio, JOGO_TITULO, FONTE.GRANDE, make_color_rgb(230, 40, 40), _borda, fa_center, fa_middle);
            }
            else
            {
                var _esc = min(1, (_gw * 0.9) / max(1, txt_largura(_e.t, _e.f)));
                txt_sombra(_cx, _meio, _e.t, _e.f, _e.c, _borda, fa_center, fa_middle, _esc);
            }
        }
        _y += _e.h;
    }
    desenho_resetar();
}