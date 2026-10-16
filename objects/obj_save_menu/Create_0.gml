// =====================================================================
//  obj_save_menu — escolher um dos 3 slots para salvar
//  (aberto pela tecla SALVAR ou pela pausa)
// =====================================================================
globais_iniciar();
selecionado = clamp(global.save_slot_atual - 1, 0, 2);
tempo = 0;
confirmado = false;
modo = "salvar";
mouse_antes_x = -1;
mouse_antes_y = -1;
dicas = dicas_tutorial();
dica_atual = irandom(array_length(dicas) - 1);
dica_tempo = 0;
slots = [slot_info(1), slot_info(2), slot_info(3)];

// Se veio do menu de pausa, a pausa volta quando este menu fechar.
vindo_da_pausa = instance_exists(obj_pausa);
mundo_pausar();

fechar = function()
{
    if (vindo_da_pausa)
    {
        instance_activate_object(obj_pausa);
        with (obj_pausa) tempo = 0;     // a pausa ignora o mesmo aperto que fechou este menu
    }
    else mundo_retomar();
    io_clear();
    global.nav_ok = false;
    global.nav_voltar = false;
    global.bloqueio_input = 10;
    instance_destroy();
};
