// =====================================================================
//  MedidorFps — mostra FPS médio, pior quadro e a resolução na tela e no
//  log (marca [fps], lida pelo adb logcat no PC). Fica nas cenas de teste.
// =====================================================================
using UnityEngine;

public class MedidorFps : MonoBehaviour
{
    float acc, pior, logT;
    int n;
    string texto = "";
    GUIStyle estilo;

    void Start()
    {
        Application.targetFrameRate = 60;
        QualitySettings.vSyncCount = 0;     // no Android o ritmo vem do targetFrameRate
    }

    void Update()
    {
        float dt = Time.unscaledDeltaTime;
        acc += dt; n++; pior = Mathf.Max(pior, dt);
        logT += dt;
        if (acc >= 1f)
        {
            texto = $"{n / acc:0} FPS · pior {pior * 1000f:0} ms · {Screen.width}x{Screen.height} · {SystemInfo.graphicsDeviceName}";
            if (logT >= 4f) { Debug.Log("[fps] " + texto); logT = 0; }
            acc = 0; n = 0; pior = 0;
        }
    }

    public static bool mostrar = true;

    void OnGUI()
    {
        if (!mostrar) return;
        if (estilo == null)
        {
            estilo = new GUIStyle(GUI.skin.label) { fontSize = Mathf.RoundToInt(Screen.height * 0.035f) };
            estilo.normal.textColor = new Color(0.55f, 1f, 0.6f);
        }
        GUI.Label(new Rect(Screen.width * 0.42f, 12, Screen.width * 0.58f, Screen.height * 0.06f), texto, estilo);
    }
}
