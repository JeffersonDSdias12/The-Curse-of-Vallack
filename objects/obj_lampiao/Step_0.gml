event_inherited();
var _dt = global.dt;
t += _dt;
// vento da tempestade (obj_clima) + um balanço lento
var _vento = -1.5;
with (obj_clima) _vento = vento;
var _alvo = _vento * 3 + 3 * sin(t / 47 + semente);     // o vento sopra para a esquerda
angv += (_alvo - ang) * 0.025 * _dt;
angv *= power(0.965, _dt);
ang = clamp(ang + angv * _dt, -50, 50);
if (pisca > 0) pisca -= _dt;
