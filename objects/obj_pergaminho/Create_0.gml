// =====================================================================
//  obj_pergaminho — tutorial em pergaminho (como no God of War)
//  * no jogo: pausa tudo e só fecha com ENTER ou X (cruz do controle)
//  * modo livro (pausa > COMANDOS): « » trocam de página, ESC fecha
// =====================================================================
globais_iniciar();
paginas = [TUT.INICIO];
pagina = 0;
tempo = 0;
abre = 0;
fechando = false;
fechar_t = 0;
modo_livro = false;
veio_da_pausa = false;
foto_externa = -1;          // a pausa empresta a "foto" dela

// "foto" do jogo para o fundo (o mundo fica congelado enquanto lê)
foto = -1;
if (surface_exists(application_surface))
{
    foto = sprite_create_from_surface(application_surface, 0, 0,
        surface_get_width(application_surface), surface_get_height(application_surface), false, false, 0, 0);
}
mundo_pausar();
io_clear();

fechar = function()
{
    if (foto != -1 and sprite_exists(foto)) sprite_delete(foto);
    foto = -1;
    // aberto pela pausa: o mundo continua parado e a pausa volta
    if (veio_da_pausa) instance_activate_object(obj_pausa);
    else mundo_retomar();
    io_clear();
    global.nav_ok = false;
    global.nav_voltar = false;
    global.bloqueio_input = 12;     // o X que fechou o pergaminho não vira pulo
    instance_destroy();
};
som("sfx_pagina", 0.8, 0);       // o pergaminho abre
