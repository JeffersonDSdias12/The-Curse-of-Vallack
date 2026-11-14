var _dt = global.dt;
t += _dt;
switch (estado)
{
    case "aviso":
        if (t >= 60) { estado = "varre"; t = 0; som_em("fogo_whoosh", x, y, 0.9); global.camera_impact = max(global.camera_impact, 6); }
    break;
    case "varre":
        ponta += dir * vel * _dt;
        var _p = instance_find(obj_player, 0);
        if (!atingiu and _p != noone and !_p.morto)
        {
            var _x1 = min(ponta, ponta - dir * 40);
            var _x2 = max(ponta, ponta - dir * 40);
            if (rectangle_in_rectangle(_x1, y_chao - alt, _x2, y_chao, _p.bbox_left, _p.bbox_top, _p.bbox_right, _p.bbox_bottom))
            {
                var _int = false;
                with (_p) _int = jogador_intangivel();
                if (!_int)
                {
                    atingiu = true;
                    with (_p) levar_dano(other.dano, other.ponta - other.dir * 30, false, 6, noone);
                }
            }
        }
        if ((dir < 0 and ponta <= x_fim) or (dir > 0 and ponta >= x_fim)) { estado = "recolhe"; t = 0; }
    break;
    case "recolhe":
        ponta -= dir * vel * 1.6 * _dt;
        if ((dir < 0 and ponta >= x_base) or (dir > 0 and ponta <= x_base)) instance_destroy();
    break;
}
