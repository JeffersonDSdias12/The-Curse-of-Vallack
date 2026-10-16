var _dt = global.dt;
if (atraso > 0) { atraso -= _dt; exit; }
t += _dt;
switch (estado)
{
    case "aviso":
        if (random(1) < 0.3 * _dt) fx_em("poeira", x + random_range(-14, 14), y, 0.3);
        if (t >= 44) { estado = "sobe"; t = 0; som_em("dest_pedra", x, y, 0.6); global.camera_impact = max(global.camera_impact, 6); fx_em("lascas", x, y - 6, 0.7); }
    break;
    case "sobe":
        sobe = min(1, sobe + 0.25 * _dt);
        if (sobe > 0.5) armadilha_area(x - 13, y - 64 * sobe, x + 13, y, dano / max(0.1, dif_dano_inimigo()), 0, atingidos, 5);
        if (t >= 46) { estado = "desce"; t = 0; }
    break;
    case "desce":
        sobe = max(0, sobe - 0.05 * _dt);
        if (sobe <= 0) instance_destroy();
    break;
}
