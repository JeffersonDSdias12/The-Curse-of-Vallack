// =====================================================================
//  CriarFase1 — monta a cena "Fase1" (A Vila em Chamas) no editor:
//  importa o cenário da equipe (atlas + json), o retrato e os sons do
//  projeto Godot, cria os materiais de partícula, a luz global da noite,
//  o pós-processamento (bloom no fogo, vinheta) e liga Twilight, câmera,
//  chuva, controles e HUD.
//  Menu: Vallack > Criar Fase 1  ·  batch: -executeMethod CriarFase1.Criar
//  (CriarFase1.CriarEConstruir também gera o APK em seguida)
// =====================================================================
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public static class CriarFase1
{
    const string CENA = "Assets/Scenes/Fase1.unity";
    const string URP_MAT = "Packages/com.unity.render-pipelines.universal/Runtime/Materials/";
    static string Godot => Path.GetFullPath(Path.Combine(Application.dataPath, "../../godot/assets/data"));

    static readonly string[] TRILHAS = { "mus_menu", "mus_fase", "mus_boss", "mus_prologo", "mus_carregamento", "bgm_main_menu", "bgm_battle_phase1", "bgm_mini_boss", "bgm_final_boss_phase1", "bgm_loading_screen" };
    static readonly string[] SONS = { "mus_fase", "amb_chuva", "amb_fogo", "atk_corte_1", "atk_corte_2", "atk_pesado", "atk_aereo", "sfx_pulo", "sfx_pouso",
        "hit_1", "hit_2", "hit_3", "hit_pesado", "fogo_explosao", "sfx_bloqueio", "sfx_aparar", "sfx_dano", "sfx_esquiva", "sfx_derrota",
        "sfx_inimigo_golpe", "sfx_portal", "sfx_critico", "sfx_backdash", "maldicao_evaporar",
        "sfx_escudo_quebra", "osso_desmonta", "osso_ergue", "osso_quebra", "osso_chocalho", "sfx_flecha",
        "aranha_chiado", "teia_disparo", "teia_prende", "pedra_tinido", "pedra_desmorona", "estatua_carga", "estatua_disparo",
        "porco_grunhido", "porco_impacto", "magia_onda", "sfx_rugido" };

    public static void CriarEConstruir()
    {
        Criar();
        BuildAndroid.Construir();
    }

    [MenuItem("Vallack/Criar Fase 1")]
    public static void Criar()
    {
        // ---------- arquivos ----------
        Copiar("cenario_fase1.png", "Assets/Art/Cenario");
        Copiar("cenario_fase1.json", "Assets/Art/Cenario");
        Copiar("pecas_fase1.png", "Assets/Art/Cenario");
        Copiar("pecas_fase1.json", "Assets/Art/Cenario");
        Copiar("heroi_retrato.png", "Assets/Art/UI");
        foreach (var arq in Directory.GetFiles(Godot, "*.ogg"))
        {
            // músicas em Resources/Musica (carregadas sob demanda); efeitos em Audio
            string n = Path.GetFileNameWithoutExtension(arq);
            bool trilha = System.Array.IndexOf(TRILHAS, n) >= 0;
            Copiar(Path.GetFileName(arq), trilha ? "Assets/Resources/Musica" : "Assets/Resources/Sons");
        }
        Copiar("logo_vallack.png", "Assets/Art/UI");
        Copiar("intro_aviso.jpg", "Assets/Art/UI");
        Copiar("mapa_fases.jpg", "Assets/Art/UI");
        Copiar("castelo_a.png", "Assets/Art/Cenario");
        Copiar("castelo_b.png", "Assets/Art/Cenario");
        for (int n = 1; n <= 30 && File.Exists(Path.Combine(Godot, $"cutscene_{n}.jpg")); n++) Copiar($"cutscene_{n}.jpg", "Assets/Art/UI");
        File.Copy(Path.Combine(Godot, "../rooms/Room2.json"), "Assets/Art/Cenario/Room2.json", true);
        string mp4 = Path.GetFullPath(Path.Combine(Application.dataPath, "../../datafiles/intro_estudio.mp4"));
        // o vídeo do estúdio vai solto em StreamingAssets (VALLACK_VIDEO=0 deixa de fora)
        bool comVideo = System.Environment.GetEnvironmentVariable("VALLACK_VIDEO") != "0" && File.Exists(mp4);
        AssetDatabase.DeleteAsset("Assets/Video");
        if (comVideo) { Directory.CreateDirectory("Assets/StreamingAssets"); File.Copy(mp4, "Assets/StreamingAssets/intro_estudio.mp4", true); }
        else AssetDatabase.DeleteAsset("Assets/StreamingAssets/intro_estudio.mp4");
        Directory.CreateDirectory("Assets/Art/Cenario");
        File.Copy(Path.Combine(Godot, "../rooms/Room1.json"), "Assets/Art/Cenario/Room1.json", true);
        AssetDatabase.DeleteAsset("Assets/Audio");
        GerarBrilho("Assets/Art/Gerado/brilho.png");
        GerarChama("Assets/Art/Gerado/chama.png");
        AssetDatabase.Refresh();
        {
            var ti = (TextureImporter)AssetImporter.GetAtPath("Assets/Art/Gerado/chama.png");
            ti.textureType = TextureImporterType.Default; ti.mipmapEnabled = false; ti.filterMode = FilterMode.Point;
            ti.wrapMode = TextureWrapMode.Clamp; ti.alphaIsTransparency = true; ti.npotScale = TextureImporterNPOTScale.None;
            ti.textureCompression = TextureImporterCompression.Uncompressed;
            ti.SaveAndReimport();
        }

        Atlas("Assets/Art/Cenario/cenario_fase1.png");
        Atlas("Assets/Art/Cenario/pecas_fase1.png");
        {
            var ti = (TextureImporter)AssetImporter.GetAtPath("Assets/Art/UI/heroi_retrato.png");
            ti.textureType = TextureImporterType.Sprite; ti.mipmapEnabled = false; ti.filterMode = FilterMode.Bilinear;
            ti.textureCompression = TextureImporterCompression.Uncompressed; ti.maxTextureSize = 512;
            ti.SaveAndReimport();
        }
        {
            var ti = (TextureImporter)AssetImporter.GetAtPath("Assets/Art/Gerado/brilho.png");
            ti.textureType = TextureImporterType.Default; ti.mipmapEnabled = false; ti.filterMode = FilterMode.Bilinear;
            ti.wrapMode = TextureWrapMode.Clamp; ti.alphaIsTransparency = true;
            ti.SaveAndReimport();
        }
        foreach (var m in TRILHAS)
        {
            var musica = (AudioImporter)AssetImporter.GetAtPath("Assets/Resources/Musica/" + m + ".ogg");
            if (musica == null) continue;
            var cfg = musica.defaultSampleSettings;
            if (cfg.loadType == AudioClipLoadType.Streaming) continue;
            cfg.loadType = AudioClipLoadType.Streaming; musica.defaultSampleSettings = cfg;
            musica.SaveAndReimport();
        }
        {
            var ti = (TextureImporter)AssetImporter.GetAtPath("Assets/Art/UI/logo_vallack.png");
            ti.textureType = TextureImporterType.Sprite; ti.mipmapEnabled = false; ti.filterMode = FilterMode.Bilinear;
            ti.textureCompression = TextureImporterCompression.Uncompressed; ti.maxTextureSize = 1024;
            ti.SaveAndReimport();
        }

        foreach (var img in Directory.GetFiles("Assets/Art/UI", "*.jpg"))
        {
            var ti = (TextureImporter)AssetImporter.GetAtPath(img.Replace("\\", "/"));
            if (ti == null || ti.textureType == TextureImporterType.Sprite) continue;
            ti.textureType = TextureImporterType.Sprite; ti.mipmapEnabled = false; ti.filterMode = FilterMode.Bilinear; ti.maxTextureSize = 2048;
            ti.SaveAndReimport();
        }
        foreach (var img in new[] { "Assets/Art/Cenario/castelo_a.png", "Assets/Art/Cenario/castelo_b.png" })
        {
            var ti = (TextureImporter)AssetImporter.GetAtPath(img);
            if (ti == null) continue;
            ti.textureType = TextureImporterType.Default; ti.npotScale = TextureImporterNPOTScale.None; ti.mipmapEnabled = false;
            ti.filterMode = FilterMode.Bilinear; ti.wrapMode = TextureWrapMode.Clamp; ti.maxTextureSize = 4096;
            ti.SaveAndReimport();
        }

        // ---------- materiais ----------
        Directory.CreateDirectory("Assets/Art/Mat");
        var brilho = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Art/Gerado/brilho.png");
        var aditivo = Material("Assets/Art/Mat/Aditivo.mat", brilho, BlendMode.SrcAlpha, BlendMode.One);
        var alfa = Material("Assets/Art/Mat/Alfa.mat", brilho, BlendMode.SrcAlpha, BlendMode.OneMinusSrcAlpha);
        var fogo = Material("Assets/Art/Mat/Fogo.mat", AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Art/Gerado/chama.png"), BlendMode.SrcAlpha, BlendMode.One);
        var lit = AssetDatabase.LoadAssetAtPath<Material>(URP_MAT + "Sprite-Lit-Default.mat");
        var unlit = AssetDatabase.LoadAssetAtPath<Material>(URP_MAT + "Sprite-Unlit-Default.mat");
        if (lit == null || unlit == null) Debug.LogError("[fase1] materiais de sprite do URP não encontrados");

        // ---------- cena ----------
        var cena = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        var cam = new GameObject("Câmera").AddComponent<Camera>();
        cam.tag = "MainCamera";
        cam.orthographic = true;
        cam.orthographicSize = 140f;
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = new Color32(24, 18, 36, 255);
        cam.nearClipPlane = 0.1f; cam.farClipPlane = 100f;
        cam.transform.position = new Vector3(300, -550, -10);
        cam.gameObject.AddComponent<AudioListener>();
        var dadosCam = cam.gameObject.AddComponent<UniversalAdditionalCameraData>();
        dadosCam.renderPostProcessing = true;
        dadosCam.antialiasing = AntialiasingMode.None;
        var camV = cam.gameObject.AddComponent<CameraVallack>();
        cam.gameObject.AddComponent<MedidorFps>();
        var chuva = cam.gameObject.AddComponent<Chuva>();
        chuva.alfa = alfa;

        // noite: a luz global é fria e baixa; quem ilumina a rua é o fogo
        var global = new GameObject("Luz global (noite)").AddComponent<Light2D>();
        global.lightType = Light2D.LightType.Global;
        global.color = new Color(0.84f, 0.8f, 0.96f);
        global.intensity = 0.78f;
        Vila.LuzCamadas(global);

        // pós-processamento: o fogo transborda (bloom), cantos escuros, contraste
        var perfil = ScriptableObject.CreateInstance<VolumeProfile>();
        var bloom = perfil.Add<Bloom>(true);
        bloom.threshold.Override(0.9f); bloom.intensity.Override(0.55f); bloom.scatter.Override(0.55f);
        // celular: bloom barato (começa em 1/4 da tela, poucas passadas, filtro simples)
        bloom.highQualityFiltering.Override(false);
        bloom.downscale.Override(BloomDownscaleMode.Quarter);
        bloom.maxIterations.Override(4);
        bloom.tint.Override(new Color(1f, 0.86f, 0.92f));
        var vin = perfil.Add<Vignette>(true);
        vin.intensity.Override(0.3f); vin.smoothness.Override(0.45f); vin.color.Override(new Color(0.05f, 0.02f, 0.06f));
        var ajuste = perfil.Add<ColorAdjustments>(true);
        ajuste.contrast.Override(10f); ajuste.saturation.Override(6f);
        AssetDatabase.DeleteAsset("Assets/Settings/Fase1Volume.asset");
        AssetDatabase.CreateAsset(perfil, "Assets/Settings/Fase1Volume.asset");
        foreach (var c in perfil.components) AssetDatabase.AddObjectToAsset(c, perfil);
        var vol = new GameObject("Pós-processamento").AddComponent<Volume>();
        vol.isGlobal = true;
        vol.sharedProfile = perfil;

        var terreno = new GameObject("Terreno").AddComponent<TerrenoFase1>();
        terreno.materialLit = lit;
        terreno.pecasTex = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Art/Cenario/pecas_fase1.png");
        terreno.pecasJson = AssetDatabase.LoadAssetAtPath<TextAsset>("Assets/Art/Cenario/pecas_fase1.json");

        var vila = new GameObject("Vila em Chamas").AddComponent<Vila>();
        vila.cenarioJson = AssetDatabase.LoadAssetAtPath<TextAsset>("Assets/Art/Cenario/cenario_fase1.json");
        vila.cenarioTex = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Art/Cenario/cenario_fase1.png");
        vila.casteloA = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Art/Cenario/castelo_a.png");
        vila.casteloB = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Art/Cenario/castelo_b.png");
        vila.lit = lit; vila.unlit = unlit; vila.aditivo = aditivo; vila.alfa = alfa; vila.fogo = fogo;

        // Twilight
        var tw = new GameObject("Twilight");
        var sr = tw.AddComponent<SpriteRenderer>();
        sr.sharedMaterial = lit;
        sr.sortingOrder = 100;
        var an = tw.AddComponent<SpriteAnimador>();
        var j = tw.AddComponent<Jogador>();
        j.parado = Anim("spr_player_parado"); j.andar = Anim("spr_player_andar"); j.corrida = Anim("spr_player_corrida");
        j.pulo = Anim("spr_player_jump"); j.queda = Anim("spr_player_fall"); j.agachar = Anim("spr_player_agaichar");
        j.ataqueRapido = Anim("spr_player_ataque_rapido"); j.ataqueDuplo = Anim("spr_player_ataque_duplo");
        j.ataqueTriplo = Anim("spr_player_ataque_triplo"); j.ataqueFrenetico = Anim("spr_player_ataque_frenetico");
        j.ataqueAr = Anim("spr_player_ataque_ar");
        j.sPulo = Som("sfx_pulo"); j.sPouso = Som("sfx_pouso"); j.sCorte1 = Som("atk_corte_1"); j.sCorte2 = Som("atk_corte_2");
        j.sPesado = Som("atk_pesado"); j.sAereo = Som("atk_aereo");
        j.defendendo = Anim("spr_player_defendendo"); j.ferido = Anim("spr_player_dano"); j.morte = Anim("spr_player_morte");
        j.sCritico = Som("sfx_critico"); j.sBackdash = Som("sfx_backdash");
        j.ataque = Anim("spr_player_ataque"); j.ataque2 = Anim("spr_ataque_2"); j.ataque03 = Anim("spr_ataque_03");
        j.agachadoAtaque = Anim("spr_player_atacar_agaichado"); j.especial = Anim("spr_player_especial");
        j.agachadoEspecial = Anim("spr_player_atacar_agaichado_especial"); j.especial2 = Anim("spr_ataque_especial_2");
        j.subindoEscada = Anim("spr_player_subindo_escada"); j.descendoEscada = Anim("spr_player_descendo_escada");
        j.agarrarCorda = Anim("spr_player_pular_e_agarrar_cordas"); j.subindoCorda = Anim("spr_player_segurando_e_subindo_cordas");
        j.aditivo = aditivo;
        j.x = 128f; j.y = TerrenoFase1.CHAO;
        an.anim = j.parado;
        if (j.parado != null) sr.sprite = j.parado.quadros[0];
        camV.alvo = j;

        new GameObject("Tempo").AddComponent<Tempo>();
        var fx = new GameObject("Efeitos").AddComponent<Efeitos>();
        fx.aditivo = aditivo; fx.alfa = alfa; fx.fogo = fogo;
        fx.hits = new[] { Som("hit_1"), Som("hit_2"), Som("hit_3") };
        fx.hitPesado = Som("hit_pesado"); fx.explosao = Som("fogo_explosao"); fx.bloqueio = Som("sfx_bloqueio");
        fx.aparar = Som("sfx_aparar"); fx.dano = Som("sfx_dano"); fx.esquiva = Som("sfx_esquiva"); fx.derrota = Som("sfx_derrota");
        fx.inimigoGolpe = Som("sfx_inimigo_golpe"); fx.portal = Som("sfx_portal"); fx.evaporar = Som("maldicao_evaporar");

        fx.escudoQuebra = Som("sfx_escudo_quebra"); fx.ossoDesmonta = Som("osso_desmonta"); fx.ossoErgue = Som("osso_ergue");
        fx.aranhaChiado = Som("aranha_chiado"); fx.teiaDisparo = Som("teia_disparo"); fx.teiaPrende = Som("teia_prende");
        fx.pedraTinido = Som("pedra_tinido"); fx.pedraDesmorona = Som("pedra_desmorona"); fx.estatuaCarga = Som("estatua_carga"); fx.estatuaDisparo = Som("estatua_disparo");
        fx.porcoGrunhido = Som("porco_grunhido"); fx.porcoImpacto = Som("porco_impacto"); fx.magiaOnda = Som("magia_onda"); fx.rugido = Som("sfx_rugido");
        fx.atkPesado = Som("atk_pesado"); fx.pulo = Som("sfx_pulo");
        fx.ossoQuebra = Som("osso_quebra"); fx.ossoChocalho = Som("osso_chocalho"); fx.flecha = Som("sfx_flecha");

        // todos os efeitos sonoros entram pelo nome do arquivo (Efeitos.Tocar("sfx_cura"))
        var todosSons = new System.Collections.Generic.List<string>();
        foreach (var arq in Directory.GetFiles("Assets/Resources/Sons", "*.ogg"))
        {
            string n = Path.GetFileNameWithoutExtension(arq);
            if (!n.StartsWith("amb_")) todosSons.Add(n);
        }
        fx.nomes = todosSons.ToArray();

        var mus = new GameObject("Música").AddComponent<Musica>();

        var telas = new GameObject("Telas").AddComponent<Telas>();
        telas.logo = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/logo_vallack.png");
        telas.avisoFiccao = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/intro_aviso.jpg");
        telas.mapa = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/mapa_fases.jpg");
        var paginas = new System.Collections.Generic.List<Sprite>();
        for (int n = 1; n <= 30; n++) { var s = AssetDatabase.LoadAssetAtPath<Sprite>($"Assets/Art/UI/cutscene_{n}.jpg"); if (s == null) break; paginas.Add(s); }
        telas.prologo = paginas.ToArray();
        telas.videoEstudio = File.Exists("Assets/StreamingAssets/intro_estudio.mp4") ? "intro_estudio.mp4" : "";
        Debug.Log($"[fase1] prólogo: {paginas.Count} imagens · vídeo: {(telas.videoEstudio != "" ? "ok" : "sem vídeo")}");

        var objs = new GameObject("Objetos").AddComponent<ObjetosFase1>();
        objs.room1 = AssetDatabase.LoadAssetAtPath<TextAsset>("Assets/Art/Cenario/Room1.json");
        objs.room2 = AssetDatabase.LoadAssetAtPath<TextAsset>("Assets/Art/Cenario/Room2.json");
        objs.aEspinhos = Anim("spr_espinhos");
        objs.aCaixote = Anim("spr_caixote"); objs.aBarril = Anim("spr_barril"); objs.aBau = Anim("spr_bau");
        objs.lit = lit; objs.aditivo = aditivo; objs.alfa = alfa;

        var ini = new GameObject("Inimigos").AddComponent<InimigosFase1>();
        ini.anims = System.Array.ConvertAll(InimigosFase1.ANIMS, Anim);
        ini.lit = lit; ini.aditivo = aditivo; ini.alfa = alfa;
        ini.room2 = AssetDatabase.LoadAssetAtPath<TextAsset>("Assets/Art/Cenario/Room2.json");

        new GameObject("Controles").AddComponent<Controles>();
        var hud = new GameObject("HUD").AddComponent<Hud>();
        hud.jogador = j;
        hud.retrato = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/heroi_retrato.png");
        hud.gameObject.AddComponent<RetratoDialogo>().retrato = hud.retrato;

        // som ambiente: música da fase, a chuva e o crepitar do incêndio

        Ambiente("Chuva (som)", "amb_chuva", 0.3f);
        Ambiente("Fogo (som)", "amb_fogo", 0.22f);

        // DIAGNÓSTICO: VALLACK_SEM="audio,imagens,castelo" tira grupos de recursos da cena
        string sem = System.Environment.GetEnvironmentVariable("VALLACK_SEM") ?? "";
        if (sem.Contains("audio")) { fx.nomes = new string[0]; foreach (var a in Object.FindObjectsByType<AudioSource>(FindObjectsSortMode.None)) a.clip = null; }
        if (sem.Contains("imagens")) { telas.prologo = new Sprite[0]; telas.mapa = null; telas.avisoFiccao = null; }
        if (sem.Contains("castelo")) { vila.casteloA = vila.casteloB = null; }
        if (sem != "") Debug.Log("[fase1] SEM: " + sem);

        EditorSceneManager.SaveScene(cena, CENA);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(CENA, true) };
        AssetDatabase.SaveAssets();
        Debug.Log("[fase1] cena criada: " + CENA);
    }

    // ---------------------------------------------------------------
    static void Copiar(string nome, string pasta)
    {
        string de = Path.Combine(Godot, nome);
        if (!File.Exists(de)) { Debug.LogWarning("[fase1] falta " + de); return; }
        Directory.CreateDirectory(pasta);
        File.Copy(de, Path.Combine(pasta, nome), true);
    }

    static void Atlas(string caminho)
    {
        var ti = (TextureImporter)AssetImporter.GetAtPath(caminho);
        if (ti == null) return;
        ti.textureType = TextureImporterType.Default;
        ti.npotScale = TextureImporterNPOTScale.None;
        ti.mipmapEnabled = false;
        ti.filterMode = FilterMode.Point;
        ti.wrapMode = TextureWrapMode.Clamp;
        ti.alphaIsTransparency = true;
        ti.textureCompression = TextureImporterCompression.Uncompressed;
        ti.maxTextureSize = 4096;
        ti.SaveAndReimport();
    }

    static void GerarBrilho(string caminho)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(caminho));
        const int N = 64;
        var t = new Texture2D(N, N, TextureFormat.RGBA32, false);
        for (int y = 0; y < N; y++)
            for (int x = 0; x < N; x++)
            {
                float dx = (x + 0.5f) / N * 2 - 1, dy = (y + 0.5f) / N * 2 - 1;
                float d = Mathf.Clamp01(1 - Mathf.Sqrt(dx * dx + dy * dy));
                t.SetPixel(x, y, new Color(1, 1, 1, d * d * (3 - 2 * d)));
            }
        File.WriteAllBytes(caminho, t.EncodeToPNG());
        Object.DestroyImmediate(t);
    }

    // labareda em pixel art: 12 x 20, ponta fina em cima, núcleo claro embaixo
    // (a cor vem da partícula: o branco vira amarelo -> laranja -> roxo)
    static void GerarChama(string caminho)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(caminho));
        const int W = 12, H = 20;
        var t = new Texture2D(W, H, TextureFormat.RGBA32, false);
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
            {
                float v = (y + 0.5f) / H;                                   // 0 = base, 1 = ponta
                float meia = (W / 2f) * (v < 0.28f ? Mathf.Sqrt(v / 0.28f) : Mathf.Pow((1f - v) / 0.72f, 1.15f));
                float dx = Mathf.Abs(x + 0.5f - W / 2f);
                Color c = new Color(0, 0, 0, 0);
                if (dx < meia)
                {
                    float r = dx / Mathf.Max(meia, 0.01f);
                    if (r < 0.45f && v < 0.62f) c = new Color(1f, 1f, 1f, 1f);               // núcleo
                    else if (r < 0.78f) c = new Color(0.82f, 0.82f, 0.82f, 0.85f);          // corpo
                    else c = new Color(0.6f, 0.6f, 0.6f, 0.55f);                             // borda
                }
                t.SetPixel(x, y, c);
            }
        File.WriteAllBytes(caminho, t.EncodeToPNG());
        Object.DestroyImmediate(t);
    }

    static Material Material(string caminho, Texture2D tex, BlendMode src, BlendMode dst)
    {
        var m = AssetDatabase.LoadAssetAtPath<Material>(caminho);
        if (m == null)
        {
            m = new Material(Shader.Find("Vallack/Particula"));
            AssetDatabase.CreateAsset(m, caminho);
        }
        m.shader = Shader.Find("Vallack/Particula");
        m.SetTexture("_MainTex", tex);
        m.SetFloat("_Src", (float)src);
        m.SetFloat("_Dst", (float)dst);
        m.renderQueue = 3000;
        EditorUtility.SetDirty(m);
        return m;
    }

    static SpriteAnim Anim(string nome)
    {
        var a = AssetDatabase.LoadAssetAtPath<SpriteAnim>($"Assets/Art/Anims/{nome}.asset");
        if (a == null) Debug.LogWarning("[fase1] sem animação " + nome);
        return a;
    }

    static AudioClip Som(string nome) => AssetDatabase.LoadAssetAtPath<AudioClip>($"Assets/Resources/Sons/{nome}.ogg");

    static void Ambiente(string nome, string clip, float vol)
    {
        var a = new GameObject(nome).AddComponent<AudioSource>();
        a.clip = Som(clip);
        a.loop = true;
        a.playOnAwake = true;
        a.volume = vol;
        a.spatialBlend = 0;
    }
}
