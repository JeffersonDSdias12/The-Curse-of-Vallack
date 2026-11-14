var _dt = global.dt;
t += _dt;
vy += g * _dt;
x += vx * _dt;
y += vy * _dt;
ang += 12 * _dt;
var _p = instance_find(obj_player, 0);
if (_p != noone and !_p.morto and point_in_rectangle(x, y, _p.bbox_left - 4, _p.bbox_top - 4, _p.bbox_right + 4, _p.bbox_bottom + 4))
{
    var _int = false;
    with (_p) _int = jogador_intangivel();
    if (!_int)
    {
        with (_p) levar_dano(other.dano, other.x, false, 2, noone);
        estourar();
        exit;
    }
}
if (place_meeting(x, y, obj_chao) or y > room_height) { estourar(); exit; }
if (t > 300) instance_destroy();
