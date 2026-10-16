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
vida_max = round(30 * dif_vida_inimigo());
vida = vida_max;
vida_atraso = vida;
dano_flecha = max(1, round(5 * dif_dano_inimigo()));
recarga = irandom_range(40, 140);
recarga_max = 300;              // 5 s para atirar de novo
velocidade_flecha = 8;

// ===== IA =====
estado_ia = "parado";
distancia_fuga = 170;           // mais perto que isso: foge
distancia_segura = 320;         // depois disso: para e volta a mirar
vel_fuga = 2.7;
distancia_ideal = 300;          // volta a se aproximar até esta distância
distancia_max = 430;            // mais longe que isso: se aproxima
vel_aproximar = 2.2;            // corre (não anda mais)
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
    empurrao = _dir * _forca * 0.5;
    inimigo_atordoar(26);
    if (vida <= 0) { inimigo_morrer(_dir); return; }
    if (atordoado > 0) { sprite_index = spr_ia_dano; image_index = 0; image_speed = 1.4; }
};
