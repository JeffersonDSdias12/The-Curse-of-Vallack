var _dt = global.dt_real;
tempo += _dt;
var _gw = display_get_gui_width();
var _cartao = min(300, _gw * 0.23);
dica_tempo += _dt;
if (dica_tempo >= 180) { dica_tempo = 0; dica_atual = (dica_atual + 1) mod array_length(dicas); }

var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _click = mouse_check_button_pressed(mb_left);
var _mexeu = (mouse_antes_x != -1) and (_mx != mouse_antes_x or _my != mouse_antes_y);
mouse_antes_x = _mx;
mouse_antes_y = _my;

if (confirmado)
{
    if (tempo > 55) fechar();
    exit;
}

if (global.nav_voltar and tempo > 8)
{
    som("sfx_menu_fechar", 0.7, 0);
    fechar();
    exit;
}

var _sel_antes = selecionado;
if (global.nav_esq or global.nav_cima)  selecionado = (selecionado + 2) mod 3;
if (global.nav_dir or global.nav_baixo) selecionado = (selecionado + 1) mod 3;

var _confirm = global.nav_ok;
for (var _i = 0; _i < 3; _i++)
{
    var _cx = _gw * (_i + 1) / 4;
    // mesma área do cartão desenhado (antes o clique começava 30 px acima)
    if (point_in_rectangle(_mx, _my, _cx - _cartao / 2, 300, _cx + _cartao / 2, 500))
    {
        if (_mexeu) selecionado = _i;
        if (_click) { selecionado = _i; _confirm = true; }
    }
}

if (selecionado != _sel_antes) som("sfx_menu_mover", 0.5, 0);
if (_confirm and tempo > 8)
{
    if (modo == "salvar")
    {
        if (salvar_slot(selecionado + 1, true))
        {
            som("sfx_salvar", 0.9, 0);
            slots[selecionado] = slot_info(selecionado + 1);
            confirmado = true;
            tempo = 0;
        }
    }
    else if (carregar_slot(selecionado + 1))
    {
        som("sfx_menu_ok", 0.8, 0);
        var _l = instance_create_depth(0, 0, -11000, obj_loading);
        _l.modo = "carregar";
        _l.destino = global.checkpoint_room;
        instance_destroy();
        exit;
    }
}
