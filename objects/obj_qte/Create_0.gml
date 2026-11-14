// =====================================================================
//  obj_qte — SEQUÊNCIA DE GOLPES (v1.17, como no God of War)
//  O Carrasco exausto e a Árvore cambaleando só caem por aqui: perto deles,
//  o botão do FINALIZADOR (BOLA / K, ou AÇÃO no toque) abre a sequência.
//  Cada botão certo na hora certa vira um golpe de cinema; no último,
//  Twilight executa o chefe. Errou ou demorou: o chefe se solta, empurra
//  Twilight e volta a lutar (até cair de novo e a sequência reaparecer).
//  Criado por qte_iniciar(alvo) (scr_v117). O mesmo da versão Android.
// =====================================================================
alvo = noone;
seq = [];
i = 0;                    // botão atual
estado = "entrada";       // entrada -> botao -> golpe -> botao ... -> sucesso | falha
t = 0;                    // tempo no estado atual (quadros, tempo real)
tempo_botao = 80;         // janela de cada botão (qte_parametros)
perfeita = true;          // nenhum erro (conquista SEQUÊNCIA PERFEITA)
acerto_fx = 0;            // brilho dourado do botão acertado
errado = -1;              // botão errado (aparece riscado na falha)
qte_falhou_agora = false; // a falha é tratada uma vez no fim do Step
golpes = ["corte1", "corte2", "execucao", "corte2", "corte1", "execucao", "corte2", "corte1", "execucao", "corte2"];
