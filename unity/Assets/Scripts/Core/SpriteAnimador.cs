// =====================================================================
//  SpriteAnimador — toca uma SpriteAnim num SpriteRenderer, como o
//  image_index / image_speed do jogo original. A lógica do jogo pode trocar
//  a animação (Tocar), mexer no quadro (Indice) ou na velocidade (Velocidade,
//  1 = a velocidade original do sprite) e saber quando ela terminou (Terminou,
//  o "Animation End" do GameMaker).
// =====================================================================
using UnityEngine;

[RequireComponent(typeof(SpriteRenderer))]
public class SpriteAnimador : MonoBehaviour
{
    public SpriteAnim anim;
    [Tooltip("1 = velocidade original do sprite; 0 = parado")]
    public float Velocidade = 1f;
    public float Indice;
    public bool Terminou { get; private set; }

    SpriteRenderer sr;

    void Awake() { sr = GetComponent<SpriteRenderer>(); }

    public void Tocar(SpriteAnim nova, bool reiniciar = true, float velocidade = 1f)
    {
        if (nova == anim && !reiniciar) { Velocidade = velocidade; return; }
        anim = nova;
        Velocidade = velocidade;
        if (reiniciar) Indice = 0;
        Terminou = false;
        Mostrar();
    }

    // mostra um quadro fixo (image_speed = 0, image_index = indice): golpes, corrida pela distância
    public void Quadro(SpriteAnim a, float indice)
    {
        anim = a;
        Velocidade = 0f;
        Indice = indice;
        Terminou = false;
        Mostrar();
    }

    void LateUpdate()
    {
        if (anim == null || anim.Total == 0) return;
        Terminou = false;
        float antes = Indice;
        Indice += anim.Fps * Velocidade * Time.deltaTime;
        if (Indice >= anim.Total)
        {
            Indice %= anim.Total;
            Terminou = true;          // passou do último quadro nesta atualização
        }
        if (Mathf.FloorToInt(antes) != Mathf.FloorToInt(Indice) || sr.sprite == null) Mostrar();
    }

    void Mostrar() { if (anim != null && anim.Total > 0) sr.sprite = anim.Quadro(Indice); }
}
