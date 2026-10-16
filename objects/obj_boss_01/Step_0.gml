var _dt = global.dt;
if (tempo_invencivel > 0) tempo_invencivel = max(0, tempo_invencivel - _dt);
if (flash_dano > 0) flash_dano -= _dt;
if (barra_tempo > 0) barra_tempo -= _dt;
if (titulo_tempo > 0) titulo_tempo -= _dt;
if (furia_fx > 0) furia_fx -= _dt;
tremor = max(0, tremor - 0.3 * _dt);
hud_alpha = lerp_dt(hud_alpha, ((acordado or estado_ia == "despertar") and !morrendo) ? 1 : 0, 0.08);
image_xscale = escala;
image_yscale = escala;

// ===== MORTE: explode em brasas, treme, afunda e evapora na fumaça da maldição =====
if (morrendo)
{
    morte_tempo += _dt;
    tremor = 3;
    explosoes_t -= _dt;
    if (explosoes_t <= 0 and morte_tempo < 150)
    {
        explosoes_t = 14;
        var _ex = x + random_range(-30, 30) * escala / 2;
        var _ey = y - random_range(15, 80) * escala;
        fx_em("faiscas_golpe", _ex, _ey, 1.6, choose(-1, 1));
        fx_em("brasas", _ex, _ey, 1.5);
        som_em(choose("fogo_explosao", "hit_3"), x, y, 0.6);
        global.camera_impact = max(global.camera_impact, 8);
    }
    if (global.cfg_qualidade > 0 and random(1) < 0.4 * _dt)
    {
        var _f = instance_create_depth(x + random_range(-45, 45) * escala / 3, y - random_range(20, 85) * escala, depth - 5, obj_fagulha);
        _f.cor = choose(make_color_rgb(255, 120, 30), make_color_rgb(255, 60, 40), make_color_rgb(255, 210, 90));
    }
    if (morte_tempo > 90 and !orbs_soltas) { orbs_soltas = true; orbs_soltar(x - 40, y - 60, ORBS_BOSS); }
    if (morte_tempo > 110) afundar = min(afundar + 0.35 * _dt, 34);
    // v1.10: a maldição consome a árvore numa fumaça negra enorme e ela some
    if (inimigo_evaporar(_dt, 110, 240))
    {
        aviso_mostrar("O GUARDIÃO CAIU  ·  O CAMINHO ESTÁ LIVRE");
        global.camera_impact = 10;
        arena_abrir(id);
        musica("mus_fase", 2500);
        progresso_marcar();
        instance_destroy();
    }
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

// o boss só desperta/ataca quando já aparece na tela
var _na_tela = true;
if (view_camera[0] != -1)
{
    var _cvx = camera_get_view_x(view_camera[0]);
    var _cvw = camera_get_view_width(view_camera[0]);
    _na_tela = (bbox_left < _cvx + _cvw - 30 and bbox_right > _cvx + 30);
}

// vira para o jogador (menos no meio de um ataque)
if (acordado and _tem_alvo and _dx != 0 and estado_ia != "atacando") dir = sign(_dx);

// relógio das ondas: 3,5 s depois de despertar e 3,5 s depois de cada onda acabar
if (acordado and servos_vivos() == 0) onda_tempo = min(onda_espera, onda_tempo + _dt);

// falas de vez em quando
if (acordado)
{
    fala_t -= _dt;
    if (fala_t <= 0)
    {
        fala_t = irandom_range(540, 900);
        var _fl = furia ? falas_boss_furia() : falas_boss();
        fala_dizer(id, _fl[irandom(array_length(_fl) - 1)], make_color_rgb(150, 20, 10));
    }
}

// raízes: na fase 2 de tempos em tempos, e sempre que Twilight fica colado no tronco
if (acordado and _tem_alvo)
{
    if (raiz_recarga > 0) raiz_recarga -= _dt;
    if (_adx < 150) perto_tempo += _dt; else perto_tempo = max(0, perto_tempo - _dt);
    if (raiz_recarga <= 0 and (furia or perto_tempo > 70) and estado_ia == "parado")
    {
        estado_ia = "raizes";
        sprite_index = spr_boss_01;
        image_index = 0;
        image_speed = 1.3;
        raizes_lancar();
        raiz_recarga = furia ? 200 : 260;
        perto_tempo = 0;
        global.camera_impact = max(global.camera_impact, 6);
    }
}

switch (estado_ia)
{
    case "dormindo":
        // a luta começa quando Twilight entra na arena e vê a árvore
        if (_tem_alvo and _na_tela and _p.x > arena_esq + 70 and abs(_dy) < 320) despertar();
    break;

    case "despertar":
        // termina no Animation End
    break;

    case "parado":
        if (sprite_index != spr_boss_01_parado) { sprite_index = spr_boss_01_parado; image_index = 0; }
        image_speed = furia ? 1.4 : 1;
        if (recarga > 0) recarga -= _dt;

        // ONDA DE SERVOS: 10 bestas + 5 arqueiros
        if (onda_tempo >= onda_espera and servos_vivos() == 0)
        {
            estado_ia = "invocando";
            onda_tempo = 0;
            invocacao_feita = false;
            sprite_index = spr_boss_01;
            image_index = 0;
            image_speed = 1;
            global.camera_impact = max(global.camera_impact, 8);
            som("sfx_portal", 0.9, 0);
        }
        else if (_tem_alvo and _na_tela and _adx <= alcance_visao and abs(_dy) < 320 and recarga <= 0)
        {
            estado_ia = "atacando";
            golpe_lancado = false;
            rajada = furia ? 3 : 1;
            sprite_index = spr_boss_01_atacando;
            image_index = 0;
            image_speed = furia ? 1.9 : 1.5;
        }
    break;

    case "atacando":
        // quadro 6: a bola de fogo sai da mão (na fúria são 3, em leque)
        if (!golpe_lancado and image_index >= 6)
        {
            golpe_lancado = true;
            if (rajada >= 3)
            {
                lancar_bola_fogo(_tem_alvo ? _p : noone, -9);
                lancar_bola_fogo(_tem_alvo ? _p : noone, 0);
                lancar_bola_fogo(_tem_alvo ? _p : noone, 9);
            }
            else lancar_bola_fogo(_tem_alvo ? _p : noone, 0);
        }
    break;

    case "invocando":
        if (!invocacao_feita and image_index >= 4)
        {
            invocacao_feita = true;
            invocar_servos();
        }
    break;
}
