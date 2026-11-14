// =====================================================================
//  CenarioFase2 — O SALÃO REAL EM RUÍNAS (obj_cenario da Fase 2).
//  A arte do castelo (duas metades, castelo_a + castelo_b) cobre a faixa
//  y = 464..688 e repete a cada 1616 px; atrás dela o mesmo salão ampliado
//  e escurecido, com paralaxe; em cima a escuridão do teto; embaixo o piso
//  de pedra. Tochas de luz 2D ao longo do salão e brasas no ar.
// =====================================================================
using UnityEngine;
using UnityEngine.Rendering.Universal;

[DefaultExecutionOrder(100)]
public class CenarioFase2 : MonoBehaviour
{
    const float BANDA_TOPO = 464f, BANDA_BASE = 688f, CHAO_Y = 682f, PERIODO = 1616f, ESC_LONGE = 1.7f;
    Transform longe;
    Camera cam;
    float acc;

    public void Montar(Texture2D a, Texture2D b, Material lit, Material unlit, Material aditivo, Material alfa)
    {
        cam = Camera.main;
        cam.backgroundColor = new Color32(10, 6, 8, 255);
        float alt = BANDA_BASE - BANDA_TOPO;
        var sa = Metade(a, PERIODO / 2f); var sb = Metade(b, PERIODO / 2f);

        // salão distante: a mesma arte ampliada e escurecida
        longe = new GameObject("salão distante").transform;
        longe.SetParent(transform, false);
        float sw = PERIODO * ESC_LONGE, hd = alt * ESC_LONGE, baseY = BANDA_TOPO + 150f;
        for (int k = -1; k <= 2; k++)
        {
            Peca(longe, sa, k * sw, baseY, sw / 2f, hd, new Color32(92, 66, 70, 255), -800, unlit);
            Peca(longe, sb, k * sw + sw / 2f, baseY, sw / 2f, hd, new Color32(92, 66, 70, 255), -800, unlit);
        }
        // escuridão do teto por cima do salão distante
        Ret(-200f, -200f, Mundo.SALA_W + 200f, BANDA_TOPO, new Color(0.02f, 0.01f, 0.02f, 0.62f), -790, alfa);

        // o salão em alta resolução
        for (float x = 0; x < Mundo.SALA_W + 100f; x += PERIODO)
        {
            Peca(transform, sa, x, BANDA_BASE, PERIODO / 2f, alt, Color.white, -400, lit);
            Peca(transform, sb, x + PERIODO / 2f, BANDA_BASE, PERIODO / 2f, alt, Color.white, -400, lit);
        }
        // sombra onde a arte encontra o teto
        Ret(-200f, BANDA_TOPO - 2f, Mundo.SALA_W + 200f, BANDA_TOPO + 34f, new Color(0.04f, 0.015f, 0.025f, 0.55f), -390, alfa);

        // piso de pedra (aberto nos abismos)
        float x0 = -60f;
        foreach (var ab in TerrenoFase1.ABISMOS) { Piso(x0, ab[0], lit); x0 = ab[1]; }
        Piso(x0, Mundo.SALA_W + 60f, lit);

        // tochas: luz quente a cada trecho do salão
        for (float x = 260f; x < Mundo.SALA_W; x += 420f)
        {
            var go = new GameObject("tocha");
            go.transform.SetParent(transform, false);
            go.transform.position = Mundo.Tela(x, 560f);
            var l = go.AddComponent<Light2D>();
            l.lightType = Light2D.LightType.Point;
            l.color = new Color(1f, 0.62f, 0.32f); l.intensity = 0.9f;
            l.pointLightOuterRadius = 230f; l.pointLightInnerRadius = 30f; l.falloffIntensity = 0.6f;
            Vila.LuzCamadas(l);
            go.AddComponent<TremularLuz>();
        }
    }

    static Sprite Metade(Texture2D t, float larguraMundo)
    {
        if (t == null) return Texturas.Branco();
        return Sprite.Create(t, new Rect(0, 0, t.width, t.height), Vector2.zero, t.width / larguraMundo, 0, SpriteMeshType.FullRect);
    }

    void Peca(Transform pai, Sprite s, float x, float baseY, float w, float h, Color cor, int ordem, Material m)
    {
        var go = new GameObject("castelo");
        go.transform.SetParent(pai, false);
        go.transform.localPosition = Mundo.Tela(x, baseY);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = s; sr.color = cor; sr.sortingOrder = ordem; sr.sharedMaterial = m;
        // estica a metade da arte para w x h unidades do mundo
        var tam = s.bounds.size;
        go.transform.localScale = new Vector3(w / tam.x, h / tam.y, 1f);
    }

    void Piso(float x1, float x2, Material lit)
    {
        Ret(x1, CHAO_Y, x2, Mundo.SALA_H + 80f, new Color32(26, 19, 22, 255), -10, lit);
        Ret(x1, CHAO_Y, x2, CHAO_Y + 5f, new Color32(96, 72, 76, 255), -9, lit);
    }

    void Ret(float x1, float y1, float x2, float y2, Color c, int ordem, Material m)
    {
        var go = new GameObject("ret");
        go.transform.SetParent(transform, false);
        go.transform.position = Mundo.Tela(x1, y2);
        go.transform.localScale = new Vector3(x2 - x1, y2 - y1, 1f);
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = Texturas.Branco(); sr.color = c; sr.sortingOrder = ordem; sr.sharedMaterial = m;
    }

    void LateUpdate()
    {
        if (cam == null || longe == null) return;
        // paralaxe do salão distante (anda a 40% da câmera)
        float vx = cam.transform.position.x - cam.orthographicSize * cam.aspect;
        longe.position = new Vector3(vx * 0.6f, 0, 0);
        // brasas subindo no ar do salão
        acc += Tempo.Dt * 0.25f;
        while (acc >= 1f)
        {
            acc -= 1f;
            Efeitos.Faiscas(vx + Random.value * cam.orthographicSize * 2f * cam.aspect, BANDA_BASE - Random.value * 40f, 0.25f, 3);
        }
    }
}
