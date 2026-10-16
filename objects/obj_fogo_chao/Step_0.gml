var _dt = global.dt;
t += _dt;
// a cada 3 s as chamas sobem por 1 s
var _ciclo = t mod 180;
var _alvo = (_ciclo > 130) ? 1 : 0.35;
if (_ciclo > 118 and _ciclo < 130 and random(1) < 0.5 * _dt) fx_em("brasas", x + random_range(-larg / 2, larg / 2), y - 4, 0.7);
forte = lerp(forte, _alvo, 0.15);
if (_ciclo < _dt) { atingidos = []; som_em("fogo_whoosh", x, y, 0.55); }
// fere: forte = mais alto e mais dano
if (forte > 0.6) armadilha_area(x - larg / 2, y - 40 * forte, x + larg / 2, y, 12, 20, atingidos, 3);
else if (floor((t - _dt) / 50) != floor(t / 50))
{
    var _baixo = [];
    armadilha_area(x - larg / 2 + 4, y - 12, x + larg / 2 - 4, y, 4, 0, _baixo, 1);
}
if (random(1) < 0.06 * _dt) fx_em("fumaca", x + random_range(-larg / 2, larg / 2), y - 16, 0.6);
if (random(1) < 0.08 * _dt) fx_em("brasas", x + random_range(-larg / 2, larg / 2), y - 6, 0.4);
