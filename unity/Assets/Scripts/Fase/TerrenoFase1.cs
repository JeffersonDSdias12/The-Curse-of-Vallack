// =====================================================================
//  TerrenoFase1 — o chão da Vila em Chamas (porta de terreno_dados("Room1")
//  e de obj_terreno): rua em y 693 com dois abismos, escadarias de madeira de
//  8 px, a torre de vigia, passarelas e ilhas de mão única, lajes sólidas.
//  Monta as colisões no Mundo e desenha as peças (lit: o fogo as ilumina).
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class TerrenoFase1 : MonoBehaviour
{
    public static float CHAO => Fase.numero == 2 ? 682f : 693f;
    static readonly float[][] ABISMOS_1 = { new[] { 1350f, 1452f }, new[] { 4026f, 4122f } };
    static readonly float[][] ABISMOS_2 = { new[] { 1760f, 1880f }, new[] { 3380f, 3480f }, new[] { 3600f, 3722f } };
    public static float[][] ABISMOS => Fase.numero == 2 ? ABISMOS_2 : ABISMOS_1;
    // Fase 2 (Room2): lajes sólidas sobre os abismos e no salão
    static readonly float[][] PLATAFORMAS_2 = { new[] { 1792f, 1848f, 616f }, new[] { 2650f, 2750f, 594f }, new[] { 2790f, 2880f, 550f }, new[] { 3636f, 3690f, 620f } };
    // lajes sólidas de 16 px [x1, x2, y]
    static readonly float[][] PLATAFORMAS = { new[] { 1546f, 1632f, 605f }, new[] { 1700f, 1776f, 585f }, new[] { 950f, 1250f, 470f }, new[] { 2120f, 2330f, 360f } };
    static readonly float[][] ESCADAS = { new[] { 318f, 406f, 605f }, new[] { 3442f, 3530f, 605f } };   // [x do chão, x do alto, y do alto]
    static readonly float[][] BLOCOS = { new[] { 3530f, 3594f, 605f } };
    // mão única: passarelas, ponte de corda e plataformas penduradas
    static readonly float[][] PONTES = { new[] { 402f, 700f, 605f }, new[] { 3594f, 3700f, 605f },
        new[] { 1316f, 1494f, 612f }, new[] { 2142f, 2212f, 590f }, new[] { 2246f, 2304f, 540f }, new[] { 4044f, 4104f, 608f } };
    // ilhas de terra flutuantes: [x do centro, y do topo, peça]
    static readonly object[][] ILHAS = { new object[] { 775f, 548f, "chao15" }, new object[] { 890f, 500f, "chao17" },
        new object[] { 1862f, 540f, "chao15" }, new object[] { 3762f, 585f, "chao15" }, new object[] { 3862f, 556f, "chao17" } };
    const float PECA_ESC = 0.7f;

    public Material materialLit;
    public Texture2D pecasTex;          // atlas pecas_fase1.png (ilhas)
    public TextAsset pecasJson;
    public int ordem = 60;

    void Awake()
    {
        Mundo.Limpar();
        if (Fase.numero == 2) { MontarFase2(); return; }
        // paredes do fim da sala (obj_chao girados no Room1)
        Mundo.Solido(-131f, -64f, 32.4f, 941f);
        Mundo.Solido(4960f, -32f, 5152f, 941f);
        // rua com os abismos abertos
        float x = 0f;
        foreach (var a in ABISMOS) { Mundo.Solido(x, CHAO, a[0], 801f); x = a[1]; }
        Mundo.Solido(x, CHAO, 5166f, 801f);

        foreach (var p in PLATAFORMAS)
        {
            Mundo.Solido(p[0], p[2], p[1], p[2] + 16f);
            Laje(p[0], p[1], p[2]);
        }
        foreach (var e in ESCADAS) Escada(e[0], e[1], e[2]);
        foreach (var b in BLOCOS)
        {
            Mundo.Solido(b[0], b[2], b[1], CHAO);
            Tabuas(b[0], b[2], b[1], CHAO, 0.85f);
        }
        foreach (var p in PONTES)
        {
            Mundo.MaoUnica(p[0], p[1], p[2]);
            Passarela(p[0], p[1], p[2]);
        }
        Ilhas();
        foreach (var a in ABISMOS) Abismo(a[0], a[1]);
    }

    // O SALÃO REAL EM RUÍNAS: piso em 682 com três abismos e lajes de pedra
    void MontarFase2()
    {
        Mundo.Solido(-131f, -64f, 32.4f, 941f);
        Mundo.Solido(4960f, -32f, 5152f, 941f);
        float x = 0f;
        foreach (var a in ABISMOS) { Mundo.Solido(x, CHAO, a[0], 801f); x = a[1]; }
        Mundo.Solido(x, CHAO, 5166f, 801f);
        foreach (var p in PLATAFORMAS_2)
        {
            Mundo.Solido(p[0], p[2], p[1], p[2] + 16f);
            Retangulo(p[0], p[2], p[1], p[2] + 16f, new Color32(92, 78, 86, 255), ordem);
            Retangulo(p[0], p[2], p[1], p[2] + 3f, new Color32(140, 120, 128, 255), ordem + 1);
        }
        foreach (var a in ABISMOS) Abismo(a[0], a[1]);
    }

    // degraus de 8 px do chão (xa) até y_alto (xb), como terreno_escada
    void Escada(float xa, float xb, float yAlto)
    {
        int n = Mathf.Max(1, Mathf.RoundToInt((CHAO - yAlto) / 8f));
        float lw = Mathf.Abs(xb - xa) / n;
        for (int k = 0; k < n; k++)
        {
            float x1 = xb > xa ? xa + k * lw : xa - (k + 1) * lw;
            float topo = CHAO - (k + 1) * 8f;
            Mundo.Solido(x1, topo, x1 + lw, CHAO);
            Tabuas(x1, topo, x1 + lw, CHAO, 0.7f + 0.3f * k / n);
        }
    }

    void Laje(float x1, float x2, float y)
    {
        // andaime: dois postes até o chão e as tábuas por cima
        foreach (float px in new[] { x1 + 8f, x2 - 8f })
            Retangulo(px - 3f, y + 16f, px + 3f, CHAO, new Color32(84, 56, 34, 255), ordem - 2);
        Tabuas(x1, y, x2, y + 16f, 1f);
    }

    void Passarela(float x1, float x2, float y)
    {
        for (float px = x1 + 10f; px < x2; px += 96f)
            Retangulo(px - 3f, y + 8f, px + 3f, CHAO, new Color32(84, 56, 34, 255), ordem - 2);
        Retangulo(x1 + 3f, y + 5f, x2 + 3f, y + 13f, new Color(0, 0, 0, 0.35f), ordem - 1);   // sombra
        Tabuas(x1, y, x2, y + 8f, 1f);
    }

    void Ilhas()
    {
        Dictionary<string, object> pecas = null;
        if (pecasJson != null) pecas = MiniJson.D(MiniJson.D(MiniJson.Ler(pecasJson.text))["pecas"]);
        for (int i = 0; i < ILHAS.Length; i++)
        {
            float cx = (float)ILHAS[i][0], topo = (float)ILHAS[i][1];
            string nome = (string)ILHAS[i][2];
            float lw = 60f;
            List<object> pc = null;
            if (pecas != null && pecas.TryGetValue(nome, out var o)) { pc = MiniJson.L(o); lw = MiniJson.F(pc[2]) * PECA_ESC * 0.78f; }
            Mundo.MaoUnica(cx - lw / 2f, cx + lw / 2f, topo);
            if (pc == null || pecasTex == null) { Tabuas(cx - lw / 2f, topo, cx + lw / 2f, topo + 10f, 1f); continue; }
            float px = MiniJson.F(pc[0]), py = MiniJson.F(pc[1]), pw = MiniJson.F(pc[2]), ph = MiniJson.F(pc[3]);
            var spr = Sprite.Create(pecasTex, new Rect(px, pecasTex.height - py - ph, pw, ph), Vector2.zero, 1f, 0, SpriteMeshType.FullRect);
            float w = pw * PECA_ESC, h = ph * PECA_ESC;
            float baseY = topo - h * 0.1f + h;
            bool esp = i % 2 == 1;
            var go = Novo("ilha " + nome, spr, ordem);
            go.transform.position = Mundo.Tela(esp ? cx + w / 2f : cx - w / 2f, baseY);
            go.transform.localScale = new Vector3(esp ? -PECA_ESC : PECA_ESC, PECA_ESC, 1f);
        }
    }

    void Abismo(float x1, float x2)
    {
        // a terra some numa garganta escura (o fundo vira breu)
        Retangulo(x1, CHAO - 1f, x2, Mundo.SALA_H + 80f, new Color32(16, 9, 12, 255), ordem + 1);
        Retangulo(x1, CHAO + 30f, x2, Mundo.SALA_H + 80f, new Color32(4, 2, 4, 255), ordem + 1);
    }

    // ---------------------------------------------------------------
    void Tabuas(float x1, float y1, float x2, float y2, float tom)
    {
        var go = Novo("tabuas", Texturas.Madeira(), ordem);
        var sr = go.GetComponent<SpriteRenderer>();
        sr.drawMode = SpriteDrawMode.Tiled;
        sr.size = new Vector2(x2 - x1, y2 - y1);
        sr.color = new Color(tom, tom, tom, 1f);
        go.transform.position = Mundo.Tela(x1, y2);
    }

    void Retangulo(float x1, float y1, float x2, float y2, Color c, int ord)
    {
        var go = Novo("ret", Texturas.Branco(), ord);
        go.GetComponent<SpriteRenderer>().color = c;
        go.transform.position = Mundo.Tela(x1, y2);
        go.transform.localScale = new Vector3(x2 - x1, y2 - y1, 1f);
    }

    GameObject Novo(string nome, Sprite s, int ord)
    {
        var go = new GameObject(nome);
        go.transform.SetParent(transform, false);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = s;
        sr.sortingOrder = ord;
        if (materialLit != null) sr.sharedMaterial = materialLit;
        return go;
    }
}
