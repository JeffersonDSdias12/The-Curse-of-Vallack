// =====================================================================
//  Efeitos — o "peso" dos golpes (obj_fx / obj_fagulha do original):
//  faíscas do corte, o risco de luz do golpe, poeira, o monstro explodindo
//  em chamas (golpe fatal), fantasmas da esquiva e textos (CRÍTICO!).
//  Tudo em lotes de partículas da GPU e objetos reaproveitados (sem criar
//  lixo durante a luta). Chamado de qualquer lugar: Efeitos.Faiscas(...).
//  Coordenadas no mundo do jogo (y para baixo).
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class Efeitos : MonoBehaviour
{
    public Material aditivo, alfa, fogo;
    public AudioClip[] hits;
    public AudioClip hitPesado, explosao, bloqueio, aparar, dano, esquiva, derrota, inimigoGolpe, portal, evaporar;
    public AudioClip aranhaChiado, teiaDisparo, teiaPrende, pedraTinido, pedraDesmorona, estatuaCarga, estatuaDisparo;
    public AudioClip porcoGrunhido, porcoImpacto, magiaOnda, rugido, atkPesado, pulo;
    public AudioClip escudoQuebra, ossoDesmonta, ossoErgue, ossoQuebra, ossoChocalho, flecha;

    // os efeitos ficam em Resources/Sons e são tocados pelo nome do arquivo. Entram aos
    // poucos (um por quadro) depois que a cena abre: pré-carregar os 106 junto com a cena
    // derrubava o jogo no celular
    public string[] nomes;
    public static float volume = 1f;
    static readonly Dictionary<string, AudioClip> porNome = new Dictionary<string, AudioClip>();
    static Efeitos eu;

    public static void Tocar(string nome, float vol = 1f, float tomVar = 0.05f, float tom = 0f)
    {
        if (eu == null) return;
        if (!porNome.TryGetValue(nome, out var c)) { c = Resources.Load<AudioClip>("Sons/" + nome); porNome[nome] = c; }
        if (c == null) return;
        eu.som.pitch = tom > 0 ? tom : Random.Range(1f - tomVar, 1f + tomVar);
        eu.som.PlayOneShot(c, vol * volume);
    }

    // onda de choque rente ao chão (pousos pesados, especiais)
    public static void OndaChao(float x, float y, float tam)
    {
        int n = Mathf.RoundToInt(3 * tam) + 1;
        for (int k = -n; k <= n; k++) Poeira(x + k * 22f * tam, y, 0.9f + 0.3f * tam);
        Corte(x, y - 3f, 1f, true);
        Faiscas(x, y - 6f, tam, 8);
    }

    // labareda comum (fogo no chão, viga em chamas)
    public static void ChamaComum(float x, float y, float forca)
    {
        if (eu == null) return;
        var ep = new ParticleSystem.EmitParams();
        float alt = Random.Range(14f, 24f) * (0.6f + forca);
        ep.position = Mundo.Tela(x, y - alt * 0.35f);
        ep.velocity = new Vector3(Random.Range(-3f, 3f), Random.Range(26f, 50f) * (0.6f + forca), 0);
        ep.startLifetime = Random.Range(0.3f, 0.55f);
        ep.startSize3D = new Vector3(alt * 0.6f, alt, 1f);
        ep.startColor = new Color(1f, 0.6f, 0.25f, 1f);
        eu.chamas.Emit(ep, 1);
    }

    // labareda dourada da Chama de Sylla
    public static void ChamaDourada(float x, float y, float forca)
    {
        if (eu == null) return;
        var ep = new ParticleSystem.EmitParams();
        float alt = Random.Range(18f, 30f);
        ep.position = Mundo.Tela(x, y - alt * 0.35f);
        ep.velocity = new Vector3(Random.Range(-3f, 3f), Random.Range(30f, 55f), 0);
        ep.startLifetime = Random.Range(0.35f, 0.6f);
        ep.startSize3D = new Vector3(alt * 0.6f, alt, 1f);
        ep.startColor = new Color(1f, 0.85f, 0.4f, forca);
        eu.chamas.Emit(ep, 1);
    }
    ParticleSystem faiscas, poeira, chamas, sangue;
    AudioSource som;

    class Risco { public SpriteRenderer sr; public float vida, max, larg, alt; }
    class Copia { public SpriteRenderer sr; public float vida, max; public Color cor; }
    class Texto { public TextMesh tm; public float vida, max; public Vector3 pos; }
    readonly List<Risco> riscos = new List<Risco>();
    readonly List<Copia> fantasmas = new List<Copia>();
    readonly List<Texto> textos = new List<Texto>();

    void Awake()
    {
        eu = this;
        som = gameObject.AddComponent<AudioSource>();
        som.playOnAwake = false;
        volume = PlayerPrefs.GetFloat("vol_efeitos", 1f);
        porNome.Clear();
        if (nomes != null) StartCoroutine(Aquecer());
        Coleta.Preparar(aditivo);

        faiscas = Sistema("faíscas", aditivo, 120, 300);
        var m = faiscas.main; m.gravityModifier = 0f;
        var r = faiscas.GetComponent<ParticleSystemRenderer>();
        r.renderMode = ParticleSystemRenderMode.Stretch; r.velocityScale = 0.035f; r.lengthScale = 1f;
        Cor(faiscas, new Color(1f, 1f, 0.9f), new Color(1f, 0.55f, 0.2f), 1f);
        var f = faiscas.forceOverLifetime; f.enabled = true; f.space = ParticleSystemSimulationSpace.World; f.y = -420f;

        poeira = Sistema("poeira", alfa, 70, 120);
        Cor(poeira, new Color(0.6f, 0.55f, 0.55f), new Color(0.45f, 0.42f, 0.45f), 0.4f);
        var sz = poeira.sizeOverLifetime; sz.enabled = true;
        sz.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(new Keyframe(0, 0.5f), new Keyframe(1, 1.4f)));

        chamas = Sistema("chamas da morte", fogo != null ? fogo : aditivo, 115, 300);
        var mc = chamas.main; mc.startSize3D = true;
        Cor(chamas, new Color(1f, 0.92f, 0.7f), new Color(0.7f, 0.2f, 0.9f), 1f);
        var szc = chamas.sizeOverLifetime; szc.enabled = true;
        szc.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(new Keyframe(0, 1f), new Keyframe(1, 0.2f)));

        sangue = Sistema("sangue", alfa, 110, 200);
        Cor(sangue, new Color(0.75f, 0.06f, 0.08f), new Color(0.4f, 0.02f, 0.05f), 0.95f);
        var fs = sangue.forceOverLifetime; fs.enabled = true; fs.space = ParticleSystemSimulationSpace.World; fs.y = -520f;
    }

    System.Collections.IEnumerator Aquecer()
    {
        yield return null;
        foreach (var n in nomes)
        {
            if (porNome.ContainsKey(n)) continue;
            Debug.Log("[som] " + n);
            porNome[n] = Resources.Load<AudioClip>("Sons/" + n);
            yield return null;
        }
        Debug.Log("[som] todos os efeitos carregados: " + porNome.Count);
    }

    ParticleSystem Sistema(string nome, Material mat, int ordem, int max)
    {
        var go = new GameObject(nome);
        go.transform.SetParent(transform, false);
        var ps = go.AddComponent<ParticleSystem>();
        ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
        var main = ps.main;
        main.loop = true; main.playOnAwake = false;
        main.simulationSpace = ParticleSystemSimulationSpace.World;
        main.maxParticles = max; main.startSpeed = 0f;
        var em = ps.emission; em.enabled = false;
        var sh = ps.shape; sh.enabled = false;
        var r = go.GetComponent<ParticleSystemRenderer>();
        r.sharedMaterial = mat; r.sortingOrder = ordem;
        ps.Play();
        return ps;
    }

    static void Cor(ParticleSystem ps, Color a, Color b, float alfa0)
    {
        var col = ps.colorOverLifetime; col.enabled = true;
        var g = new Gradient();
        g.SetKeys(new[] { new GradientColorKey(a, 0), new GradientColorKey(b, 1) },
                  new[] { new GradientAlphaKey(alfa0, 0), new GradientAlphaKey(alfa0, 0.5f), new GradientAlphaKey(0, 1) });
        col.color = g;
    }

    // ---------------------------------------------------------------
    public static void Faiscas(float x, float y, float tam = 1f, int n = 10)
    {
        if (eu == null) return;
        var ep = new ParticleSystem.EmitParams();
        for (int i = 0; i < Mathf.RoundToInt(n * tam); i++)
        {
            float ang = Random.Range(0f, Mathf.PI * 2f), v = Random.Range(90f, 260f) * tam;
            ep.position = Mundo.Tela(x, y);
            ep.velocity = new Vector3(Mathf.Cos(ang) * v, Mathf.Sin(ang) * v + 60f, 0);
            ep.startLifetime = Random.Range(0.18f, 0.4f);
            ep.startSize = Random.Range(1.2f, 2.4f);
            ep.startColor = Color.white;
            eu.faiscas.Emit(ep, 1);
        }
    }

    public static void Sangue(float x, float y, float dir, float tam = 1f)
    {
        if (eu == null) return;
        var ep = new ParticleSystem.EmitParams();
        for (int i = 0; i < Mathf.RoundToInt(9 * tam); i++)
        {
            ep.position = Mundo.Tela(x, y);
            ep.velocity = new Vector3(dir * Random.Range(40f, 190f), Random.Range(20f, 170f), 0);
            ep.startLifetime = Random.Range(0.3f, 0.6f);
            ep.startSize = Random.Range(1.6f, 3.4f);
            ep.startColor = Color.white;
            eu.sangue.Emit(ep, 1);
        }
    }

    public static void Poeira(float x, float y, float tam = 1f)
    {
        if (eu == null) return;
        var ep = new ParticleSystem.EmitParams();
        for (int i = 0; i < 5; i++)
        {
            ep.position = Mundo.Tela(x + Random.Range(-6f, 6f), y - 2f);
            ep.velocity = new Vector3(Random.Range(-26f, 26f), Random.Range(6f, 26f), 0);
            ep.startLifetime = Random.Range(0.3f, 0.55f);
            ep.startSize = Random.Range(8f, 14f) * tam;
            ep.startColor = Color.white;
            eu.poeira.Emit(ep, 1);
        }
    }

    // GOLPE FATAL: o monstro explode em chamas da maldição
    public static void ChamasMorte(float x, float y, float tam)
    {
        if (eu == null) return;
        var ep = new ParticleSystem.EmitParams();
        for (int i = 0; i < Mathf.RoundToInt(34 * tam); i++)
        {
            float alt = Random.Range(14f, 30f) * tam;
            ep.position = Mundo.Tela(x + Random.Range(-14f, 14f) * tam, y + Random.Range(-26f, 26f) * tam);
            ep.velocity = new Vector3(Random.Range(-50f, 50f), Random.Range(40f, 150f), 0);
            ep.startLifetime = Random.Range(0.35f, 0.8f);
            ep.startSize3D = new Vector3(alt * 0.6f, alt, 1f);
            ep.startColor = Color.white;
            eu.chamas.Emit(ep, 1);
        }
        Faiscas(x, y, 1.4f * tam, 14);
    }

    // o risco de luz do corte no ponto do acerto
    public static void Corte(float x, float y, float dir, bool forte)
    {
        if (eu == null) return;
        var r = eu.riscos.Find(k => k.vida <= 0);
        if (r == null)
        {
            var go = new GameObject("corte");
            go.transform.SetParent(eu.transform, false);
            r = new Risco { sr = go.AddComponent<SpriteRenderer>() };
            r.sr.sprite = Texturas.Brilho(); r.sr.sharedMaterial = eu.aditivo; r.sr.sortingOrder = 125;
            eu.riscos.Add(r);
        }
        r.max = r.vida = forte ? 9f : 7f;
        r.larg = (forte ? 110f : 78f); r.alt = forte ? 7f : 5f;
        r.sr.transform.position = Mundo.Tela(x, y);
        r.sr.transform.rotation = Quaternion.Euler(0, 0, dir * Random.Range(-38f, 38f));
        r.sr.color = forte ? new Color(1f, 0.82f, 0.6f, 1f) : Color.white;
        r.sr.enabled = true;
    }

    // rastro da esquiva: cópias do corpo que somem
    public static void Fantasma(Sprite s, Vector3 pos, Vector3 escala, Quaternion rot, Color cor, float vida = 12f)
    {
        if (eu == null || s == null) return;
        var f = eu.fantasmas.Find(k => k.vida <= 0);
        if (f == null)
        {
            var go = new GameObject("fantasma");
            go.transform.SetParent(eu.transform, false);
            f = new Copia { sr = go.AddComponent<SpriteRenderer>() };
            f.sr.sharedMaterial = eu.aditivo; f.sr.sortingOrder = 95;
            eu.fantasmas.Add(f);
        }
        f.sr.sprite = s; f.sr.transform.position = pos; f.sr.transform.localScale = escala; f.sr.transform.rotation = rot;
        f.cor = cor; f.max = f.vida = vida; f.sr.enabled = true;
    }

    public static void Popup(float x, float y, string texto, Color cor)
    {
        if (eu == null) return;
        var t = eu.textos.Find(k => k.vida <= 0);
        if (t == null)
        {
            var go = new GameObject("popup");
            go.transform.SetParent(eu.transform, false);
            t = new Texto { tm = go.AddComponent<TextMesh>() };
            t.tm.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            t.tm.fontSize = 64; t.tm.characterSize = 1.1f; t.tm.anchor = TextAnchor.LowerCenter; t.tm.fontStyle = FontStyle.Bold;
            var mr = go.GetComponent<MeshRenderer>();
            mr.sharedMaterial = t.tm.font.material; mr.sortingOrder = 140;
            eu.textos.Add(t);
        }
        t.tm.text = texto; t.tm.color = cor;
        t.pos = Mundo.Tela(x, y, -1f); t.max = t.vida = 50f;
        t.tm.gameObject.SetActive(true);
    }

    public static void Som(AudioClip c, float vol = 1f, float tomVar = 0.05f)
    {
        if (eu == null || c == null) return;
        eu.som.pitch = Random.Range(1f - tomVar, 1f + tomVar);
        eu.som.PlayOneShot(c, vol * volume);
    }

    public static void SomHit(bool pesado)
    {
        if (eu == null) return;
        if (pesado) Som(eu.hitPesado, 1f);
        else if (eu.hits != null && eu.hits.Length > 0) Som(eu.hits[Random.Range(0, eu.hits.Length)], 0.85f);
    }

    public static Efeitos Sons => eu;

    void Update()
    {
        float dt = Tempo.Dt;
        foreach (var r in riscos)
        {
            if (r.vida <= 0) continue;
            r.vida -= dt;
            float p = 1f - Mathf.Clamp01(r.vida / r.max);
            r.sr.transform.localScale = new Vector3(r.larg * (0.35f + 0.65f * Mathf.Sqrt(p)), r.alt * (1f - p), 1f);
            if (r.vida <= 0) r.sr.enabled = false;
        }
        foreach (var f in fantasmas)
        {
            if (f.vida <= 0) continue;
            f.vida -= dt;
            var c = f.cor; c.a *= Mathf.Clamp01(f.vida / f.max) * 0.6f; f.sr.color = c;
            if (f.vida <= 0) f.sr.enabled = false;
        }
        foreach (var t in textos)
        {
            if (t.vida <= 0) continue;
            t.vida -= Tempo.DtReal;
            float p = 1f - Mathf.Clamp01(t.vida / t.max);
            t.tm.transform.position = t.pos + new Vector3(0, 18f * Mathf.Sqrt(p), 0);
            float esc = 0.16f * (p < 0.12f ? Mathf.Lerp(1.8f, 1f, p / 0.12f) : 1f);
            t.tm.transform.localScale = new Vector3(esc, esc, 1);
            var c = t.tm.color; c.a = p > 0.7f ? (1f - p) / 0.3f : 1f; t.tm.color = c;
            if (t.vida <= 0) t.tm.gameObject.SetActive(false);
        }
    }
}
