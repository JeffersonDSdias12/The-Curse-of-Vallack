extends Lib
# Mato mágico (decoração). Cada tufo começa num quadro diferente e balança
# num ritmo próprio; fica atrás dos personagens.


func ev_create() -> void:
	image_index = randi_range(0, maxi(0, image_number - 1))
	image_speed = randf_range(0.7, 1.3)
	depth = 150
