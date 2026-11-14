extends Lib
# obj_pedras — pedras e grama (decoração, v1.11). O desenho muda sozinho
# conforme a posição (grandes, médias ou pequenas).


func ev_create() -> void:
	image_speed = 0
	image_index = absi(int(round(x / 32.0))) % 3
	depth = 140


func ev_draw() -> void:
	if cenario_na_tela(x - 40, x + 40):
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, 1)
