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
    // v1.20: câmera que desce nas pontes e câmera de combate
    global.cam_baixo = 0;
    global.cam_baixo_alvo = 0;
    global.cam_combate = 0;
    global.cam_foco_x = 0;
    global.cam_soco = 0;
    global.fala_espera = 0;
    ambientes_parar();
    // trilhas: menu inicial / fase. Vindo de uma tela de carregamento, a trilha
    // de carregamento continua e a da fase só começa quando a tela clareia.
    if (room == rm_menu)
    {
        audio_cena_definir("titulo");
        // durante o vídeo do estúdio (abertura) a trilha do menu espera: o vídeo tem som próprio
        if (!(variable_global_exists("video_intro_ativo") and global.video_intro_ativo)) musica("bgm_main_menu");
        return;
    }
    if (!instance_exists(obj_loading)) { audio_cena_definir("fase"); musica(musica_fase()); }

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

    // Fase 1: o CENÁRIO desenhado por código (casas, igreja, torre, ponte...)
    // no lugar da pintura de fundo. A camada de tiles "fundo" (a pintura)
    // fica escondida. "longe" (céu e montanhas) atrás do clima de guerra
    // (397); "perto" (a vila com fogo, fumaça e janelas) na frente dele.
    if (room == Room1 and !instance_exists(obj_vila) and cenario_carregar())
    {
        var _lf = layer_get_id("fundo");
        if (_lf != -1) layer_set_visible(_lf, false);
        var _longe = instance_create_depth(0, 0, 405, obj_vila);
        _longe.camada = "longe";
        instance_create_depth(0, 0, 396, obj_vila);
    }

    // Fase 2: cenário de fundo que preenche toda a tela
    if (room == Room2 and !instance_exists(obj_cenario))
        instance_create_depth(0, 0, 450, obj_cenario);

    // clima de guerra: flechas incendiárias, catapultas e brasas (fase 1),
    // cinzas caindo (fase 2)
    if ((room == Room1 or room == Room2) and !instance_exists(obj_guerra))
        instance_create_depth(0, 0, 397, obj_guerra);

    // abismos mortais e plataformas (Castlevania), na frente do chão e atrás dos personagens
    if ((room == Room1 or room == Room2) and !instance_exists(obj_terreno))
        instance_create_depth(0, 0, 280, obj_terreno);
}

// Tamanho da visão em pixels do mundo
function camera_tamanho()
{
    var _h = min(room_height, CAMERA_ALTURA / max(0.5, global.cam_zoom_atual + global.cam_soco));     // v1.20: + o soco de zoom
    var _w = min(room_width, _h * global.tela_aspecto);
    return [_w, _h];
}

// Chamado no End Step do jogador, DEPOIS do movimento (sem atraso de 1 quadro)
function camera_atualizar(_alvo)
{
    if (!view_enabled or view_camera[0] == -1 or !instance_exists(_alvo)) return;
    var _cam = view_camera[0];

    // v1.20: CÂMERA DE COMBATE — com inimigo por perto ela fecha um pouco e puxa o
    // enquadramento para o duelo; cada pancada dá um "soco" de zoom (camera_soco)
    var _perto = 0;
    var _soma_dx = 0;
    if (!global.cam_snap)
    {
        var _ax = _alvo.x, _ay = _alvo.y;
        with (obj_inimigo_base)
        {
            if (morrendo) continue;
            var _ddx = x - _ax;
            if (abs(_ddx) < 300 and abs(y - _ay) < 170) { _perto += 1; _soma_dx += _ddx; }
        }
    }
    else
    {
        global.cam_combate = 0;
        global.cam_foco_x = 0;
        global.cam_soco = 0;
    }
    global.cam_combate = lerp_dt(global.cam_combate, (_perto > 0) ? 1 : 0, 0.035);
    global.cam_foco_x = lerp_dt(global.cam_foco_x, clamp(_soma_dx / max(1, _perto) * 0.3, -64, 64), 0.045);
    global.cam_soco *= power(0.84, global.dt_real);
    if (global.cam_soco < 0.002) global.cam_soco = 0;
    var _zoom_alvo = global.camera_zoom * (1 + 0.07 * global.cam_combate);
    global.cam_zoom_atual = global.cam_snap ? _zoom_alvo : lerp_dt(global.cam_zoom_atual, _zoom_alvo, 0.12);
    var _tam = camera_tamanho();
    var _w = _tam[0];
    var _h = _tam[1];

    // "olhar à frente": a câmera mostra mais do lado para onde o herói corre.
    // Ela desliza devagar (menos que a velocidade da corrida) e só quando ele
    // anda de fato: virar de lado não arremessa a tela 80 px de uma vez, e o
    // herói não parece "teletransportar" para trás ao trocar de direção.
    var _frente = variable_instance_exists(_alvo, "facing") ? _alvo.facing : 1;
    var _vh = variable_instance_exists(_alvo, "velh") ? _alvo.velh : 0;
    if (abs(_vh) > 0.5) global.cam_frente_alvo = sign(_vh) * 28;      // v1.13: 40 -> 28 (a visão ficou menor)
    if (global.cam_snap)
    {
        global.cam_frente_alvo = _frente * 28;
        global.cam_frente = global.cam_frente_alvo;
    }
    else
    {
        var _falta = global.cam_frente_alvo - global.cam_frente;
        var _passo = min(abs(_falta) * 0.05 + 0.05, 0.85) * global.dt_real;
        global.cam_frente += clamp(_falta, -_passo, _passo);
    }
    var _tx = clamp(_alvo.x + global.cam_frente + global.cam_foco_x - _w / 2, 0, room_width - _w);
    // arena fechada (mini-boss / boss): a câmera fica entre as muralhas
    var _lo = max(0, global.cam_lim_esq);
    var _hi = min(room_width, global.cam_lim_dir);
    if (_hi - _lo <= _w) _tx = clamp((_lo + _hi) / 2 - _w / 2, 0, room_width - _w);
    else _tx = clamp(_tx, _lo, _hi - _w);
    var _ty = clamp(_alvo.y - _h * 0.64, 0, room_height - _h);
    // v1.20: sobre as pontes que desabam a câmera desce e mostra o abismo
    global.cam_baixo = global.cam_snap ? global.cam_baixo_alvo : lerp_dt(global.cam_baixo, global.cam_baixo_alvo, 0.05);
    _ty += global.cam_baixo;

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

    // "chute" do golpe (camera_empurrar): fica parado no hit-stop e volta depois
    _sx += global.cam_chute_x;
    _sy += global.cam_chute_y;
    var _amort = power(0.78, global.dt);
    global.cam_chute_x *= _amort;
    global.cam_chute_y *= _amort;
    if (abs(global.cam_chute_x) < 0.05) global.cam_chute_x = 0;
    if (abs(global.cam_chute_y) < 0.05) global.cam_chute_y = 0;

    var _vx = clamp(global.cam_x + _sx, 0, room_width - _w);
    var _vy = clamp(global.cam_y + _sy, 0, room_height - _h + global.cam_baixo);
    // arredonda para o pixel da TELA (não do mundo): a imagem é ampliada ~2-3x,
    // e arredondar no mundo fazia o cenário andar aos saltos de 2-3 px
    var _k = 1;
    if (surface_exists(application_surface)) _k = max(1, surface_get_height(application_surface) / _h);
    camera_set_view_size(_cam, _w, _h);
    camera_set_view_pos(_cam, round(_vx * _k) / _k, round(_vy * _k) / _k);
}
