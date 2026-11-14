// =====================================================================
//  Armadilhas da Vila em Chamas:
//  · Espinhos (obj_espinhos): saem do chão em ciclos — baixo → aviso
//    (tremem e soltam poeira) → alto (ferem) → descendo
//  · FogoChao (obj_fogo_chao): destroços queimando; sempre baixo e, a cada
//    3 s, as chamas sobem por 1 s (mais dano)
//  · VigaFogo (obj_viga_fogo): viga em chamas que cai do telhado quando
//    Twilight passa — aviso → queda → queimando → cinzas
//  Também ferem os inimigos que passarem por elas.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public static class Armadilha
{
    // fere Twilight (sem defesa) e os inimigos dentro da área; cada inimigo 1x por lista
    public static void Area(float x1, float y1, float x2, float y2, float danoJogador, float danoInimigo, HashSet<Inimigo> lista, float forca = 4f)
    {
        var p = Jogador.eu;
        if (p != null && !p.morto && p.Toca(x1, y1, x2, y2))
        {
            float antes = p.vida;
            p.LevarDano(Mathf.Max(1, Mathf.Round(danoJogador)), (x1 + x2) / 2f, false, forca, null);
            if (p.vida < antes && !p.morto) p.velv = Mathf.Min(p.velv, -3f);
        }
        if (danoInimigo <= 0) return;
        foreach (var e in Inimigo.todos)
        {
            if (e.morrendo || !e.ativo || e.ehChefe || lista.Contains(e) || !e.Toca(x1, y1, x2, y2)) continue;
            lista.Add(e);
            e.LevarDano(danoInimigo, (x1 + x2) / 2f, 3f, null);
        }
    }

    public static SpriteRenderer Parte(Transform pai, Sprite s, Material m, int ordem)
    {
        var go = new GameObject("p"); go.transform.SetParent(pai, false);
        var r = go.AddComponent<SpriteRenderer>(); r.sprite = s; r.sharedMaterial = m; r.sortingOrder = ordem;
        return r;
    }
}

public class Espinhos : MonoBehaviour
{
    float x, y, t, sobe;
    string estado = "baixo";
    readonly HashSet<Inimigo> atingidos = new HashSet<Inimigo>();
    SpriteRenderer sr;

    public static void Criar(float x, float y, SpriteAnim anim, Material lit)
    {
        var e = new GameObject("espinhos").AddComponent<Espinhos>();
        e.x = x; e.y = y; e.t = x % 97f;
        e.sr = Armadilha.Parte(e.transform, anim != null ? anim.Quadro(0) : Texturas.Branco(), lit, 66);
        e.transform.position = Mundo.Tela(x, y);
    }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt <= 0) return;
        t += dt;
        switch (estado)
        {
            case "baixo":
                sobe = Mathf.Max(0, sobe - 0.2f * dt);
                if (t >= 110) { estado = "aviso"; t = 0; }
                break;
            case "aviso":
                sobe = 0.18f + 0.06f * Mathf.Sin(t * 1.3f);
                if (Random.value < 0.25f * dt) Efeitos.Poeira(x + Random.Range(-12f, 12f), y, 0.25f);
                if (t >= 38) { estado = "alto"; t = 0; atingidos.Clear(); if (CameraVallack.NaTela(x, -60f)) Efeitos.Tocar("sfx_espinhos", 0.8f); }
                break;
            case "alto":
                sobe = Mathf.Min(1, sobe + 0.35f * dt);
                if (sobe > 0.6f) Armadilha.Area(x - 24, y - 22 * sobe, x + 24, y, 14, 30, atingidos, 3);
                if (t >= 70) { estado = "descendo"; t = 0; }
                break;
            case "descendo":
                sobe = Mathf.Max(0, sobe - 0.08f * dt);
                if (sobe <= 0) { estado = "baixo"; t = 0; }
                break;
        }
        // os espinhos sobem do chão (escala 1,6 do original)
        sr.transform.localScale = new Vector3(1.6f, 1.6f * Mathf.Max(0.02f, sobe), 1f);
        sr.enabled = sobe > 0.01f;
    }
}

public class FogoChao : MonoBehaviour
{
    float x, y, larg, t, forte, acc;
    readonly HashSet<Inimigo> atingidos = new HashSet<Inimigo>(), baixo = new HashSet<Inimigo>();
    SpriteRenderer brilho;

    public static void Criar(float x, float y, float blocos, Material aditivo)
    {
        var f = new GameObject("fogo no chão").AddComponent<FogoChao>();
        f.x = x; f.y = y; f.larg = 32f * Mathf.Max(1f, blocos); f.t = x % 131f;
        f.brilho = Armadilha.Parte(f.transform, Texturas.Brilho(), aditivo, 67);
        f.transform.position = Mundo.Tela(x, y);
    }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt <= 0) return;
        t += dt;
        // a cada 3 s as chamas sobem por 1 s
        float ciclo = t % 180f;
        forte = Mathf.Lerp(forte, ciclo > 130 ? 1f : 0.35f, 0.15f);
        bool naTela = CameraVallack.NaTela(x, -120f);
        if (ciclo < dt) { atingidos.Clear(); if (naTela) Efeitos.Tocar("fogo_whoosh", 0.55f); }
        if (forte > 0.6f) Armadilha.Area(x - larg / 2, y - 40 * forte, x + larg / 2, y, 12, 20, atingidos, 3);
        else if (Mathf.Floor((t - dt) / 50f) != Mathf.Floor(t / 50f)) { baixo.Clear(); Armadilha.Area(x - larg / 2 + 4, y - 12, x + larg / 2 - 4, y, 4, 0, baixo, 1); }
        if (naTela)
        {
            acc += dt * (0.5f + forte) * larg / 32f;
            while (acc >= 1f) { acc -= 1f; Efeitos.ChamaComum(Random.Range(x - larg / 2, x + larg / 2), y, forte); }
        }
        float pu = 0.8f + 0.2f * Mathf.Sin(Time.time * 9f);
        brilho.transform.localPosition = new Vector3(0, 6f, 0);
        brilho.transform.localScale = new Vector3(larg * 1.6f, 30f + 40f * forte, 1f);
        brilho.color = new Color(1f, 0.45f, 0.15f, (0.2f + 0.25f * forte) * pu);
    }
}

public class VigaFogo : MonoBehaviour
{
    float x, yChao, yViga, vy, ang, t, queima, acc;
    string estado = "esperando";
    readonly HashSet<Inimigo> atingidos = new HashSet<Inimigo>();
    SpriteRenderer viga, sombra, brilho;

    public static void Criar(float x, float y, Material lit, Material aditivo, Material alfa)
    {
        var v = new GameObject("viga em chamas").AddComponent<VigaFogo>();
        v.x = x; v.yChao = y; v.yViga = y - 320; v.ang = Random.Range(-10f, 10f);
        v.sombra = Armadilha.Parte(v.transform, Texturas.Brilho(), alfa, 65);
        v.viga = Armadilha.Parte(v.transform, Texturas.Madeira(), lit, 84);
        v.viga.drawMode = SpriteDrawMode.Tiled; v.viga.size = new Vector2(80f, 12f);
        v.brilho = Armadilha.Parte(v.transform, Texturas.Brilho(), aditivo, 85);
        v.viga.enabled = v.sombra.enabled = v.brilho.enabled = false;
    }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt <= 0) return;
        t += dt;
        var p = Jogador.eu;
        switch (estado)
        {
            case "esperando":
                if (p != null && !p.morto && Mathf.Abs(p.x - x) < 150 && Mathf.Abs(p.y - yChao) < 120)
                {
                    estado = "aviso"; t = 0; yViga = CameraVallack.TopoVista - 30;
                    Efeitos.Tocar("viga_aviso", 1f); Efeitos.Tocar("fogo_whoosh", 0.7f);
                }
                break;
            case "aviso":
                if (Random.value < 0.5f * dt) Efeitos.Faiscas(x + Random.Range(-30f, 30f), yViga + 30, 0.4f, 3);
                if (Random.value < 0.3f * dt) Efeitos.Poeira(x + Random.Range(-30f, 30f), yViga + 40, 0.3f);
                if (t >= 48) { estado = "caindo"; t = 0; vy = 2; }
                break;
            case "caindo":
                vy = Mathf.Min(vy + 0.55f * dt, 16f);
                yViga += vy * dt;
                ang = Mathf.Lerp(ang, 0, 0.05f);
                if (yViga >= yChao - 7)
                {
                    yViga = yChao - 7; estado = "queimando"; t = 0; atingidos.Clear();
                    Armadilha.Area(x - 40, yChao - 60, x + 40, yChao, 20, 45, atingidos, 6);
                    Efeitos.Tocar("dest_viga", 1f); Efeitos.Tocar("fogo_explosao", 0.5f);
                    CameraVallack.Tremer(10f);
                    Efeitos.Poeira(x, yChao, 1.3f); Efeitos.Faiscas(x, yChao - 6, 1.2f, 14);
                }
                break;
            case "queimando":
                {
                    float antes = queima; queima += dt;
                    if (Mathf.Floor(antes / 45f) != Mathf.Floor(queima / 45f)) atingidos.Clear();
                    if (queima < 260) Armadilha.Area(x - 34, yChao - 16, x + 34, yChao, 6, 10, atingidos, 2);
                    acc += dt * 0.9f * Mathf.Clamp01(1f - queima / 300f);
                    while (acc >= 1f) { acc -= 1f; Efeitos.ChamaComum(Random.Range(x - 34f, x + 34f), yChao - 8, 0.7f); }
                    if (queima >= 360) { estado = "cinzas"; t = 0; }
                }
                break;
            case "cinzas":
                if (t >= 120) { Destroy(gameObject); return; }
                break;
        }
        bool ve = estado != "esperando";
        viga.enabled = ve; sombra.enabled = estado == "aviso" || estado == "caindo";
        brilho.enabled = estado == "caindo" || estado == "queimando";
        if (!ve) return;
        float cinza = estado == "cinzas" ? Mathf.Clamp01(1f - t / 120f) : 1f;
        viga.transform.SetPositionAndRotation(Mundo.Tela(x - 40f * Mathf.Cos(ang * Mathf.Deg2Rad), yViga + 6f), Quaternion.Euler(0, 0, ang));
        viga.color = estado == "cinzas" || queima > 200 ? new Color(0.25f, 0.2f, 0.2f, cinza) : Color.white;
        sombra.transform.position = Mundo.Tela(x, yChao);
        sombra.transform.localScale = new Vector3(90f, 10f, 1f);
        sombra.color = new Color(0, 0, 0, estado == "aviso" ? 0.25f + 0.25f * Mathf.Clamp01(t / 48f) : 0.5f);
        brilho.transform.position = Mundo.Tela(x, yViga);
        brilho.transform.localScale = new Vector3(120f, 60f, 1f);
        brilho.color = new Color(1f, 0.5f, 0.15f, 0.35f * Mathf.Clamp01(1f - queima / 300f));
    }
}
