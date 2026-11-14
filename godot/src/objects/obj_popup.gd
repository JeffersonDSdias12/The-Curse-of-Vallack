extends Lib
# obj_popup — texto curto que sobe e some (CRÍTICO, CONTRA-ATAQUE). v1.12

var texto := ""
var cor := Color(1, 1, 1)
var escala := 1.0
var vida := 50.0
var vy := -1.4


func ev_step() -> void:
	vida -= G.dt_real
	y += vy * G.dt_real
	vy *= pow(0.95, G.dt_real)
	if vida <= 0:
		instance_destroy()


func ev_draw() -> void:
	var a := clampf(vida / 15.0, 0, 1)
	var s := escala * (1 + 0.35 * clampf((vida - 40) / 10.0, 0, 1))
	gpu_set_texfilter(true)
	txt_sombra(x, y, texto, FONTE.MEDIA, cor, a, fa_center, fa_bottom, 0.5 * s)
	gpu_set_texfilter(false)
	desenho_resetar()
