// =====================================================================
//  Jogador — Twilight Vetrus (porta fiel do obj_player).
//  A lógica roda em "quadros de 60 FPS" (Tempo.Dt), em pixels, y para
//  baixo e (x, y) no PÉ, como o original; só o desenho converte para Unity.
//  · movimento: corrida com aceleração, pulo com coyote e buffer, ▼ + PULO
//    desce das plataformas de mão única, escadas de mão e cordas
//  · golpes: QUADRADO (corte1 → corte2 → corte3 → frenético, corte aéreo),
//    TRIÂNGULO (salto do carrasco, mergulho no ar, quebra-escudo no combo),
//    BOLA (rasteira, rasteira sangrenta, finalizador perto de um inimigo
//    aberto), LANÇADOR (PULO + TRIÂNGULO), PULO cancela golpes, CRÍTICO
//  · especiais (barra de magia): ONDA CARMESIM, QUEDA CARMESIM, TREMOR
//  · FÚRIA: barra cheia → IRA DE VALLACK e 12 s de modo fúria
//  · sub-armas (essência): LÂMINA BUMERANGUE e, agachado, CHAMA DE SYLLA
//  · defesa, aparar com contra-ataque, rolagem, backdash, dano e morte
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

[DefaultExecutionOrder(-10)]
[RequireComponent(typeof(SpriteAnimador))]
public class Jogador : Entidade
{
    public static Jogador eu;

    [Header("Animações")]
    public SpriteAnim parado, andar, corrida, pulo, queda, agachar, defendendo, ferido, morte;
    public SpriteAnim ataqueRapido, ataqueDuplo, ataqueTriplo, ataqueFrenetico, ataqueAr;
    public SpriteAnim ataque, ataque2, ataque03, agachadoAtaque, especial, agachadoEspecial, especial2;
    public SpriteAnim subindoEscada, descendoEscada, agarrarCorda, subindoCorda;
    [Header("Sons")]
    public AudioClip sPulo, sPouso, sCorte1, sCorte2, sPesado, sAereo, sCritico, sBackdash;
    public Material aditivo;

    [Header("Estado")]
    public float facing = 1f;
    public float vida = 100f, vidaMax = 100f;
    [System.NonSerialized] public bool morto, furiaModo;
    [System.NonSerialized] public float furia, especialCarga = Jogo.ESPECIAL_SEGUNDOS, curaRestante;
    [System.NonSerialized] public string aviso = "";
    [System.NonSerialized] public float avisoT;
    [System.NonSerialized] public float bloqueioInput;      // diálogos, sequência de golpes, fim de fase

    public const float VEL_CORRER = 3.6f, VEL_PULO = 7f;
    const float VEL_AGACHADO = 0.75f, GRAV = 0.25f, ESCALA = 1.25f;
    const int AEREO_MAX = 3;
    const float CRITICO_PONTA = 0.68f, CRITICO_MULT = 1.5f;
    const float ROLAR_DURACAO = 26f, ROLAR_INVENC_INI = 2f, ROLAR_INVENC_FIM = 19f, ROLAR_VEL = 6.6f, ROLAR_BUFFER = 14f;
    const float RECUAR_DURACAO = 18f, RECUAR_INVENC = 10f, RECUAR_VEL = 7.4f;
    const float APARAR_JANELA = 10f, APARAR_RECARGA = 26f;

    float coyote, bufferPulo, pouso, noArTempo, animPasso;
    bool chao, agachado;

    Golpe golpe;
    int golpeI, golpeGrupo, aereoN;
    float golpeT, golpeIdade, cadeiaJanela, bufferGolpeT, pesadoT, puloT, empurraoUlt;
    string cadeia = "", bufferGolpe = "", golpeLetra = "";
    readonly HashSet<Inimigo> atingidos = new HashSet<Inimigo>();
    readonly HashSet<object> atingidosObj = new HashSet<object>();
    Inimigo alvoFinal, contraAlvo;
    float contraT;

    class Onda { public float x0, dir, dist, distMax, yTopo, yBase, vida; public bool ira; public HashSet<Inimigo> hit = new HashSet<Inimigo>(); public SpriteRenderer sr; }
    readonly List<Onda> ondas = new List<Onda>();

    bool machucado, bloqueando, rolando, recuando, esquivou;
    float tempoInvencivel, tempoMorte, janelaAparar, apararRecarga, defesaFx, apararFx;
    float rolarT, rolarDir, rolarBuffer, rolarRecarga, recuarT;
    float enredado, teiaImune;

    float seguroX, seguroY, inicioX, inicioY;
    [System.NonSerialized] public SpriteAnimador an;
    SpriteRenderer sr, escudo, aura;
    AudioSource som;

    public bool NoChao => chao;
    public float VelH => velh;
    public Golpe GolpeAtual => golpe;
    public bool Bloqueando => bloqueando;
    public bool Aparando => janelaAparar > 0;
    public bool Enredado => enredado > 0;
    public bool TeiaImune => teiaImune > 0;
    public bool Machucado => machucado;
    public bool Rolando => rolando;
    public float TempoInvencivel { get => tempoInvencivel; set => tempoInvencivel = value; }
    public void DefinirAndar(float v) { andaV = v; velh = v; }
    public void Atravessar(float q) { atravessarT = q; }
    public void ZerarPulo() { bufferPulo = 0; coyote = 0; }
    public void Pousar(float q) { pouso = q; }

    void Awake()
    {
        eu = this;
        mw = 11f; mh = 66f;                  // spr_mascara_player (22 x 66, base no pé)
        an = GetComponent<SpriteAnimador>();
        sr = GetComponent<SpriteRenderer>();
        som = gameObject.AddComponent<AudioSource>();
        som.playOnAwake = false;
        y = TerrenoFase1.CHAO;
        if (Checkpoint.ativo && Checkpoint.fase == Fase.numero) { x = Checkpoint.cx; y = Checkpoint.cy; }
        InicioDeTeste();
        seguroX = inicioX = x; seguroY = inicioY = y;
    }

    // TESTE no aparelho: "adb shell am start -n <pacote>/<atividade> --ef vallack_x 3200 --ei vallack_espada 5"
    // começa a fase nesse x (no chão da rua) e/ou com a espada nesse nível
    void InicioDeTeste()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using (var up = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            using (var act = up.GetStatic<AndroidJavaObject>("currentActivity"))
            using (var intent = act.Call<AndroidJavaObject>("getIntent"))
            {
                float tx = intent.Call<float>("getFloatExtra", "vallack_x", -1f);
                if (tx > 0) { x = tx; y = TerrenoFase1.CHAO; Debug.Log("[teste] início em x=" + tx); }
                int nv = intent.Call<int>("getIntExtra", "vallack_espada", 0);
                if (nv > 0) { Jogo.espadaNivel = Mathf.Clamp(nv, 1, 5); furia = 100; Debug.Log("[teste] espada nível " + nv); }
            }
        }
        catch (System.Exception e) { Debug.Log("[teste] sem início de teste: " + e.Message); }
#endif
    }

    void Start()
    {
        escudo = Filho("defesa mágica", Texturas.Brilho(), 101);
        aura = Filho("aura", Texturas.Brilho(), 99);
        escudo.enabled = aura.enabled = false;
        Mostrar();
    }

    SpriteRenderer Filho(string nome, Sprite s, int ordem)
    {
        var go = new GameObject(nome);
        var r = go.AddComponent<SpriteRenderer>();
        r.sprite = s; r.sharedMaterial = aditivo; r.sortingOrder = ordem;
        return r;
    }

    void Update()
    {
        bool livre = bloqueioInput <= 0 && !Telas.Bloqueia;
        if (bloqueioInput > 0) bloqueioInput -= Tempo.DtReal;
        // os apertos entram no buffer mesmo durante a pausa de impacto
        if (livre)
        {
            if (Controles.PuloApertou) bufferPulo = 12;
            if (Controles.GolpeApertou) { bufferGolpe = "Q"; bufferGolpeT = 18; }
            if (Controles.ForteApertou) { bufferGolpe = "T"; bufferGolpeT = 18; pesadoT = 8; }
            if (Controles.BolaApertou) { bufferGolpe = "C"; bufferGolpeT = 18; }
            if (Controles.EsquivaApertou) rolarBuffer = ROLAR_BUFFER;
        }
        float dt = Tempo.Dt;
        if (dt > 0)
        {
            Passo(dt, livre);
            Fisica(dt);
            DepoisDaFisica();
        }
        Mostrar();
    }

    // ===================================================================
    void Passo(float dt, bool livre)
    {
        bool esq = livre && Controles.Esq, dir = livre && Controles.Dir, abaixar = livre && Controles.Baixo, cima = livre && Controles.Cima;
        bool bloqueio = livre && Controles.Defesa, aparar = livre && Controles.DefesaApertou;
        bool jump = livre && Controles.PuloApertou, interagir = livre && Controles.InteragirApertou, furiaBtn = livre && Controles.FuriaApertou;
        int esp = !livre ? 0 : (Controles.Esp1Apertou ? 1 : (Controles.Esp2Apertou ? 2 : (Controles.Esp3Apertou ? 3 : 0)));
        int dirAgora = (dir ? 1 : 0) - (esq ? 1 : 0);

        if (atravessarT > 0) atravessarT -= dt;
        chao = Pisando();

        // LANÇADOR = PULAR + PESADO quase juntos (ou cima + PESADO)
        pesadoT = Mathf.Max(0, pesadoT - dt);
        if (jump && (chao || coyote > 0)) puloT = 8; else puloT = Mathf.Max(0, puloT - dt);

        // ----- temporizadores -----
        tempoInvencivel = Mathf.Max(0, tempoInvencivel - dt);
        if (bufferPulo > 0) bufferPulo -= dt;
        if (bufferGolpeT > 0) { bufferGolpeT -= dt; if (bufferGolpeT <= 0) bufferGolpe = ""; }
        if (cadeiaJanela > 0) { cadeiaJanela -= dt; if (cadeiaJanela <= 0 && golpe == null) cadeia = ""; }
        pouso = Mathf.Max(0, pouso - dt);
        if (defesaFx > 0) defesaFx -= dt;
        if (apararFx > 0) apararFx -= dt;
        if (rolarRecarga > 0) rolarRecarga -= dt;
        if (janelaAparar > 0) janelaAparar -= dt;
        if (apararRecarga > 0) apararRecarga -= dt;
        if (avisoT > 0) avisoT -= dt;

        // cura aos poucos (magia do baú entrando em Twilight)
        if (curaRestante > 0 && !morto)
        {
            float c = Mathf.Min(curaRestante, 0.55f * dt);
            vida = Mathf.Min(vidaMax, vida + c); curaRestante -= c;
            if (vida >= vidaMax) curaRestante = 0;
        }
        // barra de magia dos especiais: enche em 10 segundos
        bool emEspecial = golpe != null && golpe.especial;
        if (!emEspecial && especialCarga < Jogo.ESPECIAL_SEGUNDOS) especialCarga = Mathf.Min(Jogo.ESPECIAL_SEGUNDOS, especialCarga + dt / 60f);
        // MODO FÚRIA: dura 12 s (a barra esvazia)
        if (furiaModo)
        {
            furia -= 100f / Jogo.FURIA_MODO_QUADROS * dt;
            if (Random.value < 0.3f * dt) Efeitos.Faiscas(x + Random.Range(-14f, 14f), y - Random.Range(10f, 60f), 0.3f, 2);
            if (furia <= 0) { furia = 0; furiaModo = false; Efeitos.Tocar("furia_fim", 0.8f); }
        }
        if (!Qte.Ativo && (golpe == null || (golpe.chave != "finalizador" && golpe.chave != "ira"))) CameraVallack.zoom = emEspecial ? 1.14f : 1f;

        // ----- MORTE -----
        if (morto)
        {
            velh = 0;
            if (!chao) velv += GRAV * dt;
            if (an.Indice >= morte.Total - 1) an.Quadro(morte, morte.Total - 1);
            tempoMorte += dt;
            if (tempoMorte >= 90) Telas.FimDeJogo();
            return;
        }

        if (machucado)
        {
            velh = 0;
            if (an.anim != ferido || an.Terminou || an.Indice >= ferido.Total - 0.1f) { machucado = false; an.Tocar(parado, true); }
        }
        bool podeAgir = !machucado;

        // TEIA da Mulher-Aranha: lento, sem pulo e sem rolagem; apertar botões solta mais rápido
        if (teiaImune > 0) teiaImune = Mathf.Max(0, teiaImune - dt);
        if (enredado > 0)
        {
            enredado = Mathf.Max(0, enredado - dt);
            if (jump || Controles.EsquivaApertou || Controles.GolpeApertou || furiaBtn) enredado = Mathf.Max(0, enredado - 13);
            rolarBuffer = 0; bufferPulo = 0; jump = false;
            if (enredado <= 0) teiaImune = 40;
        }

        // ----- BACKDASH: salto rápido para trás (ESQUIVA sem direção) -----
        if (recuando)
        {
            float ra = recuarT;
            recuarT += dt;
            float rp = Mathf.Clamp01(recuarT / RECUAR_DURACAO);
            velh = -facing * RECUAR_VEL * Mathf.Pow(1 - rp, 1.4f);
            if (Mathf.Floor(ra / 3f) != Mathf.Floor(recuarT / 3f)) Rastro(new Color(0.6f, 0.75f, 1f, 1f), 10f);
            Gravidade(dt);
            if (recuarT >= 8 && bufferGolpe != "") { recuando = false; an.Tocar(parado, true); }
            else if (recuarT >= RECUAR_DURACAO) { recuando = false; rolarRecarga = 2; an.Tocar(chao ? parado : queda, true); }
            if (recuando) return;
        }

        // ----- ESQUIVA (rolagem): quadros 2-19 de 26 sem levar dano -----
        if (rolando)
        {
            float tAntes = rolarT;
            rolarT += dt;
            float p = Mathf.Clamp01(rolarT / ROLAR_DURACAO);
            velh = rolarDir * ROLAR_VEL * (1 - 0.72f * p);
            if (Mathf.Floor(tAntes / 3f) != Mathf.Floor(rolarT / 3f)) Rastro(new Color(0.6f, 0.75f, 1f, 1f), 12f);
            if (chao && Mathf.Floor(tAntes / 7f) != Mathf.Floor(rolarT / 7f)) Efeitos.Poeira(x - rolarDir * 10, y, 0.35f);
            if (rolarT >= ROLAR_DURACAO)
            {
                rolando = false; rolarRecarga = 3;
                if (chao) Efeitos.Poeira(x, y, 0.6f);
                an.Tocar(parado, true);
            }
            Gravidade(dt);
            return;
        }
        if (rolarBuffer > 0) rolarBuffer -= dt;
        bool podeRolar = chao && podeAgir && rolarRecarga <= 0 && (golpe == null || !golpe.armadura) && !Escalada.escalando;
        if (rolarBuffer > 0 && podeRolar)
        {
            rolarBuffer = 0;
            GolpeCancelar();
            cadeia = ""; bufferGolpe = "";
            esquivou = false; bloqueando = false; agachado = false;
            if (dirAgora == 0)
            {
                recuando = true; recuarT = 0;
                velv = -2.4f; chao = false;
                an.Quadro(pulo, 1);
                Tocar(sBackdash, 0.8f);
                Efeitos.Poeira(x + facing * 6, y, 0.4f);
            }
            else
            {
                rolando = true; rolarT = 0;
                rolarDir = dirAgora; facing = rolarDir;
                an.Quadro(agachar, 0);
                Efeitos.Tocar("sfx_esquiva", 0.9f);
                Efeitos.Poeira(x - rolarDir * 10, y, 0.5f);
            }
            return;
        }

        // escalando: sem golpes, defesa, esquiva, fúria nem interação
        if (Escalada.escalando) { bufferGolpe = ""; esp = 0; bloqueio = false; aparar = false; furiaBtn = false; interagir = false; }

        // ----- APARAR: apertar a defesa na hora certa -----
        if (aparar && chao && podeAgir && apararRecarga <= 0 && golpe == null)
        {
            janelaAparar = APARAR_JANELA;
            apararRecarga = APARAR_RECARGA;
        }

        // ----- CONTRA-ATAQUE automático logo depois de aparar -----
        if (contraT > 0)
        {
            contraT -= dt;
            if (contraT <= 0 && contraAlvo != null && !contraAlvo.morrendo && podeAgir)
            {
                facing = Mathf.Sign(contraAlvo.x - x); if (facing == 0) facing = 1;
                GolpeCancelar(); GolpeIniciar("contra");
                cadeia = ""; bufferGolpe = "";
                Efeitos.Popup(x + facing * 30, y - 80, "CONTRA-ATAQUE!", new Color32(140, 200, 255, 255));
            }
        }

        // ----- LANÇADOR -----
        if (((pesadoT > 0 && puloT > 0) || (bufferGolpe == "T" && cima)) && noArTempo < 10 && podeAgir && !bloqueando && !Escalada.escalando
            && (golpe == null || (!golpe.armadura && golpe.chave != "lancador")))
        {
            GolpeCancelar(); GolpeIniciar("lancador");
            golpeLetra = "T"; pesadoT = 0; puloT = 0; bufferPulo = 0; bufferGolpe = ""; cadeia = "";
        }

        bool livreParaGolpe = golpe == null || (!golpe.armadura && !golpe.especial && golpeI >= golpe.cancel);

        // ----- FINALIZADOR: BOLA (ou ITEM) perto de um inimigo aberto -----
        bool executou = false;
        if ((bufferGolpe == "C" || interagir) && chao && podeAgir && livreParaGolpe)
        {
            var fin = AlvoFinalizavel();
            if (fin != null)
            {
                facing = Mathf.Sign(fin.x - x); if (facing == 0) facing = 1;
                GolpeCancelar();
                if (fin.usaQte && (fin.ehChefe || fin.vida <= fin.vidaMax * 0.25f + 1)) Qte.Iniciar(fin);
                else
                {
                    alvoFinal = fin;
                    fin.executando = true; fin.velh = 0; fin.empurrao = 0;
                    GolpeIniciar("finalizador");
                }
                cadeia = ""; bufferGolpe = ""; livreParaGolpe = false; executou = true;
            }
        }

        // ----- ITEM: baús, cristais e, longe deles, as SUB-ARMAS -----
        if (interagir && !executou && podeAgir && livreParaGolpe && !Interativo.Usar(this))
        {
            bool agach = abaixar && chao;
            int custo = agach ? 2 : 1;
            if (!agach && Bumerangue.ativo) Avisar("A LÂMINA AINDA NÃO VOLTOU", 45);
            else if (Jogo.essencia < custo) Avisar((agach ? "CHAMA DE SYLLA" : "LÂMINA BUMERANGUE") + ": ESSÊNCIA INSUFICIENTE (" + custo + ")", 70);
            else
            {
                Jogo.essencia -= custo;
                if (dir != esq) facing = dir ? 1 : -1;
                GolpeCancelar();
                GolpeIniciar(agach ? "arremesso_chama" : "arremesso");
                cadeia = ""; bufferGolpe = ""; livreParaGolpe = false;
            }
        }

        // ----- FÚRIA: barra cheia + botão de fúria -----
        if (furiaBtn && furia >= 100 && !furiaModo && chao && podeAgir && livreParaGolpe)
        {
            GolpeCancelar(); GolpeIniciar("ira");
            cadeia = ""; bufferGolpe = ""; livreParaGolpe = false;
        }
        else if (furiaBtn && furia < 100 && !furiaModo) Avisar("A FÚRIA AINDA NÃO ESTÁ CHEIA", 70);

        // ----- ESPECIAIS -----
        if (esp != 0 && podeAgir && livreParaGolpe)
        {
            if (!Jogo.EspecialLiberado(esp)) Avisar(Jogo.EspecialNome(esp) + ": EVOLUA A ESPADA ATÉ O NÍVEL " + Jogo.EspecialNivelReq(esp), 110);
            else if (especialCarga < Jogo.EspecialCusto(esp) * Jogo.ESPECIAL_SEGUNDOS) Avisar("MAGIA INSUFICIENTE", 60);
            else if (chao)
            {
                string ch = esp == 1 ? (abaixar ? "onda_agachado" : "onda") : (esp == 2 ? "queda" : "tremor");
                if (dir != esq) facing = dir ? 1 : -1;
                GolpeCancelar(); GolpeIniciar(ch);
                cadeia = ""; bufferGolpe = "";
            }
        }

        // ----- ATAQUES: QUADRADO / TRIÂNGULO / BOLA e os combos -----
        if (bufferGolpe != "" && podeAgir && !bloqueando)
        {
            bool livreGolpe = golpe == null || (!golpe.especial && !golpe.armadura && golpeI >= golpe.cancel);
            if (livreGolpe)
            {
                string cad = (cadeiaJanela > 0 || golpe != null) ? cadeia : "";
                string prox = Golpes.Proximo(cad, bufferGolpe, !chao, abaixar && chao);
                if (prox == "corte_aereo" && aereoN >= AEREO_MAX) { prox = ""; bufferGolpe = ""; }
                if (prox != "")
                {
                    if (prox == "corte_aereo") aereoN++;
                    string letraG = bufferGolpe;
                    if (dir != esq) facing = dir ? 1 : -1;
                    GolpeCancelar();
                    GolpeIniciar(prox);
                    if (golpe != null)
                    {
                        string letra = (prox == "rasteira" && bufferGolpe == "Q") ? "C" : bufferGolpe;
                        string c = cad + letra;
                        cadeia = (golpe.combo > 0 || !chao) ? "" : (c.Length > 3 ? c.Substring(c.Length - 3) : c);
                        golpeLetra = letraG;
                    }
                    bufferGolpe = "";
                }
            }
        }

        // ----- PULO CANCELA golpes no chão -----
        if (bufferPulo > 0 && chao && golpe != null && !golpe.armadura && !golpe.noAr && podeAgir && !abaixar && enredado <= 0
            && (golpeIdade <= 7 || golpeI >= golpe.cancel))
        {
            string lg = golpeLetra; bool cedo = golpeIdade <= 7;
            GolpeCancelar();
            cadeia = "";
            Pular();
            if (cedo && lg != "") { bufferGolpe = lg; bufferGolpeT = 10; }
        }

        // ----- GOLPE EM ANDAMENTO: a animação segue a tabela de quadros -----
        if (golpe != null)
        {
            var g = golpe;
            var e = g.seq[golpeI];
            if (!g.noAr || chao) velh = 0; else velh -= empurraoUlt;
            if (e.TemAv) velh = facing * e.av;
            if (g.chave == "finalizador" && alvoFinal != null && !alvoFinal.ehChefe && !alvoFinal.morrendo)
            { alvoFinal.x = Mathf.Lerp(alvoFinal.x, x + facing * 34, 0.25f); alvoFinal.velh = 0; }
            golpeT += dt * (furiaModo ? 1.35f : 1f);
            golpeIdade += dt;
            int seguro = 0;
            while (golpe != null && seguro++ < 8)
            {
                e = golpe.seq[golpeI];
                if (golpeT < e.d) break;
                if (e.esp != null)
                {
                    bool noChao = Pisando() && velv >= 0;
                    bool ok = e.esp == "apice" ? velv >= 0 : (e.esp == "descendo" ? (velv >= 0 || noChao) : noChao);
                    if (!ok) { golpeT = e.d; break; }
                }
                golpeT -= e.d;
                golpeI++;
                if (golpeI >= golpe.seq.Length)
                {
                    GolpeCancelar();
                    cadeiaJanela = 16;
                    an.Tocar(chao ? parado : queda, false);
                    break;
                }
                GolpeEntrarQuadro();
            }
            if (golpe != null) GolpeAcertar();
        }

        OndasPasso(dt);

        // ----- ESCALAR: escadas de mão, cordas e correntes -----
        bool escalando = Escalada.Passo(this, dt, livre, jump, abaixar, esq, dir, chao, golpe != null);

        // ----- DEFESA E AGACHAR (sem golpe em andamento) -----
        bool emGolpe = golpe != null;
        bloqueando = (bloqueio || janelaAparar > 0) && chao && !emGolpe && podeAgir && !escalando;
        if (bloqueando)
        {
            velh = 0;
            if (an.anim != defendendo) an.Tocar(defendendo, true);
            if (an.Indice >= defendendo.Total - 1) an.Quadro(defendendo, defendendo.Total - 1);
        }
        agachado = abaixar && chao && !emGolpe && podeAgir && !bloqueando && !escalando;
        escalaY = (agachado || an.anim == agachar || an.anim == agachadoAtaque) ? 0.65f : (an.anim == agachadoEspecial ? 0.8f : 1f);

        // ----- MOVIMENTO -----
        if (chao) { coyote = 6; aereoN = 0; }
        else coyote = Mathf.Max(0, coyote - dt);
        if (!chao) noArTempo += dt;
        else
        {
            if (noArTempo > 14) { pouso = 7; Tocar(sPouso, 0.45f); Efeitos.Poeira(x, y, 0.5f); }
            noArTempo = 0;
        }

        if (!emGolpe && !machucado && !bloqueando && !escalando)
        {
            float v = agachado ? VEL_AGACHADO : VEL_CORRER;
            if (enredado > 0) v *= 0.35f;
            if (chao) VelhPara(dirAgora * v, 1.0f, 1.3f, dt);
            else VelhPara(dirAgora * v, 0.55f, 0.5f, dt);
            if (dirAgora != 0) { facing = dirAgora; pouso = 0; }
            // ▼ + PULO numa passarela ou ilha de mão única: desce por ela
            if (bufferPulo > 0 && abaixar && chao && PlataformaSob() >= 0)
            {
                atravessarT = 14; bufferPulo = 0; coyote = 0;
                y += 2; velv = 1; chao = false;
            }
            if (bufferPulo > 0 && coyote > 0 && !abaixar && enredado <= 0) Pular();

            if (chao)
            {
                if (agachado) an.Quadro(agachar, 0);
                else if (velh != 0)
                {
                    // a corrida avança a animação pela distância percorrida; abaixo de 60% ele anda
                    bool andando = Mathf.Abs(velh) < VEL_CORRER * 0.6f;
                    if (an.anim != andar && an.anim != corrida) animPasso = 0;
                    var s = andando ? andar : corrida;
                    float ciclo = andando ? 64f : 92f;       // px por ciclo completo (2 passadas)
                    animPasso = Mathf.Repeat(animPasso + Mathf.Abs(velh) * dt / ciclo, 1f);
                    an.Quadro(s, animPasso * s.Total);
                }
                else if (pouso > 0) an.Quadro(queda, 3);
                else an.Tocar(parado, false);
            }
            else
            {
                if (velv < 0)
                {
                    if (an.anim != pulo) an.Quadro(pulo, 1);
                    an.Velocidade = 1.4f;
                    if (an.Indice >= 4.9f) an.Indice = 4;
                }
                else
                {
                    if (an.anim != queda) an.Quadro(queda, 0);
                    an.Velocidade = 1f;
                    if (an.Indice >= 2.9f) an.Indice = 0;
                }
            }
        }

        // ----- EMPURRÃO E GRAVIDADE -----
        velh += empurrao;
        empurraoUlt = empurrao;
        empurrao = LerpDt(empurrao, 0, 0.12f, dt);
        if (Mathf.Abs(empurrao) < 0.2f) empurrao = 0;
        if (!escalando) Gravidade(dt);
    }

    void Gravidade(float dt)
    {
        if (!chao) velv += GRAV * dt;
        else if (velv > 0) velv = 0;
    }

    public void Pular(float fator = 1f)
    {
        velv = -VEL_PULO * fator;
        bufferPulo = 0; coyote = 0;
        chao = false; pouso = 0;
        an.Quadro(pulo, 1);
        an.Velocidade = 1.4f;
        Tocar(sPulo, 0.5f);
    }

    public void Avisar(string texto, float quadros) { aviso = texto; avisoT = quadros; Efeitos.Tocar("sfx_negado", 0.5f, 0f); }

    void Rastro(Color cor, float vida) =>
        Efeitos.Fantasma(sr.sprite, transform.position, transform.localScale, transform.rotation, cor, vida);

    Inimigo AlvoFinalizavel()
    {
        Inimigo melhor = null; float dist = 78f;
        foreach (var e in Inimigo.todos)
        {
            if (!e.Finalizavel || e.morrendo || !e.ativo || e.emQte) continue;
            if (e.ehChefe && !e.qtePronto) continue;
            float d = e.ehChefe ? Mathf.Max(0, Mathf.Max(e.Esq - x, x - e.Dir)) : Mathf.Abs(e.x - x);
            bool altOk = e.ehChefe ? (y > e.Topo && y < e.y + 40) : Mathf.Abs(e.y - y) < 50;
            if (d <= dist && altOk) { dist = d; melhor = e; }
        }
        return melhor;
    }

    // ===================================================================
    //  GOLPES
    // ===================================================================
    public void DefinirAlvoFinal(Inimigo a) { alvoFinal = a; }

    public void GolpeIniciar(string chave)
    {
        golpe = Golpes.Criar(chave, this);
        if (golpe == null || golpe.spr == null) { golpe = null; return; }
        golpeI = 0; golpeT = 0; golpeIdade = 0; golpeGrupo = -1; golpeLetra = "";
        atingidos.Clear(); atingidosObj.Clear();
        agachado = false; bloqueando = false;
        if (!golpe.noAr) velh = 0;
        if (golpe.especial)
        {
            especialCarga = Mathf.Max(0, especialCarga - Jogo.EspecialCusto(golpe.acaoEsp) * Jogo.ESPECIAL_SEGUNDOS);
            CameraVallack.Tremer(8f);
        }
        if (golpe.combo > 0 || golpe.especial) Efeitos.Popup(x, Topo - 14, golpe.nome, new Color32(255, 200, 120, 255));
        switch (chave)
        {
            case "corte1": case "arremesso": Tocar(sCorte1, 0.8f); break;
            case "corte2": case "contra": Tocar(sCorte2, 0.8f); break;
            case "corte_aereo": Tocar(sAereo, 0.8f); break;
            case "mergulho": Efeitos.Tocar("atk_mergulho", 0.95f); break;
            case "rasteira": case "rasteira_sangrenta": case "arremesso_chama": Efeitos.Tocar("atk_rasteira", 0.8f); break;
            case "execucao": case "carrasco": case "quebra_escudo": case "lancador": case "corte3": case "frenetico": Tocar(sPesado, 0.95f); break;
        }
        GolpeEntrarQuadro();
    }

    // encerra o golpe atual (fim da animação, dano recebido ou queda do mapa)
    public void GolpeCancelar()
    {
        if (golpe != null && golpe.chave == "finalizador" && alvoFinal != null) alvoFinal.executando = false;
        golpe = null; an.Velocidade = 1f;
        if (!Qte.Ativo) CameraVallack.zoom = 1f;
    }

    // ao entrar num quadro da tabela: eventos e mudança de grupo de acerto
    void GolpeEntrarQuadro()
    {
        var e = golpe.seq[golpeI];
        an.Quadro(golpe.spr, e.q);
        if (e.hit != null && e.grupo != golpeGrupo) { golpeGrupo = e.grupo; atingidos.Clear(); atingidosObj.Clear(); }
        if (e.ev != null) GolpeEvento(e.ev);
        GolpeAcertar();
    }

    // eventos dos quadros (saltos, impactos, efeitos)
    void GolpeEvento(string ev)
    {
        switch (ev)
        {
            case "zoom": CameraVallack.Tremer(6f); break;
            case "salto": velv = -6.0f; velh = facing * 2.4f; Tocar(sPulo, 0.7f); break;
            case "lancar": velv = -6.6f; velh = facing * 0.6f; aereoN = 0; Tocar(sPulo, 0.6f); Efeitos.Poeira(x, y, 0.6f); break;
            case "contra":
                tempoInvencivel = Mathf.Max(tempoInvencivel, 30);
                CameraVallack.zoom = 1.12f; CameraVallack.Tremer(10f);
                Efeitos.Tocar("sfx_contra", 1f);
                break;
            case "bumerangue": Bumerangue.Criar(x + facing * 22, y - 40, facing, aditivo); Efeitos.Tocar("bumerangue", 0.9f); break;
            case "chama": ChamaSylla.Criar(x + facing * 40, y, facing); Efeitos.Tocar("chama_sylla", 1f); CameraVallack.Tremer(6f); break;
            case "mergulho": velv = Mathf.Max(velv, 8.5f); velh = facing * 1.6f; break;
            case "impacto_leve":
                CameraVallack.Tremer(7f); Efeitos.Poeira(x + facing * 40, y, 0.8f); Tocar(sPouso, 0.9f);
                break;
            case "impacto_carrasco":
                velh = 0; CameraVallack.Tremer(10f);
                Efeitos.OndaChao(x + facing * 16, y, 0.75f);
                Tocar(sPouso, 1f); Efeitos.Tocar("sfx_impacto", 0.55f);
                break;
            case "impacto_quebra":
                velh = 0; CameraVallack.Tremer(16f);
                Efeitos.OndaChao(x + facing * 16, y, 1.1f);
                Efeitos.Tocar("sfx_impacto", 0.8f);
                break;
            case "onda":
            case "onda_baixa":
                CameraVallack.Tremer(16f);
                NovaOnda(facing, 132f, ev == "onda_baixa" ? -46f : -80f, 16f, false);
                Efeitos.Tocar("esp_onda", 1f);
                break;
            case "salto_queda": velv = -7.2f; velh = facing * 1.3f; Tocar(sPulo, 0.8f); break;
            case "mergulho_queda": velv = Mathf.Max(velv, 12f); velh = 0; break;
            case "impacto_queda":
                velh = 0; CameraVallack.Tremer(20f);
                GolpeArea(x + facing * 14, 130, 90);
                Efeitos.OndaChao(x + facing * 14, y, 1.3f);
                Efeitos.Tocar("esp_queda", 1f);
                break;
            case "faiscas": Efeitos.Faiscas(x, y - 30, 2f, 16); break;
            case "carga": Efeitos.Faiscas(x, y - 40, 1f, 10); Efeitos.Tocar("esp_carga", 0.85f); break;
            case "carga_max": CameraVallack.Tremer(10f); break;
            case "impacto_tremor":
                velh = 0; CameraVallack.Tremer(26f);
                GolpeArea(x, 250, 100);
                Efeitos.OndaChao(x + facing * 10, y, 2.2f);
                Efeitos.Tocar("esp_tremor", 1f);
                break;
            case "fin_inicio":
                tempoInvencivel = Mathf.Max(tempoInvencivel, 90);
                CameraVallack.zoom = 1.25f; Tocar(sPesado, 1f);
                break;
            case "fin_golpe":
                CameraVallack.zoom = 1.3f;
                Tempo.Impacto(12); Tempo.Lenta(40, 0.35f); CameraVallack.Tremer(18f);
                Efeitos.Tocar("sfx_finalizador", 1f);
                if (alvoFinal != null)
                {
                    var a = alvoFinal;
                    Efeitos.Sangue(a.x, a.MeioY, facing, 1.6f); Efeitos.Faiscas(a.x, a.MeioY, 2f);
                    a.executando = false; a.finalizado = true;
                    a.LevarDano(a.DanoFinalizador(), x, 10f, golpe, true);
                    vida = Mathf.Min(vidaMax, vida + Mathf.Round(vidaMax * 0.08f));
                    FuriaGanhar(4);
                }
                break;
            case "fin_fim": CameraVallack.zoom = 1f; alvoFinal = null; break;
            case "ira_carga":
                tempoInvencivel = Mathf.Max(tempoInvencivel, 80);
                furia = 100; furiaModo = true;
                CameraVallack.zoom = 1.2f; Tempo.Lenta(30, 0.5f); CameraVallack.Tremer(10f);
                Efeitos.Tocar("furia_inicio", 1f);
                Efeitos.Popup(x, Topo - 20, "MODO FÚRIA", new Color32(255, 60, 40, 255));
                Efeitos.Faiscas(x, y - 40, 1.6f, 14);
                break;
            case "ira_golpe":
                CameraVallack.zoom = 1f;
                Tempo.Impacto(10); CameraVallack.Tremer(30f);
                GolpeArea(x, 320, 150);
                NovaOnda(-1f, 300f, -96f, 26f, true); NovaOnda(1f, 300f, -96f, 26f, true);
                Efeitos.OndaChao(x, y, 2.6f);
                Efeitos.Tocar("esp_furia_impacto", 1f);
                break;
        }
    }

    // aplica a área de acerto do quadro atual (cada inimigo 1x por grupo)
    void GolpeAcertar()
    {
        if (golpe == null) return;
        var e = golpe.seq[golpeI];
        if (e.hit == null) return;
        float x1 = x + facing * e.hit[0], x2 = x + facing * e.hit[1];
        float hx1 = Mathf.Min(x1, x2), hx2 = Mathf.Max(x1, x2), hy1 = y + e.hit[2], hy2 = y + e.hit[3];
        var g = golpe;
        for (int i = Inimigo.todos.Count - 1; i >= 0; i--)
        {
            var alvo = Inimigo.todos[i];
            if (alvo.morrendo || !alvo.ativo || atingidos.Contains(alvo)) continue;
            if (!alvo.Toca(hx1, hy1, hx2, hy2)) continue;
            atingidos.Add(alvo);
            // CRÍTICO com a ponta da espada
            float dm = e.dm;
            if (g.dano > 0 && !g.especial && g.chave != "contra")
            {
                float borda = facing > 0 ? alvo.Esq : alvo.Dir;
                if ((borda - x) * facing >= Mathf.Max(Mathf.Abs(e.hit[0]), Mathf.Abs(e.hit[1])) * CRITICO_PONTA)
                {
                    dm *= CRITICO_MULT;
                    Efeitos.Popup(alvo.x, alvo.Topo - 6, "CRÍTICO!", new Color32(255, 230, 120, 255));
                    Tocar(sCritico, 0.8f);
                    Efeitos.Faiscas(Mathf.Lerp(x, alvo.x, 0.7f), alvo.MeioY, 1.6f);
                }
            }
            GolpeFerir(alvo, g, dm, x);
        }
        Destrutivel.Bater(hx1, hy1, hx2, hy2, (g.pesado || g.especial || g.chave == "ira") ? 2 : 1, x, atingidosObj);
    }

    // golpes de área dos especiais (queda, tremor, ira)
    void GolpeArea(float cx, float raio, float altura)
    {
        if (golpe == null) return;
        var g = golpe;
        for (int i = Inimigo.todos.Count - 1; i >= 0; i--)
        {
            var alvo = Inimigo.todos[i];
            if (alvo.morrendo || !alvo.ativo || atingidos.Contains(alvo) || !alvo.Toca(cx - raio, y - altura, cx + raio, y + 12)) continue;
            atingidos.Add(alvo);
            GolpeFerir(alvo, g, 1f, cx);
        }
        Destrutivel.Bater(cx - raio, y - altura, cx + raio, y + 12, 3, cx, atingidosObj);
    }

    // DANO DOS GOLPES (scr_combate)
    float DanoGolpe(Golpe g, Inimigo alvo, float dm)
    {
        if (g.chave == "ira")
        {
            if (alvo.ehChefe) return Mathf.Max(1, Mathf.Round(alvo.vidaMax * 0.10f));
            if (alvo.miniChefe) return Mathf.Max(1, Mathf.Round(alvo.vidaMax * 0.20f));
            if (alvo.bruto) return Mathf.Max(1, Mathf.Ceil(alvo.vidaMax * 0.5f));
            if (alvo is Escudeiro) return Mathf.Max(1, Mathf.Ceil(alvo.vidaMax * 0.7f));
            return alvo.vidaMax;
        }
        if (g.especial)
        {
            float p = g.porcento * (1 + 0.05f * (Jogo.espadaNivel - 1));
            if (alvo.ehChefe) return Mathf.Max(1, Mathf.Round(alvo.vidaMax * p * 0.15f));
            if (alvo.miniChefe) return Mathf.Max(1, Mathf.Round(alvo.vidaMax * p * 0.3f));
            if (alvo.bruto) return Mathf.Max(1, Mathf.Round(alvo.vidaMax * p * 0.6f));
            return Mathf.Max(1, Mathf.Ceil(alvo.vidaMax * p));
        }
        float fm = furiaModo ? 1.5f : 1f;
        if (g.chave == "contra")
        {
            float pc = alvo.ehChefe ? 0.05f : (alvo.miniChefe ? 0.08f : (alvo.bruto ? 0.15f : 0.35f));
            return Mathf.Max(18, Mathf.Round(alvo.vidaMax * pc * Jogo.EspadaDanoMult * fm));
        }
        return Mathf.Max(1, Mathf.Round(g.dano * dm * Jogo.EspadaDanoMult * fm));
    }

    void GolpeFerir(Inimigo alvo, Golpe g, float dm, float origemX)
    {
        float dano = DanoGolpe(g, alvo, dm);
        float cy = alvo.MeioY, px = Mathf.Lerp(x + facing * 20, alvo.x, 0.6f);
        if (!alvo.LevarDano(dano, origemX, g.forca, g, g.Forte)) return;
        if (!alvo.morrendo && !alvo.ehChefe && g.lanca > 0) alvo.Lancar(g.lanca);
        if (!alvo.morrendo && !alvo.ehChefe && g.atordoa > 0) alvo.Atordoar(g.atordoa);
        // peso: pausa maior nos golpes pesados e a câmera "leva" a pancada
        Tempo.Impacto(g.pesado ? 8 : (g.especial ? 5 : 4));
        CameraVallack.Empurrar(facing, g.pesado ? 5f : (g.especial ? 4f : 2.5f));
        Efeitos.SomHit(g.pesado || g.especial);
        Efeitos.Faiscas(px, cy, g.pesado ? 1.3f : 1f);
        Efeitos.Corte(px, cy, facing, g.pesado || g.especial);
        Efeitos.Sangue(px, cy, facing, g.pesado ? 1f : 0.6f);
        FuriaGanhar(g.especial ? 0.5f : (g.pesado ? 1.5f : 1f));
        // MODO FÚRIA: roubo de vida a cada golpe
        if (furiaModo) { vida = Mathf.Min(vidaMax, vida + (alvo.morrendo ? 5 : 2)); Tempo.Impacto(2); }
        // COMBO AÉREO
        if (!alvo.morrendo && !alvo.ehChefe)
        {
            if (g.chave == "lancador") { alvo.Lancar(7.4f); alvo.empurrao = 0; }
            else if (g.chave == "corte_aereo" && !alvo.Pisando()) { alvo.velv = -1.6f; alvo.empurrao *= 0.3f; }
        }
        if (g.chave == "corte_aereo" && !chao) velv = Mathf.Min(velv, -1.2f);
        if (g.combo > 0 || g.especial) CameraVallack.Tremer(9f);
    }

    public void FuriaGanhar(float n)
    {
        if (furia >= 100 || furiaModo) return;
        furia = Mathf.Min(100, furia + n * Jogo.FuriaGanhoMult);
        if (furia >= 100) { Efeitos.Tocar("esp_carga", 0.5f); Efeitos.Popup(x, Topo - 10, "FÚRIA CHEIA!", new Color32(255, 80, 60, 255)); }
    }

    // ----- ONDAS (Onda Carmesim e Ira de Vallack) -----
    void NovaOnda(float d, float distMax, float yTopo, float vidaO, bool ira)
    {
        var o = new Onda { x0 = x, dir = d, dist = 30f, distMax = distMax, yTopo = yTopo, yBase = -2f, vida = vidaO, ira = ira };
        o.sr = Filho("onda", Texturas.Brilho(), 110);
        ondas.Add(o);
    }

    void OndasPasso(float dt)
    {
        for (int k = ondas.Count - 1; k >= 0; k--)
        {
            var on = ondas[k];
            on.dist = Mathf.Min(on.distMax, on.dist + (on.ira ? 12f : 8f) * dt);
            on.vida -= dt;
            float ox1 = on.x0 + on.dir * (on.dist - 20), ox2 = on.x0 + on.dir * (on.dist + 10);
            foreach (var alvo in Inimigo.todos)
            {
                if (on.hit.Contains(alvo) || atingidos.Contains(alvo) || alvo.morrendo || !alvo.ativo) continue;
                if (!alvo.Toca(Mathf.Min(ox1, ox2), y + on.yTopo, Mathf.Max(ox1, ox2), y + on.yBase)) continue;
                on.hit.Add(alvo); atingidos.Add(alvo);
                float f = alvo.ehChefe ? 0 : (alvo.miniChefe ? 1 : (alvo.bruto ? 2 : 3));
                float de = on.ira ? alvo.vidaMax * (f == 0 ? 0.10f : (f == 1 ? 0.2f : (f == 2 ? 0.5f : 1f)))
                                  : alvo.vidaMax * 0.30f * (f == 0 ? 0.15f : (f == 1 ? 0.3f : (f == 2 ? 0.6f : 1f)));
                if (alvo.LevarDano(Mathf.Max(1, Mathf.Round(de)), x, 9f, null, true) && !alvo.morrendo && !alvo.ehChefe) alvo.Atordoar(60);
                Tempo.Impacto(3);
                Efeitos.Faiscas(alvo.x, alvo.MeioY, 1f);
            }
            Destrutivel.Bater(Mathf.Min(ox1, ox2), y + on.yTopo, Mathf.Max(ox1, ox2), y + on.yBase, 2, x, atingidosObj);
            float a = Mathf.Clamp01(on.vida / 16f);
            on.sr.transform.position = Mundo.Tela(on.x0 + on.dir * on.dist, y + on.yTopo * 0.5f, -0.2f);
            on.sr.transform.localScale = new Vector3(36f, -on.yTopo * 1.25f, 1f);
            on.sr.color = on.ira ? new Color(1f, 0.25f, 0.15f, a) : new Color(1f, 0.2f, 0.35f, a);
            if (on.vida <= 0) { Destroy(on.sr.gameObject); ondas.RemoveAt(k); }
        }
    }

    // ===================================================================
    //  DANO
    // ===================================================================
    public bool Intangivel() => (rolando && rolarT >= ROLAR_INVENC_INI && rolarT <= ROLAR_INVENC_FIM) || (recuando && recuarT <= RECUAR_INVENC);

    public void Enredar(float quadros)
    {
        if (morto) return;
        if (enredado <= 0) { Efeitos.Tocar("teia_prende", 0.85f); Efeitos.Popup(x, Topo - 6, "PRESO NA TEIA!", new Color32(235, 235, 240, 255)); }
        enredado = Mathf.Max(enredado, quadros);
    }

    // uma flecha foi aparada / bateu na defesa mágica
    public void AparouProjetil() => Aparou(null);
    public void BloqueouProjetil(float origemX)
    {
        float d = Mathf.Sign(x - origemX);
        if (d == 0) d = -facing;
        empurrao = d * 1.8f;
        tempoInvencivel = 12; defesaFx = 16;
        CameraVallack.Tremer(5f);
        Efeitos.Faiscas(x + facing * 22, MeioY, 0.9f);
        Efeitos.Tocar("sfx_bloqueio", 0.8f);
    }

    public void LevarDano(float dano, float origemX, bool bloqueavel, float forca, Inimigo atacante)
    {
        if (vida <= 0 || morto || Telas.FaseConcluida) return;
        float d = Mathf.Sign(x - origemX);
        if (d == 0) d = 1;
        // ESQUIVA: no meio da rolagem nada acerta Twilight
        if (Intangivel())
        {
            if (!esquivou)
            {
                esquivou = true;
                Tempo.Lenta(16, 0.55f);
                Efeitos.Popup(x, Topo - 6, "ESQUIVA!", new Color32(150, 210, 255, 255));
            }
            return;
        }
        if (tempoInvencivel > 0) return;
        bool deFrente = origemX == x || Mathf.Sign(origemX - x) == facing;
        // APARAR (parry): defesa apertada na hora certa
        if (janelaAparar > 0 && deFrente && atacante != null) { Aparou(atacante); return; }
        // DEFESA MÁGICA
        if (bloqueando && bloqueavel && deFrente)
        {
            BloqueouProjetil(origemX);
            if (atacante != null) atacante.Ricochete(Mathf.Sign(atacante.x - x));
            return;
        }
        // MODO FÚRIA = super armadura (metade do dano)
        if (furiaModo) dano = Mathf.Max(1, Mathf.Round(dano * 0.5f));
        vida = Mathf.Max(0, vida - dano);
        tempoInvencivel = 60;
        Tempo.combo = 0; Tempo.comboTempo = 0;
        CameraVallack.Tremer(8f);
        Tempo.Impacto(6);
        CameraVallack.Empurrar(d, 5f);
        Efeitos.Tocar("sfx_dano", 0.9f);
        Efeitos.Sangue(x, MeioY, d, 1f);
        FuriaGanhar(2);
        // durante especiais, fúria e finalizador Twilight não é interrompido
        if (((golpe != null && golpe.armadura) || furiaModo) && vida > 0) { tempoInvencivel = 30; return; }
        empurrao = d * forca;
        GolpeCancelar();
        cadeia = ""; bufferGolpe = "";
        bloqueando = false; rolando = false; recuando = false; contraT = 0;
        Escalada.Soltar();
        if (vida <= 0)
        {
            morto = true; machucado = false; tempoInvencivel = 0; tempoMorte = 0; curaRestante = 0;
            an.Tocar(morte, true);
            Tempo.Lenta(50, 0.4f);
            Efeitos.Tocar("sfx_derrota", 0.7f, 0f);
        }
        else
        {
            machucado = true;
            an.Tocar(ferido, true);
        }
    }

    // APARAR: o golpe é rebatido; o inimigo fica atordoado e Twilight revida sozinho
    void Aparou(Inimigo atacante)
    {
        janelaAparar = 0; apararRecarga = 0;
        machucado = false;
        apararFx = 24; defesaFx = 16;
        tempoInvencivel = Mathf.Max(tempoInvencivel, 24);
        bloqueando = false;
        Tempo.Impacto(9);
        Tempo.Lenta(34, 0.35f);
        CameraVallack.Tremer(10f);
        Efeitos.Tocar("sfx_aparar", 1f, 0f);
        Efeitos.Faiscas(x + facing * 20, MeioY - 6, 1.8f, 16);
        Efeitos.Corte(x + facing * 20, MeioY - 6, facing, true);
        Efeitos.Popup(x + facing * 20, Topo - 8, "APARADO!", new Color32(140, 200, 255, 255));
        FuriaGanhar(6);
        an.Quadro(defendendo, 2);
        if (atacante != null)
        {
            atacante.Aparado(Mathf.Sign(atacante.x - x));
            if (Mathf.Abs(atacante.x - x) < 140) { contraT = 8; contraAlvo = atacante; }
        }
    }

    // volta à vida no último ponto salvo (checkpoint) ou no começo da fase
    public void Reviver()
    {
        morto = false; machucado = false;
        vida = vidaMax; furia = 0; furiaModo = false; especialCarga = Jogo.ESPECIAL_SEGUNDOS;
        if (Checkpoint.ativo && Checkpoint.fase == Fase.numero) { x = Checkpoint.cx; y = Checkpoint.cy; } else { x = inicioX; y = inicioY; }
        seguroX = x; seguroY = y;
        velh = velv = andaV = empurrao = 0;
        tempoInvencivel = 90; tempoMorte = 0;
        GolpeCancelar();
        an.Tocar(parado, true);
        CameraVallack.Cortar();
    }

    public void Curar(float quanto) { curaRestante += quanto; }

    // ===================================================================
    void DepoisDaFisica()
    {
        x = Mathf.Clamp(x, Mathf.Max(36f, Arena.limEsq + 14f), Mathf.Min(Mundo.SALA_W - 44f, Arena.limDir - 14f));
        // chão firme dos dois lados: ponto de volta
        if (!morto && velv == 0 && Mundo.Colide(x - mw - 14, y, x - mw - 12, y + 2) && Mundo.Colide(x + mw + 12, y, x + mw + 14, y + 2))
        { seguroX = x; seguroY = y; }
        if (y > Mundo.SALA_H + 80f) CaiuNoAbismo();
    }

    // Twilight caiu num abismo. No jogo original é morte na hora
    // (jogador_cair_abismo: levar_dano(vida + 9999)). Disponível aqui: x, y,
    // vida, vidaMax, seguroX/seguroY (último chão firme), velh/velv/andaV,
    // tempoInvencivel, GolpeCancelar(), CameraVallack.Tremer(forca),
    // CameraVallack.Cortar() (a câmera pula para o herói).
    void CaiuNoAbismo()
    {
        // TODO(human): decidir a regra da queda no abismo
        x = seguroX; y = seguroY; velh = velv = andaV = 0;
        GolpeCancelar();
        CameraVallack.Tremer(6f);
    }

    // ===================================================================
    void Mostrar()
    {
        var pos = Mundo.Tela(x, y);
        var rot = Quaternion.identity;
        if (rolando)
        {
            // rola em torno do meio do corpo
            float ang = -rolarDir * 360f * Mathf.Clamp01(rolarT / ROLAR_DURACAO);
            rot = Quaternion.Euler(0, 0, ang);
            var centro = pos + new Vector3(0, 20f, 0);
            pos = centro + rot * new Vector3(0, -20f, 0);
        }
        transform.SetPositionAndRotation(pos, rot);
        transform.localScale = new Vector3(facing * ESCALA, ESCALA, 1f);

        // pisca enquanto está invencível depois de apanhar
        float a = (tempoInvencivel > 0 && !morto && golpe == null && Mathf.Repeat(Time.unscaledTime * 14f, 1f) < 0.45f) ? 0.45f : 1f;
        sr.color = enredado > 0 ? new Color(0.8f, 0.86f, 1f, a) : (furiaModo ? new Color(1f, 0.72f, 0.68f, a) : new Color(1, 1, 1, a));

        if (escudo == null) return;
        // brilho azul da defesa mágica à frente do corpo
        bool ve = bloqueando || defesaFx > 0 || apararFx > 0;
        escudo.enabled = ve;
        if (ve)
        {
            float f = Mathf.Max(defesaFx / 16f, apararFx / 24f);
            escudo.transform.position = Mundo.Tela(x + facing * 16f, y - 34f, -0.1f);
            escudo.transform.localScale = new Vector3(26f + 26f * f, 70f + 30f * f, 1f);
            escudo.color = apararFx > 0 ? new Color(0.85f, 0.95f, 1f, 0.5f + 0.5f * f) : new Color(0.45f, 0.7f, 1f, 0.28f + 0.6f * f);
        }
        // aura vermelha do modo fúria e da carga dos especiais
        bool carga = golpe != null && (golpe.especial || golpe.chave == "ira");
        aura.enabled = furiaModo || carga;
        if (aura.enabled)
        {
            float pu = 0.75f + 0.25f * Mathf.Sin(Time.unscaledTime * 16f);
            aura.transform.position = Mundo.Tela(x, y - 34f, 0.1f);
            aura.transform.localScale = new Vector3(70f * pu, 100f * pu, 1f);
            aura.color = carga ? new Color(1f, 0.3f, 0.5f, 0.45f) : new Color(1f, 0.15f, 0.1f, 0.3f);
        }
    }

    void Tocar(AudioClip c, float vol)
    {
        if (c == null) return;
        som.pitch = Random.Range(0.95f, 1.05f);
        som.PlayOneShot(c, vol);
    }
}
