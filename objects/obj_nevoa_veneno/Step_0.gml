var _dt = global.dt;
t += _dt;
if (aviso_t > 0) aviso_t -= _dt;
var _p = instance_find(obj_player, 0);
if (_p == noone or _p.morto) exit;
if (abs(_p.x - x) < larg + 6 and _p.y > y - alt and _p.y <= y + 4)
{
    if (_p.rolando) exit;                  // rolando, a névoa não segura Twilight
    var _lado = (_p.x < x) ? -1 : 1;
    _p.x = x + _lado * (larg + 7);
    if (_p.tempo_invencivel <= 0)
    {
        with (_p) levar_dano(other.dano, other.x, false, 0, noone);
        som_em("veneno_dano", x, y, 0.8);
    }
    _p.velh = 0;
    _p.empurrao = _lado * 3.5;
    aviso_t = 120;
}
