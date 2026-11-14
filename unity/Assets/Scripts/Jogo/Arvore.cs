// =====================================================================
//  Arvore — ÁRVORE AMALDIÇOADA (obj_boss_01), chefe da Fase 1.
//  dormindo → despertar (a arena se fecha) → parado ↔ ataques → (66% e
//  33% da vida) nova fase → cambaleia com 12% → SEQUÊNCIA DE GOLPES.
//  3 FASES, cada uma com a sua sequência fixa:
//    fase 1: fogo, 2 fogos, raiz, fogo, 3 raízes
//    fase 2: galho varredor, 2 fogos, sementes, 3 raízes, chuva de brasas, 3 fogos
//    fase 3: galho mais rápido, onda de 5 raízes, sementes, 3 fogos, chuva, galho, 3 fogos
//  Mais: raízes quando Twilight fica colado no tronco, CHUVA DE FOGO na
//  arena inteira (85%, 50%, 22% da vida e de tempos em tempos) e GUARDAS
//  DA RAIZ contra quem bate colado sem parar ou se esconde num canto.
//  BolaFogo, Raiz e Galho são os projéteis e armadilhas dela.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class Arvore : Inimigo
{
    public static bool derrotada;
    public SpriteAnim aAcao, aFogoParado, aFogoAcao, aFogoAtaque, aBola;
    const float ESCALA = 2.4f, VULNERAVEL_PCT = 0.12f, CHUVA_AVISO = 46f, CHUVA_INTERVALO = 9f, CHUVA_VEL = 5.4f;
    const float ALCANCE_VISAO = 760f, INVOCAR_PERTO = 240f, INVOCAR_CANTO = 480f;
    static readonly float[] CHUVA_MARCOS = { 0.85f, 0.5f, 0.22f };

    float barreiraX, arenaEsq, yChao, recargaBoss = 70f, recargaMaxBoss = 110f;
    int fase = 1, ataqueN, rajada, chuvaMarcoI;
    float[] rajadaDesvios = { 0 };
    bool dialogoFim;
    bool acordado, furia, golpeLancado, sementesLancadas, invocacaoFeita, orbsSoltas;
    float furiaFx, raizRecarga = 240f, pertoTempo, vulneravelT, tremor, afundar, explosoesT, morteTempo;
    float golpeadaT, acamparT, cantoT, cantoX = -10000f, cantoY = -10000f, vidaJogadorAnt = -1f, invocarRecarga = 600f, chuvaGrandeT = 1800f;
    string invocacaoMotivo = "perto";
    readonly List<float[]> chuvaFila = new List<float[]>();     // [x, espera, y do chão]
    readonly List<SpriteRenderer> marcas = new List<SpriteRenderer>();
    SpriteAnim sParado, sAcao, sAtaque;
    SpriteRenderer brilho;

    protected override void Configurar()
    {
        ehChefe = true; usaQte = true; semPortal = true;
        escalaVis = ESCALA; topoVis = 175f;
        mw = 12f * ESCALA; mh = 68f * ESCALA;      // spr_mascara_boss (24 x 68) na escala da árvore
        vidaBase = 1900f; danoBase = 16f;
        resisteAtordoar = true; podeLancar = false;
        orbs = 400; essenciaDrop = 0; sangueDrop = 0;
        estado = "dormindo";
        sParado = aParado; sAcao = aAcao; sAtaque = aAtaque;
        barreiraX = x + 130f; arenaEsq = x - 760f; yChao = TerrenoFase1.CHAO;
        derrotada = false;
        brilho = Filho(visual, "brilho da maldição", null, aditivo, 79);
    }

    protected override void Awake() { base.Awake(); dir = -1f; }

    void Trocar(SpriteAnim a, float v) { an.Tocar(a, true, v); }

    void Despertar()
    {
        if (acordado || estado == "despertar" || morrendo) return;
        estado = "despertar";
        Trocar(sAcao, 1.2f);
        CameraVallack.Tremer(14f);
        Efeitos.Tocar("sfx_rugido", 1f, 0f);
        Arena.Fechar(arenaEsq, barreiraX, "bgm_final_boss_phase1");
        Hud.MostrarChefe(this, "ÁRVORE AMALDIÇOADA", "GUARDIÃ DA ESTRADA DE VALLACK");
        Dialogo.Iniciar("arvore_inicio");
    }

    // ------------------------------------------------------------------
    void LancarBolaFogo(Jogador alvo, float desvio)
    {
        float sx = x + dir * 30 * ESCALA, sy = y - 36 * ESCALA;
        float tx = sx + dir * 400, ty = yChao - 30;
        if (alvo != null)
        {
            tx = alvo.x; ty = alvo.y - 34;
            // DIFÍCIL e EXTREMO: mira um pouco à frente de quem corre
            if (Dificuldade.nivel >= 2) tx += alvo.velh * Vector2.Distance(new Vector2(sx, sy), new Vector2(tx, ty)) / 4.6f * 0.7f;
        }
        if (Mathf.Sign(tx - sx) != dir) tx = sx + dir * 160;
        float ang = Mathf.Atan2(ty - sy, tx - sx) * Mathf.Rad2Deg + desvio;
        float v = new[] { 4.6f, 5.0f, 5.5f }[Mathf.Clamp(fase - 1, 0, 2)];
        var b = BolaFogo.Criar(sx, sy, Mathf.Cos(ang * Mathf.Deg2Rad) * v, Mathf.Sin(ang * Mathf.Deg2Rad) * v, danoBase, aBola, aditivo);
        b.alcance = 600f;
        CameraVallack.Tremer(5f);
        Efeitos.Tocar("fogo_bola", 0.9f);
    }

    // SEMENTES DA MALDIÇÃO: sementes em arco; ao cair, cada uma finca uma raiz menor
    void LancarSementes(Jogador alvo)
    {
        int total = fase >= 3 ? 3 : 2;
        float sx = x + dir * 22 * ESCALA, sy = y - 48 * ESCALA;
        for (int i = 0; i < total; i++)
        {
            float desloc = (i - (total - 1) * 0.5f) * 86f;
            float tx = sx + dir * (260 + i * 50), ty = yChao - 4;
            if (alvo != null) tx = Mathf.Clamp(alvo.x + desloc + alvo.velh * 9, arenaEsq + 42, barreiraX - 42);
            float tempo = Mathf.Clamp(Mathf.Abs(tx - sx) / 4.6f, 40, 78);
            const float g = 0.18f;
            var b = BolaFogo.Criar(sx, sy, (tx - sx) / tempo, (ty - sy - 0.5f * g * tempo * tempo) / tempo, Mathf.Max(1, Mathf.Round(14f * 0.72f)), aBola, aditivo);
            b.semente = true; b.gravidade = g; b.raioExplosao = 34f; b.alcance = 760f; b.yChao = yChao;
        }
        CameraVallack.Tremer(7f);
        Efeitos.Tocar("fogo_bola", 0.8f);
    }

    int ServosVivos()
    {
        int n = 0;
        foreach (var e in todos) if (e.invocado && !e.morrendo && !e.ehChefe) n++;
        return n;
    }

    // GUARDAS DA RAIZ: poucos servos, pelos portais perto de Twilight
    void InvocarGuardas(string motivo)
    {
        var p = Jogador.eu; var ini = InimigosFase1.eu;
        if (p == null || ini == null) return;
        var lista = motivo == "canto" ? new List<string> { "arqueiro", "besta", "arqueiro" } : new List<string> { "besta", "esqueleto" };
        if (fase >= 2) lista.Add(motivo == "canto" ? "besta" : "aranha");
        if (Dificuldade.nivel >= 2) lista.Add("besta");
        for (int i = 0; i < lista.Count; i++)
        {
            float lado = i % 2 == 0 ? -1f : 1f;
            float sx = p.x + lado * (130 + 50 * Mathf.Floor(i / 2f) + Random.value * 40);
            if (sx > x - 110) sx = p.x - (150 + 40 * i);          // não nasce dentro do tronco
            sx = Mathf.Clamp(sx, arenaEsq + 40, barreiraX - 60);
            ini.InvocarServo(lista[i], sx, yChao, 10 + i * 14);
        }
    }

    // CHUVA DE FOGO na arena inteira: as marcas acendem da árvore para a esquerda
    void ChuvaGrande()
    {
        int n = 9 + fase * 3;
        float x1 = arenaEsq + 40, x2 = barreiraX - 40;
        for (int i = 0; i < n; i++) Marca(x1 + (i + 0.5f) / n * (x2 - x1) + Random.Range(-14f, 14f), CHUVA_AVISO + 16 + (n - 1 - i) * 5);
        var p = Jogador.eu;
        if (p != null) for (int k = 0; k < 2; k++) Marca(Mathf.Clamp(p.x + (k == 0 ? 0 : Random.Range(-50f, 50f)), x1, x2), CHUVA_AVISO + 16 + n * 5 + k * 22);
        Efeitos.Tocar("sfx_rugido", 0.9f, 0f); Efeitos.Tocar("boss_carga", 1f);
        CameraVallack.Tremer(14f);
        Telas.Aviso("CHUVA DE FOGO!  ·  FIQUE LONGE DAS MARCAS");
    }

    void ChuvaLancar(int n)
    {
        var p = Jogador.eu; float px = p != null ? p.x : x - 300;
        for (int i = 0; i < n; i++)
        {
            // uma em cima de Twilight, as outras espalhadas dos dois lados
            float off = i == 0 ? 0 : (i % 2 == 1 ? 1f : -1f) * (60 + 70 * Mathf.Floor((i - 1) / 2f)) + Random.Range(-14f, 14f);
            Marca(Mathf.Clamp(px + off, arenaEsq + 30, barreiraX - 30), CHUVA_AVISO + i * CHUVA_INTERVALO);
        }
        Efeitos.Tocar("boss_carga", 0.9f);
    }

    void Marca(float cx, float espera)
    {
        chuvaFila.Add(new[] { cx, espera, yChao });
        var m = Filho(transform.parent, "marca da chuva", Texturas.Brilho(), aditivo, 68);
        m.transform.position = Mundo.Tela(cx, yChao - 2);
        m.transform.localScale = new Vector3(46f, 10f, 1f);
        m.color = new Color(1f, 0.4f, 0.15f, 0.2f);
        marcas.Add(m);
    }

    void LimparAtaques()
    {
        chuvaFila.Clear();
        foreach (var m in marcas) if (m != null) Destroy(m.gameObject);
        marcas.Clear();
        foreach (var r in FindObjectsByType<Raiz>(FindObjectsSortMode.None)) Destroy(r.gameObject);
        foreach (var g in FindObjectsByType<Galho>(FindObjectsSortMode.None)) Destroy(g.gameObject);
        foreach (var b in FindObjectsByType<BolaFogo>(FindObjectsSortMode.None)) if (!b.explodindo) Destroy(b.gameObject);
    }

    // raízes saem do chão embaixo de Twilight. n = 1, 3 ou 5 (onda)
    void RaizesLancar(int n)
    {
        var p = Jogador.eu;
        if (p == null) return;
        bool onda = n >= 5;
        for (int i = 0; i < n; i++)
        {
            float rx = onda ? p.x + 160 - i * 80 : p.x + (i - (n - 1) / 2f) * 76;
            Raiz.Criar(Mathf.Clamp(rx, arenaEsq + 30, barreiraX - 30), yChao, 14f, onda ? i * 12 : i * 8, aditivo, lit);
        }
    }

    string ProximoAtaque()
    {
        string[] seq = fase == 1 ? new[] { "fogo", "fogo2", "raiz1", "fogo", "raiz3" }
            : (fase == 2 ? new[] { "galho", "fogo2", "sementes", "raiz3", "chuva", "fogo3" }
            : new[] { "galho", "raiz5", "sementes", "fogo3", "chuva", "galho", "fogo3" });
        return seq[ataqueN++ % seq.Length];
    }

    // ------------------------------------------------------------------
    protected override void Reagir(float d, float forca)
    {
        tremor = 3; golpeadaT = 150f;
        if (!acordado) Despertar();
        // só morre pela SEQUÊNCIA DE GOLPES (o finalizador dela é o golpe final)
        if (vida <= 0 && qteVencido) { MorrerChefe(); return; }
        vida = Mathf.Max(1, vida);
        if (estado == "vulneravel") return;
        if (vida <= vidaMax * VULNERAVEL_PCT) { Vulneravel(); return; }
        if (fase == 1 && vida <= vidaMax * 0.66f) NovaFase(2);
        else if (fase == 2 && vida <= vidaMax * 0.33f) NovaFase(3);
    }

    // CAMBALEANDO: os ataques param, a árvore treme e espera a sequência de golpes
    void Vulneravel()
    {
        estado = "vulneravel"; vulneravelT = 0; qtePronto = true;
        LimparAtaques();
        Trocar(sAcao, 0.35f);
        tremor = 4;
        CameraVallack.Tremer(16f); Tempo.Lenta(30, 0.45f);
        Efeitos.Tocar("sfx_rugido", 0.8f, 0f);
        Telas.Aviso("A ÁRVORE CAMBALEIA  ·  EXECUTE A SEQUÊNCIA DE GOLPES!");
    }

    // errou a sequência ou demorou: volta com 25% da vida e empurra Twilight
    public override void QteFalhou()
    {
        qtePronto = false;
        vida = Mathf.Max(vida, Mathf.Round(vidaMax * 0.25f)); vidaAtraso = vida;
        estado = "transicao";
        Trocar(sAcao, 1f);
        recargaBoss = 40; tempoInvencivel = 60;
        furia = true; furiaFx = 90;
        CameraVallack.Tremer(22f);
        Efeitos.Tocar("sfx_rugido", 1f, 0f);
        Efeitos.OndaChao(x - 60, yChao, 2f);
        var p = Jogador.eu;
        if (p != null && !p.morto)
        {
            bool forte = Mathf.Abs(p.x - x) < 420;
            p.LevarDano(forte ? 14f : 1f, x, false, forte ? 12f : 6f, this);
        }
        Telas.Aviso("A ÁRVORE SE RECUPEROU!");
    }

    // troca de fase: rugido, os ataques somem e a árvore fica invulnerável
    void NovaFase(int n)
    {
        fase = n; furia = true; furiaFx = 90; ataqueN = 0;
        recargaMaxBoss = Mathf.Round(110f * (n >= 3 ? 0.5f : 0.66f));
        raizRecarga = 200; pertoTempo = 0;
        LimparAtaques();
        estado = "transicao";
        if (n >= 3) { sParado = aFogoParado; sAcao = aFogoAcao; sAtaque = aFogoAtaque; }
        Trocar(sAcao, 1f);
        tempoInvencivel = 90;
        CameraVallack.Tremer(22f); Tempo.Lenta(40, 0.45f);
        Efeitos.Tocar("sfx_rugido", 1f, 0f);
        Telas.Aviso(n == 2 ? "A ÁRVORE AMALDIÇOADA SE ENFURECEU!" : "A CHAMA DE VALLACK TOMA A ÁRVORE!");
        Dialogo.Iniciar(n == 2 ? "arvore_fase2" : "arvore_fase3");
    }

    void MorrerChefe()
    {
        morrendo = true; estado = "morrendo";
        morteTempo = 0; morteT = 0;
        Trocar(sAcao, 0.8f);
        CameraVallack.Tremer(26f);
        Jogo.inimigosDerrotados++;
        Tempo.Impacto(14); Tempo.Lenta(90, 0.3f);
        Efeitos.Tocar("sfx_rugido", 1f, 0f);
        Musica.Tocar("");
        qtePronto = false;
        LimparAtaques();
        foreach (var e in todos.ToArray()) if (e.invocado && !e.morrendo && !e.ehChefe) Destroy(e.gameObject);
    }

    // morte: brasas, tremor, afunda e evapora na fumaça da maldição
    protected override void CorpoPasso(float dt)
    {
        morteTempo += dt; morteT += dt;
        tremor = 3;
        if (an.Indice >= an.anim.Total - 1) an.Quadro(an.anim, an.anim.Total - 1);
        explosoesT -= dt;
        if (explosoesT <= 0 && morteTempo < 150)
        {
            explosoesT = 14;
            float ex = x + Random.Range(-30f, 30f) * ESCALA / 2f, ey = y - Random.Range(15f, 80f) * ESCALA;
            Efeitos.Faiscas(ex, ey, 1.6f, 12); Efeitos.ChamasMorte(ex, ey, 1.2f);
            Efeitos.Tocar(Random.value < 0.5f ? "fogo_explosao" : "hit_3", 0.6f);
            CameraVallack.Tremer(8f);
        }
        if (morteTempo > 45 && !dialogoFim) { dialogoFim = true; Dialogo.Iniciar("arvore_fim"); }
        if (morteTempo > 90 && !orbsSoltas) { orbsSoltas = true; Coleta.Orbs(x - 40, y - 60, orbs); }
        if (morteTempo > 110) afundar = Mathf.Min(afundar + 0.35f * dt, 34f);
        float e = Mathf.Clamp01((morteTempo - 110f) / 130f);
        var c = sr.color; c.a = 1f - e; sr.color = c;
        if (e >= 1f)
        {
            Telas.Aviso("O GUARDIÃO CAIU  ·  O CAMINHO ESTÁ LIVRE");
            CameraVallack.Tremer(10f);
            Arena.Abrir(); Hud.EsconderChefe(this);
            derrotada = true;
            Salvar.Gravar();
            Destroy(gameObject);
        }
        velh = velv = 0;
    }

    protected override void AposAtordoado(bool dentroCampo, float adx) { }

    // ------------------------------------------------------------------
    protected override void Agir(Jogador p, float dx, float dy, float adx, bool dentroCampo, bool noChao, bool tem, float dt)
    {
        velh = 0; empurrao = 0; atordoado = 0;
        if (furiaFx > 0) furiaFx -= dt;
        tremor = Mathf.Max(0, tremor - 0.3f * dt);
        if (estado == "parado" && !acordado) estado = "dormindo";
        bool naTela = CameraVallack.NaTela(x - mw, 30f) || CameraVallack.NaTela(x + mw, 30f);
        if (acordado && tem && dx != 0 && estado != "atacando") dir = Mathf.Sign(dx);

        // CHUVA DE BRASAS: cada marca no chão vira uma bola de fogo caindo do céu
        for (int c = chuvaFila.Count - 1; c >= 0; c--)
        {
            var ch = chuvaFila[c];
            ch[1] -= dt;
            if (marcas[c] != null) { float k = 1f - Mathf.Clamp01(ch[1] / 60f); marcas[c].color = new Color(1f, 0.4f, 0.15f, 0.2f + 0.6f * k * (0.6f + 0.4f * Mathf.Sin(Time.time * 30f))); }
            if (ch[1] > 0) continue;
            var b = BolaFogo.Criar(ch[0] + Random.Range(-8f, 8f), CameraVallack.TopoVista - 24f, Random.Range(-0.4f, 0.4f), CHUVA_VEL + fase * 0.4f, danoBase, aBola, aditivo);
            b.alcance = 2000f;
            Efeitos.Tocar("fogo_bola", 0.5f);
            if (marcas[c] != null) Destroy(marcas[c].gameObject);
            chuvaFila.RemoveAt(c); marcas.RemoveAt(c);
        }
        // raízes: sempre que Twilight fica colado no tronco
        if (acordado && tem)
        {
            if (raizRecarga > 0) raizRecarga -= dt;
            if (adx < 150) pertoTempo += dt; else pertoTempo = Mathf.Max(0, pertoTempo - dt);
            if (raizRecarga <= 0 && pertoTempo > 70 && estado == "parado" && FindAnyObjectByType<Raiz>() == null)
            {
                estado = "raizes"; Trocar(sAcao, 1.3f);
                RaizesLancar(fase >= 2 ? 3 : 1);
                raizRecarga = fase >= 2 ? 170f : 240f; pertoTempo = 0;
                CameraVallack.Tremer(6f);
            }
        }
        // INVOCAÇÃO contra quem se aproveita da luta (colado batendo, ou escondido num canto)
        if (acordado && tem && !qtePronto)
        {
            if (golpeadaT > 0) golpeadaT -= dt;
            if (invocarRecarga > 0) invocarRecarga -= dt;
            if (adx < 190 && golpeadaT > 0) acamparT += dt; else acamparT = Mathf.Max(0, acamparT - dt * 0.25f);
            if (Vector2.Distance(new Vector2(p.x, p.y), new Vector2(cantoX, cantoY)) > 90) { cantoX = p.x; cantoY = p.y; cantoT = 0; }
            else cantoT += dy < -170 ? 2 * dt : dt;       // no alto, longe do chão da arena, conta em dobro
            if (vidaJogadorAnt >= 0 && p.vida < vidaJogadorAnt) cantoT = 0;
            vidaJogadorAnt = p.vida;
            string motivo = acamparT >= INVOCAR_PERTO ? "perto" : (cantoT >= INVOCAR_CANTO ? "canto" : "");
            if (motivo != "" && invocarRecarga <= 0 && estado == "parado" && ServosVivos() < 2 && !Qte.Ativo)
            {
                estado = "invocando"; invocacaoFeita = false; invocacaoMotivo = motivo;
                Trocar(sAcao, 1f);
                acamparT = 0; cantoT = 0;
                invocarRecarga = 960f - fase * 120f;
                tremor = 3; CameraVallack.Tremer(12f);
                Efeitos.Tocar("sfx_rugido", 0.9f, 0f);
                Telas.Aviso("A ÁRVORE CONVOCA SEUS SERVOS!");
            }
        }

        bool fim = an.Terminou;
        switch (estado)
        {
            case "dormindo":
                an.Tocar(sParado, false, 0.35f);
                if (tem && naTela && p.x > arenaEsq + 70 && Mathf.Abs(dy) < 320) Despertar();
                break;
            case "despertar":
                if (fim) { estado = "parado"; acordado = true; recargaBoss = 50; an.Tocar(sParado, true); }
                break;
            case "vulneravel":
                vulneravelT += dt;
                tremor = Mathf.Max(tremor, 1.2f);
                if (an.Indice >= an.anim.Total - 1) an.Indice = an.anim.Total - 2;
                if (vulneravelT >= 420) QteFalhou();
                break;
            case "parado":
                an.Tocar(sParado, false, furia ? 1.4f : 1f);
                if (recargaBoss > 0) recargaBoss -= dt;
                if (chuvaGrandeT > 0) chuvaGrandeT -= dt;
                bool pedeChuva = (chuvaMarcoI < CHUVA_MARCOS.Length && vida <= vidaMax * CHUVA_MARCOS[chuvaMarcoI]) || chuvaGrandeT <= 0;
                if (pedeChuva && tem && naTela && chuvaFila.Count == 0)
                {
                    while (chuvaMarcoI < CHUVA_MARCOS.Length && vida <= vidaMax * CHUVA_MARCOS[chuvaMarcoI]) chuvaMarcoI++;
                    chuvaGrandeT = fase >= 3 ? 1080f : (fase == 2 ? 1440f : 1800f);
                    estado = "chuva"; Trocar(sAcao, 1f);
                    ChuvaGrande();
                }
                else if (tem && naTela && adx <= ALCANCE_VISAO && Mathf.Abs(dy) < 320 && recargaBoss <= 0)
                {
                    string atq = ProximoAtaque();
                    if (atq.StartsWith("fogo"))
                    {
                        estado = "atacando"; golpeLancado = false;
                        rajada = atq == "fogo3" ? 3 : (atq == "fogo2" ? 2 : 1);
                        rajadaDesvios = rajada == 3 ? new[] { -10f, 0f, 10f } : (rajada == 2 ? new[] { -5f, 5f } : new[] { 0f });
                        Trocar(sAtaque, fase >= 3 ? 1.5f : 1.25f);
                        Efeitos.Tocar("boss_carga", 0.9f);
                    }
                    else if (atq.StartsWith("raiz")) { estado = "raizes"; Trocar(sAcao, 1.3f); RaizesLancar(int.Parse(atq.Substring(4))); CameraVallack.Tremer(6f); }
                    else if (atq == "sementes") { estado = "semeando"; sementesLancadas = false; Trocar(sAtaque, 1.15f); Efeitos.Tocar("boss_carga", 0.7f); }
                    else if (atq == "chuva") { estado = "chuva"; Trocar(sAcao, 1.2f); ChuvaLancar(fase >= 3 ? 7 : 4); CameraVallack.Tremer(10f); }
                    else
                    {
                        // GALHO VARREDOR (fases 2 e 3): varre a arena rente ao chão. Pule ou role.
                        estado = "galho"; Trocar(sAcao, 0.9f);
                        float xb = x - 40 * ESCALA / 3.7f;
                        Galho.Criar(xb, arenaEsq + 20, yChao, fase >= 3 ? 18f : 14f, 15f, aditivo, lit);
                        CameraVallack.Tremer(8f);
                    }
                }
                break;
            case "atacando":
                if (!golpeLancado && an.Indice >= 6f) { golpeLancado = true; foreach (float dsv in rajadaDesvios) LancarBolaFogo(tem ? p : null, dsv); }
                if (fim) { recargaBoss = recargaMaxBoss; Parar(); }
                break;
            case "semeando":
                if (!sementesLancadas && an.Indice >= 4f) { sementesLancadas = true; LancarSementes(tem ? p : null); }
                if (fim) { recargaBoss = recargaMaxBoss; Parar(); }
                break;
            case "invocando":
                if (!invocacaoFeita && an.Indice >= 4f) { invocacaoFeita = true; InvocarGuardas(invocacaoMotivo); }
                if (fim) { Respiro(); Parar(); }
                break;
            case "raizes":
            case "galho":
            case "chuva":
            case "transicao":
                if (fim) { Respiro(); Parar(); }
                break;
        }
    }

    void Respiro() { recargaBoss = Mathf.Max(recargaBoss, fase >= 3 ? 20f : (fase == 2 ? 30f : 40f)); }
    void Parar() { estado = "parado"; an.Tocar(sParado, true); }

    protected override void PosPasso(float dt)
    {
        // BARREIRA DO GUARDIÃO: enquanto a Árvore vive, não dá para seguir
        var p = Jogador.eu;
        if (p != null && !morrendo && p.x > barreiraX - 14) { p.x = barreiraX - 14; if (p.velh > 0) p.velh = 0; }
    }

    protected override void MostrarExtra()
    {
        float sx = tremor > 0 ? Random.Range(-tremor, tremor) : 0f;
        if (emQte && !morrendo) sx = Random.Range(-1.5f, 1.5f);
        visual.localPosition = new Vector3(sx, -afundar, 0);
        visual.localScale = new Vector3(-dir * ESCALA, ESCALA, 1f);        // a arte olha para a esquerda
        if (!morrendo)
        {
            sr.color = estado == "dormindo" ? new Color32(125, 105, 105, 255) : (furia ? new Color32(255, 190, 180, 255) : (Color)Color.white);
            // brilho vermelho da maldição por cima do tronco
            brilho.enabled = acordado;
            if (acordado)
            {
                float t = Time.time * 60f;
                brilho.sprite = sr.sprite;
                brilho.transform.localScale = new Vector3(1.03f, 1.02f, 1f);
                brilho.color = furia ? new Color(0.86f, 0.12f, 0.04f, 0.32f + 0.14f * Mathf.Sin(t / 5f)) : new Color(0.59f, 0.08f, 0.04f, 0.18f + 0.08f * Mathf.Sin(t / 9f));
            }
        }
        else { brilho.enabled = false; var c = Color.Lerp(Color.white, new Color32(80, 50, 40, 255), Mathf.Clamp01(morteTempo / 200f)); c.a = sr.color.a; sr.color = c; }
    }
}

// ----------------------------------------------------------------------
//  BolaFogo — projétil da Árvore. Voa até "alcance" e estoura; a explosão
//  só fere quem está DENTRO da área. Aparada, volta para a Árvore. A
//  variação "semente" cai em arco e finca uma raiz menor onde pousa.
// ----------------------------------------------------------------------
public class BolaFogo : MonoBehaviour
{
    public float alcance = 560f, raioExplosao = 54f, gravidade, yChao = TerrenoFase1.CHAO;
    public bool semente, explodindo;
    float x, y, vx, vy, dano, dist, fimT;
    bool refletida;
    SpriteAnim anim; SpriteRenderer sr, halo; float quadro;
    Material aditivo;

    public static BolaFogo Criar(float x, float y, float vx, float vy, float dano, SpriteAnim anim, Material aditivo)
    {
        var go = new GameObject("bola de fogo");
        var b = go.AddComponent<BolaFogo>();
        b.x = x; b.y = y; b.vx = vx; b.vy = vy; b.dano = dano; b.anim = anim; b.aditivo = aditivo;
        b.sr = go.AddComponent<SpriteRenderer>(); b.sr.sharedMaterial = aditivo; b.sr.sortingOrder = 123;
        var h = new GameObject("halo"); h.transform.SetParent(go.transform, false);
        b.halo = h.AddComponent<SpriteRenderer>(); b.halo.sprite = Texturas.Brilho(); b.halo.sharedMaterial = aditivo; b.halo.sortingOrder = 122;
        h.transform.localScale = Vector3.one * 34f;
        go.transform.localScale = Vector3.one * 1.7f;
        go.transform.position = Mundo.Tela(x, y);
        return b;
    }

    void Explodir(bool podeFerir)
    {
        if (explodindo) return;
        explodindo = true; quadro = 7; vx = vy = 0;
        // a semente cria uma raiz menor depois de cair (com a própria janela de aviso)
        if (semente && !refletida) Raiz.Criar(x, yChao, Mathf.Max(1, Mathf.Round(dano * 0.9f)), 8, aditivo, null, 72f, 15f);
        var p = Jogador.eu;
        if (p != null && Vector2.Distance(new Vector2(x, y), new Vector2(p.x, p.y)) < 500) CameraVallack.Tremer(7f);
        Efeitos.Tocar("fogo_explosao", 0.8f);
        Efeitos.ChamasMorte(x, y, 0.7f);
        if (podeFerir && !refletida && p != null && !p.morto && Vector2.Distance(new Vector2(x, y), new Vector2(p.x, p.MeioY)) <= raioExplosao + 10)
            p.LevarDano(dano, x, true, 6f, null);
    }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt > 0)
        {
            if (!explodindo)
            {
                if (semente) vy += gravidade * dt;
                x += vx * dt; y += vy * dt;
                dist += Mathf.Sqrt(vx * vx + vy * vy) * dt;
                quadro += 0.14f * dt; if (quadro >= 6.9f) quadro = 0;
                var p = Jogador.eu;
                bool toca = p != null && !p.morto && !refletida && !p.Intangivel() && x > p.Esq - 6 && x < p.Dir + 6 && y > p.Topo - 6 && y < p.y + 6;
                if (refletida)
                {
                    foreach (var e in Inimigo.todos)
                    {
                        if (e.morrendo || !e.ativo || !e.Toca(x - 2, y - 2, x + 2, y + 2)) continue;
                        e.LevarDano(e.ehChefe ? Mathf.Max(1, Mathf.Round(e.vidaMax * 0.04f)) : e.vidaMax, x - vx, 6f, null, true);
                        Explodir(false);
                        break;
                    }
                }
                if (!explodindo)
                {
                    bool frente = toca && Mathf.Sign(x - p.x) == p.facing;
                    if (toca && p.Aparando && frente)
                    {
                        // APARADA: a bola de fogo volta para a Árvore
                        p.AparouProjetil();
                        refletida = true; vx = -vx * 1.25f; vy = -vy * 0.6f; dist = 0; alcance = 900f; gravidade = 0;
                    }
                    else if (toca && p.Bloqueando && frente) { p.BloqueouProjetil(x); Explodir(false); }
                    else if (toca) Explodir(true);
                    else if (dist >= alcance || Mundo.Colide(x - 0.5f, y + 5.5f, x + 0.5f, y + 6.5f) || y > Mundo.SALA_H) Explodir(true);
                }
            }
            else
            {
                quadro += 0.13f * dt; fimT += dt;
                if (anim == null || quadro >= anim.Total || fimT > 40) { Destroy(gameObject); return; }
            }
        }
        transform.SetPositionAndRotation(Mundo.Tela(x, y), Quaternion.Euler(0, 0, explodindo ? 0 : -Mathf.Atan2(vy, vx) * Mathf.Rad2Deg));
        if (anim != null) sr.sprite = anim.Quadro(quadro);
        var c = refletida ? new Color(0.5f, 0.75f, 1f) : (semente ? new Color(0.75f, 0.35f, 1f) : new Color(1f, 0.55f, 0.2f));
        sr.color = refletida ? new Color(0.7f, 0.85f, 1f) : (semente ? new Color(0.9f, 0.6f, 1f) : Color.white);
        halo.color = new Color(c.r, c.g, c.b, explodindo ? Mathf.Clamp01(1f - fimT / 20f) * 0.7f : 0.5f);
        halo.transform.localScale = Vector3.one * (explodindo ? 34f + fimT * 2.2f : 34f);
    }
}

// ----------------------------------------------------------------------
//  Raiz — rompe o chão: aviso (coluna de luz roxa) → sobe (fere) → desce
// ----------------------------------------------------------------------
public class Raiz : MonoBehaviour
{
    float x, y, dano, atraso, t, sobe, alt = 96f, meia = 18f;
    string estado = "aviso";
    bool somTocou, feriu;
    SpriteRenderer aviso, corpo;

    public static Raiz Criar(float x, float y, float dano, float atraso, Material aditivo, Material lit, float alt = 96f, float meia = 18f)
    {
        var go = new GameObject("raiz");
        var r = go.AddComponent<Raiz>();
        r.x = x; r.y = y; r.dano = dano; r.atraso = atraso; r.alt = alt; r.meia = meia;
        r.aviso = Parte(go.transform, Texturas.Brilho(), aditivo, 77);
        r.corpo = Parte(go.transform, Texturas.Branco(), aditivo, 78);
        r.corpo.color = new Color(0.45f, 0.2f, 0.55f, 0.95f);
        go.transform.position = Mundo.Tela(x, y);
        r.aviso.enabled = r.corpo.enabled = false;
        return r;
    }

    static SpriteRenderer Parte(Transform pai, Sprite s, Material m, int ordem)
    {
        var go = new GameObject("p"); go.transform.SetParent(pai, false);
        var r = go.AddComponent<SpriteRenderer>(); r.sprite = s; r.sharedMaterial = m; r.sortingOrder = ordem;
        return r;
    }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt <= 0) return;
        if (atraso > 0) { atraso -= dt; return; }
        if (!somTocou) { somTocou = true; Efeitos.Tocar("raiz_aviso", 0.8f); }
        t += dt;
        switch (estado)
        {
            case "aviso":
                if (Random.value < 0.4f * dt) Efeitos.Poeira(x + Random.Range(-16f, 16f), y, 0.35f);
                if (t >= 50) { estado = "sobe"; t = 0; Efeitos.Tocar("dest_pedra", 0.7f); CameraVallack.Tremer(6f); Efeitos.Faiscas(x, y - 6, 0.9f, 8); }
                break;
            case "sobe":
                sobe = Mathf.Min(1, sobe + 0.25f * dt);
                var p = Jogador.eu;
                if (sobe > 0.5f && !feriu && p != null && !p.morto && !p.Intangivel() && p.Toca(x - meia, y - alt * sobe, x + meia, y)) { feriu = true; p.LevarDano(dano, x, false, 5f, null); }
                if (t >= 46) { estado = "desce"; t = 0; }
                break;
            case "desce":
                sobe = Mathf.Max(0, sobe - 0.05f * dt);
                if (sobe <= 0) { Destroy(gameObject); return; }
                break;
        }
        bool av = estado == "aviso";
        aviso.enabled = av; corpo.enabled = !av;
        if (av)
        {
            float k = Mathf.Clamp01(t / 50f);
            aviso.transform.localPosition = new Vector3(0, alt * 0.5f, 0);
            aviso.transform.localScale = new Vector3(meia * 2.6f, alt * 1.2f, 1f);
            aviso.color = new Color(0.75f, 0.3f, 1f, (0.15f + 0.45f * k) * (0.6f + 0.4f * Mathf.Sin(t * 0.6f)));
        }
        else
        {
            // a raiz: um espinho largo embaixo e fino na ponta
            corpo.transform.localPosition = new Vector3(-meia * 0.7f, 0, 0);
            corpo.transform.localScale = new Vector3(meia * 1.4f, alt * sobe, 1f);
        }
    }
}

// ----------------------------------------------------------------------
//  Galho — GALHO VARREDOR: aviso (1 s: o chão da arena brilha) → varre a
//  arena rente ao chão → recolhe. Não dá para defender: PULE ou ROLE.
// ----------------------------------------------------------------------
public class Galho : MonoBehaviour
{
    float xBase, xFim, ponta, yChao, vel, dano, t;
    const float ALT = 34f;
    string estado = "aviso";
    bool atingiu;
    SpriteRenderer aviso, corpo;

    public static Galho Criar(float xBase, float xFim, float yChao, float vel, float dano, Material aditivo, Material lit)
    {
        var go = new GameObject("galho varredor");
        var g = go.AddComponent<Galho>();
        g.xBase = xBase; g.xFim = xFim; g.ponta = xBase; g.yChao = yChao; g.vel = vel; g.dano = dano;
        g.aviso = Parte(go.transform, Texturas.Brilho(), aditivo, 77);
        g.corpo = Parte(go.transform, Texturas.Branco(), lit, 78);
        g.corpo.color = new Color32(70, 44, 36, 255);
        g.corpo.enabled = false;
        Efeitos.Tocar("galho_aviso", 1f);
        return g;
    }

    static SpriteRenderer Parte(Transform pai, Sprite s, Material m, int ordem)
    {
        var go = new GameObject("p"); go.transform.SetParent(pai, false);
        var r = go.AddComponent<SpriteRenderer>(); r.sprite = s; r.sharedMaterial = m; r.sortingOrder = ordem;
        return r;
    }

    void Update()
    {
        float dt = Tempo.Dt;
        if (dt <= 0) return;
        t += dt;
        switch (estado)
        {
            case "aviso":
                if (t >= 60) { estado = "varre"; t = 0; Efeitos.Tocar("fogo_whoosh", 0.9f); CameraVallack.Tremer(6f); }
                break;
            case "varre":
                {
                    ponta -= vel * dt;
                    var p = Jogador.eu;
                    if (!atingiu && p != null && !p.morto && p.Toca(ponta, yChao - ALT, ponta + 40, yChao) && !p.Intangivel())
                    { atingiu = true; p.LevarDano(dano, ponta + 30, false, 6f, null); }
                    if (ponta <= xFim) { estado = "recolhe"; t = 0; }
                }
                break;
            case "recolhe":
                ponta += vel * 1.6f * dt;
                if (ponta >= xBase) { Destroy(gameObject); return; }
                break;
        }
        bool av = estado == "aviso";
        aviso.enabled = av; corpo.enabled = !av;
        if (av)
        {
            float k = t / 60f;
            aviso.transform.position = Mundo.Tela((xBase + xFim) / 2f, yChao - 2f);
            aviso.transform.localScale = new Vector3(Mathf.Abs(xBase - xFim) * 1.1f, 16f, 1f);
            aviso.color = new Color(0.75f, 0.3f, 1f, 0.15f + 0.45f * k * (0.6f + 0.4f * Mathf.Sin(t / 3f)));
        }
        else
        {
            corpo.transform.position = Mundo.Tela(ponta, yChao);
            corpo.transform.localScale = new Vector3(xBase - ponta, ALT * 0.7f, 1f);
        }
    }
}
