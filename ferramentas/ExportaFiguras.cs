// Exporta as imagens dos personagens para documentos (TCC, apresentação, loja).
// Lê o quadro escolhido de cada sprite do GameMaker (ordem do .yy), aplica o
// tingimento e as peças extras como o jogo faz, corta as bordas vazias e amplia
// em escala INTEIRA (vizinho mais próximo: a pixel art fica nítida).
// Gera duas versões: com fundo escuro (pronta para o documento) e transparente.
// Uso: ferramentas/exportar_figuras.ps1
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;

public static class ExportaFiguras
{
    static string raiz;

    // quadro N de um sprite do GameMaker (na ordem do .yy)
    static Bitmap Quadro(string spr, int n)
    {
        var dir = Path.Combine(raiz, "sprites", spr);
        var yy = File.ReadAllText(Path.Combine(dir, spr + ".yy"));
        var fr = yy.IndexOf("\"frames\":[");
        var fim = yy.IndexOf("],", fr);
        var ids = new List<string>();
        foreach (Match m in Regex.Matches(yy.Substring(fr, fim - fr), "\"\\$GMSpriteFrame\":\"v1\",\"%Name\":\"([0-9a-f-]+)\""))
            ids.Add(m.Groups[1].Value);
        using (var b = new Bitmap(Path.Combine(dir, ids[Math.Min(n, ids.Count - 1)] + ".png")))
            return new Bitmap(b);
    }

    static int Num(string spr, string campo)
    {
        var yy = File.ReadAllText(Path.Combine(raiz, "sprites", spr, spr + ".yy"));
        var m = Regex.Match(yy, "\"" + campo + "\":(-?\\d+)");
        return m.Success ? int.Parse(m.Groups[1].Value) : 0;
    }

    // multiplica a cor (como o image_blend / draw_sprite_ext do GameMaker)
    static void Tingir(Bitmap b, Color c)
    {
        var r = new Rectangle(0, 0, b.Width, b.Height);
        var d = b.LockBits(r, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        var px = new byte[d.Stride * b.Height];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        for (int i = 0; i < px.Length; i += 4)
        {
            px[i] = (byte)(px[i] * c.B / 255);
            px[i + 1] = (byte)(px[i + 1] * c.G / 255);
            px[i + 2] = (byte)(px[i + 2] * c.R / 255);
        }
        Marshal.Copy(px, 0, d.Scan0, px.Length);
        b.UnlockBits(d);
    }

    // retângulo dos pixels visíveis
    static Rectangle Caixa(Bitmap b)
    {
        var r = new Rectangle(0, 0, b.Width, b.Height);
        var d = b.LockBits(r, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var px = new byte[d.Stride * b.Height];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        b.UnlockBits(d);
        int l = b.Width, t = b.Height, rr = -1, bo = -1;
        for (int y = 0; y < b.Height; y++)
            for (int x = 0; x < b.Width; x++)
                if (px[y * d.Stride + x * 4 + 3] > 10)
                {
                    if (x < l) l = x; if (x > rr) rr = x;
                    if (y < t) t = y; if (y > bo) bo = y;
                }
        return rr < 0 ? r : Rectangle.FromLTRB(l, t, rr + 1, bo + 1);
    }

    static Bitmap Ampliar(Bitmap b, int k)
    {
        var o = new Bitmap(b.Width * k, b.Height * k, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(o))
        {
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            g.DrawImage(b, new Rectangle(0, 0, o.Width, o.Height), 0, 0, b.Width, b.Height, GraphicsUnit.Pixel);
        }
        return o;
    }

    // fundo escuro com um brilho quente atrás do personagem e a sombra no chão
    static Bitmap ComFundo(Bitmap fig, int W, int H)
    {
        var o = new Bitmap(W, H, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(o))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using (var br = new LinearGradientBrush(new Rectangle(0, 0, W, H), Color.FromArgb(26, 18, 26), Color.FromArgb(10, 8, 12), 90f))
                g.FillRectangle(br, 0, 0, W, H);
            using (var path = new GraphicsPath())
            {
                path.AddEllipse(W * 0.12f, H * 0.08f, W * 0.76f, H * 0.84f);
                using (var pg = new PathGradientBrush(path))
                {
                    pg.CenterColor = Color.FromArgb(120, 120, 40, 34);
                    pg.SurroundColors = new[] { Color.FromArgb(0, 120, 40, 34) };
                    g.FillPath(pg, path);
                }
            }
            int pe = H - 90;
            using (var path = new GraphicsPath())
            {
                path.AddEllipse(W / 2f - fig.Width * 0.42f, pe - 16, fig.Width * 0.84f, 34);
                using (var pg = new PathGradientBrush(path))
                {
                    pg.CenterColor = Color.FromArgb(150, 0, 0, 0);
                    pg.SurroundColors = new[] { Color.FromArgb(0, 0, 0, 0) };
                    g.FillPath(pg, path);
                }
            }
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.DrawImage(fig, (W - fig.Width) / 2, pe - fig.Height);
        }
        return o;
    }

    // um personagem: [arquivo, sprite, quadro, cor (ou vazio), escudo?]
    static Bitmap Montar(string spr, int quadro, Color? cor, bool escudo)
    {
        var b = Quadro(spr, quadro);
        if (cor.HasValue) Tingir(b, cor.Value);
        if (!escudo) return b;
        // BESTA ESCUDEIRA: o escudo de ferro na frente do corpo (obj_inimigo_03):
        // (+18, -38) do pé, escala 1,25, no mundo; a besta é HD (k = 3)
        int k = 3;
        var esc = Quadro("spr_escudo", 0);
        int xo = Num("spr_inimigo01_parado", "xorigin"), yo = Num("spr_inimigo01_parado", "yorigin");
        int exo = Num("spr_escudo", "xorigin"), eyo = Num("spr_escudo", "yorigin");
        float s = 1.25f * k;
        float ex = xo + 18 * k - exo * s, ey = yo - 38 * k - eyo * s;
        var o = new Bitmap(Math.Max(b.Width, (int)(ex + esc.Width * s) + 2), b.Height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(o))
        {
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            g.DrawImage(b, 0, 0, b.Width, b.Height);
            g.DrawImage(esc, new RectangleF(ex, ey, esc.Width * s, esc.Height * s), new RectangleF(0, 0, esc.Width, esc.Height), GraphicsUnit.Pixel);
        }
        return o;
    }

    // painel com peças do cenário lado a lado, na MESMA escala (proporções reais),
    // apoiadas numa linha de chão, com o nome embaixo de cada uma
    public static void Painel(string raizProjeto, string arquivo, string[] sprites, string[] nomes, int k)
    {
        raiz = raizProjeto;
        var pecas = new List<Bitmap>();
        int largura = 0, altura = 0;
        foreach (var s in sprites)
        {
            var b = Quadro(s, 0);
            var c = b.Clone(Caixa(b), PixelFormat.Format32bppArgb);
            b.Dispose();
            var a = Ampliar(c, k);
            c.Dispose();
            pecas.Add(a);
            largura += a.Width;
            altura = Math.Max(altura, a.Height);
        }
        int gap = 120, W = Math.Max(1600, largura + gap * (pecas.Count + 1)), H = Math.Max(800, altura + 320);
        using (var o = new Bitmap(W, H, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(o))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
            using (var br = new LinearGradientBrush(new Rectangle(0, 0, W, H), Color.FromArgb(26, 18, 26), Color.FromArgb(10, 8, 12), 90f))
                g.FillRectangle(br, 0, 0, W, H);
            int chao = H - 170;
            using (var p = new Pen(Color.FromArgb(70, 200, 160, 120), 3)) g.DrawLine(p, 60, chao + 2, W - 60, chao + 2);
            int x = (W - largura - gap * (pecas.Count - 1)) / 2;
            using (var fonte = new Font("Georgia", 34, FontStyle.Bold, GraphicsUnit.Pixel))
            using (var corTxt = new SolidBrush(Color.FromArgb(236, 200, 140)))
            {
                var fmt = new StringFormat { Alignment = StringAlignment.Center };
                for (int i = 0; i < pecas.Count; i++)
                {
                    var a = pecas[i];
                    g.InterpolationMode = InterpolationMode.NearestNeighbor;
                    g.PixelOffsetMode = PixelOffsetMode.Half;
                    g.DrawImage(a, x, chao - a.Height);
                    g.DrawString(nomes[i], fonte, corTxt, new RectangleF(x - 80, chao + 40, a.Width + 160, 60), fmt);
                    x += a.Width + gap;
                }
            }
            o.Save(arquivo, ImageFormat.Png);
        }
        foreach (var a in pecas) a.Dispose();
    }

    public static string Rodar(string raizProjeto, string saida)
    {
        raiz = raizProjeto;
        Directory.CreateDirectory(saida);
        var transp = Path.Combine(saida, "fundo transparente");
        Directory.CreateDirectory(transp);
        var lista = new object[][] {
            new object[] { "Figura 01 - Twilight Vetrus", "spr_player_parado", 0, null, false },
            new object[] { "Figura 02 - Besta", "spr_inimigo01_parado", 0, null, false },
            new object[] { "Figura 03 - Esqueleto Guerreiro", "spr_esqueleto_parado", 0, null, false },
            new object[] { "Figura 04 - Arqueiro Esqueleto", "spr_inimigo02_parado", 0, null, false },
            new object[] { "Figura 05 - Besta Escudeira", "spr_inimigo01_parado", 0, Color.FromArgb(165, 175, 190), true },
            new object[] { "Figura 06 - Mulher-Aranha", "spr_aranha_parada", 0, null, false },
            new object[] { "Figura 07 - Estatua Enfeiticada", "spr_estatua", 2, null, false },      // olhos acesos e a aura do feitiço
            new object[] { "Figura 08 - Mini-boss O Carrasco de Vallack", "spr_inimigo01_parado", 0, Color.FromArgb(175, 125, 140), false },
            new object[] { "Figura 09 - Homem-Porco (Porco Corrompido)", "spr_porco_parado", 1, null, false },   // espada e escudo à vista
            new object[] { "Figura 10 - Boss Arvore Amaldicoada", "spr_boss_01_parado", 0, null, false },
        };
        var log = new System.Text.StringBuilder();
        foreach (var it in lista)
        {
            string nome = (string)it[0];
            var cor = it[3] == null ? (Color?)null : (Color)it[3];
            using (var b = Montar((string)it[1], (int)it[2], cor, (bool)it[4]))
            {
                var cx = Caixa(b);
                using (var corte = b.Clone(cx, PixelFormat.Format32bppArgb))
                {
                    int k = Math.Max(1, Math.Min(1050 / corte.Height, 1300 / corte.Width));
                    using (var grande = Ampliar(corte, k))
                    {
                        grande.Save(Path.Combine(transp, nome + ".png"), ImageFormat.Png);
                        using (var f = ComFundo(grande, 1600, 1200))
                            f.Save(Path.Combine(saida, nome + ".png"), ImageFormat.Png);
                    }
                    log.AppendLine(nome + ": " + corte.Width + "x" + corte.Height + " x" + k);
                }
            }
        }
        // complemento: o retrato de Twilight (o busto da tela inicial, arte grande)
        var ret = Path.Combine(raiz, "datafiles", "heroi_retrato.png");
        if (File.Exists(ret))
        {
            using (var b = new Bitmap(ret))
            {
                var cx = Caixa(b);
                using (var corte = b.Clone(cx, PixelFormat.Format32bppArgb))
                {
                    int k = Math.Max(1, Math.Min(1050 / corte.Height, 1300 / corte.Width));
                    using (var grande = k > 1 ? Ampliar(corte, k) : new Bitmap(corte))
                    {
                        grande.Save(Path.Combine(transp, "Figura 01b - Twilight Vetrus (retrato).png"), ImageFormat.Png);
                        int W = Math.Max(1600, grande.Width + 200), H = Math.Max(1200, grande.Height + 150);
                        using (var f = ComFundo(grande, W, H))
                            f.Save(Path.Combine(saida, "Figura 01b - Twilight Vetrus (retrato).png"), ImageFormat.Png);
                    }
                    log.AppendLine("retrato: " + corte.Width + "x" + corte.Height + " x" + k);
                }
            }
        }
        return log.ToString();
    }
}
