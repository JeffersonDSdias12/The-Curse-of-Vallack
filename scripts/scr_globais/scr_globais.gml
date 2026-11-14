// =====================================================================
//  THE CURSE OF VALLACK  ·  A MALDIÇÃO DE VALLACK
//  scr_globais: estado global, fases, saves, dicas e utilidades
// =====================================================================

#macro JOGO_TITULO        "THE CURSE OF VALLACK"
#macro JOGO_SUBTITULO     "A MALDIÇÃO DE VALLACK"
#macro JOGO_VERSAO        "v1.17"
// altura (em pixels do mundo) que a câmera mostra (v1.13: 420 -> 280, a câmera
// bem mais perto do herói)
#macro CAMERA_ALTURA      280
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
    global.cam_frente = 40;          // "olhar à frente" atual da câmera (desliza)
    global.cam_frente_alvo = 40;
    global.cam_chute_x = 0;          // "chute" da câmera na direção do golpe (volta aos poucos)
    global.cam_chute_y = 0;
    global.cam_baixo = 0;            // v1.20: quanto a câmera desce além do fim da sala (pontes que desabam)
    global.cam_baixo_alvo = 0;
    global.cam_combate = 0;          // v1.20: 0..1, quanto a câmera está "em duelo"
    global.cam_foco_x = 0;           // v1.20: desvio da câmera na direção dos inimigos próximos
    global.cam_soco = 0;             // v1.20: "soco" de zoom a cada pancada
    global.fatal_t = 0;              // intervalo da câmera lenta do golpe fatal
    global.cam_lim_esq = 0;          // arena fechada: limites da câmera
    global.cam_lim_dir = 100000;
    global.fala_espera = 0;          // falas dos inimigos não se atropelam
    global.perfil_salvar_t = 0;      // v1.18: >0 = conquista esperando para ser gravada
    global.grito_espera = 0;         // v1.19: um grito com balão por leva de inimigos
    global.fala_batalha_room = -1;   // v1.19: fase em que Twilight já fez a fala de batalha
    global.veu_t   = 0;              // v1.19: véu de transição entre telas (transicao_revelar)
    global.veu_dur = 0;
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
    // v1.12: essência (sub-armas)
    global.essencia = ESSENCIA_INICIO;
    global.essencia_coletada = 0;
    global.essencia_fx = 0;
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
    global.cfg_tutorial   = 1;   // v1.13: tutorial "Como jogar" na tela de carregamento das fases (OPÇÕES / tela de dificuldade)
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
    global.inimigos_derrotados = 0;
    global.orbs            = 0;
    global.orbs_coletados  = 0;
    global.espada_nivel    = 1;
    global.tempo_jogo      = 0;
    global.abertos         = [];
    global.marca           = { orbs: 0, coletados: 0, derrotados: 0, nivel: 1, essencia: ESSENCIA_INICIO };
    global.essencia        = ESSENCIA_INICIO;
    global.essencia_coletada = 0;
    global.essencia_fx     = 0;
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
    var _info = { existe: false, nome: NOME_GUERREIRO, fase: 1, data: "", vida: 100, dificuldade: DIF.MEDIO, nivel: 1, orbs: 0, perfil: "", tempo: 0 };
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
    _info.perfil = ini_read_string("jogo", "perfil", "");       // v1.20: de quem é o progresso
    _info.tempo  = ini_read_real("jogo", "tempo", 0);
    ini_close();
    return _info;
}

// v1.20: o save mais recente do perfil (o do CONTINUAR); -1 se não há nenhum
function slot_recente()
{
    if (!variable_global_exists("perfil")) perfil_carregar();
    var _u = global.perfil.ultimo_slot;
    if (_u >= 1 and _u <= 3 and slot_existe(_u)) return _u;
    for (var _i = 1; _i <= 3; _i++) if (slot_existe(_i)) return _i;
    return -1;
}

// tempo de jogo de um save, em texto (ex.: 1h 05min)
function tempo_jogo_texto(_segundos)
{
    var _seg = floor(_segundos);
    var _h = _seg div 3600;
    var _m = (_seg mod 3600) div 60;
    if (_h > 0) return string(_h) + "h " + ((_m < 10) ? "0" : "") + string(_m) + "min";
    return string(_m) + " min";
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

    // v1.20: o perfil guarda qual é o seu save mais recente e até onde já chegou
    if (!variable_global_exists("perfil")) perfil_carregar();
    global.perfil.ultimo_slot = _slot;
    global.perfil.fase_max = max(global.perfil.fase_max, _fase);
    global.perfil.sujo = true;
    perfil_salvar_se_mudou();

    global.save_slot_atual = _slot;
    ini_open(slot_arquivo(_slot));
    ini_write_string("jogo", "nome", global.nome_guerreiro);
    ini_write_string("jogo", "perfil", perfil_nome_exibir());
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
    ini_write_real("jogo", "essencia", global.essencia);
    ini_write_string("jogo", "abertos", abertos_texto());
    ini_write_string("jogo", "data", date_datetime_string(date_current_datetime()));
    ini_close();

    global.checkpoint_ativo = true;
    global.checkpoint_room  = room;
    global.checkpoint_x     = _px;
    global.checkpoint_y     = _py;
    progresso_marcar();

    if (_mostrar) aviso_mostrar("JOGO SALVO  ·  SLOT " + string(_slot), false);
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
    global.essencia        = clamp(round(ini_read_real("jogo", "essencia", ESSENCIA_INICIO)), 0, ESSENCIA_MAX);
    global.abertos         = abertos_de_texto(ini_read_string("jogo", "abertos", ""));
    ini_close();
    progresso_marcar();
    global.capitulo         = fase_numero(_sala);
    global.save_slot_atual  = _slot;
    global.checkpoint_ativo = true;
    return true;
}

// v1.16: o aviso toca o som da MENSAGEM IMPORTANTE (sfx_important_message);
// avisos de sistema (jogo salvo, checkpoint, controle) passam _som = false
function aviso_mostrar(_texto, _som = true)
{
    with (obj_aviso) instance_destroy();
    var _a = instance_create_depth(0, 0, -10001, obj_aviso);
    _a.texto = _texto;
    if (_som) som_mensagem();
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
        case DIF.FACIL:   return ["Inimigos fracos, lentos e só com o golpe básico.", "Só 1 inimigo ataca de cada vez.", "Chefes com menos vida."];
        case DIF.MEDIO:   return ["A experiência equilibrada: saltos, teias e ondas.", "Até 2 inimigos atacam ao mesmo tempo.", "A vida volta nos baús e nos cristais dourados."];
        case DIF.DIFICIL: return ["Inimigos rápidos, resistentes e com golpes novos.", "O porco invoca esqueletos; arqueiros atiram 2 flechas.", "Até 3 atacam juntos; a guarda quebra mais."];
    }
    return ["Inimigos implacáveis: dano e vida dobrados.", "Arqueiros atiram 3 flechas; até 4 atacam juntos.", "O cristal dourado não cura: só os baús de vida."];
}
// multiplicadores e valores usados pelos objetos
// (v1.4: a vida não regenera sozinha em nenhum nível; o jogador leva menos golpes)
// v1.13: níveis BEM SEPARADOS e combate mais intenso. Cada nível muda a vida, o
// dano, a espera entre golpes, a velocidade, quantos atacam juntos e QUAIS golpes
// cada inimigo usa (dif_golpe_liberado). O nível do inimigo no mapa (Nv 1-5,
// scr_inimigos_novos) sobe mais forte nas dificuldades altas: a fase 2 aperta mais.
//                                               FÁCIL  MÉDIO  DIFÍCIL EXTREMO
function dif_dano_inimigo()   { return dif_valor([0.5,  0.85,  1.25,   1.7]); }
function dif_vida_inimigo()   { return dif_valor([0.65, 1.0,   1.4,    1.9]); }
function dif_vida_boss()      { return dif_valor([0.7,  1.0,   1.35,   1.8]); }
function dif_recarga_inimigo(){ return dif_valor([1.5,  1.0,   0.78,   0.6]); }  // espera entre golpes
function dif_atordoamento()   { return dif_valor([1.3,  1.0,   0.8,    0.6]); }   // duração do atordoamento
function dif_atacantes_max()  { return dif_valor([1,    2,     3,      4]); }     // inimigos atacando juntos
function dif_velocidade()     { return dif_valor([0.88, 1.0,   1.1,    1.2]); }  // passo dos inimigos
function dif_nivel_vida()     { return dif_valor([0.08, 0.15,  0.22,   0.3]); }   // vida a mais por nível do mapa
function dif_nivel_dano()     { return dif_valor([0.05, 0.10,  0.15,   0.2]); }   // dano a mais por nível do mapa
function dif_regen_espera()   { return 0; }
function dif_regen_taxa()     { return 0; }                                   // a vida não enche sozinha
function dif_cristal_cura()   { return global.dificuldade != DIF.EXTREMO; }
function dif_boss_recarga()   { return dif_valor([150, 100, 75, 55]); }       // quadros entre bolas de fogo
function dif_quebra_guarda()  { return dif_valor([6, 4, 3, 2]); }             // a cada N golpes, 1 quebra a guarda
// golpes especiais dos inimigos: liberados a partir de um nível
// (DIF.FACIL = sempre, DIF.MEDIO, DIF.DIFICIL ou DIF.EXTREMO)
function dif_golpe_liberado(_nivel) { return global.dificuldade >= _nivel; }
// ---------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------
// lerp independente da taxa de quadros
function lerp_dt(_a, _b, _k)
{
    return lerp(_a, _b, 1 - power(1 - clamp(_k, 0, 1), global.dt));
}

// v1.14: o ANDAR obedece a velocidade (velh). Em vez de trocar +v por -v num
// quadro (o corpo "teletransportava" ao virar), a velocidade de andar sobe com
// _acel e cai com _frear por quadro de 60 FPS; para virar ela freia até zero
// e só então acelera para o outro lado. Chamado pela entidade (jogador/inimigo).
function velh_para(_alvo, _acel, _frear)
{
    // sem andar no quadro anterior (golpe, esquiva, empurrão): parte do velh atual,
    // limitado à velocidade de andar (a esquiva emenda na corrida sem tranco)
    var _v = anda_vivo_ant ? anda_v : clamp(velh, -abs(_alvo), abs(_alvo));
    var _a = ((_v != 0 and sign(_alvo) != sign(_v)) or abs(_alvo) < abs(_v)) ? _frear : _acel;
    _a *= global.dt;
    _v = (_v < _alvo) ? min(_v + _a, _alvo) : max(_v - _a, _alvo);
    anda_v = _v;
    anda_vivo = true;
    velh = _v;
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
    global.marca = { orbs: global.orbs, coletados: global.orbs_coletados, derrotados: global.inimigos_derrotados, nivel: global.espada_nivel, essencia: global.essencia };
}
function progresso_reverter()
{
    global.orbs = global.marca.orbs;
    global.orbs_coletados = global.marca.coletados;
    global.inimigos_derrotados = global.marca.derrotados;
    global.espada_nivel = max(global.espada_nivel, global.marca.nivel);
    if (variable_struct_exists(global.marca, "essencia")) global.essencia = global.marca.essencia;
}

// Pausa curtinha (impacto) e câmera lenta
function impacto(_quadros) { global.hitstop = max(global.hitstop, _quadros); }
function camera_lenta(_quadros, _fator) { global.lenta_t = max(global.lenta_t, _quadros); global.lenta_fator = min(global.lenta_fator, _fator); }

// PESO DO GOLPE: a câmera leva um "chute" na direção do impacto e volta aos
// poucos depois da pausa (o tremor aleatório sozinho não mostra de onde veio
// a pancada). Segura durante o hit-stop: a imagem "trava" deslocada.
function camera_empurrar(_dir_x, _forca, _dir_y = 0)
{
    if (global.cfg_qualidade == 0) _forca *= 0.5;
    global.cam_chute_x = clamp(global.cam_chute_x + _dir_x * _forca, -18, 18);
    global.cam_chute_y = clamp(global.cam_chute_y + _dir_y * _forca, -12, 12);
    camera_soco(abs(_forca) * 0.012);     // v1.20: toda pancada também fecha a câmera um instante
}

// v1.20: "soco" de zoom — a câmera fecha de repente e abre de volta
function camera_soco(_forca)
{
    if (!variable_global_exists("cam_soco")) global.cam_soco = 0;
    if (global.cfg_qualidade == 0) _forca *= 0.5;
    global.cam_soco = min(0.14, global.cam_soco + _forca);
}

// GOLPE FATAL (estilo Castlevania): o tempo congela, desacelera e o monstro
// explode em chamas. A câmera lenta tem intervalo, para não arrastar as hordas.
function golpe_fatal(_x, _y, _dir, _tam)
{
    impacto(7);
    camera_empurrar(_dir, 6, -0.3);
    global.camera_impact = max(global.camera_impact, 9);
    global.last_hit_flash = max(global.last_hit_flash, 7);
    if (global.fatal_t <= 0)
    {
        camera_lenta(16, 0.35);
        global.fatal_t = 75;
    }
    fx_em("chamas_morte", _x, _y, _tam, _dir, -105);
    som("fogo_explosao", 0.45, 0.1);
}

// Tempo em texto (mm:ss)
function tempo_texto(_seg)
{
    var _m = floor(_seg / 60);
    var _s = floor(_seg mod 60);
    return string(_m) + ":" + ((_s < 10) ? "0" : "") + string(_s);
}

// Altura do CHÃO PRINCIPAL da sala, ou -1 se o chão ainda não existe ou está
// desativado (tela de carregamento, pausa). Quem usa tenta de novo depois.
// v1.11: não mede mais num ponto só (no meio da sala podia ter uma pilha de
// caixotes ou um muro, e a chuva parava no topo deles). Agora soma a largura
// de todas as peças de obj_chao em cada altura e fica com a altura que tem
// mais chão. Não contam: os sólidos filhos do obj_chao (caixotes, barris,
// paredes, muralhas) e as paredes laterais da sala (peças altas e estreitas).
function chao_da_sala()
{
    var _topos = [];
    var _largs = [];
    with (obj_chao)
    {
        var _l = bbox_right - bbox_left;
        var _h = bbox_bottom - bbox_top;
        if (object_index == obj_chao and _l > 0 and !(_h > 250 and _h > _l))
        {
            var _achou = -1;
            for (var _i = 0; _i < array_length(_topos); _i++)
            {
                if (abs(_topos[_i] - bbox_top) <= 2) { _achou = _i; break; }
            }
            if (_achou < 0) { array_push(_topos, bbox_top); array_push(_largs, _l); }
            else _largs[_achou] += _l;
        }
    }
    var _melhor = -1, _maior = 0;
    for (var _i = 0; _i < array_length(_topos); _i++)
    {
        if (_largs[_i] > _maior) { _maior = _largs[_i]; _melhor = _topos[_i]; }
    }
    return _melhor;
}

// Primeiro ponto de chão (obj_chao) abaixo de (_x, _y). Retorna _y se não achar.
function chao_abaixo(_x, _y, _max = 400)
{
    for (var _i = 0; _i < _max; _i++)
    {
        if (position_meeting(_x, _y + _i, obj_chao)) return _y + _i;
    }
    return _y;
}
