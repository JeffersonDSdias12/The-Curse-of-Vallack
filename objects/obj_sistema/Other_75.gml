// ===== ASSÍNCRONO - SISTEMA: controle conectado / desconectado =====
var _ev = async_load[? "event_type"];
if (is_undefined(_ev)) exit;

if (_ev == "gamepad discovered")
{
    var _pad = async_load[? "pad_index"];
    if (!is_undefined(_pad))
    {
        // escolhe de novo o controle (e lê nome e número de botões)
        global.pad_slot = -1;
        gamepad_escolher();
        var _d = gamepad_get_description(_pad);
        if (_d == "") _d = "CONTROLE " + string(_pad + 1);
        var _b = gamepad_button_count(_pad);
        aviso_mostrar("CONTROLE CONECTADO  ·  " + string_upper(_d) + ((_b <= 0) ? "  ·  SEM BOTÕES RECONHECIDOS" : ""));
    }
}
else if (_ev == "gamepad lost")
{
    var _pad2 = async_load[? "pad_index"];
    if (!is_undefined(_pad2) and _pad2 == global.pad_slot)
    {
        global.pad_slot = -1;
        global.usando_pad = false;
        gamepad_escolher();
        aviso_mostrar("CONTROLE DESCONECTADO");
        // no meio da fase, o jogo pausa sozinho
        if (room != rm_menu and instance_exists(obj_player) and !instance_exists(obj_pausa) and !instance_exists(obj_save_menu)
            and !instance_exists(obj_loading) and !instance_exists(obj_pergaminho) and !instance_exists(obj_game_over) and !instance_exists(obj_final))
        {
            var _p = instance_find(obj_player, 0);
            if (_p != noone and !_p.morto) instance_create_depth(0, 0, -10000, obj_pausa);
        }
    }
}
