// =====================================================================
//  CameraVallack — porta do camera_atualizar: olha 28 px à frente de quem
//  corre, segue com lerp (0,12 na horizontal, 0,10 na vertical, por quadro
//  de 60 FPS), fica presa à sala, treme nos impactos e "leva" a pancada
//  (camera_empurrar). Roda no tempo real: continua viva durante a pausa
//  de impacto e a câmera lenta.
//  Mostra 280 px do mundo na altura (orthographicSize 140), como o original.
// =====================================================================
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[DefaultExecutionOrder(50)]
[RequireComponent(typeof(Camera))]
public class CameraVallack : MonoBehaviour
{
    public Jogador alvo;
    const float ALTURA = 280f;
    public static float zoom = 1f;          // aproxima nos especiais, no finalizador e na sequência de golpes
    float zoomAtual = 1f;
    static float tremor, empurraX;
    static bool snap = true;
    static float vistaX1, vistaX2;

    Camera cam;
    float camX, camY, frente, frenteAlvo;
    float k = 1f;      // pixels de render por pixel do mundo

    public static void Tremer(float forca) => tremor = Mathf.Max(tremor, forca);
    public static void Empurrar(float dir, float forca) => empurraX = Mathf.Clamp(empurraX + dir * forca, -14f, 14f);
    public static void Cortar() => snap = true;
    public static float TopoVista;           // y do alto da vista, no mundo do jogo
    public static bool NaTela(float x, float margem) => x > vistaX1 + margem && x < vistaX2 - margem;

    void Awake()
    {
        cam = GetComponent<Camera>();
        cam.orthographicSize = ALTURA / 2f;
        snap = true; tremor = 0; empurraX = 0; zoom = 1f;
        // "bilinear nítido" (o mesmo truque da versão PC): o mundo é renderizado
        // em 280 x k inteiro (1080p -> 840 linhas, k = 3) e esticado para a tela;
        // cada pixel da arte vira um bloco exato de k x k e a GPU desenha ~40% menos
        k = Mathf.Max(1, Mathf.Floor(Screen.height / ALTURA));
        if (GraphicsSettings.currentRenderPipeline is UniversalRenderPipelineAsset urp)
            urp.renderScale = Mathf.Clamp(k * ALTURA / Screen.height, 0.5f, 1f);
    }

    static float LerpDt(float a, float b, float f, float dt) => a + (b - a) * (1f - Mathf.Pow(1f - f, dt));

    void LateUpdate()
    {
        if (alvo == null) return;
        float dt = Mathf.Min(Time.unscaledDeltaTime * 60f, 2.5f);
        zoomAtual = LerpDt(zoomAtual, zoom, 0.12f, dt);
        cam.orthographicSize = ALTURA / 2f / zoomAtual;
        float h = ALTURA / zoomAtual, w = h * cam.aspect;

        if (Mathf.Abs(alvo.VelH) > 0.5f) frenteAlvo = Mathf.Sign(alvo.VelH) * 28f;
        if (snap) { frenteAlvo = alvo.facing * 28f; frente = frenteAlvo; }
        else
        {
            float falta = frenteAlvo - frente;
            float passo = Mathf.Min(Mathf.Abs(falta) * 0.05f + 0.05f, 0.85f) * dt;
            frente += Mathf.Clamp(falta, -passo, passo);
        }
        float tx = Mathf.Clamp(alvo.x + frente - w / 2f, 0, Mundo.SALA_W - w);
        // arena fechada (mini-chefe / chefe): a câmera fica entre as muralhas
        float lo = Mathf.Max(0, Arena.limEsq), hi = Mathf.Min(Mundo.SALA_W, Arena.limDir);
        tx = hi - lo <= w ? Mathf.Clamp((lo + hi) / 2f - w / 2f, 0, Mundo.SALA_W - w) : Mathf.Clamp(tx, lo, hi - w);
        float ty = Mathf.Clamp(alvo.y - h * 0.64f, 0, Mundo.SALA_H - h);
        if (snap) { camX = tx; camY = ty; snap = false; }
        else { camX = LerpDt(camX, tx, 0.12f, dt); camY = LerpDt(camY, ty, 0.10f, dt); }
        vistaX1 = camX; vistaX2 = camX + w; TopoVista = camY;

        float sx = empurraX, sy = 0;
        empurraX = LerpDt(empurraX, 0, 0.2f, dt);
        if (tremor > 0.05f)
        {
            sx += Random.Range(-tremor, tremor) * 0.6f; sy = Random.Range(-tremor, tremor) * 0.4f;
            tremor = LerpDt(tremor, 0, 0.18f, dt);
        }
        // presa à grade de render (1/k px): a pixel art não tremula ao andar
        float px = Mathf.Round((camX + w / 2f + sx) * k) / k;
        float py = Mathf.Round((-(camY + h / 2f) + sy) * k) / k;
        transform.position = new Vector3(px, py, -10f);
    }
}
