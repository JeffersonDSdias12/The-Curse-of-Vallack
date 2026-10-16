var _dt = global.dt_real;
tempo += _dt;
var _ok = input_confirmar_pergaminho() or mouse_check_button_pressed(mb_left) or keyboard_check_pressed(vk_space);

switch (fase)
{
    case "escurecer":
        if (tempo >= 110)
        {
            mundo_pausar();
            fase = "resultado";
            tempo = 0;
        }
    break;

    case "resultado":
        mostrar_t += _dt;
        pode_continuar = (mostrar_t > 40 + array_length(linhas) * 26);
        if ((_ok and pode_continuar) or mostrar_t > 900)
        {
            som("sfx_menu_ok", 0.8, 0);
            fase = "obrigado";
            tempo = 0;
        }
    break;

    case "obrigado":
        if (tempo >= 420 or (_ok and tempo > 120)) { fase = "sair"; tempo = 0; }
    break;

    case "sair":
        if (tempo >= 50)
        {
            var _l = instance_create_depth(0, 0, -11000, obj_loading);
            _l.modo = "menu";
            _l.destino = rm_menu;
            _l.fundo_preto = true;
            instance_destroy();
        }
    break;
}

// brasas subindo
if (fase != "escurecer" and global.cfg_qualidade > 0 and array_length(brasas) < 60 and random(1) < 0.6 * _dt)
{
    array_push(brasas, { x: random(display_get_gui_width()), y: GUI_ALTURA + 6, vy: random_range(-1.6, -0.5), vida: irandom_range(80, 220), vmax: 220 });
}
for (var _i = array_length(brasas) - 1; _i >= 0; _i--)
{
    var _b = brasas[_i];
    _b.y += _b.vy * _dt;
    _b.vida -= _dt;
    if (_b.vida <= 0) array_delete(brasas, _i, 1);
}
