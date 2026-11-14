// =====================================================================
//  ProcSprite — tratamento dos sprites de personagens (ferramenta offline)
//  1. reconstrói quadros "quadriculados" (pixel-art ampliado em blocos):
//     detecta o tamanho do bloco, volta à resolução nativa e amplia de novo
//     com EPX (Scale2x), que arredonda as diagonais sem borrar
//  2. limpa a borda: tira o halo semitransparente e os pontos soltos
//  3. nitidez (unsharp mask), contraste e saturação
//  4. contorno escuro em volta do corpo (a imagem ganha "pad" px de cada lado)
//  Usado por ferramentas/processar_sprites.ps1
// =====================================================================
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ProcSprite
{
    public static int[] Carregar(string arq, out int w, out int h)
    {
        using (var b0 = new Bitmap(arq))
        using (var b = new Bitmap(b0.Width, b0.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(b)) { g.Clear(Color.Transparent); g.DrawImageUnscaled(b0, 0, 0); }
            w = b.Width; h = b.Height;
            var px = new int[w * h];
            var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(d.Scan0, px, 0, px.Length);
            b.UnlockBits(d);
            return px;
        }
    }

    public static void Salvar(string arq, int[] px, int w, int h)
    {
        using (var b = new Bitmap(w, h, PixelFormat.Format32bppArgb))
        {
            var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(px, 0, d.Scan0, px.Length);
            b.UnlockBits(d);
            b.Save(arq, ImageFormat.Png);
        }
    }

    static int A(int c) { return (c >> 24) & 255; }
    static int R(int c) { return (c >> 16) & 255; }
    static int G(int c) { return (c >> 8) & 255; }
    static int B(int c) { return c & 255; }
    static int Cor(int a, int r, int g, int b)
    {
        a = Math.Max(0, Math.Min(255, a)); r = Math.Max(0, Math.Min(255, r));
        g = Math.Max(0, Math.Min(255, g)); b = Math.Max(0, Math.Min(255, b));
        return (a << 24) | (r << 16) | (g << 8) | b;
    }
    static bool Igual(int a, int b)
    {
        if (A(a) < 128 && A(b) < 128) return true;
        return Math.Abs(A(a) - A(b)) < 24 && Math.Abs(R(a) - R(b)) < 18 && Math.Abs(G(a) - G(b)) < 18 && Math.Abs(B(a) - B(b)) < 18;
    }

    // ----- 1. tamanho do bloco: as mudanças de cor caem sempre na mesma "grade" -----
    static int Grade(int[] px, int w, int h, bool horiz, out int desloc)
    {
        int n = horiz ? w : h;
        var trans = new int[n];
        int total = 0;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int i = y * w + x;
                int pos = horiz ? x : y;
                if (pos == 0) continue;
                int j = horiz ? i - 1 : i - w;
                if (A(px[i]) < 128 && A(px[j]) < 128) continue;
                if (!Igual(px[i], px[j])) { trans[pos]++; total++; }
            }
        desloc = 0;
        if (total < 200) return 1;
        int melhor = 1;
        for (int s = 2; s <= 8; s++)
        {
            var res = new int[s];
            for (int p = 0; p < n; p++) res[p % s] += trans[p];
            int max = 0, r = 0;
            for (int k = 0; k < s; k++) if (res[k] > max) { max = res[k]; r = k; }
            if (max >= total * 0.93) { melhor = s; desloc = r; }
        }
        return melhor;
    }

    static int[] Epx(int[] p, int w, int h)
    {
        var o = new int[w * 2 * h * 2];
        int w2 = w * 2;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int P = p[y * w + x];
                int Ac = y > 0 ? p[(y - 1) * w + x] : P;
                int Bc = x < w - 1 ? p[y * w + x + 1] : P;
                int Cc = x > 0 ? p[y * w + x - 1] : P;
                int Dc = y < h - 1 ? p[(y + 1) * w + x] : P;
                int o1 = P, o2 = P, o3 = P, o4 = P;
                if (Igual(Cc, Ac) && !Igual(Cc, Dc) && !Igual(Ac, Bc)) o1 = Ac;
                if (Igual(Ac, Bc) && !Igual(Ac, Cc) && !Igual(Bc, Dc)) o2 = Bc;
                if (Igual(Dc, Cc) && !Igual(Dc, Bc) && !Igual(Cc, Ac)) o3 = Cc;
                if (Igual(Bc, Dc) && !Igual(Bc, Ac) && !Igual(Dc, Cc)) o4 = Dc;
                o[(y * 2) * w2 + x * 2] = o1;
                o[(y * 2) * w2 + x * 2 + 1] = o2;
                o[(y * 2 + 1) * w2 + x * 2] = o3;
                o[(y * 2 + 1) * w2 + x * 2 + 1] = o4;
            }
        return o;
    }

    // devolve o tamanho do bloco encontrado (1 = quadro já nítido)
    public static int Reconstruir(int[] px, int w, int h)
    {
        int ox, oy;
        int sx = Grade(px, w, h, true, out ox);
        int sy = Grade(px, w, h, false, out oy);
        int s = Math.Min(sx, sy);
        if (s < 2 || sx != sy) return 1;
        int nw = (w - ox + s - 1) / s, nh = (h - oy + s - 1) / s;
        var nat = new int[nw * nh];
        for (int y = 0; y < nh; y++)
            for (int x = 0; x < nw; x++)
            {
                int cx = Math.Min(w - 1, ox + x * s + s / 2), cy = Math.Min(h - 1, oy + y * s + s / 2);
                nat[y * nw + x] = px[cy * w + cx];
            }
        // EPX até passar do tamanho do bloco
        int f = 1;
        int[] up = nat; int uw = nw, uh = nh;
        while (f < s) { up = Epx(up, uw, uh); uw *= 2; uh *= 2; f *= 2; }
        // reduz para exatamente "s" por pixel nativo (média com alfa pré-multiplicado)
        double k = (double)f / s;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                double ux0 = (x - ox) * k, uy0 = (y - oy) * k;
                int x0 = (int)Math.Floor(ux0), y0 = (int)Math.Floor(uy0);
                int x1 = (int)Math.Ceiling(ux0 + k), y1 = (int)Math.Ceiling(uy0 + k);
                double sa = 0, sr = 0, sg = 0, sb = 0, n = 0;
                for (int yy = Math.Max(0, y0); yy < Math.Min(uh, y1); yy++)
                    for (int xx = Math.Max(0, x0); xx < Math.Min(uw, x1); xx++)
                    {
                        int c = up[yy * uw + xx];
                        double a = A(c) / 255.0;
                        sa += a; sr += R(c) * a; sg += G(c) * a; sb += B(c) * a; n++;
                    }
                if (n == 0 || sa <= 0) { px[y * w + x] = 0; continue; }
                px[y * w + x] = Cor((int)(sa / n * 255 + 0.5), (int)(sr / sa), (int)(sg / sa), (int)(sb / sa));
            }
        return s;
    }

    // ----- 1b. quadros ampliados por fator fracionário (blocos de ~5-12 px com
    // borda suavizada): mede o comprimento mediano das "corridas" de cor igual
    public static double TamanhoBloco(int[] px, int w, int h)
    {
        var corridas = new System.Collections.Generic.List<int>();
        for (int y = 0; y < h; y += 2)
        {
            int ini = -1;
            for (int x = 0; x <= w; x++)
            {
                bool fim = x == w || A(px[y * w + x]) < 128 || (ini >= 0 && !Igual(px[y * w + x], px[y * w + ini]));
                if (fim)
                {
                    if (ini >= 0 && x - ini >= 1) corridas.Add(x - ini);
                    ini = (x < w && A(px[y * w + x]) >= 128) ? x : -1;
                }
                else if (ini < 0) ini = x;
            }
        }
        if (corridas.Count < 30) return 1;
        corridas.Sort();
        return corridas[corridas.Count / 2];
    }

    // moda das corridas de cor EXATAMENTE igual (>= 3 px): revela o tamanho do bloco
    public static string HistogramaCorridas(int[] px, int w, int h)
    {
        var hist = new int[40];
        for (int y = 0; y < h; y++)
        {
            int ini = 0;
            for (int x = 1; x <= w; x++)
            {
                if (x == w || px[y * w + x] != px[y * w + ini])
                {
                    int len = x - ini;
                    if (A(px[y * w + ini]) >= 200 && len >= 3 && len < 40) hist[len]++;
                    ini = x;
                }
            }
        }
        var sb = new System.Text.StringBuilder();
        for (int i = 3; i < 40; i++) if (hist[i] > 0) sb.Append(i + ":" + hist[i] + " ");
        return sb.ToString();
    }

    // volta à resolução nativa (média por área) e amplia de novo com EPX
    public static void Suavizar(int[] px, int w, int h, double bloco)
    {
        int nw = Math.Max(2, (int)Math.Round(w / bloco)), nh = Math.Max(2, (int)Math.Round(h / bloco));
        var nat = new int[nw * nh];
        double kx = (double)w / nw, ky = (double)h / nh;
        for (int y = 0; y < nh; y++)
            for (int x = 0; x < nw; x++)
            {
                // amostra o miolo do bloco (evita a borda suavizada entre blocos)
                int x0 = (int)(x * kx + kx * 0.25), x1 = (int)Math.Ceiling(x * kx + kx * 0.75);
                int y0 = (int)(y * ky + ky * 0.25), y1 = (int)Math.Ceiling(y * ky + ky * 0.75);
                double sa = 0, sr = 0, sg = 0, sb = 0, n = 0;
                for (int yy = y0; yy < Math.Min(h, y1); yy++)
                    for (int xx = x0; xx < Math.Min(w, x1); xx++)
                    {
                        int c = px[yy * w + xx];
                        double a = A(c) / 255.0;
                        sa += a; sr += R(c) * a; sg += G(c) * a; sb += B(c) * a; n++;
                    }
                nat[y * nw + x] = (n == 0 || sa / n < 0.5) ? 0 : Cor(255, (int)(sr / sa), (int)(sg / sa), (int)(sb / sa));
            }
        int f = 1;
        int[] up = nat; int uw = nw, uh = nh;
        while (f < bloco) { up = Epx(up, uw, uh); uw *= 2; uh *= 2; f *= 2; }
        double ux = (double)uw / w, uy = (double)uh / h;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int x0 = (int)Math.Floor(x * ux), x1 = Math.Max(x0 + 1, (int)Math.Ceiling((x + 1) * ux));
                int y0 = (int)Math.Floor(y * uy), y1 = Math.Max(y0 + 1, (int)Math.Ceiling((y + 1) * uy));
                double sa = 0, sr = 0, sg = 0, sb = 0, n = 0;
                for (int yy = y0; yy < Math.Min(uh, y1); yy++)
                    for (int xx = x0; xx < Math.Min(uw, x1); xx++)
                    {
                        int c = up[yy * uw + xx];
                        double a = A(c) / 255.0;
                        sa += a; sr += R(c) * a; sg += G(c) * a; sb += B(c) * a; n++;
                    }
                px[y * w + x] = (n == 0 || sa <= 0) ? 0 : Cor((int)(sa / n * 255 + 0.5), (int)(sr / sa), (int)(sg / sa), (int)(sb / sa));
            }
    }

    // ----- 2. limpeza da borda -----
    public static void Limpar(int[] px, int w, int h, double limiar)
    {
        int lim = (int)(limiar * 255);
        for (int i = 0; i < px.Length; i++) if (A(px[i]) < lim) px[i] = 0;
        // pontos soltos (com no máximo 1 vizinho visível)
        for (int passada = 0; passada < 2; passada++)
        {
            var tira = new bool[px.Length];
            for (int y = 0; y < h; y++)
                for (int x = 0; x < w; x++)
                {
                    if (A(px[y * w + x]) == 0) continue;
                    int viz = 0;
                    for (int dy = -1; dy <= 1; dy++)
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            if (dx == 0 && dy == 0) continue;
                            int xx = x + dx, yy = y + dy;
                            if (xx >= 0 && yy >= 0 && xx < w && yy < h && A(px[yy * w + xx]) >= lim) viz++;
                        }
                    if (viz <= 1) tira[y * w + x] = true;
                }
            for (int i = 0; i < px.Length; i++) if (tira[i]) px[i] = 0;
        }
    }

    // ----- 3. nitidez, contraste e saturação -----
    public static void Realcar(int[] px, int w, int h, double nitidez, double contraste, double sat)
    {
        var o = (int[])px.Clone();
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int c = px[y * w + x];
                if (A(c) == 0) continue;
                double r = R(c), g = G(c), b = B(c);
                // média 3x3 só com vizinhos visíveis (sem halo escuro na borda)
                double mr = 0, mg = 0, mb = 0; int n = 0;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                        int v = px[yy * w + xx];
                        if (A(v) < 128) continue;
                        mr += R(v); mg += G(v); mb += B(v); n++;
                    }
                if (n > 0) { mr /= n; mg /= n; mb /= n; r += (r - mr) * nitidez; g += (g - mg) * nitidez; b += (b - mb) * nitidez; }
                r = (r - 128) * contraste + 128; g = (g - 128) * contraste + 128; b = (b - 128) * contraste + 128;
                double l = 0.299 * r + 0.587 * g + 0.114 * b;
                r = l + (r - l) * sat; g = l + (g - l) * sat; b = l + (b - l) * sat;
                o[y * w + x] = Cor(A(c), (int)r, (int)g, (int)b);
            }
        Array.Copy(o, px, px.Length);
    }

    // ----- 4. contorno: imagem nova com "pad" px de cada lado -----
    public static int[] Contornar(int[] px, int w, int h, int pad, int cr, int cg, int cb, out int nw, out int nh)
    {
        nw = w + pad * 2; nh = h + pad * 2;
        var o = new int[nw * nh];
        var msk = new bool[nw * nh];
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
                if (A(px[y * w + x]) >= 110) msk[(y + pad) * nw + x + pad] = true;
        double r2 = (pad + 0.35) * (pad + 0.35);
        int contorno = Cor(255, cr, cg, cb);
        for (int y = 0; y < nh; y++)
            for (int x = 0; x < nw; x++)
            {
                bool perto = false;
                for (int dy = -pad; dy <= pad && !perto; dy++)
                    for (int dx = -pad; dx <= pad; dx++)
                    {
                        if (dx * dx + dy * dy > r2) continue;
                        int xx = x + dx, yy = y + dy;
                        if (xx >= 0 && yy >= 0 && xx < nw && yy < nh && msk[yy * nw + xx]) { perto = true; break; }
                    }
                int ox = x - pad, oy = y - pad;
                int src = (ox >= 0 && oy >= 0 && ox < w && oy < h) ? px[oy * w + ox] : 0;
                if (!perto) { o[y * nw + x] = src; continue; }
                // o sprite por cima do contorno (fundo opaco)
                double a = A(src) / 255.0;
                o[y * nw + x] = Cor(255, (int)(R(src) * a + cr * (1 - a)), (int)(G(src) * a + cg * (1 - a)), (int)(B(src) * a + cb * (1 - a)));
            }
        return o;
    }
}
