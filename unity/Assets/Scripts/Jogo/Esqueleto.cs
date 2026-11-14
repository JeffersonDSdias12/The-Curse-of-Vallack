// =====================================================================
//  Esqueleto — ESQUELETO GUERREIRO (obj_esqueleto, filho da Besta)
//  · rápido, com GOLPE DUPLO: corte largo (quadros 2-3) e estocada (6-7)
//  · REERGUER: derrubado por golpes comuns, desmonta numa pilha de ossos e
//    se levanta ~3,5 s depois com metade da vida (uma vez só). Golpear a
//    pilha, especiais, a Fúria, o finalizador e projéteis rebatidos acabam com ele.
//  Escudeiro — BESTA ESCUDEIRA (obj_inimigo_03): o escudo segura os golpes
//  de frente; é preciso quebrar a guarda ou atacar pelas costas.
// =====================================================================
using UnityEngine;

public class Esqueleto : Inimigo
{
    public bool reerguido;
    float caidoT, erguerT, andarT, andarImg;
    const float CAIDO_DUR = 210f;
    SpriteRenderer brilho;

    protected override void Configurar()
    {
        mw = 11f; mh = 58f;                 // spr_mascara_esqueleto (22 x 58)
        escalaVis = 1.6f; topoVis = 74f;
        vidaBase = 45f; danoBase = 7f; orbs = 10;
        recargaMax = 40f; velCorrer = 2.3f;
        zonaPuloMax = 0f;
        alcanceAtaque = 46f; distanciaMinima = 34f;
        golpeJanelas = new[] { new[] { 2, 3 }, new[] { 6, 7 } };
        golpeCaixa = new[] { 4f, 44f, -50f, -6f };
        velAtaque = 0.7f; velAtordoado = 0.9f;
        brilho = Filho(transform, "brilho dos ossos", Texturas.Brilho(), aditivo, 82);
        brilho.enabled = false;
    }

    bool NoChao => estado == "caido" || estado == "erguendo";

    protected override void Reagir(float d, float forca)
    {
        var sons = Efeitos.Sons;
        // golpe na pilha de ossos: agora acabou de vez
        if (NoChao)
        {
            vida = 0;
            Efeitos.Som(sons?.ossoQuebra, 0.95f);
            Morrer(d);
            velh = 0;
            an.Quadro(aMorrer, aMorrer.Total - 1);
            morteFim = true;
            Efeitos.Faiscas(x, y - 12, 1f, 7);
            return;
        }
        empurrao = d * forca * 0.25f;
        Atordoar(30);
        if (vida > 0) return;
        if (!reerguido && !ultimoForte)
        {
            // REERGUER: desmonta numa pilha de ossos (ainda não foi derrotado)
            estado = "caido"; caidoT = 0;
            vida = 1; barraTempo = 0; atordoado = 0; pulando = false;
            tempoInvencivel = 18;
            velh = d * 1.2f; empurrao = 0;
            an.Quadro(aMorrer, 0);
            Efeitos.Som(sons?.ossoDesmonta, 0.9f);
            return;
        }
        Morrer(d);
        Efeitos.Som(sons?.ossoDesmonta, 0.8f);
    }

    protected override bool PassoProprio(float dt)
    {
        if (!NoChao) return false;
        tempoInvencivel = Mathf.Max(0, tempoInvencivel - dt);
        if (flashDano > 0) flashDano -= dt;
        atordoado = 0; barraTempo = 0;
        velh = LerpDt(velh, 0, 0.15f, dt);
        if (Mathf.Abs(velh) < 0.05f) velh = 0;
        if (!Pisando()) velv += grav * dt; else if (velv > 0) velv = 0;
        int n = aMorrer.Total;
        if (estado == "caido")
        {
            float antes = caidoT;
            caidoT += dt;
            an.Quadro(aMorrer, Mathf.Min(n - 1, caidoT * 0.16f));
            if (caidoT >= CAIDO_DUR - 50 && Mathf.Floor(antes / 12f) != Mathf.Floor(caidoT / 12f)) Efeitos.Som(Efeitos.Sons?.ossoChocalho, 0.45f);
            if (caidoT >= CAIDO_DUR) { estado = "erguendo"; erguerT = 0; Efeitos.Som(Efeitos.Sons?.ossoErgue, 0.85f); }
        }
        else
        {
            erguerT += dt;
            an.Quadro(aMorrer, Mathf.Max(0, (n - 1) - erguerT * 0.2f));
            if (Random.value < 0.3f * dt) Efeitos.Faiscas(x + Random.Range(-14f, 14f), y - Random.Range(0f, 50f), 0.3f, 2);
            if (erguerT >= (n - 1) / 0.2f)
            {
                // de pé de novo, com metade da vida (não se levanta uma segunda vez)
                estado = "perseguir"; reerguido = true;
                vida = Mathf.Max(1, Mathf.Round(vidaMax * 0.5f)); vidaAtraso = vida;
                barraTempo = 120; imuneAtordoar = 50; recarga = 18;
                alertaFx = 40; alertado = true; andarT = 66;
                an.Tocar(aParado, true);
                CameraVallack.Tremer(3f);
                Efeitos.Faiscas(x, y - 30, 0.9f, 8);
            }
        }
        return true;
    }

    protected override void PosPasso(float dt)
    {
        // a animação de dano termina com o esqueleto desmontado: em loop só nos quadros 0-7
        if (an.anim == aAtordoado && an.Indice >= 7.9f) an.Indice = 1f;
        // recém-erguido: ainda cambaleia, ANDANDO, antes de voltar a correr
        if (andarT > 0)
        {
            andarT -= dt;
            if (an.anim == aCorrer && estado == "perseguir")
            {
                andarImg = Mathf.Repeat(andarImg + 0.17f * dt, aAndar.Total);
                an.Quadro(aAndar, andarImg);
                velh = Mathf.Clamp(velh, -velCorrer * 0.45f, velCorrer * 0.45f);
                andaV = velh;
            }
        }
    }

    protected override void MostrarExtra()
    {
        // a pilha de ossos brilha vermelho quando está para se levantar
        float r = estado == "caido" ? Mathf.Clamp01((caidoT - (CAIDO_DUR - 80)) / 80f) : (estado == "erguendo" ? 1f : 0f);
        brilho.enabled = r > 0 && !morrendo;
        if (!brilho.enabled) return;
        float pu = 0.5f + 0.5f * Mathf.Sin(Time.time * 14f);
        brilho.transform.localPosition = new Vector3(0, 8f, 0);
        brilho.transform.localScale = new Vector3(56f, 24f, 1f);
        brilho.color = estado == "erguendo" ? new Color(0.75f, 0.2f, 1f, 0.5f) : new Color(0.8f, 0.16f, 0.16f, r * (0.35f + 0.3f * pu));
    }
}

public class Escudeiro : Inimigo
{
    public SpriteAnim aEscudo;          // spr_escudo: 3 quadros (inteiro, rachado, quase quebrado)
    SpriteRenderer escudo;

    protected override void Configurar()
    {
        vidaBase = 85f; danoBase = 10f; orbs = 20; sangueDrop = 8;
        recargaMax = 60f; velCorrer = 1.5f;
        zonaPuloMax = 0f;
        escudoMax = 4;
        corBase = new Color32(165, 175, 190, 255);
        escudo = Filho(transform, "escudo", null, lit, 83);
    }

    protected override void MostrarExtra()
    {
        bool ve = ativo && escudoVida > 0 && !(morrendo && morteFim) && aEscudo != null;
        escudo.enabled = ve;
        if (!ve) return;
        int q = Mathf.Clamp(Mathf.FloorToInt((1f - (float)escudoVida / escudoMax) * 3f), 0, 2);
        float ox = 18f;
        if (estado == "atacar" && an.Indice >= 3 && an.Indice < 7) ox = 28f;
        float tr = escudoFx > 0 ? Random.Range(-1.5f, 1.5f) : 0f;
        escudo.sprite = aEscudo.Quadro(q);
        escudo.transform.localPosition = new Vector3(dir * ox + tr, 38f, -0.01f);
        escudo.transform.localScale = new Vector3(dir * 1.25f, 1.25f, 1f);
        escudo.color = escudoFx > 0 ? new Color(1f, 0.9f, 0.78f) : Color.white;
    }
}
