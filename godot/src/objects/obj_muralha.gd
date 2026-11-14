extends Lib
# =====================================================================
#  obj_muralha — muralha de pedra SÓLIDA (v1.11)
#  Origem embaixo à esquerda. Escala X = largura em pedras de 32 px;
#  Escala Y = altura em pedras. Jogador e inimigos sobem e andam em cima.
# =====================================================================

var colunas := 1
var linhas := 1
var semente := 0
var tom := Color(1, 1, 1)
var solido = null


func ev_create() -> void:
	var m := cenario_medidas()
	colunas = m[0]
	linhas = m[1]
	semente = m[2]
	image_speed = 0
	depth = 155
	tom = c_white
	solido = solido_criar(x, y - 32 * linhas + 3, x + 32 * colunas, y)


func ev_cleanup() -> void:
	solido_remover(solido)


func ev_draw() -> void:
	muralha_desenhar("solida", tom, colunas, linhas, semente)
