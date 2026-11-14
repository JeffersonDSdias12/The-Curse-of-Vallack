// =====================================================================
//  obj_dialogo — caixa de diálogo (v1.12)
//  Pausa o mundo (como os pergaminhos), mostra o retrato e o nome de quem
//  fala e escreve o texto letra por letra. ENTER / X (ou ataque) completa
//  o texto e passa para a próxima fala; ESC / BOLA pula o diálogo.
//  As falas ficam em dialogo_falas() (scr_v112). Abrir com dialogo_iniciar().
// =====================================================================
globais_iniciar();
falas = [];
i = 0;
letras = 0;
tempo = 0;
abre = 0;
fechando = false;
ao_fim = undefined;
foto = -1;
blip = 0;
pendente = true;        // o diálogo começa no Step dele (nunca no meio do código de outro objeto)

dialogo_comecar = function()
{
    if (surface_exists(application_surface))
        foto = sprite_create_from_surface(application_surface, 0, 0, surface_get_width(application_surface), surface_get_height(application_surface), false, false, 0, 0);
    mundo_pausar();
    io_clear();
    som("dialogo_abrir", 0.7, 0);
};

dialogo_fechar = function()
{
    if (foto != -1 and sprite_exists(foto)) sprite_delete(foto);
    foto = -1;
    mundo_retomar();
    io_clear();
    global.nav_ok = false;
    global.nav_voltar = false;
    global.bloqueio_input = 12;          // o botão que fechou não vira golpe nem pulo
    var _f = ao_fim;
    ao_fim = undefined;
    instance_destroy();
    if (!is_undefined(_f)) _f();
};
