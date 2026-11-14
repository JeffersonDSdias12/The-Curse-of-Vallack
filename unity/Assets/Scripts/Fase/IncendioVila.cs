// =====================================================================
//  IncendioVila — o fogo da maldição preso às casas, em partículas da GPU.
//  Cada FOCO é um segmento da peça (rombo, janela quebrada, cume, água do
//  telhado) com a altura da chama; só os focos perto da câmera emitem.
//  Um sistema de partículas por fileira (o fogo do fundo fica atrás das
//  casas da frente), mais brasas, fumaça e o tremor dos brilhos.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class IncendioVila : MonoBehaviour
{
    public Material aditivo, alfa;
    public Material fogoMat;              // aditivo com a textura de labareda (pixel art)
    public float qualidade = 1f;          // multiplica a emissão (ajuste de desempenho)
    const float MARGEM = 60f;

    struct Foco { public Vector2 a, b; public float alt, forca, acc; public int plano, tipo; }
    struct Brilho { public SpriteRenderer sr; public float a, sem, x; }

    readonly List<Foco> focos = new List<Foco>();
    readonly List<Vector2> chamines = new List<Vector2>();
    readonly List<Brilho> brilhos = new List<Brilho>();
    readonly ParticleSystem[] fogo = new ParticleSystem[4];
    ParticleSystem brasas, fumaca;
    float[] accCham;
    Camera cam;

    public void AdicionarFoco(Vector2 a, Vector2 b, float alt, float forca, int plano, int tipo) =>
        focos.Add(new Foco { a = a, b = b, alt = alt, forca = forca, plano = plano, tipo = tipo, acc = Random.value });

    public void AdicionarChamine(Vector2 p) => chamines.Add(p);

    public void AdicionarBrilho(SpriteRenderer sr) =>
        brilhos.Add(new Brilho { sr = sr, a = sr.color.a, sem = Random.value * 40f, x = sr.transform.position.x });

    // ordens de desenho do fogo de cada fileira (0 = a da frente)
    public void Montar(int[] ordemFogo, int ordemBrasas, int ordemFumaca)
    {
        for (int p = 0; p < 4; p++)
        {
            var ps = Sistema("fogo fileira " + p, fogoMat != null ? fogoMat : aditivo, ordemFogo[p], 1600);
            var main = ps.main; main.startSize3D = true;
            var col = ps.colorOverLifetime; col.enabled = true;
            // labareda: base quase branca, corpo laranja, ponta roxa da maldição
            col.color = Degrade(new[] { (new Color(1f, 0.95f, 0.78f), 0f), (new Color(1f, 0.6f, 0.2f), 0.3f), (new Color(0.9f, 0.3f, 0.75f), 0.65f), (new Color(0.5f, 0.15f, 0.8f), 1f) },
                                new[] { (0f, 0f), (1f, 0.1f), (0.9f, 0.55f), (0f, 1f) });
            var sz = ps.sizeOverLifetime; sz.enabled = true;
            sz.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(new Keyframe(0, 0.8f), new Keyframe(0.15f, 1f), new Keyframe(1, 0.25f)));
            var nz = ps.noise; nz.enabled = true; nz.strength = 3.5f; nz.frequency = 0.25f; nz.scrollSpeed = 2f; nz.quality = ParticleSystemNoiseQuality.Low;
            fogo[p] = ps;
        }
        brasas = Sistema("brasas", aditivo, ordemBrasas, 400);
        {
            var col = brasas.colorOverLifetime; col.enabled = true;
            col.color = Degrade(new[] { (new Color(1f, 0.85f, 0.5f), 0f), (new Color(1f, 0.45f, 0.15f), 0.5f), (new Color(0.7f, 0.2f, 0.9f), 1f) },
                                new[] { (1f, 0f), (0.9f, 0.6f), (0f, 1f) });
            var nz = brasas.noise; nz.enabled = true; nz.strength = 40f; nz.frequency = 0.02f; nz.scrollSpeed = 0.6f; nz.quality = ParticleSystemNoiseQuality.Low;
        }
        fumaca = Sistema("fumaça", alfa, ordemFumaca, 300);
        {
            var col = fumaca.colorOverLifetime; col.enabled = true;
            col.color = Degrade(new[] { (new Color(0.55f, 0.28f, 0.2f), 0f), (new Color(0.26f, 0.22f, 0.28f), 0.25f), (new Color(0.18f, 0.16f, 0.2f), 1f) },
                                new[] { (0f, 0f), (0.32f, 0.15f), (0.22f, 0.6f), (0f, 1f) });
            var sz = fumaca.sizeOverLifetime; sz.enabled = true;
            sz.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(new Keyframe(0, 0.35f), new Keyframe(1, 1f)));
        }
        accCham = new float[chamines.Count];
    }

    ParticleSystem Sistema(string nome, Material m, int ordem, int max)
    {
        var go = new GameObject(nome);
        go.transform.SetParent(transform, false);
        var ps = go.AddComponent<ParticleSystem>();
        ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
        var main = ps.main;
        main.loop = true; main.playOnAwake = false;
        main.simulationSpace = ParticleSystemSimulationSpace.World;
        main.maxParticles = max;
        main.startSpeed = 0f;
        var em = ps.emission; em.enabled = false;
        var sh = ps.shape; sh.enabled = false;
        var r = go.GetComponent<ParticleSystemRenderer>();
        r.sharedMaterial = m;
        r.sortingOrder = ordem;
        r.renderMode = ParticleSystemRenderMode.Billboard;
        ps.Play();
        return ps;
    }

    static Gradient Degrade((Color c, float t)[] cores, (float a, float t)[] alfas)
    {
        var g = new Gradient();
        var ck = new GradientColorKey[cores.Length];
        for (int i = 0; i < cores.Length; i++) ck[i] = new GradientColorKey(cores[i].c, cores[i].t);
        var ak = new GradientAlphaKey[alfas.Length];
        for (int i = 0; i < alfas.Length; i++) ak[i] = new GradientAlphaKey(alfas[i].a, alfas[i].t);
        g.SetKeys(ck, ak);
        return g;
    }

    void Update()
    {
        if (cam == null) cam = Camera.main;
        if (cam == null || fogo[0] == null) return;
        float dt = Time.deltaTime;
        float meio = cam.orthographicSize * cam.aspect;
        float x1 = cam.transform.position.x - meio - MARGEM, x2 = cam.transform.position.x + meio + MARGEM;
        var ep = new ParticleSystem.EmitParams();

        for (int i = 0; i < focos.Count; i++)
        {
            var f = focos[i];
            if (Mathf.Max(f.a.x, f.b.x) < x1 || Mathf.Min(f.a.x, f.b.x) > x2) continue;
            float len = Vector2.Distance(f.a, f.b);
            float taxa = (12f + len * 0.7f) * f.forca * qualidade * (f.plano >= 2 ? 0.6f : 1f);
            f.acc += taxa * dt;
            int n = (int)f.acc;
            f.acc -= n;
            var ps = fogo[Mathf.Clamp(f.plano, 0, 3)];
            for (int k = 0; k < n; k++)
            {
                Vector2 p = Vector2.Lerp(f.a, f.b, Random.value);
                float vida = Random.Range(0.32f, 0.55f);
                float alt = f.alt * Random.Range(0.4f, 0.62f) * (f.tipo == 2 ? 0.8f : 1f);   // altura da língua de fogo
                ep.position = new Vector3(p.x + Random.Range(-1.5f, 1.5f), p.y + alt * 0.35f, 0f);
                ep.velocity = new Vector3(Random.Range(-2f, 2f), f.alt * 0.55f / vida * Random.Range(0.8f, 1.05f), 0f);
                ep.startLifetime = vida;
                ep.startSize3D = new Vector3(alt * Random.Range(0.5f, 0.68f), alt, 1f);
                float br = f.forca * Random.Range(0.8f, 1f);
                ep.startColor = new Color(br, br, br, 1f);
                ps.Emit(ep, 1);
            }
            // brasas que escapam das casas da frente
            if (f.plano <= 1 && Random.value < dt * 1.6f * qualidade)
            {
                Vector2 p = Vector2.Lerp(f.a, f.b, Random.value);
                ep.position = new Vector3(p.x, p.y + f.alt * 0.5f, 0f);
                ep.velocity = new Vector3(Random.Range(-10f, 18f), Random.Range(28f, 60f), 0f);
                ep.startLifetime = Random.Range(1.6f, 3.2f);
                ep.startSize = Random.Range(1.4f, 3f);
                ep.startColor = Color.white;
                brasas.Emit(ep, 1);
            }
            focos[i] = f;
        }

        for (int i = 0; i < chamines.Count; i++)
        {
            var c = chamines[i];
            if (c.x < x1 || c.x > x2) continue;
            accCham[i] += dt * 2.2f * qualidade;
            if (accCham[i] < 1f) continue;
            accCham[i] -= 1f;
            ep.position = new Vector3(c.x + Random.Range(-2f, 2f), c.y, 0f);
            ep.velocity = new Vector3(Random.Range(4f, 12f), Random.Range(14f, 24f), 0f);
            ep.startLifetime = Random.Range(3f, 4.5f);
            ep.startSize = Random.Range(14f, 24f);
            ep.startColor = Color.white;
            fumaca.Emit(ep, 1);
        }

        // brilhos das janelas e da maldição tremulando (só os perto da câmera)
        float t = Time.time * 60f / 16f;
        for (int i = 0; i < brilhos.Count; i++)
        {
            var b = brilhos[i];
            if (b.x < x1 - 200 || b.x > x2 + 200) continue;
            float fl = 0.72f + 0.28f * Mathf.Sin(t / 4f + b.sem) * Mathf.Sin(t / 9.3f + b.sem * 2f);
            var cor = b.sr.color; cor.a = b.a * fl; b.sr.color = cor;
        }
    }
}
