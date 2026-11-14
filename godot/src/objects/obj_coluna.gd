class_name ObjColuna
extends Lib
# obj_coluna — coluna de pedra ao fundo (v1.11). Origem embaixo no meio;
# a Escala Y é a altura em pedras de 32 px.

var linhas := 1
var tom := Color(1, 1, 1)
var quebrada := false


func ev_create() -> void:
	var m := cenario_medidas()
	linhas = m[1]
	image_speed = 0
	depth = 251
	tom = cenario_tom_fundo()
	quebrada = false


func ev_draw() -> void:
	coluna_desenhar(quebrada, tom, linhas)
