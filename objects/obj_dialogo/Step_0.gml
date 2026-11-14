var _dt = global.dt_real;
// começa no primeiro Step livre: espera um pergaminho, a pausa ou uma tela fechar
if (pendente)
{
    if (instance_exists(obj_pausa) or instance_exists(obj_save_menu) or instance_exists(obj_menu_armas)
        or instance_exists(obj_loading) or instance_exists(obj_game_over)) exit;
    pendente = false;
    dialogo_comecar();
    exit;
}
tempo += _dt;
if (fechando)
{
    abre = max(0, abre - 0.16 * _dt);
    if (abre <= 0) dialogo_fechar();
    exit;
}
abre = min(1, abre + 0.12 * _dt);
if (array_length(falas) == 0) { fechando = true; exit; }
var _f = falas[i];
var _n = string_length(_f.t);
// o texto aparece letra por letra (com um "bip" grave a cada 3 letras)
if (abre >= 1 and letras < _n)
{
    var _antes = floor(letras);
    letras = min(_n, letras + 1.1 * _dt);
    if (floor(letras) != _antes)
    {
        blip += 1;
        if (blip mod 3 == 0) som("dialogo_texto", 0.45, 0.06);
    }
}
var _ok = global.nav_ok or input_apertado(ACAO.ATACAR) or input_apertado(ACAO.INTERAGIR) or mouse_check_button_pressed(mb_left);
if (tempo > 10 and _ok)
{
    if (letras < _n) letras = _n;          // completa a fala
    else
    {
        i += 1;
        letras = 0;
        if (i >= array_length(falas))
        {
            i = array_length(falas) - 1;
            letras = string_length(falas[i].t);
            fechando = true;
        }
        else som("sfx_pagina", 0.35, 0.05);
    }
}
// ESC / BOLA pula o diálogo inteiro
if (tempo > 10 and global.nav_voltar) fechando = true;
