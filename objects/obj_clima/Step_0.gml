var _dt = global.dt;
t += _dt;
var _vx = 0, _vw = 960, _vy = 0, _vh = 420;
if (view_camera[0] != -1)
{
    _vx = camera_get_view_x(view_camera[0]);
    _vy = camera_get_view_y(view_camera[0]);
    _vw = camera_get_view_width(view_camera[0]);
    _vh = camera_get_view_height(view_camera[0]);
}

// chão da sala (medido de novo se ainda não existia quando a chuva foi criada)
if (chao_y < 0) chao_y = chao_da_sala();
var _chao = (chao_y >= 0) ? chao_y : _vy + _vh + 30;

// som da chuva (loop)
ambiente("amb_chuva", 0.55);

// ----- vento e rajadas -----
prox_rajada -= _dt;
if (prox_rajada <= 0) { rajada = 1; prox_rajada = irandom_range(360, 800); }
rajada = max(0, rajada - 0.006 * _dt);
vento = vento_base - 2.6 * sin(rajada * pi) - 0.4 * sin(t / 90);

// ----- chuva -----
for (var _i = 0; _i < array_length(gotas); _i++)
{
    var _g = gotas[_i];
    _g.y += _g.vel * _dt;
    _g.x += vento * (_g.perto ? 1.3 : 1) * _dt;
    if (_g.y >= _chao + (_g.perto ? 10 : 0) + random(10))
    {
        if (chao_y >= 0 and global.cfg_qualidade > 0 and random(1) < 0.45 and _g.x > _vx and _g.x < _vx + _vw)
            array_push(respingos, { x: _g.x, y: chao_y + random_range(-2, 7), t: 0, g: _g.perto });
        gotas[_i] = nova_gota(false);
    }
    else if (_g.x < _vx - 140 or _g.x > _vx + _vw + 200 or _g.y > _vy + _vh + 40)
    {
        gotas[_i] = nova_gota(false);
    }
}
for (var _r = array_length(respingos) - 1; _r >= 0; _r--)
{
    respingos[_r].t += _dt;
    if (respingos[_r].t > 12) array_delete(respingos, _r, 1);
}

// ----- relâmpagos (clarão duplo) e trovões com atraso -----
if (relampago > 0) relampago -= _dt;
prox_relampago -= _dt;
if (prox_relampago <= 0)
{
    var _perto = random(1) < 0.4;
    relampago = _perto ? 34 : 24;
    relampago_max = relampago;
    prox_relampago = irandom_range(300, 720);
    global.camera_impact = max(global.camera_impact, _perto ? 6 : 3);
    raio_criar(_vx, _vy, _vw);
    // o som chega depois da luz
    array_push(trovoes, [_perto ? irandom_range(8, 20) : irandom_range(40, 95), _perto ? 1 : 0.6]);
}
for (var _k = array_length(trovoes) - 1; _k >= 0; _k--)
{
    trovoes[_k][0] -= global.dt_real;
    if (trovoes[_k][0] <= 0)
    {
        som("sfx_trovao_" + string(irandom_range(1, 3)), trovoes[_k][1], 0.08);
        if (trovoes[_k][1] >= 1) global.terremoto = max(global.terremoto, 8);
        array_delete(trovoes, _k, 1);
    }
}
