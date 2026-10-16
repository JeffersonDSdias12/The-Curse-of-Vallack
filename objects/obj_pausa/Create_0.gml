// =====================================================================
//  obj_pausa — menu de pausa e opções rápidas (ESC / SELECT)
//  * volume da música e dos efeitos
//  * efeito de abrir e fechar (a tela "desce" com um corte carmesim)
// =====================================================================
globais_iniciar();
tempo = 0;
abre = 0;                // 0..1 animação de abertura
fechando = false;
fechar_t = 0;
acao_ao_fechar = "";     // o que fazer quando a animação de fechar terminar
selecionado = 0;
mouse_antes_x = -1;
mouse_antes_y = -1;
confirmar = -1;          // opção que está pedindo confirmação
mudou_config = false;

opcoes = ["CONTINUAR", "VOLUME DA MÚSICA", "VOLUME DOS EFEITOS", "COMANDOS E COMBOS", "REINICIAR DO CHECKPOINT", "VOLTAR AO MENU", "SAIR DO JOGO"];
anim = array_create(array_length(opcoes), 0);
faiscas = [];

// "foto" do jogo para usar de fundo (apagada no Clean Up)
foto = -1;
if (surface_exists(application_surface))
{
    foto = sprite_create_from_surface(application_surface, 0, 0,
        surface_get_width(application_surface), surface_get_height(application_surface), false, false, 0, 0);
}

// congela o jogo inteiro (menos este objeto e o sistema)
mundo_pausar();
som("sfx_menu_abrir", 0.8, 0);

opcao_y = function(_i) { return GUI_ALTURA * 0.33 + _i * 56; };

// Fecha com a animação e depois executa a ação
fechar_com = function(_acao)
{
    if (fechando) return;
    fechando = true;
    fechar_t = 0;
    acao_ao_fechar = _acao;
    som("sfx_menu_fechar", 0.8, 0);
    if (mudou_config) { config_salvar(); mudou_config = false; }
};

continuar = function()
{
    mundo_retomar();
    io_clear();
    global.bloqueio_input = 10;     // o mesmo aperto não reabre a pausa nem ataca
    instance_destroy();
};

mudar_volume = function(_i, _passo)
{
    if (_i == PAUSA_MUSICA) global.cfg_vol_musica = clamp(round((global.cfg_vol_musica + _passo * 0.1) * 10) / 10, 0, 1);
    else
    {
        global.cfg_vol_efeitos = clamp(round((global.cfg_vol_efeitos + _passo * 0.1) * 10) / 10, 0, 1);
        som("atk_corte_1", 0.9);
    }
    mudou_config = true;
};
