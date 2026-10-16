// =====================================================================
//  obj_inimigo_02 — IA do arqueiro (Step)
//  Estados: escondido/portal/subindo (surgir), parado, fugir, atirar,
//           (atordoado = sofrendo dano), morrendo
// =====================================================================
var _dt = global.dt;

// ===== AINDA ESCONDIDO: surge do chão por um portal de magia (scr_dano) =====
if (inimigo_portal_step(_dt)) exit;

// ===== MORTE: o corpo fica no mapa =====
if (morrendo)
{
    inimigo_corpo_step(_dt);
    exit;
}
if (y > room_height + 300) { instance_destroy(); exit; }

// ===== TEMPORIZADORES =====
if (tempo_invencivel > 0) tempo_invencivel = max(0, tempo_invencivel - _dt);
if (recarga > 0) recarga -= _dt;
if (barra_tempo > 0) barra_tempo -= _dt;
if (flash_dano > 0) flash_dano -= _dt;
if (alerta_fx > 0) alerta_fx -= _dt;
if (libertou_fx > 0) libertou_fx -= _dt;

var _no_chao = place_meeting(x, y + 1, obj_chao);

// ===== PRESO NO FINALIZADOR DE TWILIGHT =====
if (inimigo_finalizador_step())
{
    if (sprite_index != spr_ia_dano) { sprite_index = spr_ia_dano; image_index = 0; }
    image_speed = 0.5;
    atordoado = max(atordoado, 2);
    if (!_no_chao) velv += grav_ia * _dt; else if (velv > 0) velv = 0;
    image_xscale = escala;
    image_yscale = escala;
    exit;
}

// ===== JOGADOR =====
var _p = instance_find(obj_player, 0);
var _tem_alvo = (_p != noone);
if (_tem_alvo and _p.morto) _tem_alvo = false;
var _dx = 0;
var _dy = 0;
if (_tem_alvo) { _dx = _p.x - x; _dy = _p.y - y; }
var _adx = abs(_dx);

// ===== CAMPO DE VISÃO = a mesma área da câmera do jogador =====
var _ve = false;
if (_tem_alvo and view_enabled and view_camera[0] != -1)
{
    var _cam = view_camera[0];
    var _cx1 = camera_get_view_x(_cam);
    var _cy1 = camera_get_view_y(_cam);
    var _cx2 = _cx1 + camera_get_view_width(_cam);
    var _cy2 = _cy1 + camera_get_view_height(_cam);
    _ve = (x >= _cx1 and x <= _cx2 and y - 20 >= _cy1 and y - 60 <= _cy2);
}
if (_ve and !viu) { viu = true; alerta_fx = 40; }

// ===== REGRA DE ATORDOAMENTO =====
if (_tem_alvo) inimigo_regra_atordoamento(_p);
var _estava_atordoado = (atordoado > 0);

if (inimigo_atordoamento_step(_dt))
{
    // sofrendo dano: não foge e não atira
    if (_no_chao) velh = 0;
    if (sprite_index != spr_ia_dano) { sprite_index = spr_ia_dano; image_index = 0; }
    image_speed = 1.4;
}
else
{
    if (_estava_atordoado)
    {
        estado_ia = (_adx < distancia_fuga) ? "fugir" : "parado";
        image_speed = 1;
    }

    switch (estado_ia)
    {
        // --------------------------------------------------------------
        case "parado":
            velh = 0;
            if (sprite_index != spr_ia_dano) trocar_sprite(spr_ia_parado, 1);
            // longe demais: volta para a distância de tiro
            if (_tem_alvo and viu and _adx > distancia_max and _adx < 900 and abs(_dy) < 200)
            {
                estado_ia = "aproximar";
                break;
            }
            if (_ve)
            {
                if (_dx != 0) dir = sign(_dx);
                var _lado_fuga = (_dx >= 0) ? -1 : 1;
                if (_adx < distancia_fuga and pode_fugir(_lado_fuga))
                {
                    estado_ia = "fugir";
                }
                else if (recarga <= 0 and abs(_dy) < 160)
                {
                    // só atira de longe (ou se estiver encurralado)
                    estado_ia = "atirar";
                    flecha_solta = false;
                    fala_aleatoria(id, falas_arqueiro(), make_color_rgb(70, 40, 100), 0.22);
                    sprite_index = spr_ia_ataque;
                    image_index = 0;
                    image_speed = 1.8;
                }
            }
        break;

        // --------------------------------------------------------------
        case "fugir":
            var _fuga = (_dx >= 0) ? -1 : 1;           // para longe do jogador
            if (!_tem_alvo or _adx >= distancia_segura or !pode_fugir(_fuga))
            {
                if (_tem_alvo and !pode_fugir(_fuga)) recarga = min(recarga, 25);   // encurralado: atira logo
                estado_ia = "parado";
                velh = 0;
                if (_tem_alvo and _dx != 0) dir = sign(_dx);
            }
            else
            {
                dir = _fuga;
                velh = _fuga * vel_fuga;
                trocar_sprite(spr_ia_correr, 1.3);
            }
        break;

        // --------------------------------------------------------------
        case "aproximar":
            // corre até a distância ideal de tiro (não chega perto demais)
            if (!_tem_alvo or _adx <= distancia_ideal or abs(_dy) >= 200)
            {
                estado_ia = "parado";
                velh = 0;
                recarga = min(recarga, 30);
                break;
            }
            dir = sign(_dx);
            if (place_meeting(x + dir * 12, y - 2, obj_chao) or !pode_andar(dir)) { estado_ia = "parado"; velh = 0; break; }
            velh = dir * vel_aproximar;              // sempre correndo
            trocar_sprite(spr_ia_correr, 1.3);
        break;

        // --------------------------------------------------------------
        case "atirar":
            velh = 0;
            image_speed = 1.8;
            // quadro 5: a corda está toda puxada -> solta a flecha
            if (!flecha_solta and image_index >= 5)
            {
                flecha_solta = true;
                var _bx = x + dir * 17 * escala;
                var _by = y - 21 * escala;
                var _f = instance_create_depth(_bx, _by, depth - 1, obj_flecha);
                som_em("sfx_flecha", x, y, 0.7);
                _f.dano = dano_flecha;
                _f.escala = escala * 0.85;
                var _tx = _bx + dir * 300;
                var _ty = _by;
                if (_tem_alvo) { _tx = _p.x; _ty = _p.y - 34; }
                // mira um pouco acima para compensar a leve queda da flecha
                var _dist = point_distance(_bx, _by, _tx, _ty);
                var _tempo = _dist / velocidade_flecha;
                _ty -= 0.5 * 0.05 * _tempo * _tempo;
                var _ang = point_direction(_bx, _by, _tx, _ty);
                _f.vx = lengthdir_x(velocidade_flecha, _ang);
                _f.vy = lengthdir_y(velocidade_flecha, _ang);
                if (view_camera[0] != -1) _f.alcance = camera_get_view_width(view_camera[0]) * 1.1;
            }
        break;
    }
}

// ===== EMPURRÃO =====
if (empurrao != 0)
{
    velh += empurrao;
    empurrao = lerp_dt(empurrao, 0, 0.16);
    if (abs(empurrao) < 0.2) empurrao = 0;
}

// ===== GRAVIDADE (a física/colisão está no End Step do obj_entidade) =====
if (!_no_chao) velv += grav_ia * _dt;
else if (velv > 0) velv = 0;
image_xscale = escala;
image_yscale = escala;
