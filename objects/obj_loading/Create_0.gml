// =====================================================================
//  obj_loading — transições e telas de carregamento
//  modo:
//   "novo_jogo" / "carregar" / "transicao":
//       escurece -> troca de sala (congelada) -> título do capítulo ->
//       carregamento com o tutorial COMO JOGAR -> clareia e libera o jogo
//   "menu": carregamento -> volta ao menu inicial
//  v1.13: o COMO JOGAR é o único tutorial do jogo. Ele aparece só aqui,
//  no carregamento das fases, e espera o jogador apertar para começar.
//  Quem cria define "modo" e "destino" logo após instance_create.
// =====================================================================
persistent = true;
globais_iniciar();
audio_cena_definir("carregamento");  // sons do menu / da fase param; chuva e fogo ficam mudos
musica("bgm_loading_screen", 1500);   // v1.16: a trilha do menu/fase sai (fade) e entra a do carregamento

modo = "transicao";
destino = Room1;
fase = "inicio";          // inicio, escurecer, capitulo, carregando, clarear
tempo = 0;
progresso = 0;
congelou = false;
fundo_preto = false;      // true = a tela já está preta (ex.: vindo do final)

// ===== TUTORIAL "COMO JOGAR" (só no carregamento das fases) =====
tutorial = false;         // decidido no primeiro Step (o "modo" chega depois do Create)
tutorial_abre = 0;        // o pergaminho desenrola
pronto_t = 0;             // tempo desde que o carregamento terminou

duracao_carregamento = 240;     // 4 s (sem o tutorial: 2,5 s)
duracao_capitulo = 220;         // ~3,7 s

// ===== v1.17: CARREGAMENTO DAS FASES EM 30 s, com DICAS de combos e ataques =====
// (o título do capítulo + a barra somam 30 s; as dicas passam embaixo, uma de
// cada vez, deslizando; ao fundo, a foto do cenário da fase)
dicas = dicas_carregamento();
dica_i = irandom(array_length(dicas) - 1);
dica_t = 0;
DICA_TEMPO = 300;               // 5 s por dica
if (!variable_global_exists("img_mapa") or !sprite_exists(global.img_mapa)) global.img_mapa = imagem_carregar("mapa_fases.jpg");
