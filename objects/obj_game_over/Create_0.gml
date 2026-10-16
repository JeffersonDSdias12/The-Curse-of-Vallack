// =====================================================================
//  obj_game_over — tela de derrota
// =====================================================================
globais_iniciar();
tempo = 0;
alpha = 0;
selecionado = 0;
mouse_antes_x = -1;
mouse_antes_y = -1;
opcoes = ["TENTAR NOVAMENTE", "VOLTAR AO MENU"];
anim = [0, 0];
botao_y = function(_i) { return GUI_ALTURA / 2 + 70 + _i * 62; };
