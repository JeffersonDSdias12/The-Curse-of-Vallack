if (view_camera[0] == -1) exit;
var _dt = global.dt;
t += _dt;
var _cam = view_camera[0];
var _vxc = camera_get_view_x(_cam);
var _vw = camera_get_view_width(_cam);
var _vh = camera_get_view_height(_cam);
// parallax leve: o céu distante quase não acompanha a câmera
var _dx = (_vxc - view_ant) * 0.85;
var _dv = _vxc - view_ant;
view_ant = _vxc;

if (fase1)
{
    prox_saraivada -= _dt;
    if (prox_saraivada <= 0)
    {
        prox_saraivada = random_range(420, 840);
        var _n = round(random_range(4, 8) * qtd());
        var _esq = random(1) < 0.5;
        var _lado = _esq ? 1 : -1;
        for (var _i = 0; _i < _n; _i++)
        {
            var _sx = _esq ? (_vw + 20 + random(60)) : (-20 - random(60));
            array_push(flechas, { x: _sx + _i * random_range(6, 14) * _lado, y: _vh * random_range(0.18, 0.32),
                vx: random_range(-3.4, -2.4) * _lado, vy: random_range(-1.3, -0.7), vida: 260 });
        }
    }
    prox_catapulta -= _dt;
    if (prox_catapulta <= 0)
    {
        prox_catapulta = random_range(900, 1600);
        var _esq2 = random(1) < 0.5;
        array_push(bolas, { x: _vw * (_esq2 ? 0.9 : 0.1), y: _vh * 0.55, vx: random_range(-1.6, -1.1) * (_esq2 ? 1 : -1),
            vy: random_range(-2.6, -2.1), vida: 400 });
    }
    for (var _i = array_length(flechas) - 1; _i >= 0; _i--)
    {
        var _f = flechas[_i];
        _f.x += _f.vx * _dt - _dx;
        _f.y += _f.vy * _dt;
        _f.vy += 0.016 * _dt;
        _f.vida -= _dt;
        if (_f.vida <= 0 or _f.y >= _vh * 0.62) array_delete(flechas, _i, 1);
    }
    for (var _i = array_length(bolas) - 1; _i >= 0; _i--)
    {
        var _b = bolas[_i];
        _b.x += _b.vx * _dt - _dx;
        _b.y += _b.vy * _dt;
        _b.vy += 0.012 * _dt;
        _b.vida -= _dt;
        // caiu atrás das colinas: clarão no horizonte
        if (_b.y > _vh * 0.6 and _b.vy > 0)
        {
            _b.vida = 0;
            array_push(claroes, { x: _b.x, vida: 50, vmax: 50 });
        }
        if (_b.vida <= 0) array_delete(bolas, _i, 1);
    }
    for (var _i = array_length(claroes) - 1; _i >= 0; _i--)
    {
        var _c = claroes[_i];
        _c.x -= _dx;
        _c.vida -= _dt;
        if (_c.vida <= 0) array_delete(claroes, _i, 1);
    }
}

// frente: brasas (fase 1, sopradas pelo vento) ou cinzas (fase 2, caindo)
var _max_b = floor(26 * qtd());
if (array_length(brasas) < _max_b and random(1) < 0.35 * _dt)
{
    if (fase1)
        array_push(brasas, { x: random(_vw + 80), y: _vh + 6, vx: random_range(-1.2, -0.4), vy: random_range(-1.1, -0.5),
            r: random_range(0.7, 1.5), vida: random_range(180, 300), vmax: 300, fase: random(10) });
    else
        array_push(brasas, { x: random(_vw), y: -6, vx: random_range(-0.25, 0.25), vy: random_range(0.25, 0.55),
            r: random_range(0.8, 1.6), vida: random_range(420, 600), vmax: 600, fase: random(10) });
}
for (var _i = array_length(brasas) - 1; _i >= 0; _i--)
{
    var _br = brasas[_i];
    _br.x += (_br.vx + sin(t / 40 + _br.fase) * 0.25) * _dt - _dv;
    _br.y += _br.vy * _dt;
    _br.vida -= _dt;
    if (_br.vida <= 0 or _br.y < -20 or _br.y > _vh + 20) array_delete(brasas, _i, 1);
}
