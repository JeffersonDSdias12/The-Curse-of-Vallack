// =====================================================================
//  Hud — retrato do Twilight, nome, barra de vida (com o rastro branco que
//  desce atrasado), barra de MAGIA dos especiais, barra de FÚRIA, orbs,
//  essência, o contador de golpes e os avisos do herói ("MAGIA INSUFICIENTE").
// =====================================================================
using UnityEngine;
using UnityEngine.UI;

public class Hud : MonoBehaviour
{
    public Jogador jogador;
    public Sprite retrato, branco;
    RectTransform vidaBarra, atrasoBarra, magiaBarra, furiaBarra;
    Image furiaImg;
    Text recursos, combo, aviso;
    Canvas cv;
    float atraso = 1f, comboPulso;
    int comboVisto;
    Font fonte;

    // barra grande do chefe, embaixo da tela
    static Inimigo chefe; static string chefeNome = "", chefeTitulo = "";
    RectTransform chefeFundo, chefeVida, chefeAtraso; Text chefeTxt; float chefeAtrasoF = 1f, chefeAlfa;
    public static void MostrarChefe(Inimigo e, string nome, string titulo) { chefe = e; chefeNome = nome; chefeTitulo = titulo; }
    public static void EsconderChefe(Inimigo e) { if (chefe == e) chefe = null; }

    void Start()
    {
        chefe = null;
        if (branco == null) branco = Texturas.Branco();
        fonte = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        cv = new GameObject("HUD").AddComponent<Canvas>();
        cv.renderMode = RenderMode.ScreenSpaceOverlay;
        cv.sortingOrder = 40;
        float u = Screen.height / 280f;          // 1 px do jogo original na tela

        var ret = Caixa("retrato", retrato, Color.white, new Vector2(10, -8) * u, new Vector2(34, 34) * u);
        ret.GetComponent<Image>().preserveAspect = true;
        var nome = Texto("nome", 7, new Color(0.95f, 0.88f, 0.75f), TextAnchor.UpperLeft, new Vector2(0, 1), new Vector2(48, -8) * u, new Vector2(160, 10) * u);
        nome.text = "TWILIGHT VETRUS";

        Caixa("moldura", branco, new Color(0.08f, 0.05f, 0.07f, 0.85f), new Vector2(47, -19) * u, new Vector2(104, 8) * u);
        atrasoBarra = Caixa("atraso", branco, new Color(1f, 0.95f, 0.9f, 0.8f), new Vector2(49, -21) * u, new Vector2(100, 4) * u);
        vidaBarra = Caixa("vida", branco, new Color(0.78f, 0.12f, 0.16f), new Vector2(49, -21) * u, new Vector2(100, 4) * u);
        Caixa("moldura magia", branco, new Color(0.08f, 0.05f, 0.07f, 0.85f), new Vector2(47, -29) * u, new Vector2(74, 5) * u);
        magiaBarra = Caixa("magia", branco, new Color(0.35f, 0.6f, 1f), new Vector2(48, -30) * u, new Vector2(72, 3) * u);
        Caixa("moldura fúria", branco, new Color(0.08f, 0.05f, 0.07f, 0.85f), new Vector2(47, -36) * u, new Vector2(74, 5) * u);
        furiaBarra = Caixa("fúria", branco, new Color(1f, 0.45f, 0.15f), new Vector2(48, -37) * u, new Vector2(72, 3) * u);
        furiaImg = furiaBarra.GetComponent<Image>();

        recursos = Texto("recursos", 6.5f, new Color(1f, 0.9f, 0.8f), TextAnchor.UpperLeft, new Vector2(0, 1), new Vector2(10, -45) * u, new Vector2(200, 9) * u);
        combo = Texto("combo", 17, Color.white, TextAnchor.MiddleRight, new Vector2(1, 1), new Vector2(-18, -44) * u, new Vector2(170, 24) * u);
        combo.fontStyle = FontStyle.BoldAndItalic;
        combo.gameObject.AddComponent<Outline>().effectColor = new Color(0.2f, 0.02f, 0.05f, 0.9f);
        aviso = Texto("aviso", 7, new Color(1f, 0.82f, 0.6f), TextAnchor.MiddleCenter, new Vector2(0.5f, 0), new Vector2(0, 26) * u, new Vector2(280, 12) * u);
        aviso.gameObject.AddComponent<Outline>().effectColor = new Color(0, 0, 0, 0.9f);

        chefeFundo = Caixa("chefe fundo", branco, new Color(0.08f, 0.04f, 0.06f, 0.9f), Vector2.zero, new Vector2(204, 8) * u);
        chefeAtraso = Caixa("chefe atraso", branco, new Color(1f, 0.95f, 0.9f, 0.85f), Vector2.zero, new Vector2(200, 4) * u);
        chefeVida = Caixa("chefe vida", branco, new Color(0.72f, 0.1f, 0.5f), Vector2.zero, new Vector2(200, 4) * u);
        foreach (var rt in new[] { chefeFundo, chefeAtraso, chefeVida })
        {
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0); rt.pivot = new Vector2(0, 0.5f);
            rt.anchoredPosition = new Vector2(rt == chefeFundo ? -102 : -100, 12) * u;
        }
        chefeTxt = Texto("chefe nome", 7, new Color(1f, 0.85f, 0.7f), TextAnchor.MiddleCenter, new Vector2(0.5f, 0), new Vector2(0, 21) * u, new Vector2(260, 10) * u);
        chefeTxt.gameObject.AddComponent<Outline>().effectColor = new Color(0, 0, 0, 0.9f);
    }

    RectTransform Caixa(string nome, Sprite s, Color c, Vector2 pos, Vector2 tam)
    {
        var go = new GameObject(nome, typeof(RectTransform), typeof(Image));
        go.transform.SetParent(cv.transform, false);
        var img = go.GetComponent<Image>();
        img.sprite = s; img.color = c; img.raycastTarget = false;
        var rt = (RectTransform)go.transform;
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0, 1);
        rt.anchoredPosition = pos; rt.sizeDelta = tam;
        return rt;
    }

    Text Texto(string nome, float tam, Color c, TextAnchor alinhar, Vector2 ancora, Vector2 pos, Vector2 caixa)
    {
        var go = new GameObject(nome, typeof(RectTransform), typeof(Text));
        go.transform.SetParent(cv.transform, false);
        var t = go.GetComponent<Text>();
        t.font = fonte; t.fontSize = Mathf.RoundToInt(tam * Screen.height / 280f); t.fontStyle = FontStyle.Bold;
        t.color = c; t.alignment = alinhar; t.raycastTarget = false;
        t.horizontalOverflow = HorizontalWrapMode.Overflow; t.verticalOverflow = VerticalWrapMode.Overflow;
        var rt = (RectTransform)go.transform;
        rt.anchorMin = rt.anchorMax = rt.pivot = ancora;
        rt.anchoredPosition = pos; rt.sizeDelta = caixa;
        return t;
    }

    void Update()
    {
        if (jogador == null || vidaBarra == null) return;
        cv.enabled = !Telas.Bloqueia;
        float f = Mathf.Clamp01(jogador.vida / jogador.vidaMax);
        atraso = Mathf.MoveTowards(atraso, f, Time.deltaTime * (atraso > f ? 0.5f : 5f));
        vidaBarra.localScale = new Vector3(f, 1, 1);
        atrasoBarra.localScale = new Vector3(atraso, 1, 1);
        magiaBarra.localScale = new Vector3(Mathf.Clamp01(jogador.especialCarga / Jogo.ESPECIAL_SEGUNDOS), 1, 1);
        furiaBarra.localScale = new Vector3(Mathf.Clamp01(jogador.furia / 100f), 1, 1);
        bool cheia = jogador.furia >= 100 || jogador.furiaModo;
        furiaImg.color = cheia ? Color.Lerp(new Color(1f, 0.2f, 0.1f), new Color(1f, 0.9f, 0.5f), 0.5f + 0.5f * Mathf.Sin(Time.unscaledTime * 12f)) : new Color(1f, 0.45f, 0.15f);
        recursos.text = $"ORBS {Jogo.orbs}     ESSÊNCIA {Jogo.essencia}/{Jogo.ESSENCIA_MAX}     LÂMINA NV {Jogo.espadaNivel}" + (Jogo.chavePortao ? "     CHAVE" : "");

        aviso.text = jogador.avisoT > 0 ? jogador.aviso : "";

        bool temChefe = chefe != null && !chefe.morrendo;
        chefeAlfa = Mathf.MoveTowards(chefeAlfa, temChefe ? 1f : 0f, Time.unscaledDeltaTime * 2f);
        chefeFundo.gameObject.SetActive(chefeAlfa > 0.01f); chefeVida.gameObject.SetActive(chefeAlfa > 0.01f);
        chefeAtraso.gameObject.SetActive(chefeAlfa > 0.01f); chefeTxt.enabled = chefeAlfa > 0.01f;
        if (temChefe)
        {
            float cf = Mathf.Clamp01(chefe.vida / chefe.vidaMax);
            chefeAtrasoF = Mathf.MoveTowards(chefeAtrasoF, cf, Time.deltaTime * (chefeAtrasoF > cf ? 0.25f : 3f));
            chefeVida.localScale = new Vector3(cf, 1, 1); chefeAtraso.localScale = new Vector3(chefeAtrasoF, 1, 1);
            chefeTxt.text = chefeNome + "  ·  " + chefeTitulo;
        }

        // contador de golpes seguidos, que "pula" a cada acerto
        if (Tempo.combo != comboVisto) { if (Tempo.combo > comboVisto) comboPulso = 1f; comboVisto = Tempo.combo; }
        comboPulso = Mathf.MoveTowards(comboPulso, 0, Time.unscaledDeltaTime * 6f);
        combo.enabled = Tempo.combo >= 2;
        if (combo.enabled)
        {
            combo.text = Tempo.combo + " GOLPES";
            combo.color = Color.Lerp(new Color(1f, 0.85f, 0.45f), Color.white, comboPulso);
            float s = 1f + 0.35f * comboPulso;
            combo.rectTransform.localScale = new Vector3(s, s, 1);
        }
    }
}
