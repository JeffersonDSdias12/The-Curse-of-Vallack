// =====================================================================
//  obj_menu — abertura (créditos + título), menu inicial e opções
// =====================================================================
globais_iniciar();
if (!instance_exists(obj_sistema)) instance_create_depth(0, 0, 0, obj_sistema);
audio_cena_definir("titulo");                             // sons da tela inicial
musica("mus_menu", global.intro_vista ? 1500 : 3000);     // trilha do menu inicial (só aqui)

// ----- imagens da tela inicial (em datafiles; se faltarem, o jogo usa o título em texto) -----
if (!variable_global_exists("logo_img")) global.logo_img = -1;
if (global.logo_img == -1 or !sprite_exists(global.logo_img)) global.logo_img = imagem_carregar("logo_vallack.png");
img_aviso = global.intro_vista ? -1 : imagem_carregar("intro_aviso.jpg");   // "este é um jogo fictício"

// ----- estados -----
// intro_aviso -> intro_creditos -> intro_titulo -> menu
// menu -> dificuldade -> (slot_novo) -> cutscene -> jogo | carregar | tutorial | opcoes -> teclado / controle
estado = global.intro_vista ? "menu" : ((img_aviso != -1) ? "intro_aviso" : "intro_creditos");
aviso_total = 360;      // v1.8: imagem de introdução fica os 6 s inteiros (entra, fica e sai)
som_estado = estado;    // para tocar o som de "mover" quando a seleção muda
som_sel = 0;
som_pag = 0;
tempo = 0;              // tempo no estado atual (quadros de 60 FPS)
tempo_total = 0;
selecionado = 0;
selecionado_antes = -1;
mouse_antes_x = -1;
mouse_antes_y = -1;

opcoes_menu = ["NOVO JOGO", "CARREGAR JOGO", "TUTORIAL", "OPÇÕES", "SAIR"];
opcoes_cfg  = ["QUALIDADE VISUAL", "TAXA DE QUADROS", "MODO DE TELA", "PROPORÇÃO", "RESOLUÇÃO", "VOLUME GERAL", "VOLUME DA MÚSICA", "VOLUME DOS EFEITOS", "FUNDO HD (FASE 1)", "TUTORIAL NA FASE", "TECLADO", "CONTROLE", "VOLTAR"];
acoes = acoes_nomes();
acoes_tela = acoes_ordem_tela();     // ordem das ações na tela de remapeamento (2 colunas)
anim = array_create(24, 0);

// tutorial (livro de pergaminhos)
livro_pag = 0;
livro_abre = 0;

// remapeamento
capturando = false;
capture_wait = 0;
captura_solto = false;     // controle: espera soltar tudo antes de aceitar o novo botão
usando_pad_antes = global.usando_pad;
mensagem = "";
mensagem_tempo = 0;

// slots
confirmar_slot = -1;

slots = [];
tem_save = false;

// efeitos
faiscas = [];
relampago = 0;
proximo_relampago = irandom_range(300, 600);
gotas = [];             // sangue escorrendo das letras do título
titulo_x1 = 0;
titulo_x2 = 0;
titulo_base = 0;
menu_aparece = 0;       // tempo desde que o menu apareceu (entrada animada)
dicas = dicas_tutorial();
dica_atual = irandom(array_length(dicas) - 1);
dica_tempo = 0;

// ----- linha do tempo da abertura (não pode ser pulada) -----
// Créditos: as linhas surgem uma a uma; quando a animação termina,
// ficam mais 5 s na tela.
creditos = [
    { t: 0, texto: "UMA JORNADA SOBRE FORÇA, ESCOLHA E LEGADO", f: FONTE.MEDIA,   cor: make_color_rgb(255, 210, 90),  y: 0.14 },
    { t: 45, texto: "DESENVOLVIDO POR",                           f: FONTE.MINI,    cor: make_color_rgb(190, 190, 195), y: 0.27 },
    { t: 75, texto: "JEFFERSON DIAS",                             f: FONTE.GRANDE,  cor: c_white,                       y: 0.345 },
    { t: 140, texto: "DESENVOLVIMENTO",                            f: FONTE.MINI,    cor: make_color_rgb(255, 210, 90),  y: 0.46 },
    { t: 160, texto: "EDUARDO  ·  ISAAC  ·  ALEX  ·  ALDREON",     f: FONTE.PEQUENA, cor: c_white,                       y: 0.51 },
    { t: 230, texto: "DESIGN",                                     f: FONTE.MINI,    cor: make_color_rgb(255, 210, 90),  y: 0.60 },
    { t: 250, texto: "ALEX  ·  I.A. CLAUDE",                       f: FONTE.PEQUENA, cor: c_white,                       y: 0.65 },
    { t: 320, texto: "ROTEIRO",                                    f: FONTE.MINI,    cor: make_color_rgb(255, 210, 90),  y: 0.74 },
    { t: 340, texto: "ISAAC  ·  EDUARDO  ·  I.A. CLAUDE",          f: FONTE.PEQUENA, cor: c_white,                       y: 0.79 },
    { t: 410, texto: "FACULDADE FAPAN",                            f: FONTE.PEQUENA, cor: make_color_rgb(190, 190, 195), y: 0.89 }
];
creditos_anim_fim = 410 + 40;                  // última linha terminou de aparecer
creditos_total    = creditos_anim_fim + 300 + 50;   // + 5 s parado + saída

// Título: letra por letra, depois o subtítulo e os desenvolvedores;
// quando tudo terminou, o nome fica 5 s na tela e então vem o menu.
titulo_inicio     = 40;
titulo_intervalo  = 8;
sub_inicio        = titulo_inicio + (string_length(JOGO_TITULO) - 1) * titulo_intervalo + 40;
if (global.logo_img != -1) sub_inicio = titulo_inicio + 120;     // com a logo: ela surge e depois vem o subtítulo
sub_intervalo     = 4;
devs_inicio       = sub_inicio + (string_length(JOGO_SUBTITULO) - 1) * sub_intervalo + 30;
titulo_anim_fim   = devs_inicio + 45;
titulo_total      = titulo_anim_fim + 300 + 45;     // + 5 s parado + transição

// ----- funções -----
atualizar_slots = function()
{
    slots = [slot_info(1), slot_info(2), slot_info(3)];
    tem_save = slots[0].existe or slots[1].existe or slots[2].existe;
};
atualizar_slots();

mudar_estado = function(_novo, _sel, _com_som = true)
{
    // som da tela inicial: voltar (ESC) ou escolher
    if (_com_som)
    {
        var _volta = (_novo == "menu") or (_novo == "opcoes" and (estado == "teclado" or estado == "controle"))
            or (_novo == "dificuldade" and estado == "slot_novo");
        som(_volta ? "tit_voltar" : "tit_selecao", 0.8, 0.02);
    }
    estado = _novo;
    selecionado = _sel;
    selecionado_antes = -1;
    tempo = 0;
    capturando = false;
    confirmar_slot = -1;
    mensagem = "";
    if (_novo == "menu" or _novo == "carregar" or _novo == "slot_novo") atualizar_slots();
};

aviso_menu = function(_txt)
{
    mensagem = _txt;
    mensagem_tempo = 150;
};

// Começa a partida no slot escolhido
iniciar_jogo = function(_slot)
{
    partida_resetar();
    global.nome_guerreiro = NOME_GUERREIRO;
    global.save_slot_atual = _slot;
    global.capitulo = 1;
    // som de START e a cutscene do prólogo; depois dela vem o carregamento da fase 1
    som("tit_start", 1, 0);
    instance_create_depth(0, 0, -10500, obj_cutscene);
};

// Texto do valor de cada linha das opções
valor_opcao = function(_i)
{
    switch (_i)
    {
        case 0: var _nq = config_nomes_qualidade(); return _nq[global.cfg_qualidade];
        case 1: var _nf = config_nomes_fps(); return _nf[global.cfg_fps];
        case 2: return global.cfg_tela_cheia ? "TELA CHEIA" : "JANELA";
        case 3:
            var _np = config_nomes_proporcao();
            var _p = _np[global.cfg_proporcao];
            if (global.cfg_proporcao == 0) _p += " (" + config_nome_aspecto(display_get_width(), display_get_height()) + ")";
            return _p;
        case 4:
            var _r = config_tamanho_resolucao(global.cfg_proporcao, global.cfg_resolucao);
            return string(_r[0]) + " x " + string(_r[1]);
        case 5: return string(round(global.cfg_volume * 100)) + "%";
        case 6: return string(round(global.cfg_vol_musica * 100)) + "%";
        case 7: return string(round(global.cfg_vol_efeitos * 100)) + "%";
        case 8: return global.cfg_fundo_hd ? "LIGADO" : "DESLIGADO";
        case 9: return global.cfg_tutorial ? "LIGADO" : "DESLIGADO";
        case 10: return "PERSONALIZAR";
        case 11: return gamepad_descricao_conectado();
    }
    return "";
};

// Explicação mostrada no rodapé das opções
descricao_opcao = function(_i)
{
    switch (_i)
    {
        case 0: return "Quantidade de partículas, brilhos e tremor de câmera.";
        case 1: return "30 ou 60 quadros por segundo. A velocidade do jogo é a mesma nos dois.";
        case 2: return "Tela cheia ocupa o monitor inteiro, sem barras pretas e sem distorcer a imagem. Atalho: F11.";
        case 3:
            if (global.cfg_tela_cheia) return "Em tela cheia o jogo usa a proporção do monitor (" + config_nome_aspecto(display_get_width(), display_get_height()) + ") para cobrir toda a tela. A proporção escolhida vale para o modo janela.";
            return "Formato da janela. AUTOMÁTICA usa o mesmo formato do seu monitor.";
        case 4:
            if (global.cfg_tela_cheia) return "Em tela cheia: resolução interna da imagem (menor = mais leve).";
            return "Tamanho da janela. Se for maior que o monitor, ela é reduzida mantendo a proporção.";
        case 5: return "Volume geral do jogo.";
        case 6: return "Volume das músicas (fase e chefe).";
        case 7: return "Volume dos efeitos: espada, golpes, trovões, chuva e fogo.";
        case 8: return "Fundo da fase 1 em alta definição (imagem ampliada e suavizada). Se notar qualquer falha, desligue para voltar ao fundo original.";
        case 9: return "Pergaminhos de tutorial durante a fase (movimento, combate, especiais...). Desligue se já conhece o jogo. O livro de TUTORIAL do menu continua disponível.";
        case 10: return "Escolha as teclas de cada ação.";
        case 11:
            if (global.pad_slot >= 0 and global.pad_botoes <= 0) return "Controle conectado, mas sem botões reconhecidos. Use um programa como DS4Windows ou x360ce para que ele funcione como controle de Xbox.";
            return "Escolha os botões do controle (Xbox, PlayStation ou genérico). SELECT abre a pausa e START a tela de armas.";
        case 12: return "Salva as configurações e volta ao menu.";
    }
    return "";
};

// Altera uma opção (passo = -1 ou +1)
alterar_opcao = function(_i, _passo)
{
    switch (_i)
    {
        case 0: global.cfg_qualidade = (global.cfg_qualidade + _passo + 3) mod 3; break;
        case 1: global.cfg_fps = 1 - global.cfg_fps; break;
        case 2: global.cfg_tela_cheia = 1 - global.cfg_tela_cheia; break;
        case 3:
            global.cfg_proporcao = (global.cfg_proporcao + _passo + 5) mod 5;
            // escolhe a resolução mais próxima de 1080p na nova lista
            var _lista = config_lista_resolucoes(global.cfg_proporcao);
            var _melhor = 0;
            for (var _k = 0; _k < array_length(_lista); _k++) if (_lista[_k][1] <= 1080) _melhor = _k;
            global.cfg_resolucao = _melhor;
        break;
        case 4:
            var _n = array_length(config_lista_resolucoes(global.cfg_proporcao));
            global.cfg_resolucao = (global.cfg_resolucao + _passo + _n) mod _n;
        break;
        case 5: global.cfg_volume = clamp(global.cfg_volume + _passo * 0.1, 0, 1); break;
        case 6: global.cfg_vol_musica = clamp(global.cfg_vol_musica + _passo * 0.1, 0, 1); break;
        case 7:
            global.cfg_vol_efeitos = clamp(global.cfg_vol_efeitos + _passo * 0.1, 0, 1);
            som("tit_selecao", 0.8);          // amostra do volume
        break;
        case 8: global.cfg_fundo_hd = 1 - global.cfg_fundo_hd; break;
        case 9: global.cfg_tutorial = 1 - global.cfg_tutorial; break;
        default: return;
    }
    if (_i != 7) som("tit_alterar", 0.7, 0.03);
    config_aplicar();
    config_salvar();
};

// ----- layout (usado no Step para o mouse e no Draw) -----
menu_y = function(_i) { return 296 + _i * 60; };
cfg_y  = function(_i) { return 154 + _i * 35; };
dif_y  = function(_i) { return 196 + _i * 60; };

// Remapeamento em 2 colunas: 0..MAP_COL1-1 MOVIMENTO, MAP_COL1..ACAO.TOTAL-1 COMBATE,
// ACAO.TOTAL = RESTAURAR, ACAO.TOTAL + 1 = VOLTAR. Retorna [x do centro, y, largura].
map_pos = function(_i)
{
    var _gw = display_get_gui_width();
    var _cw = min((_gw - 100) / 2, 520);
    if (_i == ACAO.TOTAL) return [_gw / 2 - 150, 570, 270];
    if (_i == ACAO.TOTAL + 1) return [_gw / 2 + 150, 570, 270];
    var _col = (_i < MAP_COL1) ? 0 : 1;
    var _lin = (_i < MAP_COL1) ? _i : _i - MAP_COL1;
    var _cx = (_col == 0) ? (_gw / 2 - _cw / 2 - 10) : (_gw / 2 + _cw / 2 + 10);
    return [_cx, 180 + _lin * 46, _cw];
};
// Navegação em grade na tela de remapeamento
map_navegar = function(_i, _dx, _dy)
{
    var _n0 = MAP_COL1;
    var _n1 = ACAO.TOTAL - MAP_COL1;
    var _r = ACAO.TOTAL;
    var _v = ACAO.TOTAL + 1;
    if (_i == _r) { if (_dx != 0) return _v; return (_dy < 0) ? _n0 - 1 : 0; }
    if (_i == _v) { if (_dx != 0) return _r; return (_dy < 0) ? ACAO.TOTAL - 1 : _n0; }
    var _col = (_i < _n0) ? 0 : 1;
    var _lin = (_i < _n0) ? _i : _i - _n0;
    var _n = (_col == 0) ? _n0 : _n1;
    if (_dx != 0) return (_col == 0) ? _n0 + min(_lin, _n1 - 1) : _lin;
    _lin += _dy;
    if (_lin < 0 or _lin >= _n) return (_col == 0) ? _r : _v;
    return (_col == 0) ? _lin : _n0 + _lin;
};
