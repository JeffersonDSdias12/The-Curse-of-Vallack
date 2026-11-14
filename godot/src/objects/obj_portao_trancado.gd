extends Lib
# =====================================================================
#  obj_portao_trancado — o PORTÃO da paliçada no meio da fase 1 (v1.14)
#  Trancado: ninguém passa (a paliçada sobe além da câmera). Chegando perto
#  sem a chave: "ACHE A CHAVE DO PORTÃO" (ela está no baú selado no alto do
#  forte de madeira). Com a chave: a grade sobe e o caminho abre. Fica
#  aberto no save (aberto_chave). Criado pelo obj_terreno. (O mesmo da
#  versão PC.)
# =====================================================================

var y_topo := 0.0               # a paliçada passa do alto da câmera
var estado := "trancado"        # trancado -> abrindo -> aberto
var sobe := 0.0                 # a grade subindo (0 a 1)
var t := 0.0
var aviso_dado := false
var chave := ""
var solido = null


func ev_create() -> void:
	y_topo = y - 540
	chave = aberto_chave("portao", x, y)
	if aberto_tem(chave):
		estado = "aberto"
		sobe = 1
		solido = solido_criar(x - 14, y_topo, x + 14, y - 112)     # só a paliçada em cima da passagem
	else:
		solido = solido_criar(x - 14, y_topo, x + 14, y)


func ev_cleanup() -> void:
	solido_remover(solido)


func ev_step() -> void:
	var dt := G.dt
	t += dt
	var p = instance_find("obj_player", 0)
	if estado == "trancado" and p != null and not p.morto:
		if absf(p.x - x) < 70 and p.y > y - 220:
			G.portao_visto = true
			if G.chave_portao:
				estado = "abrindo"
				aberto_marcar(chave)
				aviso_mostrar("O PORTÃO SE ABRIU")
				V117.conquista("chave")      # v1.17
				som_em("sfx_portal", x, y - 40, 1, 0)
				G.camera_impact = maxf(G.camera_impact, 6)
			elif not aviso_dado:
				aviso_dado = true
				aviso_mostrar("PORTÃO TRANCADO  ·  ACHE A CHAVE DO PORTÃO")     # com o som da mensagem importante
		elif absf(p.x - x) > 180:
			aviso_dado = false
	if estado == "abrindo":
		sobe = minf(1, sobe + 0.016 * dt)
		if randf() < 0.4 * dt:
			fx_em("pedras", x + randf_range(-16, 16), y - 4, 0.4)
		if sobe >= 1:
			estado = "aberto"
			solido_remover(solido)
			solido = solido_criar(x - 14, y_topo, x + 14, y - 112)


# paliçada de troncos apontados, a grade de madeira com faixas de ferro, o
# cadeado em brasa (trancado) e duas tochas nos postes
func ev_draw() -> void:
	if x + 60 < G.view_x or x - 60 > G.view_x + G.view_w:
		return
	var pen: Pen = G.pen
	var tt := current_time() / 16.0
	for k in range(-4, 4):
		var lx := x + k * 7
		var c := Color8(124, 86, 52).lerp(Color8(98, 66, 40), (absi(k) % 2) * 0.6)
		var baixo := y - 112 if (k >= -2 and k <= 1) else y
		pen.retangulo(lx, y_topo, lx + 6, baixo, c, 1.0, false)
		pen.linha(lx + 1, y_topo, lx + 1, baixo, Color8(160, 116, 72), 1.0)
		pen.linha(lx + 6, y_topo, lx + 6, baixo, Color8(30, 20, 12), 1.0)
		pen.triangulo(lx, y_topo, lx + 6, y_topo, lx + 3, y_topo - 9, Color8(30, 20, 12), 1.0, false)
	pen.retangulo(x - 29, y - 168, x + 27, y - 162, Color8(54, 52, 56), 1.0, false)
	pen.retangulo(x - 29, y - 300, x + 27, y - 294, Color8(54, 52, 56), 1.0, false)
	# a grade (sobe ao abrir)
	var gy := y - 112 * sobe
	if sobe < 1:
		var gt := y - 110
		for k in 5:
			var bx := x - 14 + k * 7
			var topo := maxf(gt, gt - 112 * sobe)
			pen.retangulo(bx, topo, bx + 5, gy, Color8(86, 58, 36), 1.0, false)
			pen.linha(bx + 5, topo, bx + 5, gy, Color8(30, 20, 12), 1.0)
			pen.triangulo(bx, gy, bx + 5, gy, bx + 2.5, gy + 5, Color8(30, 20, 12), 1.0, false)
		for f in 3:
			var fy := gy - 20 - f * 32
			if fy > gt - 2:
				pen.retangulo(x - 16, fy, x + 18, fy + 4, Color8(70, 68, 72), 1.0, false)
	# o cadeado em brasa (só trancado)
	if estado == "trancado":
		var ly := y - 62
		var pul := 0.7 + 0.3 * sin(tt / 9.0)
		pen.blend_add = true
		pen.circulo(x + 2, ly, 20, Color8(255, 120, 40), 0.22 * pul, false)
		pen.blend_add = false
		pen.elipse(x - 5, ly - 16, x + 9, ly - 2, Color8(48, 44, 46), 1.0, true)
		pen.elipse(x - 4, ly - 15, x + 8, ly - 3, Color8(48, 44, 46), 1.0, true)
		pen.retangulo(x - 7, ly - 6, x + 11, ly + 10, Color8(150, 110, 50), 1.0, false)
		pen.linha(x - 7, ly - 6, x + 11, ly - 6, Color8(220, 170, 80), 1.0)
		pen.circulo(x + 2, ly + 1, 2, Color8(255, 150, 70), pul, false)
		pen.retangulo(x + 1, ly + 1, x + 3, ly + 6, Color8(255, 150, 70), pul, false)
	# tochas nos postes dos lados
	for s in [-1, 1]:
		var tx: float = x + s * 40
		pen.retangulo(tx - 2, y - 150, tx + 2, y, Color8(60, 40, 26), 1.0, false)
		var fl: float = 0.75 + 0.25 * sin(tt / 5.0 + s * 2) * sin(tt / 13.0 + s)
		cenario_luz(tx, y - 156, 46, fl, Color8(255, 150, 60))
		desenhar_chamas(tx, y - 150, 9, 16, tt + s * 30, 0.9, s * 7)
