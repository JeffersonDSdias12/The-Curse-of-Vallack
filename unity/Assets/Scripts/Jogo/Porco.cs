// =====================================================================
//  Porco — PORCO CORROMPIDO, o Homem-Porco (obj_porco), brutamontes
//  · golpes comuns não o atordoam nem o lançam (só aparar ou a exaustão)
//  · CORTE VERMELHO de perto (um em cada três QUEBRA a guarda)
//  · SALTO ESMAGADOR: onda de choque ao cair (pule ou role)
//  · CORTE ROXO: onda de magia rente ao chão (pule ou role)
//  · FÚRIA (dificuldade DIFÍCIL para cima): com metade da vida ruge,
//    invoca esqueletos por portais e fica mais rápido
// =====================================================================
using UnityEngine;

public static class Dificuldade
{
    public static int nivel = 1;          // 0 fácil · 1 médio · 2 difícil · 3 extremo
}

public class Porco : Inimigo
{
    public SpriteAnim aSalto, aRoxo, aFuria;
    const float ESCALA = 1.85f, ALCANCE = 66f, FORCA_SALTO = 8f;
    float recargaSaltoP, recargaOnda, noArT, velP = 1.9f;
    bool viu, ondaSolta, furioso, furiaPendente, invocou;

    protected override void Configurar()
    {
        mw = 22f; mh = 72f;                 // spr_mascara_porco (44 x 72)
        escalaVis = ESCALA; topoVis = 96f;
        vidaBase = invocado ? 96f : 160f; danoBase = 13f;
        campo = 560f; campoAltura = 160f;
        resisteAtordoar = true; podeLancar = false; bruto = true;
        orbs = 45; essenciaDrop = 2; sangueDrop = 12;
        grav = 0.45f;
        golpeJanelas = new[] { new[] { 3, 4 }, new[] { 8, 8 } };
        recargaMax = 70f;
    }

    protected override void Awake() { base.Awake(); dir = -1f; }

    protected override void Reagir(float d, float forca)
    {
        empurrao = d * forca * 0.15f;
        if (vida <= 0) { Morrer(d); velh = d * 0.6f; Efeitos.Som(Efeitos.Sons?.porcoGrunhido, 1f); return; }
        if (!invocou && vida <= vidaMax * 0.5f) furiaPendente = true;
    }

    protected override void AposAtordoado(bool dentroCampo, float adx)
    {
        if (estado == "rugir" || estado == "invocar") furiaPendente = !invocou;
        estado = dentroCampo ? "perseguir" : "parado";
        recarga = Mathf.Min(recarga, 12);
    }

    bool PodeAndar(float d, float passo)
    {
        float nx = x + d * passo;
        return nx >= 48f && nx <= Mundo.SALA_W - 48f && !Bate(nx, y - 4);
    }

    protected override void Agir(Jogador p, float dx, float dy, float adx, bool dentro, bool noChao, bool temAlvo, float dt)
    {
        if (recargaSaltoP > 0) recargaSaltoP -= dt;
        if (recargaOnda > 0) recargaOnda -= dt;
        if (!noChao) noArT += dt; else if (velv >= 0) noArT = 0;
        if (dentro && !viu && CameraVallack.NaTela(x, 0))
        {
            viu = true; alertaFx = 40;
            recarga = Random.Range(30, 60); recargaSaltoP = Random.Range(120, 220); recargaOnda = Random.Range(70, 150);
            Efeitos.Som(Efeitos.Sons?.porcoGrunhido, 0.8f);
        }
        // FÚRIA (metade da vida): ruge e invoca esqueletos assim que estiver no chão
        if (furiaPendente && Dificuldade.nivel >= 2 && !invocou && noChao && (estado == "perseguir" || estado == "parado"))
        {
            furiaPendente = false; estado = "rugir"; velh = 0;
            an.Tocar(aFuria, true, 0.8f);
            Efeitos.Som(Efeitos.Sons?.rugido, 0.9f);
            CameraVallack.Tremer(8f);
        }
        switch (estado)
        {
            case "parado":
                velh = 0; an.Tocar(aParado, false);
                if (dentro && viu) estado = "perseguir";
                break;
            case "perseguir":
                Perseguir(dentro, dx, dy, adx, noChao, dt);
                break;
            case "atacar":
                velh = 0;
                {
                    int fa = Mathf.FloorToInt(an.Indice);
                    if (golpeSomI < golpeJanelas.Length && fa >= golpeJanelas[golpeSomI][0] - 1) { golpeSomI++; Efeitos.Som(Efeitos.Sons?.atkPesado, 0.55f); }
                    for (int w = 0; w < golpeJanelas.Length && temAlvo; w++)
                    {
                        if (fa < golpeJanelas[w][0] || fa > golpeJanelas[w][1]) continue;
                        if (w != golpeJanelaAtual) { golpeJanelaAtual = w; golpeDado = false; }
                        if (golpeDado) continue;
                        float x1 = x + dir * 2, x2 = x + dir * 64;
                        if (p.Toca(Mathf.Min(x1, x2), y - 72, Mathf.Max(x1, x2), y - 4)) { golpeDado = true; p.LevarDano(danoBase, x, ataqueBloqueavel, 7f, this); }
                    }
                    if (an.Terminou)
                    {
                        estado = "perseguir"; golpeDado = false;
                        recarga = Mathf.Round(recargaMax * (furioso ? 0.7f : 1f)) + Random.Range(0, 20);
                        an.Tocar(aParado, true);
                    }
                }
                break;
            case "salto_prep":
                velh = 0;
                if (temAlvo) Virar(dx, true, dt);
                if (an.Indice >= 2f)
                {
                    float tar = 2f * FORCA_SALTO / grav;
                    velh = dir * Mathf.Clamp((adx - 20f) / tar, 2f, 8.5f);
                    velv = -FORCA_SALTO;
                    estado = "salto_ar"; noArT = 0.01f;
                    an.Velocidade = 0.9f;
                    Efeitos.Som(Efeitos.Sons?.pulo, 0.7f);
                    Efeitos.Poeira(x, y, 0.8f);
                }
                break;
            case "salto_ar":
                if (an.Indice >= 5.9f) an.Indice = 5f;
                if (velh != 0 && !PodeAndar(Mathf.Sign(velh), 26)) velh = 0;
                if (noChao && velv >= 0 && noArT <= 0)
                {
                    // ATERRISSAGEM: onda de choque no chão (pule ou role para escapar)
                    velh = 0; estado = "salto_pouso";
                    an.Indice = 6f; an.Velocidade = 0.8f;
                    Efeitos.Som(Efeitos.Sons?.porcoImpacto, 1f);
                    CameraVallack.Tremer(9f);
                    for (int k = -3; k <= 3; k++) Efeitos.Poeira(x + k * 30f, y, 1.2f);
                    Efeitos.Corte(x, y - 4, 1f, true);
                    if (temAlvo && p.Pisando() && !p.Intangivel() && Mathf.Abs(p.x - x) <= 112 && Mathf.Abs(p.y - y) < 40)
                    {
                        p.LevarDano(15f, x, false, 8f, null);
                        if (!p.morto) p.velv = Mathf.Min(p.velv, -3f);
                    }
                }
                break;
            case "salto_pouso":
                velh = 0;
                if (an.Terminou)
                {
                    estado = "perseguir";
                    recargaSaltoP = Mathf.Round(330f * (furioso ? 0.7f : 1f)) + Random.Range(0, 60);
                    recarga = Mathf.Min(recarga, 10);
                    an.Tocar(aParado, true);
                }
                break;
            case "onda":
                velh = 0;
                if (!ondaSolta && an.Indice >= 3f)
                {
                    ondaSolta = true;
                    Magia.Criar("onda", x + dir * 46, y, dir * (furioso ? 6.2f : 5.2f), 0, 11f, this, aditivo, alfa);
                    Efeitos.Som(Efeitos.Sons?.magiaOnda, 0.85f);
                }
                if (an.Terminou)
                {
                    estado = "perseguir";
                    recargaOnda = Mathf.Round(280f * (furioso ? 0.7f : 1f)) + Random.Range(0, 60);
                    recarga = Mathf.Max(recarga, 30);
                    an.Tocar(aParado, true);
                }
                break;
            case "rugir":
                velh = 0;
                if (an.Terminou) { estado = "invocar"; an.Tocar(aFuria, true, 0.8f); }
                break;
            case "invocar":
                velh = 0;
                if (!invocou && an.Indice >= 5f) { invocou = true; Invocar(p); }
                if (an.Terminou) { furioso = true; velP = 2.5f; estado = "perseguir"; recarga = 10; an.Tocar(aParado, true); }
                break;
        }
    }

    void Perseguir(bool dentro, float dx, float dy, float adx, bool noChao, float dt)
    {
        if (!dentro) { estado = "parado"; velh = 0; return; }
        Virar(dx, false, dt);
        if (noChao)
        {
            // CORTE VERMELHO: de perto
            if (recarga <= 0 && adx <= ALCANCE && Mathf.Abs(dy) < 60)
            {
                estado = "atacar"; golpeDado = false; golpeJanelaAtual = -1; golpeSomI = 0;
                contadorAtaques++;
                ataqueBloqueavel = contadorAtaques % 3 != 0;
                velh = 0;
                an.Tocar(aAtaque, true, furioso ? 1f : 0.8f);
                return;
            }
            // SALTO ESMAGADOR: média distância
            if (recargaSaltoP <= 0 && adx >= 130 && adx <= 360 && Mathf.Abs(dy) < 120 && PodeAndar(dir, 60))
            {
                estado = "salto_prep"; velh = 0;
                an.Tocar(aSalto, true, 0.55f);
                return;
            }
            // CORTE ROXO: onda de magia rente ao chão
            if (Dificuldade.nivel >= 1 && recargaOnda <= 0 && adx >= 150 && adx <= 520 && Mathf.Abs(dy) < 40 && CameraVallack.NaTela(x, 0))
            {
                estado = "onda"; ondaSolta = false; velh = 0;
                an.Tocar(aRoxo, true, 0.7f);
                return;
            }
        }
        if (adx > ALCANCE - 12 && PodeAndar(dir, 24)) { VelhPara(dir * velP, 0.3f, 0.5f, dt); an.Tocar(aCorrer, false, furioso ? 1.25f : 1f); }
        else { VelhPara(0, 0.3f, 0.5f, dt); an.Tocar(Mathf.Abs(velh) > 0.6f ? aCorrer : aParado, false); }
    }

    // invoca esqueletos por portais de magia em volta dele
    void Invocar(Jogador p)
    {
        int n = Dificuldade.nivel >= 3 ? 3 : 2;
        for (int i = 0; i < n; i++)
        {
            float lado = i % 2 == 0 ? -dir : dir;
            float sx = Mathf.Clamp(x + lado * (90 + 50 * Mathf.Floor(i / 2f) + Random.value * 30), 60, Mundo.SALA_W - 60);
            if (p != null && Mathf.Abs(sx - p.x) < 60) sx += sx < p.x ? -70 : 70;
            if (InimigosFase1.eu != null) InimigosFase1.eu.InvocarEsqueleto(sx, y, 10 + i * 14);
        }
    }

    // aura vermelha enquanto está furioso
    protected override void MostrarExtra()
    {
        if (furioso && !morrendo) sr.color = Color.Lerp(sr.color, new Color(1f, 0.55f, 0.5f), 0.4f + 0.2f * Mathf.Sin(Time.time * 10f));
    }
}
