var _dt = global.dt_real;
tempo += _dt;

// ----- dicas -----
dica_tempo += _dt;
if (dica_tempo >= dica_duracao)
{
    dica_tempo = 0;
    dica_atual = (dica_atual + 1) mod array_length(dicas);
}
letreiro_x -= 1.3 * _dt;

switch (fase)
{
    case "inicio":
        global.transicao_fase = true;
        tempo = 0;
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

    // carregamento com dicas
    case "carregando":
        if (modo != "menu" and !congelou) { mundo_pausar(); congelou = true; }
        progresso = min(100, progresso + (100 / duracao_carregamento) * _dt);
        if (progresso >= 100 and tempo >= duracao_carregamento + 25)
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
                musica("mus_fase", 1800);        // a tela clareia: começa a trilha da fase
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
