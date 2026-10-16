// =====================================================================
//  obj_inimigo_01 — IA (Step)
//  Estados: escondido/portal/subindo (surgir), parado, perseguir, atacar,
//           pular_preparo, pular_ar, pular_pouso, (atordoado), morrendo
//  O movimento/colisão acontece no End Step do obj_entidade.
// =====================================================================
var _dt = global.dt;

// ===== AINDA ESCONDIDO: surge do chão por um portal de magia (scr_dano) =====
if (inimigo_portal_step(_dt)) exit;

// ===== MORTE: animação spr_inimigo01_morrendo; o corpo fica no mapa =====
if (morrendo)
{
    inimigo_corpo_step(_dt);
    exit;
}

if (y > room_height + 300) { instance_destroy(); exit; }

// ===== TEMPORIZADORES =====
if (tempo_invencivel > 0) tempo_invencivel = max(0, tempo_invencivel - _dt);
if (recarga > 0) recarga -= _dt;
if (recarga_salto > 0) recarga_salto -= _dt;
if (barra_tempo > 0) barra_tempo -= _dt;
if (flash_dano > 0) flash_dano -= _dt;
if (alerta_fx > 0) alerta_fx -= _dt;
if (libertou_fx > 0) libertou_fx -= _dt;
if (escudo_fx > 0) escudo_fx -= _dt;

var _no_chao = place_meeting(x, y + 1, obj_chao);

// ===== PRESO NO FINALIZADOR DE TWILIGHT =====
if (inimigo_finalizador_step())
{
    pulando = false;
    estado_ia = "perseguir";
    if (sprite_index != spr_ia_atordoado) { sprite_index = spr_ia_atordoado; image_index = 0; }
    image_speed = 0.2;
    atordoado = max(atordoado, 2);
    atordoado_anim += _dt;
    if (!_no_chao) velv += grav_ia * _dt; else if (velv > 0) velv = 0;
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
var _dentro_campo = _tem_alvo and (_adx <= campo) and (abs(_dy) <= campo_altura);

// ===== REGRA DE ATORDOAMENTO (SE estou atacando ENTÃO atordoado SENÃO atacam) =====
if (_tem_alvo) inimigo_regra_atordoamento(_p);
var _estava_atordoado = (atordoado > 0);

if (inimigo_atordoamento_step(_dt))
{
    // ----- ATORDOADO: não anda e não ataca (balança, não fica congelado) -----
    if (_no_chao) velh = 0;
    pulando = false;
    if (estado_ia == "pular_ar" or estado_ia == "pular_pouso" or estado_ia == "pular_preparo") estado_ia = "perseguir";
    if (sprite_index != spr_ia_atordoado) { sprite_index = spr_ia_atordoado; image_index = 0; }
    image_speed = vel_atordoado;
}
else
{
    if (_estava_atordoado)
    {
        // o atordoamento acabou: volta à luta quase na hora
        estado_ia = _dentro_campo ? "perseguir" : "parado";
        recarga = min(recarga, irandom_range(4, 18));
        image_speed = 1;
    }

    switch (estado_ia)
    {
        // --------------------------------------------------------------
        case "parado":
            velh = 0;
            trocar_sprite(spr_ia_parado, 1);
            if (_dentro_campo)
            {
                estado_ia = "perseguir";
                if (!alertado) alerta_fx = 40;
                alertado = true;
            }
        break;

        // --------------------------------------------------------------
        case "perseguir":
            if (!_dentro_campo)
            {
                estado_ia = "parado";
                alertado = false;
                velh = 0;
                break;
            }
            if (_dx != 0) dir = sign(_dx);

            // limite de inimigos atacando ao mesmo tempo (depende da dificuldade)
            var _ativos = 0;
            with (obj_inimigo_01) if (id != other.id and ativo and estado_ia == "atacar") _ativos += 1;

            if (_no_chao and recarga <= 0 and _adx <= alcance_ataque and abs(_dy) <= alcance_ataque_y and _ativos < dif_atacantes_max())
            {
                estado_ia = "atacar";
                golpe_dado = false;
                som_golpe_tocou = false;
                golpe_janela = -1;
                golpe_som_i = 0;
                contador_ataques += 1;
                ataque_bloqueavel = (contador_ataques mod dif_quebra_guarda() != 0);   // a cada N golpes, 1 quebra a guarda
                fala_aleatoria(id, falas, cor_fala, 0.3);
                velh = 0;
                sprite_index = spr_ia_ataque;
                image_index = 0;
                image_speed = vel_ataque;
                break;
            }

            // OBSTÁCULO (caixote) no caminho: pula por cima
            if (_no_chao and _adx > distancia_minima and place_meeting(x + dir * 10, y - 2, obj_chao)
                and !place_meeting(x + dir * 10, y - 60, obj_chao) and !place_meeting(x, y - 60, obj_chao))
            {
                estado_ia = "pular_ar";
                pulo_obstaculo = true;
                pulando = true;
                velv = -6.9;
                velh = dir * 2.3;
                sprite_index = spr_ia_pular;
                image_index = 4;
                image_speed = 1;
                break;
            }

            // PULO: só quando o jogador está na zona próxima
            if (_no_chao and recarga_salto <= 0 and _adx >= zona_pulo_min and _adx <= zona_pulo_max
                and _dy > -140 and _dy < 50 and random(1) < 0.035 * _dt)
            {
                estado_ia = "pular_preparo";
                velh = 0;
                sprite_index = spr_ia_pular;
                image_index = 0;
                image_speed = 1.3;
                break;
            }

            if (_adx > distancia_minima)
            {
                // sempre correndo atrás de Twilight (não anda mais)
                velh = dir * vel_correr;
                trocar_sprite(spr_ia_correr, 1);
            }
            else
            {
                velh = 0;
                trocar_sprite(spr_ia_parado, 1);
            }
        break;

        // --------------------------------------------------------------
        case "atacar":
            velh = 0;                       // direção travada durante o golpe
            if (sprite_index != spr_ia_ataque) { sprite_index = spr_ia_ataque; image_index = 0; }
            image_speed = vel_ataque;
            var _fa = floor(image_index);
            var _nj = array_length(golpe_janelas);
            // som de cada golpe (um quadro antes de ferir)
            if (golpe_som_i < _nj and _fa >= golpe_janelas[golpe_som_i][0] - 1)
            {
                golpe_som_i += 1;
                som_golpe_tocou = true;
                som_em("sfx_inimigo_golpe", x, y, 0.55);
            }
            for (var _w = 0; _w < _nj; _w++)
            {
                var _jw = golpe_janelas[_w];
                if (_fa < _jw[0] or _fa > _jw[1]) continue;
                if (_w != golpe_janela) { golpe_janela = _w; golpe_dado = false; }   // novo golpe da sequência
                if (golpe_dado) continue;
                var _x1 = x + dir * golpe_caixa[0];
                var _x2 = x + dir * golpe_caixa[1];
                var _alvo = collision_rectangle(min(_x1, _x2), y + golpe_caixa[2], max(_x1, _x2), y + golpe_caixa[3], obj_player, false, true);
                if (_alvo != noone)
                {
                    golpe_dado = true;
                    with (_alvo) levar_dano(other.dano_ataque, other.x, other.ataque_bloqueavel, 5, other.id);
                }
            }
        break;

        // --------------------------------------------------------------
        case "pular_preparo":
            velh = 0;
            image_speed = 1.3;
            if (image_index >= 2)
            {
                if (_dx != 0) dir = sign(_dx);
                var _tempo_ar = 2 * forca_salto / grav_ia;
                var _dist = max(0, _adx - 34);
                velh = dir * clamp(_dist / _tempo_ar, 1.2, 4.4);
                velv = -forca_salto;
                pulando = true;
                pulo_obstaculo = false;
                estado_ia = "pular_ar";
            }
        break;

        // --------------------------------------------------------------
        case "pular_ar":
            image_speed = 1;
            if (pulo_obstaculo and velv < 1) velh = dir * 2.3;     // mantém o impulso por cima do caixote
            if (image_index >= 5.5) image_index = 5;
            if (_no_chao and velv >= 0)
            {
                pulando = false;
                velh = 0;
                estado_ia = "pular_pouso";
                image_index = 6;
                image_speed = 1.4;
                recarga_salto = irandom_range(150, 260);
                if (_adx < 300) global.camera_impact = max(global.camera_impact, 3);
            }
        break;

        // --------------------------------------------------------------
        case "pular_pouso":
            velh = 0;
        break;
    }
}

// ===== SEPARAÇÃO: os inimigos não ficam empilhados =====
if (atordoado <= 0 and _no_chao and (estado_ia == "perseguir" or estado_ia == "parado"))
{
    separacao = 0;
    with (obj_inimigo_base)
    {
        if (id != other.id and !morrendo and ativo and !eh_boss)
        {
            var _d = other.x - x;
            if (abs(_d) < 26 and abs(other.y - y) < 40)
            {
                var _lado = (_d == 0) ? ((other.id > id) ? 1 : -1) : sign(_d);
                other.separacao += _lado * (26 - abs(_d)) * 0.06;
            }
        }
    }
    velh += clamp(separacao, -1.2, 1.2);
}

// ===== EMPURRÃO (golpes / ricochete na defesa mágica) =====
if (empurrao != 0)
{
    velh += empurrao;
    empurrao = lerp_dt(empurrao, 0, 0.16);
    if (abs(empurrao) < 0.2) empurrao = 0;
}

// ===== GRAVIDADE =====
if (!_no_chao) velv += grav_ia * _dt;
else if (velv > 0) velv = 0;
image_xscale = 1;
