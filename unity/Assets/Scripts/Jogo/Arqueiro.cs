// =====================================================================
//  Arqueiro — arqueiro esqueleto (obj_inimigo_02)
//  · só atira de longe e só quando está na tela (o campo de visão é a câmera)
//  · foge quando Twilight chega perto; se encurralado, atira mais cedo
//  · estados: parado, fugir, aproximar, atirar
//  Flecha — obj_flecha: voa em arco; DEFESA a faz ricochetear, APARAR a
//  devolve contra os inimigos (60% da vida de quem ela acertar).
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class Arqueiro : Inimigo
{
    const float ESCALA = 1.6f, VEL_FLECHA = 8f, DIST_FUGA = 170f, DIST_SEGURA = 320f, DIST_IDEAL = 300f, DIST_MAX = 430f;
    const float VEL_FUGA = 2.7f, VEL_APROXIMAR = 2.2f;
    bool flechaSolta, viu;

    protected override void Configurar()
    {
        mw = 7f * ESCALA; mh = 36f * ESCALA;     // spr_mascara_arqueiro (14 x 36) na escala da sala
        escalaVis = ESCALA; topoVis = 36f * ESCALA + 8f;
        vidaBase = 30f; danoBase = 5f; orbs = 8;
        recargaMax = 420f;                       // 7 s entre flechas
        velAtordoado = 1.4f;
    }

    protected override void Awake()
    {
        base.Awake();
        dir = -1f;
    }

    protected override void Reagir(float d, float forca)
    {
        empurrao = d * forca * 0.3f;
        Atordoar(26);
        if (vida <= 0) Morrer(d);
    }

    protected override void AposAtordoado(bool dentroCampo, float adx) => estado = adx < DIST_FUGA ? "fugir" : "parado";

    bool PodeFugir(float d)
    {
        float nx = x + d * 32f;
        return !Bate(nx, y - 2) && nx >= 48f && nx <= Mundo.SALA_W - 48f;
    }

    protected override void Agir(Jogador p, float dx, float dy, float adx, bool dentroCampo, bool noChao, bool temAlvo, float dt)
    {
        if (recarga <= 0 && estado == "parado" && !viu) recarga = Random.Range(90, 200);
        bool ve = temAlvo && CameraVallack.NaTela(x, 0f);
        if (ve && !viu) { viu = true; alertaFx = 40; recarga = Random.Range(60, 140); }
        switch (estado)
        {
            case "perseguir":
            case "parado":
                estado = "parado";
                velh = 0;
                an.Tocar(aParado, false);
                if (temAlvo && viu && adx > DIST_MAX && adx < 900 && Mathf.Abs(dy) < 200) estado = "aproximar";
                else if (ve)
                {
                    Virar(dx, false, dt);
                    float ladoFuga = dx >= 0 ? -1f : 1f;
                    if (adx < DIST_FUGA && PodeFugir(ladoFuga)) estado = "fugir";
                    else if (recarga <= 0 && Mathf.Abs(dy) < 160 && Flecha.voando < 2)
                    {
                        estado = "atirar"; flechaSolta = false;
                        an.Tocar(aAtaque, true, 1.8f);
                    }
                }
                break;
            case "fugir":
                {
                    float fuga = dx >= 0 ? -1f : 1f;
                    if (!temAlvo || adx >= DIST_SEGURA || !PodeFugir(fuga))
                    {
                        if (temAlvo && !PodeFugir(fuga)) recarga = Mathf.Min(recarga, 70);     // encurralado: atira logo
                        estado = "parado"; velh = 0;
                        if (temAlvo) Virar(dx, true, dt);
                    }
                    else
                    {
                        dir = fuga;
                        VelhPara(fuga * VEL_FUGA, 0.4f, 0.6f, dt);
                        an.Tocar(aCorrer, false, 1.3f);
                    }
                }
                break;
            case "aproximar":
                if (!temAlvo || adx <= DIST_IDEAL || Mathf.Abs(dy) >= 200) { estado = "parado"; velh = 0; recarga = Mathf.Min(recarga, 100); }
                else
                {
                    Virar(dx, true, dt);
                    if (Bate(x + dir * 12, y - 2)) { estado = "parado"; velh = 0; }
                    else { VelhPara(dir * VEL_APROXIMAR, 0.4f, 0.6f, dt); an.Tocar(aCorrer, false, 1.3f); }
                }
                break;
            case "atirar":
                velh = 0;
                an.Velocidade = 1.8f;
                if (!flechaSolta && an.Indice >= 5f)
                {
                    flechaSolta = true;
                    Disparar(x + dir * 17f * ESCALA, y - 21f * ESCALA, temAlvo ? p : null);
                }
                if (an.Terminou || (flechaSolta && an.Indice < 1f))
                {
                    estado = "parado"; recarga = recargaMax;
                    an.Tocar(aParado, true);
                }
                break;
        }
    }

    void Disparar(float bx, float by, Jogador alvo)
    {
        Efeitos.Som(Efeitos.Sons?.flecha, 0.7f);
        float tx = bx + dir * 300f, ty = by;
        if (alvo != null) { tx = alvo.x; ty = alvo.y - 34f; }
        float dist = Vector2.Distance(new Vector2(bx, by), new Vector2(tx, ty));
        float tempo = dist / VEL_FLECHA;
        ty -= 0.5f * 0.05f * tempo * tempo;          // compensa a queda da flecha
        var v = new Vector2(tx - bx, ty - by).normalized * VEL_FLECHA;
        Flecha.Criar(bx, by, v.x, v.y, danoBase, ESCALA * 0.85f, aditivo, alfa);
    }
}

public class Flecha : MonoBehaviour
{
    public static int voando;
    float x, y, vx, vy, dano, alcance = 700f, dist, vida, vidaMax = 1f, ang, giro, escala;
    string estado = "voando";
    SpriteRenderer haste, ponta, pena, aura;

    public static void Criar(float x, float y, float vx, float vy, float dano, float escala, Material aditivo, Material alfa)
    {
        var go = new GameObject("flecha");
        var f = go.AddComponent<Flecha>();
        f.x = x; f.y = y; f.vx = vx; f.vy = vy; f.dano = dano; f.escala = escala;
        f.haste = Parte(go.transform, Texturas.Branco(), alfa, new Color32(215, 196, 160, 255), 121);
        f.ponta = Parte(go.transform, Texturas.Branco(), alfa, new Color32(150, 150, 160, 255), 122);
        f.pena = Parte(go.transform, Texturas.Branco(), alfa, new Color32(200, 40, 40, 255), 122);
        f.aura = Parte(go.transform, Texturas.Brilho(), aditivo, new Color(0.43f, 0.7f, 1f, 0.7f), 120);
        float c = 12f * escala;
        f.haste.transform.localPosition = new Vector3(-c, -1f, 0); f.haste.transform.localScale = new Vector3(c * 2f, 2f, 1f);
        f.ponta.transform.localPosition = new Vector3(c, -2f, 0); f.ponta.transform.localScale = new Vector3(4f * escala, 4f, 1f);
        f.pena.transform.localPosition = new Vector3(-c - 2f, -2.5f, 0); f.pena.transform.localScale = new Vector3(5f * escala, 5f, 1f);
        f.aura.transform.localScale = new Vector3(c * 3.2f, 14f, 1f);
        f.aura.enabled = false;
        voando++;
    }

    static SpriteRenderer Parte(Transform pai, Sprite s, Material m, Color c, int ordem)
    {
        var go = new GameObject("parte");
        go.transform.SetParent(pai, false);
        var r = go.AddComponent<SpriteRenderer>();
        r.sprite = s; r.sharedMaterial = m; r.color = c; r.sortingOrder = ordem;
        return r;
    }

    void OnDestroy() { voando = Mathf.Max(0, voando - 1); }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt > 0) Passo(dt);
        transform.SetPositionAndRotation(Mundo.Tela(x, y), Quaternion.Euler(0, 0, -ang));
        float a = (estado == "voando" || estado == "refletida") ? 1f : Mathf.Clamp01(vida / Mathf.Max(1, vidaMax) * 1.5f);
        foreach (var r in new[] { haste, ponta, pena }) { var c = r.color; c.a = a; r.color = c; }
        aura.enabled = estado == "refletida";
    }

    void Passo(float dt)
    {
        float vel = Mathf.Sqrt(vx * vx + vy * vy);
        switch (estado)
        {
            case "voando":
                {
                    vy += 0.05f * dt;
                    x += vx * dt; y += vy * dt; dist += vel * dt;
                    ang = Mathf.Atan2(vy, vx) * Mathf.Rad2Deg;
                    float px = x + Mathf.Cos(ang * Mathf.Deg2Rad) * 12f * escala, py = y + Mathf.Sin(ang * Mathf.Deg2Rad) * 12f * escala;
                    var p = Jogador.eu;
                    if (p != null && !p.morto && !p.Intangivel() && px > p.Esq && px < p.Dir && py > p.Topo && py < p.y)
                    {
                        bool deFrente = Mathf.Sign(x - p.x) == p.facing;
                        if (p.Aparando && deFrente)
                        {
                            // APARADA: a flecha volta contra quem atirou
                            p.AparouProjetil();
                            estado = "refletida";
                            vx = -vx * 1.2f; vy = -vy * 0.3f - 0.4f;
                            dist = 0; alcance = 700f;
                            return;
                        }
                        if (p.Bloqueando && deFrente)
                        {
                            p.BloqueouProjetil(x);
                            estado = "ricochete";
                            vx = -vx * 0.35f; vy = -3.2f;
                            giro = 20f * Mathf.Sign(vx == 0 ? 1f : vx);
                            vida = vidaMax = 50f;
                        }
                        else { p.LevarDano(dano, x, true, 2f, null); Destroy(gameObject); }
                    }
                    else if (Mundo.Colide(px - 0.5f, py - 0.5f, px + 0.5f, py + 0.5f)) { estado = "cravada"; vida = vidaMax = 120f; }
                    else if (dist >= alcance || y > Mundo.SALA_H + 50f) { estado = "caindo"; vida = vidaMax = 30f; }
                }
                break;
            case "refletida":
                {
                    vy += 0.02f * dt;
                    x += vx * dt; y += vy * dt; dist += vel * dt;
                    ang = Mathf.Atan2(vy, vx) * Mathf.Rad2Deg;
                    float rx = x + Mathf.Cos(ang * Mathf.Deg2Rad) * 12f * escala, ry = y + Mathf.Sin(ang * Mathf.Deg2Rad) * 12f * escala;
                    foreach (var e in Inimigo.todos)
                    {
                        if (e.morrendo || !e.ativo || !e.Toca(rx - 1, ry - 1, rx + 1, ry + 1)) continue;
                        if (e.LevarDano(Mathf.Max(1, Mathf.Round(e.vidaMax * 0.6f)), x - vx, 5f, null, true) && !e.morrendo) e.Atordoar(80, true);
                        Efeitos.Faiscas(rx, ry, 1f);
                        Efeitos.SomHit(false);
                        Destroy(gameObject);
                        return;
                    }
                    if (Mundo.Colide(rx - 0.5f, ry - 0.5f, rx + 0.5f, ry + 0.5f)) { estado = "cravada"; vida = vidaMax = 120f; }
                    else if (dist >= alcance) { estado = "caindo"; vida = vidaMax = 30f; }
                }
                break;
            case "ricochete":
                vy += 0.3f * dt;
                x += vx * dt; y += vy * dt; ang += giro * dt;
                if (Mundo.Colide(x - 0.5f, y - 0.5f, x + 0.5f, y + 0.5f)) { vx *= 0.5f; vy = 0; giro *= 0.5f; }
                vida -= dt;
                if (vida <= 0) Destroy(gameObject);
                break;
            case "cravada":
                vida -= dt;
                if (vida <= 0) Destroy(gameObject);
                break;
            case "caindo":
                vy += 0.25f * dt;
                x += vx * 0.5f * dt; y += vy * dt;
                vida -= dt;
                if (vida <= 0) Destroy(gameObject);
                break;
        }
    }
}
