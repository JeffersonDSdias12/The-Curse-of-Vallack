var _dt = global.dt_real;
tempo += _dt;
alpha = min(1, tempo / 60);     // a tela escurece em 1 segundo
var _cx = display_get_gui_width() / 2;
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _mexeu = (mouse_antes_x != -1) and (_mx != mouse_antes_x or _my != mouse_antes_y);
mouse_antes_x = _mx;
mouse_antes_y = _my;

if (tempo - _dt < 2 and tempo >= 2) som("sfx_derrota", 0.9, 0);      // som da derrota
if (tempo < 40) exit;           // evita clicar sem querer

if (global.nav_cima or global.nav_baixo) { selecionado = 1 - selecionado; som("sfx_menu_mover", 0.5, 0); }
var _ok = global.nav_ok;
for (var _i = 0; _i < 2; _i++)
{
    var _by = botao_y(_i);
    if (point_in_rectangle(_mx, _my, _cx - 190, _by - 24, _cx + 190, _by + 24))
    {
        if (_mexeu) selecionado = _i;
        if (mouse_check_button_pressed(mb_left)) { selecionado = _i; _ok = true; }
    }
}
for (var _a = 0; _a < 2; _a++) anim[_a] = lerp_dt(anim[_a], (_a == selecionado) ? 1 : 0, 0.2);

if (_ok and !instance_exists(obj_loading))
{
    som("sfx_menu_ok", 0.8, 0);
    if (selecionado == 0)
    {
        // recomeça do último checkpoint (ou do início da fase);
        // orbs e contadores voltam ao que eram no checkpoint
        progresso_reverter();
        room_restart();
    }
    else
    {
        var _l = instance_create_depth(0, 0, -11000, obj_loading);
        _l.modo = "menu";
        _l.destino = rm_menu;
    }
}
