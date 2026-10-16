// =====================================================================
//  obj_estatua — Step
//  Estados: escondido/portal/subindo (surgir), pedra, desperta,
//           esfriando, morrendo (desmorona)
// =====================================================================
var _dt = global.dt;

// ===== AINDA ESCONDIDA: surge do chão por um portal de magia (scr_dano) =====
if (inimigo_portal_step(_dt)) exit;

// ===== MORTE: desmorona; o entulho fica no mapa =====
if (morrendo)
{
    inimigo_corpo_step(_dt);
    velh = 0;
    morte_anim += _dt;
    if (morte_anim >= 50) morte_fim = true;
    exit;
}
if (y > room_height + 300) { instance_destroy(); exit; }

// ===== TEMPORIZADORES =====
if (tempo_invencivel > 0) tempo_invencivel = max(0, tempo_invencivel - _dt);
if (recarga > 0) recarga -= _dt;
if (barra_tempo > 0) barra_tempo -= _dt;
if (flash_dano > 0) flash_dano -= _dt;
if (alerta_fx > 0) alerta_fx -= _dt;
if (vulneravel_t > 0) vulneravel_t = max(0, vulneravel_t - _dt);
if (rachada_t > 0) rachada_t = max(0, rachada_t - _dt);
if (tinido_t > 0) tinido_t = max(0, tinido_t - _dt);
atordoado = 0;                      // pedra não fica tonta (o orbe rebatido a racha)
inimigo_finalizador_step();

var _no_chao = place_meeting(x, y + 1, obj_chao);

// ===== JOGADOR =====
var _p = instance_find(obj_player, 0);
var _tem_alvo = (_p != noone);
if (_tem_alvo and _p.morto) _tem_alvo = false;
var _dx = 0;
var _dy = 0;
if (_tem_alvo) { _dx = _p.x - x; _dy = _p.y - y; }
var _dentro = _tem_alvo and (abs(_dx) <= campo) and (abs(_dy) <= 220) and inimigo_na_tela(-24);

switch (estado_ia)
{
    // ------------------------------------------------------------------
    case "pedra":
        image_index = 0;
        if (_tem_alvo and _dx != 0) dir = sign(_dx);
        if (_dentro and recarga <= 0)
        {
            // OS OLHOS ACENDEM: desperta e começa a carregar o orbe
            estado_ia = "desperta";
            anim_t = 0;
            orbe_solto = false;
            alerta_fx = 30;
            som_em("estatua_carga", x, y, 0.75);
            if (!falou) { fala_dizer(id, falas[irandom(array_length(falas) - 1)], cor_fala); falou = true; }
            else fala_aleatoria(id, falas, cor_fala, 0.2);
        }
    break;

    // ------------------------------------------------------------------
    case "desperta":
        anim_t += _dt;
        image_index = clamp(1 + anim_t * 0.075, 1, 5.99);      // quadros 1-5 em ~1,1 s
        if (!orbe_solto and anim_t >= 40)
        {
            orbe_solto = true;
            vulneravel_t = 50;
            var _bx = x + dir * 4;
            var _by = y - 64;
            var _tx = _bx + dir * 200;
            var _ty = _by;
            if (_tem_alvo) { _tx = _p.x; _ty = _p.y - 34; }
            var _ang = point_direction(_bx, _by, _tx, _ty);
            var _vel = 4.4;
            magia_criar("orbe", _bx, _by, lengthdir_x(_vel, _ang), lengthdir_y(_vel, _ang), dano_orbe, id);
            som_em("estatua_disparo", x, y, 0.85);
        }
        if (anim_t >= 66)
        {
            estado_ia = "esfriando";
            anim_t = 0;
        }
    break;

    // ------------------------------------------------------------------
    case "esfriando":
        anim_t += _dt;
        image_index = 6 + min(1.99, anim_t * 0.066);            // olhos apagando
        if (anim_t >= 30)
        {
            estado_ia = "pedra";
            recarga = recarga_max + irandom(50);
        }
    break;
}

// ===== PARADA: só a gravidade =====
velh = 0;
empurrao = 0;
if (!_no_chao) velv += grav_ia * _dt;
else if (velv > 0) velv = 0;
image_xscale = 1;
image_yscale = 1;
