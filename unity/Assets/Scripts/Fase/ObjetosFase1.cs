// =====================================================================
//  ObjetosFase1 — o que há pela Vila em Chamas além do chão e dos inimigos
//  (Room1 + obj_terreno): caixotes e barris com orbs, baús de vida, cristais
//  de checkpoint, escadas de mão e cordas, o FORTE com a ARENA DA CHAVE (o
//  baú selado até os guardiões caírem) e o PORTÃO TRANCADO no meio da fase.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class ObjetosFase1 : MonoBehaviour
{
    public TextAsset room1, room2;
    public SpriteAnim aCaixote, aBarril, aBau, aEspinhos;
    bool faseDois, moradorFalou;
    public Material lit, aditivo, alfa;

    // a CHAVE DO PORTÃO: baú selado no alto do forte; ao chegar, os guardiões surgem
    const float ARENA_X1 = 2128f, ARENA_X2 = 2322f, ARENA_Y = 360f, PORTAO_X = 2470f;
    Interativo bauChave;
    string arena = "espera";
    readonly List<Inimigo> guardioes = new List<Inimigo>();
    int portaoSolido = -1;
    bool portaoAberto;
    float portaoAviso;
    SpriteRenderer portao;

    void Start()
    {
        faseDois = Fase.numero == 2;
        var sala = faseDois ? room2 : room1;
        if (sala != null)
        {
            var insts = MiniJson.L(MiniJson.D(MiniJson.Ler(sala.text))["instancias"]);
            foreach (var o in insts)
            {
                var d = MiniJson.D(o);
                string obj = (string)d["obj"];
                float x = MiniJson.F(d["x"]), y = MiniJson.F(d["y"]);
                if (obj == "obj_espinhos") { Espinhos.Criar(x, TerrenoFase1.CHAO, aEspinhos, lit); continue; }
                if (obj == "obj_fogo_chao") { FogoChao.Criar(x, TerrenoFase1.CHAO, MiniJson.F(d["sx"]), aditivo); continue; }
                if (obj == "obj_viga_fogo") { VigaFogo.Criar(x, TerrenoFase1.CHAO, lit, aditivo, alfa); continue; }
                if (!faseDois && NoAbismoOuEscada(x)) continue;
                float chao = ChaoAbaixo(x, y - 40);
                switch (obj)
                {
                    case "obj_caixote": Destrutivel.Criar(x, chao, aCaixote, lit, false); break;
                    case "obj_barril": Destrutivel.Criar(x, chao, aBarril, lit, true); break;
                    case "obj_bau": Interativo.Bau(x, chao, aBau, lit, aditivo); break;
                    case "obj_save_point": Checkpoint.Criar(x, chao, aditivo); break;
                }
            }
        }
        if (faseDois) return;       // o salão do castelo não tem forte nem portão
        // caixotes com orbs nos caminhos de cima (andaime)
        foreach (var c in new[] { 1090f, 1124f, 1180f }) Destrutivel.Criar(c, 470f, aCaixote, lit, false);
        // checkpoints antes das duas lutas grandes
        Checkpoint.Criar(2400f, 693f, aditivo);
        Checkpoint.Criar(4300f, 693f, aditivo);

        foreach (var e in Escalada.DADOS) Escalavel(e[0], e[1], e[2], e[3] == 0);

        bauChave = Interativo.Bau(2226f, ARENA_Y, aBau, lit, aditivo, "chave");
        bauChave.selado = true;
        if (Jogo.chavePortao) { arena = "livre"; bauChave.selado = false; }

        // portão trancado: uma grade de ferro do chão até o alto
        Mundo.Solido(PORTAO_X, 440f, PORTAO_X + 16f, 693f);
        portaoSolido = Mundo.solidos.Count - 1;
        portao = Ret("portão trancado", PORTAO_X - 2f, 440f, PORTAO_X + 18f, 693f, new Color32(52, 46, 58, 255), 75, lit);
        for (int k = 0; k < 6; k++) Ret("barra", PORTAO_X - 2f, 470f + k * 38f, PORTAO_X + 18f, 474f + k * 38f, new Color32(110, 96, 70, 255), 76, lit).transform.SetParent(portao.transform, true);
    }

    static bool NoAbismoOuEscada(float x)
    {
        foreach (var a in TerrenoFase1.ABISMOS) if (x > a[0] - 16 && x < a[1] + 16) return true;
        return (x > 310 && x < 414) || (x > 3434 && x < 3600);
    }

    // y do primeiro chão abaixo de (x, y)
    static float ChaoAbaixo(float x, float y)
    {
        for (float yy = y; yy < Mundo.SALA_H; yy += 1f)
            if (Mundo.Colide(x - 1, yy, x + 1, yy + 1)) return yy;
        return TerrenoFase1.CHAO;
    }

    void Escalavel(float x, float yAlto, float yBaixo, bool escada)
    {
        if (escada)
        {
            Ret("escada", x - 9f, yAlto - 6f, x - 6f, yBaixo, new Color32(84, 56, 34, 255), 58, lit);
            Ret("escada", x + 6f, yAlto - 6f, x + 9f, yBaixo, new Color32(84, 56, 34, 255), 58, lit);
            for (float yy = yAlto + 4f; yy < yBaixo - 2f; yy += 9f) Ret("degrau", x - 8f, yy, x + 8f, yy + 2.5f, new Color32(120, 84, 50, 255), 59, lit);
        }
        else
        {
            Ret("corda", x - 1.5f, yAlto - 8f, x + 1.5f, yBaixo, new Color32(150, 120, 78, 255), 58, lit);
            for (float yy = yAlto + 10f; yy < yBaixo - 4f; yy += 22f) Ret("nó", x - 3f, yy, x + 3f, yy + 4f, new Color32(110, 84, 52, 255), 59, lit);
        }
    }

    SpriteRenderer Ret(string nome, float x1, float y1, float x2, float y2, Color c, int ordem, Material m)
    {
        var go = new GameObject(nome);
        go.transform.SetParent(transform, false);
        go.transform.position = Mundo.Tela(x1, y2);
        go.transform.localScale = new Vector3(x2 - x1, y2 - y1, 1f);
        var r = go.AddComponent<SpriteRenderer>();
        r.sprite = Texturas.Branco(); r.color = c; r.sortingOrder = ordem; r.sharedMaterial = m;
        return r;
    }

    void Update()
    {
        var p = Jogador.eu;
        if (p == null) return;
        if (faseDois) return;
        // o morador que foge da vila conta o que aconteceu (uma vez)
        if (!moradorFalou && p.x > 330f && p.x < 520f && p.NoChao && !p.morto) { moradorFalou = true; Dialogo.Iniciar("morador"); }
        // FIM DA FASE 1: chegou ao fim do caminho depois de vencer a Árvore
        if (Arvore.derrotada && !p.morto && p.x >= Mundo.SALA_W - 110f) Telas.Resultado();

        // ----- ARENA DA CHAVE no alto do forte -----
        if (arena == "espera" && Mathf.Abs(p.y - ARENA_Y) < 4f && p.x > ARENA_X1 + 20 && p.x < ARENA_X2 - 20 && p.NoChao)
        {
            arena = "luta";
            Telas.Aviso("OS GUARDIÕES DA CHAVE DESPERTAM");
            var ini = InimigosFase1.eu;
            if (ini != null)
            {
                guardioes.Add(ini.Guardiao<Esqueleto>(2164f, ARENA_Y, 10));
                guardioes.Add(ini.Guardiao<Inimigo>(2296f, ARENA_Y, 24));
                guardioes.Add(ini.Guardiao<Aranha>(2250f, ARENA_Y, 38));
            }
        }
        else if (arena == "luta")
        {
            guardioes.RemoveAll(g => g == null || g.morrendo);
            if (guardioes.Count == 0)
            {
                arena = "livre";
                bauChave.QuebrarSelo();
                Telas.Aviso("O SELO DO BAÚ SE PARTIU");
            }
        }

        // ----- PORTÃO TRANCADO -----
        if (!portaoAberto)
        {
            if (portaoAviso > 0) portaoAviso -= Time.deltaTime;
            bool perto = Mathf.Abs(p.x - PORTAO_X) < 60f && p.y > 600f;
            if (perto && Jogo.chavePortao)
            {
                portaoAberto = true;
                Mundo.solidos[portaoSolido] = new Mundo.Caixa { x1 = -99999, x2 = -99998, y1 = -99999, y2 = -99998 };
                Efeitos.Tocar("sfx_portal", 0.9f, 0f);
                Efeitos.Poeira(PORTAO_X + 8, 693f, 1.5f);
                CameraVallack.Tremer(8f);
                Telas.Aviso("O PORTÃO SE ABRE");
            }
            else if (perto && portaoAviso <= 0) { portaoAviso = 6f; Telas.Aviso("PORTÃO TRANCADO  ·  A CHAVE ESTÁ NO ALTO DO FORTE"); }
        }
        else if (portao != null)
        {
            // a grade sobe
            portao.transform.position += new Vector3(0, 140f * Time.deltaTime, 0);
            if (portao.transform.position.y > -300f) { Destroy(portao.gameObject); portao = null; }
        }
    }
}
