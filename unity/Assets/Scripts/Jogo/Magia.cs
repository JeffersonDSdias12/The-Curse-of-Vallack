// =====================================================================
//  Magia — projéteis de magia dos inimigos (obj_magia)
//  "orbe" (estátua): persegue Twilight; a defesa segura, aparar devolve
//  "teia" (aranha): voa em arco e PRENDE; no chão vira armadilha pegajosa
//  "onda" (porco): corte roxo rente ao chão; não dá para defender
// =====================================================================
using UnityEngine;

public class Magia : MonoBehaviour
{
    string tipo = "orbe", estado = "voando";
    float x, y, vx, vy, dano, alcance = 900f, dist, t, ang = 180f, fimT, vidaChao, enredaQuadros = 90f;
    bool refletida, atingiu;
    Inimigo dono;
    SpriteRenderer corpo, aura;

    public static Magia Criar(string tipo, float x, float y, float vx, float vy, float dano, Inimigo dono, Material aditivo, Material alfa, Sprite orbe = null, float enreda = 90f)
    {
        var go = new GameObject("magia " + tipo);
        var m = go.AddComponent<Magia>();
        m.tipo = tipo; m.x = x; m.y = y; m.vx = vx; m.vy = vy; m.dano = dano; m.dono = dono; m.enredaQuadros = enreda;
        m.aura = Parte(go.transform, Texturas.Brilho(), aditivo, 118);
        m.corpo = Parte(go.transform, tipo == "orbe" && orbe != null ? orbe : (tipo == "teia" ? Texturas.Disco() : Texturas.Brilho()), tipo == "teia" ? alfa : aditivo, 119);
        if (tipo == "orbe" && orbe != null) m.corpo.transform.localScale = Vector3.one * 0.8f;
        return m;
    }

    static SpriteRenderer Parte(Transform pai, Sprite s, Material mat, int ordem)
    {
        var go = new GameObject("parte");
        go.transform.SetParent(pai, false);
        var r = go.AddComponent<SpriteRenderer>();
        r.sprite = s; r.sharedMaterial = mat; r.sortingOrder = ordem;
        return r;
    }

    void Estourar()
    {
        if (estado == "fim") return;
        estado = "fim"; fimT = 0; vx = vy = 0;
        if (tipo == "orbe") Efeitos.Som(Efeitos.Sons?.explosao, 0.45f);
        else if (tipo == "onda") Efeitos.Poeira(x, y, 0.5f);
    }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt > 0) Passo(dt);
        if (this == null) return;
        Desenhar();
    }

    void Passo(float dt)
    {
        t += dt;
        if (estado == "fim") { fimT += dt; if (fimT >= 16) Destroy(gameObject); return; }
        var p = Jogador.eu;
        bool vivo = p != null && !p.morto;
        bool intang = vivo && p.Intangivel();

        // TEIA GRUDADA NO CHÃO: armadilha pegajosa
        if (estado == "chao")
        {
            vidaChao -= dt;
            if (vidaChao <= 0) { Destroy(gameObject); return; }
            if (vivo && !intang && !p.Enredado && !p.TeiaImune && p.Toca(x - 22, y - 8, x + 22, y + 2)) { p.Enredar(45); vidaChao = Mathf.Min(vidaChao, 20); }
            return;
        }
        if (tipo == "orbe" && !refletida && t < 40 && vivo)
        {
            // o orbe persegue Twilight por um instante
            float alvoAng = Mathf.Atan2(p.y - 34 - y, p.x - x) * Mathf.Rad2Deg;
            float sp = Mathf.Sqrt(vx * vx + vy * vy), a = Mathf.Atan2(vy, vx) * Mathf.Rad2Deg;
            a += Mathf.Clamp(Mathf.DeltaAngle(a, alvoAng), -1.3f * dt, 1.3f * dt);
            vx = Mathf.Cos(a * Mathf.Deg2Rad) * sp; vy = Mathf.Sin(a * Mathf.Deg2Rad) * sp;
        }
        if (tipo == "teia") vy += 0.12f * dt;
        x += vx * dt; y += vy * dt;
        dist += Mathf.Sqrt(vx * vx + vy * vy) * dt;
        if (vx != 0 || vy != 0) ang = Mathf.Atan2(vy, vx) * Mathf.Rad2Deg;

        if (refletida)
        {
            // rebatida por Twilight: fere e prende os inimigos
            foreach (var e in Inimigo.todos)
            {
                if (e.morrendo || !e.ativo || !e.Toca(x - 8, y - 8, x + 8, y + 8)) continue;
                float pc = tipo == "teia" ? 0.15f : 0.5f;
                bool feriu = e.LevarDano(Mathf.Max(1, Mathf.Round(e.vidaMax * (e.ehChefe ? 0.03f : pc))), x - vx, 5f, null, true);
                if (feriu && !e.morrendo) e.Atordoar(tipo == "teia" ? 150f : 90f, true);
                if (e is Estatua est) est.Rachar();
                Efeitos.Faiscas(x, y, 1f);
                Efeitos.SomHit(false);
                Estourar();
                return;
            }
        }
        else if (vivo && !intang && !atingiu)
        {
            bool toca = tipo == "onda" ? p.Toca(x - 16, y - 30, x + 16, y) : (x > p.Esq - 5 && x < p.Dir + 5 && y > p.Topo - 5 && y < p.y + 5);
            if (toca)
            {
                bool frente = x == p.x || Mathf.Sign(x - p.x) == p.facing;
                // APARAR: volta contra quem lançou (a onda roxa não dá para aparar)
                if (tipo != "onda" && p.Aparando && frente)
                {
                    p.AparouProjetil();
                    refletida = true;
                    float sp2 = Mathf.Max(6f, Mathf.Sqrt(vx * vx + vy * vy) * 1.4f), ang2 = ang + 180f;
                    if (dono != null) ang2 = Mathf.Atan2(dono.y - 40 - y, dono.x - x) * Mathf.Rad2Deg;
                    vx = Mathf.Cos(ang2 * Mathf.Deg2Rad) * sp2; vy = Mathf.Sin(ang2 * Mathf.Deg2Rad) * sp2;
                    if (tipo == "teia") vy -= 1.2f;
                    dist = 0; alcance = 900f;
                    return;
                }
                // DEFESA MÁGICA: segura o orbe e a teia
                if (tipo != "onda" && p.Bloqueando && frente) { p.BloqueouProjetil(x); Estourar(); return; }
                float antes = p.vida;
                p.LevarDano(dano, x, tipo != "onda", tipo == "onda" ? 6f : 3f, null);
                if (tipo == "teia" && p.vida < antes && !p.morto) p.Enredar(enredaQuadros);
                if (tipo == "onda") atingiu = true; else { Estourar(); return; }
            }
        }

        // cenário e alcance
        if (tipo == "onda")
        {
            float sv = vx >= 0 ? 1f : -1f;
            if (Ponto(x + sv * 16, y - 14) || !Ponto(x, y + 4) || dist >= alcance) Estourar();
        }
        else if (Ponto(x, y))
        {
            if (tipo == "teia" && !refletida)
            {
                estado = "chao"; vidaChao = 240; vx = vy = 0;
                float gy = y;
                while (gy > y - 40 && Ponto(x, gy - 1)) gy -= 1;
                y = gy;
                Efeitos.Som(Efeitos.Sons?.teiaPrende, 0.4f);
            }
            else Estourar();
        }
        else if (dist >= alcance || y > Mundo.SALA_H + 50f) Estourar();
    }

    static bool Ponto(float px, float py) => Mundo.Colide(px - 0.5f, py - 0.5f, px + 0.5f, py + 0.5f);

    void Desenhar()
    {
        transform.position = Mundo.Tela(x, y);
        float f = estado == "fim" ? fimT / 16f : 0f;
        switch (tipo)
        {
            case "orbe":
                {
                    var cor = refletida ? new Color(0.43f, 0.75f, 1f) : new Color(1f, 0.16f, 0.24f);
                    corpo.enabled = estado != "fim";
                    corpo.transform.localRotation = Quaternion.Euler(0, 0, -(ang - 180f));
                    corpo.color = refletida ? new Color(0.67f, 0.86f, 1f) : Color.white;
                    float r = estado == "fim" ? 16f + 44f * f : 34f + 4f * Mathf.Sin(t * 0.5f);
                    aura.transform.localScale = new Vector3(r, r, 1);
                    aura.color = new Color(cor.r, cor.g, cor.b, estado == "fim" ? 0.8f * (1 - f) : 0.45f);
                }
                break;
            case "teia":
                {
                    var cw = refletida ? new Color(0.78f, 0.9f, 1f) : new Color(0.92f, 0.92f, 0.94f);
                    if (estado == "chao")
                    {
                        float va = Mathf.Clamp01(vidaChao / 30f) * 0.75f;
                        corpo.transform.localScale = new Vector3(44f, 7f, 1f);
                        corpo.transform.localPosition = new Vector3(0, 2f, 0);
                        corpo.color = new Color(cw.r, cw.g, cw.b, va * 0.6f);
                        aura.enabled = false;
                    }
                    else
                    {
                        float rr = (estado == "fim" ? 6f + fimT : 5f) * 2f;
                        corpo.transform.localScale = new Vector3(rr, rr, 1f);
                        corpo.color = new Color(cw.r, cw.g, cw.b, 1f - f);
                        aura.transform.localScale = new Vector3(rr * 2.4f, rr * 2.4f, 1f);
                        aura.color = new Color(1f, 1f, 1f, 0.35f * (1f - f));
                    }
                }
                break;
            default:
                {
                    // onda roxa: crescente de magia rente ao chão
                    float oa = 1f - f, sd = vx >= 0 ? 1f : -1f;
                    corpo.transform.localPosition = new Vector3(-sd * 4f, 18f, 0);
                    corpo.transform.localScale = new Vector3(26f, 52f, 1f);
                    corpo.color = new Color(0.9f, 0.3f, 1f, 0.9f * oa);
                    aura.transform.localPosition = new Vector3(0, 2f, 0);
                    aura.transform.localScale = new Vector3(56f, 12f, 1f);
                    aura.color = new Color(0.78f, 0.2f, 1f, 0.5f * oa);
                }
                break;
        }
    }
}
