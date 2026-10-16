var _dt = global.dt;
if (revelar_t > 0) revelar_t -= _dt;
if (!visivel) exit;

switch (estado)
{
    case "abrindo":
        t += _dt;
        // tampa: quadros 1-3
        image_index = min(3, floor(t / 7) + 1);
        if (t >= 22 and magia_soltas == 0) { fx_em("faiscas_golpe", x, y - 16, 0.8, 1); global.camera_impact = max(global.camera_impact, 4); }
        // a magia sai do baú em fluxo
        if (t >= 22 and magia_soltas < BAU_PARTICULAS)
        {
            var _n = min(BAU_PARTICULAS - magia_soltas, ceil(0.5 * _dt));
            repeat (_n)
            {
                array_push(magia, { x: x + random_range(-8, 8), y: y - 16, vx: random_range(-1.5, 1.5), vy: random_range(-3.8, -2), v: 0, chegou: false });
                magia_soltas += 1;
            }
        }
        if (magia_soltas >= BAU_PARTICULAS and array_length(magia) == 0) estado = "aberto";
    break;
}

// partículas: sobem, depois voam até o peito de Twilight
for (var _i = array_length(magia) - 1; _i >= 0; _i--)
{
    var _m = magia[_i];
    _m.v += _dt;
    if (_m.v < 16 or alvo == noone or !instance_exists(alvo))
    {
        _m.x += _m.vx * _dt;
        _m.y += _m.vy * _dt;
        _m.vy *= power(0.93, _dt);
        _m.vx *= power(0.95, _dt);
        if (_m.v > 200) array_delete(magia, _i, 1);
        continue;
    }
    var _tx = alvo.x;
    var _ty = (alvo.bbox_top + alvo.bbox_bottom) / 2;
    var _d = point_distance(_m.x, _m.y, _tx, _ty);
    var _vel = min(12, 2 + _m.v * 0.12);
    if (_d <= _vel * _dt + 4)
    {
        // chegou: cura aos poucos (jogador.cura_restante)
        with (alvo)
        {
            if (!morto)
            {
                cura_restante += other.cura_total / BAU_PARTICULAS;
                cura_fx = 20;
            }
        }
        if (_i mod 6 == 0) som("sfx_cura", 0.35, 0.1);
        array_delete(magia, _i, 1);
        continue;
    }
    var _ang = point_direction(_m.x, _m.y, _tx, _ty);
    _m.vx = lerp(_m.vx, lengthdir_x(_vel, _ang), 0.25);
    _m.vy = lerp(_m.vy, lengthdir_y(_vel, _ang), 0.25);
    _m.x += _m.vx * _dt;
    _m.y += _m.vy * _dt;
}
