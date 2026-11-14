using System;
using System.Collections.Generic;

// =====================================================================
//  ImportaCapturas: poses do herói a partir de CAPTURAS DE TELA do editor
//  de sprites (v1.19, ferramentas/importar_movimento.ps1). As capturas não
//  têm as caixas bem marcadas das folhas da equipe (ImportaFolhas.Caixas não
//  as acha), então as poses são achadas como manchas que não são fundo, e
//  as linhas finas das bordas das células que entram no recorte são apagadas.
//  O recorte sem fundo e a escala continuam com o ImportaFolhas.
// =====================================================================
public static class ImportaCapturas
{
    // é fundo da célula ou borda dela (cinza-azulado escuro)?
    static bool Fundo(uint c, int fr, int fg, int fb)
    {
        int r = ImportaFolhas.R(c), g = ImportaFolhas.G(c), b = ImportaFolhas.B(c);
        int d1 = (r - fr) * (r - fr) + (g - fg) * (g - fg) + (b - fb) * (b - fb);
        int r2 = r - (fr + 11), g2 = g - (fg + 9), b2 = b - (fb + 10);
        int d2 = r2 * r2 + g2 * g2 + b2 * b2;
        return Math.Min(d1, d2) < 900;
    }

    // manchas grandes (poses): lista de [x, y, w, h], em ordem de leitura
    public static List<int[]> Poses(ImportaFolhas.Img f, int fr, int fg, int fb, int minPix)
    {
        var vis = new bool[f.W * f.H];
        var res = new List<int[]>();
        var fila = new Queue<int>();
        for (int i = 0; i < f.P.Length; i++)
        {
            if (vis[i] || Fundo(f.P[i], fr, fg, fb)) continue;
            int x0 = int.MaxValue, x1 = -1, y0 = int.MaxValue, y1 = -1, n = 0;
            vis[i] = true; fila.Enqueue(i);
            while (fila.Count > 0)
            {
                int p = fila.Dequeue(); int px = p % f.W, py = p / f.W; n++;
                if (px < x0) x0 = px; if (px > x1) x1 = px; if (py < y0) y0 = py; if (py > y1) y1 = py;
                for (int k = 0; k < 4; k++)
                {
                    int nx = px + (k == 0 ? 1 : k == 1 ? -1 : 0), ny = py + (k == 2 ? 1 : k == 3 ? -1 : 0);
                    if (nx < 0 || ny < 0 || nx >= f.W || ny >= f.H) continue;
                    int q = ny * f.W + nx;
                    if (vis[q] || Fundo(f.P[q], fr, fg, fb)) continue;
                    vis[q] = true; fila.Enqueue(q);
                }
            }
            if (n >= minPix) res.Add(new[] { x0, y0, x1 - x0 + 1, y1 - y0 + 1 });
        }
        res.Sort((a, b) => Math.Abs(a[1] - b[1]) > 60 ? a[1].CompareTo(b[1]) : a[0].CompareTo(b[0]));
        return res;
    }

    // pouco saturado (borda da célula, não a armadura vermelha nem o cabelo)
    static bool Neutro(uint c)
    {
        if ((c >> 24) < 60) return false;
        int r = ImportaFolhas.R(c), g = ImportaFolhas.G(c), b = ImportaFolhas.B(c);
        return Math.Max(r, Math.Max(g, b)) - Math.Min(r, Math.Min(g, b)) < 40 && b >= r - 6;
    }

    // apaga linhas retas e finas (bordas das células) que entraram no recorte
    public static void TirarBordas(ImportaFolhas.Img o)
    {
        // colunas: trecho vertical neutro com mais de 40% da altura
        for (int x = 0; x < o.W; x++)
        {
            int n = 0; for (int y = 0; y < o.H; y++) if (Neutro(o.Get(x, y))) n++;
            if (n > o.H * 0.4) for (int y = 0; y < o.H; y++) if (Neutro(o.Get(x, y))) o.Set(x, y, 0);
        }
        // linhas: idem na horizontal (a borda de baixo, embaixo dos pés)
        for (int y = 0; y < o.H; y++)
        {
            int n = 0; for (int x = 0; x < o.W; x++) if (Neutro(o.Get(x, y))) n++;
            if (n > o.W * 0.4) for (int x = 0; x < o.W; x++) if (Neutro(o.Get(x, y))) o.Set(x, y, 0);
        }
        ImportaFolhas.LimparMiudos(o, 14);
    }
}
