var _dt = global.dt;
if (view_camera[0] == -1) exit;
var _cam = view_camera[0];
var _vx = camera_get_view_x(_cam);
var _vw = camera_get_view_width(_cam);

var _max = (global.cfg_qualidade == 0) ? 0 : (global.cfg_qualidade == 1 ? 18 : 36);
if (array_length(brasas) < _max and random(1) < 0.25 * _dt)
{
    array_push(brasas, {
        x: random_range(_vx, _vx + _vw),
        y: banda_base - random(40),
        vx: random_range(-0.25, 0.25),
        vy: random_range(-0.7, -0.25),
        vida: irandom_range(160, 320),
        vmax: 320
    });
}
for (var _i = array_length(brasas) - 1; _i >= 0; _i--)
{
    var _b = brasas[_i];
    _b.x += (_b.vx + sin((current_time / 600) + _i) * 0.15) * _dt;
    _b.y += _b.vy * _dt;
    _b.vida -= _dt;
    if (_b.vida <= 0 or _b.y < banda_topo - 160) array_delete(brasas, _i, 1);
}
