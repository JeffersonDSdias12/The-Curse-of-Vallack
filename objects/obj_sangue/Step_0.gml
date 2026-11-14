var _dt = global.dt;
t += _dt;
var _p = instance_find(obj_player, 0);
if (_p == noone or _p.morto or _p.furia_modo) { instance_destroy(); exit; }
if (t < espera)
{
    vy += 0.18 * _dt;
    vx *= power(0.95, _dt);
    x += vx * _dt;
    y += vy * _dt;
    exit;
}
// a lâmina fica à frente do peito de Twilight
var _tx = _p.x + _p.facing * 20;
var _ty = _p.y - 44;
var _vel = min(12, 2 + (t - espera) * 0.3);
if (point_distance(x, y, _tx, _ty) <= _vel * _dt + 5)
{
    with (_p) furia_ganhar(other.valor);
    if (global.orb_som_t <= 0) { som("sangue_lamina", 0.25, 0.1); global.orb_som_t = 4; }
    instance_destroy();
    exit;
}
var _ang = point_direction(x, y, _tx, _ty);
vx = lerp(vx, lengthdir_x(_vel, _ang), 0.25);
vy = lerp(vy, lengthdir_y(_vel, _ang), 0.25);
x += vx * _dt;
y += vy * _dt;
