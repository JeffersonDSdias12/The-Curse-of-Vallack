t += global.dt;
if (!ok or camada != "perto") exit;
var _pl = instance_find(obj_player, 0);
var _px = (_pl != noone) ? _pl.x : -10000;
var _dist_fogo = 100000;
var _q = max(0.5, global.cfg_qualidade);
// v1.18: TRAVADAS — casas a até 700 px do herói soltavam fumaça e brasas mesmo
// fora da tela: ~1000 partículas (centenas de obj_fx) vivas o tempo todo.
// Agora só emitem as casas perto da câmera, com um teto de efeitos de ambiente.
#macro VILA_FX_MARGEM 140      // px além da câmera
#macro VILA_FX_TETO   220      // obj_fx de ambiente (prof. 395) no máximo (~600 partículas)
var _ex1 = -100000, _ex2 = 100000;
if (view_camera[0] != -1)
{
    _ex1 = camera_get_view_x(view_camera[0]) - VILA_FX_MARGEM;
    _ex2 = camera_get_view_x(view_camera[0]) + camera_get_view_width(view_camera[0]) + VILA_FX_MARGEM;
}
// v1.19: fumaça e brasas agora são partículas nativas (amb_em, scr_cenario)
amb_atualizar();
var _n_amb = 0;
var _cheio = variable_global_exists("amb_ps") and part_particles_count(global.amb_ps) >= AMB_TETO;
for (var _i = 0; _i < array_length(layout); _i++)
{
    var _l = layout[_i];
    var _p = pecas[$ _l[0]];
    var _s = (array_length(_l) > 6) ? _l[6] : 1;     // v1.17: escala da peça
    var _d = abs(_l[1] + _p.w * _s / 2 - _px);
    if (_l[3] == 1) _dist_fogo = min(_dist_fogo, _d + 100);
    if (_d > 700) continue;
    var _cx = _l[1] + _p.w * _s / 2;
    if (_cheio or _cx < _ex1 or _cx > _ex2) continue;
    var _plano = (array_length(_l) > 5) ? _l[5] : 0;
    if (_plano >= 2) continue;              // fileira mais distante: só o fogo desenhado (economia)
    emissao[_i] -= global.dt;
    if (emissao[_i] > 0) continue;
    emissao[_i] = irandom_range(10, 18) / _q * (_plano == 1 ? 2 : 1);
    var _y0 = _l[2] - _p.h * _s;
    // fumaça saindo das chaminés de verdade de cada casa
    var _ch = _p.chamines;
    if (array_length(_ch) > 0 and random(1) < 0.7)
    {
        var _c = _ch[irandom(array_length(_ch) - 1)];
        amb_em("fumaca", cenario_ax(_p, _l[1], _l[4], _c[0], _s), _y0 + _c[1] * _s, ((_l[3] > 0) ? 1.1 : 0.6) * _s);
    }
    // v1.19: casa em chamas: as brasas sobem de um dos focos de verdade e os
    // rombos soltam fumaça
    var _fcs = variable_struct_exists(_p, "focos") ? _p.focos : [];
    if (_l[3] == 1 and array_length(_fcs) > 0)
    {
        var _fo = _fcs[irandom(array_length(_fcs) - 1)];
        var _u = random(1);
        var _bx = cenario_ax(_p, _l[1], _l[4], lerp(_fo[0], _fo[2], _u), _s);
        var _by = _y0 + ((_fo[5] == 2) ? _fo[1] : lerp(_fo[1], _fo[3], _u)) * _s - _fo[4] * _s * 0.5;
        if (random(1) < 0.7) amb_em("brasas", _bx, _by, 0.8 * _s);
        if (_fo[5] == 1 and random(1) < 0.5) amb_em("fumaca", _bx, _by - 10 * _s, _s);
    }
    // ruína: brasas e fumaça saindo dos escombros
    else if (_l[3] > 0 and array_length(_p.fogos) > 0)
    {
        var _f = _p.fogos[0];
        var _fx = cenario_ax(_p, _l[1], _l[4], _f[0], _s);
        if (random(1) < 0.7) amb_em("brasas", _fx + random_range(-_f[2] * 0.4, _f[2] * 0.4) * _s, _y0 + _f[1] * _s, 0.8 * _s);
        if (_l[3] == 2 and random(1) < 0.6) amb_em("fumaca", _fx + random_range(-_f[2] * 0.3, _f[2] * 0.3) * _s, _y0 + (_f[1] + 4) * _s, _s);
    }
}
// som do fogo: mais alto perto das casas queimando e do fogo no chão
with (obj_fogo_chao) _dist_fogo = min(_dist_fogo, abs(x - _px));
with (obj_viga_fogo) if (estado == "queimando") _dist_fogo = min(_dist_fogo, abs(x - _px));
with (obj_tocha) if (acesa) _dist_fogo = min(_dist_fogo, abs(x - _px) + 140);
ambiente("amb_fogo", clamp(1 - (_dist_fogo - 60) / 460, 0, 1) * 0.7);
