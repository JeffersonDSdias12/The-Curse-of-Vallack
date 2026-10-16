// ===== END STEP =====
event_inherited();          // movimento + colisão (obj_entidade)

// BARREIRA DO GUARDIÃO: enquanto o boss da fase vive, não dá para seguir
var _boss = instance_find(obj_boss_01, 0);
if (_boss != noone and !_boss.morrendo and x > _boss.barreira_x - 14)
{
    x = _boss.barreira_x - 14;
    if (velh > 0) velh = 0;
    if (empurrao > 0) empurrao = 0;
    barreira_aviso = 90;
}
camera_atualizar(id);       // câmera depois do movimento: sem tremedeira/atraso

global.ultimo_x = x;
global.ultimo_y = y;
global.ultima_vida = vida;
