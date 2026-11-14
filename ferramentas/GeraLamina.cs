// =====================================================================
//  GeraLamina.cs — onde está a LÂMINA em cada quadro dos golpes (v1.17)
//  Acha a lâmina (o maior traço reto claro e sem saturação: branco, cinza,
//  rosa-claro) em cada quadro HD, mede o eixo (PCA) e devolve o CABO (ponta do
//  eixo perto do corpo) e a PONTA da espada, relativos à origem da sprite.
//  O rastro de fogo da espada segue esses pontos quadro a quadro.
//  Uso: ferramentas/gerar_lamina.ps1 (gera os dados e uma prévia para conferir)
// =====================================================================
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;

public static class GeraLamina
{
    static uint[] Ler(string arq, out int w, out int h)
    {
        using (var b = new Bitmap(arq))
        {
            w = b.Width; h = b.Height;
            var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            int[] buf = new int[w * h];
            for (int y = 0; y < h; y++) System.Runtime.InteropServices.Marshal.Copy(d.Scan0 + y * d.Stride, buf, y * w, w);
            b.UnlockBits(d);
            var p = new uint[w * h];
            for (int i = 0; i < p.Length; i++) p[i] = (uint)buf[i];
            return p;
        }
    }

    static bool Claro(uint c)
    {
        if ((c >> 24) < 128) return false;
        int r = (int)((c >> 16) & 255), g = (int)((c >> 8) & 255), b = (int)(c & 255);
        int mx = Math.Max(r, Math.Max(g, b)), mn = Math.Min(r, Math.Min(g, b));
        return mn >= 140 && mx - mn <= 95 && g - b < 18;
    }

    // devolve [cx, cy, tx, ty, comprimento, largura, confiança] (px da imagem) ou null
    public static double[] Medir(string arq)
    {
        int w, h;
        var p = Ler(arq, out w, out h);
        var marca = new int[w * h];
        var comps = new List<List<int>>();
        for (int i = 0; i < p.Length; i++)
        {
            if (marca[i] != 0 || !Claro(p[i])) continue;
            var l = new List<int>();
            var pilha = new Stack<int>();
            pilha.Push(i); marca[i] = comps.Count + 1;
            while (pilha.Count > 0)
            {
                int k = pilha.Pop(); l.Add(k);
                int x = k % w, y = k / w;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                        int kk = yy * w + xx;
                        if (marca[kk] != 0 || !Claro(p[kk])) continue;
                        marca[kk] = comps.Count + 1;
                        pilha.Push(kk);
                    }
            }
            comps.Add(l);
        }
        // centro do corpo: média dos pixels opacos que não são claros
        double bx = 0, by = 0; int bn = 0;
        for (int i = 0; i < p.Length; i++) if ((p[i] >> 24) >= 128 && !Claro(p[i])) { bx += i % w; by += i / w; bn++; }
        if (bn > 0) { bx /= bn; by /= bn; }
        double[] melhor = null; double nota = 0;
        foreach (var l in comps)
        {
            if (l.Count < 25) continue;
            double mx = 0, my = 0;
            foreach (int k in l) { mx += k % w; my += k / w; }
            mx /= l.Count; my /= l.Count;
            double sxx = 0, syy = 0, sxy = 0;
            foreach (int k in l) { double dx = k % w - mx, dy = k / w - my; sxx += dx * dx; syy += dy * dy; sxy += dx * dy; }
            sxx /= l.Count; syy /= l.Count; sxy /= l.Count;
            double tr = sxx + syy, det = sxx * syy - sxy * sxy;
            double l1 = tr / 2 + Math.Sqrt(Math.Max(0, tr * tr / 4 - det)), l2 = tr / 2 - Math.Sqrt(Math.Max(0, tr * tr / 4 - det));
            double ex, ey;
            if (Math.Abs(sxy) > 1e-9) { ex = l1 - syy; ey = sxy; } else if (sxx >= syy) { ex = 1; ey = 0; } else { ex = 0; ey = 1; }
            double el = Math.Sqrt(ex * ex + ey * ey); ex /= el; ey /= el;
            double tmin = 1e9, tmax = -1e9, dmax = 0;
            foreach (int k in l)
            {
                double dx = k % w - mx, dy = k / w - my;
                double t = dx * ex + dy * ey, d = Math.Abs(-dx * ey + dy * ex);
                if (t < tmin) tmin = t; if (t > tmax) tmax = t; if (d > dmax) dmax = d;
            }
            double comp = tmax - tmin;
            double larg = Math.Sqrt(Math.Max(0, l2)) * 4;
            if (comp < 30 || larg > 22 || comp / Math.Max(1, larg) < 3.2) continue;
            double n = comp * Math.Min(1, comp / Math.Max(1, larg) / 6);
            if (n <= nota) continue;
            nota = n;
            double ax = mx + ex * tmin, ay = my + ey * tmin, zx = mx + ex * tmax, zy = my + ey * tmax;
            // a ponta é a extremidade mais longe do corpo
            double da = (ax - bx) * (ax - bx) + (ay - by) * (ay - by), dz = (zx - bx) * (zx - bx) + (zy - by) * (zy - by);
            if (da > dz) { double t1 = ax, t2 = ay; ax = zx; ay = zy; zx = t1; zy = t2; }
            melhor = new double[] { ax, ay, zx, zy, comp, larg, comp / Math.Max(1, larg) };
        }
        return melhor;
    }

    // prévia: quadro com a linha cabo -> ponta (verde -> amarelo)
    public static void Previa(string[] arqs, string[] rotulos, double[][] pts, string saida, double zoom)
    {
        int W = 10, H = 0;
        var tam = new List<Size>();
        foreach (var a in arqs) using (var im = new Bitmap(a)) { tam.Add(new Size(im.Width, im.Height)); }
        int col = 8;
        int linhas = (arqs.Length + col - 1) / col;
        int cw = 0, ch = 0;
        foreach (var s in tam) { cw = Math.Max(cw, (int)(s.Width * zoom)); ch = Math.Max(ch, (int)(s.Height * zoom)); }
        W = col * (cw + 8) + 10; H = linhas * (ch + 22) + 10;
        using (var b = new Bitmap(W, H, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(b))
        using (var f = new Font("Arial", 8))
        using (var pv = new Pen(Color.Lime, 2))
        {
            g.Clear(Color.FromArgb(255, 50, 60, 76));
            for (int i = 0; i < arqs.Length; i++)
            {
                int cx = 10 + (i % col) * (cw + 8), cy = 10 + (i / col) * (ch + 22);
                g.DrawString(rotulos[i], f, Brushes.White, cx, cy);
                using (var im = new Bitmap(arqs[i])) g.DrawImage(im, cx, cy + 14, (int)(im.Width * zoom), (int)(im.Height * zoom));
                var q = pts[i];
                if (q == null) { g.DrawString("SEM LAMINA", f, Brushes.Red, cx, cy + 26); continue; }
                float x1 = (float)(cx + q[0] * zoom), y1 = (float)(cy + 14 + q[1] * zoom), x2 = (float)(cx + q[2] * zoom), y2 = (float)(cy + 14 + q[3] * zoom);
                g.DrawLine(pv, x1, y1, x2, y2);
                g.FillEllipse(Brushes.Lime, x1 - 3, y1 - 3, 6, 6);
                g.FillEllipse(Brushes.Yellow, x2 - 4, y2 - 4, 8, 8);
            }
            b.Save(saida, ImageFormat.Png);
        }
    }
}
