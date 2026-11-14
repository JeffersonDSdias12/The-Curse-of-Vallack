class_name ObjDestrutivel
extends Lib
# =====================================================================
#  obj_destrutivel — pai do cenário que quebra com golpes
#  (caixotes, paredes rachadas e lampiões). Os golpes do jogador procuram
#  por ele e chamam destrutivel_bater().
# =====================================================================

var vida := 2.0
var vida_max := 2.0
var quebrado := false
var tremor := 0.0
var flash := 0.0
var lado_golpe := 1.0
var solido = null


func pode_bater() -> bool:
	return true


func ao_bater(_forca: float) -> void:
	pass


func ao_quebrar(_lado: float) -> void:
	instance_destroy()


func ev_step() -> void:
	var dt := G.dt
	if tremor > 0:
		tremor = maxf(0, tremor - 0.6 * dt)
	if flash > 0:
		flash -= dt


func ev_cleanup() -> void:
	solido_remover(solido)


# _forca: 1 golpe normal, 2 golpe pesado / onda, 3 especial em área
func destrutivel_bater(forca: float, origem_x: float) -> void:
	if quebrado or vida <= 0:
		return
	if not pode_bater():
		return
	vida -= forca
	tremor = 6
	flash = 6
	lado_golpe = signf(x - origem_x)
	if lado_golpe == 0:
		lado_golpe = 1
	if vida <= 0:
		quebrado = true
		ao_quebrar(lado_golpe)
	else:
		ao_bater(forca)
