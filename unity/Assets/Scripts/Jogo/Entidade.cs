// =====================================================================
//  Entidade — física e colisão com o chão do obj_entidade (herói e
//  inimigos). Pixels do mundo, y para baixo, (x, y) no PÉ. Move pixel a
//  pixel até encostar; sobe degraus de até 9 px andando; pousa nas
//  plataformas de mão única ao cair.
// =====================================================================
using UnityEngine;

public abstract class Entidade : MonoBehaviour
{
    [Header("Posição (px do mundo, y para baixo, no pé)")]
    public float x, y;
    [System.NonSerialized] public float velh, velv, empurrao;

    protected float mw = 11f, mh = 66f;      // meia largura e altura da máscara
    protected float escalaY = 1f;            // máscara encolhida (agachado)
    protected float atravessarT;             // descendo por uma plataforma de mão única
    protected float andaV;
    bool andaVivo, andaVivoAnt;

    // caixa que leva golpes
    public float Esq => x - mw;
    public float Dir => x + mw;
    public float Topo => y - mh * escalaY;
    public float MeioY => y - mh * escalaY * 0.5f;

    protected bool Bate(float px, float py) => Mundo.Colide(px - mw, py - mh * escalaY, px + mw, py);
    protected int PlataformaSob() => atravessarT > 0 ? -1 : Mundo.PlataformaSob(x - mw, x + mw, y);
    public bool Pisando() => Bate(x, y + 1) || PlataformaSob() >= 0;

    public bool Toca(float x1, float y1, float x2, float y2) => x1 < Dir && x2 > Esq && y1 < y && y2 > Topo;

    // v1.14: o ANDAR obedece a velocidade: acelera com acel, freia com frear
    // (por quadro de 60 FPS) e, para virar, passa pelo zero
    protected void VelhPara(float alvo, float acel, float frear, float dt)
    {
        float v = andaVivoAnt ? andaV : Mathf.Clamp(velh, -Mathf.Abs(alvo), Mathf.Abs(alvo));
        float a = ((v != 0 && Mathf.Sign(alvo) != Mathf.Sign(v)) || Mathf.Abs(alvo) < Mathf.Abs(v)) ? frear : acel;
        a *= dt;
        v = v < alvo ? Mathf.Min(v + a, alvo) : Mathf.Max(v - a, alvo);
        andaV = v; andaVivo = true; velh = v;
    }

    // ===== COLISÃO COM O CHÃO — End Step =====
    protected void Fisica(float dt)
    {
        // 0) rede de segurança: dentro do chão, sai pelo caminho mais curto
        if (Bate(x, y))
        {
            bool livre = false;
            for (int i = 1; i < 17 && !livre; i++) if (!Bate(x, y - i)) { y -= i; livre = true; }
            for (int i = 1; i < 25 && !livre; i++)
            {
                if (!Bate(x - i, y)) { x -= i; livre = true; }
                else if (!Bate(x + i, y)) { x += i; livre = true; }
            }
            int saida = 0;
            while (!livre && Bate(x, y) && saida++ < 200) y -= 1;
        }
        velv = Mathf.Min(velv, 12f);
        bool noChao = velv >= 0 && (Bate(x, y + 1) || PlataformaSob() >= 0);

        // 1) horizontal (degrau baixo é subido andando)
        float mh_ = velh * dt;
        if (Bate(x + mh_, y))
        {
            int sobe = 0;
            if (noChao && mh_ != 0)
                for (int d = 1; d <= Mundo.DEGRAU_MAX; d++) if (!Bate(x + mh_, y - d)) { sobe = d; break; }
            if (sobe > 0) { y -= sobe; x += mh_; }
            else
            {
                float ph = Mathf.Sign(mh_); int seg = 0;
                while (mh_ != 0 && !Bate(x + ph, y) && seg++ < 64) x += ph;
                velh = 0; andaV = 0;
            }
        }
        else x += mh_;

        // 2) vertical (pousa nas plataformas de mão única ao cair)
        float mv = velv * dt;
        int pl = atravessarT > 0 ? -1 : Mundo.PlataformaPouso(x - mw, x + mw, y, mv);
        if (pl >= 0 && !Bate(x, Mundo.plataformas[pl].y)) { y = Mundo.plataformas[pl].y; velv = 0; }
        else if (Bate(x, y + mv))
        {
            float pv = Mathf.Sign(mv); int seg = 0;
            while (mv != 0 && !Bate(x, y + pv) && seg++ < 64) y += pv;
            velv = 0;
        }
        else y += mv;

        // 3) descendo a escadaria: cola nos degraus em vez de "cair" a cada um
        if (noChao && velv >= 0 && !Bate(x, y + 1) && PlataformaSob() < 0)
            for (int d = 2; d < Mundo.DEGRAU_MAX + 2; d++)
                if (Bate(x, y + d)) { y += d - 1; velv = 0; break; }
        andaVivoAnt = andaVivo; andaVivo = false;
    }

    protected static float LerpDt(float a, float b, float f, float dt) => a + (b - a) * (1f - Mathf.Pow(1f - f, dt));
}
