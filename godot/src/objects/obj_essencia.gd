extends Lib
# obj_essencia — cristal azul de ESSÊNCIA (v1.12): alimenta as sub-armas.
# Salta um pouco e depois voa sozinho até Twilight, como as orbs.

var vx := 0.0
var vy := -3.0
var espera := 22.0
var t := 0.0
var fase := 0.0


func ev_create() -> void:
	fase = randf() * 100


func ev_step() -> void:
	var dt := G.dt
	t += dt
	var p = instance_find("obj_player", 0)
	if t < espera or p == null or p.morto:
		vy += 0.25 * dt
		vx *= pow(0.97, dt)
		if place_meeting(x + vx * dt, y, "obj_chao"):
			vx = -vx * 0.5
		if vy > 0 and position_meeting(x, y + vy * dt + 6, "obj_chao"):
			vy = -absf(vy) * 0.45
			if absf(vy) < 0.8:
				vy = 0
		x += vx * dt
		y += vy * dt
		return
	var tx: float = p.x
	var ty: float = (p.bbox_top + p.bbox_bottom) / 2.0
	var v := minf(13, 3 + (t - espera) * 0.25)
	if point_distance(x, y, tx, ty) <= v * dt + 6:
		essencia_ganhar(1)
		som("essencia", 0.5, 0.04)
		instance_destroy()
		return
	var ang := point_direction(x, y, tx, ty)
	vx = lerpf(vx, lengthdir_x(v, ang), 0.2)
	vy = lerpf(vy, lengthdir_y(v, ang), 0.2)
	x += vx * dt
	y += vy * dt


func ev_draw() -> void:
	var b := 0.7 + 0.3 * sin(current_time() / 120.0 + fase)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.35 * b)
	draw_set_color(Color8(80, 160, 255))
	draw_circle(x, y, 9, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(Color8(60, 130, 255))
	draw_triangle(x, y - 7, x + 5, y, x - 5, y, false)
	draw_triangle(x - 5, y, x + 5, y, x, y + 7, false)
	draw_set_color(Color8(210, 235, 255))
	draw_triangle(x, y - 7, x + 2, y - 1, x - 2, y - 1, false)
	draw_set_color(c_white)
