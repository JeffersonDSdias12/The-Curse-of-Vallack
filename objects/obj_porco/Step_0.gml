// =====================================================================
//  obj_porco — IA (Step)
//  Estados: escondido/portal/subindo (surgir), parado, perseguir, atacar,
//           salto_prep, salto_ar, salto_pouso, onda, rugir, invocar,
//           (atordoado), morrendo
// =====================================================================
var _dt = global.dt;

// ===== AINDA ESCONDIDO: surge do chão por um portal de magia (scr_dano) =====
if (inimigo_portal_step(_dt)) exit;

// ===== MORTE: animação de queda; o corpo fica no mapa =====
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
if (recarga_onda > 0) recarga_onda -= _dt;
if (barra_tempo > 0) barra_tempo -= _dt;
if (flash_dano > 0) flash_dano -= _dt;
if (alerta_fx > 0) alerta_fx -= _dt;
if (libertou_fx > 0) libertou_fx -= _dt;
aura_t += _dt;

var _no_chao = place_meeting(x, y + 1, obj_chao);
if (!_no_chao) no_ar_t += _dt; else if (velv >= 0) no_ar_t = 0;

// ===== PRESO NO FINALIZADOR DE TWILIGHT =====
if (inimigo_finalizador_step())
{
    if (estado_ia != "salto_ar") estado_ia = "perseguir";
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
    som_em("porco_grunhido", x, y, 0.8);
    fala_aleatoria(id, falas, cor_fala, 0.6);
}

// ===== ATORDOAMENTO (só aparando ou pela exaustão) =====
var _estava_atordoado = (atordoado > 0);
if (inimigo_atordoamento_step(_dt))
{
    if (_no_chao) velh = 0;
    if (estado_ia == "rugir" or estado_ia == "invocar") furia_pendente = !invocou;
    if (estado_ia == "invocar" and invocou) { furioso = true; vel_correr = 2.5; }
    if (estado_ia != "parado" and estado_ia != "salto_ar") estado_ia = "perseguir";
    trocar_sprite(spr_ia_parado, 0.3);
}
else
{
    if (_estava_atordoado)
    {
        estado_ia = _dentro ? "perseguir" : "parado";
        recarga = min(recarga, 12);
        image_speed = 1;
    }

    // FÚRIA (metade da vida): ruge e invoca esqueletos assim que estiver no chão
    if (furia_pendente and !invocou and _no_chao and (estado_ia == "perseguir" or estado_ia == "parado"))
    {
        furia_pendente = false;
        estado_ia = "rugir";
        velh = 0;
        sprite_index = spr_porco_furia;
        image_index = 0;
        image_speed = 0.8;
        som_em("sfx_rugido", x, y, 0.9);
        global.camera_impact = max(global.camera_impact, 8);
        var _ff = falas_porco_furia();
        fala_dizer(id, _ff[irandom(array_length(_ff) - 1)], cor_fala, true);
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

            if (_no_chao)
            {
                // CORTE VERMELHO: de perto
                if (recarga <= 0 and _adx <= alcance_ataque and abs(_dy) < 60)
                {
                    estado_ia = "atacar";
                    golpe_dado = false;
                    golpe_janela = -1;
                    golpe_som_i = 0;
                    contador_ataques += 1;
                    ataque_bloqueavel = (contador_ataques mod 3 != 0);    // um em cada três quebra a guarda
                    fala_aleatoria(id, falas, cor_fala, 0.25);
                    velh = 0;
                    sprite_index = spr_ia_ataque;
                    image_index = 0;
                    image_speed = furioso ? 1 : 0.8;
                    break;
                }
                // SALTO ESMAGADOR: média distância
                if (recarga_salto <= 0 and _adx >= 130 and _adx <= 360 and abs(_dy) < 120 and inimigo_pode_andar(dir, 60))
                {
                    estado_ia = "salto_prep";
                    velh = 0;
                    sprite_index = spr_porco_salto;
                    image_index = 0;
                    image_speed = 0.55;
                    fala_aleatoria(id, falas_porco_salto(), cor_fala, 0.5);
                    break;
                }
                // CORTE ROXO: onda de magia rente ao chão
                if (recarga_onda <= 0 and _adx >= 150 and _adx <= 520 and abs(_dy) < 40 and inimigo_na_tela())
                {
                    estado_ia = "onda";
                    onda_solta = false;
                    velh = 0;
                    sprite_index = spr_porco_roxo;
                    image_index = 0;
                    image_speed = 0.7;
                    fala_aleatoria(id, falas_porco_onda(), cor_fala, 0.4);
                    break;
                }
            }

            // corre atrás de Twilight
            if (_adx > alcance_ataque - 12 and inimigo_pode_andar(dir, 24))
            {
                velh = dir * vel_correr;
                trocar_sprite(spr_ia_correr, furioso ? 1.25 : 1);
            }
            else
            {
                velh = 0;
                trocar_sprite(spr_ia_parado, 1);
            }
        break;

        // --------------------------------------------------------------
        case "atacar":
            velh = 0;
            if (sprite_index != spr_ia_ataque) { sprite_index = spr_ia_ataque; image_index = 0; }
            var _fa = floor(image_index);
            var _nj = array_length(golpe_janelas);
            if (golpe_som_i < _nj and _fa >= golpe_janelas[golpe_som_i][0] - 1)
            {
                golpe_som_i += 1;
                som_em("atk_pesado", x, y, 0.55);
            }
            for (var _w = 0; _w < _nj; _w++)
            {
                var _jw = golpe_janelas[_w];
                if (_fa < _jw[0] or _fa > _jw[1]) continue;
                if (_w != golpe_janela) { golpe_janela = _w; golpe_dado = false; }
                if (golpe_dado) continue;
                var _x1 = x + dir * 2;
                var _x2 = x + dir * 64;
                var _alvo = collision_rectangle(min(_x1, _x2), y - 72, max(_x1, _x2), y - 4, obj_player, false, true);
                if (_alvo != noone)
                {
                    golpe_dado = true;
                    with (_alvo) levar_dano(other.dano_ataque, other.x, other.ataque_bloqueavel, 7, other.id);
                }
            }
        break;

        // --------------------------------------------------------------
        case "salto_prep":
            velh = 0;
            if (_tem_alvo and _dx != 0) dir = sign(_dx);
            if (image_index >= 2)
            {
                var _tar = 2 * forca_salto / grav_ia;
                velh = dir * clamp((_adx - 20) / _tar, 2, 8.5);
                velv = -forca_salto;
                estado_ia = "salto_ar";
                no_ar_t = 0;
                image_speed = 0.9;
                som_em("sfx_pulo", x, y, 0.7);
                fx_em("poeira", x, y, 0.8);
            }
        break;

        case "salto_ar":
            if (image_index >= 5.9) image_index = 5;              // segura a pose no ar
            if (velh != 0 and !inimigo_pode_andar(sign(velh), 26)) velh = 0;
            if (_no_chao and velv >= 0 and no_ar_t <= 0)
            {
                // ATERRISSAGEM: onda de choque no chão (pule ou role para escapar)
                velh = 0;
                estado_ia = "salto_pouso";
                image_index = 6;
                image_speed = 0.8;
                som_em("porco_impacto", x, y, 1);
                global.camera_impact = max(global.camera_impact, 9);
                fx_em("onda_chao", x, y, 1.2);
                fx_em("poeira", x, y, 1.2);
                if (_tem_alvo)
                {
                    var _no_chao_p = place_meeting(_p.x, _p.y + 2, obj_chao);
                    var _intang = false;
                    with (_p) _intang = jogador_intangivel();
                    if (_no_chao_p and !_intang and abs(_p.x - x) <= 112 and abs(_p.y - y) < 40)
                    {
                        with (_p) levar_dano(other.dano_salto, other.x, false, 8, noone);
                        if (!_p.morto) _p.velv = min(_p.velv, -3);
                    }
                }
            }
        break;

        case "salto_pouso":
            velh = 0;
        break;

        // --------------------------------------------------------------
        case "onda":
            velh = 0;
            if (!onda_solta and image_index >= 3)
            {
                onda_solta = true;
                magia_criar("onda", x + dir * 46, y, dir * (furioso ? 6.2 : 5.2), 0, dano_onda, id);
                som_em("magia_onda", x, y, 0.85);
            }
        break;

        // --------------------------------------------------------------
        case "rugir":
            velh = 0;
            if (floor(image_index) == 4 and global.camera_impact < 4) global.camera_impact = 4;
        break;

        case "invocar":
            velh = 0;
            if (!invocou and image_index >= 5)
            {
                invocou = true;
                porco_invocar();
            }
        break;
    }
}

// ===== EMPURRÃO =====
if (empurrao != 0)
{
    velh += empurrao;
    empurrao = lerp_dt(empurrao, 0, 0.2);
    if (abs(empurrao) < 0.2) empurrao = 0;
}

// ===== GRAVIDADE (a física/colisão está no End Step do obj_entidade) =====
if (!_no_chao) velv += grav_ia * _dt;
else if (velv > 0) velv = 0;
image_xscale = 1;
image_yscale = 1;
