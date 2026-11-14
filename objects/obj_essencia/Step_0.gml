var _dt = global.dt;
t += _dt;
var _p = instance_find(obj_player, 0);
if (t < espera or _p == noone or _p.morto)
{
    vy += 0.25 * _dt;
    vx *= power(0.97, _dt);
    if (place_meeting(x + vx * _dt, y, obj_chao)) vx = -vx * 0.5;
    if (vy > 0 and position_meeting(x, y + vy * _dt + 6, obj_chao))
    {
        vy = -abs(vy) * 0.45;
        if (abs(vy) < 0.8) vy = 0;
    }
    x += vx * _dt;
    y += vy * _dt;
    exit;
}
var _tx = _p.x;
var _ty = (_p.bbox_top + _p.bbox_bottom) / 2;
var _vel = min(13, 3 + (t - espera) * 0.25);
if (point_distance(x, y, _tx, _ty) <= _vel * _dt + 6)
{
    essencia_ganhar(1);
    som("essencia", 0.5, 0.04);
    instance_destroy();
    exit;
}
var _ang = point_direction(x, y, _tx, _ty);
vx = lerp(vx, lengthdir_x(_vel, _ang), 0.2);
vy = lerp(vy, lengthdir_y(_vel, _ang), 0.2);
x += vx * _dt;
y += vy * _dt;
