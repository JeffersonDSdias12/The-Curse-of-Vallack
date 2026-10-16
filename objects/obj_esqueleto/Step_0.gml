// =====================================================================
//  obj_esqueleto — Step
//  Pilha de ossos ("caido") e "erguendo" ficam aqui; o resto é a IA da
//  besta (obj_inimigo_01) com os quadros e a área do golpe do esqueleto.
// =====================================================================
var _dt = global.dt;

if (ativo and !morrendo and (estado_ia == "caido" or estado_ia == "erguendo"))
{
    if (tempo_invencivel > 0) tempo_invencivel = max(0, tempo_invencivel - _dt);
    if (flash_dano > 0) flash_dano -= _dt;
    if (alerta_fx > 0) alerta_fx -= _dt;
    atordoado = 0;
    finalizavel = false;
    barra_tempo = 0;
    velh = lerp_dt(velh, 0, 0.15);
    if (abs(velh) < 0.05) velh = 0;
    var _nc = place_meeting(x, y + 1, obj_chao);
    if (!_nc) velv += grav_ia * _dt;
    else if (velv > 0) velv = 0;
    if (y > room_height + 300) { instance_destroy(); exit; }

    sprite_index = spr_morrer;
    image_speed = 0;
    var _n = sprite_get_number(spr_morrer);
    if (estado_ia == "caido")
    {
        caido_t += _dt;
        image_index = min(_n - 1, caido_t * 0.16);          // desmonta até virar a pilha
        // os ossos tremem antes de se juntar de novo
        if (caido_t >= caido_dur - 50 and floor((caido_t - _dt) / 12) != floor(caido_t / 12)) som_em("osso_chocalho", x, y, 0.45);
        if (caido_t >= caido_dur)
        {
            estado_ia = "erguendo";
            erguer_t = 0;
            som_em("osso_ergue", x, y, 0.85);
            fala_aleatoria(id, falas_esqueleto_ergue(), cor_fala, 1);
        }
    }
    else
    {
        erguer_t += _dt;
        image_index = max(0, (_n - 1) - erguer_t * 0.2);    // a animação de desmontar ao contrário
        if (erguer_t >= (_n - 1) / 0.2)
        {
            // de pé de novo, com metade da vida (não se levanta uma segunda vez)
            estado_ia = "perseguir";
            reerguido = true;
            pode_lancar = true;
            vida = max(1, round(vida_max * 0.5));
            vida_atraso = vida;
            barra_tempo = 120;
            imune_atordoar = 50;
            recarga = 18;
            alerta_fx = 40;
            alertado = true;
            andar_t = 66;
            sprite_index = spr_ia_parado;
            image_index = 0;
            image_speed = 1;
            global.camera_impact = max(global.camera_impact, 3);
            repeat (global.cfg_qualidade == 0 ? 2 : 5)
            {
                var _f = instance_create_depth(x + random_range(-12, 12), y - random_range(10, 50), -100, obj_fagulha);
                _f.cor = make_color_rgb(200, 70, 255);
            }
        }
    }
    exit;
}

event_inherited();

// a animação de dano termina com o esqueleto desmontado: atordoado, ela
// fica em loop só nos quadros 0-7
if (sprite_index == spr_esqueleto_dano and image_index >= 7.9) image_index = 1;

// recém-erguido: ainda cambaleia, ANDANDO (mais devagar) antes de voltar a correr
if (andar_t > 0)
{
    andar_t -= _dt;
    if (sprite_index == spr_ia_correr and estado_ia == "perseguir")
    {
        sprite_index = spr_ia_andar;
        andar_img = (andar_img + 0.17 * _dt) mod sprite_get_number(spr_ia_andar);
        image_index = andar_img;
        image_speed = 0;
        velh *= 0.45;
    }
}
