var _dt = global.dt;
if (atraso > 0) { atraso -= _dt; exit; }
if (!som_tocou) { som_tocou = true; som_em("raiz_aviso", x, y, 0.8); }
t += _dt;
switch (estado)
{
    case "aviso":
        if (random(1) < 0.4 * _dt) fx_em("poeira", x + random_range(-16, 16), y, 0.35);
        if (t >= aviso_t) { estado = "sobe"; t = 0; som_em("dest_pedra", x, y, 0.7); global.camera_impact = max(global.camera_impact, 6); fx_em("lascas", x, y - 6, 0.9); }
    break;
    case "sobe":
        sobe = min(1, sobe + 0.25 * _dt);
        if (sobe > 0.5) armadilha_area(x - meia, y - alt * sobe, x + meia, y, dano / max(0.1, dif_dano_inimigo()), 0, atingidos, 5);
        if (t >= 46) { estado = "desce"; t = 0; }
    break;
    case "desce":
        sobe = max(0, sobe - 0.05 * _dt);
        if (sobe <= 0) instance_destroy();
    break;
}
