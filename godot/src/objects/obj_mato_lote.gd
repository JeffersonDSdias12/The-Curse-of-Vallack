extends Lib
# =====================================================================
#  obj_mato_lote — todos os tufos de obj_mato da sala num objeto só
#  (no GameMaker cada tufo era uma instância; aqui são centenas e no
#  celular cada instância custa). Mesmo visual: cada tufo começa num
#  quadro diferente, balança no seu ritmo e fica atrás dos personagens.
#  Só os tufos perto da câmera são animados e desenhados.
# =====================================================================

const MARGEM := 120.0

var px := PackedFloat32Array()
var py := PackedFloat32Array()
var sx := PackedFloat32Array()
var sy := PackedFloat32Array()
var rot := PackedFloat32Array()
var img := PackedFloat32Array()
var vel := PackedFloat32Array()
var cores: Array[Color] = []
var sprs: Array[GMSprite] = []     # v1.13: cada tufo tem o seu mato (arte do Eduardo)
var spr: GMSprite


var vaos: Array = []           # v1.20: abismos e pontes que desabam, em ordem de x


func ev_create() -> void:
	depth = 150
	spr = Spr.spr_mato
	var d := terreno_dados(G.room)
	vaos = d.get("abismos", []) + d.get("pontes_queda", [])
	vaos.sort_custom(func(a, b): return a[0] < b[0])


func adicionar(x0: float, y0: float, xs: float, ys: float, ang: float, cor: Color) -> void:
	# a mesma mistura da versão PC (obj_mato): a maioria é mato verde escurecido
	# pela noite; o mato corrompido vermelho e as plantas ficam mais raros
	var s := spr
	var hsh := absi(roundi(x0) * 7 + roundi(y0) * 13) % 10
	if hsh < 6:
		s = Spr.spr_mato_normal
		cor = cor * Color8(112, 120, 128)
	elif hsh == 8:
		s = Spr.spr_planta
		cor = cor * Color8(120, 126, 134)
	elif hsh == 9:
		s = Spr.spr_planta_maldita
	sprs.append(s)
	px.append(x0)
	py.append(y0)
	sx.append(xs)
	sy.append(ys)
	rot.append(ang)
	img.append(randi_range(0, maxi(0, s.n - 1)))
	vel.append(randf_range(0.7, 1.3))
	cores.append(cor)


# tira os tufos entre x1 e x2 (ex.: onde um abismo abriu o chão)
func remover_faixa(x1: float, x2: float) -> void:
	for i in range(px.size() - 1, -1, -1):
		if px[i] > x1 and px[i] < x2:
			px.remove_at(i)
			py.remove_at(i)
			sx.remove_at(i)
			sy.remove_at(i)
			rot.remove_at(i)
			img.remove_at(i)
			vel.remove_at(i)
			cores.remove_at(i)
			sprs.remove_at(i)


func ev_step() -> void:
	var x1 := G.view_x - MARGEM
	var x2 := G.view_x + G.view_w + MARGEM
	for i in px.size():
		var xx := px[i]
		if xx < x1 or xx > x2:
			continue
		var n := float(sprs[i].n)
		var passo := sprs[i].spd / G.velocidade_jogo
		var v := img[i] + vel[i] * passo
		if v >= n:
			v -= n
		img[i] = v


func ev_draw() -> void:
	var x1 := G.view_x - MARGEM
	var x2 := G.view_x + G.view_w + MARGEM
	var y1 := G.view_y - MARGEM
	var y2 := G.view_y + G.view_h + MARGEM
	for i in px.size():
		var xx := px[i]
		var yy := py[i]
		if xx < x1 or xx > x2 or yy < y1 or yy > y2:
			continue
		var c: Color = cores[i]
		G.pen.sprite(sprs[i], img[i], xx, yy, sx[i], sy[i], rot[i], c, c.a)
	# v1.20: perto das pontes a câmera desce abaixo da sala; a terra cobre a parte do
	# mato que ficava escondida fora da tela (menos nos vãos dos abismos)
	if G.cam_baixo > 0.5:
		var topo := G.room_height + 1.0
		var fundo := G.room_height + 260.0
		var xa := G.view_x - 4.0
		var xf := G.view_x + G.view_w + 4.0
		for v in vaos:
			if v[1] <= xa or v[0] >= xf:
				continue
			if v[0] > xa:
				_terra(xa, topo, v[0], fundo)
			xa = maxf(xa, v[1])
		if xa < xf:
			_terra(xa, topo, xf, fundo)


func _terra(x1: float, y1: float, x2: float, y2: float) -> void:
	G.pen.retangulo_cores(x1, y1, x2, y1 + 40, Color8(30, 24, 26), Color8(30, 24, 26), Color8(14, 10, 12), Color8(14, 10, 12), 1.0)
	G.pen.retangulo(x1, y1 + 40, x2, y2, Color8(14, 10, 12), 1.0, false)
