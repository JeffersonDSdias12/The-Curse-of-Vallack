// =====================================================================
//  Carrasco — O CARRASCO DE VALLACK (obj_mini_boss), mini-chefe do meio
//  da Fase 1.
//  · dorme perto do cristal do meio; quando Twilight entra, muralhas
//    mágicas fecham a arena e a trilha do mini-chefe começa
//  · golpe pesado (a cada 2, um quebra-guarda), salto com onda de choque
//    e investida; depois de 3 ações fica cansado por um instante
//  · não fica tonto com golpes comuns (só aparando ou exausto)
//  · com 60% da vida se enfurece; com 50% e 30% convoca javalis de guerra
//  · com 1/4 da vida cai de joelhos: SEQUÊNCIA DE GOLPES
//  · SEGUNDA VIDA: a primeira sequência não o mata; ele se ergue com a
//    barra cheia e volta mais rápido. Só a segunda sequência o derruba.
// =====================================================================
using UnityEngine;

public class Carrasco : Inimigo
{
    const float ESCALA = 1.65f;
    float arenaX1, arenaX2, tEstado, investidaDir = 1f;
    bool acordado, enfurecido, exaustoUsado, porcos1, porcos2, segundaVida = true, naSegundaVida;
    int acoes;
    SpriteRenderer muroE, muroD;

    protected override void Configurar()
    {
        escalaVis = ESCALA; topoVis = 118f;
        mw = 16f * ESCALA; mh = 68f * ESCALA;
        vidaBase = 460f; danoBase = 20f;
        resisteAtordoar = true; podeLancar = false; usaQte = true; miniChefe = true;
        orbs = 150; essenciaDrop = 4; sangueDrop = 30;
        grav = 0.45f;
        corBase = new Color32(175, 125, 140, 255);
        semPortal = true;
        estado = "dormindo";
        arenaX1 = x - 340f; arenaX2 = x + 300f;
        muroE = Filho(transform, "muralha", Texturas.Brilho(), aditivo, 126);
        muroD = Filho(transform, "muralha", Texturas.Brilho(), aditivo, 126);
        muroE.enabled = muroD.enabled = false;
    }

    protected override void Awake() { base.Awake(); dir = -1f; }

    void Mudar(string e) { estado = e; tEstado = 0; golpeDado = false; golpeSomI = 0; }

    void Despertar()
    {
        if (acordado) return;
        acordado = true;
        Mudar("apresentacao");
        Arena.Fechar(arenaX1, arenaX2, "bgm_mini_boss");
        Hud.MostrarChefe(this, "O CARRASCO DE VALLACK", "GUARDIÃO DA VILA EM CHAMAS");
        Efeitos.Tocar("sfx_rugido", 1f, 0f);
        CameraVallack.Tremer(12f);
        Dialogo.Iniciar("carrasco_inicio");
    }

    protected override void Reagir(float d, float forca)
    {
        empurrao = d * 0.4f;
        if (!acordado) Despertar();
        if (estado == "renascer") { vida = Mathf.Max(vida, 1); return; }
        // só cai pela SEQUÊNCIA DE GOLPES (até ela, a vida para em 1)
        if (vida <= 0)
        {
            if (qteVencido) { if (segundaVida) Renascer(); else MorrerDeVez(d); return; }
            vida = 1;
        }
        // antes de cair, convoca os javalis de guerra
        if (!porcos1 && vida <= vidaMax * 0.5f) { porcos1 = true; InvocarPorcos(Dificuldade.nivel == 0 ? 1 : (Dificuldade.nivel == 3 ? 3 : 2)); }
        else if (!porcos2 && vida <= vidaMax * 0.3f) { porcos2 = true; InvocarPorcos(Dificuldade.nivel == 0 ? 2 : (Dificuldade.nivel == 3 ? 4 : 3)); }
        // FASE 2 com 60% da vida: mais rápido e mais agressivo
        if (!enfurecido && vida <= vidaMax * 0.6f)
        {
            enfurecido = true;
            Efeitos.Tocar("sfx_rugido", 0.9f, 0f); CameraVallack.Tremer(10f);
            Telas.Aviso("O CARRASCO SE ENFURECEU!");
            Dialogo.Iniciar("carrasco_fase2");
        }
        // 1/4 da vida: cai de joelhos e fica pronto para a SEQUÊNCIA DE GOLPES
        if (!exaustoUsado && vida <= vidaMax * 0.25f)
        {
            exaustoUsado = true;
            Mudar("exausto");
            aparadoT = 0;
            Atordoar(260, true);
            CameraVallack.Tremer(8f);
            Telas.Aviso("O CARRASCO CAIU DE JOELHOS  ·  EXECUTE-O!");
        }
    }

    // os JAVALIS DE GUERRA surgem nas pontas da arena, longe de Twilight
    void InvocarPorcos(int nq)
    {
        var p = Jogador.eu; float px = p != null ? p.x : x;
        for (int k = 0; k < nq; k++)
        {
            float sx = k % 2 == 0 ? arenaX1 + 70 + k * 26 : arenaX2 - 70 - k * 26;
            if (Mathf.Abs(sx - px) < 100) sx += sx < px ? -110 : 110;
            sx = Mathf.Clamp(sx, arenaX1 + 40, arenaX2 - 40);
            if (InimigosFase1.eu != null) InimigosFase1.eu.InvocarPorco(sx, y, 6f + k * 16f);
        }
        Efeitos.Tocar("sfx_rugido", 1f, 0f); Efeitos.Tocar("porco_grunhido", 0.9f);
        CameraVallack.Tremer(12f);
        Telas.Aviso("O CARRASCO CONVOCA OS JAVALIS DE GUERRA!");
    }

    // a sequência de golpes falhou: levanta furioso, empurra Twilight e volta a lutar
    public override void QteFalhou()
    {
        enfurecido = true;
        atordoado = 0; aparadoT = 0; atordoadoAcum = 0; imuneAtordoar = 90;
        vida = Mathf.Max(vida, Mathf.Round(vidaMax * 0.4f)); vidaAtraso = vida;
        exaustoUsado = false;
        Mudar("perseguir"); recarga = 30;
        Efeitos.Tocar("sfx_rugido", 1f, 0f); CameraVallack.Tremer(14f);
        Efeitos.OndaChao(x, y, 1.2f);
        if (Jogador.eu != null) Jogador.eu.LevarDano(Mathf.Max(1, Mathf.Round(danoBase * 0.6f)), x, false, 9f, this);
        Telas.Aviso("O CARRASCO SE SOLTOU!");
    }

    // SEGUNDA VIDA: invulnerável enquanto a barra enche; volta enfurecido e mais rápido
    void Renascer()
    {
        segundaVida = false; naSegundaVida = true;
        qteVencido = false; finalizado = false; executando = false; qtePronto = false;
        atordoado = 0; aparadoT = 0; atordoadoAcum = 0;
        vida = 1; vidaAtraso = 1;
        exaustoUsado = false; porcos1 = porcos2 = false; enfurecido = true;
        corBase = new Color32(215, 80, 80, 255);
        Mudar("renascer");
        tempoInvencivel = 30;
        Efeitos.Tocar("sfx_rugido", 1f, 0f);
        CameraVallack.Tremer(22f); Tempo.Lenta(50, 0.4f);
        Efeitos.ChamasMorte(x, y - 50, 1.6f);
        Telas.Aviso("O CARRASCO SE RECUSA A CAIR!");
    }

    void MorrerDeVez(float d)
    {
        Morrer(d);
        Arena.Abrir();
        Hud.EsconderChefe(this);
        Tempo.Lenta(60, 0.35f);
        Telas.Aviso("O CARRASCO CAIU  ·  +" + Mathf.RoundToInt(orbs * (finalizado ? 1.5f : 1f)) + " ORBS");
        for (int k = 0; k < 6; k++) Coleta.Vida(x, y - 50, 6f);
        Dialogo.Iniciar("carrasco_fim");
        Salvar.Gravar();
    }

    protected override void AposAtordoado(bool dentroCampo, float adx)
    {
        if (estado == "dormindo") return;
        if (estado == "exausto")
        {
            // não foi executado: levanta enfurecido, com um pouco de vida de volta
            vida = Mathf.Max(vida, Mathf.Round(vidaMax * 0.35f)); vidaAtraso = vida;
            exaustoUsado = false; enfurecido = true;
            Efeitos.Tocar("sfx_rugido", 0.9f, 0f); CameraVallack.Tremer(10f);
        }
        Mudar("perseguir"); recarga = 20;
    }

    protected override void Agir(Jogador p, float dx, float dy, float adx, bool dentroCampo, bool noChao, bool tem, float dt)
    {
        tEstado += dt;
        float v = naSegundaVida ? 2.3f : (enfurecido ? 1.9f : 1.35f);
        switch (estado)
        {
            case "renascer":
                velh = 0; tempoInvencivel = Mathf.Max(tempoInvencivel, 10);
                an.Tocar(aParado, false, 2f);
                if (tem && dx != 0) dir = Mathf.Sign(dx);
                vida = Mathf.Min(vidaMax, vida + vidaMax / 90f * dt); vidaAtraso = vida; barraTempo = 180;
                if (Random.value < 0.35f * dt) Efeitos.Faiscas(x + Random.Range(-30f, 30f), y - Random.value * 110f, 0.5f, 3);
                if (vida >= vidaMax && tEstado >= 100)
                {
                    vida = vidaAtraso = vidaMax;
                    Mudar("perseguir"); recarga = 20;
                    // o grito do renascimento empurra Twilight para longe
                    Efeitos.Tocar("sfx_rugido", 1f, 0f); CameraVallack.Tremer(16f);
                    Efeitos.OndaChao(x, y, 1.4f);
                    if (tem && adx < 260) p.empurrao = Mathf.Sign(p.x - x) * 6f;
                }
                break;
            case "dormindo":
            case "parado":
                estado = "dormindo";
                an.Tocar(aParado, false, 0.5f); velh = 0;
                if (tem && p.x > arenaX1 + 50 && p.x < arenaX2 && Mathf.Abs(dy) < 160) Despertar();
                break;
            case "apresentacao":
                velh = 0; an.Tocar(aParado, false, 1.6f);
                if (tem && dx != 0) dir = Mathf.Sign(dx);
                if (tEstado >= 100) { Mudar("perseguir"); recarga = 30; }
                break;
            case "perseguir":
                Perseguir(p, tem, dx, dy, adx, noChao, v, dt);
                break;
            case "atacar":
                {
                    velh = 0;
                    int fa = Mathf.FloorToInt(an.Indice);
                    if (fa == 3 && tEstado < 60) velh = dir * 1.5f;
                    if (golpeSomI == 0 && fa >= 3) { golpeSomI = 1; Efeitos.Tocar("atk_pesado", 0.75f, 0.1f); }
                    if (!golpeDado && fa >= 4 && fa <= 6 && tem)
                    {
                        float x1 = x + dir * 8, x2 = x + dir * 92;
                        if (p.Toca(Mathf.Min(x1, x2), y - 96, Mathf.Max(x1, x2), y - 4)) { golpeDado = true; p.LevarDano(danoBase, x, ataqueBloqueavel, 7f, this); }
                        if (fa == 5) CameraVallack.Tremer(4f);
                    }
                    if (an.Terminou) { acoes++; recarga = enfurecido ? 24 : 44; Mudar("perseguir"); an.Tocar(aParado, true); }
                }
                break;
            case "salto_preparo":
                velh = 0;
                if (an.Indice >= 2f)
                {
                    if (tem && dx != 0) dir = Mathf.Sign(dx);
                    float alvoX = Mathf.Clamp(tem ? p.x : x + dir * 200, arenaX1 + 40, arenaX2 - 40);
                    float tempoAr = 2f * 9f / grav;
                    velh = Mathf.Clamp((alvoX - x) / tempoAr, -5.5f, 5.5f);
                    velv = -9f;
                    Mudar("salto_ar");
                    an.Indice = 4f;
                    Efeitos.Tocar("sfx_pulo", 0.9f, 0f);
                }
                break;
            case "salto_ar":
                an.Velocidade = 0.6f;
                if (an.Indice >= 5.5f) an.Indice = 5f;
                if (noChao && velv >= 0 && tEstado > 4)
                {
                    velh = 0; Mudar("salto_pouso");
                    an.Indice = 6f; an.Velocidade = 1f;
                    // ONDA DE CHOQUE: pule ou role para escapar
                    CameraVallack.Tremer(18f);
                    Efeitos.OndaChao(x, y, 1.6f);
                    Efeitos.Tocar("sfx_impacto", 0.9f);
                    if (tem && p.y >= y - 30 && p.Toca(x - 105, y - 40, x + 105, y + 4) && !p.Intangivel()) p.LevarDano(16f, x, false, 7f, null);
                    acoes++;
                }
                break;
            case "salto_pouso":
                velh = 0;
                if (an.Terminou) { recarga = enfurecido ? 20 : 36; Mudar("perseguir"); an.Tocar(aParado, true); }
                break;
            case "investida_preparo":
                velh = 0; an.Tocar(aParado, false, 2f);
                if (Random.value < 0.4f * dt) Efeitos.Poeira(x - dir * 14, y, 0.4f);
                if (tEstado >= 34) { Mudar("investida"); an.Tocar(aCorrer, true, 1.7f); }
                break;
            case "investida":
                {
                    dir = investidaDir;
                    velh = dir * (naSegundaVida ? 6.8f : (enfurecido ? 6.0f : 5.2f));
                    if (Random.value < 0.5f * dt) Efeitos.Poeira(x - dir * 18, y, 0.35f);
                    bool acabou = false;
                    if (!golpeDado && tem && p.Toca(x - 26, y - 90, x + 26, y))
                    {
                        golpeDado = true;
                        float antes = p.vida; bool bloq = p.Bloqueando;
                        p.LevarDano(14f, x, true, 9f, this);
                        if (bloq && p.vida == antes)
                        {
                            // bateu no escudo: tropeça e cansa
                            velh = 0; empurrao = -dir * 3; acoes = 3;
                            Mudar("perseguir"); acabou = true;
                        }
                    }
                    bool parede = Bate(x + dir * 6, y - 4) || x <= arenaX1 + 22 || x >= arenaX2 - 22;
                    if (!acabou && (parede || tEstado > 75))
                    {
                        velh = 0;
                        if (tEstado <= 75)
                        {
                            // bateu na muralha: fica tonto
                            CameraVallack.Tremer(12f);
                            Efeitos.Tocar("dest_pedra", 0.8f);
                            Efeitos.Poeira(x + dir * 20, y - 30, 1f);
                            Atordoar(90, true);
                        }
                        acoes++;
                        Mudar("perseguir"); recarga = 40;
                    }
                }
                break;
            case "cansado":
                velh = 0; an.Tocar(aParado, false, 0.35f);
                if (tEstado >= (naSegundaVida ? 38 : (enfurecido ? 55 : 85))) { Mudar("perseguir"); recarga = 10; }
                break;
            case "exausto":
                velh = 0; an.Tocar(aParado, false, 0.15f);
                break;
        }
    }

    void Perseguir(Jogador p, bool tem, float dx, float dy, float adx, bool noChao, float v, float dt)
    {
        if (!tem) { velh = 0; an.Tocar(aParado, false, 0.6f); return; }
        Virar(dx, false, dt);
        if (acoes >= 3) { acoes = 0; Mudar("cansado"); velh = 0; return; }
        if (recarga <= 0 && noChao)
        {
            if (adx <= 82 && Mathf.Abs(dy) < 70)
            {
                Mudar("atacar");
                contadorAtaques++;
                ataqueBloqueavel = contadorAtaques % 2 != 0;
                velh = 0;
                an.Tocar(aAtaque, true, naSegundaVida ? 0.42f : (enfurecido ? 0.36f : 0.28f));
                Efeitos.Tocar("boss_carga", 0.5f);
                return;
            }
            if (adx >= 130 && adx <= 340 && Random.value < 0.6f) { Mudar("salto_preparo"); velh = 0; an.Tocar(aPular, true, 0.8f); return; }
            if (adx > 260) { Mudar("investida_preparo"); velh = 0; investidaDir = dir; Efeitos.Tocar("sfx_rugido", 0.5f, 0.1f); return; }
        }
        if (adx > 64) { VelhPara(dir * v, 0.3f, 0.5f, dt); an.Tocar(aAndar, false, 1.1f); }
        else { VelhPara(0, 0.3f, 0.5f, dt); an.Tocar(Mathf.Abs(velh) > 0.5f ? aAndar : aParado, false, 0.8f); }
    }

    protected override void PosPasso(float dt)
    {
        // não sai da arena
        if (acordado) x = Mathf.Clamp(x, arenaX1 + 20, arenaX2 - 20);
    }

    protected override void MostrarExtra()
    {
        // de joelhos e tonto: pronto para a sequência de golpes
        qtePronto = !morrendo && estado == "exausto" && atordoado > 0;
        if (!morrendo)
        {
            if (estado == "dormindo") sr.color = Color.Lerp(sr.color, Color.black, 0.25f);
            else if (enfurecido) sr.color = Color.Lerp(sr.color, new Color(1f, 0.47f, 0.43f), 0.45f);
            if (estado == "renascer") visual.localPosition += new Vector3(Random.Range(-2.5f, 2.5f), 0, 0);
        }
        // muralhas mágicas da arena
        bool muros = acordado && !morrendo;
        muroE.enabled = muroD.enabled = muros;
        if (muros)
        {
            float pu = 0.6f + 0.4f * Mathf.Sin(Time.time * 6f);
            muroE.transform.position = Mundo.Tela(arenaX1, y - 110f); muroD.transform.position = Mundo.Tela(arenaX2, y - 110f);
            muroE.transform.localScale = muroD.transform.localScale = new Vector3(26f, 260f, 1f);
            muroE.transform.rotation = muroD.transform.rotation = Quaternion.identity;
            muroE.color = muroD.color = new Color(0.65f, 0.25f, 1f, 0.55f * pu);
        }
    }
}
