// =====================================================================
//  ImportaArte — recorte e montagem das folhas de animação da equipe
//  (ferramenta offline, usada por ferramentas/importar_arte.ps1)
//  1. corta a folha onde há menos tinta (entre uma pose e outra), sem
//     depender de uma grade exata
//  2. tira da célula os pedaços da pose vizinha
//  3. reduz com média por área (arte HD) ou amplia com EPX (pixel art)
//  4. mede os pés e o centro do corpo de cada quadro, para alinhar todos
//     numa tela comum: o corpo não "pula" de um quadro para o outro
// =====================================================================
using System;
using System.Collections.Generic;

public static class ImportaArte
{
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

    // ----- 1. cortes: n fatias na horizontal (colunas) ou vertical (linhas) -----
    // cada corte fica perto de k*len/n, na coluna com menos pixels visíveis
    public static int[] Cortes(int[] px, int w, int h, int x0, int y0, int x1, int y1, int n, bool colunas)
    {
        int len = colunas ? x1 - x0 : y1 - y0;
        var ocup = new int[len];
        for (int y = y0; y < y1; y++)
            for (int x = x0; x < x1; x++)
                if (A(px[y * w + x]) > 40) ocup[colunas ? x - x0 : y - y0]++;
        var c = new int[n + 1];
        c[0] = 0; c[n] = len;
        double passo = (double)len / n;
        for (int k = 1; k < n; k++)
        {
            int alvo = (int)Math.Round(k * passo);
            int jan = (int)(passo * 0.25);
            int melhor = alvo; long custo = long.MaxValue;
            for (int p = Math.Max(1, alvo - jan); p <= Math.Min(len - 2, alvo + jan); p++)
            {
                // custo = tinta na coluna (+ vizinhas) e um pouco de distância do alvo
                long t = ocup[p] * 4L + ocup[p - 1] + ocup[p + 1];
                t = t * 1000 + Math.Abs(p - alvo);
                if (t < custo) { custo = t; melhor = p; }
            }
            c[k] = melhor;
        }
        for (int k = 0; k <= n; k++) c[k] += colunas ? x0 : y0;
        return c;
    }

    // ----- 1b. separa as poses de uma faixa da folha por "manchas": cada parte
    // conectada do desenho vai inteira para a célula onde está a maior parte
    // dela (o rastro de luz que invade a pose vizinha continua no seu quadro).
    // Uma mancha dividida entre duas células (duas poses encostadas) é
    // cortada na linha da célula. Devolve um quadro por célula, com a altura
    // da faixa e a largura justa; xs = coluna inicial de cada quadro.
    public static int[][] Separar(int[] px, int w, int h, int y0, int y1, int[] cortes, out int[] xs, out int[] ws)
    {
        int n = cortes.Length - 1, bh = y1 - y0;
        var rot = new int[w * bh];
        var fila = new int[w * bh];
        var celDe = new int[w];
        for (int x = 0; x < w; x++)
        {
            int c = 0;
            while (c < n - 1 && x >= cortes[c + 1]) c++;
            celDe[x] = c;
        }
        var dono = new List<int>(); dono.Add(-1);
        var dividir = new List<bool>(); dividir.Add(false);
        int nrot = 0;
        for (int y = 0; y < bh; y++)
            for (int x = 0; x < w; x++)
            {
                int i = y * w + x;
                if (rot[i] != 0 || A(px[(y + y0) * w + x]) <= 60) continue;
                nrot++;
                var conta = new int[n];
                int ini = 0, fim = 0, total = 0;
                fila[fim++] = i; rot[i] = nrot;
                while (ini < fim)
                {
                    int p = fila[ini++]; total++;
                    int px0 = p % w, py0 = p / w;
                    conta[celDe[px0]]++;
                    for (int dy = -1; dy <= 1; dy++)
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            int xx = px0 + dx, yy = py0 + dy;
                            if (xx < 0 || yy < 0 || xx >= w || yy >= bh) continue;
                            int q = yy * w + xx;
                            if (rot[q] != 0 || A(px[(yy + y0) * w + xx]) <= 60) continue;
                            rot[q] = nrot; fila[fim++] = q;
                        }
                }
                int melhor = 0;
                for (int c = 1; c < n; c++) if (conta[c] > conta[melhor]) melhor = c;
                dono.Add(melhor);
                // poses grudadas umas nas outras: a mancha se espalha por várias
                // células e é cortada nas linhas delas
                dividir.Add(total > 400 && conta[melhor] < total * 0.72);
            }
        // pixels semitransparentes (borda suave) seguem a mancha vizinha
        var celPx = new int[w * bh];
        for (int y = 0; y < bh; y++)
            for (int x = 0; x < w; x++)
            {
                int i = y * w + x;
                int a = A(px[(y + y0) * w + x]);
                if (a == 0) { celPx[i] = -1; continue; }
                int r = rot[i];
                if (r == 0)
                {
                    for (int d = 1; d <= 2 && r == 0; d++)
                        for (int dy = -d; dy <= d && r == 0; dy++)
                            for (int dx = -d; dx <= d; dx++)
                            {
                                int xx = x + dx, yy = y + dy;
                                if (xx < 0 || yy < 0 || xx >= w || yy >= bh) continue;
                                if (rot[yy * w + xx] != 0) { r = rot[yy * w + xx]; break; }
                            }
                }
                if (r == 0) { celPx[i] = celDe[x]; continue; }
                celPx[i] = dividir[r] ? celDe[x] : dono[r];
            }
        var saida = new int[n][];
        xs = new int[n]; ws = new int[n];
        for (int c = 0; c < n; c++)
        {
            int l = w, rr = -1;
            for (int y = 0; y < bh; y++)
                for (int x = 0; x < w; x++)
                    if (celPx[y * w + x] == c) { if (x < l) l = x; if (x > rr) rr = x; }
            if (rr < l) { l = cortes[c]; rr = cortes[c]; }
            int fw = rr - l + 1;
            var f = new int[fw * bh];
            for (int y = 0; y < bh; y++)
                for (int x = l; x <= rr; x++)
                    if (celPx[y * w + x] == c) f[y * fw + x - l] = px[(y + y0) * w + x];
            saida[c] = f; xs[c] = l; ws[c] = fw;
        }
        return saida;
    }

    // cortes entre os CORPOS (sem lâmina nem rastro): k-médias nas colunas
    // com corpo acha o centro de cada pose, mesmo com espaçamento desigual;
    // o corte fica entre dois centros, na coluna com menos tinta
    public static int[] CortesCorpo(int[] px, int w, int h, int x0, int y0, int x1, int y1, int n)
    {
        int len = x1 - x0;
        var massa = new double[len];
        var tinta = new int[len];
        for (int y = y0; y < y1; y++)
            for (int x = x0; x < x1; x++)
            {
                int p = px[y * w + x];
                if (A(p) > 40) tinta[x - x0]++;
                if (Corpo(p)) massa[x - x0]++;
            }
        var cen = new double[n];
        for (int k = 0; k < n; k++) cen[k] = (k + 0.5) * len / n;
        for (int it = 0; it < 40; it++)
        {
            var s = new double[n]; var m = new double[n];
            for (int p = 0; p < len; p++)
            {
                if (massa[p] <= 0) continue;
                int best = 0; double bd = double.MaxValue;
                for (int k = 0; k < n; k++) { double d = Math.Abs(p - cen[k]); if (d < bd) { bd = d; best = k; } }
                s[best] += p * massa[p]; m[best] += massa[p];
            }
            for (int k = 0; k < n; k++) if (m[k] > 0) cen[k] = s[k] / m[k];
            Array.Sort(cen);
        }
        var c = new int[n + 1];
        c[0] = x0; c[n] = x1;
        for (int k = 1; k < n; k++)
        {
            double meio = (cen[k - 1] + cen[k]) / 2, jan = (cen[k] - cen[k - 1]) * 0.2;
            int melhor = (int)meio; long custo = long.MaxValue;
            for (int p = Math.Max(1, (int)(meio - jan)); p <= Math.Min(len - 2, (int)(meio + jan)); p++)
            {
                long t = (tinta[p] * 4L + tinta[p - 1] + tinta[p + 1]) * 1000 + (long)Math.Abs(p - meio);
                if (t < custo) { custo = t; melhor = p; }
            }
            c[k] = melhor + x0;
        }
        return c;
    }

    public static int[] Regiao(int[] px, int w, int h, int x0, int y0, int x1, int y1)
    {
        int cw = x1 - x0, ch = y1 - y0;
        var o = new int[cw * ch];
        for (int y = 0; y < ch; y++)
            Array.Copy(px, (y + y0) * w + x0, o, y * cw, cw);
        return o;
    }

    // ----- 2. tira os pedaços das poses vizinhas: componentes que encostam
    // nas laterais da célula e não são o corpo principal -----
    public static void LimparVizinhos(int[] c, int w, int h, double minFracao) { LimparVizinhos(c, w, h, minFracao, true); }

    // bordas = false: só tira os pontinhos soltos (menores que minFracao do corpo)
    public static void LimparVizinhos(int[] c, int w, int h, double minFracao, bool bordas)
    {
        var rot = new int[w * h];
        var tam = new List<int>(); tam.Add(0);
        var toca = new List<bool>(); toca.Add(false);
        var fila = new int[w * h];
        int nrot = 0;
        for (int i = 0; i < c.Length; i++)
        {
            if (rot[i] != 0 || A(c[i]) <= 30) continue;
            nrot++;
            int ini = 0, fim = 0, cont = 0; bool t = false;
            fila[fim++] = i; rot[i] = nrot;
            while (ini < fim)
            {
                int p = fila[ini++]; cont++;
                int x = p % w, y = p / w;
                if (x == 0 || x == w - 1) t = true;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                        int q = yy * w + xx;
                        if (rot[q] != 0 || A(c[q]) <= 30) continue;
                        rot[q] = nrot; fila[fim++] = q;
                    }
            }
            tam.Add(cont); toca.Add(t);
        }
        int maior = 0;
        for (int k = 1; k <= nrot; k++) if (maior == 0 || tam[k] > tam[maior]) maior = k;
        if (maior == 0) return;
        int minimo = (int)(tam[maior] * minFracao);
        for (int i = 0; i < c.Length; i++)
        {
            int k = rot[i];
            if (k == 0 || k == maior) { if (k == 0 && A(c[i]) <= 30) c[i] = 0; continue; }
            if ((bordas && toca[k]) || tam[k] < minimo) c[i] = 0;
        }
    }

    // tira os rastros de luz soltos (o jogo desenha o próprio rastro da espada):
    // fica a maior mancha (corpo + espada) e as partes grandes e "cheias";
    // meias-luas finas e faíscas saem, junto com o brilho em volta delas
    public static void TirarRastro(int[] c, int w, int h)
    {
        var rot = new int[w * h];
        var fila = new int[w * h];
        var tam = new List<int>(); tam.Add(0);
        var caixa = new List<int[]>(); caixa.Add(null);
        int nrot = 0;
        for (int i = 0; i < c.Length; i++)
        {
            if (rot[i] != 0 || A(c[i]) <= 60) continue;
            nrot++;
            int ini = 0, fim = 0, cont = 0, l = w, t = h, r = 0, b = 0;
            fila[fim++] = i; rot[i] = nrot;
            while (ini < fim)
            {
                int p = fila[ini++]; cont++;
                int x = p % w, y = p / w;
                if (x < l) l = x; if (x > r) r = x; if (y < t) t = y; if (y > b) b = y;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                        int q = yy * w + xx;
                        if (rot[q] != 0 || A(c[q]) <= 60) continue;
                        rot[q] = nrot; fila[fim++] = q;
                    }
            }
            tam.Add(cont); caixa.Add(new int[] { l, t, r, b });
        }
        if (nrot == 0) return;
        int maior = 1;
        for (int k = 2; k <= nrot; k++) if (tam[k] > tam[maior]) maior = k;
        var fica = new bool[nrot + 1];
        for (int k = 1; k <= nrot; k++)
        {
            var bx = caixa[k];
            double area = (bx[2] - bx[0] + 1.0) * (bx[3] - bx[1] + 1.0);
            fica[k] = k == maior || (tam[k] >= tam[maior] * 0.15 && tam[k] / area >= 0.35);
        }
        // pixels de borda suave ficam só perto de uma mancha que fica
        var o = (int[])c.Clone();
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int i = y * w + x;
                if (A(c[i]) == 0) continue;
                int k = rot[i];
                if (k != 0) { if (!fica[k]) o[i] = 0; continue; }
                bool perto = false;
                for (int dy = -2; dy <= 2 && !perto; dy++)
                    for (int dx = -2; dx <= 2; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                        int kk = rot[yy * w + xx];
                        if (kk != 0 && fica[kk]) { perto = true; break; }
                    }
                if (!perto) o[i] = 0;
            }
        Array.Copy(o, c, c.Length);
    }

    // caixas das "manchas" de uma folha de peças soltas (paredes, chão...):
    // manchas que se tocam ou ficam a menos de "junta" px se juntam numa peça;
    // as menores que "minimo" pixels saem. Ordem: de cima para baixo, da
    // esquerda para a direita. Cada caixa = {esq, topo, dir, base}.
    public static List<int[]> Manchas(int[] px, int w, int h, int minimo, int junta)
    {
        var rot = new int[w * h];
        var fila = new int[w * h];
        var cx = new List<int[]>();
        var tam = new List<int>();
        int nrot = 0;
        for (int i = 0; i < px.Length; i++)
        {
            if (rot[i] != 0 || A(px[i]) <= 60) continue;
            nrot++;
            int ini = 0, fim = 0, n = 0, l = w, t = h, r = 0, b = 0;
            fila[fim++] = i; rot[i] = nrot;
            while (ini < fim)
            {
                int p = fila[ini++]; n++;
                int x = p % w, y = p / w;
                if (x < l) l = x; if (x > r) r = x; if (y < t) t = y; if (y > b) b = y;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                        int q = yy * w + xx;
                        if (rot[q] != 0 || A(px[q]) <= 60) continue;
                        rot[q] = nrot; fila[fim++] = q;
                    }
            }
            cx.Add(new int[] { l, t, r, b }); tam.Add(n);
        }
        // as manchas grandes são as peças; as pequenas (folhas, flores, pedrinhas
        // soltas) entram na peça grande cuja caixa contém o centro delas
        var saida = new List<int[]>();
        var grande = new List<int>();
        for (int k = 0; k < cx.Count; k++) if (tam[k] >= minimo) grande.Add(k);
        var caixa = new List<int[]>();
        foreach (int k in grande) caixa.Add((int[])cx[k].Clone());
        for (int k = 0; k < cx.Count; k++)
        {
            if (tam[k] >= minimo) continue;
            int mx = (cx[k][0] + cx[k][2]) / 2, my = (cx[k][1] + cx[k][3]) / 2;
            for (int g = 0; g < grande.Count; g++)
            {
                var p = cx[grande[g]];
                if (mx < p[0] - junta || mx > p[2] + junta || my < p[1] - junta || my > p[3] + junta) continue;
                var c = caixa[g];
                caixa[g] = new int[] { Math.Min(c[0], cx[k][0]), Math.Min(c[1], cx[k][1]), Math.Max(c[2], cx[k][2]), Math.Max(c[3], cx[k][3]) };
                break;
            }
        }
        saida.AddRange(caixa);
        // linhas da folha: agrupa por faixa de altura antes de ordenar na horizontal
        saida.Sort((p, q) =>
        {
            int cp = (p[1] + p[3]) / 2, cq = (q[1] + q[3]) / 2;
            if (Math.Abs(cp - cq) > 40) return cp.CompareTo(cq);
            return p[0].CompareTo(q[0]);
        });
        return saida;
    }

    // recorte justo nos pixels visíveis
    public static int[] Aparar(int[] c, int w, int h, out int l, out int t, out int nw, out int nh)
    {
        l = w; t = h; int r = -1, b = -1;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
                if (A(c[y * w + x]) > 20) { if (x < l) l = x; if (x > r) r = x; if (y < t) t = y; if (y > b) b = y; }
        if (r < l) { l = 0; t = 0; nw = 1; nh = 1; return new int[1]; }
        nw = r - l + 1; nh = b - t + 1;
        return Regiao(c, w, h, l, t, r + 1, b + 1);
    }

    // ----- 3. redução por área (alfa pré-multiplicado) -----
    public static int[] Reduzir(int[] c, int w, int h, double s, out int nw, out int nh)
    {
        nw = Math.Max(1, (int)Math.Round(w * s)); nh = Math.Max(1, (int)Math.Round(h * s));
        var o = new int[nw * nh];
        double kx = (double)w / nw, ky = (double)h / nh;
        for (int y = 0; y < nh; y++)
        {
            double fy0 = y * ky, fy1 = (y + 1) * ky;
            for (int x = 0; x < nw; x++)
            {
                double fx0 = x * kx, fx1 = (x + 1) * kx;
                double sa = 0, sr = 0, sg = 0, sb = 0, area = 0;
                for (int yy = (int)fy0; yy < Math.Min(h, (int)Math.Ceiling(fy1)); yy++)
                {
                    double cy = Math.Min(fy1, yy + 1) - Math.Max(fy0, yy);
                    if (cy <= 0) continue;
                    for (int xx = (int)fx0; xx < Math.Min(w, (int)Math.Ceiling(fx1)); xx++)
                    {
                        double cx = Math.Min(fx1, xx + 1) - Math.Max(fx0, xx);
                        if (cx <= 0) continue;
                        double wgt = cx * cy;
                        int p = c[yy * w + xx];
                        double a = A(p) / 255.0 * wgt;
                        sa += a; sr += R(p) * a; sg += G(p) * a; sb += B(p) * a; area += wgt;
                    }
                }
                if (sa <= 0.0001) { o[y * nw + x] = 0; continue; }
                o[y * nw + x] = Cor((int)(sa / area * 255 + 0.5), (int)(sr / sa + 0.5), (int)(sg / sa + 0.5), (int)(sb / sa + 0.5));
            }
        }
        return o;
    }

    static bool Igual(int a, int b)
    {
        if (A(a) < 128 && A(b) < 128) return true;
        return Math.Abs(A(a) - A(b)) < 24 && Math.Abs(R(a) - R(b)) < 18 && Math.Abs(G(a) - G(b)) < 18 && Math.Abs(B(a) - B(b)) < 18;
    }

    // EPX (Scale2x): amplia pixel art arredondando as diagonais, sem borrar
    public static int[] Epx(int[] p, int w, int h)
    {
        var o = new int[w * 2 * h * 2];
        int w2 = w * 2;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int P = p[y * w + x];
                int Ac = y > 0 ? p[(y - 1) * w + x] : 0;
                int Bc = x < w - 1 ? p[y * w + x + 1] : 0;
                int Cc = x > 0 ? p[y * w + x - 1] : 0;
                int Dc = y < h - 1 ? p[(y + 1) * w + x] : 0;
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

    // amplia por fator inteiro: EPX até passar e redução por área até o tamanho exato
    public static int[] Ampliar(int[] c, int w, int h, int fator, out int nw, out int nh)
    {
        int f = 1; int[] up = c; int uw = w, uh = h;
        while (f < fator) { up = Epx(up, uw, uh); uw *= 2; uh *= 2; f *= 2; }
        if (f == fator) { nw = uw; nh = uh; return up; }
        return Reduzir(up, uw, uh, (double)fator / f, out nw, out nh);
    }

    // ----- 4. medidas -----
    // pixel que conta como "corpo": opaco e que não é lâmina nem rastro de luz
    // esqueletos: os ossos são claros e pouco saturados como uma lâmina, então
    // o corpo deles é medido só pela opacidade
    public static bool SoAlfa = false;

    static bool Corpo(int p)
    {
        if (A(p) < 200) return false;
        if (SoAlfa) return true;
        int r = R(p), g = G(p), b = B(p);
        int mx = Math.Max(r, Math.Max(g, b)), mn = Math.Min(r, Math.Min(g, b));
        double v = mx / 255.0, s = mx == 0 ? 0 : (mx - mn) / (double)mx;
        if (v > 0.78 && s < 0.3) return false;          // lâmina, faísca
        if (r > 225 && g > 140) return false;           // rastro alaranjado/amarelo
        return true;
    }

    // linha dos pés: a última linha com corpo suficiente
    public static int Base(int[] c, int w, int h)
    {
        int min = Math.Max(3, w / 35);        // poeira e lascas finas no chão não contam como pé
        for (int y = h - 1; y >= 0; y--)
        {
            int n = 0;
            for (int x = 0; x < w; x++) if (Corpo(c[y * w + x])) n++;
            if (n >= min) return y;
        }
        return h - 1;
    }

    // centro do corpo: média das colunas com corpo numa faixa de alturas
    // (medida a partir da base, em fração da altura de referência)
    public static double Centro(int[] c, int w, int h, int baseY, double alturaRef, double f0, double f1)
    {
        int ya = (int)(baseY - alturaRef * f1), yb = (int)(baseY - alturaRef * f0);
        ya = Math.Max(0, ya); yb = Math.Min(h - 1, yb);
        double sx = 0, n = 0;
        for (int y = ya; y <= yb; y++)
            for (int x = 0; x < w; x++)
                if (Corpo(c[y * w + x])) { sx += x; n++; }
        if (n < 4)
        {
            for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) if (A(c[y * w + x]) > 128) { sx += x; n++; }
        }
        return n > 0 ? sx / n : w / 2.0;
    }

    // tamanho da cabeleira (a maior mancha castanha): a cabeça muda pouco entre
    // as poses, então serve de régua para igualar a escala das folhas.
    // Devolve {largura, altura} da mancha.
    public static int[] Cabelo(int[] c, int w, int h) { return Mancha(c, w, h, false); }
    public static int[] Rosto(int[] c, int w, int h) { return Mancha(c, w, h, true); }

    static int[] Mancha(int[] c, int w, int h, bool pele)
    {
        var m = new bool[w * h];
        for (int i = 0; i < c.Length; i++)
        {
            int p = c[i]; if (A(p) < 200) continue;
            int r = R(p), g = G(p), b = B(p);
            if (pele) m[i] = r > 185 && g > 125 && b > 90 && r > g && g > b && r - b >= 35 && r - b <= 130 && g > r * 0.62;
            else m[i] = r >= 60 && r <= 210 && g >= 35 && g <= 140 && b >= 15 && b <= 110 && r - b > 30 && g > r * 0.38 && g < r * 0.8;
        }
        var vis = new bool[w * h];
        var fila = new int[w * h];
        int melhor = 0; int[] bx = { 0, 0 };
        for (int i = 0; i < m.Length; i++)
        {
            if (!m[i] || vis[i]) continue;
            int ini = 0, fim = 0, n = 0, l = w, t = h, rr = 0, bb = 0;
            fila[fim++] = i; vis[i] = true;
            while (ini < fim)
            {
                int p = fila[ini++]; n++;
                int x = p % w, y = p / w;
                if (x < l) l = x; if (x > rr) rr = x; if (y < t) t = y; if (y > bb) bb = y;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int xx = x + dx, yy = y + dy;
                        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                        int q = yy * w + xx;
                        if (!m[q] || vis[q]) continue;
                        vis[q] = true; fila[fim++] = q;
                    }
            }
            if (n > melhor) { melhor = n; bx = new int[] { rr - l + 1, bb - t + 1 }; }
        }
        return bx;
    }

    // centro da SILHUETA (meio da caixa do corpo, sem lâmina nem rastro) entre
    // f0 e f1 da altura de referência acima dos pés: é em volta dele que o
    // desenho espelha ao virar de lado (se a origem fica fora dele, o corpo pula)
    public static double CentroSilhueta(int[] c, int w, int h, int baseY, double alturaRef, double f0, double f1)
    {
        int ya = Math.Max(0, (int)(baseY - alturaRef * f1)), yb = Math.Min(h - 1, (int)(baseY - alturaRef * f0));
        // por coluna: quantos pixels de corpo; corta as pontas finas (5% de cada lado)
        var col = new int[w]; int total = 0;
        for (int y = ya; y <= yb; y++)
            for (int x = 0; x < w; x++)
                if (Corpo(c[y * w + x])) { col[x]++; total++; }
        if (total < 10) return w / 2.0;
        int acc = 0, l = 0, r = w - 1;
        for (int x = 0; x < w; x++) { acc += col[x]; if (acc >= total * 0.05) { l = x; break; } }
        acc = 0;
        for (int x = w - 1; x >= 0; x--) { acc += col[x]; if (acc >= total * 0.05) { r = x; break; } }
        return (l + r) / 2.0;
    }

    // REGISTRO de dois quadros da mesma animação: o deslocamento horizontal
    // de B que faz a parte de cima do corpo (cabeça e tronco, entre f0 e f1 da
    // altura de referência acima dos pés) cair em cima da de A. Cada quadro é
    // dado com a sua origem (cx, base). Devolve dx: B deve andar dx para a direita.
    public static int Registrar(int[] a, int aw, int ah, double acx, int abase,
                                int[] b, int bw, int bh, double bcx, int bbase,
                                double alt, double f0, double f1, int maxd)
    {
        int r0 = (int)(alt * f0), r1 = (int)(alt * f1);
        int R = Math.Max(aw, bw) + maxd + 2;
        int L = 2 * R + 1, nr = r1 - r0 + 1;
        var ma = new bool[nr * L];
        var mb = new bool[nr * L];
        for (int r = 0; r < nr; r++)
        {
            int ya = abase - (r0 + r), yb = bbase - (r0 + r);
            if (ya >= 0 && ya < ah)
                for (int x = 0; x < aw; x++)
                    if (Corpo(a[ya * aw + x])) { int u = (int)Math.Round(x - acx) + R; if (u >= 0 && u < L) ma[r * L + u] = true; }
            if (yb >= 0 && yb < bh)
                for (int x = 0; x < bw; x++)
                    if (Corpo(b[yb * bw + x])) { int u = (int)Math.Round(x - bcx) + R; if (u >= 0 && u < L) mb[r * L + u] = true; }
        }
        int melhor = 0; long pontos = -1;
        for (int dx = -maxd; dx <= maxd; dx++)
        {
            long s = 0;
            for (int r = 0; r < nr; r++)
            {
                int o = r * L;
                for (int u = Math.Max(0, dx); u < Math.Min(L, L + dx); u++)
                    if (ma[o + u] && mb[o + u - dx]) s++;
            }
            // empate: o menor deslocamento
            if (s > pontos || (s == pontos && Math.Abs(dx) < Math.Abs(melhor))) { pontos = s; melhor = dx; }
        }
        return pontos <= 0 ? 0 : melhor;
    }

    // cola src em dst (alfa sobre)
    public static void Colar(int[] dst, int dw, int dh, int[] src, int sw, int sh, int ox, int oy)
    {
        for (int y = 0; y < sh; y++)
        {
            int yy = y + oy; if (yy < 0 || yy >= dh) continue;
            for (int x = 0; x < sw; x++)
            {
                int xx = x + ox; if (xx < 0 || xx >= dw) continue;
                int s = src[y * sw + x];
                if (A(s) == 0) continue;
                dst[yy * dw + xx] = s;
            }
        }
    }

    public static int[] Vazio(int w, int h) { return new int[w * h]; }

    // escurece/clareia e satura (ajuste fino de cor de um quadro inteiro)
    public static void Tom(int[] c, double brilho, double sat)
    {
        for (int i = 0; i < c.Length; i++)
        {
            int p = c[i]; if (A(p) == 0) continue;
            double r = R(p) * brilho, g = G(p) * brilho, b = B(p) * brilho;
            double l = 0.299 * r + 0.587 * g + 0.114 * b;
            c[i] = Cor(A(p), (int)(l + (r - l) * sat), (int)(l + (g - l) * sat), (int)(l + (b - l) * sat));
        }
    }

    // caixa dos pixels visíveis (para a caixa de colisão do .yy)
    public static int[] Caixa(int[] c, int w, int h)
    {
        int l = w, t = h, r = -1, b = -1;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
                if (A(c[y * w + x]) > 20) { if (x < l) l = x; if (x > r) r = x; if (y < t) t = y; if (y > b) b = y; }
        if (r < 0) return new int[] { 0, 0, w - 1, h - 1 };
        return new int[] { l, t, r, b };
    }
}
