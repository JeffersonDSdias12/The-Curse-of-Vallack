// =====================================================================
//  Mundo — o chão do jogo original, sem física do Unity.
//  O jogo antigo media tudo em pixels com y para BAIXO (GameMaker); a lógica
//  continua nesse sistema (x, y do pé) e só a posição na tela vira Unity
//  (1 unidade = 1 px, y para cima): Mundo.Tela(x, y) = (x, -y).
//  · sólidos: caixas [x1,x2) × [y1,y2) (obj_chao)
//  · plataformas de mão única: só seguram quem cai de cima (obj_plataforma)
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public static class Mundo
{
    public const float SALA_W = 5000f, SALA_H = 733f;
    public const int DEGRAU_MAX = 9;           // degraus até esta altura são subidos andando

    public struct Caixa { public float x1, y1, x2, y2; }
    public struct Plataforma { public float x1, x2, y; }

    public static readonly List<Caixa> solidos = new List<Caixa>();
    public static readonly List<Plataforma> plataformas = new List<Plataforma>();

    public static Vector3 Tela(float x, float y, float z = 0f) => new Vector3(x, -y, z);

    public static void Limpar() { solidos.Clear(); plataformas.Clear(); }

    public static void Solido(float x1, float y1, float x2, float y2) =>
        solidos.Add(new Caixa { x1 = Mathf.Min(x1, x2), y1 = Mathf.Min(y1, y2), x2 = Mathf.Max(x1, x2), y2 = Mathf.Max(y1, y2) });

    public static void MaoUnica(float x1, float x2, float y) =>
        plataformas.Add(new Plataforma { x1 = x1, x2 = x2, y = y });

    // place_meeting: a caixa [x1,x2) × [y1,y2) encosta em algum sólido?
    public static bool Colide(float x1, float y1, float x2, float y2)
    {
        for (int i = 0; i < solidos.Count; i++)
        {
            var c = solidos[i];
            if (x1 < c.x2 && x2 > c.x1 && y1 < c.y2 && y2 > c.y1) return true;
        }
        return false;
    }

    // plataforma de mão única exatamente sob os pés (x1..x2 = largura da máscara)
    public static int PlataformaSob(float x1, float x2, float pe)
    {
        for (int i = 0; i < plataformas.Count; i++)
        {
            var p = plataformas[i];
            if (x2 > p.x1 && x1 < p.x2 && Mathf.Abs(pe - p.y) < 0.5f) return i;
        }
        return -1;
    }

    // caindo mv px: cruza o topo de alguma plataforma neste quadro?
    public static int PlataformaPouso(float x1, float x2, float pe, float mv)
    {
        if (mv <= 0) return -1;
        int melhor = -1;
        for (int i = 0; i < plataformas.Count; i++)
        {
            var p = plataformas[i];
            if (x2 > p.x1 && x1 < p.x2 && pe <= p.y + 0.01f && pe + mv >= p.y)
                if (melhor < 0 || p.y < plataformas[melhor].y) melhor = i;
        }
        return melhor;
    }
}
