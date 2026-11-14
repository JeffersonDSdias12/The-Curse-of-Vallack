// =====================================================================
//  TremularLuz — a luz de um fogo respira: intensidade e raio oscilam com
//  ruído (Perlin), cada fogo no seu ritmo. Usada nas tochas, incêndios das
//  casas, fogo no chão e brasas.
// =====================================================================
using UnityEngine;
using UnityEngine.Rendering.Universal;

[RequireComponent(typeof(Light2D))]
public class TremularLuz : MonoBehaviour
{
    [Range(0, 1)] public float forca = 0.25f;
    public float ritmo = 3f;
    Light2D luz;
    float baseI, baseR, semente;

    void Awake()
    {
        luz = GetComponent<Light2D>();
        baseI = luz.intensity;
        baseR = luz.pointLightOuterRadius;
        semente = Random.value * 100f;
    }

    void Update()
    {
        float t = Time.time * ritmo + semente;
        float n = Mathf.PerlinNoise(t, semente) * 0.7f + Mathf.PerlinNoise(t * 2.7f, semente + 7f) * 0.3f;   // 0..1
        float f = 1f - forca + forca * 2f * n;
        luz.intensity = baseI * f;
        luz.pointLightOuterRadius = baseR * (0.92f + 0.08f * f);
    }
}
