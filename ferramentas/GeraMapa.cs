// =====================================================================
//  GeraMapa (v1.17) - as FOTOS das 18 fases do MAPA DE VALLACK
//  mapa_fases.jpg: 6 x 3 fotos de 320 x 180 (a fase N fica na coluna
//  (N-1) mod 6, linha (N-1) div 6). A fase 1 é montada com a arte de
//  verdade da vila (cenario_fase1.png + .json); as outras são pinturas
//  do tema de cada fase (todas em desenvolvimento no jogo).
// =====================================================================
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Text.RegularExpressions;

public static class GeraMapa
{
    const int W = 320, H = 180;
    static Random R;

    static Color C(int r, int g, int b, int a = 255) { return Color.FromArgb(a, r, g, b); }

    // ------------------------------------------------------------ ferramentas de pintura
    static void Ceu(Graphics g, Color c1, Color c2, Color c3)
    {
        using (var br = new LinearGradientBrush(new Rectangle(0, 0, W, H), c1, c3, 90f))
        {
            var cb = new ColorBlend();
            cb.Colors = new[] { c1, c2, c3 };
            cb.Positions = new[] { 0f, 0.55f, 1f };
            br.InterpolationColors = cb;
            g.FillRectangle(br, 0, 0, W, H);
        }
    }

    static void Brilho(Graphics g, float x, float y, float rx, float ry, Color c, int alfa)
    {
        using (var p = new GraphicsPath())
        {
            p.AddEllipse(x - rx, y - ry, rx * 2, ry * 2);
            using (var br = new PathGradientBrush(p))
            {
                br.CenterColor = Color.FromArgb(alfa, c);
                br.SurroundColors = new[] { Color.FromArgb(0, c) };
                g.FillPath(br, p);
            }
        }
    }

    static void Montanhas(Graphics g, float baseY, float amp, float freq, Color c, int seed, bool pontudas = false)
    {
        var pts = new List<PointF>();
        pts.Add(new PointF(-2, H + 2));
        double f1 = seed * 1.7, f2 = seed * 0.37;
        for (int x = -2; x <= W + 4; x += 4)
        {
            double h = Math.Sin(x * freq + f1) * 0.55 + Math.Sin(x * freq * 2.3 + f2) * 0.3 + Math.Sin(x * freq * 5.1 + seed) * 0.15;
            if (pontudas) h = Math.Abs(h) * 1.4 - 0.2;
            pts.Add(new PointF(x, (float)(baseY - h * amp)));
        }
        pts.Add(new PointF(W + 4, H + 2));
        using (var br = new SolidBrush(c)) g.FillPolygon(br, pts.ToArray());
    }

    static void Chama(Graphics g, float x, float y, float w, float h, Color fora, Color dentro)
    {
        for (int k = 0; k < 2; k++)
        {
            float ww = w * (k == 0 ? 1 : 0.55f), hh = h * (k == 0 ? 1 : 0.6f);
            using (var p = new GraphicsPath())
            {
                p.AddBezier(x - ww / 2, y, x - ww / 2, y - hh * 0.5f, x - ww * 0.1f, y - hh * 0.7f, x, y - hh);
                p.AddBezier(x, y - hh, x + ww * 0.15f, y - hh * 0.6f, x + ww / 2, y - hh * 0.45f, x + ww / 2, y);
                p.CloseFigure();
                using (var br = new SolidBrush(k == 0 ? fora : dentro)) g.FillPath(br, p);
            }
        }
    }

    static void Particulas(Graphics g, int n, Color c, float y1, float y2, float r1, float r2)
    {
        using (var br = new SolidBrush(c))
            for (int i = 0; i < n; i++)
            {
                float r = (float)(r1 + R.NextDouble() * (r2 - r1));
                g.FillEllipse(br, (float)(R.NextDouble() * W), (float)(y1 + R.NextDouble() * (y2 - y1)), r, r);
            }
    }

    static void Nevoa(Graphics g, float y, Color c, int alfa, int n)
    {
        for (int i = 0; i < n; i++)
        {
            float cx = (float)(R.NextDouble() * W);
            Brilho(g, cx, y + (float)(R.NextDouble() * 12 - 6), 70 + (float)R.NextDouble() * 60, 10 + (float)R.NextDouble() * 6, c, alfa);
        }
    }

    static void Arvore(Graphics g, float x, float y, float ang, float comp, float esp, int nivel, Color c, bool espinhos)
    {
        if (nivel <= 0 || comp < 3) return;
        float x2 = x + (float)Math.Cos(ang) * comp, y2 = y - (float)Math.Sin(ang) * comp;
        using (var pen = new Pen(c, esp)) { pen.StartCap = LineCap.Round; pen.EndCap = LineCap.Round; g.DrawLine(pen, x, y, x2, y2); }
        if (espinhos && nivel < 4)
            using (var pen2 = new Pen(c, 1))
                for (int k = 0; k < 2; k++) { float t = (float)R.NextDouble(); float px = x + (x2 - x) * t, py = y + (y2 - y) * t; g.DrawLine(pen2, px, py, px + (float)(R.NextDouble() * 8 - 4), py - (float)(R.NextDouble() * 6)); }
        int n = 2 + (R.NextDouble() < 0.3 ? 1 : 0);
        for (int i = 0; i < n; i++)
            Arvore(g, x2, y2, ang + (float)((R.NextDouble() - 0.5) * 1.3), comp * (0.62f + (float)R.NextDouble() * 0.15f), Math.Max(1, esp * 0.65f), nivel - 1, c, espinhos);
    }

    static void Vinheta(Graphics g)
    {
        using (var p = new GraphicsPath())
        {
            p.AddEllipse(-W * 0.35f, -H * 0.45f, W * 1.7f, H * 1.9f);
            using (var br = new PathGradientBrush(p))
            {
                br.CenterColor = Color.FromArgb(0, 0, 0, 0);
                br.SurroundColors = new[] { Color.FromArgb(210, 0, 0, 0) };
                br.FocusScales = new PointF(0.55f, 0.55f);
                g.FillRectangle(br, 0, 0, W, H);
            }
        }
    }

    static void Retangulos(Graphics g, Color c, params float[] r)
    {
        using (var br = new SolidBrush(c)) for (int i = 0; i + 3 < r.Length; i += 4) g.FillRectangle(br, r[i], r[i + 1], r[i + 2], r[i + 3]);
    }

    static void Poligono(Graphics g, Color c, params float[] p)
    {
        var pts = new PointF[p.Length / 2];
        for (int i = 0; i < pts.Length; i++) pts[i] = new PointF(p[i * 2], p[i * 2 + 1]);
        using (var br = new SolidBrush(c)) g.FillPolygon(br, pts);
    }

    // ------------------------------------------------------------ FASE 1: a vila de verdade
    static Dictionary<string, Rectangle> LerPecas(string json)
    {
        var d = new Dictionary<string, Rectangle>();
        foreach (Match m in Regex.Matches(json, "\"([a-z_0-9]+)\": \\{\"x\": (\\d+), \"y\": (\\d+), \"w\": (\\d+), \"h\": (\\d+)"))
            d[m.Groups[1].Value] = new Rectangle(int.Parse(m.Groups[2].Value), int.Parse(m.Groups[3].Value), int.Parse(m.Groups[4].Value), int.Parse(m.Groups[5].Value));
        return d;
    }

    static void Peca(Graphics g, Bitmap atlas, Dictionary<string, Rectangle> pc, string nome, float x, float baseY, float esc, float tom = 1)
    {
        if (!pc.ContainsKey(nome)) return;
        var r = pc[nome];
        var ia = new ImageAttributes();
        var cm = new ColorMatrix(new float[][] {
            new float[] { tom, 0, 0, 0, 0 }, new float[] { 0, tom, 0, 0, 0 }, new float[] { 0, 0, tom * 1.05f, 0, 0 },
            new float[] { 0, 0, 0, 1, 0 }, new float[] { 0, 0, 0, 0, 1 } });
        ia.SetColorMatrix(cm);
        g.DrawImage(atlas, new Rectangle((int)x, (int)(baseY - r.Height * esc), (int)(r.Width * esc), (int)(r.Height * esc)), r.X, r.Y, r.Width, r.Height, GraphicsUnit.Pixel, ia);
    }

    static void Fase1(Graphics g, string pastaDados)
    {
        Ceu(g, C(22, 16, 36), C(70, 44, 70), C(150, 80, 70));
        Brilho(g, 244, 30, 16, 16, C(240, 220, 200), 230);
        Brilho(g, 244, 30, 40, 40, C(200, 170, 170), 60);
        string jsonArq = Path.Combine(pastaDados, "cenario_fase1.json"), pngArq = Path.Combine(pastaDados, "cenario_fase1.png");
        if (File.Exists(jsonArq) && File.Exists(pngArq))
        {
            var pc = LerPecas(File.ReadAllText(jsonArq));
            using (var atlas = new Bitmap(pngArq))
            {
                g.InterpolationMode = InterpolationMode.NearestNeighbor;
                g.PixelOffsetMode = PixelOffsetMode.Half;
                for (int x = -20; x < W; x += 160) Peca(g, atlas, pc, "montanhas", x, 120, 0.16f);
                for (int x = -40; x < W; x += 160) Peca(g, atlas, pc, "vila_longe", x, 132, 0.16f);
                Brilho(g, W / 2, 150, 200, 40, C(255, 90, 30), 90);
                string[] fundo = { "casa_x2", "casa_f", "casa_x5", "casa_h", "casa_x1", "casa_l" };
                for (int i = 0; i < fundo.Length; i++) Peca(g, atlas, pc, fundo[i], -10 + i * 58, 150, 0.5f, 0.55f);
                Retangulos(g, C(22, 22, 24), 0, 148, W, 40);
                string[] frente = { "casa_b", "igreja", "casa_x3", "casa_d" };
                float[] fx = { -18, 70, 172, 236 };
                for (int i = 0; i < frente.Length; i++) Peca(g, atlas, pc, frente[i], fx[i], 172, 0.72f);
                g.SmoothingMode = SmoothingMode.AntiAlias;
                float[] fogos = { 20, 100, 205, 268, 140 };
                foreach (float f in fogos)
                {
                    Brilho(g, f, 110, 34, 30, C(160, 40, 255), 70);
                    Chama(g, f, 116, 18, 34, C(220, 110, 255, 220), C(255, 230, 255, 230));
                }
            }
        }
        Retangulos(g, C(16, 14, 16), 0, 172, W, 10);
        Particulas(g, 50, C(255, 160, 80, 200), 60, 170, 1, 2.2f);
    }

    // ------------------------------------------------------------ fases 2 a 18 (temas)
    static void Pintar(Graphics g, int fase, string pastaDados)
    {
        R = new Random(1000 + fase * 77);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        switch (fase)
        {
            case 1: Fase1(g, pastaDados); break;
            case 2:     // O SALÃO REAL EM RUÍNAS
                Ceu(g, C(18, 10, 16), C(46, 20, 26), C(28, 12, 14));
                for (int i = 0; i < 4; i++) Brilho(g, 60 + i * 70, 0, 18, 140, C(255, 210, 160), 70);
                for (int i = 0; i < 6; i++) { float x = 14 + i * 58; Retangulos(g, C(36, 24, 28), x, 20, 22, 160); Retangulos(g, C(60, 40, 44), x - 4, 20, 30, 10, x - 4, 160, 30, 10); }
                Poligono(g, C(58, 14, 18), 150, 70, 170, 70, 172, 150, 148, 150);
                Retangulos(g, C(20, 12, 14), 136, 120, 48, 40);
                Poligono(g, C(30, 16, 18), 140, 120, 160, 82, 180, 120);
                Brilho(g, 160, 110, 50, 40, C(170, 40, 200), 80);
                Retangulos(g, C(30, 18, 18), 0, 160, W, 20);
                Particulas(g, 40, C(220, 200, 180, 120), 10, 170, 1, 2);
                break;
            case 3:     // AS MURALHAS DE VALLACK
                Ceu(g, C(10, 14, 30), C(30, 34, 64), C(80, 60, 70));
                Brilho(g, 60, 40, 14, 14, C(230, 230, 240), 220);
                Montanhas(g, 120, 16, 0.02f, C(30, 30, 46), fase);
                Retangulos(g, C(34, 32, 42), 0, 96, W, 90);
                for (int x = 0; x < W; x += 16) Retangulos(g, C(34, 32, 42), x, 88, 9, 10);
                for (int t = 0; t < 3; t++) { float tx = 30 + t * 120; Retangulos(g, C(26, 24, 34), tx, 54, 40, 130); for (int k = 0; k < 4; k++) Retangulos(g, C(26, 24, 34), tx + k * 11, 46, 7, 9); Retangulos(g, C(255, 170, 70), tx + 16, 80, 6, 10); Brilho(g, tx + 19, 85, 20, 20, C(255, 150, 60), 120); }
                using (var pen = new Pen(C(200, 190, 170, 160), 1)) for (int i = 0; i < 26; i++) { float x = (float)(R.NextDouble() * W), y = (float)(R.NextDouble() * 80); g.DrawLine(pen, x, y, x + 10, y + 7); }
                Retangulos(g, C(20, 18, 24), 0, 170, W, 10);
                break;
            case 4:     // O PÂNTANO DOS AFOGADOS
                Ceu(g, C(10, 20, 16), C(30, 50, 36), C(60, 80, 54));
                Montanhas(g, 110, 10, 0.03f, C(24, 40, 30), fase);
                Retangulos(g, C(20, 36, 30), 0, 120, W, 60);
                using (var br = new LinearGradientBrush(new Rectangle(0, 120, W, 60), C(40, 70, 52), C(10, 20, 16), 90f)) g.FillRectangle(br, 0, 120, W, 60);
                for (int i = 0; i < 5; i++) Arvore(g, 20 + i * 70 + (float)R.NextDouble() * 20, 132, (float)(Math.PI / 2), 36, 4, 5, C(16, 22, 18), false);
                Nevoa(g, 118, C(150, 220, 160), 70, 8);
                for (int i = 0; i < 9; i++) Brilho(g, (float)(R.NextDouble() * W), 90 + (float)(R.NextDouble() * 70), 6, 6, C(140, 255, 160), 200);
                break;
            case 5:     // A FLORESTA DE ESPINHOS
                Ceu(g, C(30, 6, 8), C(90, 16, 16), C(160, 50, 30));
                Brilho(g, W / 2, 110, 160, 60, C(255, 80, 30), 90);
                for (int i = 0; i < 7; i++) Arvore(g, 10 + i * 50 + (float)R.NextDouble() * 18, 185, (float)(Math.PI / 2 + (R.NextDouble() - 0.5) * 0.3), 50, 6, 6, C(16, 6, 8), true);
                Retangulos(g, C(14, 4, 6), 0, 168, W, 12);
                Particulas(g, 30, C(255, 120, 60, 180), 40, 170, 1, 2);
                break;
            case 6:     // AS MINAS DE CINZA
                Ceu(g, C(14, 10, 10), C(30, 20, 18), C(50, 30, 22));
                Brilho(g, W / 2, 120, 120, 60, C(255, 110, 30), 110);
                Poligono(g, C(10, 8, 8), 0, 0, W, 0, W, 50, 250, 30, 200, 20, 120, 24, 60, 40, 0, 60);
                Poligono(g, C(12, 9, 8), 0, 60, 40, 80, 30, 180, 0, 180);
                Poligono(g, C(12, 9, 8), W, 60, 280, 76, 290, 180, W, 180);
                for (int i = 0; i < 3; i++) { float x = 70 + i * 80; Retangulos(g, C(70, 44, 26), x, 60, 7, 110, x + 44, 60, 7, 110, x, 56, 51, 7); }
                using (var pen = new Pen(C(90, 80, 70), 2)) { g.DrawLine(pen, 40, 178, 160, 120); g.DrawLine(pen, 280, 178, 165, 120); }
                for (int i = 0; i < 20; i++) Brilho(g, (float)(R.NextDouble() * W), 150 + (float)(R.NextDouble() * 30), 3, 3, C(255, 140, 40), 220);
                break;
            case 7:     // A CATEDRAL PARTIDA
                Ceu(g, C(14, 12, 30), C(40, 30, 60), C(90, 60, 80));
                Montanhas(g, 140, 10, 0.02f, C(30, 24, 40), fase);
                Poligono(g, C(20, 16, 28), 90, 180, 90, 70, 110, 40, 130, 70, 130, 60, 160, 10, 190, 60, 190, 70, 210, 40, 230, 70, 230, 180);
                Brilho(g, 160, 92, 20, 20, C(200, 60, 160), 230);
                Brilho(g, 160, 92, 40, 40, C(80, 120, 255), 90);
                using (var pen = new Pen(C(20, 16, 28), 2)) { g.DrawLine(pen, 145, 92, 175, 92); g.DrawLine(pen, 160, 77, 160, 107); }
                Retangulos(g, C(16, 12, 22), 0, 170, W, 10);
                break;
            case 8:     // O CEMITÉRIO DOS REIS
                Ceu(g, C(10, 14, 24), C(36, 44, 60), C(70, 74, 84));
                Brilho(g, 240, 46, 20, 20, C(230, 236, 230), 230);
                Brilho(g, 240, 46, 60, 60, C(180, 200, 200), 50);
                Retangulos(g, C(26, 30, 34), 0, 140, W, 40);
                for (int i = 0; i < 12; i++) { float x = 10 + i * 27 + (float)R.NextDouble() * 6, y = 132 + (float)R.NextDouble() * 16; if (i % 3 == 0) { Retangulos(g, C(20, 24, 28), x + 4, y - 26, 4, 30, x - 4, y - 18, 20, 4); } else { Retangulos(g, C(22, 26, 30), x, y - 16, 12, 18); g.FillEllipse(new SolidBrush(C(22, 26, 30)), x, y - 22, 12, 12); } }
                Poligono(g, C(18, 20, 24), 120, 140, 120, 100, 160, 76, 200, 100, 200, 140);
                Nevoa(g, 150, C(180, 200, 210), 60, 6);
                break;
            case 9:     // A PONTE DO ABISMO
                Ceu(g, C(14, 8, 24), C(40, 20, 50), C(20, 8, 24));
                Brilho(g, W / 2, 175, 140, 50, C(170, 50, 255), 120);
                Poligono(g, C(16, 10, 18), 0, 90, 70, 96, 80, 180, 0, 180);
                Poligono(g, C(16, 10, 18), W, 84, 250, 92, 240, 180, W, 180);
                using (var pen = new Pen(C(120, 100, 90), 2))
                {
                    for (int k = 0; k < 2; k++)
                    {
                        var pts = new List<PointF>();
                        for (int x = 70; x <= 250; x += 10) pts.Add(new PointF(x, 94 + k * 10 + (float)(Math.Sin((x - 70) / 180.0 * Math.PI) * 24)));
                        g.DrawLines(pen, pts.ToArray());
                    }
                    for (int x = 80; x <= 240; x += 12) { float y = 104 + (float)(Math.Sin((x - 70) / 180.0 * Math.PI) * 24); g.DrawLine(pen, x, y - 10, x, y); }
                }
                break;
            case 10:    // AS TERRAS QUEIMADAS
                Ceu(g, C(40, 14, 8), C(110, 40, 16), C(180, 90, 40));
                for (int i = 0; i < 5; i++) { float x = 30 + i * 64; Brilho(g, x, 60, 18, 60, C(60, 50, 50), 150); }
                Retangulos(g, C(30, 14, 10), 0, 140, W, 40);
                for (int i = 0; i < 9; i++) { float x = (float)(R.NextDouble() * W), y = 140 + (float)(R.NextDouble() * 30); Brilho(g, x, y, 20, 10, C(255, 100, 30), 140); Chama(g, x, y, 10, 18 + (float)R.NextDouble() * 10, C(255, 120, 30, 220), C(255, 220, 120, 230)); }
                using (var pen = new Pen(C(24, 12, 10), 2)) for (int i = 0; i < 6; i++) { float x = 20 + i * 54; g.DrawLine(pen, x, 150, x + 6, 100); Poligono(g, C(90, 20, 16), x + 6, 100, x + 26, 106, x + 6, 114); }
                Particulas(g, 50, C(255, 170, 80, 200), 20, 170, 1, 2);
                break;
            case 11:    // A FORJA DOS CONDENADOS
                Ceu(g, C(16, 8, 6), C(40, 16, 10), C(30, 12, 8));
                Brilho(g, 160, 110, 110, 70, C(255, 120, 30), 160);
                Retangulos(g, C(24, 14, 12), 110, 90, 100, 90);
                Poligono(g, C(255, 150, 50), 130, 130, 190, 130, 180, 110, 140, 110);
                Retangulos(g, C(20, 12, 10), 30, 140, 50, 12, 46, 152, 18, 26, 240, 140, 50, 12, 256, 152, 18, 26);
                using (var pen = new Pen(C(60, 50, 50), 2)) for (int i = 0; i < 5; i++) { float x = 20 + i * 70; for (int k = 0; k < 6; k++) g.DrawEllipse(pen, x, k * 9, 6, 9); }
                for (int i = 0; i < 40; i++) Brilho(g, 160 + (float)(R.NextDouble() * 140 - 70), 40 + (float)(R.NextDouble() * 90), 2, 2, C(255, 210, 120), 255);
                break;
            case 12:    // O LAGO DE GELO NEGRO
                Ceu(g, C(16, 22, 40), C(60, 80, 110), C(140, 160, 180));
                Montanhas(g, 104, 34, 0.025f, C(150, 166, 186), fase, true);
                Montanhas(g, 114, 20, 0.04f, C(90, 104, 126), fase + 3, true);
                using (var br = new LinearGradientBrush(new Rectangle(0, 116, W, 64), C(40, 50, 70), C(10, 14, 24), 90f)) g.FillRectangle(br, 0, 116, W, 64);
                using (var pen = new Pen(C(150, 190, 220, 160), 1)) for (int i = 0; i < 10; i++) { float x = (float)(R.NextDouble() * W), y = 124 + (float)(R.NextDouble() * 50); g.DrawLine(pen, x, y, x + 20 + (float)(R.NextDouble() * 30), y + (float)(R.NextDouble() * 6 - 3)); }
                Particulas(g, 120, C(240, 246, 255, 220), 0, 180, 1, 2.4f);
                break;
            case 13:    // A TORRE DO ALQUIMISTA
                Ceu(g, C(12, 18, 16), C(30, 50, 40), C(40, 70, 50));
                Montanhas(g, 150, 14, 0.03f, C(20, 30, 26), fase);
                Poligono(g, C(18, 22, 20), 140, 180, 146, 60, 136, 40, 160, 10, 184, 40, 174, 60, 180, 180);
                for (int k = 0; k < 4; k++) { Retangulos(g, C(140, 255, 120), 154, 60 + k * 28, 10, 12); Brilho(g, 159, 66 + k * 28, 20, 18, C(120, 255, 120), 120); }
                for (int i = 0; i < 16; i++) { float x = 160 + (float)(R.NextDouble() * 60 - 30), y = 10 + (float)(R.NextDouble() * 40); Brilho(g, x, y, 6, 6, C(150, 255, 150), 150); }
                Retangulos(g, C(14, 18, 16), 0, 170, W, 10);
                break;
            case 14:    // O LABIRINTO DE OSSOS
                Ceu(g, C(18, 14, 12), C(40, 32, 26), C(26, 20, 16));
                Brilho(g, W / 2, 100, 120, 60, C(255, 200, 140), 60);
                for (int row = 0; row < 5; row++)
                    for (int i = 0; i < 9; i++)
                    {
                        float x = (row % 2) * 14 + i * 28, y = 30 + row * 24;
                        if (x > 100 && x < 220 && row > 1) continue;
                        using (var br = new SolidBrush(C(200, 186, 160))) g.FillEllipse(br, x, y, 20, 18);
                        using (var br2 = new SolidBrush(C(30, 24, 20))) { g.FillEllipse(br2, x + 4, y + 6, 4, 4); g.FillEllipse(br2, x + 12, y + 6, 4, 4); }
                    }
                using (var pen = new Pen(C(210, 196, 170), 3)) for (int k = 0; k < 5; k++) g.DrawArc(pen, 120 + k * 3, 80 + k * 10, 80 - k * 6, 90, 180, 180);
                Retangulos(g, C(20, 16, 12), 0, 168, W, 12);
                break;
            case 15:    // O PORTO FANTASMA
                Ceu(g, C(14, 20, 26), C(44, 56, 64), C(70, 80, 84));
                using (var br = new LinearGradientBrush(new Rectangle(0, 120, W, 60), C(30, 40, 46), C(8, 12, 16), 90f)) g.FillRectangle(br, 0, 120, W, 60);
                for (int s = 0; s < 3; s++)
                {
                    float x = 30 + s * 100, y = 126 - s * 4;
                    Poligono(g, C(16, 20, 22), x, y, x + 70, y, x + 60, y + 14, x + 10, y + 14);
                    using (var pen = new Pen(C(16, 20, 22), 2)) { g.DrawLine(pen, x + 35, y, x + 35, y - 70); g.DrawLine(pen, x + 15, y, x + 15, y - 46); }
                    Poligono(g, C(120, 120, 110, 160), x + 37, y - 64, x + 62, y - 50, x + 58, y - 26, x + 37, y - 30);
                    Brilho(g, x + 60, y - 4, 10, 10, C(255, 200, 120), 200);
                }
                Nevoa(g, 120, C(190, 200, 200), 90, 9);
                break;
            case 16:    // O SANTUÁRIO DE SYLLA
                Ceu(g, C(16, 10, 26), C(46, 26, 70), C(30, 16, 40));
                Brilho(g, 160, 120, 90, 70, C(170, 70, 255), 150);
                Poligono(g, C(30, 22, 40), 60, 50, 160, 14, 260, 50);
                Retangulos(g, C(34, 26, 46), 60, 50, 200, 10);
                for (int i = 0; i < 5; i++) Retangulos(g, C(40, 30, 54), 70 + i * 44, 60, 14, 104);
                Retangulos(g, C(26, 20, 34), 130, 140, 60, 24, 50, 164, 220, 16);
                Chama(g, 160, 142, 30, 52, C(190, 80, 255, 230), C(250, 220, 255, 240));
                break;
            case 17:    // O TRONO DE VALLACK
                Ceu(g, C(16, 6, 8), C(40, 12, 14), C(24, 8, 10));
                Brilho(g, 160, 80, 70, 80, C(255, 40, 30), 140);
                for (int i = 0; i < 4; i++) { Retangulos(g, C(36, 14, 16), 20 + i * 90, 0, 20, 180); Poligono(g, C(110, 18, 18), 50 + i * 90, 10, 70 + i * 90, 10, 70 + i * 90, 70, 60 + i * 90, 60, 50 + i * 90, 70); }
                for (int k = 0; k < 4; k++) Retangulos(g, C(30 + k * 6, 12, 14), 100 - k * 16, 140 + k * 10, 120 + k * 32, 10);
                Poligono(g, C(12, 6, 8), 140, 140, 140, 80, 150, 60, 160, 72, 170, 60, 180, 80, 180, 140);
                Retangulos(g, C(120, 20, 20), 150, 150, 20, 30);
                break;
            case 18:    // O COVIL DO DRAGÃO
                Ceu(g, C(30, 6, 4), C(100, 24, 10), C(200, 70, 20));
                Montanhas(g, 120, 40, 0.03f, C(30, 10, 8), fase, true);
                using (var br = new LinearGradientBrush(new Rectangle(0, 140, W, 40), C(255, 140, 30), C(180, 40, 10), 90f)) g.FillRectangle(br, 0, 150, W, 30);
                Montanhas(g, 160, 14, 0.06f, C(20, 6, 6), fase + 9);
                // o dragão na pedra, de asas abertas
                Poligono(g, C(14, 4, 6), 150, 100, 110, 50, 90, 70, 120, 96);
                Poligono(g, C(14, 4, 6), 170, 100, 210, 46, 236, 66, 200, 96);
                g.FillEllipse(new SolidBrush(C(14, 4, 6)), 140, 92, 44, 22);
                Poligono(g, C(14, 4, 6), 176, 96, 196, 80, 206, 84, 186, 100);
                Brilho(g, 202, 82, 4, 4, C(255, 220, 80), 255);
                Brilho(g, 160, 120, 80, 40, C(255, 90, 20), 70);
                Particulas(g, 70, C(255, 180, 80, 220), 0, 170, 1, 2.4f);
                break;
        }
        Vinheta(g);
    }

    public static string Gerar(string pastaGm, string pastaGd)
    {
        using (var atlas = new Bitmap(W * 6, H * 3, PixelFormat.Format24bppRgb))
        {
            using (var ga = Graphics.FromImage(atlas))
            {
                ga.Clear(Color.Black);
                for (int f = 1; f <= 18; f++)
                {
                    using (var foto = new Bitmap(W, H, PixelFormat.Format32bppArgb))
                    {
                        using (var g = Graphics.FromImage(foto))
                        {
                            g.Clear(Color.Black);
                            Pintar(g, f, pastaGm);
                        }
                        ga.DrawImageUnscaled(foto, ((f - 1) % 6) * W, ((f - 1) / 6) * H);
                    }
                }
            }
            var enc = ImageCodecInfo.GetImageEncoders();
            ImageCodecInfo jpg = null;
            foreach (var e in enc) if (e.MimeType == "image/jpeg") jpg = e;
            var pars = new EncoderParameters(1);
            pars.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 90L);
            foreach (var pasta in new[] { pastaGm, pastaGd }) atlas.Save(Path.Combine(pasta, "mapa_fases.jpg"), jpg, pars);
        }
        return "mapa_fases.jpg " + (W * 6) + "x" + (H * 3);
    }
}
