// =====================================================================
//  scr_cenario: cenário destrutível, baús de vida, armadilhas, arenas
//  e efeitos usados por vários objetos
// =====================================================================

#macro BAU_PARTICULAS 36     // gotas de magia que saem de um baú de vida

// Efeito visual (obj_fx) criado de qualquer lugar
function fx_em(_tipo, _x, _y, _tam = 1, _dir = 1, _prof = -110)
{
    var _f = instance_create_depth(_x, _y, _prof, obj_fx);
    _f.tipo = _tipo;
    _f.tam = _tam;
    _f.dir = _dir;
    with (_f) fx_iniciar();
    return _f;
}

// ---------------------------------------------------------------------
// BLOCO SÓLIDO de um objeto destrutível (caixote, parede, muralha mágica)
// O obj_solido é filho do obj_chao: jogador e inimigos sobem, andam e
// batem nele. Ele cobre exatamente a caixa de colisão do dono.
// ---------------------------------------------------------------------
function solido_criar(_x1, _y1, _x2, _y2)
{
    var _s = instance_create_depth(_x1, _y1, 0, obj_solido);
    _s.image_xscale = max(0.05, (_x2 - _x1) / 20);    // spr_chao tem 20 x 35
    _s.image_yscale = max(0.05, (_y2 - _y1) / 35);
    _s.dono = id;
    return _s;
}

function solido_mover(_s, _x1, _y1)
{
    if (_s != noone and instance_exists(_s)) { _s.x = _x1; _s.y = _y1; }
}

function solido_remover(_s)
{
    if (_s != noone and instance_exists(_s)) instance_destroy(_s);
}

// ---------------------------------------------------------------------
// DESTRUTÍVEIS (executado na instância de obj_destrutivel)
// _forca: 1 golpe normal, 2 golpe pesado / onda, 3 especial em área
// ---------------------------------------------------------------------
function destrutivel_bater(_forca, _origem_x)
{
    if (quebrado or vida <= 0) return;
    if (!pode_bater()) return;
    vida -= _forca;
    tremor = 6;
    flash = 6;
    lado_golpe = sign(x - _origem_x);
    if (lado_golpe == 0) lado_golpe = 1;
    if (vida <= 0)
    {
        quebrado = true;
        ao_quebrar(lado_golpe);
    }
    else ao_bater(_forca);
}

// Caixote: o que tem dentro
//  "nada", "orbs" (orbs_valor) ou "bau" (um baú de vida escondido)
function caixote_quebrar(_lado)
{
    som_em("dest_madeira", x, y, 1);           // destruição: madeira
    fx_em("lascas", x, y - 16, 1.1, _lado);
    fx_em("poeira", x, y, 0.7, _lado);
    global.camera_impact = max(global.camera_impact, 3);
    if (conteudo == "orbs") orbs_soltar(x, y - 18, orbs_valor);
    if (bau != noone and instance_exists(bau)) with (bau) bau_revelar();
    solido_remover(solido);
    solido = noone;
    instance_destroy();
}

// ---------------------------------------------------------------------
// BAÚ DE VIDA (executado no obj_bau)
// ---------------------------------------------------------------------
function bau_revelar()
{
    if (visivel) return;
    visivel = true;
    revelar_t = 30;
    som_em("sfx_cura", x, y, 0.4);
}

// Twilight abre o baú: animação da tampa, depois a magia flui para ele
function bau_abrir(_jogador)
{
    if (estado != "fechado" or !visivel) return;
    estado = "abrindo";
    t = 0;
    alvo = _jogador;
    aberto_marcar(chave);
    som_em("sfx_bau", x, y, 1, 0);
    global.camera_impact = max(global.camera_impact, 3);
}

// ---------------------------------------------------------------------
// ARENA: muralhas mágicas que fecham uma área (mini-boss e boss)
// ---------------------------------------------------------------------
// Ergue as duas muralhas em _x1 e _x2. Retorna [esquerda, direita].
function arena_fechar(_x1, _x2, _y_chao, _dono)
{
    var _e = instance_create_depth(_x1, _y_chao, -60, obj_parede_magica);
    var _d = instance_create_depth(_x2, _y_chao, -60, obj_parede_magica);
    _e.dono = _dono; _e.lado = -1;
    _d.dono = _dono; _d.lado = 1;
    with (_e) parede_erguer();
    with (_d) parede_erguer();
    global.cam_lim_esq = _x1 - 30;
    global.cam_lim_dir = _x2 + 30;
    som("sfx_portal", 0.9, 0);
    global.camera_impact = max(global.camera_impact, 8);
    return [_e, _d];
}

function arena_abrir(_dono)
{
    with (obj_parede_magica) if (dono == _dono) parede_baixar();
    global.cam_lim_esq = 0;
    global.cam_lim_dir = room_width;
}

// Posição x mais próxima dentro da arena ativa do dono (ou _x se não houver)
function arena_limitar_x(_x, _margem = 30)
{
    var _r = _x;
    with (obj_parede_magica)
    {
        if (!ativa) continue;
        if (lado < 0) _r = max(_r, x + _margem);
        else _r = min(_r, x - _margem);
    }
    return _r;
}

// ---------------------------------------------------------------------
// LIMPEZA DA SALA AO VOLTAR DO CHECKPOINT
// Os inimigos que ficaram para trás do checkpoint não voltam (corpos e
// orbs não "renascem"); caixotes e segredos já usados também somem.
// ---------------------------------------------------------------------
function sala_limpar_checkpoint()
{
    if (!global.checkpoint_ativo or global.checkpoint_room != room) return;
    var _cx = global.checkpoint_x;
    with (obj_inimigo_base)
    {
        if (!eh_boss and !invocado and object_index != obj_mini_boss and x < _cx - 280) instance_destroy();
    }
    with (obj_mini_boss) if (x < _cx - 280) instance_destroy();
    with (obj_viga_fogo) if (x < _cx - 200) instance_destroy();
}

// ---------------------------------------------------------------------
// ARMADILHAS: ferem o jogador (não dá para defender) e também os inimigos
// _lista = inimigos já atingidos nesta ativação
// ---------------------------------------------------------------------
function armadilha_area(_x1, _y1, _x2, _y2, _dano_jogador, _dano_inimigo, _lista, _forca = 4)
{
    var _p = instance_find(obj_player, 0);
    if (_p != noone and !_p.morto and rectangle_in_rectangle(_x1, _y1, _x2, _y2, _p.bbox_left, _p.bbox_top, _p.bbox_right, _p.bbox_bottom))
    {
        var _antes = _p.vida;
        with (_p) levar_dano(max(1, round(_dano_jogador * dif_dano_inimigo())), (_x1 + _x2) / 2, false, _forca, noone);
        if (_p.vida < _antes and !_p.morto) _p.velv = min(_p.velv, -3);
    }
    if (_dano_inimigo <= 0) return;
    var _l = ds_list_create();
    var _n = collision_rectangle_list(_x1, _y1, _x2, _y2, obj_inimigo_base, false, true, _l, false);
    for (var _i = 0; _i < _n; _i++)
    {
        var _e = _l[| _i];
        if (_e.morrendo or !_e.ativo or _e.eh_boss or array_tem(_lista, _e)) continue;
        array_push(_lista, _e);
        with (_e) levar_dano(_dano_inimigo, (_x1 + _x2) / 2, false, 3, noone);
    }
    ds_list_destroy(_l);
}

// Chamas desenhadas por código (fogo no chão, vigas e casas)
// _larg = largura, _alt = altura das chamas, _t = tempo, _forca 0..1
function desenhar_chamas(_x, _y, _larg, _alt, _t, _forca = 1, _semente = 0)
{
    if (_forca <= 0.01) return;
    gpu_set_blendmode(bm_add);
    var _n = max(3, round(_larg / 7));
    for (var _i = 0; _i < _n; _i++)
    {
        var _fx = _x - _larg / 2 + (_i + 0.5) * _larg / _n;
        var _ru = sin(_t * 0.21 + _i * 1.7 + _semente) * 0.5 + sin(_t * 0.37 + _i * 2.9 + _semente * 2) * 0.5;
        var _h = _alt * _forca * (0.6 + 0.4 * (0.5 + 0.5 * _ru)) * (1 - abs((_i + 0.5) / _n - 0.5) * 0.9);
        var _w = _larg / _n * 1.5;
        var _ox = sin(_t * 0.3 + _i) * 2;
        draw_set_alpha(0.55 * _forca);
        draw_set_color(make_color_rgb(200, 40, 10));
        draw_triangle(_fx - _w, _y, _fx + _w, _y, _fx + _ox * 1.5, _y - _h * 1.15, false);
        draw_set_alpha(0.7 * _forca);
        draw_set_color(make_color_rgb(255, 120, 30));
        draw_triangle(_fx - _w * 0.7, _y, _fx + _w * 0.7, _y, _fx + _ox, _y - _h * 0.85, false);
        draw_set_alpha(0.8 * _forca);
        draw_set_color(make_color_rgb(255, 220, 120));
        draw_triangle(_fx - _w * 0.35, _y, _fx + _w * 0.35, _y, _fx + _ox * 0.5, _y - _h * 0.45, false);
    }
    // brilho no chão
    draw_set_alpha(0.25 * _forca);
    draw_set_color(make_color_rgb(255, 110, 30));
    draw_ellipse(_x - _larg * 0.7, _y - 6, _x + _larg * 0.7, _y + 4, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
