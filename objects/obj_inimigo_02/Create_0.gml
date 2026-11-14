// =====================================================================
//  obj_inimigo_02 — arqueiro esqueleto
//  * só atira de longe e só quando está no campo de visão (a câmera)
//  * foge quando o jogador chega perto
//  * flecha: 5 de dano (no MÉDIO), uma a cada 5 segundos
//  * surge do chão por um portal de magia, como a besta
// =====================================================================
event_inherited();       // obj_inimigo_base

// A instância foi aumentada na sala de forma desigual (1,8 x 1,55), o que
// distorcia a arte. Usamos a ALTURA escolhida, de forma uniforme.
escala = abs(image_yscale);
if (escala < 0.5) escala = 1.55;
image_xscale = escala;          // a máscara acompanha o tamanho
image_yscale = escala;
mask_index = spr_mascara_arqueiro;
dir = -1;                       // as sprites olham para a direita

// ===== COMBATE (ajustado pela dificuldade) =====
inimigo_status(30);
dano_flecha = inimigo_dano(5);
recarga = irandom_range(90, 200);
recarga_max = round(420 * dif_recarga_inimigo());    // v1.12: 7 s no MÉDIO
cor_ia = c_white;               // o alquimista (filho) usa verde
velocidade_flecha = 8;

// ===== IA =====
estado_ia = "parado";
distancia_fuga = 170;           // mais perto que isso: foge
distancia_segura = 320;         // depois disso: para e volta a mirar
vel_fuga = 2.7 * dif_velocidade();
distancia_ideal = 300;          // volta a se aproximar até esta distância
distancia_max = 430;            // mais longe que isso: se aproxima
vel_aproximar = 2.2 * dif_velocidade();            // corre (não anda mais)
grav_ia = 0.4;
flecha_solta = false;
alerta_fx = 0;
viu = false;

// ===== SURGIR DO CHÃO (portal de magia, como a besta; scr_dano) =====
inimigo_portal_iniciar();

// ===== SPRITES =====
spr_ia_parado = spr_inimigo02_parado;
spr_ia_andar  = spr_inimigo02_correndo;   // o arqueiro sempre corre
spr_ia_correr = spr_inimigo02_correndo;
spr_ia_ataque = spr_inimigo02_atacando;
spr_ia_dano   = spr_inimigo02_sofrendo_dano;
spr_morrer    = spr_inimigo02_morrendo;
sprite_index = spr_ia_parado;
image_index = irandom(sprite_get_number(spr_ia_parado) - 1);
image_speed = 1;

trocar_sprite = function(_spr, _vel)
{
    if (sprite_index != _spr)
    {
        sprite_index = _spr;
        image_index = 0;
    }
    image_speed = _vel;
};

// Há espaço para fugir nessa direção? (parede ou borda do mapa = encurralado)
pode_fugir = function(_d)
{
    var _nx = x + _d * 32;
    if (place_meeting(_nx, y - 2, obj_chao) or _nx < 48 or _nx > room_width - 48) return false;
    if (arena_limitar_x(_nx, 24) != _nx) return false;
    // não foge para trás da barreira do guardião (o jogador não conseguiria alcançá-lo)
    var _b = instance_find(obj_boss_01, 0);
    if (_b != noone and !_b.morrendo and _nx > _b.barreira_x - 24) return false;
    return true;
};

// Pode andar nessa direção sem sair da arena / do mapa?
pode_andar = function(_d)
{
    var _nx = x + _d * 32;
    if (_nx < 48 or _nx > room_width - 48) return false;
    if (arena_limitar_x(_nx, 24) != _nx) return false;
    var _b = instance_find(obj_boss_01, 0);
    if (_b != noone and !_b.morrendo and _nx > _b.barreira_x - 24) return false;
    return true;
};

reagir_dano = function(_dano, _dir, _forca)
{
    empurrao = _dir * _forca * 0.3;          // v1.12: era 0.5 (os golpes jogavam o inimigo longe)
    inimigo_atordoar(26);
    if (vida <= 0) { inimigo_morrer(_dir); return; }
    if (atordoado > 0) { sprite_index = spr_ia_dano; image_index = 0; image_speed = 1.4; }
};

// v1.12: o disparo virou uma função (o alquimista troca a flecha pelo frasco)
disparar = function(_bx, _by, _alvo)
{
    som_em("sfx_flecha", x, y, 0.7);
    var _tx = _bx + dir * 300;
    var _ty = _by;
    if (_alvo != noone) { _tx = _alvo.x; _ty = _alvo.y - 34; }
    // mira um pouco acima para compensar a leve queda da flecha
    var _dist = point_distance(_bx, _by, _tx, _ty);
    var _tempo = _dist / velocidade_flecha;
    _ty -= 0.5 * 0.05 * _tempo * _tempo;
    var _ang = point_direction(_bx, _by, _tx, _ty);
    // v1.13: no DIFÍCIL sai uma 2ª flecha um pouco mais alta; no EXTREMO, 3 em leque
    var _leque = dif_valor([[0], [0], [0, 6], [0, -7, 7]]);
    for (var _k = 0; _k < array_length(_leque); _k++)
    {
        var _f = instance_create_depth(_bx, _by, depth - 1, obj_flecha);
        _f.dano = dano_flecha;
        _f.escala = escala * 0.85;
        _f.vx = lengthdir_x(velocidade_flecha, _ang + _leque[_k]);
        _f.vy = lengthdir_y(velocidade_flecha, _ang + _leque[_k]);
        if (view_camera[0] != -1) _f.alcance = camera_get_view_width(view_camera[0]) * 1.1;
    }
};
