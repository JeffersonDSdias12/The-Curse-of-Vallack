// =====================================================================
//  Texturas — pequenas texturas geradas por código (tábuas de madeira,
//  branco para retângulos, brilho redondo para luzes e partículas).
//  Filtro Point para casar com a pixel art; o brilho usa Bilinear.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public static class Texturas
{
    static readonly Dictionary<string, Sprite> cache = new Dictionary<string, Sprite>();

    public static Sprite Branco() => Pegar("branco", () =>
    {
        var t = Nova(4, 4, FilterMode.Point);
        var px = new Color32[16];
        for (int i = 0; i < 16; i++) px[i] = new Color32(255, 255, 255, 255);
        t.SetPixels32(px); t.Apply(false, true);
        return Sprite.Create(t, new Rect(0, 0, 4, 4), Vector2.zero, 4f, 0, SpriteMeshType.FullRect);  // 1 x 1 unidade
    });

    // tábuas: 32 x 16, duas tábuas com veios, pregos e a borda de cima clara
    public static Sprite Madeira() => Pegar("madeira", () =>
    {
        const int W = 32, H = 16;
        var t = Nova(W, H, FilterMode.Point);
        t.wrapMode = TextureWrapMode.Repeat;
        var px = new Color32[W * H];
        var r = new System.Random(7);
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
            {
                int tabua = y / 8;                       // 0 = de baixo
                int yy = y % 8;
                int junta = (tabua == 0 ? 11 : 27);
                float v = 0.82f + 0.12f * Mathf.Sin(x * 0.7f + tabua * 3f + yy * 0.4f) + (float)r.NextDouble() * 0.08f;
                Color c = new Color(0.36f, 0.24f, 0.15f) * v;
                if (yy == 7) c = new Color(0.55f, 0.38f, 0.24f);           // borda de cima iluminada
                if (yy == 0) c = new Color(0.14f, 0.09f, 0.06f);           // fresta entre as tábuas
                if (x == junta) c = new Color(0.12f, 0.08f, 0.05f);        // emenda
                if ((x == junta + 2 || x == junta - 2) && yy == 4) c = new Color(0.62f, 0.6f, 0.58f);  // prego
                c.a = 1;
                px[y * W + x] = c;
            }
        t.SetPixels32(px); t.Apply(false, true);
        return Sprite.Create(t, new Rect(0, 0, W, H), Vector2.zero, 1f, 0, SpriteMeshType.FullRect);
    });

    // brilho redondo suave (luz, fogo, fumaça, chuva)
    public static Sprite Brilho() => Pegar("brilho", () =>
    {
        const int N = 64;
        var t = Nova(N, N, FilterMode.Bilinear);
        var px = new Color32[N * N];
        for (int y = 0; y < N; y++)
            for (int x = 0; x < N; x++)
            {
                float dx = (x + 0.5f) / N * 2 - 1, dy = (y + 0.5f) / N * 2 - 1;
                float d = Mathf.Clamp01(1 - Mathf.Sqrt(dx * dx + dy * dy));
                byte a = (byte)(255 * d * d * (3 - 2 * d));
                px[y * N + x] = new Color32(255, 255, 255, a);
            }
        t.SetPixels32(px); t.Apply(false, true);
        return Sprite.Create(t, new Rect(0, 0, N, N), new Vector2(0.5f, 0.5f), N, 0, SpriteMeshType.FullRect); // 1 unidade
    });

    // disco de borda dura (a lua), 32 px = 1 unidade, pivô no centro
    public static Sprite Disco() => Pegar("disco", () =>
    {
        const int N = 32;
        var t = Nova(N, N, FilterMode.Bilinear);
        var px = new Color32[N * N];
        for (int y = 0; y < N; y++)
            for (int x = 0; x < N; x++)
            {
                float dx = x + 0.5f - N / 2f, dy = y + 0.5f - N / 2f;
                float a = Mathf.Clamp01(N / 2f - Mathf.Sqrt(dx * dx + dy * dy));
                px[y * N + x] = new Color32(255, 255, 255, (byte)(255 * a));
            }
        t.SetPixels32(px); t.Apply(false, true);
        return Sprite.Create(t, new Rect(0, 0, N, N), new Vector2(0.5f, 0.5f), N, 0, SpriteMeshType.FullRect);
    });

    // céu em degradê vertical (cores do jogo original: noite roxa até o horizonte em brasa)
    public static Sprite Ceu(Color c1, Color c2, Color c3) => Pegar("ceu", () =>
    {
        const int H = 128;
        var t = Nova(1, H, FilterMode.Bilinear);
        t.wrapMode = TextureWrapMode.Clamp;
        for (int y = 0; y < H; y++)
        {
            float k = 1f - (y + 0.5f) / H;              // 0 = alto, 1 = horizonte
            Color c = k < 0.42f ? Color.Lerp(c1, c2, k / 0.42f) : Color.Lerp(c2, c3, (k - 0.42f) / 0.58f);
            t.SetPixel(0, y, c);
        }
        t.Apply(false, true);
        return Sprite.Create(t, new Rect(0, 0, 1, H), new Vector2(0.5f, 0.5f), 1, 0, SpriteMeshType.FullRect);
    });

    static Texture2D Nova(int w, int h, FilterMode f) =>
        new Texture2D(w, h, TextureFormat.RGBA32, false) { filterMode = f, wrapMode = TextureWrapMode.Clamp };

    static Sprite Pegar(string k, System.Func<Sprite> criar)
    {
        if (!cache.TryGetValue(k, out var s) || s == null) { s = criar(); s.name = k; cache[k] = s; }
        return s;
    }
}
