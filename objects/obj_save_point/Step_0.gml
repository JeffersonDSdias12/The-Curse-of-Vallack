// A tecla INTERAGIR é tratada pelo jogador (abre a tela de salvar e, perto do
// cristal, recupera a vida).
var _p = instance_find(obj_player, 0);
perto = (_p != noone) and point_distance(x, y, _p.x, _p.y) < 70;
if (marcado_fx > 0) marcado_fx -= global.dt;

// primeira vez perto: este cristal vira o checkpoint (ao morrer, Twilight volta aqui)
if (!marcado and _p != noone and !_p.morto and abs(_p.x - x) < 90 and abs(_p.y - y) < 120 and !global.transicao_fase)
{
    marcado = true;
    marcado_fx = 45;
    var _novo = !(global.checkpoint_ativo and global.checkpoint_room == room and abs(global.checkpoint_x - _p.x) < 120);
    salvar_slot(global.save_slot_atual, false);
    if (_novo) aviso_mostrar("CHECKPOINT  ·  JOGO SALVO AUTOMATICAMENTE");
}
