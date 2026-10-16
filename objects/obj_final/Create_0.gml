// =====================================================================
//  obj_final — fim do jogo (Fase 2 sem nenhum inimigo)
//  tela escurece -> "CONTINUA..." (efeito amaldiçoado) -> carregamento ->
//  volta ao menu inicial.
// =====================================================================
globais_iniciar();
global.jogo_finalizado = true;
fase = "escurecer";
tempo = 0;
duracao_texto = 420;      // 7 s com o "CONTINUA..." na tela
brasas = [];
som("fase_concluida", 1, 0);       // som de passar de fase
