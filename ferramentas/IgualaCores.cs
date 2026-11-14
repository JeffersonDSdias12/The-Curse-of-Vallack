// Iguala a cor de animações a uma referência (v1.23). Trabalha no espaço Lab
// (claro/escuro separado da cor) para não estragar a pixel art:
//  * brilho (L): ajusta média e contraste para os da referência;
//  * saturação: multiplica o croma, então o que é cinza (espada, metal) continua cinza;
//  * matiz: só os tons de vermelho/laranja giram para o vermelho da referência
//    (a armadura), com transição suave nas bordas da faixa.
// A transparência de cada pixel é mantida. Também monta folhas de comparação.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class IgualaCores
{
    public class Est { public double mL, sL, mC, hVerm; public long n, nVerm; }

    // ---------- sRGB <-> Lab (D65) ----------
    static double Lin(double c) { c /= 255.0; return c <= 0.04045 ? c / 12.92 : Math.Pow((c + 0.055) / 1.055, 2.4); }
    static double Gam(double c) { c = c <= 0.0031308 ? 12.92 * c : 1.055 * Math.Pow(c, 1 / 2.4) - 0.055; return Math.Max(0, Math.Min(255, c * 255.0)); }
    static double F(double t) { return t > 216.0 / 24389 ? Math.Pow(t, 1 / 3.0) : (24389.0 / 27 * t + 16) / 116; }
    static double Fi(double t) { double t3 = t * t * t; return t3 > 216.0 / 24389 ? t3 : (116 * t - 16) / (24389.0 / 27); }
    public static void ParaLab(double r, double g, double b, out double L, out double A, out double B)
    {
        double R = Lin(r), G = Lin(g), Bb = Lin(b);
        double x = (0.4124 * R + 0.3576 * G + 0.1805 * Bb) / 0.95047, y = 0.2126 * R + 0.7152 * G + 0.0722 * Bb, z = (0.0193 * R + 0.1192 * G + 0.9505 * Bb) / 1.08883;
        double fx = F(x), fy = F(y), fz = F(z);
        L = 116 * fy - 16; A = 500 * (fx - fy); B = 200 * (fy - fz);
    }
    public static void ParaRgb(double L, double A, double B, out double r, out double g, out double b)
    {
        double fy = (L + 16) / 116, fx = fy + A / 500, fz = fy - B / 200;
        double x = Fi(fx) * 0.95047, y = L > 8 ? fy * fy * fy : L / (24389.0 / 27), z = Fi(fz) * 1.08883;
        r = Gam(3.2406 * x - 1.5372 * y - 0.4986 * z); g = Gam(-0.9689 * x + 1.8758 * y + 0.0415 * z); b = Gam(0.0557 * x - 0.2040 * y + 1.0570 * z);
    }

    // faixa dos vermelhos/laranjas (armadura): matiz em graus entre -35 e 75
    static double PesoVermelho(double h, double c)
    {
        if (c < 14) return 0;
        double w = 1;
        if (h < -35 || h > 75) return 0;
        if (h < -20) w = (h + 35) / 15; else if (h > 55) w = (75 - h) / 20;
        return w * Math.Min(1, (c - 14) / 12);
    }

    static double Matiz(double a, double b) { return Math.Atan2(b, a) * 180 / Math.PI; }

    public static Est Medir(string[] pastas)
    {
        var e = new Est(); double sL = 0, sL2 = 0, sC = 0, sx = 0, sy = 0; long nC = 0;
        foreach (var p in pastas) foreach (var arq in Directory.GetFiles(p, "*.png"))
        {
            int w, h; var px = MedeCores.Ler(arq, out w, out h);
            for (int i = 0; i < px.Length; i += 4)
            {
                if (px[i + 3] < 200) continue;
                double L, A, B; ParaLab(px[i + 2], px[i + 1], px[i], out L, out A, out B);
                e.n++; sL += L; sL2 += L * L;
                double c = Math.Sqrt(A * A + B * B);
                if (c > 8) { sC += c; nC++; }
                double hh = Matiz(A, B), wv = PesoVermelho(hh, c);
                if (wv > 0.5) { e.nVerm++; sx += Math.Cos(hh * Math.PI / 180) * c; sy += Math.Sin(hh * Math.PI / 180) * c; }
            }
        }
        if (e.n == 0) return e;
        e.mL = sL / e.n; e.sL = Math.Sqrt(Math.Max(1e-6, sL2 / e.n - e.mL * e.mL));
        e.mC = nC > 0 ? sC / nC : 0;
        e.hVerm = Math.Atan2(sy, sx) * 180 / Math.PI;
        return e;
    }

    // aplica em todos os PNG da pasta "alvo", da estatística "src" para a "ref"
    public static int Aplicar(string alvo, Est src, Est r, double forca)
    {
        double kL = r.sL / src.sL, kC = src.mC > 0 ? r.mC / src.mC : 1, dH = r.hVerm - src.hVerm;
        int n = 0;
        foreach (var arq in Directory.GetFiles(alvo, "*.png"))
        {
            int w, h; var px = MedeCores.Ler(arq, out w, out h);
            for (int i = 0; i < px.Length; i += 4)
            {
                if (px[i + 3] == 0) continue;
                double L, A, B; ParaLab(px[i + 2], px[i + 1], px[i], out L, out A, out B);
                double c = Math.Sqrt(A * A + B * B), hh = Matiz(A, B);
                double L2 = (L - src.mL) * kL + r.mL;
                double c2 = c * kC;
                double h2 = hh + dH * PesoVermelho(hh, c);
                double A2 = Math.Cos(h2 * Math.PI / 180) * c2, B2 = Math.Sin(h2 * Math.PI / 180) * c2;
                L2 = L + (L2 - L) * forca; A2 = A + (A2 - A) * forca; B2 = B + (B2 - B) * forca;
                L2 = Math.Max(0, Math.Min(100, L2));
                double rr, gg, bb; ParaRgb(L2, A2, B2, out rr, out gg, out bb);
                px[i + 2] = (byte)Math.Round(rr); px[i + 1] = (byte)Math.Round(gg); px[i] = (byte)Math.Round(bb);
            }
            Gravar(arq, px, w, h); n++;
        }
        return n;
    }

    public static void Gravar(string arq, byte[] px, int w, int h)
    {
        using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
        {
            var d = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            for (int y = 0; y < h; y++) Marshal.Copy(px, y * w * 4, d.Scan0 + y * d.Stride, w * 4);
            bmp.UnlockBits(d);
            var tmp = arq + ".tmp.png"; bmp.Save(tmp, ImageFormat.Png);
            File.Copy(tmp, arq, true); File.Delete(tmp);
        }
    }

    // folha: o 1º quadro de cada pasta lado a lado, num fundo escuro (para olhar)
    public static void Folha(string[] pastas, string saida, int alt)
    {
        var imgs = new List<Bitmap>(); int largura = 0;
        foreach (var p in pastas)
        {
            var arqs = Directory.GetFiles(p, "*.png"); Array.Sort(arqs);
            if (arqs.Length == 0) continue;
            var b = new Bitmap(arqs[arqs.Length / 2]); imgs.Add(b); largura += (int)(b.Width * (double)alt / b.Height) + 8;
        }
        using (var f = new Bitmap(Math.Max(1, largura), alt, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(f))
        {
            g.Clear(Color.FromArgb(40, 34, 38)); g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;
            int x = 0; foreach (var b in imgs) { int w2 = (int)(b.Width * (double)alt / b.Height); g.DrawImage(b, x, 0, w2, alt); x += w2 + 8; b.Dispose(); }
            f.Save(saida, ImageFormat.Png);
        }
    }
}
