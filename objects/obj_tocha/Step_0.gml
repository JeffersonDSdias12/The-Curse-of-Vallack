var _dt = global.dt;
if (!acesa)
{
    if (cenario_dist_jogador(x, y) < 300)
    {
        acesa = true;
        som_em("tocha_acender", x, y, 0.8);
        fx_em("brasas", x, y - 4, 0.7, 1, depth - 1);
        fx_em("faiscas_golpe", x, y - 2, 0.45, choose(-1, 1), depth - 1);
    }
    exit;
}
luz = min(1, luz + 0.05 * _dt);
brasa_t -= _dt;
if (brasa_t <= 0)
{
    brasa_t = irandom_range(16, 34) / max(0.5, global.cfg_qualidade);
    if (cenario_na_tela(x, x, 0)) fx_em("brasas", x, y - 8, 0.22, 1, depth - 1);
}
