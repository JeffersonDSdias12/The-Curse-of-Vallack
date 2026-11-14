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

// v1.17: presa na SEQUÊNCIA DE GOLPES: treme e espera (o obj_qte comanda)
if (em_qte and !morrendo)
{
    tremor = max(tremor, 1.5);
    image_speed = 0.2;
    exit;
}

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
    // v1.12: últimas palavras numa caixa de diálogo
    if (morte_tempo > 45 and !dialogo_fim_feito) { dialogo_fim_feito = true; dialogo_iniciar("arvore_fim"); }
    if (morte_tempo > 90 and !orbs_soltas) { orbs_soltas = true; orbs_soltar(x - 40, y - 60, ORBS_BOSS); }
    if (morte_tempo > 110) afundar = min(afundar + 0.35 * _dt, 34);
    // v1.10: a maldição consome a árvore numa fumaça negra enorme e ela some
    if (inimigo_evaporar(_dt, 110, 240))
    {
        aviso_mostrar("O GUARDIÃO CAIU  ·  O CAMINHO ESTÁ LIVRE");
        global.camera_impact = 10;
        arena_abrir(id);
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

// v1.12: sem ondas de servos e sem balões de fala

// v1.19: CHUVA DE BRASAS: cada marca no chão vira uma bola de fogo caindo do céu
for (var _c = array_length(chuva_fila) - 1; _c >= 0; _c--)
{
    var _ch = chuva_fila[_c];
    _ch[@ 1] -= _dt;
    if (_ch[1] > 0) continue;
    var _topo_cam = (view_camera[0] != -1) ? camera_get_view_y(view_camera[0]) : y_chao - 400;
    var _b = instance_create_depth(_ch[0] + random_range(-8, 8), _topo_cam - 24, depth - 5, obj_bola_fogo);
    _b.dano = dano_fogo;
    _b.alcance = 2000;
    _b.vx = random_range(-0.4, 0.4);
    _b.vy = CHUVA_VEL + fase * 0.4;
    som_em("fogo_bola", _ch[0], y_chao, 0.5);
    array_delete(chuva_fila, _c, 1);
}

// v1.19: fase 3: a chama de Vallack faz chover brasas na arena (só enfeite)
if (fase >= 3 and acordado and random(1) < 0.25 * _dt)
{
    var _vx0 = (view_camera[0] != -1) ? camera_get_view_x(view_camera[0]) : arena_esq;
    var _vy0 = (view_camera[0] != -1) ? camera_get_view_y(view_camera[0]) : y_chao - 300;
    fx_em("brasas", _vx0 + random(view_camera[0] != -1 ? camera_get_view_width(view_camera[0]) : 600), _vy0 + random(120), 0.8);
}

// raízes: sempre que Twilight fica colado no tronco (fora da sequência)
if (acordado and _tem_alvo)
{
    if (raiz_recarga > 0) raiz_recarga -= _dt;
    if (_adx < 150) perto_tempo += _dt; else perto_tempo = max(0, perto_tempo - _dt);
    if (raiz_recarga <= 0 and perto_tempo > 70 and estado_ia == "parado" and !instance_exists(obj_raiz))
    {
        estado_ia = "raizes";
        sprite_index = spr_acao;
        image_index = 0;
        image_speed = 1.3;
        raizes_lancar(fase >= 2 ? 3 : 1);
        raiz_recarga = (fase >= 2) ? 170 : 240;     // v1.19: pune mais rápido quem fica colado
        perto_tempo = 0;
        global.camera_impact = max(global.camera_impact, 6);
    }
}

// v1.19: INVOCAÇÃO contra quem se aproveita da luta: colado no tronco batendo
// sem parar, ou parado num lugar onde os ataques não chegam (procurando um "bug")
if (acordado and _tem_alvo and !finalizavel)
{
    if (golpeada_t > 0) golpeada_t -= _dt;
    if (invocar_recarga > 0) invocar_recarga -= _dt;
    if (_adx < 190 and golpeada_t > 0) acampar_t += _dt; else acampar_t = max(0, acampar_t - _dt * 0.25);
    if (point_distance(_p.x, _p.y, canto_x, canto_y) > 90) { canto_x = _p.x; canto_y = _p.y; canto_t = 0; }
    else canto_t += (_dy < -170) ? 2 * _dt : _dt;      // no alto, longe do chão da arena, conta em dobro
    if (vida_jogador_ant >= 0 and _p.vida < vida_jogador_ant) canto_t = 0;   // está sendo acertado: não é esconderijo
    vida_jogador_ant = _p.vida;
    var _motivo = (acampar_t >= INVOCAR_PERTO) ? "perto" : ((canto_t >= INVOCAR_CANTO) ? "canto" : "");
    if (_motivo != "" and invocar_recarga <= 0 and estado_ia == "parado" and servos_vivos() < 2 and !instance_exists(obj_qte))
    {
        estado_ia = "invocando";
        invocacao_feita = false;
        invocacao_motivo = _motivo;
        sprite_index = spr_acao;
        image_index = 0;
        image_speed = 1;
        acampar_t = 0;
        canto_t = 0;
        invocar_recarga = 960 - fase * 120;          // 16 / 14 / 12 s entre uma e outra
        tremor = 3;
        global.camera_impact = max(global.camera_impact, 12);
        global.terremoto = max(global.terremoto, 24);
        som("sfx_rugido", 0.9, 0);
        fala_balao(id, (_motivo == "canto") ? "Acha que pode se esconder de mim?" : "Servos... protejam a raiz!", make_color_rgb(150, 20, 20), 150);
        aviso_mostrar("A ÁRVORE CONVOCA SEUS SERVOS!");
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

    // v1.17: CAMBALEANDO (12% da vida): espera a sequência de golpes; se demorar, se recupera
    case "vulneravel":
        vulneravel_t += _dt;
        tremor = max(tremor, 1.2);
        if (image_index >= image_number - 1) image_index = image_number - 2;
        if (vulneravel_t >= 420) boss_recuperar();
    break;

    case "parado":
        if (sprite_index != spr_parado) { sprite_index = spr_parado; image_index = 0; }
        image_speed = furia ? 1.4 : 1;
        if (recarga > 0) recarga -= _dt;

        // v1.19: CHUVA DE FOGO nos momentos marcados (85%, 50%, 22% da vida) e de tempos em tempos
        if (chuva_grande_t > 0) chuva_grande_t -= _dt;
        var _pede_chuva = (chuva_marco_i < array_length(chuva_marcos) and vida <= vida_max * chuva_marcos[chuva_marco_i]) or chuva_grande_t <= 0;
        if (_pede_chuva and _tem_alvo and _na_tela and array_length(chuva_fila) == 0)
        {
            while (chuva_marco_i < array_length(chuva_marcos) and vida <= vida_max * chuva_marcos[chuva_marco_i]) chuva_marco_i += 1;
            chuva_grande_t = (fase >= 3) ? 1080 : ((fase == 2) ? 1440 : 1800);     // 18 / 24 / 30 s
            estado_ia = "chuva";
            sprite_index = spr_acao;
            image_index = 0;
            image_speed = 1;
            chuva_grande();
            break;
        }

        // v1.12: cada fase tem a sua sequência de ataques (boss_proximo_ataque)
        if (_tem_alvo and _na_tela and _adx <= alcance_visao and abs(_dy) < 320 and recarga <= 0)
        {
            var _atq = boss_proximo_ataque();
            if (string_copy(_atq, 1, 4) == "fogo")
            {
                // AVISO: a mão brilha e a árvore "puxa" a chama antes de lançar
                estado_ia = "atacando";
                golpe_lancado = false;
                rajada = (_atq == "fogo3") ? 3 : ((_atq == "fogo2") ? 2 : 1);
                rajada_desvios = (rajada == 3) ? [-10, 0, 10] : ((rajada == 2) ? [-5, 5] : [0]);
                sprite_index = spr_ataque;
                image_index = 0;
                image_speed = (fase >= 3) ? 1.5 : 1.25;
                som_em("boss_carga", x, y, 0.9);
            }
            else if (string_copy(_atq, 1, 4) == "raiz")
            {
                estado_ia = "raizes";
                sprite_index = spr_acao;
                image_index = 0;
                image_speed = 1.3;
                raizes_lancar(real(string_delete(_atq, 1, 4)));
                global.camera_impact = max(global.camera_impact, 6);
            }
            else if (_atq == "chuva")
            {
                // v1.19: ergue os galhos e chama a chuva de brasas
                estado_ia = "chuva";
                sprite_index = spr_acao;
                image_index = 0;
                image_speed = 1.2;
                chuva_lancar((fase >= 3) ? 7 : 4);
                global.camera_impact = max(global.camera_impact, 8);
                global.terremoto = max(global.terremoto, 16);
            }
            else
            {
                estado_ia = "galho";
                sprite_index = spr_acao;
                image_index = 0;
                image_speed = 0.9;
                galho_lancar();
                global.camera_impact = max(global.camera_impact, 8);
            }
        }
    break;

    case "transicao":
    case "galho":
    case "chuva":
        // terminam no Animation End
    break;

    case "atacando":
        // quadro 6: a bola de fogo sai da mão (na fúria são 3, em leque)
        if (!golpe_lancado and image_index >= 6)
        {
            golpe_lancado = true;
            for (var _r = 0; _r < array_length(rajada_desvios); _r++) lancar_bola_fogo(_tem_alvo ? _p : noone, rajada_desvios[_r]);
        }
    break;

    case "invocando":
        if (!invocacao_feita and image_index >= 4)
        {
            invocacao_feita = true;
            invocar_guardas(invocacao_motivo);     // v1.19: poucos servos, perto de Twilight
        }
    break;
}
