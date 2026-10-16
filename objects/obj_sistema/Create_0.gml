// =====================================================================
//  obj_sistema — controlador único e persistente do jogo
//  * configurações, fontes e sistema de vídeo (resolução / proporção / tela cheia)
//  * leitura de controles (teclado, controle e analógico) 1x por quadro
//  * desenha a imagem do jogo ocupando a janela inteira (Post Draw)
//  É criado automaticamente pelo obj_menu (ou pelo obj_player, ao testar
//  uma fase direto) e nunca é congelado pelas pausas.
// =====================================================================
persistent = true;

globais_iniciar();
config_carregar();
fontes_carregar();
audio_iniciar();
randomize();

window_set_caption(JOGO_TITULO + " - " + JOGO_SUBTITULO);

// O próprio sistema desenha a application surface esticada na janela inteira
// (Post Draw). Assim nunca sobram barras ou cantos sem imagem.
application_surface_draw_enable(false);

global.dt = clamp(60 / max(1, game_get_speed(gamespeed_fps)), 0.5, 3);
tela_atualizar();
sala_preparar();
