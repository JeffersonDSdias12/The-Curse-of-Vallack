var _dt = global.dt;
t += _dt;
if (choque > 0) choque -= _dt;
switch (estado)
{
    case "subindo":
        sobe = min(1, sobe + 0.05 * _dt);
        if (sobe >= 1) estado = "ativa";
    break;
    case "descendo":
        sobe = max(0, sobe - 0.03 * _dt);
        if (sobe <= 0) { instance_destroy(); exit; }
    break;
}
if (!ativa) exit;
// quem encosta é jogado de volta para dentro da arena
var _dentro = -lado;      // direção para dentro
with (obj_inimigo_base)
{
    if (morrendo or eh_boss) continue;
    if (abs(x - other.x) < 22 and y > other.y - other.altura)
    {
        empurrao = _dentro * 5;
        x += _dentro * 2;
        other.choque = 12;
    }
}
var _p = instance_find(obj_player, 0);
if (_p != noone and abs(_p.x - x) < 18 and _p.y > y - altura)
{
    _p.empurrao = _dentro * 3;
    if (choque <= 0) som_em("sfx_bloqueio", x, y, 0.4, 0.2);
    choque = 12;
}
