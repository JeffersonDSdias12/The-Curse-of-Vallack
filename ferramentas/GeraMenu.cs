// =====================================================================
//  GeraMenu — a mancha de sangue pintada a pincel que fica atrás da logo
//  no menu inicial (v1.14). Saída: mancha_sangue.png (fundo transparente)
//  em datafiles/ (PC) e godot/assets/data/ (Android). Usado por
//  ferramentas/gerar_menu.ps1.
// =====================================================================
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class GeraMenu
{
    static double Hs(int x, int y, int s)
    {
        unchecked
        {
            uint h = (uint)(x * 374761393 + y * 668265263 + s * 982451653);
            h = (h ^ (h >> 13)) * 1274126177u;
            h ^= h >> 16;
            return (h & 0xFFFFFF) / 16777216.0;
        }
    }
    // ruído suave 1D (interpola valores aleatórios a cada "passo" px)
    static double Ruido(double x, double passo, int s)
    {
        int i = (int)Math.Floor(x / passo);
        double f = x / passo - i;
        f = f * f * (3 - 2 * f);
        return Hs(i, 0, s) * (1 - f) + Hs(i + 1, 0, s) * f;
    }

    public static string Gerar(string pastaGm, string pastaGd)
    {
        int W = 960, H = 400;
        var px = new int[W * H];
        double x0 = 24, x1 = 910, cy = 160;
        var rng = new Random(77);
        // a pincelada principal: grossa à esquerda, afinando em fiapos à direita
        for (int x = 0; x < W; x++)
        {
            double u = (x - x0) / (x1 - x0);
            if (u < 0 || u > 1) continue;
            double grosso = 220 * Math.Pow(1 - u, 0.5) * (0.86 + 0.28 * Ruido(x, 60, 3)) * Math.Min(1, u * 14 + 0.25);
            double topo = cy - grosso * 0.52 + 14 * (Ruido(x, 24, 5) - 0.5) + 30 * (Ruido(x, 140, 6) - 0.5);
            double baixo = cy + grosso * 0.48 + 12 * (Ruido(x, 20, 7) - 0.5) + 26 * (Ruido(x, 120, 8) - 0.5);
            for (int y = (int)topo; y <= (int)baixo; y++)
            {
                if (y < 0 || y >= H) continue;
                // fiapos do pincel no fim da pincelada
                double fio = Hs(0, y / 3, 11);
                if (u > 0.55 && fio < (u - 0.55) * 1.8) continue;
                double borda = Math.Min(y - topo, baixo - y);
                double tinta = 0.80 + 0.26 * Ruido(x + (y / 4) * 53.0, 46, 13) - 0.06 * Hs(x / 2, y / 2, 17);
                int r = (int)(138 * tinta), g = (int)(10 * tinta), b = (int)(14 * tinta);
                if (borda < 3) { r = r * 6 / 10; g = g * 6 / 10; b = b * 6 / 10; }          // borda mais escura (tinta acumulada)
                int a = borda < 1.5 ? 170 : 238;
                px[y * W + x] = (a << 24) | (Math.Min(255, r) << 16) | (Math.Min(255, g) << 8) | Math.Min(255, b);
            }
        }
        // escorridos: pingos descendo da borda de baixo
        for (int k = 0; k < 16; k++)
        {
            double dx = x0 + 30 + rng.NextDouble() * 640;
            double u = (dx - x0) / (x1 - x0);
            double grosso = 220 * Math.Pow(1 - u, 0.5);
            double ini = cy + grosso * 0.40;
            double comp = 18 + rng.NextDouble() * (130 * (1 - u) + 20);
            double larg = 2.5 + rng.NextDouble() * 4.5 * (1 - u * 0.6);
            for (double y = ini; y < ini + comp; y += 0.5)
            {
                double w = larg * (1 - 0.5 * (y - ini) / comp);
                for (int x = (int)(dx - w); x <= (int)(dx + w); x++)
                    if (x >= 0 && x < W && y >= 0 && y < H) px[(int)y * W + x] = (232 << 24) | (112 << 16) | (8 << 8) | 12;
            }
            // gota na ponta
            double gr = larg * 0.95, gy = ini + comp;
            for (int y = (int)(gy - gr); y <= (int)(gy + gr); y++)
                for (int x = (int)(dx - gr); x <= (int)(dx + gr); x++)
                    if (x >= 0 && x < W && y >= 0 && y < H && (x - dx) * (x - dx) + (y - gy) * (y - gy) <= gr * gr)
                        px[y * W + x] = (236 << 24) | (96 << 16) | (6 << 8) | 10;
        }
        // respingos em volta
        for (int k = 0; k < 170; k++)
        {
            double ang = rng.NextDouble() * Math.PI * 2;
            double sx = x0 + rng.NextDouble() * 760, sy = cy + Math.Sin(ang) * (90 + rng.NextDouble() * 70);
            double rr = 0.8 + Math.Pow(rng.NextDouble(), 3) * 7;
            for (int y = (int)(sy - rr); y <= (int)(sy + rr); y++)
                for (int x = (int)(sx - rr); x <= (int)(sx + rr); x++)
                    if (x >= 0 && x < W && y >= 0 && y < H && (x - sx) * (x - sx) + (y - sy) * (y - sy) <= rr * rr)
                        px[y * W + x] = (220 << 24) | (120 << 16) | (10 << 8) | 14;
        }
        using (var bmp = new Bitmap(W, H, PixelFormat.Format32bppArgb))
        {
            var d = bmp.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(px, 0, d.Scan0, px.Length);
            bmp.UnlockBits(d);
            bmp.Save(System.IO.Path.Combine(pastaGm, "mancha_sangue.png"), ImageFormat.Png);
            bmp.Save(System.IO.Path.Combine(pastaGd, "mancha_sangue.png"), ImageFormat.Png);
        }
        return "mancha_sangue.png " + W + "x" + H;
    }
}
