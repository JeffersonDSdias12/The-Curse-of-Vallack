// =====================================================================
//  BuildAndroid — gera o APK do celular sem abrir o editor (modo batch).
//  Uso (linha de comando):
//    Unity.exe -batchmode -quit -projectPath unity -executeMethod BuildAndroid.Construir
//  O APK sai em ../build/unity/TheCurseOfVallack_unity.apk (ou em VALLACK_APK).
//  Também no menu do editor: Vallack > Build Android.
// =====================================================================
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;

public static class BuildAndroid
{
    // durante o desenvolvimento convive no celular com a versão Godot
    const string PACOTE = "com.fapan.thecurseofvallack.unity";

    [MenuItem("Vallack/Build Android")]
    public static void Construir()
    {
        Configurar();
        var cenas = EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray();
        string saida = System.Environment.GetEnvironmentVariable("VALLACK_APK");
        if (string.IsNullOrEmpty(saida)) saida = Path.GetFullPath(Path.Combine(Application.dataPath, "../../build/unity/TheCurseOfVallack_unity.apk"));
        Directory.CreateDirectory(Path.GetDirectoryName(saida));
        var r = BuildPipeline.BuildPlayer(new BuildPlayerOptions
        {
            scenes = cenas,
            locationPathName = saida,
            target = BuildTarget.Android,
            options = BuildOptions.None,
        });
        Debug.Log("[build] resultado=" + r.summary.result + " tamanho=" + r.summary.totalSize + " tempo=" + r.summary.totalTime + " apk=" + saida);
        if (Application.isBatchMode) EditorApplication.Exit(r.summary.result == BuildResult.Succeeded ? 0 : 1);
    }

    [MenuItem("Vallack/Configurar Android")]
    public static void Configurar()
    {
        if (EditorUserBuildSettings.activeBuildTarget != BuildTarget.Android)
            EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Android, BuildTarget.Android);
        PlayerSettings.companyName = "Fapan";
        PlayerSettings.productName = "The Curse of Vallack";
        PlayerSettings.bundleVersion = "2.0.0";
        PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android, PACOTE);
        // C# compilado em código nativo: a lógica fica muitas vezes mais rápida que no GDScript
        PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
        // desenvolvimento: só ARM64 (o Redmi de teste) — o IL2CPP compila na metade do tempo.
        // Para a versão de lançamento: VALLACK_ARMV7=1 inclui os celulares antigos de 32 bits.
        PlayerSettings.Android.targetArchitectures = System.Environment.GetEnvironmentVariable("VALLACK_ARMV7") == "1"
            ? AndroidArchitecture.ARM64 | AndroidArchitecture.ARMv7 : AndroidArchitecture.ARM64;
        // jogo de ação de lado: só paisagem
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.AutoRotation;
        PlayerSettings.allowedAutorotateToPortrait = false;
        PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
        PlayerSettings.allowedAutorotateToLandscapeLeft = true;
        PlayerSettings.allowedAutorotateToLandscapeRight = true;
        PlayerSettings.Android.renderOutsideSafeArea = true;
        EditorUserBuildSettings.buildAppBundle = false;
        PlayerSettings.Android.useCustomKeystore = false;    // chave de depuração do Unity (por enquanto)
        AssetDatabase.SaveAssets();
    }
}
