extends Lib
# obj_balaustrada — balaustrada de pedra (decoração ao fundo, v1.11).
# Origem embaixo à esquerda; repete na horizontal pela Escala X.

var tom := Color(1, 1, 1)
var colunas := 1


func ev_create() -> void:
	image_speed = 0
	depth = 251
	tom = cenario_tom_fundo()
	colunas = maxi(1, int(round(absf(image_xscale))))


func ev_draw() -> void:
	if not cenario_na_tela(x, x + 32 * colunas):
		return
	for i in colunas:
		draw_sprite_ext(sprite_index, 0, x + 32 * i, y, 1, 1, 0, tom, 1)
