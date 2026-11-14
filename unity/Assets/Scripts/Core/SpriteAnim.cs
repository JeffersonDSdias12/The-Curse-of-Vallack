// =====================================================================
//  SpriteAnim — uma animação de sprite do jogo original (quadros + velocidade).
//  Criada pelo importador (Vallack > Importar sprites) a partir de
//  godot/assets/data/sprites.json. 1 unidade do Unity = 1 pixel do mundo
//  original (os sprites HD têm PPU = k), então velocidades e alcances do
//  jogo original continuam valendo.
// =====================================================================
using UnityEngine;

[CreateAssetMenu(menuName = "Vallack/Sprite Anim")]
public class SpriteAnim : ScriptableObject
{
    public Sprite[] quadros;
    [Tooltip("Velocidade original (quadros por segundo se porSegundo, senão quadros por passo de jogo)")]
    public float velocidade = 0f;
    public bool porSegundo = true;
    [Tooltip("Fator HD do sprite original (PPU)")]
    public float k = 1f;

    public int Total => quadros == null ? 0 : quadros.Length;

    // quadros por segundo reais (o jogo original andava a 60 passos por segundo)
    public float Fps => porSegundo ? velocidade : velocidade * 60f;

    public Sprite Quadro(float indice)
    {
        if (Total == 0) return null;
        int i = Mathf.FloorToInt(indice) % Total;
        if (i < 0) i += Total;
        return quadros[i];
    }
}
