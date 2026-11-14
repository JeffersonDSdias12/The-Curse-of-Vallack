var _dt = global.dt;
t += _dt;
var _p = instance_find(obj_player, 0);
if (_p != noone and !_p.morto and abs(_p.x - x) < larg and abs(_p.y - y) < 14 and _p.tempo_invencivel <= 0)
{
    var _int = false;
    with (_p) _int = jogador_intangivel();
    if (!_int)
    {
        with (_p) levar_dano(other.dano, other.x, false, 0.5, noone);
        som_em("veneno_dano", x, y, 0.7);
    }
}
if (t >= vida) instance_destroy();
