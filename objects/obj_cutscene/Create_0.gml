// =====================================================================
//  obj_cutscene — PRÓLOGO: "O Herói e o Dragão"
//  Aparece só no NOVO JOGO, depois de escolher a dificuldade e antes do
//  carregamento da fase 1. X / ENTER (ou A / clique) passa as imagens;
//  ESC / BOLA pula o prólogo. No fim começa o carregamento da fase 1.
//  As imagens ficam em datafiles: cutscene_1.jpg, cutscene_2.jpg, ...
//  (para trocar ou acrescentar imagens, basta seguir a numeração).
// =====================================================================
audio_cena_definir("cutscene");      // os sons da tela inicial param aqui
musica("mus_prologo", 800);          // trilha própria do prólogo

imagens = [];
for (var _i = 1; _i <= 30; _i++)
{
    var _arq = "cutscene_" + string(_i) + ".jpg";
    if (!file_exists(_arq)) break;
    var _s = imagem_carregar(_arq);
    if (_s != -1) array_push(imagens, _s);
}

indice = 0;                  // imagem atual
tempo = 0;                   // tempo no estado atual (quadros de 60 FPS)
troca = 0;                   // 0..1 durante a passagem para a próxima imagem
fase = (array_length(imagens) > 0) ? "entrando" : "fim";   // entrando -> mostrando <-> trocando -> saindo -> fim
carregamento_criado = false;
io_clear();                  // o ENTER que escolheu a dificuldade não passa a 1ª imagem
