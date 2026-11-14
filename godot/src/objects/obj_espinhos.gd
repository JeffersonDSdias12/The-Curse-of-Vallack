extends Lib
# =====================================================================
#  obj_espinhos — espinhos que saem do chão em ciclos
#  baixo -> aviso (tremem e soltam poeira) -> alto (ferem) -> descendo
# =====================================================================

var estado := "baixo"
var t := 0.0
var sobe := 0.0
var atingidos: Array = []


func ev_create() -> void:
	sprite_index = Spr.spr_espinhos
	image_speed = 0
	t = fmod(x, 97)


func ev_step() -> void:
	var dt := G.dt
	t += dt
	match estado:
		"baixo":
			sobe = maxf(0, sobe - 0.2 * dt)
			if t >= 110:
				estado = "aviso"
				t = 0
		"aviso":
			sobe = 0.18 + 0.06 * sin(t * 1.3)
			if randf() < 0.25 * dt:
				fx_em("poeira", x + randf_range(-12, 12), y, 0.25)
			if t >= 38:
				estado = "alto"
				t = 0
				atingidos = []
				som_em("sfx_espinhos", x, y, 0.8)
		"alto":
			sobe = minf(1, sobe + 0.35 * dt)
			if sobe > 0.6:
				armadilha_area(x - 24, y - 22 * sobe, x + 24, y, 14, 30, atingidos, 3)
			if t >= 70:
				estado = "descendo"
				t = 0
		"descendo":
			sobe = maxf(0, sobe - 0.08 * dt)
			if sobe <= 0:
				estado = "baixo"
				t = 0


func ev_draw() -> void:
	var e := ESPINHOS_ESCALA
	draw_set_color(Color8(20, 14, 12))
	draw_set_alpha(0.85)
	draw_rectangle(x - 24, y - 2, x + 24, y + 1, false)
	draw_set_alpha(1)
	if estado == "aviso":
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.35 + 0.25 * sin(t * 0.8))
		draw_set_color(Color8(255, 80, 50))
		draw_rectangle(x - 24, y - 3, x + 24, y + 1, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	if sobe <= 0.01:
		return
	var h := sprite_index.h
	var vis := clampf(round(h * sobe), 1, h)
	draw_sprite_part_ext(sprite_index, 0, 0, 0, sprite_index.w, vis, x - sprite_index.xo * e, y - vis * e, e, e, c_white, 1)
	if estado == "alto" and sobe > 0.6:
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.2)
		draw_set_color(Color8(255, 60, 40))
		draw_rectangle(x - 24, y - vis * e, x + 24, y, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	if G.debug_hitbox:
		draw_set_color(c_red)
		draw_rectangle(x - 24, y - 22 * sobe, x + 24, y, true)
