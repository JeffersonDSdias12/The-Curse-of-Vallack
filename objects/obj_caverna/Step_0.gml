var _dt = global.dt;
if (cenario_dist_jogador(x, y - 60) > 700) exit;
fumaca_t -= _dt;
if (fumaca_t <= 0)
{
    fumaca_t = irandom_range(14, 30) / max(0.5, global.cfg_qualidade);
    fx_em("fumaca_maldita", x + random_range(-26, 26), y - random_range(14, 70), 0.45, 1, depth - 1);
}
