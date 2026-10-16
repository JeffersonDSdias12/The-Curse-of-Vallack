var _dt = global.dt;
t += _dt;
switch (estado)
{
    case "baixo":
        sobe = max(0, sobe - 0.2 * _dt);
        if (t >= 110) { estado = "aviso"; t = 0; }
    break;
    case "aviso":
        sobe = 0.18 + 0.06 * sin(t * 1.3);
        if (random(1) < 0.25 * _dt) fx_em("poeira", x + random_range(-12, 12), y, 0.25);
        if (t >= 38) { estado = "alto"; t = 0; atingidos = []; som_em("sfx_espinhos", x, y, 0.8); }
    break;
    case "alto":
        sobe = min(1, sobe + 0.35 * _dt);
        if (sobe > 0.6) armadilha_area(x - 15, y - 13 * sobe, x + 15, y, 14, 30, atingidos, 3);
        if (t >= 70) { estado = "descendo"; t = 0; }
    break;
    case "descendo":
        sobe = max(0, sobe - 0.08 * _dt);
        if (sobe <= 0) { estado = "baixo"; t = 0; }
    break;
}
