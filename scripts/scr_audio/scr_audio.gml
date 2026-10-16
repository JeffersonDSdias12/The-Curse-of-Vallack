// =====================================================================
//  scr_audio: efeitos sonoros, músicas e ambientes
//  Todos os sons ficam em datafiles (Included Files) como OGG e tocam em
//  "stream" (o mesmo caminho das músicas). Cada efeito é aberto em algumas
//  cópias, para o mesmo som poder tocar várias vezes ao mesmo tempo.
//
//  CADA SOM PERTENCE AO SEU AMBIENTE ("cena" atual do jogo):
//   * "titulo"     tela inicial (abertura, menu, opções): tit_*  + mus_menu
//   * "cutscene"   prólogo antes da fase 1: cut_*                + mus_prologo
//   * "carregamento" telas de carregamento                      + mus_carregamento
//   * "fase"       jogando: ataques, especiais, acertos, cenário, fogo, chuva,
//                  menus do jogo (pausa, armas, cristal)        + mus_fase / mus_boss
//   * "transicao"  sons que atravessam a troca de tela (START do jogo)
//  Ao trocar de cena, os efeitos da cena anterior param (com um fade curto)
//  e a chuva / fogo só tocam com a fase rodando (nunca no carregamento).
//
//  Todos os sons foram sintetizados para o jogo; para trocar por outro,
//  basta substituir o arquivo OGG mantendo o nome.
// =====================================================================

// [nome, ambiente, cópias]
function audio_lista_efeitos()
{
    return [
        // ----- tela inicial -----
        ["tit_mover", "titulo", 3], ["tit_selecao", "titulo", 2], ["tit_alterar", "titulo", 3], ["tit_voltar", "titulo", 2],
        ["tit_negado", "titulo", 2], ["tit_logo", "titulo", 1], ["tit_start", "transicao", 1],
        // ----- cutscene -----
        ["cut_passar", "cutscene", 2],
        // ----- menus do jogo (pausa, armas, cristal, pergaminhos, game over) -----
        ["sfx_menu_abrir", "ui", 2], ["sfx_menu_fechar", "ui", 2], ["sfx_menu_mover", "ui", 3], ["sfx_menu_ok", "ui", 2],
        ["sfx_negado", "ui", 2], ["sfx_pagina", "ui", 2], ["sfx_salvar", "ui", 1], ["sfx_derrota", "ui", 1],
        // ----- ataques -----
        ["atk_corte_1", "fase", 3], ["atk_corte_2", "fase", 3], ["atk_aereo", "fase", 2], ["atk_pesado", "fase", 3],
        ["atk_rasteira", "fase", 2], ["atk_mergulho", "fase", 2], ["sfx_inimigo_golpe", "fase", 4], ["sfx_flecha", "fase", 3],
        // ----- especiais (com grave) -----
        ["esp_carga", "fase", 2], ["esp_tremor", "fase", 2], ["esp_onda", "fase", 2], ["esp_queda", "fase", 2],
        ["esp_furia", "fase", 1], ["esp_furia_impacto", "fase", 1], ["sfx_finalizador", "fase", 2], ["sfx_impacto", "fase", 3],
        // ----- acertos e defesa -----
        ["hit_1", "fase", 4], ["hit_2", "fase", 4], ["hit_3", "fase", 4], ["hit_pesado", "fase", 3], ["sfx_dano", "fase", 3],
        ["sfx_bloqueio", "fase", 3], ["sfx_aparar", "fase", 2], ["sfx_escudo_quebra", "fase", 2],
        // ----- destruição de elementos -----
        ["dest_madeira", "fase", 3], ["dest_pedra", "fase", 3], ["dest_viga", "fase", 2], ["dest_quique", "fase", 3],
        // ----- passar de fase, evoluir a espada, segredos -----
        ["fase_concluida", "fase", 1], ["espada_evoluir", "fase", 1], ["sfx_segredo", "fase", 1],
        // ----- fogo -----
        ["fogo_whoosh", "fase", 3], ["fogo_bola", "fase", 3], ["fogo_explosao", "fase", 3],
        // ----- movimento, itens, inimigos e clima -----
        ["sfx_esquiva", "fase", 2], ["sfx_pulo", "fase", 3], ["sfx_pouso", "fase", 3], ["sfx_orb", "fase", 4],
        ["sfx_bau", "fase", 1], ["sfx_cura", "fase", 2], ["sfx_portal", "fase", 3], ["sfx_rugido", "fase", 2],
        ["sfx_espinhos", "fase", 3], ["sfx_trovao_1", "fase", 1], ["sfx_trovao_2", "fase", 1], ["sfx_trovao_3", "fase", 1],
        // ----- v1.8: inimigos novos (esqueleto, aranha, porco, estátua) -----
        ["osso_chocalho", "fase", 2], ["osso_desmonta", "fase", 3], ["osso_ergue", "fase", 2], ["osso_quebra", "fase", 3],
        ["teia_disparo", "fase", 3], ["teia_prende", "fase", 2], ["aranha_chiado", "fase", 2],
        ["porco_grunhido", "fase", 2], ["porco_impacto", "fase", 2], ["magia_onda", "fase", 2],
        ["pedra_tinido", "fase", 3], ["estatua_carga", "fase", 2], ["estatua_disparo", "fase", 2], ["pedra_desmorona", "fase", 2],
        // ----- v1.10: a maldição levando o corpo dos inimigos (fumaça negra) -----
        ["maldicao_evaporar", "fase", 4], ["maldicao_grande", "fase", 1]
    ];
}

function audio_iniciar()
{
    if (variable_global_exists("audio_ok") and global.audio_ok) return;
    global.audio_ok = true;
    global.audio_cena = "titulo";
    global.sfx = {};
    global.sfx_tocando = [];             // { inst, amb } dos efeitos tocando agora
    global.sfx_saindo = [];              // efeitos de outra cena diminuindo até parar
    var _lista = audio_lista_efeitos();
    for (var _i = 0; _i < array_length(_lista); _i++)
    {
        var _nome = _lista[_i][0];
        var _arq = _nome + ".ogg";
        if (!file_exists(_arq)) { show_debug_message("Som não encontrado: " + _arq); continue; }
        var _copias = [];
        // se um arquivo não abrir, o jogo segue sem aquele som (não trava)
        try { repeat (_lista[_i][2]) array_push(_copias, audio_create_stream(_arq)); }
        catch (_erro) { show_debug_message("Som não carregado: " + _arq); }
        if (array_length(_copias) > 0) global.sfx[$ _nome] = { s: _copias, prox: 0, amb: _lista[_i][1] };
    }
    global.streams = {};
    var _ms = ["mus_menu", "mus_prologo", "mus_carregamento", "mus_fase", "mus_boss", "amb_chuva", "amb_fogo"];
    for (var _j = 0; _j < array_length(_ms); _j++)
    {
        var _arq2 = _ms[_j] + ".ogg";
        try { if (file_exists(_arq2)) global.streams[$ _ms[_j]] = audio_create_stream(_arq2); }
        catch (_erro) { show_debug_message("Música não carregada: " + _arq2); }
    }
    global.musica_nome = "";
    global.musica_inst = -1;
    global.musica_saindo = [];           // instâncias diminuindo até parar
    global.musica_alvo = 0;
    global.ambientes = {};               // nome -> { inst, alvo }
    global.audio_pausa = false;
}

// O efeito deste ambiente pode tocar na cena atual?
function som_permitido(_amb)
{
    if (!variable_global_exists("audio_cena")) return true;
    switch (_amb)
    {
        case "transicao": return true;
        case "titulo":    return global.audio_cena == "titulo";
        case "cutscene":  return global.audio_cena == "cutscene";
        case "ui":        return global.audio_cena == "fase";
        case "fase":      return global.audio_cena == "fase";
    }
    return false;
}

// Troca a cena do áudio: os efeitos que não pertencem a ela param (fade curto)
// e os ambientes (chuva, fogo) só continuam se a cena for a fase.
function audio_cena_definir(_cena)
{
    if (!variable_global_exists("sfx")) return;
    if (global.audio_cena == _cena) return;
    global.audio_cena = _cena;
    for (var _i = array_length(global.sfx_tocando) - 1; _i >= 0; _i--)
    {
        var _t = global.sfx_tocando[_i];
        if (som_permitido(_t.amb)) continue;
        if (audio_is_playing(_t.inst))
        {
            audio_sound_gain(_t.inst, 0, 200);
            array_push(global.sfx_saindo, _t.inst);
        }
        array_delete(global.sfx_tocando, _i, 1);
    }
    if (_cena != "fase") ambientes_parar();
}

// Toca um efeito. _var_tom muda um pouco o tom a cada vez (não fica repetitivo)
function som(_nome, _vol = 1, _var_tom = 0.05)
{
    if (!variable_global_exists("sfx")) return -1;
    var _e = global.sfx[$ _nome];
    if (is_undefined(_e)) return -1;
    if (!som_permitido(_e.amb)) return -1;
    var _g = _vol * global.cfg_vol_efeitos;
    if (_g <= 0.01) return -1;
    var _s = _e.s[_e.prox];
    _e.prox = (_e.prox + 1) mod array_length(_e.s);
    var _inst = audio_play_sound(_s, 5, false, _g, 0, 1 + random_range(-_var_tom, _var_tom));
    array_push(global.sfx_tocando, { inst: _inst, amb: _e.amb });
    return _inst;
}

// Efeito com volume pela distância até o centro da tela
function som_em(_nome, _x, _y, _vol = 1, _var_tom = 0.05)
{
    var _cx = global.cam_x + CAMERA_ALTURA * global.tela_aspecto / 2;
    var _d = abs(_x - _cx);
    var _a = clamp(1 - (_d - 300) / 700, 0, 1);
    if (_a <= 0.02) return -1;
    return som(_nome, _vol * _a, _var_tom);
}

// Um entre vários: som_var("hit", 3) toca hit_1..3
function som_var(_base, _qtd, _vol = 1)
{
    return som(_base + "_" + string(irandom_range(1, _qtd)), _vol);
}

// ---------------------------------------------------------------------
// MÚSICA (troca com fade)
// ---------------------------------------------------------------------
function musica(_nome, _fade_ms = 1500)
{
    if (!variable_global_exists("streams")) return;
    if (global.musica_nome == _nome) return;
    if (global.musica_inst != -1 and audio_is_playing(global.musica_inst))
    {
        audio_sound_gain(global.musica_inst, 0, _fade_ms);
        array_push(global.musica_saindo, global.musica_inst);
    }
    global.musica_inst = -1;
    global.musica_nome = _nome;
    if (_nome == "") return;
    var _s = global.streams[$ _nome];
    if (is_undefined(_s)) return;
    global.musica_inst = audio_play_sound(_s, 10, true, 0);
    global.musica_alvo = musica_ganho();
    audio_sound_gain(global.musica_inst, global.musica_alvo, _fade_ms);
}

function musica_ganho()
{
    return global.cfg_vol_musica * (global.audio_pausa ? 0.35 : 1);
}

// Sons de ambiente em loop (chuva, fogo): o volume vai até o alvo aos poucos.
// Só tocam com a fase rodando: no carregamento, na cutscene e no menu ficam mudos.
function ambiente(_nome, _alvo)
{
    if (!variable_global_exists("streams")) return;
    if (global.audio_cena != "fase" or instance_exists(obj_loading)) _alvo = 0;
    var _a = global.ambientes[$ _nome];
    if (is_undefined(_a))
    {
        if (_alvo <= 0.01) return;
        var _s = global.streams[$ _nome];
        if (is_undefined(_s)) return;
        _a = { inst: audio_play_sound(_s, 8, true, 0), alvo: _alvo, atual: 0 };
        global.ambientes[$ _nome] = _a;
    }
    _a.alvo = _alvo;
}

// Chamado 1x por quadro pelo obj_sistema
function audio_atualizar()
{
    if (!variable_global_exists("streams")) return;
    // música: segue o volume das opções (e abaixa na pausa)
    if (global.musica_inst != -1 and audio_is_playing(global.musica_inst))
    {
        var _g = musica_ganho();
        if (abs(global.musica_alvo - _g) > 0.01)
        {
            global.musica_alvo = _g;
            audio_sound_gain(global.musica_inst, _g, 400);
        }
    }
    for (var _i = array_length(global.musica_saindo) - 1; _i >= 0; _i--)
    {
        var _m = global.musica_saindo[_i];
        if (!audio_is_playing(_m) or audio_sound_get_gain(_m) <= 0.01)
        {
            audio_stop_sound(_m);
            array_delete(global.musica_saindo, _i, 1);
        }
    }
    // efeitos: limpa os que terminaram e para os de outra cena
    for (var _k = array_length(global.sfx_tocando) - 1; _k >= 0; _k--)
    {
        if (!audio_is_playing(global.sfx_tocando[_k].inst)) array_delete(global.sfx_tocando, _k, 1);
    }
    for (var _k2 = array_length(global.sfx_saindo) - 1; _k2 >= 0; _k2--)
    {
        var _sx = global.sfx_saindo[_k2];
        if (!audio_is_playing(_sx) or audio_sound_get_gain(_sx) <= 0.01)
        {
            audio_stop_sound(_sx);
            array_delete(global.sfx_saindo, _k2, 1);
        }
    }
    // ambientes
    var _nomes = variable_struct_get_names(global.ambientes);
    for (var _j = 0; _j < array_length(_nomes); _j++)
    {
        var _a = global.ambientes[$ _nomes[_j]];
        if (global.audio_cena != "fase" or instance_exists(obj_loading)) _a.alvo = 0;
        var _alvo = _a.alvo * global.cfg_vol_efeitos * (global.audio_pausa ? 0.4 : 1);
        _a.atual = lerp(_a.atual, _alvo, 0.05);
        audio_sound_gain(_a.inst, _a.atual, 0);
        if (_a.alvo <= 0.01 and _a.atual <= 0.01)
        {
            audio_stop_sound(_a.inst);
            variable_struct_remove(global.ambientes, _nomes[_j]);
        }
    }
}

// Para os ambientes (troca de sala / de cena)
function ambientes_parar()
{
    if (!variable_global_exists("streams")) return;
    var _nomes = variable_struct_get_names(global.ambientes);
    for (var _j = 0; _j < array_length(_nomes); _j++) global.ambientes[$ _nomes[_j]].alvo = 0;
}
