// =====================================================================
//  Vila — a Vila em Chamas montada a partir do cenário da equipe
//  (cenario_fase1.png + cenario_fase1.json, o mesmo do obj_vila):
//  céu e lua, faixas distantes com paralaxe, quatro fileiras de casas
//  (as do fundo mais escuras), o incêndio preso a cada peça, as janelas
//  acesas, luzes 2D de verdade nas casas em chamas, o muro/cerca/sebe da
//  frente e o chão calçado (aberto nos abismos).
// =====================================================================
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class Vila : MonoBehaviour
{
    public TextAsset cenarioJson;
    public Texture2D cenarioTex;
    public Material lit, unlit, aditivo, alfa, fogo;
    public Texture2D casteloA, casteloB;      // Fase 2: a arte do Salão Real
    [Tooltip("0 = baixa, 1 = média, 2 = alta (fileiras do fundo com fogo, luzes)")]
    public int qualidade = 2;

    // ordens de desenho (sortingOrder)
    public const int O_CEU = -1000, O_NUVENS = -900, O_MONTANHAS = -800, O_FLORESTA = -700, O_LONGE = -600,
        O_FUMACA = -520, O_TERRA = -500, O_FRENTE = -20, O_CHAO = -10, O_BRASAS = 90;
    static int OrdemFileira(int plano) => -400 + (3 - plano) * 100;      // fileira 3 (fundo) = -400 ... 0 (frente) = -100

    static readonly Color32[] TOM = { new Color32(255, 255, 255, 255), new Color32(128, 116, 132, 255), new Color32(84, 74, 96, 255), new Color32(62, 54, 76, 255) };
    static readonly float[] FORCA = { 0.9f, 0.65f, 0.5f, 0.4f };

    Dictionary<string, object> pecas;
    readonly Dictionary<string, Sprite> sprites = new Dictionary<string, Sprite>();
    IncendioVila inc;
    int luzes;

    void Awake()
    {
        if (Fase.numero == 2)
        {
            gameObject.AddComponent<CenarioFase2>().Montar(casteloA, casteloB, lit, unlit, aditivo, alfa);
            return;
        }
        var cen = MiniJson.D(MiniJson.Ler(cenarioJson.text));
        pecas = MiniJson.D(cen["pecas"]);
        var layout = MiniJson.L(cen["layout"]);
        var cam = Camera.main;
        float viewH = cam.orthographicSize * 2f, viewW = viewH * cam.aspect;

        inc = gameObject.AddComponent<IncendioVila>();
        inc.aditivo = aditivo; inc.alfa = alfa; inc.fogoMat = fogo;

        Ceu(cam, viewW, viewH);
        NovaFaixa("nuvens", 0.06f, viewH * 0.28f, true, 7.2f, O_NUVENS, viewW);
        NovaFaixa("montanhas", 0.1f, 606f, false, 0, O_MONTANHAS, viewW);
        NovaFaixa("floresta", 0.3f, 652f, false, 0, O_FLORESTA, viewW);
        var longe = NovaFaixa("vila_longe", 0.55f, 672f, false, 0, O_LONGE, viewW);
        foreach (var o in MiniJson.L(MiniJson.D(pecas["vila_longe"])["fogos"]))
        {
            var f = MiniJson.L(o);
            float fx = MiniJson.F(f[0]), fy = MiniJson.F(f[1]), fw = MiniJson.F(f[2]);
            longe.Brilho(Texturas.Brilho(), aditivo, fx, fy - 1, fw * 1.8f, 12f, new Color(1f, 0.38f, 0.14f, 0.2f), O_LONGE + 1);
            longe.Brilho(Texturas.Brilho(), aditivo, fx, fy - 0.5f, fw * 0.8f, 5f, new Color(1f, 0.67f, 0.31f, 0.22f), O_LONGE + 2);
        }

        // terra escura atrás das casas (liga a vila ao longe ao chão)
        Retangulo(-2f, 641f, Mundo.SALA_W + 2f, 700f, new Color32(24, 26, 26, 255), O_TERRA, lit);

        var porPlano = new int[4];
        for (int i = 0; i < layout.Count; i++) Casa(MiniJson.L(layout[i]), i, porPlano);
        Frente();
        Chao();
        inc.Montar(Enumerable.Range(0, 4).Select(p => OrdemFileira(p) + 95).ToArray(), O_BRASAS, O_FUMACA);
        inc.qualidade = qualidade == 0 ? 0.5f : (qualidade == 1 ? 0.75f : 1f);
        Debug.Log($"[vila] {layout.Count} peças, {luzes} luzes 2D");
    }

    // ---------------------------------------------------------------
    void Casa(List<object> l, int i, int[] porPlano)
    {
        string nome = (string)l[0];
        if (!pecas.TryGetValue(nome, out var po)) return;
        var p = MiniJson.D(po);
        float x = MiniJson.F(l[1]), b = MiniJson.F(l[2]);
        int q = MiniJson.I(l[3]);
        bool esp = MiniJson.I(l[4]) == 1;
        int plano = l.Count > 5 ? MiniJson.I(l[5]) : 0;
        float s = l.Count > 6 ? MiniJson.F(l[6]) : 1f;
        float pw = MiniJson.F(p["w"]), ph = MiniJson.F(p["h"]);
        float w = pw * s, h = ph * s, y0 = b - h;
        if (plano >= 2 && qualidade == 0) return;          // nível baixo: sem as fileiras do fundo

        int ord = OrdemFileira(plano) + 1 + 2 * porPlano[plano]++;
        float Ax(float ax) => esp ? x + (pw - ax) * s : x + ax * s;

        if (nome == "ponte")
            Retangulo(x - 30f, b - 18f, x + w + 30f, b + 8f, new Color32(28, 38, 58, 255), ord - 1, lit);

        // a luz roxa da maldição sobe do telhado (atrás da casa)
        if (q == 1)
            inc.AdicionarBrilho(Glow(x + w * 0.5f, (y0 - 34f * s + y0 + h * 0.55f) / 2f, w * 1.3f, h * 0.55f + 34f * s,
                new Color(0.55f, 0.16f, 1f, 0.16f), ord - 1));

        var go = new GameObject(nome);
        go.transform.SetParent(transform, false);
        go.transform.position = Mundo.Tela(esp ? x + w : x, b);
        go.transform.localScale = new Vector3(esp ? -s : s, s, 1f);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = Peca(nome, p);
        sr.sortingOrder = ord;
        sr.sharedMaterial = lit;
        sr.color = TOM[Mathf.Clamp(plano, 0, 3)];

        // ruína fumegante: brasas no meio dos escombros
        var fogos = MiniJson.L(p["fogos"]);
        if (q == 2 && fogos.Count > 0)
        {
            var f = MiniJson.L(fogos[0]);
            float gw = MiniJson.F(f[2]) * s;
            inc.AdicionarBrilho(Glow(Ax(MiniJson.F(f[0])), y0 + MiniJson.F(f[1]) * s + s, gw * 1.2f, 14f * s,
                new Color(1f, 0.35f, 0.12f, plano > 0 ? 0.12f : 0.18f), ord, -0.01f));
        }
        // janelas acesas (roxo-alaranjado nas casas em chamas)
        foreach (var jo in MiniJson.L(p["janelas"]))
        {
            var j = MiniJson.L(jo);
            float jx0 = MiniJson.F(j[0]), jy = MiniJson.F(j[1]), jw = MiniJson.F(j[2]), jh = MiniJson.F(j[3]);
            float jx = esp ? x + (pw - jx0 - jw) * s : x + jx0 * s;
            var c = q == 1 ? new Color(0.86f, 0.43f, 1f, 0.5f) : new Color(1f, 0.67f, 0.27f, 0.3f);
            var r = Retangulo(jx - 2f * s, y0 + (jy - 2f) * s, jx + (jw + 1f) * s, y0 + (jy + jh + 1f) * s, c, ord, aditivo, -0.01f);
            inc.AdicionarBrilho(r);
        }
        // lampiões, lanternas e vitrais
        foreach (var lo in MiniJson.L(p["luzes"]))
        {
            var lz = MiniJson.L(lo);
            float lx = Ax(MiniJson.F(lz[0])), ly = y0 + MiniJson.F(lz[1]) * s, rr = MiniJson.F(lz[2]) * s;
            var cl = nome == "igreja" ? new Color(0.78f, 0.47f, 1f) : new Color(1f, 0.67f, 0.31f);
            inc.AdicionarBrilho(Glow(lx, ly, rr * 2f, rr * 2f, new Color(cl.r, cl.g, cl.b, 0.16f), ord, -0.01f));
            inc.AdicionarBrilho(Glow(lx, ly, rr, rr, new Color(cl.r, cl.g, cl.b, 0.3f), ord, -0.01f));
            if (plano <= 1 && qualidade >= 1) Luz(lx, ly, cl, plano == 0 ? 0.9f : 0.5f, rr * 3.2f);
        }
        // as chamas da maldição presas à construção
        if (q == 1 && plano <= qualidade + 1)
        {
            float forca = FORCA[Mathf.Clamp(plano, 0, 3)];
            var focos = MiniJson.L(p.TryGetValue("focos", out var fo) ? fo : null);
            if (focos.Count > 0)
            {
                foreach (var oo in focos)
                {
                    var f = MiniJson.L(oo);
                    int tipo = MiniJson.I(f[5]);
                    if (plano >= 2 && tipo == 2) continue;
                    var a = Mundo.Tela(Ax(MiniJson.F(f[0])), y0 + MiniJson.F(f[1]) * s);
                    var bb = Mundo.Tela(Ax(MiniJson.F(f[2])), y0 + MiniJson.F(f[3]) * s);
                    inc.AdicionarFoco(a, bb, MiniJson.F(f[4]) * s * (tipo == 1 ? 0.8f : 1f), forca, plano, tipo);
                }
            }
            else
            {
                foreach (var oo in fogos)
                {
                    var f = MiniJson.L(oo);
                    float fx = Ax(MiniJson.F(f[0])), fy = y0 + MiniJson.F(f[1]) * s, fw = MiniJson.F(f[2]) * s;
                    inc.AdicionarFoco(Mundo.Tela(fx - fw / 2f, fy), Mundo.Tela(fx + fw / 2f, fy), (22f + MiniJson.F(f[2]) * 0.25f) * s, forca, plano, 0);
                }
            }
            foreach (var co in MiniJson.L(p["chamines"]))
            {
                var c = MiniJson.L(co);
                if (plano <= 2) inc.AdicionarChamine(Mundo.Tela(Ax(MiniJson.F(c[0])), y0 + MiniJson.F(c[1]) * s));
            }
            // a casa em chamas ilumina a rua de verdade (luz 2D)
            if (plano <= 1 && qualidade >= 1)
            {
                var cor = i % 3 == 0 ? new Color(0.78f, 0.4f, 1f) : new Color(1f, 0.52f, 0.22f);
                Luz(x + w * 0.5f, y0 + h * 0.4f, cor, plano == 0 ? 1.25f : 0.75f, Mathf.Max(w, h) * 1.05f);
            }
        }
    }

    // muro de pedra, cerca e sebes alternados pela fase toda (base 680)
    void Frente()
    {
        float x = -40f; int k = 0;
        while (x < Mundo.SALA_W + 100f)
        {
            int hh = (k * 7919 + 13) % 10;
            string nome = hh < 4 ? "muro" : (hh < 7 ? "cerca" : "sebe");
            var p = MiniJson.D(pecas[nome]);
            float pw = MiniJson.F(p["w"]);
            if (!NoAbismo(x, x + pw)) Peca(nome, p, x, 680f, O_FRENTE, lit);
            x += pw - (nome == "sebe" ? 12f : 0f) + (hh == 9 ? 28f : 0f);
            k++;
        }
    }

    // chão calçado: um trecho por pedaço de rua (os abismos ficam abertos)
    void Chao()
    {
        var p = MiniJson.D(pecas["chao"]);
        float ph = MiniJson.F(p["h"]);
        var trechos = new List<(float, float)>();
        float x = -40f;
        foreach (var a in TerrenoFase1.ABISMOS) { trechos.Add((x, a[0])); x = a[1]; }
        trechos.Add((x, Mundo.SALA_W + 60f));
        foreach (var (x1, x2) in trechos)
        {
            var go = new GameObject("chão");
            go.transform.SetParent(transform, false);
            go.transform.position = Mundo.Tela(x1, 675f + ph);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = Peca("chao", p);
            sr.drawMode = SpriteDrawMode.Tiled;
            sr.size = new Vector2(x2 - x1, ph);
            sr.sortingOrder = O_CHAO;
            sr.sharedMaterial = lit;
        }
    }

    static bool NoAbismo(float x1, float x2)
    {
        foreach (var a in TerrenoFase1.ABISMOS) if (x2 > a[0] + 4 && x1 < a[1] - 4) return true;
        return false;
    }

    // céu e lua presos à câmera
    void Ceu(Camera cam, float viewW, float viewH)
    {
        var ceu = new GameObject("céu");
        ceu.transform.SetParent(cam.transform, false);
        ceu.transform.localPosition = new Vector3(0, 0, 20f);
        ceu.transform.localScale = new Vector3(viewW * 1.3f + 8f, (viewH + 8f) / 128f, 1f);
        var sr = ceu.AddComponent<SpriteRenderer>();
        sr.sprite = Texturas.Ceu(new Color32(24, 18, 36, 255), new Color32(76, 52, 76, 255), new Color32(146, 102, 106, 255));
        sr.sortingOrder = O_CEU; sr.sharedMaterial = unlit;

        var lua = new GameObject("lua");
        lua.transform.SetParent(cam.transform, false);
        lua.transform.localPosition = new Vector3(viewW * 0.26f, viewH * 0.35f, 19f);
        for (int k = 4; k >= 1; k--)
            Filho(lua.transform, Texturas.Brilho(), (11 + k * 9) * 2.4f, new Color(0.78f, 0.67f, 0.67f, 0.09f), O_CEU + 1, aditivo);
        Filho(lua.transform, Texturas.Disco(), 22f, new Color32(234, 224, 204, 255), O_CEU + 2, unlit);
        var m1 = Filho(lua.transform, Texturas.Disco(), 5f, new Color32(204, 192, 176, 255), O_CEU + 3, unlit); m1.localPosition = new Vector3(-3, 2, 0);
        var m2 = Filho(lua.transform, Texturas.Disco(), 4f, new Color32(204, 192, 176, 255), O_CEU + 3, unlit); m2.localPosition = new Vector3(4, -3, 0);
        var m3 = Filho(lua.transform, Texturas.Disco(), 3f, new Color32(204, 192, 176, 255), O_CEU + 3, unlit); m3.localPosition = new Vector3(1, 5, 0);
    }

    Transform Filho(Transform pai, Sprite s, float tam, Color c, int ord, Material m)
    {
        var go = new GameObject("parte");
        go.transform.SetParent(pai, false);
        go.transform.localScale = new Vector3(tam, tam, 1);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = s; sr.color = c; sr.sortingOrder = ord; sr.sharedMaterial = m;
        return go.transform;
    }

    Faixa NovaFaixa(string nome, float fx, float yb, bool yCam, float deriva, int ordem, float viewW)
    {
        var go = new GameObject("faixa " + nome);
        go.transform.SetParent(transform, false);
        var f = go.AddComponent<Faixa>();
        f.fx = fx; f.yBase = yb; f.yCamera = yCam; f.deriva = deriva;
        f.Montar(Peca(nome, MiniJson.D(pecas[nome])), ordem, unlit, Color.white, viewW);
        return f;
    }

    // ---------------------------------------------------------------
    Sprite Peca(string nome, Dictionary<string, object> p)
    {
        if (sprites.TryGetValue(nome, out var s)) return s;
        float px = MiniJson.F(p["x"]), py = MiniJson.F(p["y"]), pw = MiniJson.F(p["w"]), ph = MiniJson.F(p["h"]);
        s = Sprite.Create(cenarioTex, new Rect(px, cenarioTex.height - py - ph, pw, ph), Vector2.zero, 1f, 0, SpriteMeshType.FullRect);
        s.name = nome;
        sprites[nome] = s;
        return s;
    }

    void Peca(string nome, Dictionary<string, object> p, float x, float baseY, int ord, Material m)
    {
        var go = new GameObject(nome);
        go.transform.SetParent(transform, false);
        go.transform.position = Mundo.Tela(x, baseY);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = Peca(nome, p); sr.sortingOrder = ord; sr.sharedMaterial = m;
    }

    SpriteRenderer Glow(float cx, float cy, float w, float h, Color c, int ord, float z = 0.01f)
    {
        var go = new GameObject("brilho");
        go.transform.SetParent(transform, false);
        go.transform.position = Mundo.Tela(cx, cy, z);
        go.transform.localScale = new Vector3(w, h, 1);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = Texturas.Brilho(); sr.color = c; sr.sortingOrder = ord; sr.sharedMaterial = aditivo;
        return sr;
    }

    SpriteRenderer Retangulo(float x1, float y1, float x2, float y2, Color c, int ord, Material m, float z = 0f)
    {
        var go = new GameObject("ret");
        go.transform.SetParent(transform, false);
        go.transform.position = Mundo.Tela(x1, y2, z);
        go.transform.localScale = new Vector3(x2 - x1, y2 - y1, 1f);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = Texturas.Branco(); sr.color = c; sr.sortingOrder = ord; sr.sharedMaterial = m;
        return sr;
    }

    void Luz(float x, float y, Color c, float intensidade, float raio)
    {
        var go = new GameObject("luz");
        go.transform.SetParent(transform, false);
        go.transform.position = Mundo.Tela(x, y);
        var l = go.AddComponent<Light2D>();
        l.lightType = Light2D.LightType.Point;
        l.color = c;
        l.intensity = intensidade;
        l.pointLightOuterRadius = raio;
        l.pointLightInnerRadius = raio * 0.12f;
        l.falloffIntensity = 0.6f;
        LuzCamadas(l);
        go.AddComponent<TremularLuz>();
        luzes++;
    }

    // a luz criada por código não sabe em quais camadas brilhar: todas
    static FieldInfo campoCamadas;
    public static void LuzCamadas(Light2D l)
    {
        campoCamadas ??= typeof(Light2D).GetField("m_ApplyToSortingLayers", BindingFlags.NonPublic | BindingFlags.Instance);
        campoCamadas?.SetValue(l, SortingLayer.layers.Select(c => c.id).ToArray());
    }
}
