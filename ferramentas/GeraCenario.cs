// =====================================================================
//  GeraCenario — desenha por código o cenário da FASE 1 (a vila em chamas)
//  em pixel art, inspirado na pintura antiga (spr_fundo): casas em
//  enxaimel, igreja, torre de vigia, barracas, poço, lampiões, árvores,
//  ponte, muros, cercas, chão e as faixas distantes (montanhas, floresta,
//  vila ao longe e nuvens).
//  Saída: um atlas PNG + um JSON com as peças (região no atlas e âncoras
//  dos efeitos: chaminés, fogo no telhado, janelas acesas, luzes) e a
//  disposição da fase. O PC (GameMaker) e o Android (Godot) leem os
//  mesmos arquivos. Usado por ferramentas/gerar_cenario.ps1.
//  1 pixel = 1 pixel do mundo. A lua ilumina pela esquerda.
// =====================================================================
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Text;

public class Tela
{
    public int W, H;
    public int[] P;
    public Tela(int w, int h) { W = w; H = h; P = new int[w * h]; }
    public bool Dentro(int x, int y) { return x >= 0 && y >= 0 && x < W && y < H; }
    public void Px(int x, int y, int c) { if (Dentro(x, y)) P[y * W + x] = c; }
    public int Le(int x, int y) { return Dentro(x, y) ? P[y * W + x] : 0; }
    public bool Cheio(int x, int y) { return Dentro(x, y) && ((P[y * W + x] >> 24) & 255) > 0; }
    public void Ret(int x1, int y1, int x2, int y2, int c)
    {
        for (int y = y1; y < y2; y++) for (int x = x1; x < x2; x++) Px(x, y, c);
    }
    public void RetF(int x1, int y1, int x2, int y2, Func<int, int, int> f)
    {
        for (int y = y1; y < y2; y++) for (int x = x1; x < x2; x++) if (Dentro(x, y)) P[y * W + x] = f(x, y);
    }
    public void Linha(int x0, int y0, int x1, int y1, int c)
    {
        int dx = Math.Abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
        int dy = -Math.Abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
        int err = dx + dy;
        while (true)
        {
            Px(x0, y0, c);
            if (x0 == x1 && y0 == y1) break;
            int e2 = 2 * err;
            if (e2 >= dy) { err += dy; x0 += sx; }
            if (e2 <= dx) { err += dx; y0 += sy; }
        }
    }
    // polígono (varredura par-ímpar) pintado por uma função de cor
    public void Poligono(double[] xs, double[] ys, Func<int, int, int> f)
    {
        int n = xs.Length;
        double ymin = double.MaxValue, ymax = double.MinValue;
        for (int i = 0; i < n; i++) { ymin = Math.Min(ymin, ys[i]); ymax = Math.Max(ymax, ys[i]); }
        for (int y = (int)Math.Floor(ymin); y <= (int)Math.Ceiling(ymax); y++)
        {
            double yc = y + 0.5;
            var cortes = new List<double>();
            for (int i = 0, j = n - 1; i < n; j = i++)
            {
                double yi = ys[i], yj = ys[j];
                if ((yi <= yc && yj > yc) || (yj <= yc && yi > yc))
                    cortes.Add(xs[i] + (yc - yi) / (yj - yi) * (xs[j] - xs[i]));
            }
            cortes.Sort();
            for (int k = 0; k + 1 < cortes.Count; k += 2)
                for (int x = (int)Math.Ceiling(cortes[k] - 0.5); x <= (int)Math.Floor(cortes[k + 1] - 0.5); x++)
                    if (Dentro(x, y)) P[y * W + x] = f(x, y);
        }
    }
    public void Disco(double cx, double cy, double r, Func<int, int, int> f)
    {
        for (int y = (int)Math.Floor(cy - r - 1); y <= (int)Math.Ceiling(cy + r + 1); y++)
            for (int x = (int)Math.Floor(cx - r - 1); x <= (int)Math.Ceiling(cx + r + 1); x++)
            {
                double dx = x + 0.5 - cx, dy = y + 0.5 - cy;
                if (dx * dx + dy * dy <= r * r && Dentro(x, y)) P[y * W + x] = f(x, y);
            }
    }
    // tom de noite: escurece e azula tudo, menos as luzes (janelas, vitrais, lanternas)
    public void Noite()
    {
        for (int i = 0; i < P.Length; i++)
        {
            int c = P[i];
            int a = (c >> 24) & 255;
            if (a == 0) continue;
            int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;
            if (Math.Max(r, Math.Max(g, b)) >= 200) continue;
            r = (int)(r * 0.78 * 0.86 + 34 * 0.14);
            g = (int)(g * 0.78 * 0.86 + 30 * 0.14);
            b = (int)(b * 0.78 * 0.86 + 54 * 0.14);
            P[i] = (a << 24) | (r << 16) | (g << 8) | b;
        }
    }
    // contorno escuro de 1 px por fora do desenho
    public void Contorno(int c)
    {
        var o = (int[])P.Clone();
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
            {
                if (Cheio(x, y)) continue;
                if (Cheio(x - 1, y) || Cheio(x + 1, y) || Cheio(x, y - 1) || Cheio(x, y + 1)) o[y * W + x] = c;
            }
        P = o;
    }
}

// uma peça do cenário: o desenho e as âncoras dos efeitos (em px da peça)
public class Peca
{
    public string Nome;
    public Tela T;
    public int AX, AY;
    public List<int[]> Chamines = new List<int[]>();   // [x, y] topo da chaminé (fumaça)
    public List<int[]> Fogos = new List<int[]>();      // [x centro, y base, largura] fogo no telhado
    // v1.19: focos do incêndio presos à construção: [x1, y1, x2, y2, altura, tipo]
    //  tipo 0 = beiral/água do telhado (a base segue a linha x1,y1 -> x2,y2)
    //  tipo 1 = rombo no telhado (labareda alta saindo do buraco)
    //  tipo 2 = janela quebrada (brilho dentro do vão x1,y1-x2,y2; línguas subindo da verga)
    //  tipo 3 = escombros (muitas chamas baixas ao longo da linha)
    public List<int[]> Focos = new List<int[]>();
    public List<int[]> Janelas = new List<int[]>();    // [x, y, w, h] janelas acesas
    public List<int[]> Luzes = new List<int[]>();      // [x, y, raio] lampiões, lanternas, vitrais
    public Peca(string n, Tela t) { Nome = n; T = t; }
}

public static class Gera
{
    // ---------------------------------------------------------------- cores
    public static int C(int r, int g, int b) { return CA(r, g, b, 255); }
    public static int CA(int r, int g, int b, int a) { return (Cl(a) << 24) | (Cl(r) << 16) | (Cl(g) << 8) | Cl(b); }
    static int Cl(int v) { return v < 0 ? 0 : (v > 255 ? 255 : v); }
    public static int A(int c) { return (c >> 24) & 255; }
    public static int R(int c) { return (c >> 16) & 255; }
    public static int Gc(int c) { return (c >> 8) & 255; }
    public static int B(int c) { return c & 255; }
    public static int Mix(int a, int b, double t)
    {
        return CA((int)(R(a) + (R(b) - R(a)) * t + 0.5), (int)(Gc(a) + (Gc(b) - Gc(a)) * t + 0.5),
            (int)(B(a) + (B(b) - B(a)) * t + 0.5), (int)(A(a) + (A(b) - A(a)) * t + 0.5));
    }
    public static int Esc(int c, double f) { return CA((int)(R(c) * f), (int)(Gc(c) * f), (int)(B(c) * f), A(c)); }
    public static double Hs(int x, int y, int s)
    {
        unchecked
        {
            uint h = (uint)(x * 374761393 + y * 668265263 + s * 982451653);
            h = (h ^ (h >> 13)) * 1274126177u;
            h ^= h >> 16;
            return (h & 0xFFFFFF) / 16777216.0;
        }
    }
    // luar vindo da esquerda: o lado direito de cada peça fica mais escuro
    public static int Luz(int c, int dx, int larg)
    {
        double t = larg <= 1 ? 0.5 : Math.Max(0, Math.Min(1, (double)dx / larg));
        return Esc(c, 1.05 - 0.22 * t);
    }

    static readonly int CONTORNO = C(20, 14, 16);

    // ------------------------------------------------------------ materiais
    public static Func<int, int, int> Gesso(int seed, int x0, int larg)
    {
        int claro = C(184, 168, 148), meio = C(160, 145, 127), sombra = C(136, 122, 106);
        return (x, y) =>
        {
            double n = Hs(x, y, seed);
            int c = n < 0.07 ? sombra : (n > 0.94 ? claro : meio);
            if (Hs(x / 4, y / 3, seed + 7) < 0.18) c = Esc(c, 0.92);
            return Luz(c, x - x0, larg);
        };
    }
    public static Func<int, int, int> Telhas(int seed, int y0, int x0, int larg, int baseC, int claroC, int escC, int juntaC, int alt, int lar)
    {
        return (x, y) =>
        {
            int dy = Math.Max(0, y - y0);
            int r = dy / alt, ry = dy % alt;
            int off = (r % 2) * (lar / 2);
            int col = (x + off + 1000) / lar, rx = (x + off + 1000) % lar;
            int c = baseC;
            double v = Hs(col, r, seed);
            if (v < 0.14) c = Esc(c, 0.86); else if (v > 0.9) c = Esc(c, 1.08);
            if (ry == 0) c = claroC;
            else if (ry == alt - 1) c = escC;
            else if (rx == 0) c = juntaC;
            if (Hs(x, y, seed + 3) < 0.03) c = C(72, 80, 54);
            return Luz(c, x - x0, larg);
        };
    }
    public static Func<int, int, int> TelhaBarro(int seed, int y0, int x0, int larg)
    {
        return Telhas(seed, y0, x0, larg, C(126, 64, 52), C(158, 90, 70), C(84, 40, 34), C(98, 48, 40), 4, 6);
    }
    public static Func<int, int, int> Ardosia(int seed, int y0, int x0, int larg)
    {
        return Telhas(seed, y0, x0, larg, C(74, 76, 94), C(102, 104, 122), C(48, 50, 64), C(58, 60, 74), 3, 5);
    }
    public static void Pedras(Tela t, int x1, int y1, int x2, int y2, int seed, int baseC, int luzX0, int larg)
    {
        var rng = new Random(seed);
        int y = y1, linha = 0;
        while (y < y2)
        {
            int h = Math.Min(y2 - y, 5 + rng.Next(3));
            int x = x1 - (linha % 2) * rng.Next(3, 7);
            while (x < x2)
            {
                int w = 7 + rng.Next(8);
                int c = Esc(baseC, 0.86 + rng.NextDouble() * 0.24);
                for (int yy = y; yy < y + h; yy++)
                    for (int xx = Math.Max(x, x1); xx < Math.Min(x + w, x2); xx++)
                    {
                        int cc = c;
                        if (yy == y + h - 1 || xx == x + w - 1) cc = C(48, 44, 50);
                        else if (yy == y || xx == x) cc = Mix(c, C(172, 168, 170), 0.35);
                        else if (yy == y + h - 2 || xx == x + w - 2) cc = Esc(c, 0.82);
                        else if (Hs(xx, yy, seed) < 0.08) cc = Esc(c, 0.9);
                        t.Px(xx, yy, Luz(cc, xx - luzX0, larg));
                    }
                x += w;
            }
            y += h; linha++;
        }
    }
    // pedras que emendam dos dois lados (faixa repetida)
    public static void PedrasRepetidas(Tela t, int y1, int y2, int seed, int baseC)
    {
        var rng = new Random(seed);
        int W = t.W, y = y1, linha = 0;
        while (y < y2)
        {
            int h = Math.Min(y2 - y, 5 + rng.Next(3));
            var cortes = new List<int>();
            int soma = 0;
            while (soma < W) { int w = 8 + rng.Next(8); if (W - soma - w < 7) w = W - soma; cortes.Add(w); soma += w; }
            int off = rng.Next(W);
            int x = 0;
            foreach (int w in cortes)
            {
                int c = Esc(baseC, 0.86 + rng.NextDouble() * 0.24);
                for (int yy = y; yy < y + h; yy++)
                    for (int k = 0; k < w; k++)
                    {
                        int xx = (x + k + off) % W;
                        int cc = c;
                        if (yy == y + h - 1 || k == w - 1) cc = C(46, 42, 48);
                        else if (yy == y || k == 0) cc = Mix(c, C(168, 164, 166), 0.32);
                        else if (yy == y + h - 2 || k == w - 2) cc = Esc(c, 0.82);
                        else if (Hs(xx, yy, seed) < 0.08) cc = Esc(c, 0.9);
                        t.Px(xx, yy, cc);
                    }
                x += w;
            }
            y += h; linha++;
        }
    }
    public static void Viga(Tela t, int x1, int y1, int x2, int y2)
    {
        for (int y = y1; y < y2; y++)
            for (int x = x1; x < x2; x++)
            {
                int c = C(70, 48, 36);
                if (y == y1 && y2 - y1 > 2) c = C(98, 70, 52);
                else if (y == y2 - 1 && y2 - y1 > 2) c = C(44, 30, 22);
                else if (x2 - x1 <= 3 && x == x1) c = C(92, 66, 48);
                t.Px(x, y, c);
            }
    }
    public static void VigaDiag(Tela t, int x1, int y1, int x2, int y2)
    {
        t.Linha(x1, y1, x2, y2, C(66, 45, 34));
        t.Linha(x1 + 1, y1, x2 + 1, y2, C(52, 36, 27));
    }
    public static void Janela(Tela t, int x, int y, int w, int h, bool acesa, bool quebrada, int seed)
    {
        int moldura = C(44, 30, 24);
        t.Ret(x - 1, y - 1, x + w + 1, y + h + 1, moldura);
        for (int yy = y; yy < y + h; yy++)
            for (int xx = x; xx < x + w; xx++)
            {
                int c;
                if (quebrada) c = Hs(xx, yy, seed) < 0.5 ? C(16, 12, 14) : C(30, 22, 24);
                else if (acesa)
                {
                    double cx = (xx - x + 0.5) / w - 0.5, cy = (yy - y + 0.5) / h - 0.5;
                    double d = Math.Sqrt(cx * cx + cy * cy) * 1.6;
                    c = Mix(C(255, 228, 152), C(212, 126, 58), Math.Min(1, d));
                }
                else c = ((xx - x + yy - y) % 5 == 0) ? C(70, 76, 100) : C(34, 36, 52);
                t.Px(xx, yy, c);
            }
        int mx = x + w / 2, my = y + h / 2;
        for (int yy = y; yy < y + h; yy++) t.Px(mx, yy, moldura);
        for (int xx = x; xx < x + w; xx++) t.Px(xx, my, moldura);
        t.Ret(x - 2, y + h + 1, x + w + 2, y + h + 2, C(112, 88, 66));
    }
    // vitral em arco (igreja): âmbar e roxo
    public static void Vitral(Tela t, int x, int y, int w, int h)
    {
        int r = w / 2;
        double cx = x + w / 2.0;
        for (int yy = y - 1; yy < y + h + 1; yy++)
            for (int xx = x - 1; xx < x + w + 1; xx++)
            {
                double dy = (y + r) - (yy + 0.5), dx = xx + 0.5 - cx;
                bool arco = yy >= y + r || dx * dx + dy * dy <= (r + 1) * (r + 1);
                if (!arco) continue;
                bool borda = xx == x - 1 || xx == x + w || yy == y + h || (yy < y + r && dx * dx + dy * dy > r * r);
                int c;
                if (borda) c = C(40, 34, 40);
                else if ((xx - x) == w / 2 || (yy - y) % 5 == 0) c = C(54, 40, 50);
                else c = ((xx - x) < w / 2) ^ (((yy - y) / 5) % 2 == 0) ? C(238, 168, 78) : C(152, 92, 206);
                t.Px(xx, yy, c);
            }
    }
    public static void Porta(Tela t, int x, int y, int w, int h)
    {
        int r = w / 2;
        double cx = x + w / 2.0;
        for (int yy = y - 1; yy < y + h; yy++)
            for (int xx = x - 1; xx < x + w + 1; xx++)
            {
                double dy = (y + r) - (yy + 0.5), dx = xx + 0.5 - cx;
                bool arco = yy >= y + r || dx * dx + dy * dy <= (r + 1) * (r + 1);
                if (!arco) continue;
                bool borda = xx == x - 1 || xx == x + w || (yy < y + r && dx * dx + dy * dy > r * r);
                int c = borda ? C(122, 114, 114) : (((xx - x) % 3 == 0) ? C(58, 38, 26) : C(94, 64, 44));
                t.Px(xx, yy, c);
            }
        t.Px(x + w - 3, y + h / 2 + 2, C(206, 172, 90));
    }
    static void Chamine(Tela t, Peca p, int cx, int yTopo, int yBase, int seed)
    {
        Pedras(t, cx, yTopo, cx + 7, yBase, seed, C(118, 92, 84), cx, 7);
        t.Ret(cx - 1, yTopo - 2, cx + 8, yTopo, C(62, 54, 54));
        p.Chamines.Add(new[] { cx + 3, yTopo - 3 });
    }

    // ---------------------------------------------------------------- casas
    // W = largura da parede; frontal = empena virada para a frente
    // queimada = casa já tomada pela maldição (telhado furado, fuligem)
    public static Peca Casa(string nome, int seed, int W, int andares, bool frontal, bool queimada)
    {
        var rng = new Random(seed);
        int beiral = 6, jetty = andares > 1 ? 3 : 0, plinto = 6, andarH = 30;
        int paredeH = plinto + andares * andarH;
        int telhadoH = frontal ? (int)(W * 0.55) : (int)(W * 0.36) + 6;
        int Wt = W + 2 * (beiral + jetty) + 4;
        int H = paredeH + telhadoH + 24;
        var t = new Tela(Wt, H);
        var p = new Peca(nome, t);
        int ox = beiral + jetty + 2;
        int baseY = H - 1;
        int topoParede = baseY + 1 - paredeH;
        Pedras(t, ox, baseY + 1 - plinto, ox + W, baseY + 1, seed + 11, C(100, 96, 100), ox, W);
        for (int f = 0; f < andares; f++)
        {
            int y2 = baseY + 1 - plinto - f * andarH, y1 = y2 - andarH;
            int j = f > 0 ? jetty : 0;
            int x1 = ox - j, x2 = ox + W + j;
            t.RetF(x1, y1, x2, y2, Gesso(seed + f, x1, x2 - x1));
            Viga(t, x1, y1, x2, y1 + 3);
            Viga(t, x1, y2 - 3, x2, y2);
            int nPostes = Math.Max(2, (x2 - x1) / 17 + 1);
            var postes = new List<int>();
            for (int k = 0; k < nPostes; k++)
            {
                int px = x1 + (int)Math.Round(k * (x2 - x1 - 3) / (double)(nPostes - 1));
                postes.Add(px);
                Viga(t, px, y1, px + 3, y2);
            }
            int meio = (postes.Count - 1) / 2;
            for (int k = 0; k + 1 < postes.Count; k++)
            {
                int vx1 = postes[k] + 3, vx2 = postes[k + 1], vw = vx2 - vx1;
                if (vw < 8) continue;
                if (f == 0 && k == meio && vw >= 10)
                {
                    int pw = Math.Min(12, vw - 2), ph = 20;
                    Porta(t, vx1 + (vw - pw) / 2, y2 - 3 - ph, pw, ph);
                }
                else if (rng.NextDouble() < 0.78)
                {
                    int jw = Math.Min(8, vw - 4), jh = 10;
                    int jx = vx1 + (vw - jw) / 2, jy = y1 + 8;
                    bool acesa = !queimada && rng.NextDouble() < 0.7;
                    bool quebrada = queimada && rng.NextDouble() < 0.7;
                    Janela(t, jx, jy, jw, jh, acesa, quebrada, seed + k + f * 10);
                    if (acesa) p.Janelas.Add(new[] { jx, jy, jw, jh });
                    // v1.19: o fogo de dentro sai pelas janelas quebradas (mais no andar de cima)
                    if (quebrada && (f == andares - 1 || Hs(k, f, seed + 13) < 0.45))
                        p.Focos.Add(new[] { jx, jy, jx + jw, jy + jh, 12 + (int)(8 * Hs(k, f, seed + 14)), 2 });
                }
                else
                {
                    VigaDiag(t, vx1, y1 + 3, vx2 - 2, y2 - 4);
                    VigaDiag(t, vx2 - 2, y1 + 3, vx1, y2 - 4);
                }
            }
        }
        // ----- telhado -----
        int jt = jetty;
        int ry2 = topoParede + 2;
        int rx1 = ox - jt - beiral, rx2 = ox + W + jt + beiral;
        int ry1 = topoParede - telhadoH;
        var telha = TelhaBarro(seed + 21, ry1, rx1, rx2 - rx1);
        int beiralC = C(58, 30, 26);
        if (!frontal)
        {
            int inset = (int)(telhadoH * 0.85);
            t.Poligono(new double[] { rx1, rx1 + inset, rx2 - inset, rx2 }, new double[] { ry2, ry1, ry1, ry2 }, telha);
            t.Ret(rx1, ry2 - 2, rx2, ry2, beiralC);
            t.Ret(rx1 + inset, ry1, rx2 - inset, ry1 + 1, C(172, 102, 82));
            p.Fogos.Add(new[] { (rx1 + rx2) / 2, ry1 + 3, Math.Max(16, rx2 - rx1 - 2 * inset + 8) });
            if (W >= 84 && rng.NextDouble() < 0.75)
            {
                int dw = 16, dxl = (rx1 + rx2) / 2 - dw / 2 + rng.Next(-12, 13), dyb = ry2 - telhadoH / 3;
                t.RetF(dxl + 2, dyb - 10, dxl + dw - 2, dyb, Gesso(seed + 31, dxl, dw));
                bool acesa = !queimada;
                Janela(t, dxl + 5, dyb - 8, 6, 6, acesa, queimada, seed + 41);
                if (acesa) p.Janelas.Add(new[] { dxl + 5, dyb - 8, 6, 6 });
                if (queimada) p.Focos.Add(new[] { dxl + 5, dyb - 8, dxl + 11, dyb - 2, 12, 2 });
                t.Poligono(new double[] { dxl - 1, dxl + dw / 2.0, dxl + dw + 1 }, new double[] { dyb - 9, dyb - 19, dyb - 9 }, telha);
                t.Linha(dxl - 1, dyb - 9, dxl + dw / 2, dyb - 19, beiralC);
                t.Linha(dxl + dw / 2, dyb - 19, dxl + dw + 1, dyb - 9, beiralC);
            }
            int nCh = W >= 90 ? 2 : 1;
            for (int k = 0; k < nCh; k++)
            {
                int chx = nCh == 1 ? rx2 - inset - 14 : (k == 0 ? rx1 + inset + 4 : rx2 - inset - 12);
                Chamine(t, p, chx, ry1 - 11, ry1 + 4, seed + 60 + k);
            }
        }
        else
        {
            int cx = (rx1 + rx2) / 2;
            t.Poligono(new double[] { ox - jt, cx, ox + W + jt }, new double[] { topoParede + 1, ry1 + 7, topoParede + 1 }, Gesso(seed + 51, ox, W));
            Viga(t, ox - jt, topoParede - 2, ox + W + jt, topoParede + 1);
            Viga(t, cx - 1, ry1 + 9, cx + 2, topoParede - 2);
            VigaDiag(t, cx, topoParede - 4, ox - jt + 8, topoParede - 3 - (telhadoH / 4));
            VigaDiag(t, cx, topoParede - 4, ox + W + jt - 8, topoParede - 3 - (telhadoH / 4));
            int jy = topoParede - telhadoH / 2;
            bool acesa = !queimada && rng.NextDouble() < 0.85;
            Janela(t, cx - 4, jy, 8, 9, acesa, queimada, seed + 71);
            if (acesa) p.Janelas.Add(new[] { cx - 4, jy, 8, 9 });
            if (queimada) p.Focos.Add(new[] { cx - 4, jy, cx + 4, jy + 9, 16, 2 });
            double ex = 11;
            t.Poligono(new double[] { cx, rx1, rx1 + ex, cx }, new double[] { ry1, ry2, ry2, ry1 + ex * 0.9 }, telha);
            t.Poligono(new double[] { cx, cx, rx2 - ex, rx2 }, new double[] { ry1, ry1 + ex * 0.9, ry2, ry2 }, telha);
            t.Linha(cx, ry1, rx1, ry2, beiralC);
            t.Linha(cx, ry1, rx2, ry2, beiralC);
            t.Linha(cx, ry1 - 1, rx1 + 1, ry2 - 1, C(176, 108, 84));
            p.Fogos.Add(new[] { cx, ry1 + 6, Math.Max(18, (rx2 - rx1) / 2) });
            int chx = cx + (rx2 - cx) / 2 - 2;
            double tYr = ry1 + (ry2 - ry1) * (chx + 3.5 - cx) / (rx2 - cx);
            Chamine(t, p, chx, (int)tYr - 12, (int)tYr + 3, seed + 80);
        }
        if (queimada)
        {
            Queimar(t, p, rx1, rx2, ry1, ry2, topoParede, baseY, seed);
            // v1.19: o fogo corre pelo telhado de verdade: o cume e UMA das águas
            // (o lado que pega é sorteado pela semente; o outro fica só nos rombos)
            bool esq = Hs(seed, 3, 17) < 0.5;
            if (!frontal)
            {
                int inset = (int)(telhadoH * 0.85);
                int ax = rx1 + inset, bx = rx2 - inset;
                p.Focos.Add(new[] { ax + 2, ry1 + 1, bx - 2, ry1 + 1, 18, 0 });
                if (esq) p.Focos.Add(new[] { rx1 + inset * 45 / 100, ry1 + (ry2 - ry1) * 55 / 100, ax, ry1 + 1, 14, 0 });
                else p.Focos.Add(new[] { bx, ry1 + 1, rx2 - inset * 45 / 100, ry1 + (ry2 - ry1) * 55 / 100, 14, 0 });
            }
            else
            {
                int cx = (rx1 + rx2) / 2;
                double l1 = esq ? 0.7 : 0.35, l2 = esq ? 0.35 : 0.7;     // quanto de cada água está queimando
                p.Focos.Add(new[] { cx - (int)((cx - rx1) * l1), ry1 + (int)((ry2 - ry1) * l1), cx, ry1 + 1, 16, 0 });
                p.Focos.Add(new[] { cx, ry1 + 1, cx + (int)((rx2 - cx) * l2), ry1 + (int)((ry2 - ry1) * l2), 16, 0 });
            }
        }
        t.Contorno(CONTORNO);
        return p;
    }
    // telhado com rombos (caibros à mostra) e fuligem nas paredes
    static void Queimar(Tela t, Peca p, int rx1, int rx2, int ry1, int ry2, int topoParede, int baseY, int seed)
    {
        var rng = new Random(seed + 900);
        int furos = 2 + rng.Next(2);
        for (int k = 0; k < furos; k++)
        {
            int cx = rx1 + 10 + rng.Next(Math.Max(1, rx2 - rx1 - 20));
            int cy = ry1 + (ry2 - ry1) / 3 + rng.Next(Math.Max(1, (ry2 - ry1) / 2));
            int rr = 6 + rng.Next(6);
            // v1.19: a labareda mais forte sai de dentro de cada rombo
            if (t.Cheio(cx, cy) && t.Cheio(cx, cy + rr / 3))      // só rombo que caiu sobre a casa (não no ar)
                p.Focos.Add(new[] { cx - rr / 2, cy + rr / 3, cx + rr / 2, cy + rr / 3, 22 + rr * 2, 1 });
            for (int y = cy - rr; y <= cy + rr; y++)
                for (int x = cx - rr - 3; x <= cx + rr + 3; x++)
                {
                    double d = Math.Sqrt((x - cx) * (x - cx) * 0.7 + (y - cy) * (y - cy));
                    if (d > rr * (0.75 + 0.35 * Hs(x, y, seed)) || !t.Cheio(x, y) || y > ry2 - 2) continue;
                    int c = ((x - cx + 40) % 5 == 0) ? C(62, 40, 30) : C(22, 16, 18);
                    if (d > rr * 0.7) c = C(48, 30, 26);
                    t.Px(x, y, c);
                }
        }
        // fuligem subindo das janelas e portas
        for (int y = topoParede; y <= baseY; y++)
            for (int x = rx1; x <= rx2; x++)
            {
                if (!t.Cheio(x, y)) continue;
                double n = Hs(x / 3, y / 4, seed + 5);
                if (n < 0.22) t.Px(x, y, Esc(t.Le(x, y), 0.62));
            }
    }

    // ------------------------------------------- casas destruídas (v1.14)
    // monte de escombros: pedra, tijolo, telha e carvão, com brasas acesas
    static void Escombro(Tela t, int x1, int x2, int baseY, int alt, int seed)
    {
        double meio = (x1 + x2) / 2.0, meia = Math.Max(1, (x2 - x1) / 2.0);
        for (int x = x1; x < x2; x++)
        {
            double u = (x - meio) / meia;
            double hh = alt * Math.Max(0, 1 - u * u) * (0.72 + 0.28 * Hs(x / 3, 1, seed)) + (Hs(x, 2, seed) < 0.3 ? 1 : 0);
            int topo = baseY - (int)hh;
            for (int y = topo; y <= baseY; y++)
            {
                double n = Hs(x / 2, y / 2, seed + 3);
                int c;
                if (n < 0.28) c = C(96, 90, 96);            // pedra
                else if (n < 0.46) c = C(118, 62, 48);      // tijolo e telha
                else if (n < 0.78) c = C(52, 40, 36);       // terra queimada
                else c = C(26, 20, 20);                     // carvão
                if (y == topo) c = Mix(c, C(150, 140, 140), 0.25);
                if (y > topo + 1 && Hs(x, y, seed + 9) < 0.025) c = Hs(x, y, seed + 11) < 0.5 ? C(255, 116, 42) : C(224, 66, 30);   // brasa
                t.Px(x, y, Luz(c, x - x1, x2 - x1));
            }
        }
    }
    // viga carbonizada (a ponta ainda em brasa)
    static void VigaQueimada(Tela t, int x1, int y1, int x2, int y2, bool brasaNaPonta)
    {
        t.Linha(x1, y1, x2, y2, C(30, 22, 20));
        t.Linha(x1 + 1, y1, x2 + 1, y2, C(48, 34, 28));
        t.Linha(x1 + 2, y1, x2 + 2, y2, C(22, 16, 16));
        if (brasaNaPonta) { t.Px(x2, y2, C(255, 120, 44)); t.Px(x2 + 1, y2, C(232, 72, 32)); }
    }
    // reboco coberto de fuligem
    static Func<int, int, int> GessoQueimado(int seed, int x0, int larg)
    {
        var g = Gesso(seed, x0, larg);
        return (x, y) =>
        {
            double n = Hs(x / 3, y / 4, seed + 5);
            return Esc(g(x, y), n < 0.35 ? 0.42 : (n < 0.7 ? 0.58 : 0.72));
        };
    }
    // abre um buraco irregular (transparente) na peça
    static void Rombo(Tela t, double cx, double cy, double rx, double ry, int seed)
    {
        for (int y = (int)(cy - ry - 2); y <= (int)(cy + ry + 2); y++)
            for (int x = (int)(cx - rx - 2); x <= (int)(cx + rx + 2); x++)
            {
                double dx = (x - cx) / rx, dy = (y - cy) / ry;
                if (Math.Sqrt(dx * dx + dy * dy) > 0.78 + 0.32 * Hs(x, y, seed)) continue;
                if (t.Dentro(x, y)) t.P[y * t.W + x] = 0;
            }
    }
    // tipo 0: só o térreo de pé, a borda de cima quebrada, postes carbonizados
    //         apontando para o céu, uma viga caída e a chaminé sozinha
    // tipo 1: o telhado desabou para dentro (as duas águas em "V", caibros à mostra)
    // tipo 2: só a empena da frente de pé, furada, sobre o monte de escombros
    // tipo 3: monte de escombros com o batente da porta ainda de pé
    public static Peca Destruida(string nome, int seed, int W, int tipo)
    {
        var rng = new Random(seed);
        int plinto = 6, andarH = 30;
        int H = tipo == 0 ? 84 : (tipo == 1 ? 76 : (tipo == 2 ? 104 : 58));
        var t = new Tela(W + 24, H);
        var p = new Peca(nome, t);
        int x1 = 12, x2 = 12 + W, baseY = H - 1;
        if (tipo == 0)
        {
            int topo = baseY + 1 - plinto - andarH;
            Pedras(t, x1, baseY + 1 - plinto, x2, baseY + 1, seed + 11, C(92, 88, 94), x1, W);
            var g = GessoQueimado(seed, x1, W);
            for (int x = x1; x < x2; x++)
            {
                double u = (x - x1) / (double)W;
                int quebra = (int)(10 * Hs(x / 4, 0, seed) + 8 * Math.Max(0, Math.Sin(u * 7 + seed)) + (u > 0.55 && u < 0.8 ? 12 : 0));
                for (int y = topo + quebra; y < baseY + 1 - plinto; y++) t.Px(x, y, g(x, y));
            }
            Viga(t, x1, baseY + 1 - plinto - 3, x2, baseY + 1 - plinto);
            for (int k = 0; k < W / 26; k++) Janela(t, x1 + 8 + k * 26, topo + 13, 8, 9, false, true, seed + k);
            Rombo(t, x1 + W * 0.5, baseY - plinto - 10, 7, 11, seed + 3);
            int nP = 3 + rng.Next(2), meioX = x1, meioY = topo;
            for (int k = 0; k < nP; k++)
            {
                int px = x1 + 2 + (int)Math.Round(k * (W - 6) / (double)(nP - 1));
                int alto = Math.Max(6, topo - 12 - rng.Next(30));
                VigaQueimada(t, px, topo + 6, px, alto, rng.NextDouble() < 0.5);
                if (k == nP / 2) { meioX = px; meioY = alto; }
            }
            VigaQueimada(t, meioX, meioY + 2, Math.Min(x2 + 8, meioX + W / 2 + 6), baseY - 4, true);
            int chx = rng.NextDouble() < 0.5 ? x1 + 4 : x2 - 12;
            Pedras(t, chx, Math.Max(4, topo - 40), chx + 8, topo + 8, seed + 77, C(110, 88, 82), chx, 8);
            p.Chamines.Add(new[] { chx + 4, Math.Max(2, topo - 42) });
            Escombro(t, x1 - 10, x2 + 10, baseY, 9, seed + 21);
            p.Fogos.Add(new[] { (x1 + x2) / 2, topo + 10, Math.Max(18, W - 20) });
            // v1.19: o fogo come o que sobrou do andar (a borda quebrada) e os escombros
            p.Focos.Add(new[] { x1 + 4, topo + 16, x1 + W * 55 / 100, topo + 12, 14, 0 });
            p.Focos.Add(new[] { x1 - 6, baseY - 5, x2 + 6, baseY - 5, 10, 3 });
            p.Focos.Add(new[] { x1 + 8, topo + 13, x1 + 16, topo + 22, 12, 2 });
        }
        else if (tipo == 1)
        {
            int topo = baseY + 1 - plinto - andarH;
            Pedras(t, x1, baseY + 1 - plinto, x2, baseY + 1, seed + 11, C(92, 88, 94), x1, W);
            t.RetF(x1, topo, x2, baseY + 1 - plinto, GessoQueimado(seed, x1, W));
            Viga(t, x1, topo, x2, topo + 3);
            for (int px = x1; px < x2 - 2; px += 17) Viga(t, px, topo, px + 3, baseY + 1 - plinto);
            Janela(t, x1 + 6, topo + 9, 8, 10, false, true, seed + 4);
            Janela(t, x2 - 14, topo + 9, 8, 10, false, true, seed + 5);
            int rx1 = x1 - 6, rx2 = x2 + 6, cx = (x1 + x2) / 2;
            var telha = TelhaBarro(seed + 21, topo - 40, rx1, rx2 - rx1);
            Func<int, int, int> telhaQ = (x, y) => Esc(telha(x, y), Hs(x / 3, y / 3, seed + 8) < 0.4 ? 0.5 : 0.78);
            // água esquerda ainda presa na parede, caindo para o meio
            t.Poligono(new double[] { rx1, x1 + 10, cx - 6, cx - 10 }, new double[] { topo + 2, topo - 26, topo + 6, topo + 12 }, telhaQ);
            // água direita partida, com a ponta enterrada
            t.Poligono(new double[] { cx + 4, x2 - 8, rx2, cx + 10 }, new double[] { topo + 14, topo - 18, topo + 2, topo + 18 }, telhaQ);
            for (int k = 0; k < 5; k++)
            {
                int bx = cx - 16 + k * 8;
                VigaQueimada(t, bx, topo - 20 + rng.Next(8), bx + 6 - rng.Next(12), topo + 10, k % 2 == 0);
            }
            Rombo(t, cx, topo + 2, 9, 7, seed + 6);
            Escombro(t, x1 - 6, x2 + 6, baseY, 6, seed + 22);
            p.Fogos.Add(new[] { cx, topo - 4, Math.Max(16, W / 2) });
            p.Chamines.Add(new[] { cx, topo - 8 });
            // v1.19: o telhado desabado arde no "V" e pela água esquerda que ainda está presa
            p.Focos.Add(new[] { cx - 8, topo + 6, cx + 8, topo + 8, 30, 1 });
            p.Focos.Add(new[] { x1 + 10, topo - 24, cx - 9, topo + 4, 14, 0 });
            p.Focos.Add(new[] { x2 - 14, topo + 9, x2 - 6, topo + 19, 12, 2 });
        }
        else if (tipo == 2)
        {
            int topoParede = baseY + 1 - plinto - andarH * 2;
            int cx = (x1 + x2) / 2;
            var g = GessoQueimado(seed, x1, W);
            int ex1 = x1 + W / 6, ex2 = x2 - W / 6;
            t.RetF(ex1, topoParede, ex2, baseY - 8, g);
            t.Poligono(new double[] { ex1, cx, ex2 }, new double[] { topoParede + 1, topoParede - (ex2 - ex1) * 0.55, topoParede + 1 }, g);
            Viga(t, ex1, topoParede - 2, ex2, topoParede + 1);
            Viga(t, ex1, topoParede, ex1 + 3, baseY - 8);
            Viga(t, ex2 - 3, topoParede, ex2, baseY - 8);
            Viga(t, cx - 1, topoParede - 20, cx + 2, topoParede);
            Janela(t, cx - 4, topoParede - 18, 8, 9, false, true, seed + 2);
            Janela(t, ex1 + 6, topoParede + 10, 8, 10, false, true, seed + 3);
            Rombo(t, cx + 6, topoParede + 18, 10, 13, seed + 4);
            Rombo(t, ex2 - 2, topoParede - 8, 9, 14, seed + 5);          // a quina quebrada
            VigaQueimada(t, ex1 + 4, topoParede - 4, x1 - 6, baseY - 10, true);
            Escombro(t, x1 - 10, x2 + 10, baseY, 18, seed + 23);
            p.Fogos.Add(new[] { cx, baseY - 14, Math.Max(18, W - 16) });
            // v1.19: a empena furada: fogo saindo do rombo, da janela e do monte de escombros
            p.Focos.Add(new[] { cx + 1, topoParede + 26, cx + 11, topoParede + 26, 26, 1 });
            p.Focos.Add(new[] { cx - 4, topoParede - 18, cx + 4, topoParede - 9, 12, 2 });
            p.Focos.Add(new[] { x1 - 4, baseY - 12, x2 + 4, baseY - 10, 14, 3 });
        }
        else
        {
            int cx = (x1 + x2) / 2 + rng.Next(-8, 9);
            Viga(t, cx - 9, baseY - 34, cx - 6, baseY);
            Viga(t, cx + 6, baseY - 34, cx + 9, baseY);
            Viga(t, cx - 11, baseY - 37, cx + 11, baseY - 33);
            for (int k = 0; k < 3; k++)
            {
                int bx = x1 + 6 + rng.Next(Math.Max(1, W - 12));
                VigaQueimada(t, bx, baseY - 30 - rng.Next(14), bx + rng.Next(-14, 15), baseY - 6, true);
            }
            Escombro(t, x1 - 10, x2 + 10, baseY, 22, seed + 24);
            p.Fogos.Add(new[] { (x1 + x2) / 2, baseY - 18, Math.Max(18, W - 10) });
            // v1.19: o monte arde em chamas baixas; a mais alta sai do pé do batente
            p.Focos.Add(new[] { x1 - 4, baseY - 14, (x1 + x2) / 2 - 4, baseY - 21, 16, 3 });
            p.Focos.Add(new[] { (x1 + x2) / 2 + 4, baseY - 21, x2 + 4, baseY - 12, 13, 3 });
            p.Focos.Add(new[] { cx - 6, baseY - 4, cx + 6, baseY - 4, 24, 1 });
        }
        t.Contorno(CONTORNO);
        return p;
    }

    // --------------------------------------------------------------- igreja
    public static Peca Igreja(int seed)
    {
        int torreW = 32, corpoW = 104, corpoH = 58, telH = 30, torreH = 118, flecha = 66;
        int Wt = torreW + corpoW + 18, H = torreH + flecha + 16;
        var t = new Tela(Wt, H);
        var p = new Peca("igreja", t);
        int baseY = H - 1;
        int tx = 6, cx1 = tx + torreW, cx2 = cx1 + corpoW;
        int pedraC = C(112, 108, 114);
        // corpo
        Pedras(t, cx1, baseY + 1 - corpoH, cx2, baseY + 1, seed, pedraC, cx1, corpoW);
        for (int k = 0; k < 3; k++)
        {
            int vx = cx1 + 18 + k * 30, vy = baseY + 1 - corpoH + 14;
            Vitral(t, vx, vy, 8, 24);
            p.Luzes.Add(new[] { vx + 4, vy + 12, 14 });
        }
        int ry1 = baseY + 1 - corpoH - telH, ry2 = baseY + 1 - corpoH + 2;
        var ard = Ardosia(seed + 5, ry1, cx1 - 4, corpoW + 8);
        t.Poligono(new double[] { cx1 - 4, cx1 + 16, cx2 - 16, cx2 + 5 }, new double[] { ry2, ry1, ry1, ry2 }, ard);
        t.Ret(cx1 - 4, ry2 - 2, cx2 + 5, ry2, C(40, 40, 52));
        // torre
        int ty1 = baseY + 1 - torreH;
        Pedras(t, tx, ty1, tx + torreW, baseY + 1, seed + 3, Esc(pedraC, 1.04), tx, torreW);
        Porta(t, tx + 9, baseY + 1 - 26, 14, 26);
        // rosácea
        double rx = tx + torreW / 2.0, ryc = ty1 + 50;
        t.Disco(rx, ryc, 7, (x, y) => C(40, 34, 40));
        t.Disco(rx, ryc, 6, (x, y) =>
        {
            double a = Math.Atan2(y + 0.5 - ryc, x + 0.5 - rx);
            return ((int)Math.Floor((a + Math.PI) / (Math.PI / 4)) % 2 == 0) ? C(238, 168, 78) : C(152, 92, 206);
        });
        t.Disco(rx, ryc, 1.5, (x, y) => C(255, 236, 170));
        p.Luzes.Add(new[] { (int)rx, (int)ryc, 16 });
        // sineira: duas aberturas em arco com o sino
        for (int k = 0; k < 2; k++)
        {
            int ax = tx + 6 + k * 13;
            for (int yy = ty1 + 10; yy < ty1 + 26; yy++)
                for (int xx = ax; xx < ax + 7; xx++)
                {
                    double dy = (ty1 + 13.5) - (yy + 0.5), dx = xx + 0.5 - (ax + 3.5);
                    if (yy < ty1 + 13 && dx * dx + dy * dy > 12.5) continue;
                    t.Px(xx, yy, C(18, 14, 18));
                }
            t.Ret(ax + 2, ty1 + 17, ax + 5, ty1 + 22, C(172, 140, 70));
        }
        // ameias e flecha de ardósia com a cruz
        for (int k = 0; k < 4; k++) t.Ret(tx + k * 9, ty1 - 5, tx + k * 9 + 5, ty1, Esc(pedraC, 0.95));
        var ard2 = Ardosia(seed + 9, ty1 - flecha, tx - 3, torreW + 6);
        t.Poligono(new double[] { tx - 3, tx + torreW / 2.0, tx + torreW + 3 }, new double[] { ty1 - 2, ty1 - flecha, ty1 - 2 }, ard2);
        int crx = tx + torreW / 2;
        t.Ret(crx - 1, ty1 - flecha - 12, crx + 1, ty1 - flecha + 1, C(178, 150, 86));
        t.Ret(crx - 4, ty1 - flecha - 9, crx + 4, ty1 - flecha - 7, C(178, 150, 86));
        t.Contorno(CONTORNO);
        return p;
    }

    // ------------------------------------------------------- torre de vigia
    public static Peca Torre(int seed)
    {
        int tw = 36, th = 104, cone = 34;
        int Wt = tw + 16, H = th + cone + 12;
        var t = new Tela(Wt, H);
        var p = new Peca("torre", t);
        int baseY = H - 1, tx = 8, ty1 = baseY + 1 - th;
        Pedras(t, tx, ty1, tx + tw, baseY + 1, seed, C(106, 102, 108), tx, tw);
        for (int k = 0; k < 2; k++)
        {
            int sx = tx + 10 + k * 13, sy = ty1 + 22 + k * 30;
            t.Ret(sx, sy, sx + 3, sy + 8, C(255, 196, 110));
            t.Ret(sx + 1, sy + 1, sx + 2, sy + 7, C(255, 236, 170));
            p.Luzes.Add(new[] { sx + 1, sy + 4, 12 });
        }
        // bandeira com o brasão
        int bx = tx + tw - 10;
        t.Ret(bx, ty1 + 34, bx + 9, ty1 + 58, C(118, 30, 34));
        for (int k = 0; k < 9; k += 3) t.Px(bx + k + 1, ty1 + 58, C(118, 30, 34));
        t.Ret(bx + 4, ty1 + 40, bx + 5, ty1 + 52, C(206, 172, 96));
        t.Ret(bx + 2, ty1 + 44, bx + 7, ty1 + 45, C(206, 172, 96));
        for (int k = 0; k < 5; k++) t.Ret(tx - 2 + k * 8, ty1 - 6, tx - 2 + k * 8 + 5, ty1, C(112, 108, 114));
        var ard = Ardosia(seed + 4, ty1 - cone, tx - 4, tw + 8);
        t.Poligono(new double[] { tx - 4, tx + tw / 2.0, tx + tw + 4 }, new double[] { ty1 - 5, ty1 - cone, ty1 - 5 }, ard);
        t.Contorno(CONTORNO);
        return p;
    }

    // ------------------------------------------------------- barraca (feira)
    public static Peca Barraca(string nome, int seed, int cor1, int cor2)
    {
        int W = 50, H = 44;
        var t = new Tela(W + 4, H + 2);
        var p = new Peca(nome, t);
        int baseY = H, ox = 2;
        var rng = new Random(seed);
        t.Ret(ox + 3, 10, ox + 6, baseY, C(78, 54, 38));
        t.Ret(ox + W - 6, 10, ox + W - 3, baseY, C(70, 48, 34));
        // balcão e mercadorias
        t.Ret(ox + 1, baseY - 15, ox + W - 1, baseY - 12, C(110, 78, 52));
        t.RetF(ox + 2, baseY - 12, ox + W - 2, baseY, (x, y) => ((x % 5) == 0) ? C(62, 42, 30) : C(92, 64, 44));
        for (int k = 0; k < 7; k++)
        {
            int gx = ox + 5 + k * 6, gy = baseY - 17;
            int gc = rng.NextDouble() < 0.5 ? C(170, 46, 40) : C(116, 140, 70);
            t.Disco(gx + 2, gy + 1, 2.4, (x, y) => gc);
        }
        // toldo listrado com a borda recortada
        t.Poligono(new double[] { ox, ox + 5, ox + W - 5, ox + W }, new double[] { 16, 3, 3, 16 }, (x, y) => (((x - ox) / 5) % 2 == 0) ? cor1 : cor2);
        for (int k = 0; k < W; k += 6)
            t.Disco(ox + k + 3, 16, 3, (x, y) => (((x - ox) / 5) % 2 == 0) ? cor1 : cor2);
        t.Ret(ox + 4, 2, ox + W - 4, 3, Esc(cor1, 0.7));
        t.Contorno(CONTORNO);
        return p;
    }

    public static Peca Poco(int seed)
    {
        int W = 38, H = 40;
        var t = new Tela(W + 4, H + 2);
        var p = new Peca("poco", t);
        int baseY = H, ox = 2;
        Pedras(t, ox + 4, baseY - 13, ox + W - 4, baseY, seed, C(110, 106, 110), ox, W);
        t.Ret(ox + 3, baseY - 15, ox + W - 3, baseY - 13, C(140, 134, 136));
        t.Ret(ox + 7, 9, ox + 10, baseY - 13, C(80, 56, 40));
        t.Ret(ox + W - 10, 9, ox + W - 7, baseY - 13, C(72, 50, 36));
        t.Ret(ox + 10, 13, ox + W - 10, 14, C(56, 40, 30));
        t.Linha(ox + W / 2, 14, ox + W / 2, 21, C(140, 120, 90));
        t.Ret(ox + W / 2 - 2, 21, ox + W / 2 + 3, 25, C(92, 66, 46));
        var telha = TelhaBarro(seed + 3, 1, ox, W);
        t.Poligono(new double[] { ox, ox + W / 2.0, ox + W }, new double[] { 11, 0, 11 }, telha);
        t.Contorno(CONTORNO);
        return p;
    }

    public static Peca Lampiao()
    {
        int W = 20, H = 56;
        var t = new Tela(W, H);
        var p = new Peca("lampiao", t);
        int px = 6, baseY = H - 1;
        t.Ret(px - 2, baseY - 3, px + 4, baseY + 1, C(30, 28, 32));
        t.Ret(px, 6, px + 2, baseY - 3, C(38, 36, 42));
        t.Ret(px, 6, px + 9, 8, C(38, 36, 42));
        t.Ret(px + 7, 8, px + 8, 11, C(38, 36, 42));
        t.Ret(px + 4, 11, px + 12, 21, C(32, 28, 30));
        t.Ret(px + 5, 12, px + 11, 20, C(255, 206, 120));
        t.Ret(px + 7, 14, px + 9, 18, C(255, 240, 190));
        t.Ret(px + 3, 10, px + 13, 11, C(48, 44, 48));
        p.Luzes.Add(new[] { px + 8, 16, 22 });
        t.Contorno(CONTORNO);
        return p;
    }

    // --------------------------------------------------------------- árvores
    static void Copa(Tela t, double cx, double cy, double rx, double ry, int n, int seed, double rmin, double rmax)
    {
        var rng = new Random(seed);
        var blocos = new List<double[]>();
        for (int k = 0; k < n; k++)
        {
            double a = rng.NextDouble() * Math.PI * 2, d = Math.Sqrt(rng.NextDouble());
            blocos.Add(new[] { cx + Math.Cos(a) * rx * d, cy + Math.Sin(a) * ry * d, rmin + rng.NextDouble() * (rmax - rmin) });
        }
        blocos.Sort((a, b) => a[1].CompareTo(b[1]));
        foreach (var bl in blocos)
        {
            double bx = bl[0], by = bl[1], r = bl[2];
            t.Disco(bx, by, r, (x, y) =>
            {
                double dx = (x + 0.5 - bx) / r, dy = (y + 0.5 - by) / r;
                double l = -(dx * 0.6 + dy * 0.8);
                double n2 = Hs(x, y, seed) * 0.35;
                int c;
                if (l + n2 > 0.62) c = C(96, 112, 78);
                else if (l + n2 > 0.22) c = C(60, 78, 54);
                else if (l + n2 > -0.25) c = C(40, 54, 40);
                else c = C(26, 36, 28);
                if (Hs(x, y, seed + 9) < 0.04) c = C(126, 136, 98);
                return c;
            });
        }
    }
    public static Peca Arvore(string nome, int seed, int W, int H)
    {
        var t = new Tela(W + 4, H + 2);
        var p = new Peca(nome, t);
        int baseY = H, cx = W / 2 + 2;
        int tw = Math.Max(6, W / 9);
        for (int y = (int)(H * 0.42); y <= baseY; y++)
        {
            double fl = y > baseY - 8 ? (y - (baseY - 8)) * 0.8 : 0;
            for (int x = (int)(cx - tw / 2 - fl); x <= (int)(cx + tw / 2 + fl); x++)
            {
                int c = ((x - cx + 50) % 3 == 0) ? C(46, 36, 30) : C(70, 56, 46);
                t.Px(x, y, Luz(c, x - (cx - tw), tw * 2));
            }
        }
        Copa(t, cx, H * 0.36, W * 0.38, H * 0.25, 26, seed, W * 0.1, W * 0.17);
        t.Contorno(CONTORNO);
        return p;
    }
    public static Peca Pinheiro(string nome, int seed, int W, int H)
    {
        var t = new Tela(W + 4, H + 2);
        var p = new Peca(nome, t);
        int baseY = H, cx = W / 2 + 2;
        t.Ret(cx - 2, baseY - 10, cx + 2, baseY + 1, C(60, 46, 38));
        int niveis = 5;
        for (int k = 0; k < niveis; k++)
        {
            double topo = 2 + k * (H - 14) / (double)niveis * 0.8;
            double fundo = topo + (H - 14) / (double)niveis * 1.5;
            double meia = (W / 2.0) * (0.42 + 0.58 * (k + 1) / niveis);
            t.Poligono(new double[] { cx, cx + meia, cx - meia }, new double[] { topo, fundo, fundo }, (x, y) =>
            {
                double rel = (x - (cx - meia)) / (2 * meia);
                int c = rel < 0.35 ? C(54, 74, 60) : (rel < 0.7 ? C(38, 56, 46) : C(26, 40, 34));
                if (Hs(x, y, seed) < 0.1) c = Esc(c, 0.85);
                return c;
            });
            for (int x = (int)(cx - meia); x <= (int)(cx + meia); x += 2)
                if (Hs(x, k, seed) < 0.5) t.Px(x, (int)fundo, C(30, 44, 36));
        }
        t.Contorno(CONTORNO);
        return p;
    }
    // a árvore anciã da praça (onde a Árvore Amaldiçoada desperta)
    public static Peca ArvoreAncia(int seed)
    {
        int W = 300, H = 330;
        var t = new Tela(W + 4, H + 2);
        var p = new Peca("arvore_ancia", t);
        int baseY = H, cx = W / 2 + 2;
        for (int y = 120; y <= baseY; y++)
        {
            double h = (double)(y - 120) / (baseY - 120);
            double meia = 26 + 10 * h + (y > baseY - 30 ? Math.Pow((y - (baseY - 30)) / 30.0, 2) * 46 : 0);
            for (int x = (int)(cx - meia); x <= (int)(cx + meia); x++)
            {
                double ondula = Math.Sin(y * 0.09 + x * 0.21) * 1.4;
                int c = (((int)(x + ondula) + 60) % 5 < 2) ? C(44, 34, 28) : C(78, 62, 50);
                if (Hs(x, y, seed) < 0.06) c = C(98, 80, 64);
                t.Px(x, y, Luz(c, x - (int)(cx - meia), (int)(meia * 2)));
            }
        }
        // galhos grossos
        for (int k = -1; k <= 1; k += 2)
            for (int s = 0; s < 70; s++)
            {
                double gx = cx + k * (14 + s * 1.3), gy = 150 - s * 0.9;
                t.Disco(gx, gy, 9 - s * 0.08, (x, y) => C(60, 46, 38));
            }
        Copa(t, cx, H * 0.32, W * 0.42, H * 0.2, 46, seed, 24, 42);
        // lanternas penduradas e estandartes
        int[][] lant = { new[] { cx - 96, 168 }, new[] { cx + 92, 162 }, new[] { cx - 48, 186 }, new[] { cx + 52, 190 } };
        foreach (var l in lant)
        {
            t.Linha(l[0], l[1] - 18, l[0], l[1] - 6, C(30, 26, 26));
            t.Ret(l[0] - 4, l[1] - 6, l[0] + 4, l[1] + 4, C(32, 28, 30));
            t.Ret(l[0] - 3, l[1] - 5, l[0] + 3, l[1] + 3, C(255, 204, 116));
            t.Ret(l[0] - 1, l[1] - 3, l[0] + 1, l[1] + 1, C(255, 240, 190));
            p.Luzes.Add(new[] { l[0], l[1] - 1, 26 });
        }
        for (int k = -1; k <= 1; k += 2)
        {
            int bx = cx + k * 70 - 8, by = 200;
            t.Ret(bx - 2, by - 2, bx + 18, by, C(60, 44, 34));
            t.Ret(bx, by, bx + 16, by + 40, C(118, 30, 34));
            for (int s = 0; s < 16; s += 4) t.Ret(bx + s, by + 40, bx + s + 2, by + 43, C(118, 30, 34));
            t.Ret(bx + 7, by + 8, bx + 9, by + 30, C(206, 172, 96));
            t.Ret(bx + 3, by + 14, bx + 13, by + 16, C(206, 172, 96));
        }
        t.Contorno(CONTORNO);
        return p;
    }

    // ---------------------------------------------------------------- ponte
    public static Peca Ponte(int seed)
    {
        int W = 230, H = 72;
        var t = new Tela(W + 4, H + 2);
        var p = new Peca("ponte", t);
        int ox = 2, baseY = H;
        Pedras(t, ox, 14, ox + W, baseY + 1, seed, C(108, 104, 110), ox, W);
        // parapeito com pilaretes
        Pedras(t, ox, 4, ox + W, 14, seed + 1, C(120, 116, 120), ox, W);
        for (int k = 0; k < W; k += 23) t.Ret(ox + k, 0, ox + k + 6, 6, C(126, 122, 126));
        // dois arcos vazados: o rio passa por eles
        for (int a = 0; a < 2; a++)
        {
            double acx = ox + W * (0.27 + a * 0.46), r = 38;
            for (int y = 26; y <= baseY; y++)
                for (int x = (int)(acx - r - 2); x <= (int)(acx + r + 2); x++)
                {
                    double dx = x + 0.5 - acx, dy = (baseY + 4) - (y + 0.5);
                    double d = Math.Sqrt(dx * dx + dy * dy);
                    if (d < r) t.Px(x, y, 0);
                    else if (d < r + 2.5 && t.Cheio(x, y)) t.Px(x, y, C(76, 72, 80));
                }
        }
        t.Contorno(CONTORNO);
        return p;
    }

    // --------------------------------------------- faixa da frente e o chão
    public static Peca Muro()
    {
        var t = new Tela(96, 28);
        var p = new Peca("muro", t);
        PedrasRepetidas(t, 4, 28, 4401, C(98, 94, 100));
        for (int x = 0; x < 96; x++)
        {
            t.Px(x, 2, C(134, 130, 134));
            t.Px(x, 3, C(112, 108, 114));
            if (Hs(x, 1, 4402) < 0.6) t.Px(x, 1, C(52, 66, 46));
        }
        return p;
    }
    public static Peca Cerca()
    {
        var t = new Tela(64, 26);
        var p = new Peca("cerca", t);
        for (int x = 0; x < 64; x++)
        {
            for (int y = 8; y < 11; y++) t.Px(x, y, y == 8 ? C(110, 80, 56) : C(78, 54, 38));
            for (int y = 16; y < 19; y++) t.Px(x, y, y == 16 ? C(104, 76, 52) : C(72, 50, 36));
        }
        foreach (int px in new[] { 6, 38 })
        {
            t.Ret(px, 3, px + 5, 26, C(84, 58, 40));
            t.Ret(px, 3, px + 1, 26, C(112, 82, 58));
            t.Ret(px + 4, 3, px + 5, 26, C(56, 38, 28));
            t.Poligono(new double[] { px, px + 2.5, px + 5 }, new double[] { 3, 0, 3 }, (x, y) => C(84, 58, 40));
        }
        return p;
    }
    public static Peca Sebe(int seed)
    {
        var t = new Tela(52, 28);
        var p = new Peca("sebe", t);
        Copa(t, 26, 18, 18, 6, 7, seed, 7, 11);
        t.Contorno(CONTORNO);
        return p;
    }
    public static Peca Chao()
    {
        int W = 128, H = 80;
        var t = new Tela(W, H);
        var p = new Peca("chao", t);
        var rng = new Random(77);
        // terra escura no fundo
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
                t.Px(x, y, Mix(C(54, 44, 40), C(20, 16, 18), Math.Min(1, y / (double)H * 1.3)));
        // calçamento de pedras (emenda dos dois lados)
        int yp = 6;
        while (yp < 40)
        {
            int h = 5 + rng.Next(2), x = rng.Next(W), soma = 0;
            while (soma < W)
            {
                int w = 6 + rng.Next(7);
                if (W - soma - w < 5) w = W - soma;
                double esc = 0.8 + rng.NextDouble() * 0.3 - (yp - 6) * 0.008;
                int c = Esc(C(116, 108, 104), esc);
                for (int yy = yp; yy < yp + h; yy++)
                    for (int k = 0; k < w; k++)
                    {
                        int xx = (x + soma + k) % W, cc = c;
                        if (yy == yp + h - 1 || k == w - 1) cc = C(38, 32, 32);
                        else if (yy == yp || k == 0) cc = Mix(c, C(170, 160, 152), 0.3);
                        t.Px(xx, yy, cc);
                    }
                soma += w;
            }
            yp += h;
        }
        // grama na borda de cima
        for (int x = 0; x < W; x++)
        {
            int alt = 2 + (int)(Hs(x, 0, 78) * 4);
            for (int y = 0; y < 6; y++)
            {
                if (y < 6 - alt) continue;
                t.Px(x, y, Hs(x, y, 79) < 0.5 ? C(46, 60, 40) : C(32, 44, 30));
            }
            if (Hs(x, 5, 80) < 0.2) t.Px(x, 1, C(64, 80, 52));
        }
        return p;
    }

    // ------------------------------------------------- faixas distantes (repetem)
    static double Onda(double x, double[][] termos, int W)
    {
        double s = 0;
        foreach (var k in termos) s += k[1] * Math.Sin(2 * Math.PI * k[0] * x / W + k[2]);
        return s;
    }
    public static Peca Montanhas()
    {
        int W = 1024, H = 230;
        var t = new Tela(W, H);
        var p = new Peca("montanhas", t);
        var longe = new[] { new[] { 2.0, 26, 1 }, new[] { 5.0, 16, 2 }, new[] { 11.0, 9, 0.5 }, new[] { 23.0, 4, 3 }, new[] { 41.0, 2, 1 } };
        var perto = new[] { new[] { 3.0, 22, 4 }, new[] { 7.0, 13, 1 }, new[] { 17.0, 6, 2 }, new[] { 37.0, 2.5, 0.3 } };
        for (int x = 0; x < W; x++)
        {
            double hf = 104 + Onda(x, longe, W);
            double hfa = 104 + Onda(x - 1, longe, W);
            double pico = Math.Exp(-Math.Pow((x - 610) / 46.0, 2)) + Math.Exp(-Math.Pow((x - 610 + W) / 46.0, 2));
            double hn = 166 + Onda(x, perto, W) - 74 * pico;
            double hna = 166 + Onda(x - 1, perto, W) - 74 * (Math.Exp(-Math.Pow((x - 611) / 46.0, 2)) + Math.Exp(-Math.Pow((x - 611 + W) / 46.0, 2)));
            // encosta virada para a esquerda pega a lua: luz pela inclinação,
            // só perto da crista (antes a coluna inteira acendia e virava listra)
            double luzN = Math.Max(0, Math.Min(1, (hna - hn) * 0.7));
            double luzF = Math.Max(0, Math.Min(1, (hfa - hf) * 0.7));
            for (int y = 0; y < H; y++)
            {
                if (y >= hn)
                {
                    double prof = y - hn;
                    int c = Mix(C(66, 60, 80), C(112, 66, 62), Math.Min(1, pico * 1.2));
                    double l = luzN * Math.Max(0, 1 - prof / (10 + 14 * Hs(x / 6, 0, 5)));
                    c = Mix(c, C(128, 114, 130), l * 0.55);
                    if (pico > 0.3 && prof < 5 && Hs(x, y, 3) < 0.5) c = C(170, 96, 72);
                    if (Hs(x / 2, y / 3, 11) < 0.12) c = Esc(c, 0.92);
                    c = Mix(c, C(40, 36, 52), Math.Min(1, prof / 90.0));
                    t.Px(x, y, c);
                }
                else if (y >= hf)
                {
                    double prof = y - hf;
                    int c = C(96, 90, 116);
                    double l = luzF * Math.Max(0, 1 - prof / (12 + 16 * Hs(x / 7, 0, 6)));
                    c = Mix(c, C(132, 124, 150), l * 0.6);
                    // neve nos picos altos, escorrendo em veios
                    if (hf < 94 && prof < 5 + 6 * Hs(x / 3, 0, 7)) c = C(176, 170, 188);
                    if (Hs(x / 2, y / 3, 12) < 0.1) c = Esc(c, 0.94);
                    c = Mix(c, C(84, 76, 100), Math.Min(1, prof / 120.0));
                    t.Px(x, y, c);
                }
            }
        }
        return p;
    }
    static void PinheiroSilhueta(Tela t, int cx, int baseY, int h, int cor, int corLuz, int W)
    {
        for (int y = baseY - h; y <= baseY; y++)
        {
            double rel = (y - (baseY - h)) / (double)h;
            int meia = (int)(rel * h * 0.32) + 1;
            if (((y - (baseY - h)) % 6) == 5) meia = Math.Max(1, meia - 2);
            for (int k = -meia; k <= meia; k++)
            {
                int x = ((cx + k) % W + W) % W;
                t.Px(x, y, k == -meia ? corLuz : cor);   // só um fio de luz na borda esquerda
            }
        }
    }
    public static Peca Floresta()
    {
        int W = 1024, H = 160;
        var t = new Tela(W, H);
        var p = new Peca("floresta", t);
        var morro = new[] { new[] { 2.0, 12, 0.4 }, new[] { 5.0, 7, 1.2 }, new[] { 13.0, 3, 2 } };
        var rng = new Random(505);
        // fileira de trás (mais azulada)
        for (int x = 0; x < W; x += 9)
        {
            int bx = x + rng.Next(6);
            int baseY = (int)(78 + Onda(bx, morro, W));
            PinheiroSilhueta(t, bx, baseY, 30 + rng.Next(26), C(42, 52, 56), C(56, 66, 70), W);
        }
        for (int x = 0; x < W; x++)
        {
            int baseY = (int)(78 + Onda(x, morro, W));
            for (int y = baseY; y < H; y++) t.Px(x, y, C(36, 46, 46));
        }
        // fileira da frente (mais escura)
        for (int x = 0; x < W; x += 11)
        {
            int bx = x + rng.Next(7);
            int baseY = (int)(118 + Onda(bx, morro, W) * 0.6);
            PinheiroSilhueta(t, bx, baseY, 34 + rng.Next(30), C(26, 36, 32), C(38, 50, 44), W);
        }
        for (int x = 0; x < W; x++)
        {
            int baseY = (int)(118 + Onda(x, morro, W) * 0.6);
            for (int y = baseY; y < H; y++) t.Px(x, y, C(24, 32, 30));
        }
        return p;
    }
    public static Peca VilaLonge()
    {
        int W = 1024, H = 96;
        var t = new Tela(W, H);
        var p = new Peca("vila_longe", t);
        var rng = new Random(606);
        int x = 0;
        int corCasa = C(54, 46, 58), corTelh = C(66, 52, 60), corLuz = C(238, 172, 92);
        var rngF = new Random(6061);
        while (x < W)
        {
            int w = 20 + rng.Next(22), h = 16 + rng.Next(16), baseY = 74;
            bool torre = rng.NextDouble() < 0.08;
            if (torre) { w = 10; h = 46; }
            // v1.14: o reino arrasado ao longe: muitas casas sem telhado, com a borda
            // de cima quebrada, e incêndios brilhando nos escombros
            bool ruina = rngF.NextDouble() < (torre ? 0.5 : 0.42);
            for (int k = 0; k < w; k++)
            {
                int quebra = ruina ? (int)(3 + 7 * Hs(k / 2, x, 66) + (k > w / 2 ? 3 : 0)) : 0;
                if (ruina && torre) quebra = (int)(14 + 10 * Hs(k, x, 67));
                for (int y = baseY - h + quebra; y < baseY; y++) t.Px((x + k) % W, y, corCasa);
            }
            int th = torre ? 26 : w / 2 + 2;
            if (!ruina)
                for (int y = 0; y < th; y++)
                {
                    int meia = (int)((w / 2.0 + 2) * y / th);
                    for (int k = -meia; k <= meia; k++)
                        t.Px(((x + w / 2 + k) % W + W) % W, baseY - h - th + y, torre ? C(58, 54, 70) : corTelh);
                }
            else if (!torre && rngF.NextDouble() < 0.6)
            {
                // caibro carbonizado apontando para o céu
                int px = x + 2 + rngF.Next(Math.Max(1, w - 4));
                for (int y = baseY - h - 6 - rngF.Next(6); y < baseY - h + 4; y++) t.Px(px % W, y, C(34, 28, 36));
            }
            if (rngF.NextDouble() < (ruina ? 0.7 : 0.3))
            {
                // incêndio: brasas no alto (o jogo desenha o brilho e a fumaça por cima)
                int fy = baseY - h + (ruina ? 5 : -th + 4);
                for (int k = 1; k < w - 1; k++)
                    if (Hs(k, x, 68) < 0.45) t.Px((x + k) % W, fy + (int)(3 * Hs(k, x, 69)), Hs(k, x, 70) < 0.5 ? C(255, 136, 60) : C(206, 74, 40));
                p.Fogos.Add(new[] { (x + w / 2) % W, fy, w });
            }
            int janelas = torre ? 1 : rng.Next(3);
            for (int j = 0; j < janelas; j++)
            {
                int jx = x + 3 + rng.Next(Math.Max(1, w - 6)), jy = baseY - h + 4 + rng.Next(Math.Max(1, h - 10));
                if (ruina) jy = Math.Max(jy, baseY - h + 16);          // abaixo da borda quebrada
                if (jy < baseY - 2) t.Ret(jx % W, jy, jx % W + 2, jy + 2, ruina ? C(226, 96, 44) : corLuz);
            }
            x += w + rng.Next(6);
        }
        for (int xx = 0; xx < W; xx++)
            for (int y = 74; y < H; y++) t.Px(xx, y, Mix(C(40, 36, 44), C(30, 30, 32), (y - 74) / 22.0));
        return p;
    }
    public static Peca Nuvens()
    {
        int W = 1024, H = 110;
        var t = new Tela(W, H);
        var p = new Peca("nuvens", t);
        var rng = new Random(707);
        for (int n = 0; n < 9; n++)
        {
            double cx = rng.Next(W), cy = 30 + rng.Next(60);
            int partes = 5 + rng.Next(5);
            for (int k = 0; k < partes; k++)
            {
                double bx = cx + (k - partes / 2.0) * 16 + rng.Next(-6, 7), by = cy + rng.Next(-6, 6), r = 10 + rng.Next(12);
                for (int y = (int)(by - r); y <= (int)(by + r); y++)
                    for (int x = (int)(bx - r); x <= (int)(bx + r); x++)
                    {
                        double dx = x + 0.5 - bx, dy = (y + 0.5 - by) * 1.6;
                        if (dx * dx + dy * dy > r * r || y < 0 || y >= H) continue;
                        int xx = ((x % W) + W) % W;
                        int c = dy < -r * 0.3 ? CA(150, 122, 136, 150) : CA(104, 84, 108, 130);
                        t.Px(xx, y, c);
                    }
            }
        }
        return p;
    }

    // ------------------------------------------------------- atlas e saída
    static void Salvar(string arq, Tela t)
    {
        using (var b = new Bitmap(t.W, t.H, PixelFormat.Format32bppArgb))
        {
            var d = b.LockBits(new Rectangle(0, 0, t.W, t.H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(t.P, 0, d.Scan0, t.P.Length);
            b.UnlockBits(d);
            b.Save(arq, ImageFormat.Png);
        }
    }

    static string Arr(List<int[]> l)
    {
        var sb = new StringBuilder("[");
        for (int i = 0; i < l.Count; i++)
        {
            if (i > 0) sb.Append(",");
            sb.Append("[" + string.Join(",", l[i]) + "]");
        }
        return sb.Append("]").ToString();
    }

    // disposição da fase: [peça, x, base, queima (0 não, 1 em chamas, 2 ruína fumegante), espelho, plano]
    // plano 0 = frente (lista FRENTE); 1 e 2 = fileiras de trás, geradas: o reino
    // inteiro queimando, casa colada em casa (2 é a mais distante e escura)
    static readonly object[][] FRENTE = {
        new object[] { "arvore1", -30, 686, 0, 0, 0 },
        new object[] { "casa_a", 210, 676, 0, 0, 0 },
        new object[] { "poco", 330, 682, 0, 0, 0 },
        new object[] { "casa_b", 372, 676, 1, 0, 0 },
        new object[] { "barraca1", 506, 682, 0, 0, 0 },
        new object[] { "casa_c", 566, 676, 1, 0, 0 },
        new object[] { "pinheiro1", 700, 686, 0, 0, 0 },
        new object[] { "casa_d", 742, 676, 1, 1, 0 },
        new object[] { "igreja", 900, 676, 1, 0, 0 },
        new object[] { "arvore2", 1080, 686, 0, 0, 0 },
        new object[] { "casa_e", 1170, 676, 1, 0, 0 },
        new object[] { "casa_x3", 1300, 676, 2, 0, 0 },          // v1.14: casas da frente desabadas abrem a vista do reino arrasado
        new object[] { "barraca2", 1436, 682, 0, 0, 0 },
        new object[] { "casa_f", 1500, 676, 1, 1, 0 },
        new object[] { "casa_g", 1648, 676, 1, 0, 0 },
        new object[] { "pinheiro2", 1788, 686, 0, 0, 0 },
        new object[] { "ponte", 1880, 678, 0, 0, 0 },
        new object[] { "casa_x1", 2124, 676, 1, 0, 0 },
        new object[] { "torre", 2262, 676, 1, 0, 0 },
        new object[] { "casa_k", 2340, 676, 1, 1, 0 },
        new object[] { "casa_q3", 2440, 676, 2, 1, 0 },
        new object[] { "casa_x2", 2556, 676, 1, 1, 0 },
        new object[] { "casa_i", 2700, 676, 1, 0, 0 },
        new object[] { "casa_x4", 2840, 676, 2, 0, 0 },
        new object[] { "arvore3", 2990, 686, 0, 0, 0 },
        new object[] { "casa_j", 3090, 676, 1, 1, 0 },
        new object[] { "casa_k", 3240, 676, 1, 0, 0 },
        new object[] { "poco", 3370, 682, 0, 1, 0 },
        new object[] { "casa_l", 3420, 676, 1, 0, 0 },
        new object[] { "pinheiro1", 3560, 686, 0, 1, 0 },
        new object[] { "barraca1", 3610, 682, 0, 1, 0 },
        new object[] { "casa_a", 3680, 676, 2, 1, 0 },
        new object[] { "arvore2", 3820, 686, 0, 1, 0 },
        new object[] { "casa_x5", 4020, 676, 1, 1, 0 },
        new object[] { "casa_q2", 4130, 676, 2, 0, 0 },
        new object[] { "lampiao", 4290, 686, 0, 0, 0 },
        new object[] { "casa_x3", 4396, 676, 2, 0, 0 },          // (a árvore anciã saiu: perto do chefe parecia outra árvore)
        new object[] { "casa_g", 4530, 676, 1, 1, 0 },
        new object[] { "lampiao", 4700, 686, 0, 1, 0 },
        new object[] { "casa_m", 4760, 676, 1, 0, 0 },
        new object[] { "casa_e", 4880, 676, 1, 1, 0 },
    };

    static object[][] Layout()
    {
        var l = new List<object[]>();
        string[] casas = { "casa_a", "casa_b", "casa_c", "casa_d", "casa_e", "casa_f", "casa_g", "casa_h", "casa_i", "casa_j", "casa_k", "casa_l", "casa_m" };
        string[] ruinas = { "casa_q1", "casa_q2", "casa_q3" };
        string[] destruidas = { "casa_x1", "casa_x2", "casa_x3", "casa_x4", "casa_x5", "casa_x6", "casa_x7" };
        var rng = new Random(4242);
        // v1.14: fileira mais ao fundo (plano 3): o reino arrasado, casa desabada
        // colada em casa desabada, escombros fumegando e o fogo que sobrou
        // v1.17: as casas com o DOBRO do tamanho: as fileiras geradas ficam com o
        // dobro do espaço entre uma casa e outra (a escala vai no JSON, EscalaDe)
        var rng3 = new Random(9393);
        for (int x = -120; x < 5060; x += (64 + rng3.Next(28)) * 2)
        {
            bool de = rng3.NextDouble() < 0.62;
            string nome = de ? destruidas[rng3.Next(destruidas.Length)] : casas[rng3.Next(casas.Length)];
            l.Add(new object[] { nome, x, 641, de ? (rng3.NextDouble() < 0.45 ? 1 : 2) : 1, rng3.Next(2), 3 });
        }
        // fileira distante: a maior parte em chamas, muitas já desabadas
        for (int x = -80; x < 5040; x += (92 + rng.Next(26)) * 2)
        {
            double r = rng.NextDouble();
            string nome = r < 0.3 ? destruidas[rng.Next(destruidas.Length)] : (r < 0.42 ? ruinas[rng.Next(3)] : casas[rng.Next(casas.Length)]);
            int q = r < 0.3 ? (rng.NextDouble() < 0.5 ? 1 : 2) : (r < 0.42 ? 2 : 1);
            l.Add(new object[] { nome, x, 652, q, rng.Next(2), 2 });
        }
        // fileira do meio: a maioria queimando, várias em ruínas ou desabadas, poucas inteiras
        for (int x = -60; x < 5040; x += (84 + rng.Next(24)) * 2)
        {
            double r = rng.NextDouble();
            int q = r < 0.5 ? 1 : (r < 0.92 ? 2 : 0);
            string nome = q == 2 ? (rng.NextDouble() < 0.55 ? destruidas[rng.Next(destruidas.Length)] : ruinas[rng.Next(3)]) : casas[rng.Next(casas.Length)];
            l.Add(new object[] { nome, x, 663, q, rng.Next(2), 1 });
        }
        l.AddRange(FRENTE);
        return l.ToArray();
    }

    // v1.17: "as casas do cenário com o dobro do tamanho; o cenário maior":
    // casas, ruínas, igreja e torre 2x; árvores, barracas, poço, lampião e ponte 1,5x
    static double EscalaDe(string nome)
    {
        if (nome.StartsWith("casa_") || nome == "igreja" || nome == "torre") return 2.0;
        return 1.5;
    }

    public static string Gerar(string pastaGm, string pastaGd)
    {
        var pecas = new List<Peca>();
        pecas.Add(Montanhas());
        pecas.Add(Floresta());
        pecas.Add(VilaLonge());
        pecas.Add(Nuvens());
        pecas.Add(Casa("casa_a", 101, 86, 1, false, false));
        pecas.Add(Casa("casa_b", 202, 92, 2, false, false));
        pecas.Add(Casa("casa_c", 303, 72, 2, true, false));
        pecas.Add(Casa("casa_d", 404, 100, 1, false, false));
        pecas.Add(Casa("casa_e", 505, 78, 2, true, false));
        pecas.Add(Casa("casa_f", 606, 104, 2, false, false));
        pecas.Add(Casa("casa_g", 707, 82, 1, true, false));
        pecas.Add(Casa("casa_h", 808, 96, 2, false, false));
        pecas.Add(Casa("casa_i", 909, 74, 2, true, false));
        pecas.Add(Casa("casa_j", 1010, 90, 1, false, false));
        pecas.Add(Casa("casa_k", 1111, 80, 2, true, false));
        pecas.Add(Casa("casa_l", 1212, 98, 2, false, false));
        pecas.Add(Casa("casa_m", 1313, 88, 2, false, false));
        // v1.19: a mesma casa já tomada pelo fogo (telhado com rombos, fuligem e as
        // janelas quebradas): é ela que aparece onde o layout diz "em chamas"
        // (antes uma casa intacta, de janelas acesas, recebia uma faixa de fogo por cima)
        object[][] intactas = {
            new object[] { "casa_a", 101, 86, 1, false }, new object[] { "casa_b", 202, 92, 2, false }, new object[] { "casa_c", 303, 72, 2, true },
            new object[] { "casa_d", 404, 100, 1, false }, new object[] { "casa_e", 505, 78, 2, true }, new object[] { "casa_f", 606, 104, 2, false },
            new object[] { "casa_g", 707, 82, 1, true }, new object[] { "casa_h", 808, 96, 2, false }, new object[] { "casa_i", 909, 74, 2, true },
            new object[] { "casa_j", 1010, 90, 1, false }, new object[] { "casa_k", 1111, 80, 2, true }, new object[] { "casa_l", 1212, 98, 2, false },
            new object[] { "casa_m", 1313, 88, 2, false } };
        foreach (var c in intactas)
            pecas.Add(Casa((string)c[0] + "_f", (int)c[1], (int)c[2], (int)c[3], (bool)c[4], true));
        pecas.Add(Casa("casa_q1", 1414, 90, 1, false, true));
        pecas.Add(Casa("casa_q2", 1515, 76, 2, true, true));
        pecas.Add(Casa("casa_q3", 1616, 96, 2, false, true));
        pecas.Add(Destruida("casa_x1", 3131, 84, 0));
        pecas.Add(Destruida("casa_x2", 3232, 96, 1));
        pecas.Add(Destruida("casa_x3", 3333, 90, 2));
        pecas.Add(Destruida("casa_x4", 3434, 100, 3));
        pecas.Add(Destruida("casa_x5", 3535, 72, 0));
        pecas.Add(Destruida("casa_x6", 3636, 80, 1));
        pecas.Add(Destruida("casa_x7", 3737, 76, 2));
        pecas.Add(Igreja(1717));
        pecas.Add(Torre(1818));
        pecas.Add(Barraca("barraca1", 1919, C(150, 48, 44), C(200, 184, 152)));
        pecas.Add(Barraca("barraca2", 2020, C(64, 88, 120), C(196, 180, 150)));
        pecas.Add(Poco(2121));
        pecas.Add(Lampiao());
        pecas.Add(Arvore("arvore1", 2222, 96, 128));
        pecas.Add(Arvore("arvore2", 2323, 84, 112));
        pecas.Add(Arvore("arvore3", 2424, 110, 140));
        pecas.Add(Pinheiro("pinheiro1", 2525, 40, 92));
        pecas.Add(Pinheiro("pinheiro2", 2626, 46, 108));
        pecas.Add(ArvoreAncia(2727));
        pecas.Add(Ponte(2828));
        pecas.Add(Muro());
        pecas.Add(Cerca());
        pecas.Add(Sebe(2929));
        pecas.Add(Chao());
        // tudo à noite, menos as faixas distantes (já pintadas no tom do céu)
        foreach (var pc in pecas)
            if (pc.Nome != "montanhas" && pc.Nome != "floresta" && pc.Nome != "vila_longe" && pc.Nome != "nuvens") pc.T.Noite();

        // ----- atlas: prateleiras de 2048 px, 2 px de folga entre peças -----
        int AW = 2048, pad = 2;
        var ordem = new List<Peca>(pecas);
        ordem.Sort((a, b) => b.T.H.CompareTo(a.T.H));
        int px = 0, py = 0, alturaLinha = 0;
        foreach (var pc in ordem)
        {
            if (px + pc.T.W + pad > AW) { px = 0; py += alturaLinha + pad; alturaLinha = 0; }
            pc.AX = px; pc.AY = py;
            px += pc.T.W + pad;
            alturaLinha = Math.Max(alturaLinha, pc.T.H);
        }
        int AH = py + alturaLinha;
        var atlas = new Tela(AW, AH);
        foreach (var pc in pecas)
            for (int y = 0; y < pc.T.H; y++)
                Array.Copy(pc.T.P, y * pc.T.W, atlas.P, (pc.AY + y) * AW + pc.AX, pc.T.W);

        // ----- JSON -----
        var sb = new StringBuilder();
        sb.Append("{\n\"atlas\": \"cenario_fase1.png\", \"aw\": " + AW + ", \"ah\": " + AH + ",\n\"pecas\": {\n");
        for (int i = 0; i < pecas.Count; i++)
        {
            var pc = pecas[i];
            sb.Append("\"" + pc.Nome + "\": {\"x\": " + pc.AX + ", \"y\": " + pc.AY + ", \"w\": " + pc.T.W + ", \"h\": " + pc.T.H
                + ", \"chamines\": " + Arr(pc.Chamines) + ", \"fogos\": " + Arr(pc.Fogos) + ", \"focos\": " + Arr(pc.Focos) + ", \"janelas\": " + Arr(pc.Janelas)
                + ", \"luzes\": " + Arr(pc.Luzes) + "}" + (i < pecas.Count - 1 ? ",\n" : "\n"));
        }
        sb.Append("},\n\"layout\": [\n");
        var LAYOUT = Layout();
        var larguras = new Dictionary<string, int>();
        foreach (var pc in pecas) larguras[pc.Nome] = pc.T.W;
        for (int i = 0; i < LAYOUT.Length; i++)
        {
            var l = LAYOUT[i];
            string nome = (string)l[0];
            // v1.19: casa "em chamas" usa a versão queimada (mesma forma, mesmo lugar)
            if (Convert.ToInt32(l[3]) == 1 && larguras.ContainsKey(nome + "_f")) nome += "_f";
            double esc = EscalaDe(nome);
            // a peça maior fica centrada no mesmo ponto em que ficava (o pé não sai do lugar)
            int w = larguras.ContainsKey(nome) ? larguras[nome] : 0;
            int x = (int)Math.Round(Convert.ToInt32(l[1]) + w / 2.0 - w * esc / 2.0);
            sb.Append("[\"" + nome + "\", " + x + ", " + l[2] + ", " + l[3] + ", " + l[4] + ", " + l[5] + ", " + esc.ToString(System.Globalization.CultureInfo.InvariantCulture) + "]" + (i < LAYOUT.Length - 1 ? ",\n" : "\n"));
        }
        sb.Append("]\n}\n");
        var utf8 = new UTF8Encoding(false);
        foreach (var pasta in new[] { pastaGm, pastaGd })
        {
            Salvar(System.IO.Path.Combine(pasta, "cenario_fase1.png"), atlas);
            System.IO.File.WriteAllText(System.IO.Path.Combine(pasta, "cenario_fase1.json"), sb.ToString(), utf8);
        }
        return "atlas " + AW + "x" + AH + ", " + pecas.Count + " pecas, " + Layout().Length + " na fase";
    }
}
