// Mede a cor de cada animação (pasta de quadros PNG): média de R, G e B, brilho,
// saturação e a cor média das áreas "vermelhas" (a armadura de Twilight), só
// nos pixels opacos. Usado por ferramentas/medir_cores.ps1 e igualar_cores.ps1.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class MedeCores
{
    public class Medida
    {
        public string Nome; public int Quadros; public long Pixels;
        public double R, G, B, Brilho, Saturacao;     // médias (0..255 / 0..1)
        public double VR, VG, VB; public long NVermelho; // média dos pixels de armadura
        public double LumP50;                          // mediana do brilho
    }

    public static byte[] Ler(string arq, out int w, out int h)
    {
        using (var bmp0 = new Bitmap(arq))
        using (var bmp = bmp0.Clone(new Rectangle(0, 0, bmp0.Width, bmp0.Height), PixelFormat.Format32bppArgb))
        {
            w = bmp.Width; h = bmp.Height;
            var d = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            var px = new byte[d.Stride * h];
            Marshal.Copy(d.Scan0, px, 0, px.Length);
            bmp.UnlockBits(d);
            if (d.Stride != w * 4) { var c = new byte[w * h * 4]; for (int y = 0; y < h; y++) Buffer.BlockCopy(px, y * d.Stride, c, y * w * 4, w * 4); px = c; }
            return px;
        }
    }

    public static Medida Medir(string pasta)
    {
        var m = new Medida { Nome = Path.GetFileName(pasta) };
        var hist = new long[256];
        foreach (var arq in Directory.GetFiles(pasta, "*.png"))
        {
            int w, h; var px = Ler(arq, out w, out h); m.Quadros++;
            for (int i = 0; i < px.Length; i += 4)
            {
                if (px[i + 3] < 200) continue;
                double b = px[i], g = px[i + 1], r = px[i + 2];
                m.Pixels++; m.R += r; m.G += g; m.B += b;
                double mx = Math.Max(r, Math.Max(g, b)), mn = Math.Min(r, Math.Min(g, b));
                double lum = 0.299 * r + 0.587 * g + 0.114 * b;
                m.Brilho += lum; hist[(int)lum]++;
                m.Saturacao += mx > 0 ? (mx - mn) / mx : 0;
                if (r > 70 && r > g * 1.6 && r > b * 1.6) { m.NVermelho++; m.VR += r; m.VG += g; m.VB += b; }
            }
        }
        if (m.Pixels > 0) { m.R /= m.Pixels; m.G /= m.Pixels; m.B /= m.Pixels; m.Brilho /= m.Pixels; m.Saturacao /= m.Pixels; }
        if (m.NVermelho > 0) { m.VR /= m.NVermelho; m.VG /= m.NVermelho; m.VB /= m.NVermelho; }
        long acc = 0; for (int k = 0; k < 256; k++) { acc += hist[k]; if (acc * 2 >= m.Pixels) { m.LumP50 = k; break; } }
        return m;
    }
}
