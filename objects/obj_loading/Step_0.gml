var _dt = global.dt_real;
tempo += _dt;


switch (fase)
{
    case "inicio":
        global.transicao_fase = true;
        tempo = 0;
        // v1.17: sem o pergaminho do COMO JOGAR: as fases carregam em 30 s (título do
        // capítulo + barra) com dicas de combos passando embaixo; o menu, rápido
        tutorial = false;
        duracao_carregamento = (modo != "menu") ? 1800 - duracao_capitulo : 150;
        if (modo == "menu") fase = fundo_preto ? "carregando" : "escurecer";
        else fase = "escurecer";
    break;

    // escurece a tela atual
    case "escurecer":
        if (tempo >= 45)
        {
            tempo = 0;
            if (modo == "menu")
            {
                fase = "carregando";
                progresso = 0;
            }
            else
            {
                // congela a sala atual e troca para a fase de destino
                mundo_pausar();
                fase = "capitulo";
                congelou = false;
                room_goto(destino);
            }
        }
    break;

    // título do capítulo (a fase nova já existe, mas está congelada)
    case "capitulo":
        if (!congelou) { mundo_pausar(); congelou = true; }
        if (tempo >= duracao_capitulo)
        {
            tempo = 0;
            progresso = 0;
            fase = "carregando";
        }
    break;

    // carregamento (com o tutorial COMO JOGAR nas fases)
    case "carregando":
        if (modo != "menu" and !congelou) { mundo_pausar(); congelou = true; }
        // v1.19: garante as texturas na placa antes da fase começar (sem engasgos na luta)
        if (progresso == 0) { texture_prefetch("Default"); texture_prefetch("texturegroup1"); }
        progresso = min(100, progresso + (100 / duracao_carregamento) * _dt);
        dica_t += _dt;
        if (dica_t >= DICA_TEMPO and array_length(dicas) > 0) { dica_t = 0; dica_i = (dica_i + 1) mod array_length(dicas); }
        if (tutorial)
        {
            if (tutorial_abre <= 0) som_mensagem();     // v1.16: o pergaminho do COMO JOGAR se abre
            tutorial_abre = min(1, tutorial_abre + _dt / 26);
        }
        var _liberar = (progresso >= 100 and tempo >= duracao_carregamento + 25);
        if (tutorial and _liberar)
        {
            // espera o jogador ler: [X] / [ENTER] (ou clique) começa a fase
            pronto_t += _dt;
            _liberar = (pronto_t > 12) and (input_confirmar_pergaminho() or mouse_check_button_pressed(mb_left));
            if (_liberar) { som("sfx_pagina", 0.7, 0); io_clear(); global.bloqueio_input = 12; }
        }
        if (_liberar)
        {
            tempo = 0;
            fase = "clarear";
            if (modo == "menu")
            {
                partida_resetar();
                room_goto(rm_menu);
            }
            else
            {
                mundo_retomar();
                global.cam_snap = true;
                audio_cena_definir("fase");      // a fase começa: sons da fase, chuva e fogo
                musica(musica_fase(), 1500);     // a tela clareia: começa a trilha da fase (fase 1: bgm_battle_phase1)
                // ao chegar na fase 2, o progresso é salvo no slot da partida
                if (modo == "transicao") salvar_slot(global.save_slot_atual, false);
                else if (modo == "novo_jogo") salvar_slot(global.save_slot_atual, false);
            }
        }
    break;

    // revela o jogo / o menu
    case "clarear":
        if (tempo >= 40)
        {
            global.transicao_fase = false;
            persistent = false;
            instance_destroy();
        }
    break;
}
