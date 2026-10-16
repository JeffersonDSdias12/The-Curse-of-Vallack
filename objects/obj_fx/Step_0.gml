var _dt = global.dt;
t += _dt;

// faíscas: continuam saindo do chão no começo
if (tipo == "faiscas_tela" and t < 34 and global.cfg_qualidade > 0 and random(1) < 0.6 * _dt) faiscas_emitir(3);

if (flash > 0) flash -= _dt;
for (var _i = array_length(parts) - 1; _i >= 0; _i--)
{
    var _p = parts[_i];
    if (gen)
    {
        _p.vy += _p.g * _dt;
        _p.x += _p.vx * _dt;
        _p.y += _p.vy * _dt;
        _p.rot += _p.vr * _dt;
        if (_p.forma == "fumo") { _p.r += 0.12 * _dt; _p.vx += 0.01 * _dt; }
        else if (_p.forma == "maldita")
        {
            // fumaça da maldição: cresce, sobe ondulando e freia
            _p.r += 0.16 * _dt;
            _p.vx += sin((t + _p.rot) * 0.09) * 0.03 * _dt;
            _p.vx *= power(0.975, _dt);
            _p.vy *= power(0.985, _dt);
        }
        else if (_p.forma != "linha" and _p.g > 0 and _p.vy > 0 and position_meeting(_p.x, _p.y + _p.r, obj_chao))
        {
            // quica e para no chão
            _p.vy = -_p.vy * 0.25;
            _p.vx *= 0.5;
            _p.vr *= 0.5;
            if (abs(_p.vy) < 0.6) { _p.vy = 0; _p.g = 0; }
        }
        _p.v -= _dt;
        if (_p.v <= 0) array_delete(parts, _i, 1);
        continue;
    }
    switch (tipo)
    {
        case "poeira":
            _p.x += _p.vx * _dt;
            _p.y += _p.vy * _dt;
            _p.vx *= power(0.93, _dt);
            _p.r += 0.25 * _dt;
        break;
        case "faiscas_tela":
            _p.x += (_p.vx + sin((t + _p.fase) / 9) * 0.35) * _dt;
            _p.y += _p.vy * _dt;
            _p.vy *= power(0.995, _dt);
        break;
        case "carga":
            _p.d = max(0, _p.d - 2.4 * _dt);
            _p.ang += 6 * _dt;
            _p.x = x + lengthdir_x(_p.d, _p.ang);
            _p.y = y + lengthdir_y(_p.d, _p.ang);
        break;
        case "pedras":
            _p.vy += 0.3 * _dt;
            _p.x += _p.vx * _dt;
            _p.y += _p.vy * _dt;
            _p.rot += _p.vr * _dt;
        break;
    }
    _p.v -= _dt;
    if (_p.v <= 0) array_delete(parts, _i, 1);
}

if (t >= vida and array_length(parts) == 0) instance_destroy();
if (t >= vida + 200) instance_destroy();
