// =====================================================================
//  Coleta — o que os inimigos e caixotes soltam e voa até Twilight:
//  · ORB de alma (vermelha): moeda da evolução da espada (obj_orb)
//  · ORB de vida (verde): cura ao chegar
//  · ESSÊNCIA (azul): munição das sub-armas, até 9 (obj_essencia)
//  · SANGUE: gotas que voam para a lâmina e enchem a FÚRIA (obj_sangue)
//  Saltam um pouco, quicam no chão e depois voam sozinhas, acelerando.
//  SubArmas: LÂMINA BUMERANGUE e CHAMA DE SYLLA.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class Coleta : MonoBehaviour
{
    public enum Tipo { Alma, Vida, Essencia, Sangue }
    static Material aditivo;
    static float somT; static int seq;

    Tipo tipo; float valor, x, y, vx, vy, t, espera = 20f, fase;
    SpriteRenderer nucleo, halo;

    public static void Preparar(Material mat) { aditivo = mat; }

    // solta orbs num ponto: viram bolinhas que voam sozinhas até o jogador
    public static void Orbs(float px, float py, float total)
    {
        int t = Mathf.RoundToInt(total);
        while (t > 0)
        {
            int v = t >= 50 ? 25 : (t >= 10 ? 5 : 1);
            t -= v;
            Criar(Tipo.Alma, px, py, v);
        }
    }
    public static void Essencia(float px, float py, int n) { for (int i = 0; i < n; i++) Criar(Tipo.Essencia, px, py, 1); }
    public static void Sangue(float px, float py, int n) { for (int i = 0; i < n; i++) Criar(Tipo.Sangue, px, py, 1).espera = Random.Range(6f, 16f); }
    public static void Vida(float px, float py, float cura) { Criar(Tipo.Vida, px, py, cura); }

    static Coleta Criar(Tipo tipo, float px, float py, float valor)
    {
        var go = new GameObject("coleta " + tipo);
        var c = go.AddComponent<Coleta>();
        c.tipo = tipo; c.valor = valor;
        c.x = px + Random.Range(-6f, 6f); c.y = py + Random.Range(-6f, 6f);
        c.vx = Random.Range(-2.2f, 2.2f); c.vy = Random.Range(-4.2f, -2f);
        c.fase = Random.value * 100f;
        c.halo = Parte(go.transform, Texturas.Brilho(), 124);
        c.nucleo = Parte(go.transform, Texturas.Disco(), 125);
        return c;
    }

    static SpriteRenderer Parte(Transform pai, Sprite s, int ordem)
    {
        var go = new GameObject("p");
        go.transform.SetParent(pai, false);
        var r = go.AddComponent<SpriteRenderer>();
        r.sprite = s; r.sharedMaterial = aditivo; r.sortingOrder = ordem;
        return r;
    }

    float Raio => tipo == Tipo.Vida ? 4.2f : (tipo == Tipo.Essencia ? 3.4f : (tipo == Tipo.Sangue ? 1.8f : (valor >= 25 ? 5f : (valor >= 5 ? 3.6f : 2.4f))));

    void Update()
    {
        float dt = Tempo.Dt;
        if (Time.frameCount != ultimoQuadro)
        {
            // um relógio só para todas as orbs: espaça os sons e zera a escala quando param de chegar
            ultimoQuadro = Time.frameCount;
            somT -= Tempo.DtReal;
            if (somT < -30f) seq = 0;
        }
        if (dt > 0 && Passo(dt)) { Destroy(gameObject); return; }
        float r = Raio, pul = 1f + 0.15f * Mathf.Sin((Time.time * 60f + fase) / 5f);
        transform.position = Mundo.Tela(x, y);
        Color c = tipo == Tipo.Vida ? new Color(0.35f, 1f, 0.47f) : (tipo == Tipo.Essencia ? new Color(0.45f, 0.75f, 1f) : (tipo == Tipo.Sangue ? new Color(0.9f, 0.08f, 0.1f) : new Color(1f, 0.27f, 0.2f)));
        nucleo.transform.localScale = Vector3.one * r * 2f * pul;
        nucleo.color = c;
        halo.transform.localScale = Vector3.one * r * 5f * pul;
        halo.color = new Color(c.r, c.g, c.b, 0.5f);
    }

    bool Passo(float dt)
    {
        t += dt;
        var p = Jogador.eu;
        float r = Raio;
        if (t < espera || p == null || p.morto)
        {
            // pula e quica no chão
            vy += 0.25f * dt;
            vx *= Mathf.Pow(0.97f, dt);
            if (Mundo.Colide(x + vx * dt - 1, y - 1, x + vx * dt + 1, y + 1)) vx = -vx * 0.5f;
            if (vy > 0 && Mundo.Colide(x - 0.5f, y + vy * dt + r - 0.5f, x + 0.5f, y + vy * dt + r + 0.5f))
            {
                vy = -Mathf.Abs(vy) * 0.45f;
                if (Mathf.Abs(vy) < 0.8f) vy = 0;
            }
            x += vx * dt; y += vy * dt;
            return y > Mundo.SALA_H + 200f;
        }
        // voa até o peito de Twilight, acelerando
        float tx = p.x, ty = p.MeioY;
        float d = Vector2.Distance(new Vector2(x, y), new Vector2(tx, ty));
        float v = Mathf.Min(14f, 3f + (t - espera) * 0.25f);
        if (d <= v * dt + 6f)
        {
            switch (tipo)
            {
                case Tipo.Vida:
                    p.vida = Mathf.Min(p.vidaMax, p.vida + valor);
                    if (somT <= 0) { Efeitos.Tocar("sfx_cura", 0.4f); somT = 4; }
                    break;
                case Tipo.Essencia:
                    if (Jogo.essencia < Jogo.ESSENCIA_MAX) Jogo.essencia++;
                    Efeitos.Tocar("essencia", 0.5f);
                    break;
                case Tipo.Sangue:
                    p.FuriaGanhar(1f);
                    break;
                default:
                    Jogo.orbs += Mathf.RoundToInt(valor);
                    // o som em sequência sobe de tom
                    if (somT <= 0) { seq = Mathf.Min(seq + 1, 10); Efeitos.Tocar("sfx_orb", 0.45f, 0f, 1f + seq * 0.04f); somT = 3; }
                    break;
            }
            return true;
        }
        var dirv = new Vector2(tx - x, ty - y).normalized * v;
        vx = Mathf.Lerp(vx, dirv.x, 0.2f); vy = Mathf.Lerp(vy, dirv.y, 0.2f);
        x += vx * dt; y += vy * dt;
        return false;
    }

    static int ultimoQuadro;
}

// LÂMINA BUMERANGUE (1 essência): gira para a frente, freia, volta para
// Twilight e acerta cada inimigo uma vez na ida e uma na volta.
public class Bumerangue : MonoBehaviour
{
    public static bool ativo;
    float x, y, dir, vel = 10.5f, t, ang;
    bool volta;
    readonly HashSet<Inimigo> atingidos = new HashSet<Inimigo>();
    readonly HashSet<object> objs = new HashSet<object>();
    Transform lamina;

    public static void Criar(float x, float y, float dir, Material aditivo)
    {
        var go = new GameObject("bumerangue");
        var b = go.AddComponent<Bumerangue>();
        b.x = x; b.y = y; b.dir = dir;
        var halo = go.AddComponent<SpriteRenderer>();
        halo.sprite = Texturas.Brilho(); halo.sharedMaterial = aditivo; halo.sortingOrder = 116; halo.color = new Color(1f, 0.82f, 0.47f, 0.5f);
        go.transform.localScale = Vector3.one * 38f;
        var l = new GameObject("lâmina");
        l.transform.SetParent(go.transform, false);
        var sr = l.AddComponent<SpriteRenderer>();
        sr.sprite = Texturas.Branco(); sr.sharedMaterial = aditivo; sr.sortingOrder = 117; sr.color = new Color(0.9f, 0.92f, 0.96f, 1f);
        l.transform.localScale = new Vector3(0.75f, 0.1f, 1f);
        l.transform.localPosition = new Vector3(-0.37f, -0.05f, 0);
        b.lamina = go.transform;
        ativo = true;
    }

    void OnDestroy() { ativo = false; }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt > 0)
        {
            t += dt; ang -= dir * 26f * dt;
            if (!volta)
            {
                x += dir * vel * dt; vel -= 0.42f * dt;
                if (vel <= 0 || Mundo.Colide(x + dir * 10 - 2, y - 2, x + dir * 10 + 2, y + 2) || x < 0 || x > Mundo.SALA_W) { volta = true; atingidos.Clear(); objs.Clear(); vel = 2; }
            }
            else
            {
                var p = Jogador.eu;
                if (p == null) { Destroy(gameObject); return; }
                vel = Mathf.Min(12f, vel + 0.5f * dt);
                var alvo = new Vector2(p.x, p.y - 40);
                var d = alvo - new Vector2(x, y);
                if (d.magnitude < vel * dt + 14f) { Destroy(gameObject); return; }
                d = d.normalized * vel * dt; x += d.x; y += d.y;
            }
            if (t > 240) { Destroy(gameObject); return; }
            foreach (var e in Inimigo.todos)
            {
                if (atingidos.Contains(e) || e.morrendo || !e.ativo || !e.Toca(x - 16, y - 14, x + 16, y + 14)) continue;
                atingidos.Add(e);
                if (e.LevarDano(Mathf.Max(1, Mathf.Round(12f * Jogo.EspadaDanoMult)), x, 1.5f, null) && !e.morrendo && !e.ehChefe) e.Atordoar(20);
                Efeitos.Faiscas(e.x, e.MeioY, 0.7f);
                Efeitos.SomHit(false);
                Tempo.Impacto(1);
            }
            Destrutivel.Bater(x - 16, y - 14, x + 16, y + 14, 1, x, objs);
        }
        lamina.SetPositionAndRotation(Mundo.Tela(x, y), Quaternion.Euler(0, 0, ang));
    }
}

// CHAMA DE SYLLA (2 essências): chama sagrada dourada no chão à frente de
// Twilight; queima os inimigos que passam por ela durante 4 s.
public class ChamaSylla : MonoBehaviour
{
    float x, y, dir, t, tick, acc;
    const float VIDA = 240f;

    public static void Criar(float x, float y, float dir)
    {
        var c = new GameObject("chama de Sylla").AddComponent<ChamaSylla>();
        c.x = x; c.y = y; c.dir = dir;
    }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt <= 0) return;
        t += dt; tick -= dt;
        float x1 = Mathf.Min(x, x + dir * 90) - 16, x2 = Mathf.Max(x, x + dir * 90) + 16;
        if (tick <= 0)
        {
            tick = 24;
            foreach (var e in Inimigo.todos)
            {
                if (e.morrendo || !e.ativo || !e.Toca(x1, y - 46, x2, y)) continue;
                if (e.LevarDano(Mathf.Max(1, Mathf.Round(6f * Jogo.EspadaDanoMult)), x, 0.5f, null) && !e.morrendo && !e.ehChefe) e.Atordoar(12);
            }
        }
        acc += dt * 1.4f;
        while (acc >= 1f) { acc -= 1f; Efeitos.ChamaDourada(Random.Range(x1 + 10, x2 - 10), y, Mathf.Clamp01(Mathf.Min(t / 10f, (VIDA - t) / 30f))); }
        if (t >= VIDA) Destroy(gameObject);
    }
}
