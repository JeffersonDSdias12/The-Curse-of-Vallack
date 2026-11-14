extends Lib
# =====================================================================
#  obj_raiz — raiz da Árvore Amaldiçoada que rompe o chão
#  aviso (coluna de luz roxa + "!" + som) -> sobe (fere) -> desce
# =====================================================================

var dano := 14.0
var atraso := 0.0
var t := 0.0
var estado := "aviso"
var sobe := 0.0
var atingidos: Array = []
var semente := 0.0
var aviso_t := 50.0
var alt := 96.0
var meia := 18.0
var som_tocou := false


func ev_create() -> void:
	semente = randf() * 100


func ev_step() -> void:
	var dt := G.dt
	if atraso > 0:
		atraso -= dt
		return
	if not som_tocou:
		som_tocou = true
		som_em("raiz_aviso", x, y, 0.8)
	t += dt
	match estado:
		"aviso":
			if randf() < 0.4 * dt:
				fx_em("poeira", x + randf_range(-16, 16), y, 0.35)
			if t >= aviso_t:
				estado = "sobe"
				t = 0
				som_em("dest_pedra", x, y, 0.7)
				G.camera_impact = maxf(G.camera_impact, 6)
				fx_em("lascas", x, y - 6, 0.9)
		"sobe":
			sobe = minf(1, sobe + 0.25 * dt)
			if sobe > 0.5:
				armadilha_area(x - meia, y - alt * sobe, x + meia, y, dano / maxf(0.1, dif_dano_inimigo()), 0, atingidos, 5)
			if t >= 46:
				estado = "desce"
				t = 0
		"desce":
			sobe = maxf(0, sobe - 0.05 * dt)
			if sobe <= 0:
				instance_destroy()


func ev_draw() -> void:
	if atraso > 0:
		return
	var tt := current_time() / 16.0
	if estado == "aviso":
		var k := clampf(t / aviso_t, 0, 1)
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.12 + 0.25 * k)
		draw_set_color(Color8(150, 40, 255))
		draw_rectangle(x - meia * (0.5 + 0.5 * k), y - alt * 1.3, x + meia * (0.5 + 0.5 * k), y, false)
		draw_set_alpha(0.4 + 0.5 * k)
		draw_set_color(Color8(200, 90, 255))
		draw_ellipse(x - 22 * k - 6, y - 4, x + 22 * k + 6, y + 3, false)
		draw_line_width(x - 20, y - 1, x + 20, y, 2)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
		var pa := 0.6 + 0.4 * sin(tt * 0.6)
		gpu_set_texfilter(true)
		txt_sombra(x, y - alt * 1.3 - 4, "!", FONTE.GRANDE, Color8(230, 120, 255), pa, fa_center, fa_bottom, 0.7 + 0.2 * k)
		gpu_set_texfilter(false)
		return
	var h := alt * sobe
	var seg := 9
	for i in seg:
		var a1 := float(i) / seg
		var a2 := float(i + 1) / seg
		var ox1 := sin(a1 * 5 + semente) * 7 * a1
		var ox2 := sin(a2 * 5 + semente) * 7 * a2
		var w1 := meia * (1 - a1 * 0.85)
		var w2 := meia * (1 - a2 * 0.85)
		var y1 := y - h * a1
		var y2 := y - h * a2
		draw_set_color(Color8(58, 34, 24))
		draw_triangle(x + ox1 - w1, y1, x + ox1 + w1, y1, x + ox2 + w2, y2, false)
		draw_triangle(x + ox1 - w1, y1, x + ox2 - w2, y2, x + ox2 + w2, y2, false)
		draw_set_color(Color8(110, 66, 40))
		draw_line(x + ox1 - w1 * 0.4, y1, x + ox2 - w2 * 0.4, y2)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.35 * sobe)
	draw_set_color(Color8(150, 40, 255))
	draw_rectangle(x - meia - 2, y - h, x + meia + 2, y, true)
	draw_set_alpha(0.7 * sobe)
	draw_set_color(Color8(200, 90, 255))
	draw_circle(x + sin(5 + semente) * 7, y - h, 5 + sin(tt / 4.0), false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
