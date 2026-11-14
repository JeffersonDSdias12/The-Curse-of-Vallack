extends Lib
# =====================================================================
#  obj_guerra — clima de GUERRA ao fundo e na frente da cena
#  Fase 1: saraivadas de flechas incendiárias cruzando o céu ao longe,
#    bolas de fogo de catapulta (com clarão no horizonte), brilho de
#    incêndios distantes e brasas sopradas pela tela.
#  Fase 2: cinzas caindo no salão em ruínas.
#  Fundo (Draw, profundidade 397: atrás do chão e dos personagens) e
#  frente (Draw End). Leve: poucas dezenas de partículas.
# =====================================================================

var t := 0.0
var flechas: Array = []         # {x, y, vx, vy, vida} em coordenadas da visão
var bolas: Array = []           # bolas de fogo de catapulta
var claroes: Array = []         # claroes no horizonte {x, vida, vmax}
var brasas: Array = []          # frente: brasas / cinzas
var prox_saraivada := 240.0
var prox_catapulta := 600.0
var view_ant := 0.0
var fase1 := true


func ev_create() -> void:
	depth = 397
	fase1 = G.room == "Room1"
	view_ant = G.view_x
	prox_saraivada = randf_range(120, 300)
	prox_catapulta = randf_range(400, 800)


func _qtd() -> float:
	return [0.4, 0.75, 1.0][clampi(G.cfg_qualidade, 0, 2)]


func ev_step() -> void:
	var dt := G.dt
	t += dt
	var vw := G.view_w
	var vh := G.view_h
	# parallax leve: o céu distante quase não acompanha a câmera
	var dx := (G.view_x - view_ant) * 0.85
	view_ant = G.view_x
	if fase1:
		prox_saraivada -= dt
		if prox_saraivada <= 0:
			prox_saraivada = randf_range(420, 840)
			var n := int(round(randf_range(4, 8) * _qtd()))
			var esq := randf() < 0.5
			for i in n:
				var sx := (vw + 20 + randf() * 60) if esq else (-20 - randf() * 60)
				flechas.append({"x": sx + i * randf_range(6, 14) * (1 if esq else -1), "y": vh * randf_range(0.18, 0.32),
					"vx": randf_range(-3.4, -2.4) * (1 if esq else -1), "vy": randf_range(-1.3, -0.7), "vida": 260.0})
		prox_catapulta -= dt
		if prox_catapulta <= 0:
			prox_catapulta = randf_range(900, 1600)
			var esq2 := randf() < 0.5
			bolas.append({"x": vw * (0.9 if esq2 else 0.1), "y": vh * 0.55, "vx": randf_range(-1.6, -1.1) * (1 if esq2 else -1),
				"vy": randf_range(-2.6, -2.1), "vida": 400.0})
		for f in flechas:
			f.x += f.vx * dt - dx
			f.y += f.vy * dt
			f.vy += 0.016 * dt
			f.vida -= dt
		for b in bolas:
			b.x += b.vx * dt - dx
			b.y += b.vy * dt
			b.vy += 0.012 * dt
			b.vida -= dt
			if b.y > vh * 0.6 and b.vy > 0:
				b.vida = 0
				claroes.append({"x": b.x, "vida": 50.0, "vmax": 50.0})
		for c in claroes:
			c.x -= dx
			c.vida -= dt
		flechas = flechas.filter(func(f): return f.vida > 0 and f.y < vh * 0.62)
		bolas = bolas.filter(func(b): return b.vida > 0)
		claroes = claroes.filter(func(c): return c.vida > 0)
	# frente: brasas (fase 1, sopradas pelo vento) ou cinzas (fase 2, caindo)
	var max_b := int(26 * _qtd())
	if brasas.size() < max_b and randf() < 0.35 * dt:
		if fase1:
			brasas.append({"x": randf() * (vw + 80), "y": vh + 6, "vx": randf_range(-1.2, -0.4), "vy": randf_range(-1.1, -0.5),
				"r": randf_range(0.7, 1.5), "vida": randf_range(180, 300), "vmax": 300.0, "fase": randf() * 10})
		else:
			brasas.append({"x": randf() * vw, "y": -6, "vx": randf_range(-0.25, 0.25), "vy": randf_range(0.25, 0.55),
				"r": randf_range(0.8, 1.6), "vida": randf_range(420, 600), "vmax": 600.0, "fase": randf() * 10})
	for b in brasas:
		b.x += (b.vx + sin(t / 40.0 + b.fase) * 0.25) * dt - (G.view_x - view_ant)
		b.y += b.vy * dt
		b.vida -= dt
	brasas = brasas.filter(func(b): return b.vida > 0 and b.y > -20 and b.y < vh + 20)


# FUNDO: céu de guerra atrás do chão e dos personagens
func ev_draw() -> void:
	if not fase1:
		return
	var pen: Pen = G.pen
	var vx := G.view_x
	var vy := G.view_y
	var vw := G.view_w
	var vh := G.view_h
	pen.blend_add = true
	# incêndios distantes: brilho pulsando perto do horizonte
	for k in 3:
		var gx := vx + vw * (0.18 + 0.32 * k) + sin(t / 300.0 + k) * 20
		var pulso := 0.5 + 0.5 * sin(t / (38.0 + k * 9) + k * 2.0)
		pen.elipse(gx - 120, vy + vh * 0.47, gx + 120, vy + vh * 0.62, Color8(255, 90, 30), 0.05 + 0.04 * pulso, false)
	for c in claroes:
		var p: float = c.vida / c.vmax
		pen.elipse(vx + c.x - 140, vy + vh * 0.42, vx + c.x + 140, vy + vh * 0.66, Color8(255, 150, 70), 0.35 * p, false)
		pen.elipse(vx + c.x - 50, vy + vh * 0.5, vx + c.x + 50, vy + vh * 0.6, Color8(255, 230, 180), 0.4 * p, false)
	# flechas incendiárias: risco claro com rastro de fogo
	for f in flechas:
		var px: float = vx + f.x
		var py: float = vy + f.y
		var d := Vector2(f.vx, f.vy).normalized()
		pen.linha(px - d.x * 16, py - d.y * 16, px, py, Color8(255, 120, 40), 0.45, 1.6)
		pen.linha(px - d.x * 5, py - d.y * 5, px + d.x * 2, py + d.y * 2, Color8(255, 236, 190), 0.9, 1.2)
		pen.circulo(px, py, 2.2, Color8(255, 170, 70), 0.6, false)
	# bolas de fogo de catapulta
	for b in bolas:
		var bx: float = vx + b.x
		var by: float = vy + b.y
		var d2 := Vector2(b.vx, b.vy).normalized()
		for k in 5:
			pen.circulo(bx - d2.x * k * 5, by - d2.y * k * 5, 5.5 - k, Color8(255, 110 + k * 10, 40), 0.5 - k * 0.08, false)
		pen.circulo(bx, by, 3, Color8(255, 240, 200), 0.9, false)
	pen.blend_add = false


# FRENTE: brasas e cinzas por cima da cena (atrás do HUD)
func ev_draw_end() -> void:
	var pen: Pen = G.pen
	var vx := G.view_x
	var vy := G.view_y
	if fase1:
		pen.blend_add = true
		for b in brasas:
			var a := clampf(b.vida / 60.0, 0, 1) * clampf((b.vmax - b.vida) / 30.0, 0, 1)
			var piscar := 0.6 + 0.4 * sin(t / 6.0 + b.fase * 3)
			pen.circulo(vx + b.x, vy + b.y, b.r, Color8(255, 150, 60), 0.85 * a * piscar, false)
			pen.circulo(vx + b.x, vy + b.y, b.r * 3, Color8(255, 90, 30), 0.15 * a, false)
		pen.blend_add = false
	else:
		for b in brasas:
			var a2 := clampf(b.vida / 80.0, 0, 1) * clampf((b.vmax - b.vida) / 40.0, 0, 1)
			pen.circulo(vx + b.x, vy + b.y, b.r, Color8(170, 160, 156), 0.5 * a2, false)
