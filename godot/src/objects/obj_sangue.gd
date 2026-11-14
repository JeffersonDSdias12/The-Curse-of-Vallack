extends Lib
# obj_sangue — sangue de um inimigo derrotado voando para a lâmina (v1.12).
# Ao chegar na espada, enche um pouco a barra de FÚRIA.

var valor := 1.0
var vx := 0.0
var vy := -2.0
var t := 0.0
var espera := 10.0


func ev_create() -> void:
	espera = 10 + randf() * 8


func ev_step() -> void:
	var dt := G.dt
	t += dt
	var p = instance_find("obj_player", 0)
	if p == null or p.morto or p.furia_modo:
		instance_destroy()
		return
	if t < espera:
		vy += 0.18 * dt
		vx *= pow(0.95, dt)
		x += vx * dt
		y += vy * dt
		return
	var tx: float = p.x + p.facing * 20
	var ty: float = p.y - 44
	var v := minf(12, 2 + (t - espera) * 0.3)
	if point_distance(x, y, tx, ty) <= v * dt + 5:
		p.furia_ganhar(valor)
		if G.orb_som_t <= 0:
			som("sangue_lamina", 0.25, 0.1)
			G.orb_som_t = 4
		instance_destroy()
		return
	var ang := point_direction(x, y, tx, ty)
	vx = lerpf(vx, lengthdir_x(v, ang), 0.25)
	vy = lerpf(vy, lengthdir_y(v, ang), 0.25)
	x += vx * dt
	y += vy * dt


func ev_draw() -> void:
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.3)
	draw_set_color(Color8(255, 40, 30))
	draw_circle(x, y, 5, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(Color8(170, 10, 15))
	draw_circle(x, y, 2.4, false)
	draw_line_width(x, y, x - vx * 2, y - vy * 2, 2)
	draw_set_color(c_white)
