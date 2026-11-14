// =====================================================================
//  Faixa — camada distante que se repete e anda mais devagar que a câmera
//  (cenario_faixa do jogo original). fx: 0 = presa à câmera, 1 = presa ao
//  mundo; deriva soma um deslocamento contínuo (as nuvens).
//  Cada repetição é um SpriteRenderer; brilhos extras (incêndios ao longe)
//  são copiados em todas as repetições.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

[DefaultExecutionOrder(100)]          // depois da câmera
public class Faixa : MonoBehaviour
{
    public float fx = 0.5f;
    public float yBase;                // base da faixa no mundo (y para baixo)
    public float deriva;               // px por segundo
    public bool yCamera;               // yBase conta a partir do alto da câmera (as nuvens)
    float w;
    readonly List<Transform> blocos = new List<Transform>();
    readonly List<(SpriteRenderer sr, float a, float sem)> brilhos = new List<(SpriteRenderer, float, float)>();
    Camera cam;
    float desloc;

    public void Montar(Sprite s, int ordem, Material mat, Color cor, float viewW)
    {
        w = s.rect.width;
        int n = Mathf.CeilToInt(viewW * 1.6f / w) + 2;
        for (int k = 0; k < n; k++)
        {
            var go = new GameObject("rep " + k);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(k * w, 0, 0);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = s; sr.sortingOrder = ordem; sr.color = cor;
            if (mat != null) sr.sharedMaterial = mat;
            blocos.Add(go.transform);
        }
    }

    // brilho (elipse aditiva) em coordenadas da peça: lx a partir da esquerda, ly a partir do topo
    public void Brilho(Sprite brilho, Material aditivo, float lx, float ly, float bw, float bh, Color cor, int ordem)
    {
        float h = blocos.Count > 0 ? blocos[0].GetComponent<SpriteRenderer>().sprite.rect.height : 0;
        foreach (var b in blocos)
        {
            var go = new GameObject("brilho");
            go.transform.SetParent(b, false);
            go.transform.localPosition = new Vector3(lx, h - ly, 0);
            go.transform.localScale = new Vector3(bw, bh, 1);
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = brilho; sr.sharedMaterial = aditivo; sr.sortingOrder = ordem; sr.color = cor;
            brilhos.Add((sr, cor.a, Random.value * 50f));
        }
    }

    void LateUpdate()
    {
        if (cam == null) cam = Camera.main;
        if (cam == null || w <= 0) return;
        desloc += deriva * Time.deltaTime;
        float viewW = cam.orthographicSize * 2f * cam.aspect;
        float vx = cam.transform.position.x - viewW / 2f;
        float ox = vx * (1f - fx) - desloc;
        float x = ox + Mathf.Floor((vx - ox) / w) * w;
        float yb = yBase;
        if (yCamera) yb += -cam.transform.position.y - cam.orthographicSize;
        transform.position = new Vector3(Mathf.Round(x), -yb, 0);
        if (brilhos.Count > 0)
        {
            float t = Time.time * 60f;
            for (int i = 0; i < brilhos.Count; i++)
            {
                var b = brilhos[i];
                float fl = 0.7f + 0.3f * Mathf.Sin(t * 0.09f + b.sem) * Mathf.Sin(t * 0.031f + b.sem * 2f);
                var c = b.sr.color; c.a = b.a * fl; b.sr.color = c;
            }
        }
    }
}
