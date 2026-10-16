if (ativacao_fx > 0) ativacao_fx -= global.dt;
if (!ativado and instance_exists(obj_player))
{
    var _entrou = collision_rectangle(x - 40, y - 90, x + 40, y + 30, obj_player, false, true);
    if (_entrou != noone and !_entrou.morto)
    {
        ativado = true;
        ativacao_fx = 45;
        global.checkpoint_ativo = true;
        global.checkpoint_room = room;
        global.checkpoint_x = _entrou.x;
        global.checkpoint_y = _entrou.y;
        salvar_slot(global.save_slot_atual, false);
        progresso_marcar();
        aviso_mostrar("CHECKPOINT SALVO AUTOMATICAMENTE");
        global.camera_impact = max(global.camera_impact, 4);
    }
}
