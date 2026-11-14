var _dt = global.dt;
t += _dt;
ang -= dir * 26 * _dt;
if (fase == "ida")
{
    x += dir * vel * _dt;
    vel -= 0.42 * _dt;
    if (vel <= 0 or place_meeting(x + dir * 10, y, obj_chao) or x < 0 or x > room_width) { fase = "volta"; atingidos = []; vel = 2; }
}
else
{
    if (!instance_exists(dono)) { instance_destroy(); exit; }
    var _tx = dono.x;
    var _ty = dono.y - 40;
    vel = min(12, vel + 0.5 * _dt);
    var _a = point_direction(x, y, _tx, _ty);
    x += lengthdir_x(vel * _dt, _a);
    y += lengthdir_y(vel * _dt, _a);
    if (point_distance(x, y, _tx, _ty) < vel * _dt + 14) { instance_destroy(); exit; }
}
if (t > 240) { instance_destroy(); exit; }
var _l = ds_list_create();
var _n = collision_rectangle_list(x - 16, y - 14, x + 16, y + 14, obj_inimigo_base, false, true, _l, false);
var _g = { chave: "bumerangue", especial: false, pesado: false, porcento: 0, dano: dano, combo: 0, no_ar: false };
for (var _i = 0; _i < _n; _i++)
{
    var _alvo = _l[| _i];
    if (array_tem(atingidos, _alvo) or _alvo.morrendo or !_alvo.ativo) continue;
    array_push(atingidos, _alvo);
    var _d = max(1, round(dano * espada_dano_mult()));
    with (_alvo)
    {
        levar_dano(_d, other.x, true, 1.5, noone, _g);
        if (!morrendo and !eh_boss) inimigo_atordoar(20);
    }
    fx_em("faiscas_golpe", _alvo.x, (_alvo.bbox_top + _alvo.bbox_bottom) / 2, 0.7, dir);
    som_var("hit", 3, 0.6);
    impacto(1);
}
ds_list_clear(_l);
var _nd = collision_rectangle_list(x - 16, y - 14, x + 16, y + 14, obj_destrutivel, false, true, _l, false);
for (var _j = 0; _j < _nd; _j++)
{
    var _de = _l[| _j];
    if (array_tem(atingidos, _de)) continue;
    array_push(atingidos, _de);
    with (_de) destrutivel_bater(1, other.x);
}
ds_list_destroy(_l);
