extends Lib
# obj_fala — balão de fala de um inimigo / boss (criado por fala_dizer)

var alvo = null
var texto := ""
var cor := Color(1, 1, 1)
var vida := 110.0
var vida_max := 110.0
var t := 0.0
var ax := 0.0
var ay := 0.0


func ev_create() -> void:
	ax = x
	ay = y


func ev_step() -> void:
	var dt := G.dt_real
	t += dt
	vida -= dt
	if G.existe(alvo):
		ax = alvo.x
		ay = alvo.bbox_top
		# o balão também serve ao jogador (fala de batalha), que não tem estas variáveis
		if "morrendo" in alvo and alvo.morrendo and not alvo.eh_boss:
			vida = minf(vida, 12)
	else:
		vida = minf(vida, 12)
	if vida <= 0:
		instance_destroy()


func ev_draw() -> void:
	var ein := clampf(t / 8.0, 0, 1)
	var eout := clampf(vida / 12.0, 0, 1)
	var a := minf(ein, eout)
	var esc := 0.42 * (0.8 + 0.2 * (1 - pow(1 - ein, 3)))
	gpu_set_texfilter(true)
	var w := txt_largura(texto, FONTE.PEQUENA, esc) + 12
	var h := 18.0
	var bx := clampf(ax, G.view_x + w / 2 + 4, G.view_x + G.view_w - w / 2 - 4)
	var by := ay - 16 - t * 0.04
	draw_set_alpha(a * 0.55)
	draw_set_color(c_black)
	draw_roundrect_ext(bx - w / 2 + 2, by - h + 2, bx + w / 2 + 2, by + 2, 8, 8, false)
	draw_set_alpha(a * 0.92)
	draw_set_color(Color8(236, 222, 190))
	draw_roundrect_ext(bx - w / 2, by - h, bx + w / 2, by, 8, 8, false)
	draw_triangle(ax - 4, by - 1, ax + 4, by - 1, ax, by + 6, false)
	draw_set_color(Color8(90, 40, 30))
	draw_roundrect_ext(bx - w / 2, by - h, bx + w / 2, by, 8, 8, true)
	txt(bx, by - h / 2, texto, FONTE.PEQUENA, cor, a, fa_center, fa_middle, esc)
	gpu_set_texfilter(false)
	desenho_resetar()
