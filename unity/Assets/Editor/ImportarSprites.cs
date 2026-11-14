// =====================================================================
//  ImportarSprites — traz os sprites do jogo para o Unity.
//  Fonte: ../godot/assets/sprites/<nome>/<n>.png (já tratados: contorno,
//  limpeza) e ../godot/assets/data/sprites.json (origem, caixa, velocidade,
//  fator HD k e a borda extra "pad" de cada sprite).
//  Destino: Assets/Art/Sprites/<nome>/ + Assets/Art/Anims/<nome>.asset.
//  Regras: 1 unidade = 1 pixel do mundo original (PPU = k), pivô na origem
//  original, filtro Point, sem compressão nem mipmaps (pixel art nítida).
//  Menu: Vallack > Importar sprites  ·  batch: -executeMethod ImportarSprites.Importar
// =====================================================================
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

public static class ImportarSprites
{
    const string DESTINO = "Assets/Art/Sprites";
    const string ANIMS = "Assets/Art/Anims";

    [System.Serializable] class Info { public float w, h, xo, yo, spd, spdt, n, k = 1, pad; }

    static string Raiz => Path.GetFullPath(Path.Combine(Application.dataPath, "../.."));

    [MenuItem("Vallack/Importar sprites")]
    public static void Importar()
    {
        var json = File.ReadAllText(Path.Combine(Raiz, "godot/assets/data/sprites.json"));
        var dados = LerJson(json);
        var origem = Path.Combine(Raiz, "godot/assets/sprites");
        Directory.CreateDirectory(DESTINO);
        Directory.CreateDirectory(ANIMS);
        // 1) copia os PNGs
        int copiados = 0;
        foreach (var kv in dados)
        {
            var dir = Path.Combine(origem, kv.Key);
            if (!Directory.Exists(dir)) continue;
            var dst = Path.Combine(DESTINO, kv.Key);
            Directory.CreateDirectory(dst);
            for (int i = 0; i < (int)kv.Value.n; i++)
            {
                var src = Path.Combine(dir, i + ".png");
                if (!File.Exists(src)) continue;
                File.Copy(src, Path.Combine(dst, i.ToString("00") + ".png"), true);
                copiados++;
            }
        }
        AssetDatabase.Refresh();
        // 2) ajusta a importação de cada quadro e monta a animação
        AssetDatabase.StartAssetEditing();
        try
        {
            foreach (var kv in dados)
            {
                var info = kv.Value;
                float k = info.k <= 0 ? 1 : info.k;
                for (int i = 0; i < (int)info.n; i++)
                {
                    var caminho = $"{DESTINO}/{kv.Key}/{i:00}.png";
                    var imp = AssetImporter.GetAtPath(caminho) as TextureImporter;
                    if (imp == null) continue;
                    imp.textureType = TextureImporterType.Sprite;
                    imp.spriteImportMode = SpriteImportMode.Single;
                    imp.filterMode = FilterMode.Point;
                    imp.mipmapEnabled = false;
                    imp.textureCompression = TextureImporterCompression.Uncompressed;
                    imp.alphaIsTransparency = true;
                    imp.spritePixelsPerUnit = k;
                    // tamanho real do PNG = (w + 2·pad) x (h + 2·pad) pixels
                    float W = info.w + 2 * info.pad, H = info.h + 2 * info.pad;
                    var ts = new TextureImporterSettings();
                    imp.ReadTextureSettings(ts);
                    ts.spriteAlignment = (int)SpriteAlignment.Custom;
                    ts.spritePivot = new Vector2((info.xo + info.pad) / W, 1f - (info.yo + info.pad) / H);
                    ts.spriteMeshType = SpriteMeshType.FullRect;
                    ts.spriteExtrude = 1;
                    imp.SetTextureSettings(ts);
                    imp.SaveAndReimport();
                }
            }
        }
        finally { AssetDatabase.StopAssetEditing(); }
        // 3) uma SpriteAnim por sprite
        int anims = 0;
        foreach (var kv in dados)
        {
            var info = kv.Value;
            var quadros = new List<Sprite>();
            for (int i = 0; i < (int)info.n; i++)
            {
                var s = AssetDatabase.LoadAssetAtPath<Sprite>($"{DESTINO}/{kv.Key}/{i:00}.png");
                if (s != null) quadros.Add(s);
            }
            if (quadros.Count == 0) continue;
            var caminho = $"{ANIMS}/{kv.Key}.asset";
            var a = AssetDatabase.LoadAssetAtPath<SpriteAnim>(caminho);
            if (a == null) { a = ScriptableObject.CreateInstance<SpriteAnim>(); AssetDatabase.CreateAsset(a, caminho); }
            a.quadros = quadros.ToArray();
            a.velocidade = info.spd;
            a.porSegundo = info.spdt == 0;      // GameMaker: 0 = quadros por segundo, 1 = por passo
            a.k = info.k <= 0 ? 1 : info.k;
            EditorUtility.SetDirty(a);
            anims++;
        }
        AssetDatabase.SaveAssets();
        Debug.Log($"[importar] sprites={dados.Count} quadros={copiados} anims={anims}");
    }

    // sprites.json é um objeto { "spr_x": { ... }, ... }: o JsonUtility não lê
    // dicionários, então separa cada entrada à mão e lê o objeto interno
    static Dictionary<string, Info> LerJson(string json)
    {
        var r = new Dictionary<string, Info>();
        int i = json.IndexOf('{') + 1;
        while (true)
        {
            int a = json.IndexOf('"', i);
            if (a < 0) break;
            int b = json.IndexOf('"', a + 1);
            string nome = json.Substring(a + 1, b - a - 1);
            int ini = json.IndexOf('{', b);
            int fim = json.IndexOf('}', ini);
            r[nome] = JsonUtility.FromJson<Info>(json.Substring(ini, fim - ini + 1));
            i = fim + 1;
        }
        return r;
    }
}
