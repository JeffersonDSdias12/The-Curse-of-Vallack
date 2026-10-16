var _dt = global.dt;
t += _dt;
var _p = instance_find(obj_player, 0);
var _r = (valor >= 25) ? 5 : ((valor >= 5) ? 3.6 : 2.4);

array_push(rastro, [x, y]);
if (array_length(rastro) > 6) array_delete(rastro, 0, 1);

if (t < espera or _p == noone or _p.morto)
{
    // pula e quica no chão
    vy += 0.25 * _dt;
    vx *= power(0.97, _dt);
    if (place_meeting(x + vx * _dt, y, obj_chao)) vx = -vx * 0.5;
    if (vy > 0 and position_meeting(x, y + vy * _dt + _r, obj_chao))
    {
        vy = -abs(vy) * 0.45;
        if (abs(vy) < 0.8) vy = 0;
    }
    x += vx * _dt;
    y += vy * _dt;
    exit;
}

// voa até o peito de Twilight, acelerando
var _tx = _p.x;
var _ty = (_p.bbox_top + _p.bbox_bottom) / 2;
var _d = point_distance(x, y, _tx, _ty);
var _vel = min(14, 3 + (t - espera) * 0.25);
if (_d <= _vel * _dt + 6)
{
    orbs_ganhar(valor);
    // som em sequência sobe de tom (como no God of War)
    if (global.orb_som_t <= 0)
    {
        global.orb_seq = min(global.orb_seq + 1, 10);
        var _s = som("sfx_orb", 0.45, 0);
        if (_s != -1) audio_sound_pitch(_s, 1 + global.orb_seq * 0.04);
        global.orb_som_t = 3;
    }
    instance_destroy();
    exit;
}
var _ang = point_direction(x, y, _tx, _ty);
vx = lerp(vx, lengthdir_x(_vel, _ang), 0.2);
vy = lerp(vy, lengthdir_y(_vel, _ang), 0.2);
x += vx * _dt;
y += vy * _dt;
