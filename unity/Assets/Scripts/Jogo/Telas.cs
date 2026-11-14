// =====================================================================
//  Telas — tudo que fica por cima do jogo: título, opções, pausa, evolução
//  da espada, fim de jogo, fase concluída e os avisos de tela.
//  Um Canvas só, montado por código. Toque/mouse apertam a opção; teclado
//  e controle andam com ▲▼ e confirmam com PULO/Enter.
//  Salvar — progresso em PlayerPrefs (orbs, essência, espada, checkpoint).
//  Musica — trilhas com troca suave (menu, fase, mini-chefe, chefe).
//  Qte — SEQUÊNCIA DE GOLPES dos chefes (obj_qte, como no God of War).
// =====================================================================
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public static class Salvar
{
    public static bool Existe => PlayerPrefs.GetInt("vallack_save", 0) == 1;

    public static void Gravar()
    {
        PlayerPrefs.SetInt("vallack_save", 1);
        PlayerPrefs.SetInt("orbs", Jogo.orbs);
        PlayerPrefs.SetInt("essencia", Jogo.essencia);
        PlayerPrefs.SetInt("espada", Jogo.espadaNivel);
        PlayerPrefs.SetInt("chave", Jogo.chavePortao ? 1 : 0);
        PlayerPrefs.SetInt("cp", Checkpoint.ativo ? 1 : 0);
        PlayerPrefs.SetFloat("cpx", Checkpoint.cx);
        PlayerPrefs.SetFloat("cpy", Checkpoint.cy);
        PlayerPrefs.SetInt("dificuldade", Dificuldade.nivel);
        PlayerPrefs.SetInt("fase", Fase.numero);
        PlayerPrefs.SetInt("cpfase", Checkpoint.fase);
        PlayerPrefs.Save();
    }

    public static void Carregar()
    {
        Jogo.orbs = PlayerPrefs.GetInt("orbs", 0);
        Jogo.essencia = PlayerPrefs.GetInt("essencia", 3);
        Jogo.espadaNivel = PlayerPrefs.GetInt("espada", 1);
        Jogo.chavePortao = PlayerPrefs.GetInt("chave", 0) == 1;
        Checkpoint.ativo = PlayerPrefs.GetInt("cp", 0) == 1;
        Checkpoint.cx = PlayerPrefs.GetFloat("cpx", 0);
        Checkpoint.cy = PlayerPrefs.GetFloat("cpy", 0);
        Dificuldade.nivel = PlayerPrefs.GetInt("dificuldade", 1);
        Fase.numero = PlayerPrefs.GetInt("fase", 1);
        Checkpoint.fase = PlayerPrefs.GetInt("cpfase", 1);
    }

    public static void Opcoes()
    {
        PlayerPrefs.SetFloat("vol_musica", Musica.volume);
        PlayerPrefs.SetFloat("vol_efeitos", Efeitos.volume);
        PlayerPrefs.SetInt("dificuldade", Dificuldade.nivel);
        PlayerPrefs.SetInt("fps", MedidorFps.mostrar ? 1 : 0);
        PlayerPrefs.Save();
    }
}

public class Musica : MonoBehaviour
{
    // as trilhas ficam em Resources/Musica e entram uma por vez, sob demanda: pré-carregar
    // as dez em streaming junto com a cena derrubava o jogo no celular
    public static float volume = 0.6f;
    static Musica eu;
    AudioSource a, b;
    string atual = "";

    void Awake()
    {
        eu = this;
        volume = PlayerPrefs.GetFloat("vol_musica", 0.6f);
        a = gameObject.AddComponent<AudioSource>(); b = gameObject.AddComponent<AudioSource>();
        a.loop = b.loop = true; a.volume = b.volume = 0; a.ignoreListenerPause = b.ignoreListenerPause = true;
    }

    public static void Tocar(string nome)
    {
        if (eu == null || eu.atual == nome) return;
        eu.atual = nome;
        var clip = nome == "" ? null : Resources.Load<AudioClip>("Musica/" + nome);
        var t = eu.a; eu.a = eu.b; eu.b = t;         // a = a que entra, b = a que sai
        var velha = eu.a.clip;
        eu.a.clip = clip;
        if (velha != null && velha != clip && velha != eu.b.clip) Resources.UnloadAsset(velha);
        if (clip != null) eu.a.Play();
    }

    void Update()
    {
        float dt = Time.unscaledDeltaTime;
        a.volume = Mathf.MoveTowards(a.volume, a.clip != null ? volume : 0, dt * 0.8f);
        b.volume = Mathf.MoveTowards(b.volume, 0, dt * 0.8f);
        if (b.volume <= 0 && b.isPlaying) b.Stop();
    }
}

[DefaultExecutionOrder(-150)]
public class Telas : MonoBehaviour
{
    public Sprite logo, avisoFiccao, mapa;
    public Sprite[] prologo;                       // cutscene_1.jpg ... (O Herói e o Dragão)
    public string videoEstudio = "";               // arquivo em StreamingAssets ("" = sem vídeo); tocado por endereço, nunca pré-carregado
    public static bool pularTitulo;
    static bool introVista;
    Image tela; RawImage telaVideo; UnityEngine.Video.VideoPlayer video;
    int pagina; float telaT, troca;
    static Telas eu;

    string estado = "jogo";
    public static bool EmMenu => eu != null && eu.estado != "jogo";
    public static bool Bloqueia => EmMenu || Dialogo.Ativo;
    public static bool FaseConcluida => eu != null && eu.estado == "resultado";

    Canvas cv;
    Image fundo, imgLogo;
    Text titulo, sub, avisoTxt, pausaBtn;
    readonly List<(RectTransform rt, Text txt, Action acao)> opcoes = new List<(RectTransform, Text, Action)>();
    int sel;
    float avisoT, tempoFase;
    Font fonte;
    float U => Screen.height / 280f;

    void Awake()
    {
        eu = this;
        ExtrasDeTeste();
        fonte = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        Dificuldade.nivel = PlayerPrefs.GetInt("dificuldade", 1);
        MedidorFps.mostrar = PlayerPrefs.GetInt("fps", 1) == 1;
        cv = new GameObject("Telas").AddComponent<Canvas>();
        cv.renderMode = RenderMode.ScreenSpaceOverlay; cv.sortingOrder = 100;
        fundo = Img(cv.transform, "fundo", new Color(0.03f, 0.01f, 0.04f, 0.78f));
        fundo.rectTransform.anchorMin = Vector2.zero; fundo.rectTransform.anchorMax = Vector2.one;
        fundo.rectTransform.offsetMin = fundo.rectTransform.offsetMax = Vector2.zero;
        tela = Img(cv.transform, "tela", Color.white);
        tela.rectTransform.anchorMin = Vector2.zero; tela.rectTransform.anchorMax = Vector2.one;
        tela.rectTransform.offsetMin = tela.rectTransform.offsetMax = Vector2.zero;
        tela.preserveAspect = true; tela.enabled = false;
        imgLogo = Img(cv.transform, "logo", Color.white);
        imgLogo.sprite = logo; imgLogo.preserveAspect = true;
        Ancorar(imgLogo.rectTransform, 0.5f, 0.74f, 150 * U, 80 * U);
        titulo = Txt(cv.transform, "título", 16, new Color(0.96f, 0.85f, 0.62f), TextAnchor.MiddleCenter);
        Ancorar(titulo.rectTransform, 0.5f, 0.8f, 260 * U, 24 * U);
        sub = Txt(cv.transform, "sub", 7, new Color(0.85f, 0.8f, 0.8f), TextAnchor.MiddleCenter);
        Ancorar(sub.rectTransform, 0.5f, 0.68f, 260 * U, 30 * U);
        avisoTxt = Txt(cv.transform, "aviso", 8, new Color(1f, 0.9f, 0.6f), TextAnchor.MiddleCenter);
        Ancorar(avisoTxt.rectTransform, 0.5f, 0.86f, 270 * U, 14 * U);
        avisoTxt.gameObject.AddComponent<Outline>().effectColor = new Color(0, 0, 0, 0.9f);
        pausaBtn = Txt(cv.transform, "pausa", 10, new Color(1, 1, 1, 0.55f), TextAnchor.MiddleCenter);
        pausaBtn.text = "II";
        Ancorar(pausaBtn.rectTransform, 0.965f, 0.93f, 16 * U, 16 * U);
    }

    // TESTE no aparelho: "--ei vallack_fase 2" abre na Fase 2; "--ei vallack_direto 1" pula abertura e título
    static bool extrasLidos;
    void ExtrasDeTeste()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        if (extrasLidos) return;
        extrasLidos = true;
        try
        {
            using (var up = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            using (var act = up.GetStatic<AndroidJavaObject>("currentActivity"))
            using (var intent = act.Call<AndroidJavaObject>("getIntent"))
            {
                int f = intent.Call<int>("getIntExtra", "vallack_fase", 0);
                if (f == 2) Fase.numero = 2;
                if (intent.Call<int>("getIntExtra", "vallack_direto", 0) == 1) { pularTitulo = true; introVista = true; }
                Debug.Log($"[teste] fase {Fase.numero} · direto {pularTitulo}");
            }
        }
        catch (System.Exception e) { Debug.Log("[teste] sem extras: " + e.Message); }
#endif
    }

    void Start()
    {
        if (pularTitulo) { pularTitulo = false; Jogar(); }
        else if (!introVista) Intro();
        else Titulo();
    }

    // ---------------------------------------------------------------
    Image Img(Transform pai, string nome, Color c)
    {
        var go = new GameObject(nome, typeof(RectTransform), typeof(Image));
        go.transform.SetParent(pai, false);
        var i = go.GetComponent<Image>(); i.color = c; i.raycastTarget = false;
        return i;
    }

    Text Txt(Transform pai, string nome, float tam, Color c, TextAnchor ancora)
    {
        var go = new GameObject(nome, typeof(RectTransform), typeof(Text));
        go.transform.SetParent(pai, false);
        var t = go.GetComponent<Text>();
        t.font = fonte; t.fontSize = Mathf.RoundToInt(tam * U); t.color = c; t.alignment = ancora; t.fontStyle = FontStyle.Bold;
        t.horizontalOverflow = HorizontalWrapMode.Overflow; t.verticalOverflow = VerticalWrapMode.Overflow; t.raycastTarget = false;
        return t;
    }

    static void Ancorar(RectTransform rt, float ax, float ay, float w, float h)
    {
        rt.anchorMin = rt.anchorMax = new Vector2(ax, ay); rt.pivot = new Vector2(0.5f, 0.5f);
        rt.anchoredPosition = Vector2.zero; rt.sizeDelta = new Vector2(w, h);
    }

    void Menu(string est, string tit, string subtitulo, bool comLogo, params (string, Action)[] itens)
    {
        estado = est;
        foreach (var o in opcoes) Destroy(o.rt.gameObject);
        opcoes.Clear();
        fundo.enabled = true; imgLogo.enabled = comLogo && logo != null; tela.enabled = false;
        fundo.color = new Color(0.03f, 0.01f, 0.04f, 0.78f);
        titulo.text = comLogo && logo != null ? "" : tit; sub.text = subtitulo;
        float y0 = 0.56f - (itens.Length > 4 ? 0.02f : 0f);
        for (int i = 0; i < itens.Length; i++)
        {
            var caixa = Img(cv.transform, "opção", new Color(1, 1, 1, 0.07f));
            Ancorar(caixa.rectTransform, 0.5f, y0 - i * 0.105f, 190 * U, 24 * U);
            var t = Txt(caixa.transform, "t", 9, Color.white, TextAnchor.MiddleCenter);
            t.rectTransform.anchorMin = Vector2.zero; t.rectTransform.anchorMax = Vector2.one;
            t.rectTransform.offsetMin = t.rectTransform.offsetMax = Vector2.zero;
            t.text = itens[i].Item1;
            opcoes.Add((caixa.rectTransform, t, itens[i].Item2));
        }
        sel = 0;
        Tempo.pausado = true;
        Controles.visivel = false;
    }

    void Jogar()
    {
        estado = "jogo";
        foreach (var o in opcoes) Destroy(o.rt.gameObject);
        opcoes.Clear();
        fundo.enabled = imgLogo.enabled = tela.enabled = false; titulo.text = sub.text = "";
        Tempo.pausado = false;
        Controles.visivel = true;
        Musica.Tocar(Arena.musica != "" ? Arena.musica : "mus_fase");
    }

    void Titulo()
    {
        Musica.Tocar("mus_menu");
        var itens = new List<(string, Action)> { ("NOVO JOGO", NovoJogo) };
        if (Salvar.Existe) itens.Insert(0, ("CONTINUAR", Continuar));
        itens.Add(("OPÇÕES", () => Opcoes(Titulo)));
        Menu("titulo", "THE CURSE OF VALLACK", "", true, itens.ToArray());
    }

    void NovoJogo()
    {
        Jogo.NovaPartida(); Checkpoint.ativo = false; Fase.numero = 1; Dialogo.Esquecer();
        PlayerPrefs.SetInt("vallack_save", 0);
        Prologo();
    }

    // ---------- telas de imagem: vídeo do estúdio, aviso, prólogo, pergaminho ----------
    void TelaCheia(string est, Sprite s)
    {
        estado = est; telaT = 0; troca = 0;
        foreach (var o in opcoes) Destroy(o.rt.gameObject);
        opcoes.Clear();
        fundo.enabled = true; fundo.color = Color.black;
        imgLogo.enabled = false; titulo.text = ""; sub.text = "";
        tela.enabled = s != null; tela.sprite = s; tela.color = new Color(1, 1, 1, 0);
        Tempo.pausado = true; Controles.visivel = false;
    }

    // abertura: o vídeo do estúdio e depois o aviso de obra de ficção
    void Intro()
    {
        introVista = true;
        if (string.IsNullOrEmpty(videoEstudio)) { Aviso1(); return; }
        TelaCheia("video", null);
        var go = new GameObject("vídeo do estúdio", typeof(RectTransform), typeof(RawImage));
        go.transform.SetParent(cv.transform, false);
        go.transform.SetSiblingIndex(tela.transform.GetSiblingIndex() + 1);
        telaVideo = go.GetComponent<RawImage>(); telaVideo.raycastTarget = false;
        var rt = telaVideo.rectTransform; rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = new Vector2(Screen.height * 16f / 9f, Screen.height);
        var rtex = new RenderTexture(1280, 720, 0);
        telaVideo.texture = rtex; telaVideo.color = Color.black;
        video = go.AddComponent<UnityEngine.Video.VideoPlayer>();
        video.playOnAwake = false; video.isLooping = false;
        video.source = UnityEngine.Video.VideoSource.Url;
        video.url = System.IO.Path.Combine(Application.streamingAssetsPath, videoEstudio);
        video.prepareCompleted += v =>
        {
            // ajusta a imagem à proporção real do vídeo
            if (telaVideo == null || v.height == 0) return;
            float asp = (float)v.width / v.height, h = Screen.height, w = Mathf.Min(Screen.width, h * asp);
            telaVideo.rectTransform.sizeDelta = new Vector2(w, w / asp);
        };
        video.renderMode = UnityEngine.Video.VideoRenderMode.RenderTexture; video.targetTexture = rtex;
        video.timeUpdateMode = UnityEngine.Video.VideoTimeUpdateMode.UnscaledGameTime;
        video.loopPointReached += _ => FimDoVideo();
        video.errorReceived += (_, __) => FimDoVideo();
        video.Play();
    }

    void FimDoVideo()
    {
        if (estado != "video") return;
        if (video != null) { video.Stop(); Destroy(video.gameObject); video = null; }
        Aviso1();
    }

    void Aviso1()
    {
        if (avisoFiccao == null) { Titulo(); return; }
        TelaCheia("aviso", avisoFiccao);
        Efeitos.Tocar("sfx_important_message", 0.6f, 0f);
    }

    // PRÓLOGO "O Herói e o Dragão": só no NOVO JOGO
    void Prologo()
    {
        if (prologo == null || prologo.Length == 0) { Pergaminho(); return; }
        pagina = 0;
        TelaCheia("prologo", prologo[0]);
        Musica.Tocar("mus_prologo");
        sub.text = "";
    }

    // pergaminho com os comandos antes de a fase começar
    void Pergaminho()
    {
        TelaCheia("pergaminho", null);
        Musica.Tocar("mus_carregamento");
        fundo.color = new Color(0.1f, 0.07f, 0.05f, 1f);
        titulo.text = "A LÂMINA DE SYLLA";
        sub.text = "GOLPE: toque até quatro vezes para o combo   ·   FORTE: salto do carrasco   ·   BOLA: rasteira e finalizador\n" +
                   "DEFESA: segure para bloquear, aperte na hora certa para APARAR   ·   ESQUIVA: role (com direção) ou recue\n" +
                   "ONDA / QUEDA / TREMOR: especiais da barra azul   ·   FÚRIA: com a barra vermelha cheia   ·   ITEM: baús e sub-armas\n\n" +
                   "TOQUE PARA COMEÇAR";
    }

    void PassoDeTela(bool apertou)
    {
        float dt = Time.unscaledDeltaTime;
        telaT += dt;
        switch (estado)
        {
            case "video":
                if (video != null && video.isPlaying) telaVideo.color = Color.white;
                // sem imagem depois de 4 s (aparelho sem suporte) ou toque: pula
                if ((apertou && telaT > 1f) || (telaT > 4f && (video == null || !video.isPlaying)) || telaT > 40f) FimDoVideo();
                break;
            case "aviso":
                tela.color = new Color(1, 1, 1, Mathf.Clamp01(Mathf.Min(telaT / 0.6f, (5f - telaT) / 0.6f)));
                if (telaT > 5f || (apertou && telaT > 1f)) Titulo();
                break;
            case "prologo":
                if (troca > 0)
                {
                    // escurece, troca a imagem e clareia
                    troca -= dt / 0.45f;
                    if (troca <= 0.5f && tela.sprite != prologo[pagina]) tela.sprite = prologo[pagina];
                    tela.color = new Color(1, 1, 1, Mathf.Abs(troca - 0.5f) * 2f);
                }
                else
                {
                    tela.color = new Color(1, 1, 1, Mathf.Clamp01(telaT / 0.8f));
                    sub.text = "";
                    if (apertou && telaT > 0.4f)
                    {
                        Efeitos.Tocar("cut_passar", 0.8f, 0.03f);
                        if (pagina < prologo.Length - 1) { pagina++; troca = 1f; telaT = 1f; }
                        else Pergaminho();
                    }
                }
                break;
            case "pergaminho":
                if (apertou && telaT > 0.6f) Recarregar();
                break;
        }
    }

    void Continuar() { Salvar.Carregar(); Recarregar(); }

    static void Recarregar()
    {
        pularTitulo = true;
        Tempo.pausado = false; Time.timeScale = 1f;
        Arena.Abrir();
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }

    void Pausa()
    {
        Efeitos.Tocar("sfx_menu_abrir", 0.6f, 0f);
        Menu("pausa", "PAUSA", $"ORBS {Jogo.orbs}   ·   ESSÊNCIA {Jogo.essencia}/{Jogo.ESSENCIA_MAX}   ·   LÂMINA DE SYLLA NÍVEL {Jogo.espadaNivel}", false,
            ("CONTINUAR", Jogar), ("EVOLUIR A ESPADA", Armas), ("OPÇÕES", () => Opcoes(Pausa)), ("MENU PRINCIPAL", () => { Salvar.Gravar(); pularTitulo = false; RecarregarTitulo(); }));
    }

    static void RecarregarTitulo()
    {
        Tempo.pausado = false; Time.timeScale = 1f; Arena.Abrir();
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }

    // EVOLUÇÃO DA LÂMINA DE SYLLA (obj_menu_armas): cada nível custa orbs
    void Armas()
    {
        int prox = Jogo.espadaNivel + 1;
        string[] ganho = { "", "", "ONDA CARMESIM  ·  +8% de dano", "COMBO QUEBRA-ESCUDO  ·  +16% de dano", "QUEDA CARMESIM  ·  +24% de dano", "COMBO RASTEIRA SANGRENTA  ·  +32% de dano  ·  fúria mais rápida" };
        if (prox > Jogo.ESPADA_NIVEL_MAX)
        {
            Menu("armas", "LÂMINA DE SYLLA", "NÍVEL MÁXIMO  ·  a lâmina não pode crescer mais", false, ("VOLTAR", Pausa));
            return;
        }
        int custo = Jogo.EspadaCusto(prox);
        Menu("armas", "LÂMINA DE SYLLA", $"NÍVEL {Jogo.espadaNivel}  →  {prox}:  {ganho[prox]}\nCUSTO {custo} ORBS   ·   VOCÊ TEM {Jogo.orbs}", false,
            (Jogo.orbs >= custo ? "EVOLUIR" : "ORBS INSUFICIENTES", () =>
            {
                if (Jogo.orbs < custo) { Efeitos.Tocar("sfx_negado", 0.7f, 0f); return; }
                Jogo.orbs -= custo; Jogo.espadaNivel = prox;
                Efeitos.Tocar("espada_evoluir", 0.9f, 0f);
                Salvar.Gravar();
                Armas();
            }), ("VOLTAR", Pausa));
    }

    void Opcoes(Action voltar)
    {
        string[] dif = { "FÁCIL", "MÉDIO", "DIFÍCIL", "EXTREMO" };
        Menu("opcoes", "OPÇÕES", "", false,
            ("DIFICULDADE:  " + dif[Mathf.Clamp(Dificuldade.nivel, 0, 3)], () => { Dificuldade.nivel = (Dificuldade.nivel + 1) % 4; Salvar.Opcoes(); Opcoes(voltar); }),
            ("MÚSICA:  " + Mathf.RoundToInt(Musica.volume * 100) + "%", () => { Musica.volume = Musica.volume >= 0.99f ? 0f : Mathf.Min(1f, Musica.volume + 0.2f); Salvar.Opcoes(); Opcoes(voltar); }),
            ("EFEITOS:  " + Mathf.RoundToInt(Efeitos.volume * 100) + "%", () => { Efeitos.volume = Efeitos.volume >= 0.99f ? 0f : Mathf.Min(1f, Efeitos.volume + 0.2f); Salvar.Opcoes(); Opcoes(voltar); }),
            ("MOSTRAR FPS:  " + (MedidorFps.mostrar ? "SIM" : "NÃO"), () => { MedidorFps.mostrar = !MedidorFps.mostrar; Salvar.Opcoes(); Opcoes(voltar); }),
            ("VOLTAR", voltar));
    }

    public static void FimDeJogo()
    {
        if (eu == null || eu.estado != "jogo") return;
        Musica.Tocar("");
        eu.Menu("morte", "VOCÊ CAIU", "A maldição de Vallack ainda pesa sobre o reino.", false,
            ("TENTAR DE NOVO", () => { Jogador.eu.Reviver(); eu.Jogar(); }), ("MENU PRINCIPAL", () => { pularTitulo = false; RecarregarTitulo(); }));
    }

    public static void Resultado()
    {
        if (eu == null || eu.estado == "resultado") return;
        Efeitos.Tocar("fase_concluida", 1f, 0f);
        Salvar.Gravar();
        int seg = Mathf.RoundToInt(eu.tempoFase);
        // o MAPA: a estrada segue da vila para o castelo
        eu.Menu("resultado", "FASE CONCLUÍDA", $"{Fase.Nome}\nTEMPO {seg / 60}:{seg % 60:00}   ·   INIMIGOS {Jogo.inimigosDerrotados}   ·   ORBS {Jogo.orbs}", false,
            ("SEGUIR PARA O CASTELO DE VALLACK", () => { Fase.numero = 2; Checkpoint.ativo = false; Salvar.Gravar(); Recarregar(); }),
            ("MENU PRINCIPAL", () => { pularTitulo = false; RecarregarTitulo(); }));
        if (eu.mapa != null) { eu.tela.enabled = true; eu.tela.sprite = eu.mapa; eu.tela.color = new Color(1, 1, 1, 0.55f); eu.fundo.color = Color.black; }
    }

    // FIM DO JOGO: o Salão Real foi limpo
    public static void Final()
    {
        if (eu == null || eu.estado == "resultado") return;
        Efeitos.Tocar("fase_concluida", 1f, 0f);
        Musica.Tocar("mus_menu");
        Fase.numero = 1; Checkpoint.ativo = false;
        Salvar.Gravar();
        int seg = Mathf.RoundToInt(eu.tempoFase);
        eu.Menu("resultado", "O SALÃO REAL ESTÁ LIVRE", $"Os servos de Vallack caíram, mas a chama maldita ainda arde.\nA jornada de Twilight continua...\n\nTEMPO {seg / 60}:{seg % 60:00}   ·   INIMIGOS {Jogo.inimigosDerrotados}   ·   ORBS {Jogo.orbs}", false,
            ("MENU PRINCIPAL", () => { pularTitulo = false; RecarregarTitulo(); }));
    }

    public static void Aviso(string texto, float segundos = 3.2f)
    {
        if (eu == null) return;
        eu.avisoTxt.text = texto; eu.avisoT = segundos;
        Efeitos.Tocar("sfx_important_message", 0.7f, 0f);
    }

    // ---------------------------------------------------------------
    void Update()
    {
        if (avisoT > 0) { avisoT -= Time.unscaledDeltaTime; var c = avisoTxt.color; c.a = Mathf.Clamp01(avisoT * 2f); avisoTxt.color = c; if (avisoT <= 0) avisoTxt.text = ""; }
        pausaBtn.enabled = estado == "jogo";

        // toque / clique
        bool apertou = false; Vector2 pos = default;
        var ts = Touchscreen.current;
        if (ts != null) foreach (var t in ts.touches) if (t.press.wasPressedThisFrame) { apertou = true; pos = t.position.ReadValue(); }
        var ms = Mouse.current;
        if (ms != null && ms.leftButton.wasPressedThisFrame) { apertou = true; pos = ms.position.ReadValue(); }
        var kb = Keyboard.current; var gp = Gamepad.current;

        if (estado == "video" || estado == "aviso" || estado == "prologo" || estado == "pergaminho") { PassoDeTela(apertou || Controles.QualquerApertou); return; }
        if (estado == "jogo")
        {
            if (Dialogo.Ativo) return;
            tempoFase += Time.deltaTime;
            bool p = (kb != null && (kb.escapeKey.wasPressedThisFrame || kb.pKey.wasPressedThisFrame)) || (gp != null && gp.startButton.wasPressedThisFrame);
            if (apertou && RectTransformUtility.RectangleContainsScreenPoint(pausaBtn.rectTransform, pos)) p = true;
            if (p && Jogador.eu != null && !Jogador.eu.morto && !Qte.Ativo) Pausa();
            return;
        }
        // navegação por teclado / controle
        int mov = 0; bool ok = false;
        if (kb != null) { if (kb.downArrowKey.wasPressedThisFrame || kb.sKey.wasPressedThisFrame) mov = 1; if (kb.upArrowKey.wasPressedThisFrame || kb.wKey.wasPressedThisFrame) mov = -1; ok |= kb.enterKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame; }
        if (gp != null) { if (gp.dpad.down.wasPressedThisFrame) mov = 1; if (gp.dpad.up.wasPressedThisFrame) mov = -1; ok |= gp.buttonSouth.wasPressedThisFrame; }
        if (mov != 0 && opcoes.Count > 0) { sel = (sel + mov + opcoes.Count) % opcoes.Count; Efeitos.Tocar("sfx_menu_mover", 0.5f, 0f); }
        Action acao = null;
        for (int i = 0; i < opcoes.Count; i++)
        {
            if (apertou && RectTransformUtility.RectangleContainsScreenPoint(opcoes[i].rt, pos)) { sel = i; acao = opcoes[i].acao; }
            opcoes[i].txt.color = i == sel ? new Color(1f, 0.85f, 0.45f) : Color.white;
            opcoes[i].rt.GetComponent<Image>().color = new Color(1, 1, 1, i == sel ? 0.16f : 0.07f);
        }
        if (ok && opcoes.Count > 0) acao = opcoes[sel].acao;
        if (acao != null) { Efeitos.Tocar("sfx_menu_ok", 0.6f, 0f); acao(); }
    }
}

// =====================================================================
//  SEQUÊNCIA DE GOLPES: o Carrasco exausto e a Árvore cambaleando só caem
//  por aqui. Cada botão certo na hora certa vira um golpe de cinema; no
//  último, Twilight executa o chefe. Errou ou demorou: o chefe se solta.
// =====================================================================
public class Qte : MonoBehaviour
{
    static Qte eu;
    public static bool Ativo => eu != null;
    static readonly string[] GOLPES = { "corte1", "corte2", "execucao", "corte2", "corte1", "execucao", "corte2", "corte1", "execucao", "corte2" };
    static readonly string[] BOTOES = { "GOLPE", "FORTE", "PULO", "DEFESA" };

    Inimigo alvo;
    int[] seq; int i;
    string estado = "entrada";
    float t, tempoBotao = 80f, acertoFx;
    Text rotulo; Image anel, disco;

    public static void Iniciar(Inimigo alvo)
    {
        if (eu != null || alvo == null) return;
        var q = new GameObject("QTE").AddComponent<Qte>();
        eu = q; q.alvo = alvo;
        int n = alvo.ehChefe ? 6 : 4;
        if (Dificuldade.nivel >= 2) n++;
        q.tempoBotao = Dificuldade.nivel == 0 ? 110f : (Dificuldade.nivel == 1 ? 80f : (Dificuldade.nivel == 2 ? 62f : 48f));
        q.seq = new int[n];
        for (int k = 0; k < n; k++)
        {
            int a = UnityEngine.Random.Range(0, BOTOES.Length);
            if (k >= 2 && q.seq[k - 1] == a && q.seq[k - 2] == a) a = (a + 1 + UnityEngine.Random.Range(0, 3)) % BOTOES.Length;   // nunca 3 iguais seguidos
            q.seq[k] = a;
        }
        alvo.emQte = true; alvo.qtePronto = false; alvo.velh = 0; alvo.empurrao = 0;
        Efeitos.Tocar("sfx_finalizador", 0.8f, 0f);
        q.MontarUI();
    }

    void MontarUI()
    {
        var cv = gameObject.AddComponent<Canvas>(); cv.renderMode = RenderMode.ScreenSpaceOverlay; cv.sortingOrder = 90;
        float u = Screen.height / 280f;
        anel = Novo("anel", new Color(1f, 0.85f, 0.4f, 0.5f)); disco = Novo("disco", new Color(0.1f, 0.05f, 0.08f, 0.9f));
        var go = new GameObject("rótulo", typeof(RectTransform), typeof(Text));
        go.transform.SetParent(transform, false);
        rotulo = go.GetComponent<Text>();
        rotulo.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"); rotulo.fontSize = Mathf.RoundToInt(13 * u);
        rotulo.fontStyle = FontStyle.Bold; rotulo.alignment = TextAnchor.MiddleCenter; rotulo.raycastTarget = false;
        rotulo.horizontalOverflow = HorizontalWrapMode.Overflow;
        var rt = rotulo.rectTransform; rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.7f); rt.sizeDelta = new Vector2(120 * u, 30 * u);
    }

    Image Novo(string nome, Color c)
    {
        var go = new GameObject(nome, typeof(RectTransform), typeof(Image));
        go.transform.SetParent(transform, false);
        var im = go.GetComponent<Image>(); im.sprite = Texturas.Disco(); im.color = c; im.raycastTarget = false;
        im.rectTransform.anchorMin = im.rectTransform.anchorMax = new Vector2(0.5f, 0.7f);
        return im;
    }

    void OnDestroy() { if (eu == this) eu = null; if (!Telas.Bloqueia) CameraVallack.zoom = 1f; }

    static int Apertado()
    {
        if (Controles.GolpeApertou) return 0;
        if (Controles.ForteApertou) return 1;
        if (Controles.PuloApertou) return 2;
        if (Controles.DefesaApertou || Controles.EsquivaApertou) return 3;
        if (Controles.BolaApertou || Controles.InteragirApertou || Controles.Esp1Apertou || Controles.Esp2Apertou || Controles.Esp3Apertou || Controles.FuriaApertou) return 9;
        return -1;
    }

    void Update()
    {
        float dt = Tempo.DtReal;
        if (Tempo.pausado) return;
        t += dt;
        if (acertoFx > 0) acertoFx -= dt;
        var p = Jogador.eu;
        if (alvo == null || (alvo.morrendo && estado != "sucesso") || p == null || p.morto)
        {
            if (alvo != null) { alvo.emQte = false; alvo.executando = false; }
            Destroy(gameObject); return;
        }
        if (estado != "sucesso" && estado != "falha")
        {
            // Twilight só obedece à sequência; nada o acerta; fica colado no chefe
            p.bloqueioInput = Mathf.Max(p.bloqueioInput, 2);
            float lado = Mathf.Sign(p.x - alvo.x); if (lado == 0) lado = -1;
            float tx = lado > 0 ? alvo.Dir + 18f : alvo.Esq - 18f;
            p.TempoInvencivel = Mathf.Max(p.TempoInvencivel, 20);
            p.x = Mathf.Lerp(p.x, tx, 0.3f); p.velh = 0; p.empurrao = 0;
            p.facing = Mathf.Sign(alvo.x - p.x) == 0 ? 1 : Mathf.Sign(alvo.x - p.x);
            CameraVallack.zoom = 1.24f;
        }
        bool falhou = false;
        switch (estado)
        {
            case "entrada": if (t >= 34) { estado = "botao"; t = 0; } break;
            case "botao":
                {
                    int ap = Apertado();
                    if (ap != -1 && t > 3) { if (ap == seq[i]) Acertou(p); else falhou = true; }
                    else if (t >= tempoBotao) falhou = true;
                }
                break;
            case "golpe":
                if (t >= 24) { if (i >= seq.Length) Concluir(p); else { estado = "botao"; t = 0; } }
                break;
            case "sucesso": if (t >= 70) Destroy(gameObject); break;
            case "falha": if (t >= 50) Destroy(gameObject); break;
        }
        if (falhou)
        {
            // o chefe se solta, empurra Twilight e volta a lutar
            estado = "falha"; t = 0;
            Efeitos.Tocar("sfx_negado", 0.9f, 0f);
            CameraVallack.Tremer(14f); CameraVallack.zoom = 1f;
            p.GolpeCancelar(); p.TempoInvencivel = 0;
            alvo.emQte = false; alvo.executando = false; alvo.qtePronto = false;
            alvo.QteFalhou();
        }
        // interface: o botão pedido e o anel do tempo
        bool pede = estado == "botao";
        rotulo.enabled = anel.enabled = disco.enabled = pede || estado == "entrada" || acertoFx > 0;
        float u = Screen.height / 280f;
        if (pede)
        {
            float frac = 1f - t / tempoBotao;
            rotulo.text = BOTOES[seq[i]]; rotulo.color = Color.white;
            disco.rectTransform.sizeDelta = Vector2.one * 46 * u;
            anel.rectTransform.sizeDelta = Vector2.one * (46 + 40 * frac) * u;
            anel.color = Color.Lerp(new Color(1f, 0.25f, 0.2f, 0.6f), new Color(1f, 0.85f, 0.4f, 0.5f), frac);
        }
        else if (estado == "entrada") { rotulo.text = "SEQUÊNCIA DE GOLPES"; rotulo.color = new Color(1f, 0.85f, 0.45f); disco.rectTransform.sizeDelta = anel.rectTransform.sizeDelta = Vector2.zero; }
        else if (acertoFx > 0) { rotulo.text = (i >= seq.Length ? "EXECUÇÃO!" : "BOA!"); rotulo.color = new Color(0.6f, 1f, 0.6f); disco.rectTransform.sizeDelta = anel.rectTransform.sizeDelta = Vector2.zero; }
    }

    void Acertou(Jogador p)
    {
        i++; acertoFx = 16; estado = "golpe"; t = 0;
        // o golpe de cinema (a vida quem tira é a sequência: o chefe está em_qte)
        p.GolpeCancelar();
        p.GolpeIniciar(GOLPES[(i - 1) % GOLPES.Length]);
        int n = seq.Length, resta = n - i + 1;
        alvo.FerirNaSequencia(Mathf.Max(1, Mathf.Round((alvo.vida - 1) / Mathf.Max(1, resta))));
        float cx = alvo.ehChefe ? (p.x < alvo.x ? alvo.Esq + 26 : alvo.Dir - 26) : alvo.x, cy = alvo.MeioY;
        Efeitos.Corte(cx, cy, p.facing, true);
        Efeitos.Faiscas(cx, cy, i >= n ? 2f : 1.3f);
        Efeitos.Sangue(cx, cy, p.facing, alvo.ehChefe ? 1.4f : 1.1f);
        Tempo.Impacto(i >= n ? 10 : 6);
        CameraVallack.Tremer(i >= n ? 16 : 9);
        Efeitos.SomHit(true);
    }

    void Concluir(Jogador p)
    {
        // SEQUÊNCIA COMPLETA: o finalizador derruba o chefe
        estado = "sucesso"; t = 0;
        p.GolpeCancelar();
        alvo.emQte = false; alvo.qteVencido = true; alvo.executando = true; alvo.qtePronto = false;
        p.DefinirAlvoFinal(alvo);
        p.GolpeIniciar("finalizador");
        p.vida = Mathf.Min(p.vidaMax, p.vida + Mathf.Round(p.vidaMax * 0.2f));     // cada sequência completa devolve vida
        Efeitos.Tocar("espada_evoluir", 0.6f, 0f);
    }
}
