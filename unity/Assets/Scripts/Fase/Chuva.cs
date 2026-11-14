// =====================================================================
//  Chuva — a tempestade da Fase 1 em partículas da GPU (obj_clima):
//  gotas esticadas pela velocidade caindo inclinadas sobre a vista,
//  presas à câmera, e respingos no chão da rua.
// =====================================================================
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class Chuva : MonoBehaviour
{
    public Material alfa;
    public int gotasPorSegundo = 420;
    public int ordem = 150;
    public float chaoY = 693f;          // mundo (y para baixo)

    ParticleSystem gotas, respingos;
    Camera cam;
    float accResp;

    void Start()
    {
        cam = GetComponent<Camera>();
        if (Fase.numero == 2)
        {
            // dentro do castelo não chove: sem gotas e sem o som da chuva
            foreach (var a in FindObjectsByType<AudioSource>(FindObjectsSortMode.None)) if (a.clip != null && a.clip.name == "amb_chuva") a.Stop();
            enabled = false; return;
        }
        chaoY = TerrenoFase1.CHAO;
        float h = cam.orthographicSize * 2f, w = h * cam.aspect;

        gotas = Novo("chuva", 900);
        var main = gotas.main;
        main.startLifetime = 0.75f;
        main.startSpeed = 0f;
        main.startSize = new ParticleSystem.MinMaxCurve(1.1f, 1.6f);
        main.startColor = new Color(0.7f, 0.74f, 0.9f, 0.32f);
        var em = gotas.emission; em.enabled = true; em.rateOverTime = gotasPorSegundo;
        var sh = gotas.shape; sh.enabled = true;
        sh.shapeType = ParticleSystemShapeType.Box;
        sh.scale = new Vector3(w * 1.4f, 1f, 1f);
        sh.position = new Vector3(w * 0.15f, h * 0.62f, 0f);
        var vel = gotas.velocityOverLifetime; vel.enabled = true; vel.space = ParticleSystemSimulationSpace.World;
        vel.x = new ParticleSystem.MinMaxCurve(-120f, -90f);
        vel.y = new ParticleSystem.MinMaxCurve(-560f, -480f);
        vel.z = new ParticleSystem.MinMaxCurve(0f, 0f);
        var r = gotas.GetComponent<ParticleSystemRenderer>();
        r.renderMode = ParticleSystemRenderMode.Stretch;
        r.velocityScale = 0.028f;
        r.lengthScale = 1f;
        gotas.Play();

        respingos = Novo("respingos", 200);
        var m2 = respingos.main;
        m2.startSpeed = 0f;
        m2.gravityModifier = 0f;
        var sz = respingos.sizeOverLifetime; sz.enabled = true;
        sz.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(new Keyframe(0, 0.4f), new Keyframe(1, 1f)));
        var col = respingos.colorOverLifetime; col.enabled = true;
        var g = new Gradient();
        g.SetKeys(new[] { new GradientColorKey(new Color(0.75f, 0.8f, 0.95f), 0), new GradientColorKey(new Color(0.75f, 0.8f, 0.95f), 1) },
                  new[] { new GradientAlphaKey(0.35f, 0), new GradientAlphaKey(0f, 1) });
        col.color = g;
        respingos.Play();
    }

    ParticleSystem Novo(string nome, int max)
    {
        var go = new GameObject(nome);
        go.transform.SetParent(transform, false);
        go.transform.localPosition = new Vector3(0, 0, 9f);
        var ps = go.AddComponent<ParticleSystem>();
        ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
        var main = ps.main;
        main.loop = true; main.playOnAwake = false;
        main.simulationSpace = ParticleSystemSimulationSpace.World;
        main.maxParticles = max;
        var em = ps.emission; em.enabled = false;
        var sh = ps.shape; sh.enabled = false;
        var r = go.GetComponent<ParticleSystemRenderer>();
        r.sharedMaterial = alfa;
        r.sortingOrder = ordem;
        return ps;
    }

    void Update()
    {
        if (respingos == null) return;
        // respingos na rua visível (só fora dos abismos)
        float meio = cam.orthographicSize * cam.aspect;
        float yTela = -chaoY;
        if (Mathf.Abs(cam.transform.position.y - yTela) > cam.orthographicSize + 10f) return;
        accResp += Time.deltaTime * 55f;
        var ep = new ParticleSystem.EmitParams();
        while (accResp >= 1f)
        {
            accResp -= 1f;
            float x = cam.transform.position.x + Random.Range(-meio, meio);
            bool buraco = false;
            foreach (var a in TerrenoFase1.ABISMOS) if (x > a[0] && x < a[1]) buraco = true;
            if (buraco) continue;
            ep.position = new Vector3(x, yTela + Random.Range(2f, 14f), 0);
            ep.startLifetime = Random.Range(0.18f, 0.3f);
            ep.startSize = Random.Range(3f, 5f);
            ep.velocity = Vector3.zero;
            respingos.Emit(ep, 1);
        }
    }
}
