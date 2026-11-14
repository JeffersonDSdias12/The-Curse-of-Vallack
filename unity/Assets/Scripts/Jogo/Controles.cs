// =====================================================================
//  Controles — toque, teclado e controle num estado só (Input System novo).
//  Toque: metade esquerda = analógico flutuante (nasce onde o dedo encosta).
//  À direita, em losango como num controle: PULO (embaixo), GOLPE (esquerda),
//  ESQUIVA (direita), DEFESA (em cima); ao lado FORTE e BOLA; em arco por
//  cima os três especiais (ONDA, QUEDA, TREMOR), a FÚRIA e o ITEM.
//  Teclado: setas/WASD · Espaço pula · J golpe · U forte · I bola · K defesa
//           L esquiva · 1 2 3 especiais · F fúria · E item
//  Controle: A pula · X golpe · Y forte · B bola · RB defesa · RT esquiva
//            LB + X/Y/B especiais · LT fúria · direcional ▲ = item
// =====================================================================
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

[DefaultExecutionOrder(-100)]
public class Controles : MonoBehaviour
{
    public static bool Esq, Dir, Cima, Baixo;
    public static bool PuloSegurado, PuloApertou, GolpeApertou, Defesa, DefesaApertou, EsquivaApertou;
    public static bool ForteApertou, BolaApertou, Esp1Apertou, Esp2Apertou, Esp3Apertou, FuriaApertou, InteragirApertou;
    public static bool QualquerApertou;        // avançar telas e diálogos
    public static bool visivel = true;         // as telas de menu escondem os botões

    public Sprite disco;

    const int PULO = 0, GOLPE = 1, ESQUIVA = 2, DEFESA = 3, FORTE = 4, BOLA = 5, ESP1 = 6, ESP2 = 7, ESP3 = 8, FURIA = 9, ITEM = 10, N = 11;
    static readonly string[] NOMES = { "PULO", "GOLPE", "ESQUIVA", "DEFESA", "FORTE", "BOLA", "ONDA", "QUEDA", "TREMOR", "FÚRIA", "ITEM" };
    static readonly Color[] CORES = {
        new Color(0.75f, 0.85f, 1f), new Color(1f, 0.7f, 0.6f), new Color(0.7f, 1f, 0.8f), new Color(0.8f, 0.75f, 1f),
        new Color(1f, 0.8f, 0.5f), new Color(1f, 0.55f, 0.55f), new Color(1f, 0.45f, 0.6f), new Color(1f, 0.45f, 0.6f), new Color(1f, 0.45f, 0.6f),
        new Color(1f, 0.3f, 0.25f), new Color(0.6f, 0.85f, 1f) };
    readonly RectTransform[] botoes = new RectTransform[N];
    readonly Image[] imagens = new Image[N];
    readonly bool[] agora = new bool[N], antes = new bool[N];

    RectTransform baseAnalogico, pinoAnalogico;
    GameObject raiz;
    int dedoAnalogico = -1;
    Vector2 centroAnalogico;
    bool toqueVisivel;

    float R => Screen.height * 0.13f;
    float Raio(int i) => Screen.height * (i <= DEFESA ? 0.088f : (i <= BOLA ? 0.07f : 0.056f));

    Vector2 Pos(int i)
    {
        float h = Screen.height, w = Screen.width;
        var c = new Vector2(w - h * 0.3f, h * 0.3f);
        float d = h * 0.165f;
        switch (i)
        {
            case PULO: return c + new Vector2(0, -d);
            case GOLPE: return c + new Vector2(-d, 0);
            case ESQUIVA: return c + new Vector2(d, 0);
            case DEFESA: return c + new Vector2(0, d);
            case FORTE: return c + new Vector2(-d * 1.95f, d * 0.8f);
            case BOLA: return c + new Vector2(-d * 1.95f, -d * 0.6f);
            case ESP1: return c + new Vector2(-d * 1.15f, d * 1.8f);
            case ESP2: return c + new Vector2(0, d * 2.15f);
            case ESP3: return c + new Vector2(d * 1.15f, d * 1.8f);
            case FURIA: return new Vector2(w - h * 0.09f, h * 0.8f);
            default: return c + new Vector2(-d * 2.4f, d * 2.0f);
        }
    }

    void Awake()
    {
        toqueVisivel = Touchscreen.current != null || Application.isMobilePlatform;
        if (toqueVisivel) MontarUI();
    }

    void MontarUI()
    {
        if (disco == null) disco = Texturas.Disco();
        var cv = new GameObject("Controles de toque").AddComponent<Canvas>();
        raiz = cv.gameObject;
        cv.renderMode = RenderMode.ScreenSpaceOverlay;
        cv.sortingOrder = 50;
        baseAnalogico = Circulo(cv.transform, "analógico", new Color(1, 1, 1, 0.12f));
        pinoAnalogico = Circulo(baseAnalogico, "pino", new Color(1, 1, 1, 0.3f));
        for (int i = 0; i < N; i++)
        {
            botoes[i] = Circulo(cv.transform, NOMES[i], CORES[i]);
            imagens[i] = botoes[i].GetComponent<Image>();
            Rotulo(botoes[i], NOMES[i], i <= DEFESA ? 0.026f : 0.02f);
        }
        Posicionar();
    }

    RectTransform Circulo(Transform pai, string nome, Color c)
    {
        var go = new GameObject(nome, typeof(RectTransform), typeof(Image));
        go.transform.SetParent(pai, false);
        var img = go.GetComponent<Image>();
        img.sprite = disco; img.color = c; img.raycastTarget = false;
        var rt = (RectTransform)go.transform;
        rt.anchorMin = rt.anchorMax = Vector2.zero;
        return rt;
    }

    void Rotulo(RectTransform pai, string texto, float tam)
    {
        var go = new GameObject("rótulo", typeof(RectTransform), typeof(Text));
        go.transform.SetParent(pai, false);
        var t = go.GetComponent<Text>();
        t.text = texto;
        t.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        t.alignment = TextAnchor.MiddleCenter;
        t.color = new Color(1, 1, 1, 0.6f);
        t.fontStyle = FontStyle.Bold;
        t.raycastTarget = false;
        t.horizontalOverflow = HorizontalWrapMode.Overflow;
        var rt = (RectTransform)go.transform;
        rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one; rt.offsetMin = rt.offsetMax = Vector2.zero;
        t.fontSize = Mathf.RoundToInt(Screen.height * tam);
    }

    void Posicionar()
    {
        baseAnalogico.sizeDelta = Vector2.one * R * 2f;
        pinoAnalogico.sizeDelta = Vector2.one * R * 0.9f;
        pinoAnalogico.anchorMin = pinoAnalogico.anchorMax = new Vector2(0.5f, 0.5f);
        if (dedoAnalogico < 0) centroAnalogico = new Vector2(Screen.height * 0.24f, Screen.height * 0.24f);
        baseAnalogico.anchoredPosition = centroAnalogico;
        for (int i = 0; i < N; i++)
        {
            botoes[i].sizeDelta = Vector2.one * Raio(i) * 2f;
            botoes[i].anchoredPosition = Pos(i);
        }
    }

    void Update()
    {
        bool esq = false, dir = false, cima = false, baixo = false, qualquer = false;
        for (int i = 0; i < N; i++) agora[i] = false;

        var kb = Keyboard.current;
        if (kb != null)
        {
            esq |= kb.leftArrowKey.isPressed || kb.aKey.isPressed;
            dir |= kb.rightArrowKey.isPressed || kb.dKey.isPressed;
            cima |= kb.upArrowKey.isPressed || kb.wKey.isPressed;
            baixo |= kb.downArrowKey.isPressed || kb.sKey.isPressed;
            agora[PULO] |= kb.spaceKey.isPressed || kb.zKey.isPressed;
            agora[GOLPE] |= kb.jKey.isPressed || kb.xKey.isPressed;
            agora[FORTE] |= kb.uKey.isPressed;
            agora[BOLA] |= kb.iKey.isPressed;
            agora[DEFESA] |= kb.kKey.isPressed || kb.cKey.isPressed;
            agora[ESQUIVA] |= kb.lKey.isPressed || kb.leftShiftKey.isPressed;
            agora[ESP1] |= kb.digit1Key.isPressed; agora[ESP2] |= kb.digit2Key.isPressed; agora[ESP3] |= kb.digit3Key.isPressed;
            agora[FURIA] |= kb.fKey.isPressed;
            agora[ITEM] |= kb.eKey.isPressed;
            qualquer |= kb.enterKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame;
        }
        var gp = Gamepad.current;
        if (gp != null)
        {
            Vector2 st = gp.leftStick.ReadValue() + gp.dpad.ReadValue();
            esq |= st.x < -0.35f; dir |= st.x > 0.35f;
            cima |= gp.leftStick.ReadValue().y > 0.6f; baixo |= st.y < -0.6f;
            bool lb = gp.leftShoulder.isPressed;
            agora[PULO] |= gp.buttonSouth.isPressed;
            agora[GOLPE] |= !lb && gp.buttonWest.isPressed;
            agora[FORTE] |= !lb && gp.buttonNorth.isPressed;
            agora[BOLA] |= !lb && gp.buttonEast.isPressed;
            agora[ESP1] |= lb && gp.buttonWest.isPressed;
            agora[ESP2] |= lb && gp.buttonNorth.isPressed;
            agora[ESP3] |= lb && gp.buttonEast.isPressed;
            agora[DEFESA] |= gp.rightShoulder.isPressed;
            agora[ESQUIVA] |= gp.rightTrigger.isPressed;
            agora[FURIA] |= gp.leftTrigger.isPressed;
            agora[ITEM] |= gp.dpad.up.isPressed;
            qualquer |= gp.buttonSouth.wasPressedThisFrame || gp.startButton.wasPressedThisFrame;
        }

        var ts = Touchscreen.current;
        if (ts != null && toqueVisivel)
        {
            bool analogicoVivo = false;
            Vector2 pino = Vector2.zero;
            foreach (var t in ts.touches)
            {
                // um toque que encostou e soltou entre dois quadros ainda conta como aperto
                if (!t.press.isPressed && !t.press.wasPressedThisFrame) continue;
                if (t.press.wasPressedThisFrame) qualquer = true;
                if (!visivel) continue;
                int id = t.touchId.ReadValue();
                Vector2 p = t.position.ReadValue();
                if (id == dedoAnalogico) { analogicoVivo = true; pino = p - centroAnalogico; continue; }
                if (dedoAnalogico < 0 && t.press.wasPressedThisFrame && p.x < Screen.width * 0.4f)
                {
                    dedoAnalogico = id; centroAnalogico = p; analogicoVivo = true; pino = Vector2.zero;
                    continue;
                }
                if (p.x >= Screen.width * 0.4f)
                {
                    // o botão mais perto do dedo (com folga em volta)
                    int melhor = -1; float md = 1e9f;
                    for (int i = 0; i < N; i++)
                    {
                        float d = Vector2.Distance(p, Pos(i));
                        if (d < Raio(i) * 1.4f && d < md) { md = d; melhor = i; }
                    }
                    if (melhor >= 0) agora[melhor] = true;
                }
            }
            if (!analogicoVivo) dedoAnalogico = -1;
            else
            {
                // o centro segue o dedo quando ele passa da borda (analógico flutuante)
                if (pino.magnitude > R) { centroAnalogico += pino - pino.normalized * R; pino = pino.normalized * R; }
                esq |= pino.x < -R * 0.3f; dir |= pino.x > R * 0.3f;
                baixo |= pino.y < -R * 0.55f; cima |= pino.y > R * 0.6f;
            }
            if (raiz != null)
            {
                if (raiz.activeSelf != visivel) raiz.SetActive(visivel);
                if (visivel)
                {
                    Posicionar();
                    pinoAnalogico.anchoredPosition = pino;
                    for (int i = 0; i < N; i++)
                    {
                        var c = CORES[i]; c.a = agora[i] ? 0.5f : 0.2f;
                        // especiais ainda trancados e fúria vazia aparecem apagados
                        if (i >= ESP1 && i <= ESP3 && !Jogo.EspecialLiberado(i - ESP1 + 1)) c.a *= 0.35f;
                        if (i == FURIA && Jogador.eu != null && Jogador.eu.furia < 100 && !Jogador.eu.furiaModo) c.a *= 0.4f;
                        imagens[i].color = c;
                    }
                }
            }
        }

        Esq = esq; Dir = dir; Cima = cima; Baixo = baixo;
        PuloApertou = agora[PULO] && !antes[PULO];
        GolpeApertou = agora[GOLPE] && !antes[GOLPE];
        EsquivaApertou = agora[ESQUIVA] && !antes[ESQUIVA];
        DefesaApertou = agora[DEFESA] && !antes[DEFESA];
        ForteApertou = agora[FORTE] && !antes[FORTE];
        BolaApertou = agora[BOLA] && !antes[BOLA];
        Esp1Apertou = agora[ESP1] && !antes[ESP1];
        Esp2Apertou = agora[ESP2] && !antes[ESP2];
        Esp3Apertou = agora[ESP3] && !antes[ESP3];
        FuriaApertou = agora[FURIA] && !antes[FURIA];
        InteragirApertou = agora[ITEM] && !antes[ITEM];
        PuloSegurado = agora[PULO];
        Defesa = agora[DEFESA];
        QualquerApertou = qualquer;
        for (int i = 0; i < N; i++) antes[i] = agora[i];
    }
}
