// =====================================================================
//  Golpes — a tabela de golpes do jogo original (golpe_criar / _q) e o
//  estado da partida (Jogo: orbs, essência, nível da espada).
//  Cada quadro: q (quadro da animação), d (duração em quadros de 60 FPS),
//  hit [x1, x2, y1, y2] relativo ao pé e à frente, av (avanço), dm (fração
//  do dano), grupo (cada inimigo leva 1 acerto por grupo), ev (evento),
//  esp (espera: "apice", "descendo", "chao").
// =====================================================================
using UnityEngine;

public static class Jogo
{
    public const int ESSENCIA_MAX = 9, ESPADA_NIVEL_MAX = 5;
    public const float ESPECIAL_SEGUNDOS = 10f, FURIA_MODO_QUADROS = 720f;
    public static int orbs, essencia = 3, espadaNivel = 1, inimigosDerrotados;
    public static bool chavePortao;

    public static float EspadaDanoMult => 1f + 0.08f * (espadaNivel - 1);
    public static float FuriaGanhoMult => espadaNivel >= 5 ? 1.35f : 1f;
    public static bool ComboLiberado(int n) => espadaNivel >= (n >= 3 ? 5 : (n == 2 ? 3 : 1));
    // especiais: 1 = ONDA CARMESIM (nível 2) · 2 = QUEDA CARMESIM (nível 4) · 3 = TREMOR DE VALLACK (nível 1)
    public static int EspecialNivelReq(int e) => e == 1 ? 2 : (e == 2 ? 4 : 1);
    public static bool EspecialLiberado(int e) => espadaNivel >= EspecialNivelReq(e);
    public static string EspecialNome(int e) => e == 1 ? "ONDA CARMESIM" : (e == 2 ? "QUEDA CARMESIM" : "TREMOR DE VALLACK");
    public static float EspecialCusto(int e) => e == 1 ? 0.4f : (e == 2 ? 0.7f : 0.6f);
    public static int EspadaCusto(int nivel) => new[] { 0, 0, 120, 280, 420, 520 }[Mathf.Clamp(nivel, 0, ESPADA_NIVEL_MAX)];

    public static void NovaPartida() { orbs = 0; essencia = 3; espadaNivel = 1; inimigosDerrotados = 0; chavePortao = false; }
}

public class Golpe
{
    public string chave, nome;
    public SpriteAnim spr;
    public float dano, forca, atordoa, lanca, porcento;
    public int cancel, combo, acaoEsp;
    public bool noAr, pesado, especial, armadura;
    public Quadro[] seq;
    // especiais, fúria, finalizador e projéteis rebatidos atravessam a pedra e o escudo
    public bool Forte => especial || chave == "ira" || chave == "finalizador";
}

public struct Quadro
{
    public int q;
    public float d;
    public float[] hit;
    public float av;          // NaN = sem avanço
    public float dm;
    public int grupo;
    public string ev, esp;
    public bool TemAv => !float.IsNaN(av);
}

public static class Golpes
{
    static Quadro Q(int q, float d, float[] hit = null, float av = float.NaN, float dm = 1f, int grupo = 0, string ev = null, string esp = null) =>
        new Quadro { q = q, d = d, hit = hit, av = av, dm = dm, grupo = grupo, ev = ev, esp = esp };

    static float[] H(float x1, float x2, float y1, float y2) => new[] { x1, x2, y1, y2 };

    public static Golpe Criar(string chave, Jogador j)
    {
        Golpe g = null;
        switch (chave)
        {
            // 1 toque = ATAQUE RÁPIDO, 2º = ATAQUE DUPLO (segunda metade), 3º = ATAQUE TRIPLO, 4º = FRENÉTICO
            case "corte1":
                g = new Golpe { nome = "ATAQUE RÁPIDO", spr = j.ataqueRapido, dano = 8, forca = 2.2f, atordoa = 30, cancel = 3, seq = new[] {
                    Q(0, 2), Q(1, 3, av: 0.8f), Q(2, 3, H(4, 58, -58, -34), 1.0f, 0.45f),
                    Q(3, 4, H(4, 64, -70, -6), grupo: 1, dm: 0.6f), Q(4, 3, H(4, 64, -50, -24), grupo: 2, dm: 0.4f), Q(5, 6) } };
                break;
            case "corte2":
                g = new Golpe { nome = "ATAQUE DUPLO", spr = j.ataqueDuplo, dano = 12, forca = 2.5f, atordoa = 32, cancel = 3, seq = new[] {
                    Q(6, 3, H(4, 58, -62, -42), 1.2f, 0.45f), Q(7, 4, H(-24, 54, -80, -6), grupo: 1, dm: 0.6f),
                    Q(8, 3, H(4, 56, -52, -18), grupo: 1), Q(9, 3), Q(10, 3, H(4, 66, -46, -26), 1.0f, 0.45f, 2), Q(11, 6) } };
                break;
            case "corte3":
                g = new Golpe { nome = "ATAQUE TRIPLO", spr = j.ataqueTriplo, pesado = true, dano = 18, forca = 5, atordoa = 50, lanca = 1, cancel = 4, seq = new[] {
                    Q(11, 3, av: 1.5f), Q(12, 4, H(-12, 62, -84, -4)), Q(13, 6, H(4, 58, -42, 6), grupo: 1, dm: 0.5f, ev: "impacto_leve"),
                    Q(14, 4), Q(15, 4), Q(16, 4), Q(17, 5) } };
                break;
            case "frenetico":
                g = new Golpe { nome = "ATAQUE FRENÉTICO", spr = j.ataqueFrenetico, pesado = true, dano = 30, forca = 6, atordoa = 60, lanca = 2, cancel = 99, combo = 1, seq = new[] {
                    Q(0, 3, H(-30, 58, -64, -10), 1.2f, 0.12f), Q(1, 3, H(-40, 60, -80, -4), grupo: 1, dm: 0.12f), Q(2, 3),
                    Q(3, 3, H(-30, 60, -58, -14), 0.8f, 0.12f, 2), Q(4, 3), Q(5, 3, H(-40, 52, -86, -4), grupo: 3, dm: 0.12f),
                    Q(6, 3, H(4, 56, -62, -4), grupo: 4, dm: 0.1f), Q(7, 3, H(4, 60, -52, -32), 1.0f, 0.1f, 5),
                    Q(8, 4, H(4, 74, -52, -22), 2.4f, 0.12f, 6), Q(9, 3), Q(10, 3, H(-30, 60, -86, -4), grupo: 7, dm: 0.12f),
                    Q(11, 3, H(4, 58, -82, -4), grupo: 8, dm: 0.1f), Q(12, 4, H(-8, 62, -98, 4), grupo: 9, dm: 0.3f, ev: "impacto_leve"),
                    Q(13, 6, H(-20, 66, -42, 6), grupo: 10, dm: 0.2f), Q(14, 4), Q(15, 4), Q(16, 4), Q(17, 6) } };
                break;
            case "corte_aereo":
                g = new Golpe { nome = "CORTE AÉREO", spr = j.ataqueAr, dano = 10, forca = 1.2f, atordoa = 30, cancel = 3, noAr = true, seq = new[] {
                    Q(0, 2), Q(1, 3), Q(2, 3, H(4, 46, -62, -4)), Q(3, 4, H(4, 60, -60, -4)), Q(4, 4, H(4, 38, -60, -4)), Q(5, 5) } };
                break;
            case "execucao":
                g = new Golpe { nome = "EXECUÇÃO", spr = j.ataque2, pesado = true, dano = 24, forca = 7, atordoa = 55, lanca = 2, cancel = 99, combo = 1, seq = new[] {
                    Q(1, 3), Q(2, 4, H(-4, 30, -84, -24), dm: 0.4f), Q(3, 4), Q(4, 3), Q(5, 3), Q(6, 5, ev: "brilho"),
                    Q(7, 3, H(4, 50, -72, -4), 3.0f, grupo: 1), Q(8, 7, H(4, 62, -46, 0), 1.8f, grupo: 1, ev: "impacto_leve"), Q(9, 6), Q(10, 5), Q(11, 5) } };
                break;
            case "carrasco":
            case "quebra_escudo":
                {
                    bool f = chave == "quebra_escudo";
                    g = new Golpe { nome = f ? "QUEBRA-ESCUDO" : "SALTO DO CARRASCO", spr = j.ataque2, pesado = true, dano = f ? 28 : 18, forca = f ? 8 : 6,
                        atordoa = f ? 75 : 45, lanca = f ? 4 : 3, cancel = 99, combo = f ? 2 : 0, noAr = true, seq = new[] {
                        Q(0, 4), Q(1, 4), Q(2, 4, H(-6, 32, -92, -26), dm: 0.45f, ev: "salto"), Q(3, 4), Q(4, 4), Q(5, 4),
                        Q(6, 3, esp: "descendo"), Q(7, 2, H(0, 46, -72, 2), grupo: 1, esp: "chao"),
                        Q(8, 8, f ? H(-58, 86, -56, 6) : H(-32, 64, -50, 6), grupo: 1, ev: f ? "impacto_quebra" : "impacto_carrasco"),
                        Q(9, 6), Q(10, 5), Q(11, 5) } };
                }
                break;
            case "mergulho":
                g = new Golpe { nome = "MERGULHO", spr = j.ataque2, pesado = true, dano = 16, forca = 5, atordoa = 40, lanca = 2, cancel = 99, noAr = true, seq = new[] {
                    Q(6, 4), Q(7, 2, H(0, 42, -64, 2), ev: "mergulho", esp: "chao"), Q(8, 7, H(-28, 58, -46, 6), grupo: 1, ev: "impacto_carrasco"),
                    Q(9, 6), Q(10, 5), Q(11, 4) } };
                break;
            case "rasteira":
            case "rasteira_sangrenta":
                {
                    bool s = chave == "rasteira_sangrenta";
                    float m = s ? 1.6f : 1f;
                    g = new Golpe { nome = s ? "RASTEIRA SANGRENTA" : "RASTEIRA", spr = j.agachadoAtaque, dano = s ? 16 : 9, forca = s ? 3 : 2,
                        atordoa = s ? 60 : 48, lanca = s ? 4.5f : 0, cancel = 4, combo = s ? 3 : 0, seq = new[] {
                        Q(0, 3, av: 1.5f * m), Q(1, 3, av: 2.0f * m), Q(2, 3, H(4, 47, -42, 0), 1.5f * m), Q(3, 4, H(4, 56, -42, 0), 0.8f * m),
                        Q(4, 4, H(4, 45, -42, 0)), Q(5, 7) } };
                }
                break;
            case "lancador":
                g = new Golpe { nome = "LANÇADOR", spr = j.ataque2, pesado = true, noAr = true, dano = 12, forca = 0.6f, atordoa = 55, cancel = 4, seq = new[] {
                    Q(0, 3), Q(1, 3), Q(2, 4, H(-8, 54, -100, 2), ev: "lancar"), Q(3, 4, H(-8, 46, -120, -24)), Q(4, 4), Q(5, 5) } };
                break;
            case "contra":
                g = new Golpe { nome = "CONTRA-ATAQUE", spr = j.ataque, pesado = true, armadura = true, dano = 1, forca = 1.4f, atordoa = 90, cancel = 99, seq = new[] {
                    Q(1, 2, av: 3.2f, ev: "contra"), Q(2, 3, H(0, 70, -70, 0), 2.4f), Q(3, 4, H(0, 86, -66, 0)), Q(4, 4, H(0, 60, -62, 0)), Q(5, 8) } };
                break;
            case "arremesso":
                g = new Golpe { nome = "LÂMINA BUMERANGUE", spr = j.ataque, cancel = 3, seq = new[] { Q(0, 3), Q(2, 3, ev: "bumerangue"), Q(3, 4), Q(5, 6) } };
                break;
            case "arremesso_chama":
                g = new Golpe { nome = "CHAMA DE SYLLA", spr = j.agachadoAtaque, cancel = 4, seq = new[] { Q(0, 3), Q(1, 3), Q(2, 4, ev: "chama"), Q(3, 4), Q(5, 7) } };
                break;
            case "onda":
                g = new Golpe { nome = "ONDA CARMESIM", spr = j.especial, especial = true, porcento = 0.30f, acaoEsp = 1, armadura = true, forca = 10, atordoa = 60, lanca = 2, cancel = 99, seq = new[] {
                    Q(0, 7, ev: "zoom"), Q(1, 5, H(0, 47, -82, -2)), Q(2, 5, H(0, 74, -54, -2), ev: "onda"), Q(3, 5, H(0, 56, -76, -2)), Q(4, 5, H(0, 45, -70, -2)), Q(5, 10) } };
                break;
            case "onda_agachado":
                g = new Golpe { nome = "ONDA CARMESIM", spr = j.agachadoEspecial, especial = true, porcento = 0.30f, acaoEsp = 1, armadura = true, forca = 9, atordoa = 60, lanca = 1, cancel = 99, seq = new[] {
                    Q(0, 5, ev: "zoom"), Q(1, 5), Q(2, 4, H(0, 58, -46, -2), ev: "onda_baixa"), Q(3, 5, H(0, 50, -58, -2)), Q(4, 5, H(0, 41, -42, -2)), Q(5, 8) } };
                break;
            case "queda":
                g = new Golpe { nome = "QUEDA CARMESIM", spr = j.especial2, especial = true, porcento = 0.40f, acaoEsp = 2, armadura = true, noAr = true, forca = 8, atordoa = 70, lanca = 4, cancel = 99, seq = new[] {
                    Q(0, 6, ev: "zoom"), Q(1, 5, ev: "salto_queda"), Q(2, 5), Q(3, 5), Q(4, 3, esp: "apice"), Q(5, 2, ev: "mergulho_queda", esp: "chao"),
                    Q(6, 9, ev: "impacto_queda"), Q(7, 24, ev: "faiscas") } };
                break;
            case "tremor":
                g = new Golpe { nome = "TREMOR DE VALLACK", spr = j.ataque03, especial = true, porcento = 0.35f, acaoEsp = 3, armadura = true, forca = 9, atordoa = 80, lanca = 5, cancel = 99, seq = new[] {
                    Q(0, 5, ev: "zoom"), Q(1, 7, ev: "carga"), Q(2, 7), Q(3, 7), Q(4, 11, ev: "carga_max"), Q(5, 3), Q(6, 8, ev: "impacto_tremor"), Q(7, 26) } };
                break;
            case "finalizador":
                g = new Golpe { nome = "FINALIZADOR", spr = j.ataque2, pesado = true, armadura = true, forca = 9, cancel = 99, seq = new[] {
                    Q(0, 4, ev: "fin_inicio"), Q(1, 4), Q(2, 5), Q(3, 5), Q(4, 4), Q(5, 4), Q(6, 9, ev: "brilho"), Q(7, 3, av: 2.0f),
                    Q(8, 12, ev: "fin_golpe"), Q(9, 7), Q(10, 6), Q(11, 6, ev: "fin_fim") } };
                break;
            case "ira":
                g = new Golpe { nome = "IRA DE VALLACK", spr = j.especial, armadura = true, forca = 12, atordoa = 90, lanca = 5, cancel = 99, seq = new[] {
                    Q(0, 30, ev: "ira_carga"), Q(1, 5), Q(2, 6, ev: "ira_golpe"), Q(3, 6), Q(4, 6), Q(5, 16) } };
                break;
        }
        if (g != null) g.chave = chave;
        return g;
    }

    // a cadeia guarda as 3 últimas letras: Q = QUADRADO, T = TRIÂNGULO (forte), C = BOLA
    public static string Proximo(string cadeia, string botao, bool noAr, bool agachado)
    {
        if (noAr) return botao == "Q" ? "corte_aereo" : (botao == "T" ? "mergulho" : "");
        if (agachado && botao == "Q") return "rasteira";
        int n = cadeia.Length;
        string ult = n >= 1 ? cadeia.Substring(n - 1) : "";
        string f2 = n >= 2 ? cadeia.Substring(n - 2) : "";
        string f3 = n >= 3 ? cadeia.Substring(n - 3) : "";
        if (f3 == "QQQ" && botao == "Q") return "frenetico";
        if (f2 == "QQ" && f3 != "QQQ")
        {
            if (botao == "Q") return "corte3";
            if (botao == "T" && Jogo.ComboLiberado(2)) return "quebra_escudo";
            if (botao == "C" && Jogo.ComboLiberado(3)) return "rasteira_sangrenta";
        }
        if (ult == "Q" && botao == "Q") return "corte2";
        if (botao == "Q") return "corte1";
        if (botao == "T") return "carrasco";
        if (botao == "C") return "rasteira";
        return "";
    }
}
