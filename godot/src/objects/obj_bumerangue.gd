extends Lib
# =====================================================================
#  obj_bumerangue — LÂMINA BUMERANGUE (sub-arma, v1.12, 1 essência)
#  Gira para a frente, freia, volta para Twilight e acerta cada inimigo
#  uma vez na ida e uma na volta. Também quebra caixotes.
# =====================================================================

var dir := 1.0
var dono = null
var vel := 10.5
var fase := "ida"
var t := 0.0
var ang := 0.0
var dano := 12.0
var atingidos: Array = []


func ev_step() -> void:
	var dt := G.dt
	t += dt
	ang -= dir * 26 * dt
	if fase == "ida":
		x += dir * vel * dt
		vel -= 0.42 * dt
		if vel <= 0 or place_meeting(x + dir * 10, y, "obj_chao") or x < 0 or x > G.room_width:
			fase = "volta"
			atingidos = []
			vel = 2
	else:
		if not G.existe(dono):
			instance_destroy()
			return
		var tx: float = dono.x
		var ty: float = dono.y - 40
		vel = minf(12, vel + 0.5 * dt)
		var a := point_direction(x, y, tx, ty)
		x += lengthdir_x(vel * dt, a)
		y += lengthdir_y(vel * dt, a)
		if point_distance(x, y, tx, ty) < vel * dt + 14:
			instance_destroy()
			return
	if t > 240:
		instance_destroy()
		return
	var g := {"chave": "bumerangue", "especial": false, "pesado": false, "porcento": 0, "dano": dano, "combo": 0, "no_ar": false}
	for alvo in collision_rectangle_list(x - 16, y - 14, x + 16, y + 14, "obj_inimigo_base"):
		if atingidos.has(alvo) or alvo.morrendo or not alvo.ativo:
			continue
		atingidos.append(alvo)
		var d := maxf(1, round(dano * espada_dano_mult()))
		alvo.levar_dano(d, x, true, 1.5, null, g)
		if not alvo.morrendo and not alvo.eh_boss:
			alvo.inimigo_atordoar(20)
		fx_em("faiscas_golpe", alvo.x, (alvo.bbox_top + alvo.bbox_bottom) / 2.0, 0.7, dir)
		som_var("hit", 3, 0.6)
		impacto(1)
	for de in collision_rectangle_list(x - 16, y - 14, x + 16, y + 14, "obj_destrutivel"):
		if atingidos.has(de):
			continue
		atingidos.append(de)
		de.destrutivel_bater(1, x)


func ev_draw() -> void:
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.3)
	draw_set_color(Color8(255, 210, 120))
	draw_circle(x, y, 18, false)
	draw_set_alpha(0.55)
	draw_circle(x, y, 8, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	var c := dcos(ang)
	var s := -dsin(ang)
	var tx := x + c * 20
	var ty := y + s * 20
	var hx := x - c * 8
	var hy := y - s * 8
	var nx := -s * 3
	var ny := c * 3
	draw_set_color(Color8(225, 230, 240))
	draw_triangle(x + nx, y + ny, x - nx, y - ny, tx, ty, false)
	draw_set_color(Color8(150, 160, 175))
	draw_line(x, y, tx, ty)
	draw_set_color(Color8(205, 165, 60))
	draw_line_width(x - nx * 1.7, y - ny * 1.7, x + nx * 1.7, y + ny * 1.7, 2)
	draw_line_width(x, y, hx, hy, 2.5)
	draw_set_alpha(0.25)
	draw_set_color(Color8(255, 230, 160))
	draw_circle(x, y, 20, true)
	draw_set_alpha(1)
	draw_set_color(c_white)
