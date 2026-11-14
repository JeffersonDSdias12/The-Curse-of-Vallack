// =====================================================================
//  obj_resultado — FIM DA DEMO (depois de vencer o boss e seguir em frente)
//  escurecer -> RESULTADO (tempo, inimigos, orbs...) -> "Obrigado por
//  jogar nossa Demo." -> CRÉDITOS (nomes da equipe) -> carregamento -> menu inicial
// =====================================================================
globais_iniciar();
global.jogo_finalizado = true;
fase = "escurecer";
tempo = 0;
brasas = [];
var _taxa = global.attacks_total > 0 ? min(100, global.hits_total / global.attacks_total * 100) : 0;
linhas = [
    { nome: "TEMPO DE JOGO",       valor: global.tempo_jogo,          tipo: "tempo" },
    { nome: "INIMIGOS DERROTADOS", valor: global.inimigos_derrotados, tipo: "num" },
    { nome: "ORBS COLETADAS",      valor: global.orbs_coletados,      tipo: "num" },
    { nome: "NÍVEL DA ESPADA",     valor: global.espada_nivel,        tipo: "nivel" },
    { nome: "TAXA DE ACERTO",      valor: _taxa,                      tipo: "pct" },
    { nome: "DIFICULDADE",         valor: 0,                          tipo: "dif" }
];
mostrar_t = 0;
pode_continuar = false;
som("fase_concluida", 1, 0);         // som de passar de fase
// v1.17: CONQUISTAS do fim da fase 1
perfil_somar("fases");
conquista("fase1");
if (global.dificuldade >= DIF.DIFICIL) conquista("dificil");
if (global.dificuldade >= DIF.EXTREMO) conquista("extremo");
if (global.tempo_jogo < 15 * 60) conquista("veloz");
perfil_salvar();
musica("bgm_main_menu", 3000);       // v1.16: o tema principal fecha a demo (resultado e créditos)
