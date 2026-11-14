class_name ObjMuralhaFundo
extends Lib
# =====================================================================
#  obj_muralha_fundo — muralha do castelo AO FUNDO, sem colisão (v1.11)
#  Com 3 ou mais pedras de altura ganha ameias; torres estreitas e altas
#  ganham seteiras acesas. Com 1 ou 2 pedras vira uma mureta.
# =====================================================================

var colunas := 1
var linhas := 1
var semente := 0
var tom := Color(1, 1, 1)
var tipo := "fundo"


func ev_create() -> void:
	var m := cenario_medidas()
	colunas = m[0]
	linhas = m[1]
	semente = m[2]
	image_speed = 0
	depth = 252
	tom = cenario_tom_fundo()
	tipo = "fundo"


func ev_draw() -> void:
	muralha_desenhar(tipo, tom, colunas, linhas, semente)
