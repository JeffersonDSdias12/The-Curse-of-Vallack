// =====================================================================
//  CriarCenaTeste — monta a cena "Teste" (primeiro teste no celular):
//  Twilight, a Besta e a Árvore animados, chão, luz global noturna e duas
//  luzes de fogo tremulando (URP 2D), e o medidor de FPS.
//  Menu: Vallack > Criar cena de teste  ·  batch: -executeMethod CriarCenaTeste.Criar
// =====================================================================
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public static class CriarCenaTeste
{
    const string CENA = "Assets/Scenes/Teste.unity";

    [MenuItem("Vallack/Criar cena de teste")]
    public static void Criar()
    {
        var cena = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        // câmera: mostra 280 px do mundo na altura (como o jogo original)
        var cam = new GameObject("Camera").AddComponent<Camera>();
        cam.orthographic = true;
        cam.orthographicSize = 140f;
        cam.transform.position = new Vector3(60f, 110f, -10f);
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = new Color(0.07f, 0.05f, 0.1f);
        cam.gameObject.tag = "MainCamera";
        cam.gameObject.AddComponent<MedidorFps>();

        // noite: a luz global fica baixa e arroxeada; o fogo é quem ilumina
        var global = new GameObject("Luz global").AddComponent<Light2D>();
        global.lightType = Light2D.LightType.Global;
        global.color = new Color(0.55f, 0.5f, 0.75f);
        global.intensity = 0.35f;

        Fogo("Fogo (laranja)", new Vector3(-40f, 30f, 0f), new Color(1f, 0.55f, 0.2f), 1.6f, 150f);
        Fogo("Fogo maldito (roxo)", new Vector3(200f, 60f, 0f), new Color(0.65f, 0.3f, 1f), 1.8f, 170f);

        // chão
        var chao = Sprite("Chao", "spr_chao", new Vector3(-250f, 0f, 0f));
        if (chao != null)
        {
            var sr = chao.GetComponent<SpriteRenderer>();
            sr.drawMode = SpriteDrawMode.Tiled;
            sr.size = new Vector2(700f, 35f);
            chao.transform.position = new Vector3(-250f, 0f, 0f);
        }

        Personagem("Twilight", "spr_player_parado", new Vector3(0f, 0f, 0f));
        Personagem("Besta", "spr_inimigo01_parado", new Vector3(110f, 0f, 0f));
        Personagem("Arvore", "spr_boss_01_parado", new Vector3(260f, 0f, 0f));

        EditorSceneManager.SaveScene(cena, CENA);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(CENA, true) };
        AssetDatabase.SaveAssets();
        Debug.Log("[cena] Teste criada");
    }

    static void Fogo(string nome, Vector3 pos, Color cor, float intensidade, float raio)
    {
        var l = new GameObject(nome).AddComponent<Light2D>();
        l.lightType = Light2D.LightType.Point;
        l.color = cor;
        l.intensity = intensidade;
        l.pointLightOuterRadius = raio;
        l.pointLightInnerRadius = raio * 0.15f;
        l.transform.position = pos;
        l.gameObject.AddComponent<TremularLuz>();
    }

    static GameObject Sprite(string nome, string anim, Vector3 pos)
    {
        var a = AssetDatabase.LoadAssetAtPath<SpriteAnim>($"Assets/Art/Anims/{anim}.asset");
        if (a == null || a.Total == 0) { Debug.LogWarning("[cena] sem anim " + anim); return null; }
        var go = new GameObject(nome);
        go.transform.position = pos;
        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = a.quadros[0];
        return go;
    }

    static void Personagem(string nome, string anim, Vector3 pos)
    {
        var go = Sprite(nome, anim, pos);
        if (go == null) return;
        var an = go.AddComponent<SpriteAnimador>();
        an.anim = AssetDatabase.LoadAssetAtPath<SpriteAnim>($"Assets/Art/Anims/{anim}.asset");
        go.GetComponent<SpriteRenderer>().sortingOrder = 10;
    }
}
