// =====================================================================
//  scr_camera: câmera do jogo controlada por código
//  (segue o jogador com suavização, olha para a frente, treme nos impactos
//   e respeita a proporção real da tela — sem cortar e sem barras)
// =====================================================================

// Chamado no Room Start pelo obj_sistema
function sala_preparar()
{
    global.cam_snap = true;
    global.camera_zoom = 1;
    global.cam_zoom_atual = 1;
    global.hitstop = 0;
    global.lenta_t = 0;
    global.lenta_fator = 1;
    global.cam_lim_esq = 0;
    global.cam_lim_dir = room_width;
    global.fala_espera = 0;
    ambientes_parar();
    // trilhas: menu inicial / fase. Vindo de uma tela de carregamento, a trilha
    // de carregamento continua e a da fase só começa quando a tela clareia.
    if (room == rm_menu) { audio_cena_definir("titulo"); musica("mus_menu"); return; }
    if (!instance_exists(obj_loading)) { audio_cena_definir("fase"); musica("mus_fase"); }

    // voltando do checkpoint: o que ficou para trás não renasce
    sala_limpar_checkpoint();

    view_enabled = true;
    view_visible[0] = true;
    if (view_camera[0] != -1)
    {
        // A câmera do editor seguia o jogador sozinha e brigava com o código.
        camera_set_view_target(view_camera[0], noone);
        camera_set_view_speed(view_camera[0], -1, -1);
        camera_set_view_border(view_camera[0], 0, 0);
    }

    // Fase 1: tempestade (chuva, névoa e relâmpagos)
    if (room == Room1 and !instance_exists(obj_clima))
        instance_create_depth(0, 0, -200, obj_clima);

    // Fase 1: fundo em alta definição (OPÇÕES > FUNDO HD), logo à frente da
    // camada de tiles "fundo" (profundidade 400) e atrás do chão (300)
    if (room == Room1 and global.cfg_fundo_hd and !instance_exists(obj_fundo_hd))
        instance_create_depth(0, 0, 399, obj_fundo_hd);

    // Fase 1: vila em chamas ao fundo (casas queimando, fumaça e aldeões fugindo)
    if (room == Room1 and !instance_exists(obj_vila))
        instance_create_depth(0, 0, 398, obj_vila);

    // Fase 2: cenário de fundo que preenche toda a tela
    if (room == Room2 and !instance_exists(obj_cenario))
        instance_create_depth(0, 0, 450, obj_cenario);
}

// Tamanho da visão em pixels do mundo
function camera_tamanho()
{
    var _h = min(room_height, CAMERA_ALTURA / max(0.5, global.cam_zoom_atual));
    var _w = min(room_width, _h * global.tela_aspecto);
    return [_w, _h];
}

// Chamado no End Step do jogador, DEPOIS do movimento (sem atraso de 1 quadro)
function camera_atualizar(_alvo)
{
    if (!view_enabled or view_camera[0] == -1 or !instance_exists(_alvo)) return;
    var _cam = view_camera[0];

    global.cam_zoom_atual = global.cam_snap ? global.camera_zoom : lerp_dt(global.cam_zoom_atual, global.camera_zoom, 0.12);
    var _tam = camera_tamanho();
    var _w = _tam[0];
    var _h = _tam[1];

    var _frente = variable_instance_exists(_alvo, "facing") ? _alvo.facing : 1;
    var _tx = clamp(_alvo.x + _frente * 40 - _w / 2, 0, room_width - _w);
    // arena fechada (mini-boss / boss): a câmera fica entre as muralhas
    var _lo = max(0, global.cam_lim_esq);
    var _hi = min(room_width, global.cam_lim_dir);
    if (_hi - _lo <= _w) _tx = clamp((_lo + _hi) / 2 - _w / 2, 0, room_width - _w);
    else _tx = clamp(_tx, _lo, _hi - _w);
    var _ty = clamp(_alvo.y - _h * 0.64, 0, room_height - _h);

    if (global.cam_snap)
    {
        global.cam_x = _tx;
        global.cam_y = _ty;
        global.cam_snap = false;
    }
    else
    {
        global.cam_x = lerp_dt(global.cam_x, _tx, 0.12);
        global.cam_y = lerp_dt(global.cam_y, _ty, 0.10);
    }

    // tremor de impacto (desligado na qualidade BAIXA)
    var _sx = 0;
    var _sy = 0;
    if (global.camera_impact > 0 and global.cfg_qualidade > 0)
    {
        var _f = global.camera_impact * (global.cfg_qualidade == 2 ? 0.7 : 0.4);
        _sx = random_range(-_f, _f);
        _sy = random_range(-_f, _f);
    }
    // terremoto (especiais que batem no chão): tremor longo, mais vertical;
    // na qualidade BAIXA ele continua, só que mais fraco
    if (global.terremoto > 0)
    {
        var _qs = [0.35, 0.7, 1];
        var _q = _qs[clamp(global.cfg_qualidade, 0, 2)];
        var _ft = min(global.terremoto, 30) * 0.2 * _q;
        _sx += random_range(-_ft, _ft) * 0.7;
        _sy += random_range(-_ft, _ft) * 1.2;
    }

    var _vx = clamp(global.cam_x + _sx, 0, room_width - _w);
    var _vy = clamp(global.cam_y + _sy, 0, room_height - _h);
    camera_set_view_size(_cam, _w, _h);
    camera_set_view_pos(_cam, round(_vx), round(_vy));
}
