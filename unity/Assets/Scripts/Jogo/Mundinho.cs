// =====================================================================
//  Peças do mundo que o herói usa:
//  · Arena: limites da luta fechada (mini-chefe, chefe, arena da chave)
//  · Checkpoint: cristal mágico que salva ao passar (obj_checkpoint)
//  · Interativo: baús de vida / da chave (obj_bau) abertos com o botão ITEM
//  · Destrutivel: caixotes e barris que soltam orbs (obj_caixote, obj_barril)
//  · Escalada: escadas de mão, cordas e correntes (v1.14)
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public static class Arena
{
    public static float limEsq = -9999f, limDir = 99999f;
    public static string musica = "";       // trilha da luta fechada ("" = a da fase)
    public static void Fechar(float x1, float x2, string trilha = "") { limEsq = x1; limDir = x2; musica = trilha; if (trilha != "") Musica.Tocar(trilha); }
    public static void Abrir() { limEsq = -9999f; limDir = 99999f; if (musica != "") { musica = ""; Musica.Tocar("mus_fase"); } }
}

public class Checkpoint : MonoBehaviour
{
    public static bool ativo; public static float cx, cy; public static int fase = 1;
    public float x, y;
    bool ativado; float fx;
    SpriteRenderer cristal, brilho;

    public static Checkpoint Criar(float x, float y, Material aditivo)
    {
        var c = new GameObject("checkpoint").AddComponent<Checkpoint>();
        c.x = x; c.y = y;
        c.brilho = Parte(c.transform, Texturas.Brilho(), aditivo, 70);
        c.cristal = Parte(c.transform, Texturas.Disco(), aditivo, 71);
        return c;
    }

    static SpriteRenderer Parte(Transform pai, Sprite s, Material m, int ordem)
    {
        var go = new GameObject("p"); go.transform.SetParent(pai, false);
        var r = go.AddComponent<SpriteRenderer>(); r.sprite = s; r.sharedMaterial = m; r.sortingOrder = ordem;
        return r;
    }

    void Update()
    {
        var p = Jogador.eu;
        if (fx > 0) fx -= Tempo.Dt;
        if (!ativado && p != null && !p.morto && p.Toca(x - 40, y - 90, x + 40, y + 30))
        {
            ativado = true; fx = 45;
            ativo = true; cx = p.x; cy = p.y; fase = Fase.numero;
            Salvar.Gravar();
            Telas.Aviso("CHECKPOINT SALVO AUTOMATICAMENTE");
            CameraVallack.Tremer(4f);
            Efeitos.Tocar("sfx_salvar", 0.8f, 0f);
        }
        float t = Time.time * 60f;
        var cor = ativado ? new Color(0.27f, 0.75f, 1f) : new Color(0.49f, 0.31f, 0.86f);
        float br = ativado ? 1f : 0.5f, pu = 1f + (fx > 0 ? fx / 45f : 0f);
        transform.position = Mundo.Tela(x, y - 66 + Mathf.Sin(t * 0.05f) * 4f);
        cristal.transform.localScale = new Vector3(10f * pu, 22f * pu, 1f);
        cristal.color = new Color(cor.r, cor.g, cor.b, 0.95f);
        brilho.transform.localScale = new Vector3(60f * pu, 80f * pu, 1f);
        brilho.color = new Color(cor.r, cor.g, cor.b, 0.35f * br + (fx > 0 ? 0.4f : 0f));
    }
}

public class Interativo : MonoBehaviour
{
    public static readonly List<Interativo> todos = new List<Interativo>();
    public const int BAU_PARTICULAS = 24;
    public float x, y;
    public string conteudo = "vida";       // "vida" ou "chave"
    public bool selado;
    public SpriteAnim aBau;
    string estado = "fechado";
    float t, chaveVoo = -1f;
    int soltas;
    SpriteRenderer sr, brilho;
    Material aditivo;

    public static Interativo Bau(float x, float y, SpriteAnim anim, Material lit, Material aditivo, string conteudo = "vida")
    {
        var b = new GameObject("baú").AddComponent<Interativo>();
        b.x = x; b.y = y; b.aBau = anim; b.conteudo = conteudo; b.aditivo = aditivo;
        b.sr = b.gameObject.AddComponent<SpriteRenderer>();
        b.sr.sharedMaterial = lit; b.sr.sortingOrder = 72;
        if (anim != null) b.sr.sprite = anim.Quadro(0);
        var g = new GameObject("brilho"); g.transform.SetParent(b.transform, false);
        b.brilho = g.AddComponent<SpriteRenderer>();
        b.brilho.sprite = Texturas.Brilho(); b.brilho.sharedMaterial = aditivo; b.brilho.sortingOrder = 73;
        b.transform.position = Mundo.Tela(x, y);
        return b;
    }

    void OnEnable() { todos.Add(this); }
    void OnDisable() { todos.Remove(this); }

    // botão ITEM: abre o baú mais perto. false = nada por perto (vira sub-arma)
    public static bool Usar(Jogador p)
    {
        foreach (var b in todos)
        {
            if (b.estado != "fechado" || Mathf.Abs(b.x - p.x) >= 46 || Mathf.Abs(b.y - p.y) >= 40 || !p.NoChao) continue;
            p.facing = Mathf.Sign(b.x - p.x) == 0 ? 1 : Mathf.Sign(b.x - p.x);
            b.Abrir();
            p.velh = 0;
            return true;
        }
        return false;
    }

    void Abrir()
    {
        if (selado) { Telas.Aviso("O BAÚ ESTÁ SELADO  ·  DERROTE OS GUARDIÕES"); return; }
        if (conteudo == "chave") chaveVoo = 0;
        estado = "abrindo"; t = 0;
        Efeitos.Tocar("sfx_bau", 1f, 0f);
        CameraVallack.Tremer(3f);
    }

    public void QuebrarSelo() { if (selado) { selado = false; Efeitos.Faiscas(x, y - 16, 1.4f, 14); Efeitos.Tocar("sfx_cura", 0.6f); } }

    void Update()
    {
        float dt = Tempo.Dt;
        if (chaveVoo >= 0)
        {
            chaveVoo += dt;
            if (chaveVoo >= 70)
            {
                chaveVoo = -1; Jogo.chavePortao = true;
                Telas.Aviso("CHAVE DO PORTÃO  ·  VOLTE AO PORTÃO TRANCADO");
                Efeitos.Tocar("sfx_cura", 0.7f, 0f);
            }
        }
        if (estado == "abrindo")
        {
            t += dt;
            if (aBau != null) sr.sprite = aBau.Quadro(Mathf.Min(3, Mathf.Floor(t / 7f) + 1));
            if (conteudo == "chave" && t >= 22) estado = "aberto";
            else if (t >= 22 && soltas < BAU_PARTICULAS)
            {
                // a magia flui do baú até Twilight, curando aos poucos
                if (soltas == 0) { Efeitos.Faiscas(x, y - 16, 0.8f); CameraVallack.Tremer(4f); }
                float cura = Dificuldade.nivel == 0 ? 70 : (Dificuldade.nivel == 1 ? 55 : (Dificuldade.nivel == 2 ? 45 : 35));
                Coleta.Vida(x, y - 16, cura / BAU_PARTICULAS);
                soltas++;
            }
            else if (soltas >= BAU_PARTICULAS) estado = "aberto";
        }
        bool fechado = estado == "fechado";
        var p = Jogador.eu;
        bool perto = fechado && p != null && Mathf.Abs(x - p.x) < 46 && Mathf.Abs(y - p.y) < 40;
        float pu = 0.6f + 0.4f * Mathf.Sin(Time.time * 5f);
        brilho.enabled = fechado || chaveVoo >= 0;
        brilho.transform.localPosition = new Vector3(0, chaveVoo >= 0 ? 16f + chaveVoo * 0.6f : 14f, 0);
        brilho.transform.localScale = Vector3.one * (perto ? 46f : 30f);
        brilho.color = selado ? new Color(0.7f, 0.3f, 1f, 0.35f * pu) : (chaveVoo >= 0 ? new Color(1f, 0.8f, 0.3f, 0.9f) : new Color(1f, 0.85f, 0.45f, (perto ? 0.5f : 0.22f) * pu));
    }
}

public class Destrutivel : MonoBehaviour
{
    public static readonly List<Destrutivel> todos = new List<Destrutivel>();
    public float x, y, larg = 32f, alt = 32f;
    public int vida = 2, orbs = 6;
    public bool barril, solido = true;
    int caixaIdx = -1;
    float tremer;
    SpriteRenderer sr;

    public static Destrutivel Criar(float x, float y, SpriteAnim anim, Material lit, bool barril)
    {
        var d = new GameObject(barril ? "barril" : "caixote").AddComponent<Destrutivel>();
        d.x = x; d.y = y; d.barril = barril;
        d.sr = d.gameObject.AddComponent<SpriteRenderer>();
        d.sr.sharedMaterial = lit; d.sr.sortingOrder = 74;
        if (anim != null) { d.sr.sprite = anim.Quadro(0); d.larg = d.sr.sprite.bounds.size.x; d.alt = d.sr.sprite.bounds.size.y; }
        d.vida = barril ? 1 : 2; d.orbs = barril ? 4 : 6;
        // o caixote é um degrau sólido (os inimigos pulam por cima)
        if (!barril) { Mundo.Solido(x - d.larg / 2f, y - d.alt, x + d.larg / 2f, y); d.caixaIdx = Mundo.solidos.Count - 1; }
        d.transform.position = Mundo.Tela(x, y);
        return d;
    }

    void OnEnable() { todos.Add(this); }
    void OnDisable() { todos.Remove(this); }

    public static void Bater(float x1, float y1, float x2, float y2, int forca, float origemX, HashSet<object> ja)
    {
        for (int i = todos.Count - 1; i >= 0; i--)
        {
            var d = todos[i];
            if (ja != null && ja.Contains(d)) continue;
            if (!(x1 < d.x + d.larg / 2f && x2 > d.x - d.larg / 2f && y1 < d.y && y2 > d.y - d.alt)) continue;
            ja?.Add(d);
            d.vida -= forca; d.tremer = 8;
            Efeitos.Faiscas(d.x, d.y - d.alt / 2f, 0.7f, 6);
            Efeitos.Tocar(d.vida <= 0 ? "dest_madeira" : "dest_quique", 0.7f);
            if (d.vida <= 0) d.Quebrar();
        }
    }

    void Quebrar()
    {
        Efeitos.Poeira(x, y - alt / 2f, 1.2f);
        Efeitos.Faiscas(x, y - alt / 2f, 1.2f, 12);
        Coleta.Orbs(x, y - alt / 2f, orbs);
        if (Random.value < 0.25f) Coleta.Essencia(x, y - alt / 2f, 1);
        // tira o sólido do mundo sem mexer nos índices dos outros
        if (caixaIdx >= 0 && caixaIdx < Mundo.solidos.Count) Mundo.solidos[caixaIdx] = new Mundo.Caixa { x1 = -99999, x2 = -99998, y1 = -99999, y2 = -99998 };
        Destroy(gameObject);
    }

    void Update()
    {
        if (tremer > 0) { tremer -= Tempo.Dt; transform.position = Mundo.Tela(x + Random.Range(-1.5f, 1.5f), y); }
    }
}

public static class Escalada
{
    // [x, y do alto, y de baixo, tipo (0 escada · 1 corda), saída no alto (-1 esquerda, 1 direita, 0 reto)]
    public static readonly float[][] DADOS =
    {
        new[] { 1316f, 612f, 693f, 0f, 1f },      // sobe para a ponte de corda do abismo
        new[] { 1236f, 470f, 640f, 1f, 0f },      // corda pendurada no andaime (pula e agarra)
        new[] { 2142f, 590f, 693f, 0f, 1f },      // sobe para as plataformas penduradas do forte
        new[] { 2346f, 360f, 548f, 1f, -1f },     // a corda até o alto do forte (a arena da chave)
    };
    public static bool escalando;
    static int idx = -1;
    static float agarrar, anim;
    static bool desce;

    public static void Soltar() { escalando = false; idx = -1; }

    public static bool Passo(Jogador p, float dt, bool livre, bool jump, bool abaixar, bool esq, bool dir, bool chao, bool emGolpe)
    {
        bool sobe = livre && (Controles.PuloSegurado || Controles.Cima);
        if (!escalando && !p.morto && !p.Machucado && !p.Rolando && !emGolpe)
        {
            for (int i = 0; i < DADOS.Length; i++)
            {
                var es = DADOS[i];
                if (Mathf.Abs(p.x - es[0]) > 13) continue;
                bool noTrecho = p.y > es[1] + 2 && p.y <= es[2] + 2;
                bool noTopo = Mathf.Abs(p.y - es[1]) <= 2 && chao;
                bool agarra = noTrecho && sobe && (chao ? (jump || Controles.Cima) : p.velv > -3);
                if (agarra || (noTopo && abaixar))
                {
                    escalando = true; idx = i;
                    agarrar = es[3] == 0 ? 0f : 18f;        // pula e agarra a corda / corrente
                    desce = !agarra;
                    if (!agarra) p.y += 4;                  // desce pela borda de cima
                    p.velh = 0; p.velv = 0; p.DefinirAndar(0); p.ZerarPulo(); p.Atravessar(10);
                    break;
                }
            }
        }
        if (escalando && (p.Machucado || p.morto || emGolpe)) Soltar();
        if (!escalando) return false;
        {
            var es = DADOS[idx];
            p.x = Mathf.Lerp(p.x, es[0], 0.4f);
            if (Mathf.Abs(p.x - es[0]) < 0.6f) p.x = es[0];
            float vy = sobe ? -2.2f : (abaixar ? 2.6f : 0f);
            p.velh = 0; p.velv = vy; p.empurrao = 0;
            if (vy != 0) anim += Mathf.Abs(vy) * dt;
            if (es[3] == 0)
            {
                if (vy > 0) desce = true; else if (vy < 0) desce = false;
                var a = desce ? p.descendoEscada : p.subindoEscada;
                if (a != null) p.an.Quadro(a, Mathf.Floor(anim / 9f) % a.Total);
            }
            else if (agarrar > 0)
            {
                agarrar = Mathf.Max(0, agarrar - dt);
                if (p.agarrarCorda != null) p.an.Quadro(p.agarrarCorda, Mathf.Min(4, Mathf.Floor((1 - agarrar / 18f) * 5f)));
            }
            else if (p.subindoCorda != null) p.an.Quadro(p.subindoCorda, Mathf.Floor(anim / 10f) % 6);

            bool sai = false;
            if (jump && (esq || dir))
            {
                // salta para fora da escada / corda
                sai = true;
                p.facing = (dir ? 1 : 0) - (esq ? 1 : 0);
                p.Pular(0.85f);
                p.DefinirAndar(p.facing * Jogador.VEL_CORRER);
            }
            else if (p.y + vy * dt <= es[1])
            {
                // chegou ao alto: passa para a plataforma
                sai = true;
                p.y = es[1]; p.velv = 0;
                p.x += es[4] * 22f;
                if (es[4] != 0) p.facing = es[4];
                p.Pousar(4);
            }
            else if (vy > 0 && Mundo.Colide(p.x - 11, p.y - 60, p.x + 11, p.y + 2)) sai = true;     // chegou embaixo
            if (sai) Soltar();
        }
        return escalando;
    }
}
