var _dt = global.dt;
var _p = instance_find(obj_player, 0);
var _px = (_p != noone) ? _p.x : -10000;
var _dist_fogo = 100000;
var _q = max(0.5, global.cfg_qualidade);
aldeao_t -= _dt;
if (chao_y < 0) chao_y = chao_da_sala();         // chão ainda não medido (sala acabou de abrir)

for (var _i = 0; _i < array_length(casas); _i++)
{
    var _c = casas[_i];
    var _d = abs(_c.x - _px);
    _dist_fogo = min(_dist_fogo, _d + 120);          // as casas ficam ao fundo: som mais baixo
    if (_d > 900) continue;
    // fumaça subindo do telhado
    _c.fumaca -= _dt;
    if (_c.fumaca <= 0)
    {
        _c.fumaca = irandom_range(6, 14) / _q;
        fx_em("fumaca", _c.x + random_range(-_c.l * 0.35, _c.l * 0.35), _c.y + random_range(-6, 10), 1.3, 1, 398);
        if (random(1) < 0.6) fx_em("brasas", _c.x + random_range(-_c.l * 0.4, _c.l * 0.4), _c.y + random_range(0, 30), 0.8, 1, 397);
    }
    // aldeões saem correndo quando Twilight chega perto
    if (chao_y >= 0 and _c.fugiram < _c.fogem and _d < 430 and aldeao_t <= 0)
    {
        aldeao_t = irandom_range(35, 80);
        _c.fugiram += 1;
        var _a = instance_create_depth(_c.x + random_range(-20, 20), chao_y, 396, obj_aldeao);
        _a.dir = (_px < _c.x) ? 1 : -1;            // correm para longe de Twilight
        if (random(1) < 0.25) _a.dir = -_a.dir;
    }
}
// som do fogo: mais alto perto das casas e do fogo no chão
with (obj_fogo_chao) _dist_fogo = min(_dist_fogo, abs(x - _px));
with (obj_viga_fogo) if (estado == "queimando") _dist_fogo = min(_dist_fogo, abs(x - _px));
ambiente("amb_fogo", clamp(1 - (_dist_fogo - 60) / 460, 0, 1) * 0.7);
