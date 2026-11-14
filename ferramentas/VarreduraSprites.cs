// Varredura de sprites, quadros e máscaras: GameMaker (.yy + PNG) x Godot (sprites.json + PNG + DEF).
// Uso: ferramentas/varredura_sprites.ps1 (compila este arquivo com Add-Type e imprime o relatório).
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;

public static class VarreduraSprites
{
    class Gm
    {
        public string nome;
        public int w, h, xo, yo, bl, bt, br, bb, modo;
        public List<string> quadros = new List<string>();
    }

    static int Num(string yy, string campo)
    {
        var m = Regex.Match(yy, "\"" + campo + "\":(-?\\d+)");
        return m.Success ? int.Parse(m.Groups[1].Value) : int.MinValue;
    }

    // caixa dos pixels visíveis (alfa > 8); null = quadro vazio
    static int[] Opaco(Bitmap b)
    {
        var r = new Rectangle(0, 0, b.Width, b.Height);
        var d = b.LockBits(r, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var px = new byte[d.Stride * b.Height];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        b.UnlockBits(d);
        int l = int.MaxValue, t = int.MaxValue, rr = -1, bo = -1;
        for (int y = 0; y < b.Height; y++)
            for (int x = 0; x < b.Width; x++)
                if (px[y * d.Stride + x * 4 + 3] > 8)
                {
                    if (x < l) l = x; if (x > rr) rr = x;
                    if (y < t) t = y; if (y > bo) bo = y;
                }
        return rr < 0 ? null : new int[] { l, t, rr, bo };
    }

    public static string Rodar(string raiz)
    {
        var sb = new StringBuilder();
        var avisos = new SortedDictionary<string, List<string>>();
        Action<string, string> av = (cat, msg) =>
        {
            if (!avisos.ContainsKey(cat)) avisos[cat] = new List<string>();
            avisos[cat].Add(msg);
        };

        // ---------------- GameMaker ----------------
        var gms = new Dictionary<string, Gm>();
        foreach (var dir in Directory.GetDirectories(Path.Combine(raiz, "sprites")))
        {
            var nome = Path.GetFileName(dir);
            var arq = Path.Combine(dir, nome + ".yy");
            if (!File.Exists(arq)) { av("GM sem .yy", nome); continue; }
            var yy = File.ReadAllText(arq);
            var g = new Gm { nome = nome, w = Num(yy, "width"), h = Num(yy, "height"), xo = Num(yy, "xorigin"), yo = Num(yy, "yorigin"),
                bl = Num(yy, "bbox_left"), bt = Num(yy, "bbox_top"), br = Num(yy, "bbox_right"), bb = Num(yy, "bbox_bottom"), modo = Num(yy, "bboxMode") };
            var fr = yy.IndexOf("\"frames\":[");
            var fim = yy.IndexOf("],", fr);
            foreach (Match m in Regex.Matches(yy.Substring(fr, fim - fr), "\"\\$GMSpriteFrame\":\"v1\",\"%Name\":\"([0-9a-f-]+)\""))
                g.quadros.Add(m.Groups[1].Value);
            gms[nome] = g;

            if (g.quadros.Count == 0) av("GM sprite sem quadros", nome);
            if (g.bl < 0 || g.bt < 0 || g.br >= g.w || g.bb >= g.h || g.bl > g.br || g.bt > g.bb)
                av("GM máscara fora da imagem", nome + " bbox " + g.bl + "," + g.bt + "-" + g.br + "," + g.bb + " em " + g.w + "x" + g.h);
            int ul = int.MaxValue, ut = int.MaxValue, ur = -1, ub = -1, vazios = 0;
            for (int i = 0; i < g.quadros.Count; i++)
            {
                var png = Path.Combine(dir, g.quadros[i] + ".png");
                if (!File.Exists(png)) { av("GM quadro sem PNG", nome + " #" + i); continue; }
                using (var b = new Bitmap(png))
                {
                    if (b.Width != g.w || b.Height != g.h) av("GM quadro com tamanho errado", nome + " #" + i + " " + b.Width + "x" + b.Height + " (sprite " + g.w + "x" + g.h + ")");
                    var o = Opaco(b);
                    if (o == null) { vazios++; av("GM quadro vazio (transparente)", nome + " #" + i); continue; }
                    ul = Math.Min(ul, o[0]); ut = Math.Min(ut, o[1]); ur = Math.Max(ur, o[2]); ub = Math.Max(ub, o[3]);
                }
            }
            // máscara automática/total gravada x pixels reais (só sprites com arte, não as máscaras)
            if (ur >= 0 && !nome.StartsWith("spr_mascara") && nome != "spr_hitbox" && g.modo == 0)
            {
                int dif = Math.Max(Math.Max(Math.Abs(g.bl - ul), Math.Abs(g.bt - ut)), Math.Max(Math.Abs(g.br - ur), Math.Abs(g.bb - ub)));
                if (dif > 3) av("GM máscara automática desatualizada", nome + " gravada " + g.bl + "," + g.bt + "-" + g.br + "," + g.bb + " / arte " + ul + "," + ut + "-" + ur + "," + ub);
            }
            if (g.xo < -g.w || g.xo > 2 * g.w || g.yo < -g.h || g.yo > 2 * g.h) av("GM origem muito fora", nome + " " + g.xo + "," + g.yo);
        }

        // ---------------- Godot ----------------
        var gdRaiz = Path.Combine(raiz, "godot");
        var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        var dados = js.Deserialize<Dictionary<string, Dictionary<string, object>>>(File.ReadAllText(Path.Combine(gdRaiz, "assets", "data", "sprites.json")));
        Func<Dictionary<string, object>, string, double> D = (d, k) => d.ContainsKey(k) ? Convert.ToDouble(d[k]) : 0;
        var pastaGd = Path.Combine(gdRaiz, "assets", "sprites");
        foreach (var kv in dados)
        {
            var nome = kv.Key; var d = kv.Value;
            int n = (int)D(d, "n");
            var dir = Path.Combine(pastaGd, nome);
            if (!Directory.Exists(dir)) { av("Godot sem pasta de quadros", nome); continue; }
            var pngs = Directory.GetFiles(dir, "*.png");
            if (pngs.Length != n) av("Godot nº de quadros x sprites.json", nome + " pasta " + pngs.Length + " / json " + n);
            for (int i = 0; i < n; i++)
            {
                var p = Path.Combine(dir, i + ".png");
                if (!File.Exists(p)) { av("Godot quadro faltando", nome + " #" + i); continue; }
                if (!File.Exists(p + ".import")) av("Godot quadro não importado", nome + " #" + i);
                using (var b = new Bitmap(p))
                    if (Opaco(b) == null && !nome.StartsWith("spr_mascara") && nome != "spr_hitbox") av("Godot quadro vazio (transparente)", nome + " #" + i);
            }
            Gm g;
            if (!gms.TryGetValue(nome, out g)) { av("Godot sprite sem par no GM (só Android)", nome); continue; }
            double pad = 0;     // o json guarda medidas do GM; o "pad" é só a borda extra da textura
            if (g.quadros.Count != n) av("Quadros GM x Godot", nome + " GM " + g.quadros.Count + " / Godot " + n);
            if (Math.Abs(D(d, "w") - (g.w + 2 * pad)) > 0.5 || Math.Abs(D(d, "h") - (g.h + 2 * pad)) > 0.5)
                av("Tamanho GM x Godot", nome + " GM " + g.w + "x" + g.h + " / Godot " + D(d, "w") + "x" + D(d, "h") + " pad " + pad);
            if (Math.Abs(D(d, "xo") - (g.xo + pad)) > 0.5 || Math.Abs(D(d, "yo") - (g.yo + pad)) > 0.5)
                av("Origem GM x Godot", nome + " GM " + g.xo + "," + g.yo + " / Godot " + D(d, "xo") + "," + D(d, "yo") + " pad " + pad);
            if (Math.Abs(D(d, "bl") - (g.bl + pad)) > 0.5 || Math.Abs(D(d, "bt") - (g.bt + pad)) > 0.5 || Math.Abs(D(d, "br") - (g.br + pad)) > 0.5 || Math.Abs(D(d, "bb") - (g.bb + pad)) > 0.5)
                av("Máscara GM x Godot", nome + " GM " + g.bl + "," + g.bt + "-" + g.br + "," + g.bb + " / Godot " + D(d, "bl") + "," + D(d, "bt") + "-" + D(d, "br") + "," + D(d, "bb") + " pad " + pad);
        }
        foreach (var g in gms.Values)
            if (!dados.ContainsKey(g.nome)) av("GM sprite sem par no Godot", g.nome);

        // ---------------- objetos: sprite e máscara ----------------
        var gtxt = File.ReadAllText(Path.Combine(gdRaiz, "src", "core", "g.gd"));
        var def = new Dictionary<string, string[]>();
        foreach (Match m in Regex.Matches(gtxt, "\"(obj_\\w+)\": \\[\"(\\w*)\", \"(\\w*)\"\\]"))
            def[m.Groups[1].Value] = new[] { m.Groups[2].Value, m.Groups[3].Value };
        foreach (var dir in Directory.GetDirectories(Path.Combine(raiz, "objects")))
        {
            var o = Path.GetFileName(dir);
            var arq = Path.Combine(dir, o + ".yy");
            if (!File.Exists(arq)) continue;
            var yy = File.ReadAllText(arq);
            var ms = Regex.Match(yy, "\"spriteId\":\\{\\s*\"name\":\"(\\w+)\"");
            var mm = Regex.Match(yy, "\"spriteMaskId\":\\{\\s*\"name\":\"(\\w+)\"");
            string s = ms.Success ? ms.Groups[1].Value : "", k = mm.Success ? mm.Groups[1].Value : "";
            string[] gd;
            if (!def.TryGetValue(o, out gd)) { if (s != "" || k != "") av("Objeto do GM sem DEF no Godot", o + " (" + s + ", " + k + ")"); continue; }
            if (gd[0] != s) av("Sprite do objeto GM x Godot", o + " GM " + s + " / Godot " + gd[0]);
            if (gd[1] != k) av("Máscara do objeto GM x Godot", o + " GM '" + k + "' / Godot '" + gd[1] + "'");
            if (s != "" && !gms.ContainsKey(s)) av("Objeto com sprite inexistente", o + " " + s);
        }

        foreach (var kv in avisos)
        {
            sb.AppendLine("== " + kv.Key + " (" + kv.Value.Count + ")");
            foreach (var l in kv.Value.Take(40)) sb.AppendLine("   " + l);
            if (kv.Value.Count > 40) sb.AppendLine("   ... +" + (kv.Value.Count - 40));
        }
        sb.AppendLine("sprites GM: " + gms.Count + "  Godot: " + dados.Count + "  objetos DEF: " + def.Count);
        return sb.ToString();
    }
}
