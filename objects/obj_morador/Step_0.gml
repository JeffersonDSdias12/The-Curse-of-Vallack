var _dt = global.dt;
var _p = instance_find(obj_player, 0);
switch (estado)
{
    case "parado":
        if (_p != noone) dir = (_p.x < x) ? -1 : 1;
        if (_p != noone and !_p.morto and abs(_p.x - x) < 120 and abs(_p.y - y) < 90
            and !instance_exists(obj_dialogo) and !instance_exists(obj_pausa)
            and !instance_exists(obj_loading) and !instance_exists(obj_save_menu))
        {
            estado = "conversando";
            var _d = dialogo_iniciar("morador", function()
            {
                with (obj_morador)
                {
                    estado = "fugindo";
                    sprite_index = spr_morador_correndo;
                    image_index = 0;
                    aberto_marcar(chave);
                }
            });
            if (_d == noone) estado = "parado";
        }
    break;
    case "fugindo":
        dir = -1;
        x -= 3.4 * _dt;
        if (x < -40 or (view_camera[0] != -1 and x < camera_get_view_x(view_camera[0]) - 60)) instance_destroy();
    break;
}
