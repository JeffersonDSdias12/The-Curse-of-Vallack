// =====================================================================
//  ImportaFolhas.cs — importa as animações novas do Twilight a partir das
//  folhas de quadros (JPG) enviadas pela equipe (v1.17):
//   escada (subir / descer), corda (pular e agarrar / segurar e subir) e os
//   ataques (rápido, duplo, triplo e frenético).
//  1) acha as caixas dos quadros (borda cinza-azulada sobre o fundo ardósia)
//  2) recorta, apaga o número amarelo e tira o fundo (desfazendo a mistura do
//     JPG na borda: o contorno escuro fica limpo, sem halo azulado)
//  3) mede o cabelo (régua da escala) e os pés / o tronco (âncora)
//  4) iguala a escala à das sprites do jogo e alinha todos os quadros numa
//     tela comum com a mesma origem (nada "pula" de um quadro para o outro)
//  Uso: ferramentas/importar_folhas.ps1
// =====================================================================
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class ImportaFolhas
{
    public class Img
    {
        public int W, H;
        public uint[] P;
        public Img(int w, int h) { W = w; H = h; P = new uint[w * h]; }
        public uint Get(int x, int y) { return (x < 0 || y < 0 || x >= W || y >= H) ? 0u : P[y * W + x]; }
        public void Set(int x, int y, uint c) { if (x >= 0 && y >= 0 && x < W && y < H) P[y * W + x] = c; }
        public int A(int x, int y) { return (int)(Get(x, y) >> 24); }
    }

    public static int R(uint c) { return (int)((c >> 16) & 255); }
    public static int G(uint c) { return (int)((c >> 8) & 255); }
    public static int B(uint c) { return (int)(c & 255); }
    public static uint Argb(int a, int r, int g, int b)
    {
        a = Math.Max(0, Math.Min(255, a)); r = Math.Max(0, Math.Min(255, r)); g = Math.Max(0, Math.Min(255, g)); b = Math.Max(0, Math.Min(255, b));
        return ((uint)a << 24) | ((uint)r << 16) | ((uint)g << 8) | (uint)b;
    }

    public static Img Carregar(string arq)
    {
        using (var src = new Bitmap(arq))
        using (var b = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(b)) g.DrawImage(src, 0, 0, src.Width, src.Height);
            var im = new Img(b.Width, b.Height);
            var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            int[] buf = new int[b.Width * b.Height];
            for (int y = 0; y < b.Height; y++) System.Runtime.InteropServices.Marshal.Copy(d.Scan0 + y * d.Stride, buf, y * b.Width, b.Width);
            b.UnlockBits(d);
            for (int i = 0; i < buf.Length; i++) im.P[i] = (uint)buf[i];
            return im;
        }
    }

    public static void Salvar(Img im, string arq)
    {
        using (var b = new Bitmap(im.W, im.H, PixelFormat.Format32bppArgb))
        {
            var d = b.LockBits(new Rectangle(0, 0, im.W, im.H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            int[] buf = new int[im.W * im.H];
            for (int i = 0; i < buf.Length; i++) buf[i] = (int)im.P[i];
            for (int y = 0; y < im.H; y++) System.Runtime.InteropServices.Marshal.Copy(buf, y * im.W, d.Scan0 + y * d.Stride, im.W);
            b.UnlockBits(d);
            Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(arq)));
            b.Save(arq, ImageFormat.Png);
        }
    }

    // ----------------------------------------------------------------
    // 1) CAIXAS DOS QUADROS
    // ----------------------------------------------------------------
    // borda das caixas: cinza-azulado mais claro que o fundo daquela folha
    static bool Borda(uint c)
    {
        int r = R(c) - FundoR, g = G(c) - FundoG, b = B(c) - FundoB;
        return r >= 12 && r <= 62 && g >= 10 && g <= 58 && b >= 8 && b <= 55 && Math.Abs(r - g) <= 14 && Math.Abs(g - b) <= 14;
    }

    // fundo da folha: a cor mais comum (quantizada de 4 em 4)
    public static void EstimarFundo(Img f)
    {
        var cont = new Dictionary<int, int>();
        for (int i = 0; i < f.P.Length; i += 3)
        {
            uint c = f.P[i];
            int k = ((R(c) >> 2) << 12) | ((G(c) >> 2) << 6) | (B(c) >> 2);
            int v; cont.TryGetValue(k, out v); cont[k] = v + 1;
        }
        int melhor = 0, mv = -1;
        foreach (var kv in cont) if (kv.Value > mv) { mv = kv.Value; melhor = kv.Key; }
        FundoR = ((melhor >> 12) & 63) * 4 + 2; FundoG = ((melhor >> 6) & 63) * 4 + 2; FundoB = (melhor & 63) * 4 + 2;
    }

    // trechos retos de borda: [fixo, ini, fim] (com tolerância a falhas de 2 px do JPG)
    static List<int[]> Trechos(Img f, bool horizontal, int minimo)
    {
        var l = new List<int[]>();
        int n1 = horizontal ? f.H : f.W, n2 = horizontal ? f.W : f.H;
        for (int a = 0; a < n1; a++)
        {
            int ini = -1, falha = 0, ult = -1;
            for (int b = 0; b <= n2; b++)
            {
                bool e = b < n2 && Borda(horizontal ? f.Get(b, a) : f.Get(a, b));
                if (e) { if (ini < 0) ini = b; ult = b; falha = 0; }
                else if (ini >= 0)
                {
                    falha++;
                    if (falha > 2 || b == n2)
                    {
                        if (ult - ini + 1 >= minimo) l.Add(new[] { a, ini, ult });
                        ini = -1; falha = 0;
                    }
                }
            }
        }
        return l;
    }

    // devolve as caixas [x1, y1, x2, y2] (borda externa), em ordem de leitura
    static bool BordaPerto(Img f, int x, int y)
    {
        return Borda(f.Get(x, y)) || Borda(f.Get(x - 1, y)) || Borda(f.Get(x + 1, y)) || Borda(f.Get(x, y - 1)) || Borda(f.Get(x, y + 1));
    }

    // Por perfis: linhas horizontais (muitas bordas na mesma altura) e, entre
    // cada par de linhas, as colunas de borda que vão de uma à outra.
    public static List<int[]> Caixas(Img f)
    {
        EstimarFundo(f);
        var cnt = new int[f.H];
        for (int y = 0; y < f.H; y++) { int c = 0; for (int x = 0; x < f.W; x++) if (Borda(f.Get(x, y))) c++; cnt[y] = c; }
        var linhas = new List<int>();
        for (int y = 1; y < f.H - 1; y++)
        {
            if (cnt[y] < 140) continue;
            if (cnt[y] < cnt[y - 1] || cnt[y] < cnt[y + 1]) continue;
            if (linhas.Count > 0 && y - linhas[linhas.Count - 1] <= 3) { if (cnt[y] > cnt[linhas[linhas.Count - 1]]) linhas[linhas.Count - 1] = y; continue; }
            linhas.Add(y);
        }
        var cx = new List<int[]>();
        for (int i = 0; i < linhas.Count; i++)
            for (int j = i + 1; j < linhas.Count; j++)
            {
                int t = linhas[i], b = linhas[j];
                if (b - t < 100) continue;
                var cols = new List<int>();
                int alt = b - t - 6;
                for (int x = 0; x < f.W; x++)
                {
                    int n = 0;
                    for (int y = t + 3; y <= b - 3; y++) if (BordaPerto(f, x, y)) n++;
                    if (n < alt * 0.72) continue;
                    if (cols.Count > 0 && x - cols[cols.Count - 1] <= 3) continue;
                    cols.Add(x);
                }
                for (int k = 0; k + 1 < cols.Count; k++)
                {
                    int xa = cols[k], xb = cols[k + 1];
                    if (xb - xa < 100) continue;
                    // as bordas de cima e de baixo têm que existir entre as duas colunas
                    int nt = 0, nb = 0;
                    for (int x = xa + 2; x <= xb - 2; x++) { if (BordaPerto(f, x, t)) nt++; if (BordaPerto(f, x, b)) nb++; }
                    if (nt < (xb - xa) * 0.6 || nb < (xb - xa) * 0.6) continue;
                    var c = new[] { xa, t, xb, b };
                    bool rep = false;
                    foreach (var o in cx) if (Math.Abs(o[0] - c[0]) <= 4 && Math.Abs(o[1] - c[1]) <= 4 && Math.Abs(o[2] - c[2]) <= 4 && Math.Abs(o[3] - c[3]) <= 4) { rep = true; break; }
                    // uma caixa não pode conter outra linha do meio (par de linhas errado)
                    bool atravessa = false;
                    foreach (int l in linhas) if (l > t + 4 && l < b - 4) { int n2 = 0; for (int x = xa + 2; x <= xb - 2; x++) if (BordaPerto(f, x, l)) n2++; if (n2 >= (xb - xa) * 0.6) { atravessa = true; break; } }
                    if (!rep && !atravessa) cx.Add(c);
                }
            }
        cx.Sort((a, b2) => Math.Abs(a[1] - b2[1]) > 30 ? a[1].CompareTo(b2[1]) : a[0].CompareTo(b2[0]));
        return cx;
    }

    public static List<int[]> CaixasAntigo(Img f)
    {
        EstimarFundo(f);
        var hs = Trechos(f, true, 50);
        var vs = Trechos(f, false, 50);
        var cx = new List<int[]>();
        foreach (var t in hs)
        {
            // procura a borda de baixo com as mesmas pontas
            int[] melhor = null;
            foreach (var b in hs)
            {
                if (b[0] <= t[0] + 50 || Math.Abs(b[1] - t[1]) > 5 || Math.Abs(b[2] - t[2]) > 5) continue;
                if (melhor != null && b[0] >= melhor[0]) continue;
                // os dois lados verticais cobrindo a altura
                bool esq = false, dir = false;
                foreach (var v in vs)
                {
                    if (v[1] > t[0] + 6 || v[2] < b[0] - 6) continue;
                    if (Math.Abs(v[0] - t[1]) <= 4) esq = true;
                    if (Math.Abs(v[0] - t[2]) <= 4) dir = true;
                }
                if (esq && dir) melhor = b;
            }
            if (melhor == null) continue;
            var c = new[] { t[1], t[0], t[2], melhor[0] };
            bool repetida = false;
            foreach (var o in cx)
                if (Math.Abs(o[0] - c[0]) <= 5 && Math.Abs(o[1] - c[1]) <= 5 && Math.Abs(o[2] - c[2]) <= 5 && Math.Abs(o[3] - c[3]) <= 5)
                {
                    // fica com a caixa mais externa
                    o[0] = Math.Min(o[0], c[0]); o[1] = Math.Min(o[1], c[1]); o[2] = Math.Max(o[2], c[2]); o[3] = Math.Max(o[3], c[3]);
                    repetida = true; break;
                }
            if (!repetida) cx.Add(c);
        }
        cx.Sort((a, b) => Math.Abs(a[1] - b[1]) > 30 ? a[1].CompareTo(b[1]) : a[0].CompareTo(b[0]));
        return cx;
    }

    // ----------------------------------------------------------------
    // 2) RECORTE SEM FUNDO
    // ----------------------------------------------------------------
    public static int FundoR = 71, FundoG = 88, FundoB = 106;

    public static Img Extrair(Img f, int[] c)
    {
        int ins = 4;
        int x1 = c[0] + ins, y1 = c[1] + ins, x2 = c[2] - ins, y2 = c[3] - ins;
        var o = new Img(x2 - x1 + 1, y2 - y1 + 1);
        for (int y = 0; y < o.H; y++)
            for (int x = 0; x < o.W; x++)
            {
                uint p = f.Get(x1 + x, y1 + y);
                int r = R(p), g = G(p), b = B(p);
                // o número amarelo do quadro (canto de cima, à esquerda)
                if (x < 36 && y < 34 && g - b > 18 && r > 70 && g > 80) { o.Set(x, y, 0); continue; }
                double dr = r - FundoR, dg = g - FundoG, db = b - FundoB;
                double d = Math.Sqrt(dr * dr + dg * dg + db * db);
                double a = (d - 24) / (58 - 24);
                if (a <= 0) { o.Set(x, y, 0); continue; }
                if (a > 1) a = 1;
                // desfaz a mistura com o fundo (sem halo azulado no contorno)
                double fr = (r - (1 - a) * FundoR) / a, fg = (g - (1 - a) * FundoG) / a, fb = (b - (1 - a) * FundoB) / a;
                o.Set(x, y, Argb((int)Math.Round(a * 255), (int)Math.Round(fr), (int)Math.Round(fg), (int)Math.Round(fb)));
            }
        LimparMiudos(o, 14);
        // halo fraco que sobrou: abaixo de 35% some
        for (int i = 0; i < o.P.Length; i++) if ((o.P[i] >> 24) < 90) o.P[i] = 0;
        return o;
    }

    // tira manchinhas soltas (ruído do JPG) com menos de "min" pixels
    public static void LimparMiudos(Img o, int min)
    {
        var marca = new int[o.W * o.H];
        int id = 0;
        for (int i = 0; i < o.P.Length; i++)
        {
            if (marca[i] != 0 || (o.P[i] >> 24) < 60) continue;
            id++;
            var l = new List<int>();
            var pilha = new Stack<int>(); pilha.Push(i); marca[i] = id;
            while (pilha.Count > 0)
            {
                int k = pilha.Pop(); l.Add(k);
                int x = k % o.W, y = k / o.W;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= o.W || yy >= o.H) continue;
                        int kk = yy * o.W + xx;
                        if (marca[kk] != 0 || (o.P[kk] >> 24) < 60) continue;
                        marca[kk] = id; pilha.Push(kk);
                    }
            }
            if (l.Count < min) foreach (int k in l) o.P[k] = 0;
        }
    }

    // ----------------------------------------------------------------
    // 3) MEDIDAS
    // ----------------------------------------------------------------
    public static bool Cabelo(uint c)
    {
        if ((c >> 24) < 128) return false;
        int r = R(c), g = G(c), b = B(c);
        return r >= 62 && r <= 200 && g >= 30 && g <= 130 && b >= 8 && b <= 100 && r - g >= 22 && r - g <= 95 && g - b >= 8 && g - b <= 70;
    }

    public static bool Claro(uint c)
    {
        if ((c >> 24) < 128) return false;
        int r = R(c), g = G(c), b = B(c);
        return Math.Min(r, Math.Min(g, b)) >= 150;          // lâmina, rastro branco/rosa
    }

    public static bool RastroVermelho(uint c)
    {
        // a parte vermelha/rosa viva do borrão do golpe (não é armadura escura)
        if ((c >> 24) < 128) return false;
        int r = R(c), g = G(c), b = B(c);
        return r > 200 && g > 60 && b > 60 && g < 200;
    }

    // [largura, altura, cx, cy] do maior pedaço de cabelo (ou null)
    public static double[] MedirCabelo(Img o)
    {
        var marca = new bool[o.W * o.H];
        double[] melhor = null; int mn = 0;
        for (int i = 0; i < o.P.Length; i++)
        {
            if (marca[i] || !Cabelo(o.P[i])) continue;
            var pilha = new Stack<int>(); pilha.Push(i); marca[i] = true;
            int n = 0, xa = 99999, xb = -1, ya = 99999, yb = -1; double sx = 0, sy = 0;
            while (pilha.Count > 0)
            {
                int k = pilha.Pop(); n++;
                int x = k % o.W, y = k / o.W;
                sx += x; sy += y;
                if (x < xa) xa = x; if (x > xb) xb = x; if (y < ya) ya = y; if (y > yb) yb = y;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= o.W || yy >= o.H) continue;
                        int kk = yy * o.W + xx;
                        if (marca[kk] || !Cabelo(o.P[kk])) continue;
                        marca[kk] = true; pilha.Push(kk);
                    }
            }
            if (n > mn) { mn = n; melhor = new double[] { xb - xa + 1, yb - ya + 1, sx / n, sy / n, n }; }
        }
        return melhor;
    }

    // corpo = opaco que não é lâmina nem rastro: [x esq, x dir, y topo, y pé, cx, cy, pé x médio]
    public static double[] MedirCorpo(Img o)
    {
        int xa = 99999, xb = -1, ya = 99999, yb = -1; double sx = 0, sy = 0; int n = 0;
        for (int y = 0; y < o.H; y++)
            for (int x = 0; x < o.W; x++)
            {
                uint c = o.Get(x, y);
                if ((c >> 24) < 128 || Claro(c) || RastroVermelho(c)) continue;
                n++; sx += x; sy += y;
                if (x < xa) xa = x; if (x > xb) xb = x; if (y < ya) ya = y; if (y > yb) yb = y;
            }
        if (n == 0) return null;
        // pés: média x dos pixels de corpo nos 12% de baixo
        double px = 0; int pn = 0;
        int corte = yb - (int)Math.Max(6, (yb - ya) * 0.12);
        for (int y = corte; y <= yb; y++)
            for (int x = 0; x < o.W; x++)
            {
                uint c = o.Get(x, y);
                if ((c >> 24) < 128 || Claro(c) || RastroVermelho(c)) continue;
                px += x; pn++;
            }
        return new double[] { xa, xb, ya, yb, sx / n, sy / n, pn > 0 ? px / pn : sx / n };
    }

    // ----------------------------------------------------------------
    // 4) ESCALA (média de área, alfa pré-multiplicado) E MONTAGEM
    // ----------------------------------------------------------------
    public static Img Escalar(Img s, double k)
    {
        int w = Math.Max(1, (int)Math.Round(s.W * k)), h = Math.Max(1, (int)Math.Round(s.H * k));
        var d = new Img(w, h);
        double inv = 1.0 / k;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                double sx0 = x * inv, sy0 = y * inv, sx1 = (x + 1) * inv, sy1 = (y + 1) * inv;
                double ar = 0, ag = 0, ab = 0, aa = 0, peso = 0;
                for (int yy = (int)Math.Floor(sy0); yy < (int)Math.Ceiling(sy1); yy++)
                    for (int xx = (int)Math.Floor(sx0); xx < (int)Math.Ceiling(sx1); xx++)
                    {
                        double wx = Math.Min(sx1, xx + 1) - Math.Max(sx0, xx), wy = Math.Min(sy1, yy + 1) - Math.Max(sy0, yy);
                        if (wx <= 0 || wy <= 0) continue;
                        double wgt = wx * wy;
                        uint c = s.Get(xx, yy);
                        double al = (c >> 24) / 255.0;
                        ar += R(c) * al * wgt; ag += G(c) * al * wgt; ab += B(c) * al * wgt; aa += al * wgt; peso += wgt;
                    }
                if (peso <= 0 || aa / peso < 0.02) continue;
                double alfa = aa / peso;
                d.Set(x, y, Argb((int)Math.Round(alfa * 255), (int)Math.Round(ar / aa), (int)Math.Round(ag / aa), (int)Math.Round(ab / aa)));
            }
        return d;
    }

    // corta as bordas vazias; devolve [x0, y0] do corte (para corrigir a âncora)
    public static Img Aparar(Img s, int[] desloc)
    {
        int xa = s.W, xb = -1, ya = s.H, yb = -1;
        for (int y = 0; y < s.H; y++)
            for (int x = 0; x < s.W; x++)
                if ((s.Get(x, y) >> 24) > 0) { if (x < xa) xa = x; if (x > xb) xb = x; if (y < ya) ya = y; if (y > yb) yb = y; }
        if (xb < 0) { desloc[0] = 0; desloc[1] = 0; return s; }
        var d = new Img(xb - xa + 1, yb - ya + 1);
        for (int y = ya; y <= yb; y++) for (int x = xa; x <= xb; x++) d.Set(x - xa, y - ya, s.Get(x, y));
        desloc[0] = xa; desloc[1] = ya;
        return d;
    }

    public static void Colar(Img dst, Img src, int dx, int dy)
    {
        for (int y = 0; y < src.H; y++)
            for (int x = 0; x < src.W; x++)
            {
                uint c = src.Get(x, y);
                if ((c >> 24) == 0) continue;
                dst.Set(x + dx, y + dy, c);
            }
    }

    // prévia: quadros lado a lado com a cruz da origem e a linha do chão
    public static void Previa(List<Img> q, int ox, int oy, string arq, string titulo)
    {
        if (q.Count == 0) return;
        int w = q.Count * (q[0].W + 10) + 10, h = q[0].H + 40;
        using (var b = new Bitmap(w, h, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(b))
        using (var f = new Font("Arial", 10))
        using (var pc = new Pen(Color.FromArgb(160, 255, 255, 0)))
        using (var pg = new Pen(Color.FromArgb(90, 255, 255, 255)))
        {
            g.Clear(Color.FromArgb(255, 40, 44, 54));
            g.DrawString(titulo, f, Brushes.White, 6, 4);
            for (int i = 0; i < q.Count; i++)
            {
                int x0 = 10 + i * (q[0].W + 10), y0 = 30;
                g.DrawRectangle(pg, x0 - 1, y0 - 1, q[i].W + 1, q[i].H + 1);
                var tmp = Path.Combine(Path.GetTempPath(), "if_" + Guid.NewGuid().ToString("N") + ".png");
                Salvar(q[i], tmp);
                using (var im = new Bitmap(tmp)) g.DrawImage(im, x0, y0, q[i].W, q[i].H);
                File.Delete(tmp);
                g.DrawLine(pc, x0, y0 + oy, x0 + q[i].W, y0 + oy);
                g.DrawLine(pc, x0 + ox, y0 + oy - 8, x0 + ox, y0 + oy + 8);
                g.DrawString(i.ToString(), f, Brushes.Yellow, x0 + 2, y0 + 2);
            }
            b.Save(arq, ImageFormat.Png);
        }
    }
}
