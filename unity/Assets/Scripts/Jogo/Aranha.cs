// =====================================================================
//  Aranha — MULHER-ARANHA (obj_aranha)
//  · ágil: mantém distância, avança e recua de frente para Twilight
//  · GARRA de perto e BOTE (salta com as garras) de média distância
//  · TEIA: cospe teia em arco que PRENDE Twilight; no chão vira armadilha.
//    A defesa segura; aparada, ela volta e prende a própria aranha.
//  Estatua — ESTÁTUA ENFEITIÇADA (obj_estatua): torre parada. Em PEDRA os
//  golpes comuns só tiram faíscas; quando os OLHOS ACENDEM ela dispara um
//  ORBE que persegue e só então (e logo depois) pode ser ferida. O orbe
//  aparado volta, RACHA a estátua e a deixa vulnerável por alguns segundos.
// =====================================================================
using UnityEngine;

public class Aranha : Inimigo
{
    const float ESCALA = 1.45f, VEL_ANDAR = 2.5f, IDEAL_MIN = 120f, IDEAL_MAX = 230f;
    float recargaTeia, recargaBote, ataqueT, boteNoAr;
    bool viu, teiaSolta;

    protected override void Configurar()
    {
        mw = 21f; mh = 64f;                 // spr_mascara_aranha (42 x 64)
        escalaVis = ESCALA; topoVis = 78f;
        vidaBase = 50f; danoBase = 8f;
        campo = 520f; campoAltura = 150f; orbs = 14;
        morteAnimDur = 36f;
        aMorrer = aParado;
    }

    protected override void Awake() { base.Awake(); dir = -1f; }

    protected override void Reagir(float d, float forca)
    {
        empurrao = d * forca * 0.3f;
        Atordoar(24);
        if (vida <= 0) { Morrer(d); Efeitos.Som(Efeitos.Sons?.aranhaChiado, 0.9f); }
    }

    protected override void AposAtordoado(bool dentroCampo, float adx) { estado = dentroCampo ? "perseguir" : "parado"; recarga = Mathf.Min(recarga, 14); }

    bool PodeAndar(float d, float passo = 32f)
    {
        float nx = x + d * passo;
        return nx >= 48f && nx <= Mundo.SALA_W - 48f && !Bate(nx, y - 4);
    }

    protected override void Agir(Jogador p, float dx, float dy, float adx, bool dentro, bool noChao, bool temAlvo, float dt)
    {
        if (recargaTeia > 0) recargaTeia -= dt;
        if (recargaBote > 0) recargaBote -= dt;
        if (!viu && recargaTeia <= 0 && recargaBote <= 0) { recarga = Random.Range(30, 70); recargaTeia = Random.Range(50, 110); recargaBote = Random.Range(80, 150); }
        if (dentro && !viu && CameraVallack.NaTela(x, 0)) { viu = true; alertaFx = 40; }
        switch (estado)
        {
            case "parado":
                velh = 0; an.Tocar(aParado, false);
                if (dentro && viu) estado = "perseguir";
                break;
            case "perseguir":
                Perseguir(dentro, dx, dy, adx, noChao, dt);
                break;
            case "garra":
                velh = 0;
                {
                    float antes = ataqueT; ataqueT += dt;
                    an.Quadro(aAtaque, ataqueT < 16 ? 0 : Mathf.Min(3, 1 + Mathf.Floor((ataqueT - 16) / 8f)));
                    if (!golpeDado && ataqueT >= 16 && ataqueT < 26)
                    {
                        if (antes < 16) Efeitos.Som(Efeitos.Sons?.inimigoGolpe, 0.5f);
                        float x1 = x + dir * 4, x2 = x + dir * 50;
                        if (temAlvo && p.Toca(Mathf.Min(x1, x2), y - 50, Mathf.Max(x1, x2), y - 4)) { golpeDado = true; p.LevarDano(danoBase, x, true, 4f, this); }
                    }
                    if (ataqueT >= 40) { estado = "perseguir"; recarga = 44 + Random.Range(0, 20); an.Tocar(aParado, true); }
                }
                break;
            case "teia":
                velh = 0; ataqueT += dt;
                if (temAlvo && !teiaSolta && dx != 0) dir = Mathf.Sign(dx);
                an.Quadro(aAtaque, ataqueT < 22 ? 0 : Mathf.Min(3, 1 + Mathf.Floor((ataqueT - 22) / 8f)));
                if (!teiaSolta && ataqueT >= 22)
                {
                    teiaSolta = true;
                    float bx = x + dir * 16, by = y - 46, tx = bx + dir * 240, ty = y - 30;
                    if (temAlvo) { tx = p.x; ty = p.y - 30; }
                    const float vh = 5.6f;
                    float tempo = Mathf.Max(8f, Mathf.Abs(tx - bx) / vh);
                    float vv = (ty - by) / tempo - 0.5f * 0.12f * tempo;
                    Magia.Criar("teia", bx, by, dir * vh, Mathf.Clamp(vv, -7f, 4f), 3f, this, aditivo, alfa, null, 80f);
                    Efeitos.Som(Efeitos.Sons?.teiaDisparo, 0.75f);
                }
                if (ataqueT >= 46) { estado = "perseguir"; recargaTeia = 250 + Random.Range(0, 60); recarga = Mathf.Max(recarga, 30); an.Tocar(aParado, true); }
                break;
            case "bote_prep":
                velh = 0; ataqueT += dt;
                if (temAlvo) Virar(dx, true, dt);
                if (ataqueT >= 18)
                {
                    const float forca = 5.4f;
                    float tar = 2f * forca / grav;
                    velh = dir * Mathf.Clamp((adx - 30f) / tar, 2.5f, 7f);
                    velv = -forca;
                    estado = "bote"; boteNoAr = 0;
                    an.Quadro(aAtaque, 1);
                    Efeitos.Som(Efeitos.Sons?.aranhaChiado, 0.55f);
                }
                break;
            case "bote":
                boteNoAr += dt;
                an.Quadro(aAtaque, 1);
                if (!golpeDado && temAlvo)
                {
                    float x1 = x, x2 = x + dir * 46;
                    if (p.Toca(Mathf.Min(x1, x2), y - 48, Mathf.Max(x1, x2), y - 2)) { golpeDado = true; p.LevarDano(10f, x, true, 6f, this); }
                }
                if (noChao && velv >= 0 && boteNoAr > 4) { velh = 0; estado = "bote_fim"; ataqueT = 0; an.Quadro(aAtaque, 2); Efeitos.Poeira(x, y, 0.5f); }
                if (velh != 0 && !PodeAndar(Mathf.Sign(velh), 18)) velh = 0;
                break;
            case "bote_fim":
                velh = 0; ataqueT += dt;
                an.Quadro(aAtaque, ataqueT < 10 ? 2 : 3);
                if (ataqueT >= 22) { estado = "perseguir"; recargaBote = 180 + Random.Range(0, 60); recarga = Mathf.Max(recarga, 24); an.Tocar(aParado, true); }
                break;
        }
    }

    void Perseguir(bool dentro, float dx, float dy, float adx, bool noChao, float dt)
    {
        if (!dentro) { estado = "parado"; velh = 0; return; }
        Virar(dx, false, dt);
        if (noChao && recarga <= 0)
        {
            if (adx <= 62 && Mathf.Abs(dy) < 50) { estado = "garra"; ataqueT = 0; golpeDado = false; velh = 0; an.Quadro(aAtaque, 0); return; }
            if (recargaBote <= 0 && adx >= 90 && adx <= 230 && Mathf.Abs(dy) < 60 && PodeAndar(dir, 64)) { estado = "bote_prep"; ataqueT = 0; golpeDado = false; velh = 0; an.Quadro(aParado, 1); return; }
            if (recargaTeia <= 0 && adx >= 110 && adx <= 430 && Mathf.Abs(dy) < 140 && CameraVallack.NaTela(x, 0)) { estado = "teia"; ataqueT = 0; teiaSolta = false; velh = 0; an.Quadro(aAtaque, 0); return; }
        }
        // mantém a distância ideal, sempre de frente para Twilight
        float mv = 0;
        if (adx > IDEAL_MAX) mv = dir;
        else if (recarga <= 0 && adx > 58) mv = dir;
        else if (adx < IDEAL_MIN) mv = -dir;
        if (mv != 0 && !PodeAndar(mv)) mv = 0;
        if (mv != 0) { VelhPara(mv * VEL_ANDAR * (mv == dir ? 1f : 0.75f), 0.35f, 0.5f, dt); an.Tocar(aAndar, false, mv == dir ? 1.5f : 1.1f); }
        else { VelhPara(0, 0.35f, 0.5f, dt); an.Tocar(Mathf.Abs(velh) > 0.5f ? aAndar : aParado, false); }
    }

    // morte: vira de patas para cima e encolhe as patas
    protected override void MostrarExtra()
    {
        if (!morrendo) return;
        float m = Mathf.Clamp01(morteT / 36f), e = 1f - (1f - m) * (1f - m);
        float ys = ESCALA * (1f - 1.5f * e);
        visual.localScale = new Vector3(dir * ESCALA, ys, 1f);
        visual.localPosition = new Vector3(0, Mathf.Max(0, -ys) * 47f, 0);
    }
}

public class Estatua : Inimigo
{
    public SpriteAnim aOrbe;
    const float ESCALA = 1.25f;
    float animT, vulneravelT, rachadaT, tinidoT;
    bool orbeSolto;

    protected override void Configurar()
    {
        mw = 23f; mh = 80f;                 // spr_mascara_estatua (46 x 80)
        escalaVis = ESCALA; topoVis = 96f;
        vidaBase = 70f; danoBase = 10f;
        campo = 600f;
        resisteAtordoar = true; podeLancar = false; orbs = 18; sangueDrop = 8;
        morteAnimDur = 50f;
        aMorrer = aParado;
        estado = "pedra";
        recargaMax = 170f;
    }

    protected override void Awake() { base.Awake(); dir = -1f; }

    public void Rachar() => rachadaT = 180f;
    bool Vulneravel => estado == "desperta" || vulneravelT > 0 || rachadaT > 0;

    // PEDRA: golpes comuns não ferem (só faíscas e um tinido)
    protected override bool BloquearGolpe(Golpe g, float origemX, bool forte)
    {
        if (Vulneravel || forte) return false;
        tinidoT = 10; tempoInvencivel = 6;
        Efeitos.Som(Efeitos.Sons?.pedraTinido, 0.8f);
        float lado = origemX == x ? -dir : Mathf.Sign(origemX - x);
        Efeitos.Faiscas(x + lado * 20, y - 50, 0.8f, 6);
        if (g != null && Jogador.eu != null) Jogador.eu.empurrao = -Jogador.eu.facing * 1.6f;
        return true;
    }

    protected override void Reagir(float d, float forca)
    {
        if (vida > 0) return;
        Morrer(d);
        velh = 0;
        Efeitos.Som(Efeitos.Sons?.pedraDesmorona, 1f);
        Efeitos.Poeira(x, y, 1.6f); Efeitos.Poeira(x, y - 40, 1.4f);
    }

    protected override void AposAtordoado(bool dentroCampo, float adx) { }

    protected override void Agir(Jogador p, float dx, float dy, float adx, bool dentroCampo, bool noChao, bool temAlvo, float dt)
    {
        if (vulneravelT > 0) vulneravelT = Mathf.Max(0, vulneravelT - dt);
        if (rachadaT > 0) rachadaT = Mathf.Max(0, rachadaT - dt);
        if (tinidoT > 0) tinidoT = Mathf.Max(0, tinidoT - dt);
        atordoado = 0;
        if (estado == "perseguir" || estado == "parado") estado = "pedra";
        bool dentro = temAlvo && adx <= campo && Mathf.Abs(dy) <= 220 && CameraVallack.NaTela(x, 24f);
        switch (estado)
        {
            case "pedra":
                an.Quadro(aParado, 0);
                if (temAlvo && dx != 0) dir = Mathf.Sign(dx);
                if (dentro && recarga <= 0)
                {
                    // OS OLHOS ACENDEM: desperta e começa a carregar o orbe
                    estado = "desperta"; animT = 0; orbeSolto = false; alertaFx = 30;
                    Efeitos.Som(Efeitos.Sons?.estatuaCarga, 0.75f);
                }
                break;
            case "desperta":
                animT += dt;
                an.Quadro(aParado, Mathf.Clamp(1 + animT * 0.075f, 1, 5.99f));
                if (!orbeSolto && animT >= 40)
                {
                    orbeSolto = true; vulneravelT = 50;
                    float bx = x + dir * 4, by = y - 64, tx = bx + dir * 200, ty = by;
                    if (temAlvo) { tx = p.x; ty = p.y - 34; }
                    var v = new Vector2(tx - bx, ty - by).normalized * 4.4f;
                    Magia.Criar("orbe", bx, by, v.x, v.y, danoBase, this, aditivo, alfa, aOrbe != null ? aOrbe.Quadro(0) : null);
                    Efeitos.Som(Efeitos.Sons?.estatuaDisparo, 0.85f);
                }
                if (animT >= 66) { estado = "esfriando"; animT = 0; }
                break;
            case "esfriando":
                animT += dt;
                an.Quadro(aParado, 6 + Mathf.Min(1.99f, animT * 0.066f));
                if (animT >= 30) { estado = "pedra"; recarga = recargaMax + Random.Range(0, 50); }
                break;
        }
        velh = 0; empurrao = 0;
    }

    // morte: desmorona; rachada: treme e fica avermelhada
    protected override void MostrarExtra()
    {
        if (morrendo)
        {
            float m = Mathf.Clamp01(morteT / 50f), e = 1f - (1f - m) * (1f - m);
            visual.localScale = new Vector3(dir * ESCALA, ESCALA * Mathf.Lerp(1f, 0.26f, e), 1f);
            visual.localPosition = new Vector3(morteFim ? 0 : Random.Range(-1.5f, 1.5f) * (1 - m), 0, 0);
            return;
        }
        if (tinidoT > 0) visual.localPosition = new Vector3(Random.Range(-1f, 1f), 0, 0);
        if (rachadaT > 0 && ativo) sr.color = Color.Lerp(sr.color, new Color(1f, 0.6f, 0.55f), 0.5f + 0.3f * Mathf.Sin(Time.time * 18f));
    }
}
