// =====================================================================
//  obj_aranha — IA (Step)
//  Estados: escondido/portal/subindo (surgir), parado, perseguir,
//           garra, teia, bote_prep, bote, bote_fim, (atordoada), morrendo
//  Os ataques controlam os quadros à mão (a animação tem só 4 quadros).
// =====================================================================
var _dt = global.dt;

// ===== AINDA ESCONDIDA: surge do chão por um portal de magia (scr_dano) =====
if (inimigo_portal_step(_dt)) exit;

// ===== MORTE: vira de patas para cima (desenhada no Draw); o corpo fica =====
if (morrendo)
{
    inimigo_corpo_step(_dt);
    morte_anim += _dt;
    if (morte_anim >= 36) morte_fim = true;
    exit;
}
if (y > room_height + 300) { instance_destroy(); exit; }

// ===== TEMPORIZADORES =====
if (tempo_invencivel > 0) tempo_invencivel = max(0, tempo_invencivel - _dt);
if (recarga > 0) recarga -= _dt;
if (recarga_teia > 0) recarga_teia -= _dt;
if (recarga_bote > 0) recarga_bote -= _dt;
if (barra_tempo > 0) barra_tempo -= _dt;
if (flash_dano > 0) flash_dano -= _dt;
if (alerta_fx > 0) alerta_fx -= _dt;
if (libertou_fx > 0) libertou_fx -= _dt;

var _no_chao = place_meeting(x, y + 1, obj_chao);

// ===== PRESA NO FINALIZADOR DE TWILIGHT =====
if (inimigo_finalizador_step())
{
    estado_ia = "perseguir";
    trocar_sprite(spr_ia_parado, 0.2);
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
var _dentro = _tem_alvo and (_adx <= campo) and (abs(_dy) <= campo_altura);
if (_dentro and !viu and inimigo_na_tela())
{
    viu = true;
    alerta_fx = 40;
    fala_aleatoria(id, falas, cor_fala, 0.5);
}

// ===== REGRA DE ATORDOAMENTO =====
if (_tem_alvo) inimigo_regra_atordoamento(_p);
var _estava_atordoado = (atordoado > 0);

if (inimigo_atordoamento_step(_dt))
{
    if (_no_chao) velh = 0;
    if (estado_ia != "parado") estado_ia = "perseguir";      // cancela garra, teia e bote
    trocar_sprite(spr_ia_parado, 0.5);
}
else
{
    if (_estava_atordoado)
    {
        estado_ia = _dentro ? "perseguir" : "parado";
        recarga = min(recarga, 14);
        image_speed = 1;
    }

    switch (estado_ia)
    {
        // --------------------------------------------------------------
        case "parado":
            velh = 0;
            trocar_sprite(spr_ia_parado, 1);
            if (_dentro and viu) estado_ia = "perseguir";
        break;

        // --------------------------------------------------------------
        case "perseguir":
            if (!_dentro) { estado_ia = "parado"; velh = 0; break; }
            if (_dx != 0) dir = sign(_dx);

            if (_no_chao and recarga <= 0)
            {
                // GARRA: de perto
                if (_adx <= 62 and abs(_dy) < 50)
                {
                    estado_ia = "garra";
                    ataque_t = 0;
                    golpe_dado = false;
                    velh = 0;
                    trocar_sprite(spr_ia_ataque, 0);
                    image_index = 0;
                    break;
                }
                // BOTE: salta com as garras
                if (recarga_bote <= 0 and _adx >= 90 and _adx <= 230 and abs(_dy) < 60 and inimigo_pode_andar(dir, 64))
                {
                    estado_ia = "bote_prep";
                    ataque_t = 0;
                    golpe_dado = false;
                    velh = 0;
                    trocar_sprite(spr_ia_parado, 0);
                    image_index = 1;
                    fala_aleatoria(id, falas, cor_fala, 0.3);
                    break;
                }
                // TEIA: de longe, em arco
                if (recarga_teia <= 0 and _adx >= 110 and _adx <= 430 and abs(_dy) < 140 and inimigo_na_tela())
                {
                    estado_ia = "teia";
                    ataque_t = 0;
                    teia_solta = false;
                    velh = 0;
                    trocar_sprite(spr_ia_ataque, 0);
                    image_index = 0;
                    break;
                }
            }

            // movimento: mantém a distância ideal, sempre de frente para Twilight
            var _mv = 0;
            if (_adx > dist_ideal_max) _mv = dir;
            else if (recarga <= 0 and _adx > 58) _mv = dir;             // pronta para atacar: avança
            else if (_adx < dist_ideal_min) _mv = -dir;                // perto demais: recua
            if (_mv != 0 and !inimigo_pode_andar(_mv)) _mv = 0;
            if (_mv != 0)
            {
                velh = _mv * vel_andar * ((_mv == dir) ? 1 : 0.75);
                trocar_sprite(spr_ia_andar, (_mv == dir) ? 1.5 : 1.1);
            }
            else
            {
                velh = 0;
                trocar_sprite(spr_ia_parado, 1);
            }
        break;

        // --------------------------------------------------------------
        case "garra":
            velh = 0;
            ataque_t += _dt;
            if (ataque_t < 16) image_index = 0;                       // ergue as garras (aviso)
            else image_index = min(3, 1 + floor((ataque_t - 16) / 8));
            if (!golpe_dado and ataque_t >= 16 and ataque_t < 26)
            {
                if (ataque_t - _dt < 16) som_em("sfx_inimigo_golpe", x, y, 0.5);
                var _x1 = x + dir * 4;
                var _x2 = x + dir * 50;
                var _alvo = collision_rectangle(min(_x1, _x2), y - 50, max(_x1, _x2), y - 4, obj_player, false, true);
                if (_alvo != noone)
                {
                    golpe_dado = true;
                    with (_alvo) levar_dano(other.dano_garra, other.x, true, 4, other.id);
                }
            }
            if (ataque_t >= 40)
            {
                estado_ia = "perseguir";
                recarga = recarga_garra + irandom(20);
                trocar_sprite(spr_ia_parado, 1);
            }
        break;

        // --------------------------------------------------------------
        case "teia":
            velh = 0;
            ataque_t += _dt;
            if (_tem_alvo and !teia_solta and _dx != 0) dir = sign(_dx);
            if (ataque_t < 22) image_index = 0;
            else image_index = min(3, 1 + floor((ataque_t - 22) / 8));
            if (!teia_solta and ataque_t >= 22)
            {
                teia_solta = true;
                var _bx = x + dir * 16;
                var _by = y - 46;
                var _tx = _bx + dir * 240;
                var _ty = y - 30;
                if (_tem_alvo) { _tx = _p.x; _ty = _p.y - 30; }
                // arco: velocidade horizontal fixa, a vertical compensa a gravidade da teia
                var _vh = 5.6;
                var _tempo = max(8, abs(_tx - _bx) / _vh);
                var _vv = (_ty - _by) / _tempo - 0.5 * 0.12 * _tempo;
                magia_criar("teia", _bx, _by, dir * _vh, clamp(_vv, -7, 4), dano_teia, id);
                som_em("teia_disparo", x, y, 0.75);
                fala_aleatoria(id, falas_aranha_teia(), cor_fala, 0.3);
            }
            if (ataque_t >= 46)
            {
                estado_ia = "perseguir";
                recarga_teia = recarga_teia_max + irandom(60);
                recarga = max(recarga, 30);
                trocar_sprite(spr_ia_parado, 1);
            }
        break;

        // --------------------------------------------------------------
        case "bote_prep":
            velh = 0;
            ataque_t += _dt;
            if (_tem_alvo and _dx != 0) dir = sign(_dx);
            if (ataque_t >= 18)
            {
                // salta até onde Twilight está
                var _forca = 5.4;
                var _tar = 2 * _forca / grav_ia;
                velh = dir * clamp((_adx - 30) / _tar, 2.5, 7);
                velv = -_forca;
                estado_ia = "bote";
                bote_no_ar = 0;
                trocar_sprite(spr_ia_ataque, 0);
                image_index = 1;
                som_em("aranha_chiado", x, y, 0.55);
            }
        break;

        case "bote":
            bote_no_ar += _dt;
            image_index = 1;
            if (!golpe_dado)
            {
                var _bx1 = x + dir * 0;
                var _bx2 = x + dir * 46;
                var _alvo_b = collision_rectangle(min(_bx1, _bx2), y - 48, max(_bx1, _bx2), y - 2, obj_player, false, true);
                if (_alvo_b != noone)
                {
                    golpe_dado = true;
                    with (_alvo_b) levar_dano(other.dano_bote, other.x, true, 6, other.id);
                }
            }
            if (_no_chao and velv >= 0 and bote_no_ar > 4)
            {
                velh = 0;
                estado_ia = "bote_fim";
                ataque_t = 0;
                image_index = 2;
                fx_em("poeira", x, y, 0.5);
            }
            // bateu numa parede ou na beira da arena: para
            if (velh != 0 and !inimigo_pode_andar(sign(velh), 18)) velh = 0;
        break;

        case "bote_fim":
            velh = 0;
            ataque_t += _dt;
            image_index = (ataque_t < 10) ? 2 : 3;
            if (ataque_t >= 22)
            {
                estado_ia = "perseguir";
                recarga_bote = recarga_bote_max + irandom(60);
                recarga = max(recarga, 24);
                trocar_sprite(spr_ia_parado, 1);
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
image_xscale = 1;
image_yscale = 1;
