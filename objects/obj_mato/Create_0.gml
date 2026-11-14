// Mato mágico (decoração). Cada tufo começa num quadro diferente e balança
// num ritmo próprio; fica atrás dos personagens.
// v1.13: mistura dos matos do Eduardo (a mesma regra da versão Android):
// a maioria é mato verde escurecido pela noite; o mato corrompido vermelho e
// as plantas ficam mais raros (antes era só o vermelho, que poluía a frente)
var _h = abs(round(x) * 7 + round(y) * 13) mod 10;
if (_h < 6) { sprite_index = spr_mato_normal; image_blend = make_color_rgb(112, 120, 128); }
else if (_h == 8) { sprite_index = spr_planta; image_blend = make_color_rgb(120, 126, 134); }
else if (_h == 9) sprite_index = spr_planta_maldita;
image_index = irandom(max(0, image_number - 1));
image_speed = random_range(0.7, 1.3);
depth = 150;
