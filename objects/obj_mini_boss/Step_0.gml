var _dt = global.dt;
if (morrendo) { inimigo_corpo_step(_dt); exit; }

if (tempo_invencivel > 0) tempo_invencivel = max(0, tempo_invencivel - _dt);
if (recarga > 0) recarga -= _dt;
if (barra_tempo > 0) barra_tempo -= _dt;
if (flash_dano > 0) flash_dano -= _dt;
if (titulo_tempo > 0) titulo_tempo -= _dt;
if (onda_fx > 0) onda_fx -= _dt;
if (libertou_fx > 0) libertou_fx -= _dt;
t_estado += _dt;
hud_alpha = lerp_dt(hud_alpha, acordado ? 1 : 0, 0.08);
image_xscale = escala;
image_yscale = escala;
var _no_chao = place_meeting(x, y + 1, obj_chao);

var _p = instance_find(obj_player, 0);
var _tem = (_p != noone and !_p.morto);
var _dx = _tem ? _p.x - x : 0;
var _dy = _tem ? _p.y - y : 0;
var _adx = abs(_dx);

// ----- preso no finalizador -----
if (inimigo_finalizador_step())
{
    trocar_sprite(spr_ia_parado, 0.15);
    if (!_no_chao) velv += grav_ia * _dt; else if (velv > 0) velv = 0;
    exit;
}

// ----- atordoado (aparado ou exausto) -----
var _estava = (atordoado > 0);
if (inimigo_atordoamento_step(_dt))
{
    if (_no_chao) velh = 0;
    trocar_sprite(spr_ia_parado, 0.15);
    if (!_no_chao) velv += grav_ia * _dt; else if (velv > 0) velv = 0;
    if (empurrao != 0) { velh += empurrao; empurrao = lerp_dt(empurrao, 0, 0.16); if (abs(empurrao) < 0.2) empurrao = 0; }
    exit;
}
if (_estava and estado_ia != "dormindo")
{
    if (estado_ia == "exausto")
    {
        // não foi finalizado: levanta enfurecido
        enfurecido = true;
        som("sfx_rugido", 0.9, 0);
        fala_dizer(id, "Agora você vai ver!", make_color_rgb(150, 20, 20), true);
        global.camera_impact = max(global.camera_impact, 10);
    }
    mudar("perseguir");
    recarga = 20;
}

// falas de vez em quando
if (acordado)
{
    fala_t -= _dt;
    if (fala_t <= 0) { fala_t = irandom_range(420, 720); fala_dizer(id, choose("Sua cabeça é minha!", "Pela maldição de Vallack!", "Fique parado!", "Hahaha!"), make_color_rgb(120, 20, 20)); }
}

var _vel = enfurecido ? 1.9 : 1.35;
switch (estado_ia)
{
    case "dormindo":
        trocar_sprite(spr_ia_parado, 0.5);
        velh = 0;
        if (_tem and _p.x > arena_x1 + 50 and _p.x < arena_x2 and abs(_dy) < 160) despertar();
    break;

    case "apresentacao":
        velh = 0;
        trocar_sprite(spr_ia_parado, 1.6);
        if (_tem and _dx != 0) dir = sign(_dx);
        if (t_estado >= 100) { mudar("perseguir"); recarga = 30; }
    break;

    case "perseguir":
        if (!_tem) { velh = 0; trocar_sprite(spr_ia_parado, 0.6); break; }
        if (_dx != 0) dir = sign(_dx);
        if (acoes >= 3) { acoes = 0; mudar("cansado"); velh = 0; break; }
        if (recarga <= 0 and _no_chao)
        {
            if (_adx <= 82 and abs(_dy) < 70)
            {
                mudar("atacar");
                contador_ataques += 1;
                ataque_bloqueavel = (contador_ataques mod 2 != 0);       // um sim, um não: quebra-guarda
                velh = 0;
                sprite_index = spr_ia_ataque;
                image_index = 0;
                image_speed = enfurecido ? 0.36 : 0.28;
                if (random(1) < 0.35) fala_dizer(id, choose("Toma!", "Morra!", "Hrraaa!"), make_color_rgb(120, 20, 20));
                break;
            }
            if (_adx >= 130 and _adx <= 340 and random(1) < 0.6)
            {
                mudar("salto_preparo");
                velh = 0;
                sprite_index = spr_ia_pular;
                image_index = 0;
                image_speed = 0.8;
                break;
            }
            if (_adx > 260)
            {
                mudar("investida_preparo");
                velh = 0;
                investida_dir = dir;
                som("sfx_rugido", 0.5, 0.1);
                break;
            }
        }
        if (_adx > 64) { velh = dir * _vel; trocar_sprite(spr_ia_andar, 1.1); }
        else { velh = 0; trocar_sprite(spr_ia_parado, 0.8); }
    break;

    case "atacar":
        velh = 0;
        var _fa = floor(image_index);
        if (_fa == 3 and t_estado < 60) velh = dir * 1.5;     // dá um passo no golpe
        if (!som_golpe_tocou and _fa >= 3) { som_golpe_tocou = true; som("atk_pesado", 0.75, 0.1); }
        if (!golpe_dado and _fa >= 4 and _fa <= 6 and _tem)
        {
            var _x1 = x + dir * 8;
            var _x2 = x + dir * 92;
            if (rectangle_in_rectangle(min(_x1, _x2), y - 96, max(_x1, _x2), y - 4, _p.bbox_left, _p.bbox_top, _p.bbox_right, _p.bbox_bottom))
            {
                golpe_dado = true;
                with (_p) levar_dano(other.dano_corte, other.x, other.ataque_bloqueavel, 7, other.id);
            }
            if (_fa == 5 and t_estado > 1) { global.camera_impact = max(global.camera_impact, 4); }
        }
    break;

    case "salto_preparo":
        velh = 0;
        if (image_index >= 2)
        {
            if (_tem and _dx != 0) dir = sign(_dx);
            var _alvo_x = _tem ? _p.x : x + dir * 200;
            _alvo_x = arena_limitar_x(_alvo_x, 40);
            var _tempo_ar = 2 * 9 / grav_ia;
            velh = clamp((_alvo_x - x) / _tempo_ar, -5.5, 5.5);
            velv = -9;
            mudar("salto_ar");
            image_index = 4;
            som("sfx_pulo", 0.9, 0);
        }
    break;

    case "salto_ar":
        image_speed = 0.6;
        if (image_index >= 5.5) image_index = 5;
        if (_no_chao and velv >= 0 and t_estado > 4)
        {
            velh = 0;
            mudar("salto_pouso");
            image_index = 6;
            image_speed = 1;
            // ONDA DE CHOQUE: pule ou role para escapar
            global.camera_impact = max(global.camera_impact, 16);
            global.terremoto = max(global.terremoto, 20);
            onda_fx = 30;
            fx_em("onda_chao", x, y, 1.1);
            fx_em("poeira", x, y, 1.6);
            fx_em("rachaduras", x, y, 1.1);
            som("sfx_impacto", 0.9, 0.05);
            var _lst = [];
            if (_tem and _p.y >= y - 30) armadilha_area(x - 105, y - 40, x + 105, y + 4, dano_salto / max(0.1, dif_dano_inimigo()), 0, _lst, 7);
            acoes += 1;
        }
    break;

    case "salto_pouso":
        velh = 0;
    break;

    case "investida_preparo":
        velh = 0;
        trocar_sprite(spr_ia_parado, 2);
        if (random(1) < 0.4 * _dt) fx_em("poeira", x - dir * 14, y, 0.4);
        if (t_estado >= 34)
        {
            mudar("investida");
            sprite_index = spr_ia_correr;
            image_index = 0;
            image_speed = 1.7;
        }
    break;

    case "investida":
        dir = investida_dir;
        velh = dir * (enfurecido ? 6 : 5.2);
        if (random(1) < 0.5 * _dt) fx_em("poeira", x - dir * 18, y, 0.35);
        if (!golpe_dado and _tem and rectangle_in_rectangle(x - 26, y - 90, x + 26, y, _p.bbox_left, _p.bbox_top, _p.bbox_right, _p.bbox_bottom))
        {
            golpe_dado = true;
            var _vida_antes = _p.vida;
            var _bloq = _p.bloqueando;
            with (_p) levar_dano(other.dano_investida, other.x, true, 9, other.id);
            if (_bloq and _p.vida == _vida_antes)
            {
                // bateu no escudo: tropeça e cansa
                velh = 0;
                empurrao = -dir * 3;
                acoes = 3;
                mudar("perseguir");
                break;
            }
        }
        // bateu na muralha / parede: fica tonto
        if (place_meeting(x + dir * 6, y - 4, obj_chao) or t_estado > 75)
        {
            velh = 0;
            if (t_estado <= 75)
            {
                global.camera_impact = max(global.camera_impact, 12);
                som("dest_pedra", 0.8, 0.05);
                fx_em("poeira", x + dir * 20, y - 30, 1);
                inimigo_atordoar(90, true);
            }
            acoes += 1;
            mudar("perseguir");
            recarga = 40;
        }
    break;

    case "cansado":
        velh = 0;
        trocar_sprite(spr_ia_parado, 0.35);
        if (t_estado >= (enfurecido ? 55 : 85)) { mudar("perseguir"); recarga = 10; }
    break;
}

// empurrão
if (empurrao != 0)
{
    velh += empurrao;
    empurrao = lerp_dt(empurrao, 0, 0.16);
    if (abs(empurrao) < 0.2) empurrao = 0;
}
// não sai da arena
if (arena_fechada) x = clamp(x, arena_x1 + 20, arena_x2 - 20);
if (!_no_chao) velv += grav_ia * _dt;
else if (velv > 0) velv = 0;
