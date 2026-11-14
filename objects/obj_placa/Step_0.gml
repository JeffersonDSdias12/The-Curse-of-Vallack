var _p = instance_find(obj_player, 0);
var _perto = (_p != noone and abs(_p.x - x) < 90 and abs(_p.y - y) < 140);
// v1.14: com a dica do cristal de salvar na tela, o aviso da placa dá lugar a ela
var _sp = instance_nearest(x, y, obj_save_point);
if (_sp != noone and _sp.perto) _perto = false;
mostrar = clamp(mostrar + (_perto ? 0.08 : -0.06) * global.dt, 0, 1);
// v1.14: com Twilight embaixo do pergaminho (subindo a escada ao lado da placa),
// o aviso sobe acima da cabeça dele em vez de cobri-lo
var _alvo = y - 66;
if (_perto and _p.bbox_bottom > _alvo - 34 and _p.bbox_top - 6 < _alvo) _alvo = _p.bbox_top - 14;
aviso_base = lerp_dt(aviso_base, _alvo, 0.25);
