var _dt = global.dt_real;
tempo += _dt;

if (fechando)
{
    fechar_t += _dt;
    abre = max(0, 1 - fechar_t / 14);
    if (fechar_t >= 14) fechar();
    exit;
}
abre = min(1, abre + _dt / 22);

// espera um instante antes de aceitar o botão (não fecha sem querer)
if (tempo < 26) exit;

var _n = array_length(paginas);
if (modo_livro)
{
    if (global.nav_esq and pagina > 0)        { pagina -= 1; abre = 0.55; som("sfx_pagina", 0.7, 0.05); }
    if (global.nav_dir and pagina < _n - 1)   { pagina += 1; abre = 0.55; som("sfx_pagina", 0.7, 0.05); }
    if (keyboard_check_pressed(vk_escape) or (global.pad_slot >= 0 and gamepad_button_check_pressed(global.pad_slot, gp_face2)))
    {
        fechando = true;
        som("sfx_menu_fechar", 0.6, 0);
        exit;
    }
}

// ENTER ou X: próxima página / fecha
if (input_confirmar_pergaminho())
{
    if (pagina < _n - 1) { pagina += 1; abre = 0.55; som("sfx_pagina", 0.7, 0.05); }
    else { fechando = true; som("sfx_menu_fechar", 0.6, 0); }
}
