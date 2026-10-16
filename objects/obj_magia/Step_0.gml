var _dt = global.dt;
t += _dt;

// ===== ESTOURANDO =====
if (estado == "fim")
{
    fim_t += _dt;
    if (fim_t >= 16) instance_destroy();
    exit;
}

var _p = instance_find(obj_player, 0);
var _vivo = (_p != noone) and !_p.morto;
var _intang = false;
if (_vivo) with (_p) _intang = jogador_intangivel();

// ===== TEIA GRUDADA NO CHÃO: armadilha pegajosa =====
if (estado == "chao")
{
    vida_chao -= _dt;
    if (vida_chao <= 0) { instance_destroy(); exit; }
    if (_vivo and !_intang and _p.enredado <= 0 and _p.teia_imune <= 0
        and rectangle_in_rectangle(x - 22, y - 8, x + 22, y + 2, _p.bbox_left, _p.bbox_top, _p.bbox_right, _p.bbox_bottom) > 0)
    {
        jogador_enredar(45);
        vida_chao = min(vida_chao, 20);          // a teia se rasga
    }
    exit;
}

// ===== MOVIMENTO =====
switch (tipo)
{
    case "orbe":
        // persegue Twilight só no começo (dá para desviar)
        if (!refletida and t < 40 and _vivo)
        {
            var _alvo_ang = point_direction(x, y, _p.x, _p.y - 34);
            var _sp = point_distance(0, 0, vx, vy);
            var _a = point_direction(0, 0, vx, vy);
            _a += clamp(angle_difference(_alvo_ang, _a), -1.3 * _dt, 1.3 * _dt);
            vx = lengthdir_x(_sp, _a);
            vy = lengthdir_y(_sp, _a);
        }
    break;
    case "teia":
        vy += 0.12 * _dt;
    break;
}
x += vx * _dt;
y += vy * _dt;
dist += point_distance(0, 0, vx, vy) * _dt;
if (vx != 0 or vy != 0) ang = point_direction(0, 0, vx, vy);

// ===== REBATIDA POR TWILIGHT: fere e prende os inimigos =====
if (refletida)
{
    var _e = collision_rectangle(x - 8, y - 8, x + 8, y + 8, obj_inimigo_base, false, true);
    if (_e != noone and !_e.morrendo and _e.ativo)
    {
        var _gw = { chave: (tipo == "teia") ? "teia" : "orbe", especial: false, pesado: true, porcento: 0, dano: 0, combo: 0 };
        var _pc = (tipo == "teia") ? 0.15 : 0.5;
        var _dn = _e.eh_boss ? max(1, round(_e.vida_max * 0.03)) : max(1, round(_e.vida_max * _pc));
        var _at = (tipo == "teia") ? 150 : 90;
        with (_e)
        {
            levar_dano(_dn, other.x - other.vx, false, 5, noone, _gw);
            if (!morrendo) inimigo_atordoar(_at, true);
        }
        if (instance_exists(_e) and variable_instance_exists(_e, "rachada_t")) _e.rachada_t = 180;
        fx_em("faiscas_golpe", x, y, 1, sign(vx));
        som_em("hit_2", x, y, 0.9);
        estourar();
        exit;
    }
}
// ===== ACERTA TWILIGHT =====
else if (_vivo and !_intang and !atingiu)
{
    var _toca = false;
    if (tipo == "onda") _toca = rectangle_in_rectangle(x - 16, y - 30, x + 16, y, _p.bbox_left, _p.bbox_top, _p.bbox_right, _p.bbox_bottom) > 0;
    else _toca = point_in_rectangle(x, y, _p.bbox_left - 5, _p.bbox_top - 5, _p.bbox_right + 5, _p.bbox_bottom + 5);
    if (_toca)
    {
        var _frente = (x == _p.x) or (sign(x - _p.x) == _p.facing);
        // APARAR: volta contra quem lançou (a onda roxa não dá para aparar)
        if (tipo != "onda" and _p.janela_aparar > 0 and _frente)
        {
            jogador_aparou(noone);
            refletida = true;
            var _sp2 = max(6, point_distance(0, 0, vx, vy) * 1.4);
            var _ang2 = ang + 180;
            if (instance_exists(dono)) _ang2 = point_direction(x, y, dono.x, dono.y - 40);
            vx = lengthdir_x(_sp2, _ang2);
            vy = lengthdir_y(_sp2, _ang2);
            if (tipo == "teia") vy -= 1.2;
            dist = 0;
            alcance = 900;
            exit;
        }
        // DEFESA MÁGICA: segura o orbe e a teia
        if (tipo != "onda" and _p.bloqueando and _frente)
        {
            jogador_bloqueou(x);
            estourar();
            exit;
        }
        // acertou
        var _bloq = (tipo != "onda");
        var _vida_antes = _p.vida;
        var _armadura = _p.armadura;
        with (_p) levar_dano(other.dano, other.x, _bloq, (other.tipo == "onda") ? 6 : 3, noone);
        if (tipo == "teia" and _p.vida < _vida_antes and !_armadura and !_p.morto)
        {
            var _q = 90;
            if (instance_exists(dono) and variable_instance_exists(dono, "teia_quadros")) _q = dono.teia_quadros;
            jogador_enredar(_q);
        }
        if (tipo == "onda") atingiu = true;
        else { estourar(); exit; }
    }
}

// ===== CENÁRIO E ALCANCE =====
if (tipo == "onda")
{
    var _sv = (vx >= 0) ? 1 : -1;
    if (position_meeting(x + _sv * 16, y - 14, obj_chao) or !position_meeting(x, y + 4, obj_chao) or dist >= alcance) estourar();
}
else if (position_meeting(x, y, obj_chao))
{
    if (tipo == "teia" and !refletida)
    {
        // gruda no chão e vira armadilha
        estado = "chao";
        vida_chao = 240;
        vx = 0;
        vy = 0;
        var _gy = y;
        while (_gy > y - 40 and position_meeting(x, _gy - 1, obj_chao)) _gy -= 1;
        y = _gy;
        som_em("teia_prende", x, y, 0.4);
    }
    else estourar();
}
else if (dist >= alcance or y > room_height + 50) estourar();
