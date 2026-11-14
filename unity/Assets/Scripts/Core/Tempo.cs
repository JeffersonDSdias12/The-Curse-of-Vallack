// =====================================================================
//  Tempo — o relógio do jogo: "quadros de 60 FPS" (G.dt do original) com
//  a PAUSA DE IMPACTO (hitstop: o mundo congela alguns quadros quando um
//  golpe pega) e a CÂMERA LENTA (aparar, golpe fatal, morte).
//  Usa Time.timeScale, então partículas e animações congelam junto; a
//  câmera e a interface seguem no tempo real.
// =====================================================================
using UnityEngine;

[DefaultExecutionOrder(-200)]
public class Tempo : MonoBehaviour
{
    public static float Dt;             // quadros de jogo deste frame (0 durante a pausa de impacto)
    public static float DtReal;         // quadros reais (sem pausa nem câmera lenta)
    public static bool pausado;         // menus por cima do jogo
    public static int combo;            // golpes seguidos (HUD)
    public static float comboTempo;

    static float parar, lentaT, lentaEsc = 1f, fatalT;

    // impacto(n) do original: congela n quadros
    public static void Impacto(float quadros) => parar = Mathf.Max(parar, quadros);

    // camera_lenta(quadros, escala)
    public static void Lenta(float quadros, float escala)
    {
        if (quadros >= lentaT) { lentaT = quadros; lentaEsc = escala; }
    }

    // GOLPE FATAL: a câmera lenta tem intervalo, para não arrastar as hordas
    public static bool FatalLivre()
    {
        if (fatalT > 0) return false;
        fatalT = 75;
        return true;
    }

    public static void Golpe() { combo++; comboTempo = 120; }

    void Awake() { parar = lentaT = fatalT = 0; combo = 0; Time.timeScale = 1f; }

    void Update()
    {
        float r = Mathf.Min(Time.unscaledDeltaTime * 60f, 2.5f);
        DtReal = r;
        if (fatalT > 0) fatalT -= r;
        if (pausado) { Time.timeScale = 0f; Dt = 0f; return; }
        float esc = 1f;
        if (parar > 0) { parar -= r; esc = 0f; }
        else if (lentaT > 0) { lentaT -= r; esc = lentaEsc; }
        Time.timeScale = esc;
        Dt = r * esc;
        if (comboTempo > 0) { comboTempo -= Dt; if (comboTempo <= 0) combo = 0; }
    }

    void OnDestroy() { Time.timeScale = 1f; }
}
