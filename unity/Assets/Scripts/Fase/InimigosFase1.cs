// =====================================================================
//  InimigosFase1 — põe na Vila em Chamas os inimigos do Room1 original,
//  já nas posições da v1.14 ("mover": espalhados pela fase, o arqueiro no
//  alto da torre de vigia). Ainda faltam: Mulher-Aranha, Estátua, Homem-
//  Porco, o Carrasco e a Árvore.
// =====================================================================
using System.Collections.Generic;
using UnityEngine;

public class InimigosFase1 : MonoBehaviour
{
    // animações usadas (o montador da cena preenche "anims" nesta ordem)
    public static readonly string[] ANIMS =
    {
        "spr_inimigo01_parado", "spr_inimigo01_andar", "spr_inimigo01_correndo", "spr_inimigo01_atacando", "spr_inimigo01_pulando", "spr_inimigo01_morrendo",
        "spr_esqueleto_parado", "spr_esqueleto_andando", "spr_esqueleto_correndo", "spr_esqueleto_ataque", "spr_esqueleto_dano", "spr_esqueleto_morrendo",
        "spr_inimigo02_parado", "spr_inimigo02_correndo", "spr_inimigo02_atacando", "spr_inimigo02_sofrendo_dano", "spr_inimigo02_morrendo",
        "spr_escudo",
        "spr_aranha_parada", "spr_aranha_andando", "spr_aranha_ataque",
        "spr_estatua", "spr_estatua_orbe",
        "spr_boss_01_parado", "spr_boss_01", "spr_boss_01_atacando", "spr_boss_fogo_parado", "spr_boss_fogo", "spr_boss_fogo_atacando", "spr_boss_01_bola_de_fogo",
        "spr_porco_parado", "spr_porco_correndo", "spr_porco_ataque", "spr_porco_morrendo", "spr_porco_salto", "spr_porco_roxo", "spr_porco_furia",
    };
    public static InimigosFase1 eu;
    void Awake() { eu = this; }

    // esqueletos invocados (Homem-Porco em fúria, a Árvore): não se reerguem
    public void InvocarEsqueleto(float x, float y, float atraso)
    {
        var e = Criar<Esqueleto>("Esqueleto invocado", x, y, false);
        e.reerguido = true; e.surgirAgora = true; e.surgirAtraso = atraso; e.invocado = true;
    }
    // GUARDAS DA RAIZ da Árvore: besta, esqueleto, arqueiro ou aranha, com 80% da vida
    public void InvocarServo(string tipo, float x, float y, float atraso)
    {
        Inimigo e = tipo == "esqueleto" ? Preparar<Esqueleto>(x, y) : (tipo == "arqueiro" ? Preparar<Arqueiro>(x, y) : (tipo == "aranha" ? Preparar<Aranha>(x, y) : Preparar<Inimigo>(x, y)));
        e.surgirAgora = true; e.surgirAtraso = atraso; e.invocado = true; e.vidaMult = 0.8f;
        if (e is Esqueleto esq) esq.reerguido = true;
        e.gameObject.SetActive(true);
    }

    // javalis de guerra do Carrasco: 60% da vida, sem deixar essência
    public void InvocarPorco(float x, float y, float atraso)
    {
        var e = Criar<Porco>("Javali de guerra", x, y, false);
        e.surgirAgora = true; e.surgirAtraso = atraso; e.invocado = true; e.vidaBase *= 0.6f;
    }

    // guardiões da arena da chave: surgem por portal na hora e ficam presos ao alto do forte
    public T Guardiao<T>(float x, float y, float atraso) where T : Inimigo
    {
        var e = Criar<T>("Guardião", x, y, false);
        e.surgirAgora = true; e.surgirAtraso = atraso;
        return e;
    }
    public SpriteAnim[] anims;
    public Material lit, aditivo, alfa;
    public TextAsset room2;
    bool fase2Pronta; float fimT;

    // Fase 2: os inimigos vêm direto do Room2 (nível 2 no mapa: +15% de vida)
    void MontarFase2()
    {
        if (room2 == null) return;
        foreach (var o in MiniJson.L(MiniJson.D(MiniJson.Ler(room2.text))["instancias"]))
        {
            var d = MiniJson.D(o);
            string obj = (string)d["obj"];
            float x = MiniJson.F(d["x"]), y = TerrenoFase1.CHAO;
            Inimigo e = null;
            switch (obj)
            {
                case "obj_inimigo_01": e = Preparar<Inimigo>(x, y, "Besta"); break;
                case "obj_besta_elite": e = Preparar<Inimigo>(x, y, "Besta de elite", true); break;
                case "obj_esqueleto": e = Preparar<Esqueleto>(x, y, "Esqueleto"); break;
                case "obj_aranha": e = Preparar<Aranha>(x, y, "Mulher-Aranha"); break;
                case "obj_estatua": e = Preparar<Estatua>(x, y, "Estátua Enfeitiçada"); break;
                case "obj_porco": e = Preparar<Porco>(x, y, "Homem-Porco"); break;
            }
            if (e == null) continue;
            e.vidaMult = 1.15f;
            e.gameObject.SetActive(true);
        }
        fase2Pronta = true;
    }

    void Update()
    {
        // FIM DO JOGO NA FASE 2: não resta nenhum inimigo vivo
        if (!fase2Pronta || Jogador.eu == null || Jogador.eu.morto) return;
        foreach (var e in Inimigo.todos) if (!e.morrendo) { fimT = 0; return; }
        fimT += Time.deltaTime;
        if (fimT > 2.5f) { fase2Pronta = false; Telas.Final(); }
    }

    readonly Dictionary<string, SpriteAnim> mapa = new Dictionary<string, SpriteAnim>();
    SpriteAnim A(string nome) => mapa.TryGetValue(nome, out var a) ? a : null;

    void Start()
    {
        for (int i = 0; i < ANIMS.Length && i < anims.Length; i++) mapa[ANIMS[i]] = anims[i];
        if (Fase.numero == 2) { MontarFase2(); return; }

        // tipo, x, y do pé, elite
        Criar<Inimigo>("Besta", 760f, 693f, false);
        Criar<Inimigo>("Besta de elite", 1180f, 693f, true);
        Criar<Inimigo>("Besta", 1600f, 605f, false);
        Criar<Inimigo>("Besta", 1900f, 693f, false);
        Criar<Inimigo>("Besta", 1990f, 693f, false);
        Criar<Esqueleto>("Esqueleto", 3930f, 693f, false);
        Criar<Esqueleto>("Esqueleto de elite", 3380f, 693f, true);
        Criar<Escudeiro>("Besta Escudeira", 3740f, 693f, false);
        Criar<Arqueiro>("Arqueiro", 3562f, 605f, false);
        Criar<Estatua>("Estátua Enfeitiçada", 1738f, 585f, false);
        Criar<Porco>("Homem-Porco", 3250f, 693f, false);
        Criar<Aranha>("Mulher-Aranha", 4150f, 693f, false);
        Criar<Carrasco>("O Carrasco de Vallack", 2850f, 693f, false);
        Criar<Arvore>("Árvore Amaldiçoada", 4736f, 693f, false);
    }

    T Criar<T>(string nome, float x, float y, bool elite) where T : Inimigo
    {
        var e = Preparar<T>(x, y, nome, elite);
        e.gameObject.SetActive(true);
        return e;
    }

    // monta o inimigo desligado (os campos entram antes do Awake/Start); quem chama liga
    T Preparar<T>(float x, float y, string nome = "Servo", bool elite = false) where T : Inimigo
    {
        var go = new GameObject(nome);
        go.transform.SetParent(transform, false);
        go.SetActive(false);                       // os campos entram antes do Awake/Start
        var e = go.AddComponent<T>();
        e.x = x; e.y = y; e.elite = elite;
        e.lit = lit; e.aditivo = aditivo; e.alfa = alfa;
        if (e is Esqueleto)
        {
            e.aParado = A("spr_esqueleto_parado"); e.aAndar = A("spr_esqueleto_andando"); e.aCorrer = A("spr_esqueleto_correndo");
            e.aAtaque = A("spr_esqueleto_ataque"); e.aPular = A("spr_esqueleto_correndo"); e.aMorrer = A("spr_esqueleto_morrendo");
            e.aAtordoado = A("spr_esqueleto_dano");
        }
        else if (e is Arvore arv)
        {
            e.aParado = A("spr_boss_01_parado"); e.aAndar = e.aCorrer = e.aPular = e.aMorrer = A("spr_boss_01"); e.aAtaque = A("spr_boss_01_atacando");
            arv.aAcao = A("spr_boss_01"); arv.aFogoParado = A("spr_boss_fogo_parado"); arv.aFogoAcao = A("spr_boss_fogo");
            arv.aFogoAtaque = A("spr_boss_fogo_atacando"); arv.aBola = A("spr_boss_01_bola_de_fogo");
        }
        else if (e is Aranha)
        {
            e.aParado = A("spr_aranha_parada"); e.aAndar = A("spr_aranha_andando"); e.aCorrer = A("spr_aranha_andando");
            e.aAtaque = A("spr_aranha_ataque"); e.aPular = A("spr_aranha_ataque"); e.aMorrer = A("spr_aranha_parada");
        }
        else if (e is Estatua est)
        {
            e.aParado = e.aAndar = e.aCorrer = e.aAtaque = e.aPular = e.aMorrer = A("spr_estatua");
            est.aOrbe = A("spr_estatua_orbe");
        }
        else if (e is Porco po)
        {
            e.aParado = A("spr_porco_parado"); e.aAndar = A("spr_porco_correndo"); e.aCorrer = A("spr_porco_correndo");
            e.aAtaque = A("spr_porco_ataque"); e.aPular = A("spr_porco_salto"); e.aMorrer = A("spr_porco_morrendo");
            po.aSalto = A("spr_porco_salto"); po.aRoxo = A("spr_porco_roxo"); po.aFuria = A("spr_porco_furia");
        }
        else if (e is Arqueiro)
        {
            e.aParado = A("spr_inimigo02_parado"); e.aAndar = A("spr_inimigo02_correndo"); e.aCorrer = A("spr_inimigo02_correndo");
            e.aAtaque = A("spr_inimigo02_atacando"); e.aPular = A("spr_inimigo02_correndo"); e.aMorrer = A("spr_inimigo02_morrendo");
            e.aAtordoado = A("spr_inimigo02_sofrendo_dano");
        }
        else
        {
            e.aParado = A("spr_inimigo01_parado"); e.aAndar = A("spr_inimigo01_andar"); e.aCorrer = A("spr_inimigo01_correndo");
            e.aAtaque = A("spr_inimigo01_atacando"); e.aPular = A("spr_inimigo01_pulando"); e.aMorrer = A("spr_inimigo01_morrendo");
            if (e is Escudeiro esc) esc.aEscudo = A("spr_escudo");
        }
        return e;
    }
}
