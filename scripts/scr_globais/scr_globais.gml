// =====================================================================
//  THE CURSE OF VALLACK  ·  A MALDIÇÃO DE VALLACK
//  scr_globais: estado global, fases, saves, dicas e utilidades
// =====================================================================

#macro JOGO_TITULO        "THE CURSE OF VALLACK"
#macro JOGO_SUBTITULO     "A MALDIÇÃO DE VALLACK"
#macro JOGO_VERSAO        "v1.4"
// altura (em pixels do mundo) que a câmera mostra
#macro CAMERA_ALTURA      420
// altura fixa da interface; a largura acompanha a proporção
#macro GUI_ALTURA         720
// tempo de recarga dos especiais (os 3 especiais usam a mesma barra)
#macro ESPECIAL_SEGUNDOS  10
// o projeto tem 2 fases; a DEMO termina ao vencer o boss da fase 1
#macro FASE_TOTAL         2
#macro DEMO_FIM_NA_FASE_1 true

// Twilight Vetrus é o herói da história (As Crônicas de Twilight: Twilight é o reino).
// O jogador não escolhe o nome. No HUD, se o nome completo não couber, aparece só o primeiro.
#macro NOME_GUERREIRO     "Twilight Vetrus"
#macro NOME_CURTO         "Twilight"

// ações do jogador. INTERAGIR (antes SALVAR) abre baús e salva nos cristais.
// ESQUIVA e FURIA vieram na v1.4.
enum ACAO  { ESQUERDA, DIREITA, PULAR, ATACAR, ESPECIAL, DEFENDER, INTERAGIR, AGACHAR, ATAQUE_FORTE, ATAQUE_SALTO, ESPECIAL_2, ESPECIAL_3, ESQUIVA, FURIA, TOTAL }
enum DIF   { FACIL, MEDIO, DIFICIL, EXTREMO, TOTAL }
enum FONTE { TITULO, GRANDE, MEDIA, PEQUENA, MINI, TOTAL }

// ---------------------------------------------------------------------
// Inicialização (roda uma única vez; chamadas extras não fazem nada)
// ---------------------------------------------------------------------
function globais_iniciar()
{
    if (variable_global_exists("globais_ok") and global.globais_ok) return;
    global.globais_ok = true;

    // ===== PARTIDA =====
    global.nome_guerreiro   = NOME_GUERREIRO;
    global.dificuldade      = DIF.MEDIO;
    global.save_slot_atual  = 1;
    global.capitulo         = 1;
    global.checkpoint_ativo = false;
    global.checkpoint_room  = noone;
    global.checkpoint_x     = 0;
    global.checkpoint_y     = 0;
    global.vida_carregada   = -1;
    global.transicao_fase   = false;
    global.jogo_finalizado  = false;
    global.intro_vista      = false;
    global.ultimo_x         = 0;
    global.ultimo_y         = 0;
    global.ultima_vida      = 100;

    // ===== COMBATE / EFEITOS =====
    global.combo            = 0;
    global.combo_tempo      = 0;
    global.attacks_total    = 0;
    global.hits_total       = 0;
    global.last_hit_flash   = 0;
    global.last_hit_damage  = 0;
    global.camera_impact    = 0;
    global.camera_zoom      = 1;
    global.terremoto        = 0;     // tremor longo da tela (especiais que batem no chão)

    // ===== TUTORIAL (pergaminhos já mostrados nesta partida) =====
    global.tut_visto             = array_create(TUT.TOTAL, false);
    global.inimigos_derrotados   = 0;

    // ===== PROGRESSO: orbs, nível da espada e estatísticas da partida =====
    global.orbs            = 0;      // orbs para gastar (evoluir a espada)
    global.orbs_coletados  = 0;      // total coletado na partida (tela de resultado)
    global.espada_nivel    = 1;
    global.tempo_jogo      = 0;      // segundos jogados
    global.abertos         = [];     // baús abertos, paredes quebradas e segredos já achados
    global.marca           = { orbs: 0, coletados: 0, derrotados: 0, nivel: 1 };   // ao morrer volta a isto

    // ===== IMPACTO (pausa curtinha nos golpes e câmera lenta) =====
    global.hitstop     = 0;
    global.lenta_t     = 0;
    global.lenta_fator = 1;
    global.dt_real     = 1;

    // ===== TEMPO =====
    // dt = 1 a 60 FPS e 2 a 30 FPS. Toda a lógica é escrita em "quadros de 60 FPS"
    // e multiplicada por dt; assim o jogo tem a mesma velocidade nas duas opções.
    global.dt = 1;

    // ===== CÂMERA =====
    global.cam_x = 0;
    global.cam_y = 0;
    global.cam_zoom_atual = 1;
    global.cam_snap = true;
    global.cam_lim_esq = 0;          // arena fechada: limites da câmera
    global.cam_lim_dir = 100000;
    global.fala_espera = 0;          // falas dos inimigos não se atropelam
    global.orb_som_t = 0;
    global.orb_seq = 0;

    // ===== TELA =====
    global.tela_aspecto      = 16 / 9;
    global.tela_trocando     = 0;
    global.tela_redimensionar = true;
    global.tela_centralizar  = 0;
    global.tela_janela_w     = 0;
    global.tela_janela_h     = 0;

    // ===== DEPURAÇÃO (F1 mostra máscaras e hitboxes) =====
    global.debug_hitbox = false;

    // ===== CONTROLES =====
    global.teclas = teclas_padrao();
    global.botoes = botoes_padrao();
    global.inp_segurado = array_create(ACAO.TOTAL, false);
    global.inp_apertado = array_create(ACAO.TOTAL, false);
    global.inp_pad_apertado = array_create(ACAO.TOTAL, false);
    global.pad_slot = -1;
    global.pad_desc = "";
    global.pad_botoes = 0;
    global.pad_aviso = 0;        // aviso "controle conectado / desconectado"
    global.pad_aviso_txt = "";
    global.usando_pad = false;   // último comando veio do controle (troca os ícones da interface)
    global.pad_eixo = 0;         // inclinação do analógico (0..1)
    global.esquiva_stick = 0;    // analógico direito: -1 / 1 no quadro do "toque"
    global.eixo_dir_antes = 0;
    global.orbs_fx = 0;          // o pote de orbs do HUD pulsa ao coletar
    global.bloqueio_input = 0;   // quadros em que o jogador ignora comandos (após fechar menus)
    input_nav_iniciar();

    // ===== CONFIGURAÇÕES PADRÃO (config_carregar sobrescreve) =====
    global.cfg_tela_cheia = 0;
    global.cfg_proporcao  = 0;   // 0 = automática (proporção do monitor)
    global.cfg_resolucao  = 1;
    global.cfg_qualidade  = 2;
    global.cfg_fps        = 1;
    global.cfg_volume     = 1;   // volume geral
    global.cfg_vol_musica = 0.75;
    global.cfg_vol_efeitos = 1;
    global.cfg_fundo_hd   = 1;   // fundo da fase 1 em alta definição
    global.cfg_tutorial   = 1;   // pergaminhos de tutorial durante a fase (OPÇÕES / tela de dificuldade)
    global.cfg_window_width  = 1280;
    global.cfg_window_height = 720;

    // ===== FONTES (carregadas pelo obj_sistema) =====
    global.fonte_ok    = false;
    global.fonte_super = 1;
    global.fontes      = array_create(FONTE.TOTAL, -1);
    global.fonte_esc   = array_create(FONTE.TOTAL, 1);

    // ===== TEXTURAS HD dos personagens (scr_hd) =====
    hd_iniciar();
}

// Zera tudo o que pertence a uma partida (novo jogo / fim de jogo).
function partida_resetar()
{
    global.nome_guerreiro   = NOME_GUERREIRO;
    global.capitulo         = 1;
    global.checkpoint_ativo = false;
    global.checkpoint_room  = noone;
    global.checkpoint_x     = 0;
    global.checkpoint_y     = 0;
    global.vida_carregada   = -1;
    global.transicao_fase   = false;
    global.jogo_finalizado  = false;
    global.combo            = 0;
    global.combo_tempo      = 0;
    global.attacks_total    = 0;
    global.hits_total       = 0;
    global.last_hit_flash   = 0;
    global.camera_impact    = 0;
    global.camera_zoom      = 1;
    global.terremoto        = 0;
    global.tut_visto = array_create(TUT.TOTAL, false);
    global.inimigos_derrotados = 0;
    global.orbs            = 0;
    global.orbs_coletados  = 0;
    global.espada_nivel    = 1;
    global.tempo_jogo      = 0;
    global.abertos         = [];
    global.marca           = { orbs: 0, coletados: 0, derrotados: 0, nivel: 1 };
    global.hitstop         = 0;
    global.lenta_t         = 0;
    global.lenta_fator     = 1;
}

// ---------------------------------------------------------------------
// Pausar / retomar o mundo (o controlador do sistema nunca é congelado)
// ---------------------------------------------------------------------
function mundo_pausar()
{
    instance_deactivate_all(true);
    instance_activate_object(obj_sistema);
    instance_activate_object(obj_fundo_hd);     // FUNDO HD: só desenha o fundo (não tem lógica)
}

function mundo_retomar()
{
    instance_activate_all();
}

// ---------------------------------------------------------------------
// Fases
// ---------------------------------------------------------------------
function fase_numero(_room)
{
    if (_room == Room1) return 1;
    if (_room == Room2) return 2;
    return 0;
}

function fase_room(_numero)
{
    return (_numero >= 2) ? Room2 : Room1;
}

function fase_nome(_numero)
{
    if (_numero >= 2) return "O SALÃO REAL EM RUÍNAS";
    return "A CAMINHO DO CASTELO";
}

function fase_sub(_numero)
{
    if (_numero >= 2) return "No coração do castelo, a maldição aguarda. Derrote todos os inimigos.";
    return "A estrada até as muralhas de Vallack está tomada por bestas amaldiçoadas.";
}

function fase_objetivo(_numero)
{
    if (_numero >= 2) return "Derrote todos os inimigos do salão";
    return "Siga para o leste até o castelo  »";
}

// ---------------------------------------------------------------------
// Saves (3 slots)
// ---------------------------------------------------------------------
function slot_arquivo(_slot) { return "save_slot" + string(clamp(_slot, 1, 3)) + ".ini"; }
function slot_existe(_slot)  { return file_exists(slot_arquivo(_slot)); }

function slot_vazio_primeiro()
{
    for (var _i = 1; _i <= 3; _i++) if (!slot_existe(_i)) return _i;
    return -1;
}

function slot_info(_slot)
{
    var _info = { existe: false, nome: NOME_GUERREIRO, fase: 1, data: "", vida: 100, dificuldade: DIF.MEDIO, nivel: 1, orbs: 0 };
    if (!slot_existe(_slot)) return _info;
    ini_open(slot_arquivo(_slot));
    _info.existe = true;
    _info.nome   = ini_read_string("jogo", "nome", "Guerreiro");
    var _sala    = asset_get_index(ini_read_string("jogo", "sala", "Room1"));
    _info.fase   = clamp(round(ini_read_real("jogo", "fase", max(1, fase_numero(_sala)))), 1, FASE_TOTAL);
    _info.data   = ini_read_string("jogo", "data", "");
    _info.vida   = ini_read_real("jogo", "vida", 100);
    _info.dificuldade = clamp(round(ini_read_real("jogo", "dificuldade", DIF.MEDIO)), 0, DIF.TOTAL - 1);
    _info.nivel  = clamp(round(ini_read_real("jogo", "espada_nivel", 1)), 1, ESPADA_NIVEL_MAX);
    _info.orbs   = ini_read_real("jogo", "orbs", 0);
    _info.nome   = NOME_GUERREIRO;
    ini_close();
    return _info;
}

function salvar_slot(_slot, _mostrar = true)
{
    _slot = clamp(_slot, 1, 3);

    // O jogador grava sua posição em global.ultimo_x/y todo quadro. Assim o save
    // funciona mesmo com o jogo pausado (jogador desativado).
    var _px = global.ultimo_x;
    var _py = global.ultimo_y;
    var _pv = global.ultima_vida;
    var _p  = instance_find(obj_player, 0);
    if (_p != noone) { _px = _p.x; _py = _p.y; _pv = _p.vida; }

    var _fase = fase_numero(room);
    if (_fase <= 0) return false;

    global.save_slot_atual = _slot;
    ini_open(slot_arquivo(_slot));
    ini_write_string("jogo", "nome", global.nome_guerreiro);
    ini_write_string("jogo", "sala", room_get_name(room));
    ini_write_real("jogo", "fase", _fase);
    ini_write_real("jogo", "dificuldade", global.dificuldade);
    ini_write_real("jogo", "x", _px);
    ini_write_real("jogo", "y", _py);
    ini_write_real("jogo", "vida", max(1, _pv));
    ini_write_real("jogo", "orbs", global.orbs);
    ini_write_real("jogo", "orbs_coletados", global.orbs_coletados);
    ini_write_real("jogo", "espada_nivel", global.espada_nivel);
    ini_write_real("jogo", "tempo", global.tempo_jogo);
    ini_write_real("jogo", "derrotados", global.inimigos_derrotados);
    ini_write_string("jogo", "abertos", abertos_texto());
    ini_write_string("jogo", "data", date_datetime_string(date_current_datetime()));
    ini_close();

    global.checkpoint_ativo = true;
    global.checkpoint_room  = room;
    global.checkpoint_x     = _px;
    global.checkpoint_y     = _py;
    progresso_marcar();

    if (_mostrar) aviso_mostrar("JOGO SALVO  ·  SLOT " + string(_slot));
    return true;
}

function carregar_slot(_slot)
{
    _slot = clamp(_slot, 1, 3);
    if (!slot_existe(_slot)) return false;
    partida_resetar();
    ini_open(slot_arquivo(_slot));
    global.nome_guerreiro  = NOME_GUERREIRO;
    global.dificuldade     = clamp(round(ini_read_real("jogo", "dificuldade", DIF.MEDIO)), 0, DIF.TOTAL - 1);
    var _sala = asset_get_index(ini_read_string("jogo", "sala", "Room1"));
    // saves antigos podem apontar para fases que não existem mais (Room3..Room5)
    if (_sala == -1 or fase_numero(_sala) == 0) _sala = fase_room(ini_read_real("jogo", "fase", 1));
    global.checkpoint_room = _sala;
    global.checkpoint_x    = ini_read_real("jogo", "x", 80);
    global.checkpoint_y    = ini_read_real("jogo", "y", 640);
    global.vida_carregada  = ini_read_real("jogo", "vida", 100);
    global.orbs            = ini_read_real("jogo", "orbs", 0);
    global.orbs_coletados  = ini_read_real("jogo", "orbs_coletados", 0);
    global.espada_nivel    = clamp(round(ini_read_real("jogo", "espada_nivel", 1)), 1, ESPADA_NIVEL_MAX);
    global.tempo_jogo      = ini_read_real("jogo", "tempo", 0);
    global.inimigos_derrotados = ini_read_real("jogo", "derrotados", 0);
    global.abertos         = abertos_de_texto(ini_read_string("jogo", "abertos", ""));
    ini_close();
    progresso_marcar();
    global.capitulo         = fase_numero(_sala);
    global.save_slot_atual  = _slot;
    global.checkpoint_ativo = true;
    // quem continua um jogo salvo já viu os pergaminhos (estão no TUTORIAL do menu)
    global.tut_visto = array_create(TUT.TOTAL, true);
    return true;
}

function aviso_mostrar(_texto)
{
    with (obj_aviso) instance_destroy();
    var _a = instance_create_depth(0, 0, -10001, obj_aviso);
    _a.texto = _texto;
}

// ---------------------------------------------------------------------
// Dicas de tutorial (usadas nas telas de carregamento e no menu)
// ---------------------------------------------------------------------
function dicas_tutorial()
{
    return [
        "Aperte " + rotulo_acao(ACAO.ATACAR) + " várias vezes: Twilight encadeia os golpes num combo completo.",
        "COMBO 1: " + rotulo_acao(ACAO.ATACAR) + " " + rotulo_acao(ACAO.ATACAR) + " " + rotulo_acao(ACAO.ATACAR) + ". Os combos 2 (" + rotulo_acao(ACAO.ATAQUE_FORTE) + " no fim) e 3 (" + rotulo_acao(ACAO.ATAQUE_SALTO) + " no fim) chegam ao evoluir a espada.",
        "Aperte " + rotulo_acao(ACAO.DEFENDER) + " no instante do golpe inimigo para APARAR: o golpe é rebatido e o inimigo fica tonto.",
        "Inimigo atordoado com o ícone sobre a cabeça: aperte " + rotulo_acao(ACAO.ATAQUE_SALTO) + " perto dele para o FINALIZADOR.",
        "Use " + rotulo_acao(ACAO.ESQUIVA) + " para rolar: no meio da rolagem nada acerta Twilight.",
        "A barra de FÚRIA enche ao acertar e ao aparar. Cheia, aperte " + rotulo_acao(ACAO.FURIA) + " para liberar a Ira de Vallack.",
        "Inimigos derrotados soltam ORBS. Na tela de ARMAS (TAB / START) elas evoluem a espada e liberam combos e especiais.",
        "Finalizadores rendem 50% a mais de orbs e recuperam um pouco de vida.",
        "Os especiais gastam a barra de MAGIA: Tremor 60%, Onda 40% e Queda 70%. Ela enche em " + string(ESPECIAL_SEGUNDOS) + " segundos.",
        "A vida não volta sozinha: procure os BAÚS DE VIDA, às vezes escondidos dentro de caixotes.",
        "Caixotes quebram com golpes, e dá para subir neles para escapar de armadilhas.",
        "Paredes rachadas escondem segredos. Golpes pesados e especiais derrubam mais rápido.",
        "Bestas escudeiras seguram golpes de frente: insista até a guarda quebrar ou role para as costas delas.",
        "Golpes marcados com QUEBRA-GUARDA atravessam a defesa: saia do alcance ou role!",
        "Arqueiros fogem quando você chega perto e voltam para a distância de tiro quando você se afasta.",
        "Uma flecha aparada na hora certa volta contra o arqueiro.",
        "Vigas em chamas caem do alto: quando a poeira cair, saia de baixo!",
        "A Árvore Amaldiçoada fecha a arena com muralhas mágicas e invoca ondas de servos.",
        "Com metade da vida a Árvore se enfurece: três bolas de fogo e raízes que saem do chão.",
        "Só existem dois cristais dourados por fase: no início e no meio. Aperte " + rotulo_acao(ACAO.INTERAGIR) + " perto deles para salvar.",
        "No nível EXTREMO o cristal dourado não recupera a vida: só os baús.",
        "ESC / SELECT abre a pausa, com o volume da música e dos efeitos.",
        "Teclas e botões do controle podem ser personalizados em OPÇÕES. F11 alterna a tela cheia."
    ];
}

// ---------------------------------------------------------------------
// Níveis de dificuldade
// ---------------------------------------------------------------------
function dif_valor(_lista)
{
    return _lista[clamp(global.dificuldade, 0, DIF.TOTAL - 1)];
}
function dificuldade_nome(_d = global.dificuldade)
{
    var _n = ["FÁCIL", "MÉDIO", "DIFÍCIL", "EXTREMO"];
    return _n[clamp(_d, 0, DIF.TOTAL - 1)];
}
function dificuldade_cor(_d = global.dificuldade)
{
    var _c = [make_color_rgb(120, 220, 110), make_color_rgb(255, 210, 90), make_color_rgb(255, 140, 50), make_color_rgb(235, 40, 40)];
    return _c[clamp(_d, 0, DIF.TOTAL - 1)];
}
function dificuldade_descricao(_d)
{
    switch (_d)
    {
        case DIF.FACIL:   return ["Inimigos mais fracos e mais lentos para atacar.", "Só 1 inimigo ataca de cada vez.", "Boss e mini-boss com menos vida."];
        case DIF.MEDIO:   return ["A experiência equilibrada do jogo.", "Até 2 inimigos atacam ao mesmo tempo.", "A vida volta nos baús e nos cristais dourados."];
        case DIF.DIFICIL: return ["Inimigos mais resistentes e com mais dano.", "Boss mais rápido e com mais vida.", "Golpes inimigos quebram a guarda com mais frequência."];
    }
    return ["Inimigos causam muito mais dano.", "O cristal dourado não cura: só os baús de vida.", "Boss implacável."];
}
// multiplicadores e valores usados pelos objetos
// (v1.4: a vida não regenera sozinha em nenhum nível; o jogador leva menos golpes)
function dif_dano_inimigo()   { return dif_valor([0.5, 0.8, 1.1, 1.6]); }
function dif_vida_inimigo()   { return dif_valor([0.75, 1.0, 1.3, 1.6]); }
function dif_vida_boss()      { return dif_valor([0.7, 1.0, 1.3, 1.6]); }
function dif_recarga_inimigo(){ return dif_valor([1.5, 1.15, 0.95, 0.8]); }   // espera entre golpes
function dif_atordoamento()   { return dif_valor([1.25, 1.0, 0.85, 0.7]); }   // duração do atordoamento
function dif_atacantes_max()  { return dif_valor([1, 2, 2, 3]); }             // inimigos atacando juntos
function dif_regen_espera()   { return 0; }
function dif_regen_taxa()     { return 0; }                                   // a vida não enche sozinha
function dif_cristal_cura()   { return global.dificuldade != DIF.EXTREMO; }
function dif_boss_recarga()   { return dif_valor([150, 110, 85, 65]); }       // quadros entre bolas de fogo
function dif_quebra_guarda()  { return dif_valor([5, 4, 3, 2]); }             // a cada N golpes, 1 quebra a guarda

// ---------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------
// lerp independente da taxa de quadros
function lerp_dt(_a, _b, _k)
{
    return lerp(_a, _b, 1 - power(1 - clamp(_k, 0, 1), global.dt));
}

function array_tem(_arr, _valor)
{
    for (var _i = 0; _i < array_length(_arr); _i++) if (_arr[_i] == _valor) return true;
    return false;
}

function texto_aparar(_s)
{
    while (string_length(_s) > 0 and string_char_at(_s, 1) == " ") _s = string_delete(_s, 1, 1);
    while (string_length(_s) > 0 and string_char_at(_s, string_length(_s)) == " ") _s = string_delete(_s, string_length(_s), 1);
    return _s;
}

// ---------------------------------------------------------------------
// Baús abertos, paredes quebradas e segredos (gravados no save)
// ---------------------------------------------------------------------
function aberto_chave(_tipo, _x, _y) { return room_get_name(room) + ":" + _tipo + ":" + string(round(_x)) + ":" + string(round(_y)); }
function aberto_tem(_chave) { return array_tem(global.abertos, _chave); }
function aberto_marcar(_chave) { if (!aberto_tem(_chave)) array_push(global.abertos, _chave); }
function abertos_texto()
{
    var _s = "";
    for (var _i = 0; _i < array_length(global.abertos); _i++) _s += ((_i > 0) ? "|" : "") + global.abertos[_i];
    return _s;
}
function abertos_de_texto(_s)
{
    var _r = [];
    if (_s == "") return _r;
    var _p = string_split(_s, "|");
    for (var _i = 0; _i < array_length(_p); _i++) if (_p[_i] != "") array_push(_r, _p[_i]);
    return _r;
}

// Progresso guardado no checkpoint: ao morrer, orbs e contadores voltam a ele
function progresso_marcar()
{
    global.marca = { orbs: global.orbs, coletados: global.orbs_coletados, derrotados: global.inimigos_derrotados, nivel: global.espada_nivel };
}
function progresso_reverter()
{
    global.orbs = global.marca.orbs;
    global.orbs_coletados = global.marca.coletados;
    global.inimigos_derrotados = global.marca.derrotados;
    global.espada_nivel = max(global.espada_nivel, global.marca.nivel);
}

// Pausa curtinha (impacto) e câmera lenta
function impacto(_quadros) { global.hitstop = max(global.hitstop, _quadros); }
function camera_lenta(_quadros, _fator) { global.lenta_t = max(global.lenta_t, _quadros); global.lenta_fator = min(global.lenta_fator, _fator); }

// Tempo em texto (mm:ss)
function tempo_texto(_seg)
{
    var _m = floor(_seg / 60);
    var _s = floor(_seg mod 60);
    return string(_m) + ":" + ((_s < 10) ? "0" : "") + string(_s);
}

// Primeiro ponto de chão (obj_chao) abaixo de (_x, _y). Retorna _y se não achar.
// Altura do chão no meio da sala, ou -1 se o chão ainda não existe ou está
// desativado (tela de carregamento, pausa). Quem usa tenta de novo depois.
function chao_da_sala()
{
    var _cx = room_width / 2;
    var _y = chao_abaixo(_cx, 300, 420);
    return position_meeting(_cx, _y, obj_chao) ? _y : -1;
}

function chao_abaixo(_x, _y, _max = 400)
{
    for (var _i = 0; _i < _max; _i++)
    {
        if (position_meeting(_x, _y + _i, obj_chao)) return _y + _i;
    }
    return _y;
}
