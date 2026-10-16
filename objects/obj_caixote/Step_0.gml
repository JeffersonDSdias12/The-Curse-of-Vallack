event_inherited();
var _dt = global.dt;

// liga o baú escondido dentro dele (colocado no mesmo lugar na sala)
if (!ligado)
{
    ligado = true;
    var _b = instance_nearest(x, y, obj_bau);
    if (_b != noone and abs(_b.x - x) < 20 and abs(_b.y - y) < 40 and _b.estado == "fechado")
    {
        bau = _b;
        conteudo = "bau";
        _b.visivel = false;
    }
}

// gravidade: cai quando não há nada embaixo (o próprio bloco sai da frente)
if (instance_exists(solido))
{
    solido.y += 100000;
    var _livre = !place_meeting(x, y + 1, obj_chao);
    if (_livre or velv != 0)
    {
        velv = min(velv + 0.4 * _dt, 10);
        var _mv = velv * _dt;
        if (place_meeting(x, y + _mv, obj_chao))
        {
            var _s = 0;
            while (!place_meeting(x, y + 1, obj_chao) and _s < 64) { y += 1; _s += 1; }
            if (velv > 3) { som_em("dest_quique", x, y, 0.5); fx_em("poeira", x, y, 0.5); }
            velv = 0;
        }
        else y += _mv;
    }
    solido.y -= 100000;
    solido_mover(solido, x + dx_solido, y + dy_solido);
    if (bau != noone and instance_exists(bau) and !bau.visivel) { bau.x = x; bau.y = y; }
}
if (y > room_height + 100) instance_destroy();
