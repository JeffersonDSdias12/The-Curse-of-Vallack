// =====================================================================
//  obj_resultado — FIM DA DEMO (depois de vencer o boss e seguir em frente)
//  escurecer -> RESULTADO (tempo, inimigos, orbs...) -> "Obrigado por
//  jogar nossa Demo." -> carregamento -> menu inicial
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
musica("mus_fase", 3000);
