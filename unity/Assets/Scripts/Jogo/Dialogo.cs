// =====================================================================
//  Dialogo — caixa de diálogo (obj_dialogo): pausa o mundo, mostra o nome
//  de quem fala (e o retrato do Twilight) e escreve o texto letra por
//  letra. Qualquer toque / GOLPE / Enter completa o texto e passa para a
//  próxima fala. As falas são as do jogo original (dialogo_falas).
//  Fase — qual fase está carregada (1 = Vila em Chamas, 2 = Castelo).
// =====================================================================
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public static class Fase
{
    public static int numero = 1;
    public static string Nome => numero == 2 ? "O CASTELO DE VALLACK" : "A VILA EM CHAMAS";
}

public class Dialogo : MonoBehaviour
{
    public static bool Ativo => eu != null;
    static Dialogo eu;
    static Sprite retratoTwilight;
    static readonly HashSet<string> vistos = new HashSet<string>();

    (string quem, string texto)[] falas;
    int i; float letras, tempo, abre;
    bool fechando; int blip;
    Action aoFim;
    Image caixa, retrato; Text nome, texto, dica;
    CanvasGroup grupo;

    public static void Retrato(Sprite s) { retratoTwilight = s; }

    static (string, string)[] Falas(string qual)
    {
        switch (qual)
        {
            case "morador": return new[] {
                ("morador", "Senhor! Graças aos céus... Os servos de Vallack invadiram a vila!"),
                ("twilight", "Leve todos para a ponte do norte. Ninguém fica nas ruas: eu cuido deles."),
                ("morador", "E o fogo? Chove a noite inteira e as casas não param de queimar!"),
                ("twilight", "Não é fogo comum. Essas chamas roxas vêm do poder de Vallack. A chuva não as apaga."),
                ("morador", "Os anciãos dizem que só a água mágica do templo de Sylla apaga a chama maldita..."),
                ("twilight", "Então vou buscá-la, depois de abrir caminho até o castelo. Agora vá!") };
            case "batalha": return new[] { ("twilight", "Servos de Vallack... irão pagar com a vida!") };
            case "carrasco_inicio": return new[] {
                ("carrasco", "Mais um herói vindo morrer na estrada de Vallack."),
                ("twilight", "Saia da frente, Carrasco. Esta vila não pertence ao seu mestre."),
                ("carrasco", "Tudo pertence a Vallack. Até a sua cabeça... quando eu a cortar!") };
            case "carrasco_fase2": return new[] { ("carrasco", "Você luta bem... Chega de brincadeira!") };
            case "carrasco_fim": return new[] {
                ("carrasco", "Isso... não acaba aqui... A Árvore guarda a estrada..."),
                ("twilight", "Então ela é a próxima.") };
            case "arvore_inicio": return new[] {
                ("arvore", "Pequeno guerreiro... Minhas raízes beberam o sangue de mil invasores."),
                ("twilight", "Foi você quem espalhou a chama maldita pela vila?"),
                ("arvore", "A chama é de Vallack. Eu apenas a guardo. Nenhuma chuva vai apagá-la!"),
                ("twilight", "Então vou arrancá-la pela raiz.") };
            case "arvore_fase2": return new[] { ("arvore", "Sinta a floresta inteira se erguer contra você!") };
            case "arvore_fase3": return new[] { ("arvore", "Vallack... me dê força... QUEIME!") };
            case "arvore_fim": return new[] {
                ("arvore", "A chama... não morre comigo... só a água do templo..."),
                ("twilight", "Então é para o templo que eu vou.") };
        }
        return null;
    }

    static string NomeDe(string q) => q == "twilight" ? "TWILIGHT VETRUS" : (q == "carrasco" ? "O CARRASCO DE VALLACK" : (q == "arvore" ? "ÁRVORE AMALDIÇOADA" : "MORADOR DA VILA"));
    static Color CorDe(string q) => q == "twilight" ? new Color(0.95f, 0.85f, 0.6f) : (q == "morador" ? new Color(0.75f, 0.9f, 1f) : new Color(1f, 0.45f, 0.45f));

    // umaVez: falas de história não repetem ao tentar a luta de novo
    public static void Iniciar(string qual, Action aoFim = null, bool umaVez = true)
    {
        if (eu != null || (umaVez && vistos.Contains(qual))) { aoFim?.Invoke(); return; }
        var f = Falas(qual);
        if (f == null) { aoFim?.Invoke(); return; }
        vistos.Add(qual);
        var d = new GameObject("Diálogo").AddComponent<Dialogo>();
        eu = d; d.falas = f; d.aoFim = aoFim;
        d.Montar();
        Tempo.pausado = true;
        Controles.visivel = false;
        Efeitos.Tocar("dialogo_abrir", 0.7f, 0f);
    }

    public static void Esquecer() { vistos.Clear(); }

    void Montar()
    {
        var cv = gameObject.AddComponent<Canvas>(); cv.renderMode = RenderMode.ScreenSpaceOverlay; cv.sortingOrder = 95;
        grupo = gameObject.AddComponent<CanvasGroup>();
        float u = Screen.height / 280f;
        var fonte = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        caixa = Novo<Image>("caixa"); caixa.color = new Color(0.05f, 0.03f, 0.06f, 0.9f);
        Ret(caixa.rectTransform, 0.5f, 0f, new Vector2(0, 10) * u, new Vector2(330, 62) * u, new Vector2(0.5f, 0));
        retrato = Novo<Image>("retrato"); retrato.preserveAspect = true; retrato.sprite = retratoTwilight;
        Ret(retrato.rectTransform, 0.5f, 0f, new Vector2(-140, 14) * u, new Vector2(46, 54) * u, new Vector2(0.5f, 0));
        nome = Novo<Text>("nome"); nome.font = fonte; nome.fontSize = Mathf.RoundToInt(8 * u); nome.fontStyle = FontStyle.Bold; nome.alignment = TextAnchor.UpperLeft;
        Ret(nome.rectTransform, 0.5f, 0f, new Vector2(18, 56) * u, new Vector2(250, 12) * u, new Vector2(0.5f, 0));
        texto = Novo<Text>("texto"); texto.font = fonte; texto.fontSize = Mathf.RoundToInt(8.5f * u); texto.color = Color.white; texto.alignment = TextAnchor.UpperLeft;
        Ret(texto.rectTransform, 0.5f, 0f, new Vector2(18, 20) * u, new Vector2(250, 34) * u, new Vector2(0.5f, 0));
        dica = Novo<Text>("dica"); dica.font = fonte; dica.fontSize = Mathf.RoundToInt(6 * u); dica.color = new Color(1f, 0.85f, 0.5f); dica.alignment = TextAnchor.LowerRight;
        dica.text = "TOQUE PARA CONTINUAR";
        Ret(dica.rectTransform, 0.5f, 0f, new Vector2(60, 12) * u, new Vector2(200, 8) * u, new Vector2(0.5f, 0));
    }

    T Novo<T>(string nomeObj) where T : Graphic
    {
        var go = new GameObject(nomeObj, typeof(RectTransform), typeof(T));
        go.transform.SetParent(transform, false);
        var g = go.GetComponent<T>(); g.raycastTarget = false;
        return g;
    }

    static void Ret(RectTransform rt, float ax, float ay, Vector2 pos, Vector2 tam, Vector2 pivo)
    {
        rt.anchorMin = rt.anchorMax = new Vector2(ax, ay); rt.pivot = pivo; rt.anchoredPosition = pos; rt.sizeDelta = tam;
    }

    void Update()
    {
        float dt = Tempo.DtReal;
        tempo += dt;
        if (fechando)
        {
            abre = Mathf.Max(0, abre - 0.16f * dt); grupo.alpha = abre;
            if (abre <= 0) Fechar();
            return;
        }
        abre = Mathf.Min(1, abre + 0.12f * dt); grupo.alpha = abre;
        var f = falas[i];
        int n = f.texto.Length;
        // o texto aparece letra por letra (com um "bip" grave a cada 3 letras)
        if (abre >= 1 && letras < n)
        {
            float antes = Mathf.Floor(letras);
            letras = Mathf.Min(n, letras + 1.1f * dt);
            if (Mathf.Floor(letras) != antes && ++blip % 3 == 0) Efeitos.Tocar("dialogo_texto", 0.45f, 0.06f);
        }
        nome.text = NomeDe(f.quem); nome.color = CorDe(f.quem);
        texto.text = f.texto.Substring(0, Mathf.FloorToInt(letras));
        retrato.enabled = f.quem == "twilight" && retratoTwilight != null;
        dica.enabled = letras >= n && Mathf.Repeat(Time.unscaledTime, 1f) < 0.65f;
        if (tempo > 10 && Controles.QualquerApertou)
        {
            if (letras < n) letras = n;
            else if (i < falas.Length - 1) { i++; letras = 0; tempo = 0; Efeitos.Tocar("cut_passar", 0.5f); }
            else fechando = true;
        }
    }

    void Fechar()
    {
        eu = null;
        if (!Telas.EmMenu) { Tempo.pausado = false; Controles.visivel = true; }
        if (Jogador.eu != null) Jogador.eu.bloqueioInput = 12;     // o toque que fechou não vira golpe nem pulo
        var f = aoFim; aoFim = null;
        Destroy(gameObject);
        f?.Invoke();
    }
}

// entrega o retrato do Twilight para a caixa de diálogo
public class RetratoDialogo : MonoBehaviour
{
    public Sprite retrato;
    void Awake() { Dialogo.Retrato(retrato); }
}
