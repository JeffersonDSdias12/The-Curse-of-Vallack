// =====================================================================
//  Inimigo — porta do obj_inimigo_base + obj_inimigo_01 (a Besta).
//  Surge do chão por um portal de magia quando Twilight se aproxima;
//  estados: parado, perseguir, atacar, pular_preparo, pular_ar, pular_pouso,
//  (atordoado), morrendo. Regras do original: reação antes de virar, no
//  máximo 2 atacando ao mesmo tempo, a cada 4 golpes um QUEBRA-GUARDA,
//  separação entre inimigos, atordoamento que acumula e liberta, ricochete
//  na defesa, aparado (parry), corpo que fica e evapora, golpe fatal.
//  Os outros inimigos da fase herdam daqui trocando números e animações.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class Inimigo : Entidade
{
    public static readonly List<Inimigo> todos = new List<Inimigo>();

    [Header("Animações")]
    public SpriteAnim aParado, aAndar, aCorrer, aAtaque, aPular, aMorrer;
    public Material lit, aditivo, alfa;

    [Header("Combate")]
    public float vidaBase = 60f, danoBase = 8f;
    public bool elite, ehChefe, miniChefe, bruto, usaQte, invocado;
    public float vidaMult = 1f;             // servos invocados vêm mais fracos
    public int orbs = 12, essenciaDrop = -1, sangueDrop = 6;
    [System.NonSerialized] public bool executando, finalizado, emQte, qtePronto, qteVencido;

    // dano do finalizador: derrota os comuns; nos que resistem tira 25% da vida máxima
    public float DanoFinalizador() => resisteAtordoar ? Mathf.Max(1, Mathf.Round(vidaMax * 0.25f)) : vida;
    public virtual void QteFalhou() { }
    public void FerirNaSequencia(float dano)
    {
        if (barraTempo <= 0) vidaAtraso = vida;
        barraTempo = 180; flashDano = ehChefe ? 3 : 5;
        vida = Mathf.Max(1, vida - dano);
    }
    public float campo = 480f, campoAltura = 130f, alcanceAtaque = 50f, alcanceAtaqueY = 44f, distanciaMinima = 38f;
    public float velCorrer = 1.9f, forcaSalto = 7.2f, velAtaque = 0.35f, recargaMax = 46f;
    public int[][] golpeJanelas = { new[] { 3, 6 } };
    public SpriteAnim aAtordoado;
    public float velAtordoado = 0.4f, zonaPuloMax = 210f;
    public int escudoMax;
    public float[] golpeCaixa = { 6, 46, -52, -6 };
    public float topoVis = 72f, escalaVis = 1f;

    [System.NonSerialized] public float vida, vidaMax, dir = -1f;
    [System.NonSerialized] public bool ativo, morrendo;
    public bool Finalizavel { get; private set; }

    protected const float GRAV = 0.4f, ZONA_PULO_MIN = 85f;
    const int ATACANTES_MAX = 2, QUEBRA_GUARDA = 4;
    const float EVAPORAR_INI = 70f, EVAPORAR_FIM = 180f;

    static int proximoId, falaBatalhaFase;
    readonly int id = ++proximoId;
    protected string estado = "parado";
    protected float tempoInvencivel, barraTempo, flashDano, virarT, vidaAtraso;
    protected float atordoado, atordoadoAnim, atordoadoAcum, imuneAtordoar, aparadoT, libertouFx;
    protected float recarga, recargaSalto, alertaFx, separacao;
    protected bool golpeDado, alertado, pulando, puloObstaculo, ataqueBloqueavel = true, morteFim;
    protected int contadorAtaques, golpeJanelaAtual = -1, golpeSomI;
    protected float morteT;
    protected string surgir = "escondido";
    protected float surgirT, portalRaio;
    protected int escudoVida;
    protected float escudoFx, escudoQuebradoT;
    protected Golpe ultimoGolpe;
    protected Color corBase = Color.white;

    protected SpriteAnimador an;
    protected SpriteRenderer sr, srFlash, sombra, portal, barraFundo, barraAtraso, barraVida, aviso;
    protected Transform visual;

    public bool surgirAgora;                 // invocado: abre o portal depois de surgirAtraso
    public float surgirAtraso;
    protected bool resisteAtordoar, ultimoForte;
    protected bool podeLancar = true;
    protected float morteAnimDur;            // > 0: a morte é desenhada pelo filho (aranha, estátua)
    protected float grav = 0.4f;
    protected bool semPortal;                // chefes: já estão no mapa, não surgem por portal
    protected virtual bool BloquearGolpe(Golpe g, float origemX, bool forte) => false;
    protected virtual void AoMorrer(float d) { }

    // ----- ganchos dos filhos (esqueleto, escudeiro, arqueiro...) -----
    protected virtual void Configurar() { }                                   // números e máscara, antes da vida
    protected virtual bool PassoProprio(float dt) => false;                   // true = o filho cuidou deste quadro
    protected virtual void PosPasso(float dt) { }
    protected virtual void MostrarExtra() { }
    protected virtual void AposAtordoado(bool dentroCampo, float adx) { estado = dentroCampo ? "perseguir" : "parado"; recarga = Mathf.Min(recarga, Random.Range(4, 18)); }
    protected virtual void Reagir(float d, float forca)
    {
        empurrao = d * forca * 0.25f;
        Atordoar(30);
        if (vida <= 0) Morrer(d);
    }

    // ---------------------------------------------------------------
    protected virtual void Awake()
    {
        mw = 16f; mh = 68f;                 // spr_mascara_inimigo (32 x 68)
        visual = new GameObject("corpo").transform;
        visual.SetParent(transform, false);
        sr = visual.gameObject.AddComponent<SpriteRenderer>();
        an = visual.gameObject.AddComponent<SpriteAnimador>();
        todos.Add(this);
    }

    void OnDestroy() { todos.Remove(this); }

    void Start()
    {
        Configurar();
        escudoVida = escudoMax;
        if (aAtordoado == null) aAtordoado = aParado;
        sr.sharedMaterial = lit; sr.sortingOrder = 80;
        srFlash = Filho(visual, "flash", null, aditivo, 81); srFlash.enabled = false;
        sombra = Filho(transform, "sombra", Texturas.Brilho(), alfa, 79);
        sombra.color = new Color(0, 0, 0, 0.45f); sombra.transform.localScale = new Vector3(40f, 8f, 1f);
        portal = Filho(transform, "portal", Texturas.Brilho(), aditivo, 78);
        portal.color = new Color(0.6f, 0.2f, 1f, 0f);
        barraFundo = Filho(transform, "barra fundo", Texturas.Branco(), alfa, 130);
        barraAtraso = Filho(transform, "barra atraso", Texturas.Branco(), alfa, 131);
        barraVida = Filho(transform, "barra vida", Texturas.Branco(), alfa, 132);
        aviso = Filho(transform, "aviso", Texturas.Disco(), aditivo, 133); aviso.enabled = false;
        barraFundo.color = new Color(0, 0, 0, 0.8f); barraAtraso.color = Color.white; barraVida.color = new Color32(230, 80, 65, 255);

        vidaMax = Mathf.Max(1, Mathf.Round(vidaBase * (elite ? 1.8f : 1f) * vidaMult));
        vida = vidaAtraso = vidaMax;
        dir = Random.value < 0.5f ? -1f : 1f;
        recarga = Random.Range(0, 30);
        recargaSalto = Random.Range(40, 120);
        if (elite) { escalaVis *= 1.15f; corBase = new Color(1f, 0.72f, 0.72f); }
        an.Tocar(aParado, true);
        an.Indice = Random.Range(0, aParado.Total);
        ativo = false;
        sr.enabled = false; sombra.enabled = false;
        if (semPortal) { ativo = true; surgir = "ativo"; sr.enabled = true; sombra.enabled = true; }
        Mostrar();
    }

    protected SpriteRenderer Filho(Transform pai, string nome, Sprite s, Material m, int ordem)
    {
        var go = new GameObject(nome);
        go.transform.SetParent(pai, false);
        var r = go.AddComponent<SpriteRenderer>();
        r.sprite = s; r.sharedMaterial = m; r.sortingOrder = ordem;
        return r;
    }

    // ===================================================================
    void Update()
    {
        float dt = Tempo.Dt;
        if (dt <= 0) { Mostrar(); return; }
        var p = Jogador.eu;

        if (PortalPasso(dt, p)) { Mostrar(); return; }
        if (morrendo) { CorpoPasso(dt); Fisica(dt); Mostrar(); return; }
        if (y > Mundo.SALA_H + 300f) { Destroy(gameObject); return; }
        // preso no finalizador de Twilight ou esperando a sequência de golpes de um chefe
        if (executando || emQte || (Qte.Ativo && !emQte))
        {
            velh = 0; empurrao = 0;
            if (executando) { atordoado = Mathf.Max(atordoado, 2); atordoadoAnim += dt; if (p == null || p.GolpeAtual == null || p.GolpeAtual.chave != "finalizador") executando = false; }
            if (!Pisando()) velv += grav * dt; else if (velv > 0) velv = 0;
            Fisica(dt); Mostrar(); return;
        }
        if (PassoProprio(dt)) { Fisica(dt); Mostrar(); return; }

        tempoInvencivel = Mathf.Max(0, tempoInvencivel - dt);
        if (recarga > 0) recarga -= dt;
        if (recargaSalto > 0) recargaSalto -= dt;
        if (barraTempo > 0) barraTempo -= dt;
        if (flashDano > 0) flashDano -= dt;
        if (alertaFx > 0) alertaFx -= dt;
        if (libertouFx > 0) libertouFx -= dt;
        if (escudoFx > 0) escudoFx -= dt;
        if (escudoQuebradoT > 0) escudoQuebradoT = Mathf.Max(0, escudoQuebradoT - dt);
        bool noChao = Pisando();

        bool temAlvo = p != null && !p.morto;
        float dx = temAlvo ? p.x - x : 0, dy = temAlvo ? p.y - y : 0, adx = Mathf.Abs(dx);
        bool dentroCampo = temAlvo && adx <= campo && Mathf.Abs(dy) <= campoAltura;

        // SE o jogador está atacando ENTÃO os inimigos à frente ficam atordoados
        if (temAlvo && p.GolpeAtual != null && escudoVida <= 0)
        {
            float frente = (x - p.x) * p.facing;
            if (frente >= -16 && frente <= 72 && Mathf.Abs(y - p.y) <= 70) Atordoar(10);
        }
        bool fraco = vida <= vidaMax * (resisteAtordoar ? 0.25f : 0.34f);
        bool executavel = !resisteAtordoar && (elite || bruto || this is Escudeiro || this is Estatua) && vida <= vidaMax * 0.25f;
        Finalizavel = !ehChefe && ((atordoado > 0 && (aparadoT > 0 || escudoQuebradoT > 0 || fraco)) || executavel);
        if (ehChefe) Finalizavel = qtePronto;      // a Árvore só entra cambaleando (sequência de golpes)

        bool estavaAtordoado = atordoado > 0;
        if (AtordoamentoPasso(dt))
        {
            if (noChao) velh = 0;
            pulando = false;
            if (estado == "pular_ar" || estado == "pular_pouso" || estado == "pular_preparo") estado = "perseguir";
            an.Tocar(aAtordoado, false, velAtordoado);
        }
        else
        {
            if (estavaAtordoado) AposAtordoado(dentroCampo, adx);
            Agir(p, dx, dy, adx, dentroCampo, noChao, temAlvo, dt);
        }

        // EMPURRÃO
        empurrao = Mathf.Clamp(empurrao, -2.6f, 2.6f);
        if (empurrao != 0)
        {
            velh += empurrao;
            empurrao = LerpDt(empurrao, 0, 0.16f, dt);
            if (Mathf.Abs(empurrao) < 0.2f) empurrao = 0;
        }
        // GRAVIDADE
        if (!noChao) velv += grav * dt;
        else if (velv > 0) velv = 0;

        Fisica(dt);
        x = Mathf.Clamp(x, 48f, Mundo.SALA_W - 48f);
        PosPasso(dt);
        Mostrar();
    }

    // a IA de corpo a corpo (Besta, Esqueleto, Escudeiro); o arqueiro troca por inteiro
    protected virtual void Agir(Jogador p, float dx, float dy, float adx, bool dentroCampo, bool noChao, bool temAlvo, float dt)
    {
        {
            switch (estado)
            {
                case "parado":
                    velh = 0;
                    an.Tocar(aParado, false);
                    if (dentroCampo) { estado = "perseguir"; if (!alertado) alertaFx = 40; alertado = true; }
                    break;
                case "perseguir":
                    Perseguir(p, dx, dy, adx, dentroCampo, noChao, dt);
                    break;
                case "atacar":
                    velh = 0;
                    if (an.anim != aAtaque) an.Tocar(aAtaque, true, velAtaque);
                    an.Velocidade = velAtaque;
                    int fa = Mathf.FloorToInt(an.Indice);
                    if (golpeSomI < golpeJanelas.Length && fa >= golpeJanelas[golpeSomI][0] - 1) { golpeSomI++; Efeitos.Som(Efeitos.Sons?.inimigoGolpe, 0.55f); }
                    for (int w = 0; w < golpeJanelas.Length && temAlvo; w++)
                    {
                        if (fa < golpeJanelas[w][0] || fa > golpeJanelas[w][1]) continue;
                        if (w != golpeJanelaAtual) { golpeJanelaAtual = w; golpeDado = false; }
                        if (golpeDado) continue;
                        float x1 = x + dir * golpeCaixa[0], x2 = x + dir * golpeCaixa[1];
                        if (p.Toca(Mathf.Min(x1, x2), y + golpeCaixa[2], Mathf.Max(x1, x2), y + golpeCaixa[3]))
                        {
                            golpeDado = true;
                            p.LevarDano(danoBase * (elite ? 1.4f : 1f), x, ataqueBloqueavel, 5f, this);
                        }
                    }
                    if (an.Terminou || an.Indice >= aAtaque.Total - 0.05f)
                    {
                        estado = "perseguir"; golpeDado = false;
                        recarga = recargaMax + Random.Range(0, 24);
                        an.Tocar(aParado, true);
                    }
                    break;
                case "pular_preparo":
                    velh = 0;
                    an.Velocidade = 1.3f;
                    if (an.Indice >= 2f)
                    {
                        Virar(dx, true, dt);
                        float tempoAr = 2f * forcaSalto / GRAV;
                        velh = dir * Mathf.Clamp(Mathf.Max(0, adx - 34f) / tempoAr, 1.2f, 4.4f);
                        velv = -forcaSalto;
                        pulando = true; puloObstaculo = false;
                        estado = "pular_ar";
                    }
                    break;
                case "pular_ar":
                    an.Velocidade = 1f;
                    if (puloObstaculo && velv < 1) velh = dir * 2.3f;
                    if (an.Indice >= 5.5f) an.Indice = 5f;
                    if (noChao && velv >= 0)
                    {
                        pulando = false; velh = 0;
                        estado = "pular_pouso";
                        an.Indice = 6f; an.Velocidade = 1.4f;
                        recargaSalto = Random.Range(150, 260);
                        if (adx < 300) CameraVallack.Tremer(3f);
                        Efeitos.Poeira(x, y, 0.8f);
                    }
                    break;
                case "pular_pouso":
                    velh = 0;
                    if (an.Terminou || an.anim != aPular) { estado = "perseguir"; recarga = Mathf.Min(recarga, 6); an.Tocar(aParado, true); }
                    break;
            }
        }

        // SEPARAÇÃO: os inimigos não ficam empilhados
        if (atordoado <= 0 && noChao && (estado == "perseguir" || estado == "parado"))
        {
            separacao = 0;
            foreach (var e in todos)
            {
                if (e == this || e.morrendo || !e.ativo) continue;
                float d = x - e.x;
                if (Mathf.Abs(d) < 26 && Mathf.Abs(y - e.y) < 40)
                {
                    float lado = d == 0 ? (id > e.id ? 1f : -1f) : Mathf.Sign(d);
                    separacao += lado * (26 - Mathf.Abs(d)) * 0.06f;
                }
            }
            velh += Mathf.Clamp(separacao, -1.2f, 1.2f);
        }
    }

    void Perseguir(Jogador p, float dx, float dy, float adx, bool dentroCampo, bool noChao, float dt)
    {
        if (!dentroCampo) { estado = "parado"; alertado = false; velh = 0; return; }
        Virar(dx, false, dt);
        int ativos = 0;
        foreach (var e in todos) if (e != this && e.ativo && e.estado == "atacar") ativos++;
        if (noChao && recarga <= 0 && adx <= alcanceAtaque && Mathf.Abs(dy) <= alcanceAtaqueY && ativos < ATACANTES_MAX)
        {
            estado = "atacar";
            golpeDado = false; golpeJanelaAtual = -1; golpeSomI = 0;
            contadorAtaques++;
            ataqueBloqueavel = contadorAtaques % QUEBRA_GUARDA != 0;
            velh = 0;
            an.Tocar(aAtaque, true, velAtaque);
            return;
        }
        // OBSTÁCULO no caminho: pula por cima
        if (noChao && adx > distanciaMinima && Bate(x + dir * 10, y - 2) && !Bate(x + dir * 10, y - 60) && !Bate(x, y - 60))
        {
            estado = "pular_ar"; puloObstaculo = true; pulando = true;
            velv = -6.9f; velh = dir * 2.3f;
            an.Quadro(aPular, 4); an.Velocidade = 1f;
            return;
        }
        // PULO: só quando o jogador está na zona próxima
        if (noChao && recargaSalto <= 0 && adx >= ZONA_PULO_MIN && adx <= zonaPuloMax && dy > -140 && dy < 50 && Random.value < 0.035f * dt)
        {
            estado = "pular_preparo"; velh = 0;
            an.Tocar(aPular, true, 1.3f);
            return;
        }
        if (adx > distanciaMinima)
        {
            VelhPara(dir * velCorrer, 0.35f, 0.55f, dt);
            an.Tocar(aCorrer, false);
        }
        else
        {
            VelhPara(0, 0.35f, 0.55f, dt);
            an.Tocar(Mathf.Abs(velh) > 0.6f ? aCorrer : aParado, false);
        }
    }

    // v1.14: VIRAR DE LADO com reação (só com o alvo a mais de 8 px do outro lado)
    protected void Virar(float dx, bool ja, float dt)
    {
        if (Mathf.Abs(dx) <= 8 || Mathf.Sign(dx) == dir) { virarT = 0; return; }
        virarT += dt;
        if (ja || virarT >= 7) { dir = Mathf.Sign(dx); virarT = 0; }
    }

    // ===================================================================
    //  PORTAL: escondido -> o portal abre -> a besta sobe do chão
    // ===================================================================
    protected bool PortalPasso(float dt, Jogador p)
    {
        if (ativo)
        {
            if (portalRaio > 0) portalRaio = Mathf.Max(0, portalRaio - 0.04f * dt);
            return false;
        }
        switch (surgir)
        {
            case "escondido":
                if (surgirAgora ? (surgirAtraso -= dt) <= 0
                    : (p != null && !p.morto && Mathf.Abs(p.x - x) <= 420f && Mathf.Abs(p.y - y) <= 200f && CameraVallack.NaTela(x, 24f)))
                {
                    surgir = "portal"; surgirT = 0;
                    // a primeira leva da fase: Twilight fala antes da luta
                    if (!surgirAgora && p != null && falaBatalhaFase != Fase.numero)
                    {
                        falaBatalhaFase = Fase.numero;
                        Efeitos.Popup(p.x, p.Topo - 12, "Servos de Vallack... irão pagar com a vida!", new Color32(255, 120, 110, 255));
                    }
                    Efeitos.Som(Efeitos.Sons?.portal, 0.45f);
                }
                break;
            case "portal":
                surgirT += dt;
                portalRaio = Mathf.Min(1, surgirT / 24f);
                if (surgirT >= 30) { surgir = "subindo"; surgirT = 0; sr.enabled = true; }
                break;
            case "subindo":
                surgirT += dt;
                if (surgirT >= 26)
                {
                    ativo = true; sombra.enabled = true;
                    if (p != null) dir = Mathf.Sign(p.x - x) == 0 ? 1 : Mathf.Sign(p.x - x);
                    Efeitos.Faiscas(x, y - 30, 0.8f, 8);
                }
                break;
        }
        return !ativo;
    }

    // ===================================================================
    //  DANO
    // ===================================================================
    public bool LevarDano(float dano, float origemX, float forca, Golpe golpe, bool forte = false)
    {
        if (vida <= 0 || morrendo || !ativo || emQte) return false;
        if (executando && (golpe == null || golpe.chave != "finalizador")) return false;     // no finalizador só o golpe final acerta
        if (executando) tempoInvencivel = 0;
        if (tempoInvencivel > 0) return false;
        float d = Mathf.Sign(x - origemX);
        if (d == 0) d = 1;
        // ESCUDO: segura golpes de frente até a guarda quebrar (pesados contam em dobro)
        if (escudoVida > 0 && golpe != null)
        {
            bool frente = origemX == x || Mathf.Sign(origemX - x) == dir;
            if (forte) EscudoBater(99, d);       // especiais, fúria e finalizador quebram a guarda na hora
            else if (frente && atordoado <= 0) { EscudoBater(golpe.pesado ? 2 : 1, d); return false; }
        }
        // DEFESA PRÓPRIA (a estátua em forma de pedra)
        if (BloquearGolpe(golpe, origemX, forte)) return false;
        if (barraTempo <= 0) vidaAtraso = vida;
        vida = Mathf.Max(0, vida - dano);
        tempoInvencivel = 6; barraTempo = 180; flashDano = 8;
        Tempo.Golpe();
        CameraVallack.Tremer(4f);
        ultimoGolpe = golpe; ultimoForte = forte;
        Reagir(d, forca);
        return true;
    }

    void EscudoBater(int forca, float d)
    {
        escudoVida = Mathf.Max(0, escudoVida - forca);
        escudoFx = 10;
        tempoInvencivel = 6;
        Efeitos.Som(Efeitos.Sons?.bloqueio, 0.9f);
        Tempo.Impacto(2);
        Efeitos.Faiscas(x + dir * 20, y - 40, 0.9f, 8);
        if (Jogador.eu != null) Jogador.eu.empurrao = -Jogador.eu.facing * 1.6f;
        empurrao = d * 0.8f;
        recarga = Mathf.Min(recarga, 14);
        if (escudoVida <= 0)
        {
            // a guarda quebrou: tonto e aberto para o finalizador
            escudoQuebradoT = 150;
            Efeitos.Som(Efeitos.Sons?.escudoQuebra, 1f);
            Tempo.Impacto(6);
            CameraVallack.Tremer(8f);
            imuneAtordoar = 0; atordoadoAcum = 0;
            Atordoar(110, true);
            empurrao = d * 1.6f;
            Efeitos.Faiscas(x + dir * 18, y - 40, 1.6f, 14);
            Efeitos.Popup(x, Topo - 6, "GUARDA QUEBRADA!", new Color32(255, 220, 140, 255));
        }
    }

    public void Atordoar(float quadros, bool forcar = false)
    {
        if (morrendo || !ativo) return;
        if (ehChefe) return;
        if (resisteAtordoar && !forcar) return;
        if (imuneAtordoar > 0 && !forcar) return;
        if (elite && !forcar) quadros = Mathf.Round(quadros * 0.6f);
        if (atordoado <= 0) atordoadoAnim = 0;
        atordoado = Mathf.Max(atordoado, quadros);
        if (estado == "atacar" || estado == "atirar" || estado == "pular_preparo" || estado == "pular_pouso") { estado = "perseguir"; golpeDado = false; }
    }

    protected bool AtordoamentoPasso(float dt)
    {
        if (imuneAtordoar > 0) imuneAtordoar -= dt;
        if (aparadoT > 0) aparadoT = Mathf.Max(0, aparadoT - dt);
        if (atordoado <= 0) { atordoadoAcum = Mathf.Max(0, atordoadoAcum - dt * 2); return false; }
        atordoado -= dt; atordoadoAnim += dt;
        if (aparadoT <= 0) atordoadoAcum += dt;
        if (atordoadoAcum >= 150)
        {
            // apanhou demais sem parar: liberta-se e fica imune por um instante
            atordoado = 0; atordoadoAcum = 0; imuneAtordoar = 80; libertouFx = 20; recarga = 0;
        }
        if (atordoado <= 0) { atordoado = 0; return false; }
        return true;
    }

    // golpe batendo na defesa mágica: é arremessado e fica tonto
    public void Ricochete(float d)
    {
        if (morrendo || !ativo || ehChefe) return;
        if (d == 0) d = -dir;
        empurrao = d * (resisteAtordoar ? 2.2f : 3.6f);
        velv = Mathf.Min(velv, -2.2f);
        imuneAtordoar = 0;
        Atordoar(24);
        flashDano = 6;
    }

    // o golpe foi APARADO: atordoado por 2 s e pronto para o finalizador
    public void Aparado(float d)
    {
        if (morrendo || !ativo) return;
        if (ehChefe) { flashDano = 8; recarga = Mathf.Max(recarga, 60); return; }
        if (d == 0) d = -dir;
        empurrao = d * 1.8f;
        imuneAtordoar = 0; atordoadoAcum = 0;
        aparadoT = resisteAtordoar ? 70 : 120;
        Atordoar(aparadoT, true);
        flashDano = 8; golpeDado = true;
    }

    public void Lancar(float forca) { if (!morrendo && podeLancar) velv = Mathf.Min(velv, -forca); }

    protected void Morrer(float d)
    {
        if (morrendo) return;
        // o que ele deixa: orbs, essência e sangue (a fúria)
        Jogo.inimigosDerrotados++;
        Coleta.Orbs(x, y - 30, (invocado ? 3 : orbs * (elite ? 3 : 1)) * (finalizado ? 1.5f : 1f));
        int ess = invocado || ehChefe ? 0 : (elite ? 3 : (essenciaDrop >= 0 ? essenciaDrop : (Random.value < 0.35f ? 1 : 0)));
        if (ess > 0) Coleta.Essencia(x, y - 34, ess);
        Coleta.Sangue(x, y - 30, invocado ? 2 : (elite ? sangueDrop * 2 : sangueDrop));
        // GOLPE FATAL: pausa, câmera lenta e o monstro explode em chamas
        float tam = Mathf.Clamp(mh / 64f, 0.8f, 2.4f);
        Tempo.Impacto(7);
        CameraVallack.Empurrar(d, 6f);
        CameraVallack.Tremer(9f);
        if (Tempo.FatalLivre()) Tempo.Lenta(16, 0.35f);
        Efeitos.ChamasMorte(x, MeioY, tam);
        Efeitos.Sangue(x, MeioY, d, 1.4f);
        Efeitos.Som(Efeitos.Sons?.explosao, 0.45f, 0.1f);
        morrendo = true; pulando = false; atordoado = 0; Finalizavel = false;
        estado = "morrendo";
        velh = d * 1.6f; velv = Mathf.Min(velv, 0); empurrao = 0;
        morteFim = false; morteT = 0;
        if (morteAnimDur > 0) an.Quadro(aMorrer, 0); else an.Tocar(aMorrer, true);
        srFlash.enabled = false;
        AoMorrer(d);
    }

    protected virtual void CorpoPasso(float dt)
    {
        velh = LerpDt(velh, 0, 0.12f, dt);
        if (!Pisando()) velv += grav * dt; else if (velv > 0) velv = 0;
        if (morteAnimDur > 0) morteFim = morteT >= morteAnimDur;
        else if (!morteFim && (an.Terminou || an.Indice >= aMorrer.Total - 0.1f)) { morteFim = true; an.Quadro(aMorrer, aMorrer.Total - 1); }
        morteT += dt;
        float e = Mathf.Clamp01((morteT - EVAPORAR_INI) / (EVAPORAR_FIM - EVAPORAR_INI));
        if (e > 0)
        {
            // a maldição evapora o corpo
            var c = sr.color; c.a = 1f - e; sr.color = c;
            if (Random.value < 0.35f * dt) Efeitos.Faiscas(x + Random.Range(-14f, 14f), y - Random.Range(4f, 40f), 0.35f, 3);
            if (e >= 1f) Destroy(gameObject);
        }
    }

    // ===================================================================
    protected void Mostrar()
    {
        transform.position = Mundo.Tela(x, y);
        float trem = atordoado > 0 ? Mathf.Sin(atordoadoAnim * 1.4f) * 1.5f : 0f;
        float sobe = 1f;
        if (!ativo && surgir == "subindo") sobe = Mathf.Clamp01(surgirT / 26f);
        visual.localPosition = new Vector3(trem, -(1f - sobe) * 26f, 0);
        visual.localScale = new Vector3(dir * escalaVis, escalaVis * Mathf.Lerp(0.55f, 1f, sobe), 1f);

        Color cor = corBase;
        if (atordoado > 0) cor = Color.Lerp(cor, new Color(0.8f, 0.8f, 1f), 0.6f);
        if (imuneAtordoar > 0 && !morrendo) cor = new Color(1f, 0.67f, 0.59f);
        if (morrendo) { cor = Color.Lerp(cor, new Color(0.35f, 0.31f, 0.31f), morteFim ? 0.35f : 0f); cor.a = sr.color.a; }
        else if (!ativo) cor.a = sobe;
        sr.color = cor;

        bool flash = flashDano > 0 && !morrendo;
        srFlash.enabled = flash;
        if (flash) { srFlash.sprite = sr.sprite; srFlash.color = new Color(1, 1, 1, 0.9f); }

        float pr = ativo ? portalRaio : (surgir == "escondido" ? 0f : Mathf.Max(portalRaio, 0.6f));
        portal.enabled = pr > 0.01f;
        if (portal.enabled)
        {
            float pulsa = 0.85f + 0.15f * Mathf.Sin(Time.time * 14f);
            portal.transform.localPosition = new Vector3(0, 2f, 0);
            portal.transform.localScale = new Vector3(70f * pr * pulsa, 20f * pr, 1f);
            portal.color = new Color(0.62f, 0.22f, 1f, 0.85f * pr);
        }
        sombra.transform.localPosition = new Vector3(0, 0, 0);

        // barra de vida sobre a cabeça depois de apanhar
        bool barra = ativo && !morrendo && barraTempo > 0 && vida > 0;
        barraFundo.enabled = barraAtraso.enabled = barraVida.enabled = barra;
        if (barra)
        {
            const float L = 52f;
            vidaAtraso = LerpDt(vidaAtraso, vida, 0.06f, Mathf.Max(Tempo.Dt, 0.01f));
            float a = Mathf.Min(1, barraTempo / 24f), by = topoVis + 6f;
            barraFundo.transform.localPosition = new Vector3(-L / 2f - 2f, by - 2f, 0);
            barraFundo.transform.localScale = new Vector3(L + 4f, 8f, 1f);
            barraAtraso.transform.localPosition = new Vector3(-L / 2f, by, 0);
            barraAtraso.transform.localScale = new Vector3(L * Mathf.Clamp01(vidaAtraso / vidaMax), 4f, 1f);
            barraVida.transform.localPosition = new Vector3(-L / 2f, by, 0);
            barraVida.transform.localScale = new Vector3(L * Mathf.Clamp01(vida / vidaMax), 4f, 1f);
            barraFundo.color = new Color(0, 0, 0, 0.8f * a);
            barraAtraso.color = new Color(1, 1, 1, a);
            barraVida.color = new Color(0.9f, 0.31f, 0.25f, a);
        }

        // aviso sobre a cabeça: "!" ao notar o herói, vermelho pulsando no QUEBRA-GUARDA,
        // dourado quando está pronto para o finalizador
        bool quebra = estado == "atacar" && !ataqueBloqueavel && an.Indice < golpeJanelas[golpeJanelas.Length - 1][1] + 1;
        aviso.enabled = ativo && !morrendo && (quebra || alertaFx > 0 || Finalizavel);
        if (aviso.enabled)
        {
            float pulsa = 0.75f + 0.25f * Mathf.Sin(Time.unscaledTime * 16f);
            aviso.transform.localPosition = new Vector3(0, topoVis + 16f, 0);
            float t = quebra ? 9f * pulsa : (Finalizavel ? 7f * pulsa : 5f);
            aviso.transform.localScale = new Vector3(t, t, 1f);
            aviso.color = quebra ? new Color(1f, 0.25f, 0.12f, pulsa) : (Finalizavel ? new Color(1f, 0.85f, 0.3f, pulsa) : new Color(1f, 0.35f, 0.25f, Mathf.Clamp01(alertaFx / 12f)));
        }
        MostrarExtra();
    }
}
