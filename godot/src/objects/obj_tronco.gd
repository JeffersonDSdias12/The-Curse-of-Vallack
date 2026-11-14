extends Lib
# obj_tronco — tronco caído (decoração, v1.11)


func ev_create() -> void:
	image_speed = 0
	depth = 140


func ev_draw() -> void:
	if cenario_na_tela(x - 60, x + 60):
		draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, 0, c_white, 1)
