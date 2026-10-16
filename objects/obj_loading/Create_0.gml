// =====================================================================
//  obj_loading — transições e telas de carregamento
//  modo:
//   "novo_jogo" / "carregar" / "transicao":
//       escurece -> troca de sala (congelada) -> título do capítulo ->
//       carregamento com dicas -> clareia e libera o jogo
//   "menu": carregamento com dicas -> volta ao menu inicial
//  Quem cria define "modo" e "destino" logo após instance_create.
// =====================================================================
persistent = true;
globais_iniciar();
audio_cena_definir("carregamento");  // sons do menu / da fase param; chuva e fogo ficam mudos
musica("mus_carregamento", 900);      // trilha das telas de carregamento

modo = "transicao";
destino = Room1;
fase = "inicio";          // inicio, escurecer, capitulo, carregando, clarear
tempo = 0;
progresso = 0;
congelou = false;
fundo_preto = false;      // true = a tela já está preta (ex.: vindo do final)

// ===== DICAS PASSANDO =====
dicas = dicas_tutorial();
dica_atual = irandom(array_length(dicas) - 1);
dica_tempo = 0;
dica_duracao = 170;       // ~2,8 s por dica
letreiro = "";
for (var _i = 0; _i < array_length(dicas); _i++) letreiro += dicas[_i] + "      ·      ";
letreiro_x = 0;

// duração do carregamento: tempo para várias dicas passarem
duracao_carregamento = 420;     // 7 s
duracao_capitulo = 220;         // ~3,7 s
