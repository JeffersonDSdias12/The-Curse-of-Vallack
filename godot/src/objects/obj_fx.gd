extends Lib
# =====================================================================
#  obj_fx — efeitos dos golpes e especiais (desenhados por código)
#  tipos: poeira, onda_chao, rachaduras, faiscas_tela, carga, pedras,
#  faiscas_golpe, sangue, aparar, escudo_quebrado, lascas, fumaca,
#  brasas, entulho, fumaca_maldita, fumaca_maldita_estouro, corte, chamas_morte
# =====================================================================

var tipo := ""
var tam := 1.0
var dir := 1.0
var t := 0.0
var vida := 40.0
var parts: Array = []
var fendas: Array = []
var flash := 0.0
var gen := false
var forte := false              # corte de golpe pesado / especial (vermelho e maior)
var angulo := 0.0
var lote := false               # agrupa as partículas de vários efeitos (Lib.fx_em)
var efeitos: Array = []         # no lote: [tipo, fim] de cada efeito ainda vivo
# v1.17: efeitos de espada (lua crescente, cortes em X, estrela, raios de tinta, rajada)
var a1 := 0.0                   # arco da lua crescente (graus, para quem olha para a direita)
var a2 := 0.0
var raio := 40.0
var raios: Array = []           # pontas da estrela / raios de tinta / zigue-zague da rajada
var angulo_x := [0.0, 0.0]
var estilo := {}                # cores do estilo de lâmina (V117)
var descartado := false         # v1.18: cortado pelo orçamento de efeitos (some no próximo passo)

# chamas do golpe fatal: 3 camadas (vermelho, laranja, miolo amarelo)
const CHAMA_COR := [Color8(200, 40, 18), Color8(255, 120, 30), Color8(255, 232, 150)]
const CHAMA_ESC := [1.0, 0.68, 0.38]
const CHAMA_ALFA := [0.55, 0.7, 0.85]

# formas das partículas genéricas
enum { LINHA, CIRCULO, FUMO, MALDITA, RET, TRI, CHAMA }
const FORMAS := {"linha": LINHA, "circulo": CIRCULO, "fumo": FUMO, "maldita": MALDITA, "ret": RET, "tri": TRI, "chama": CHAMA}


# partícula com campos tipados (bem mais rápida que um dicionário no celular)
class Part:
	var x := 0.0
	var y := 0.0
	var vx := 0.0
	var vy := 0.0
	var r := 0.0
	var v := 0.0
	var vmax := 0.0
	var cor := Color.WHITE
	var g := 0.0
	var rot := 0.0
	var vr := 0.0
	var forma := 0
	var add := false
	var ang := 0.0
	var d := 0.0
	var fase := 0.0


func _part(px: float, py: float, vx: float, vy: float, r: float, v: float) -> Part:
	var p := Part.new()
	p.x = px
	p.y = py
	p.vx = vx
	p.vy = vy
	p.r = r
	p.v = v
	p.vmax = v
	parts.append(p)
	return p


# quantos efeitos deste tipo esta instância representa (lote ou efeito único)
func contar(tp: String) -> int:
	if not lote:
		return 1 if tipo == tp else 0
	var n := 0
	for e in efeitos:
		if e[0] == tp and e[1] > t:
			n += 1
	return n


# acrescenta as partículas de um efeito (sem clarão) a este lote
func lote_adicionar(tp: String, px: float, py: float, tm: float, d: float) -> void:
	var guarda := [tipo, x, y, tam, dir]
	var antes := parts.size()
	tipo = tp
	x = px
	y = py
	tam = tm
	dir = d
	fx_iniciar()
	# o efeito "vive" enquanto a sua partícula mais longa existir
	var maior := 0.0
	for i in range(antes, parts.size()):
		maior = maxf(maior, parts[i].v)
	for i in range(efeitos.size() - 1, -1, -1):
		if efeitos[i][1] <= t:
			efeitos.remove_at(i)
	efeitos.append([tp, t + maxf(maior, 10.0)])
	tipo = guarda[0]
	x = guarda[1]
	y = guarda[2]
	tam = guarda[3]
	dir = guarda[4]
	vida = 10
	flash = 0


# partícula genérica
func part_add(px: float, py: float, vx: float, vy: float, r: float, v: float, cor: Color, g: float, forma: String, add: bool) -> void:
	var p := _part(px, py, vx, vy, r, v)
	p.cor = cor
	p.g = g
	p.rot = randf() * 360
	p.vr = randf_range(-14, 14)
	p.forma = FORMAS[forma]
	p.add = add


func fx_iniciar() -> void:
	var q := G.cfg_qualidade
	var mult := 0.4 if q == 0 else (0.7 if q == 1 else 1.0)
	# v1.18: orçamento dos efeitos de combate (Lib.fx_orcamento). Descartado, o
	# efeito não desenha nada e some no próximo passo; num lote só não acrescenta nada.
	var orc := fx_orcamento(tipo, x, y)
	if orc <= 0:
		if not lote:
			descartado = true
		return
	mult *= orc
	_fx_criar_tipo(mult, q)
	# um clarão decorativo por vez
	if flash > 0 and tipo in FX_DECORATIVOS and not fx_flash_livre():
		flash = 0


func _fx_criar_tipo(mult: float, q: int) -> void:
	match tipo:
		"poeira":
			vida = 34
			for i in int(round(14 * tam * mult)) + 3:
				_part(x + randf_range(-24, 24) * tam, y - randf() * 6, randf_range(-1.6, 1.6) * tam, randf_range(-1.4, -0.2),
					randf_range(5, 11) * tam, randf_range(24, 34))
		"onda_chao":
			vida = 28
		"corte":
			# risco de luz no ponto do acerto, na diagonal do golpe
			vida = 13
			depth = -130
			angulo = (-28.0 if dir == 1 else 208.0) + randf_range(-14, 14)
			estilo = V117.espada_estilo_atual()
		# ----- v1.17: EFEITOS DE ESPADA (cores do estilo de lâmina do PERFIL) -----
		"corte_lua":
			vida = 13 if forte else 11
			estilo = V117.espada_estilo_atual()
		"corte_x":
			vida = 13
			estilo = V117.espada_estilo_atual()
			angulo_x = [randf_range(-12, 12), randf_range(-12, 12)]
		# ----- v1.17: FOGO (a espada em chamas) -----
		"explosao_fogo":
			vida = 20
			flash = 6
			estilo = V117.espada_estilo_atual()
			angulo = randf() * 360
			var nl := 7 if q == 0 else (10 if q == 1 else 13)
			for k in nl:
				raios.append({"ang": k * 360.0 / nl + randf_range(-14, 14), "len": randf_range(0.7, 1.25), "larg": randf_range(0.7, 1.2)})
			for k in int(round((6 + 6 * tam) * mult)):
				var ab := randf() * 360
				var vb := randf_range(1.2, 4.2) * tam
				var pe := _part(x, y, lengthdir_x(vb, ab) + dir * 0.6, lengthdir_y(vb, ab) - 1.2, randf_range(1, 2.2), randf_range(16, 30))
				pe.vmax = 30.0
		"chamas_corpo":
			# o inimigo derrotado ardendo (no lugar da fumaça negra)
			gen = true
			vida = 10
			var rt3 := tam if tam <= 1.5 else 1.5 + (tam - 1.5) * 0.45
			for i in maxi(1, int(round((2 + 1.2 * tam) * mult))):
				part_add(x + randf_range(-12, 12) * tam, y + randf_range(-8, 8) * tam, randf_range(-0.35, 0.35), randf_range(-1.9, -0.8),
					randf_range(3.5, 6.5) * rt3, randf_range(18, 30), c_white, -0.02, "chama", true)
			for i in randi_range(1, 2):
				part_add(x + randf_range(-12, 12) * tam, y + randf_range(-6, 6) * tam, randf_range(-0.6, 0.6), randf_range(-2.6, -1.1), randf_range(0.9, 1.8), randf_range(30, 55),
					choose([Color8(255, 200, 90), Color8(255, 130, 40), Color8(255, 80, 30)]), -0.012, "circulo", true)
		"chamas_estouro":
			# o último lampejo: o que sobrou do corpo vira brasa e some
			gen = true
			vida = 10
			flash = 7
			var rt4 := tam if tam <= 1.5 else 1.5 + (tam - 1.5) * 0.45
			for i in int(round((4 + 3 * tam) * mult)) + 2:
				var a5 := randf() * 360
				var v5 := randf_range(0.5, 2) * (0.8 + 0.25 * tam)
				part_add(x + lengthdir_x(randf() * 10 * tam, a5), y + lengthdir_y(randf() * 14 * tam, a5), lengthdir_x(v5, a5), lengthdir_y(v5 * 0.6, a5) - 1.2,
					randf_range(4, 7.5) * rt4, randf_range(18, 30), c_white, -0.025, "chama", true)
			for i in int(round((4 + 3 * tam) * mult)) + 2:
				part_add(x + randf_range(-14, 14) * tam, y + randf_range(-20, 20) * tam, randf_range(-1.6, 1.6), randf_range(-3.4, -1), randf_range(1, 2.4), randf_range(35, 70),
					choose([Color8(255, 210, 100), Color8(255, 140, 40), Color8(255, 90, 30)]), -0.012, "circulo", true)
		"rajada":
			vida = 15
			estilo = V117.espada_estilo_atual()
			var fz := 0.0
			while fz < 1:
				raios.append({"f": fz, "o": randf_range(-14, 14)})
				fz += randf_range(0.06, 0.12)
			raios.append({"f": 1.0, "o": 0.0})
		"chamas_morte":
			# golpe fatal (Castlevania): clarão e línguas de fogo subindo do corpo
			# (r = largura da chama, d = altura)
			vida = 36
			flash = 9
			for i in int(round(6 * tam * mult)) + 3:
				var pc := _part(x + randf_range(-16, 16) * tam, y + randf_range(-12, 24) * tam, 0, randf_range(-1.7, -0.6),
					randf_range(5, 9) * tam, randf_range(22, 36))
				pc.d = randf_range(18, 34) * tam
				pc.fase = randf() * 10
		"rachaduras":
			vida = 70
			for i in 6:
				var lado := 1.0 if i % 2 == 0 else -1.0
				var comp := randf_range(40, 90) * tam
				var pts := [[0.0, 0.0]]
				var px := 0.0
				for k in range(1, 6):
					px += lado * comp / 5.0
					pts.append([px, randf_range(-3, 4)])
				fendas.append(pts)
		"faiscas_tela":
			vida = 130
			depth = -210
			faiscas_emitir(int(round(70 * mult)) + 10)
		"carga":
			vida = 34
			for i in int(round(18 * mult)) + 4:
				var a := randf() * 360
				var d := randf_range(50, 80)
				var pc := _part(x + lengthdir_x(d, a), y + lengthdir_y(d, a), 0.0, 0.0, randf_range(1.5, 3), 34.0)
				pc.ang = a
				pc.d = d
		"faiscas_golpe":
			gen = true
			vida = 10
			flash = 7
			for i in int(round(12 * tam * mult)) + 4:
				var a := randf_range(-55, 55) + (0.0 if dir == 1 else 180.0)
				var s := randf_range(2.5, 7) * tam
				part_add(x, y, lengthdir_x(s, a), lengthdir_y(s, a) - 1, randf_range(1, 2.2), randf_range(12, 26),
					choose([Color8(255, 240, 180), Color8(255, 190, 80), c_white]), 0.22, "linha", true)
		"sangue":
			gen = true
			vida = 10
			for i in int(round(16 * tam * mult)) + 4:
				var a2 := randf_range(-70, 70) + (0.0 if dir == 1 else 180.0)
				var s2 := randf_range(1.5, 5.5) * tam
				part_add(x, y, lengthdir_x(s2, a2), lengthdir_y(s2, a2) - 1.5, randf_range(1.5, 3.2), randf_range(24, 44),
					choose([Color8(150, 10, 14), Color8(200, 20, 24), Color8(110, 0, 8)]), 0.28, "circulo", false)
		"aparar":
			gen = true
			vida = 22
			flash = 10
			for i in int(round(16 * mult)) + 6:
				var a3 := randf() * 360
				var s3 := randf_range(2, 6.5)
				part_add(x, y, lengthdir_x(s3, a3), lengthdir_y(s3, a3), randf_range(1, 2), randf_range(14, 28),
					choose([Color8(170, 220, 255), c_white, Color8(255, 230, 160)]), 0.05, "linha", true)
		"escudo_quebrado":
			gen = true
			vida = 10
			for i in int(round(10 * mult)) + 4:
				part_add(x + randf_range(-6, 6), y + randf_range(-14, 14), dir * randf_range(-1, 4) + randf_range(-1.5, 1.5), randf_range(-5.5, -2),
					randf_range(2.5, 5), randf_range(50, 80), choose([Color8(150, 150, 160), Color8(95, 92, 100), Color8(190, 160, 90)]), 0.3, "tri", false)
		"lascas":
			gen = true
			vida = 10
			for i in int(round(14 * tam * mult)) + 5:
				part_add(x + randf_range(-14, 14) * tam, y + randf_range(-14, 10) * tam, randf_range(-3.5, 3.5), randf_range(-6, -1.5),
					randf_range(2, 5) * tam, randf_range(40, 70), choose([Color8(120, 78, 40), Color8(150, 100, 52), Color8(84, 52, 26)]), 0.3, "ret", false)
		"entulho":
			gen = true
			vida = 10
			for i in int(round(22 * tam * mult)) + 6:
				part_add(x + randf_range(-16, 16), y - randf() * 110, randf_range(-3, 3), randf_range(-4, 0.5),
					randf_range(2.5, 6), randf_range(50, 90), choose([Color8(92, 84, 80), Color8(70, 62, 60), Color8(120, 110, 100)]), 0.3, "tri", false)
		"fumaca":
			gen = true
			vida = 10
			for i in maxi(1, int(round(3 * tam * mult))):
				part_add(x + randf_range(-10, 10) * tam, y, randf_range(-0.3, 0.6), randf_range(-1.1, -0.5), randf_range(6, 11) * tam, randf_range(70, 120),
					choose([Color8(40, 36, 38), Color8(60, 54, 54), Color8(30, 28, 30)]), -0.004, "fumo", false)
		"brasas":
			gen = true
			vida = 10
			for i in maxi(1, int(round(4 * tam * mult))):
				part_add(x + randf_range(-16, 16) * tam, y, randf_range(-0.6, 0.9), randf_range(-2.6, -0.8), randf_range(1, 2), randf_range(40, 80),
					choose([Color8(190, 110, 255), Color8(150, 50, 255), Color8(235, 200, 255)]), -0.01, "circulo", true)
		"fumaca_maldita":
			gen = true
			vida = 10
			# fumaça discreta: poucos sopros pequenos e curtos (não esconde o cenário)
			var rt := tam if tam <= 1.5 else 1.5 + (tam - 1.5) * 0.45
			for i in maxi(1, int(round((1 + 0.8 * tam) * mult))):
				part_add(x + randf_range(-10, 10) * tam, y + randf_range(-8, 8) * tam, randf_range(-0.45, 0.45), randf_range(-1.7, -0.6) * (0.8 + 0.2 * rt),
					randf_range(5, 8.5) * rt, randf_range(28, 44), choose([Color8(40, 30, 48), Color8(52, 38, 60), Color8(64, 46, 70)]), -0.004, "maldita", false)
			for i in randi_range(0, 1):
				part_add(x + randf_range(-10, 10) * tam, y + randf_range(-6, 6) * tam, randf_range(-0.5, 0.5), randf_range(-2.4, -1.0), randf_range(1, 2.2), randf_range(30, 60),
					choose([Color8(190, 40, 255), Color8(255, 40, 70), Color8(150, 20, 200)]), -0.01, "circulo", true)
		"fumaca_maldita_estouro":
			gen = true
			vida = 10
			flash = 6
			var rt2 := tam if tam <= 1.5 else 1.5 + (tam - 1.5) * 0.45
			# o último sopro também ficou pequeno: some rápido
			for i in int(round((5 + 3 * tam) * mult)) + 2:
				var a4 := randf() * 360
				var v4 := randf_range(0.6, 2.2) * (0.8 + 0.25 * tam)
				part_add(x + lengthdir_x(randf() * 10 * tam, a4), y + lengthdir_y(randf() * 14 * tam, a4), lengthdir_x(v4, a4), lengthdir_y(v4 * 0.7, a4) - 0.8,
					randf_range(6, 11) * rt2, randf_range(38, 60), choose([Color8(8, 4, 10), Color8(18, 6, 20), Color8(30, 8, 28)]), -0.006, "maldita", false)
			for i in int(round((3 + 2 * tam) * mult)) + 1:
				part_add(x + randf_range(-14, 14) * tam, y + randf_range(-20, 20) * tam, randf_range(-1.4, 1.4), randf_range(-3, -0.8), randf_range(1.2, 2.6), randf_range(35, 70),
					choose([Color8(200, 50, 255), Color8(255, 50, 80), Color8(170, 30, 220)]), -0.012, "circulo", true)
		"pedras":
			vida = 60
			for i in int(round(16 * mult)) + 4:
				var pp := _part(x + randf_range(-60, 60), y - 2, randf_range(-2.2, 2.2), randf_range(-6.5, -3), randf_range(2, 4.5), 60.0)
				pp.rot = randf() * 360
				pp.vr = randf_range(-12, 12)


# faíscas subindo por toda a largura da tela
func faiscas_emitir(qt: int) -> void:
	var cx1 := G.view_x
	var cw := G.view_w
	var base := minf(y + 8, G.view_y + G.view_h)
	for i in qt:
		var fx := cx1 + randf() * cw
		var perto := 1 - minf(1, absf(fx - x) / (cw * 0.6))
		var p := _part(fx, base - randf() * 20, randf_range(-0.5, 0.5), -randf_range(1.2, 3.2) - 2.2 * perto, randf_range(1.2, 2.8), randf_range(70, 125))
		p.cor = choose([Color8(255, 210, 90), Color8(255, 140, 40), Color8(255, 80, 40), c_white])
		p.fase = randf() * 100


func ev_step() -> void:
	if descartado:
		instance_destroy()
		return
	var dt := G.dt
	t += dt
	if tipo == "faiscas_tela" and t < 34 and G.cfg_qualidade > 0 and randf() < 0.6 * dt:
		faiscas_emitir(3)
	if flash > 0:
		flash -= dt
	if gen:
		# partículas genéricas: atualiza e compacta a lista mantendo a ordem
		var amort_x := pow(0.975, dt)
		var amort_y := pow(0.985, dt)
		var vivas := 0
		var n := parts.size()
		for i in n:
			var p: Part = parts[i]
			p.vy += p.g * dt
			p.x += p.vx * dt
			p.y += p.vy * dt
			p.rot += p.vr * dt
			var f := p.forma
			if f == FUMO:
				p.r += 0.12 * dt
				p.vx += 0.01 * dt
			elif f == MALDITA:
				p.r += 0.16 * dt
				p.vx += sin((t + p.rot) * 0.09) * 0.03 * dt
				p.vx *= amort_x
				p.vy *= amort_y
			elif f != LINHA and p.g > 0 and p.vy > 0 and G.chao_ponto(p.x, p.y + p.r):
				p.vy = -p.vy * 0.25
				p.vx *= 0.5
				p.vr *= 0.5
				if absf(p.vy) < 0.6:
					p.vy = 0
					p.g = 0
			p.v -= dt
			if p.v > 0:
				parts[vivas] = p
				vivas += 1
		parts.resize(vivas)
	# efeitos de um tipo só (poeira, faíscas da tela, carga, pedras)
	var restantes := 0 if gen else parts.size()
	for i in range(restantes - 1, -1, -1):
		var p: Part = parts[i]
		match tipo:
			"poeira":
				p.x += p.vx * dt
				p.y += p.vy * dt
				p.vx *= pow(0.93, dt)
				p.r += 0.25 * dt
			"faiscas_tela":
				p.x += (p.vx + sin((t + p.fase) / 9.0) * 0.35) * dt
				p.y += p.vy * dt
				p.vy *= pow(0.995, dt)
			"carga":
				p.d = maxf(0, p.d - 2.4 * dt)
				p.ang += 6 * dt
				p.x = x + lengthdir_x(p.d, p.ang)
				p.y = y + lengthdir_y(p.d, p.ang)
			"pedras":
				p.vy += 0.3 * dt
				p.x += p.vx * dt
				p.y += p.vy * dt
				p.rot += p.vr * dt
			"chamas_morte":
				p.y += p.vy * dt
				p.vy *= pow(0.96, dt)
				p.x += sin((t + p.fase) / 5.0) * 0.35 * dt
			"explosao_fogo":
				p.x += p.vx * dt
				p.y += p.vy * dt
				p.vx *= pow(0.95, dt)
				p.vy = p.vy * pow(0.95, dt) - 0.03 * dt
		p.v -= dt
		if p.v <= 0:
			parts.remove_at(i)
	if t >= vida and parts.is_empty():
		instance_destroy()
		return
	if t >= vida + 200 and not lote:
		instance_destroy()


func ev_draw() -> void:
	if descartado:
		return
	var p01 := clampf(t / vida, 0, 1)
	if gen:
		if flash > 0:
			gpu_set_blendmode(bm_add)
			var fa := flash / (10.0 if tipo == "aparar" else 7.0)
			draw_set_alpha(fa)
			if tipo == "aparar":
				draw_set_color(Color8(150, 210, 255))
			elif tipo == "fumaca_maldita_estouro":
				draw_set_color(Color8(170, 40, 200))
			else:
				draw_set_color(Color8(255, 230, 170))
			var fr := (26.0 if tipo == "aparar" else 12.0) * (1.4 - fa * 0.4) * tam
			draw_triangle(x - fr * 1.8, y, x, y - fr * 0.3, x, y + fr * 0.3, false)
			draw_triangle(x + fr * 1.8, y, x, y - fr * 0.3, x, y + fr * 0.3, false)
			draw_triangle(x, y - fr, x - fr * 0.25, y, x + fr * 0.25, y, false)
			draw_triangle(x, y + fr, x - fr * 0.25, y, x + fr * 0.25, y, false)
			draw_circle(x, y, fr * 0.45, false)
			if tipo == "aparar":
				draw_set_alpha(fa * 0.8)
				draw_circle(x, y, 10 + (1 - fa) * 40, true)
				draw_circle(x, y, 8 + (1 - fa) * 30, true)
			gpu_set_blendmode(bm_normal)
		# partículas desenhadas direto no Pen (o lote pode ter centenas)
		var pen: Pen = G.pen
		var brilho_maldito := Color8(140, 25, 120)
		var miolo_maldito := Color8(40, 6, 36)
		var qual := G.cfg_qualidade > 0
		for item in parts:
			var q: Part = item
			var qx := q.x
			var qy := q.y
			var qr := q.r
			var cq := q.cor
			var qa := clampf(q.v / (q.vmax * 0.4), 0, 1)
			pen.blend_add = q.add
			match q.forma:
				LINHA:
					pen.linha(qx, qy, qx - q.vx * 2.2, qy - q.vy * 2.2, cq, qa, qr)
				CIRCULO:
					pen.circulo(qx, qy, qr, cq, qa, false)
				FUMO:
					pen.circulo(qx, qy, qr, cq, 0.32 * clampf(q.v / q.vmax * 1.6, 0, 1) * minf(1, (q.vmax - q.v) / 12.0), false)
				MALDITA:
					var ma := clampf(q.v / q.vmax * 1.5, 0, 1) * minf(1, (q.vmax - q.v) / 8.0)
					if qual:
						pen.blend_add = true
						pen.circulo(qx, qy, qr * 1.2, brilho_maldito, 0.16 * ma, false)
						pen.blend_add = false
					pen.circulo(qx, qy, qr, cq, 0.36 * ma, false)
					pen.circulo(qx - qr * 0.08, qy + qr * 0.06, qr * 0.74, cq, 0.36 * ma, false)
					pen.circulo(qx + qr * 0.12, qy + qr * 0.16, qr * 0.46, miolo_maldito, 0.4 * ma, false)
				CHAMA:
					# v1.17: língua de fogo: branco-amarelo ao nascer, laranja, vermelho e some
					var kc := clampf(q.v / q.vmax, 0, 1)
					var ac := minf(1, (q.vmax - q.v) / 4.0) * minf(1, kc * 1.6)
					var cc1 := Color8(255, 150, 50).lerp(Color8(255, 236, 170), (kc - 0.6) / 0.4) if kc > 0.6 else Color8(200, 40, 16).lerp(Color8(255, 150, 50), kc / 0.6)
					var rc := qr * (0.55 + 0.45 * kc)
					var bal := sin((t + q.rot) * 0.3) * rc * 0.5
					pen.circulo(qx, qy, rc * 1.5, cc1, 0.45 * ac, false)
					pen.triangulo(qx - rc, qy, qx + rc, qy, qx + bal, qy - rc * 2.8, cc1, 0.9 * ac, false)
					pen.circulo(qx, qy, rc, cc1, 0.9 * ac, false)
				RET:
					var c1: float = dcos(q.rot) * qr
					var s1: float = dsin(q.rot) * qr
					pen.triangulo(qx - c1, qy - s1 * 0.4, qx + c1, qy + s1 * 0.4, qx + c1 - s1 * 0.4, qy + s1 * 0.4 + c1 * 0.4, cq, qa, false)
					pen.triangulo(qx - c1, qy - s1 * 0.4, qx - c1 - s1 * 0.4, qy - s1 * 0.4 + c1 * 0.4, qx + c1 - s1 * 0.4, qy + s1 * 0.4 + c1 * 0.4, cq, qa, false)
				_:
					var cc: float = dcos(q.rot) * qr
					var sn2: float = dsin(q.rot) * qr
					pen.triangulo(qx + cc, qy + sn2, qx - sn2, qy + cc, qx - cc * 0.6, qy - sn2 * 0.6, cq, qa, false)
		pen.blend_add = false
		draw_set_alpha(1)
		draw_set_color(c_white)
		return
	match tipo:
		"corte":
			var pen: Pen = G.pen
			var e := 1 - pow(1 - p01, 3)
			var dl := Vector2(dcos(angulo), -dsin(angulo))
			var nl := Vector2(-dl.y, dl.x)
			var c := Vector2(x, y)
			var comp := (40 + 26 * tam) * (0.55 + 0.45 * e)
			var larg := (5.5 * tam) * (1 - p01)
			var cor_brilho := Color8(255, 70, 40) if forte else Color8(255, 196, 130)
			if not estilo.is_empty() and estilo.id != "carmesim":
				cor_brilho = estilo.brilho if forte else estilo.meio      # v1.17
			pen.blend_add = true
			for camada in [[2.6, cor_brilho, 0.45], [1.0, c_white, 0.95]]:
				var lw: float = larg * camada[0]
				var cl: Color = camada[1]
				var al: float = (1 - p01) * camada[2]
				var a1 := c - dl * comp * 0.5
				var a2 := c + dl * comp * 0.5
				var m1 := c + nl * lw
				var m2 := c - nl * lw
				pen.triangulo(a1.x, a1.y, m1.x, m1.y, m2.x, m2.y, cl, al, false)
				pen.triangulo(a2.x, a2.y, m1.x, m1.y, m2.x, m2.y, cl, al, false)
			# onda de choque
			var ra := (6 + 30 * tam) * e
			pen.circulo(x, y, ra, cor_brilho, (1 - p01) * 0.55, true)
			if forte:
				pen.circulo(x, y, ra * 0.7, c_white, (1 - p01) * 0.4, true)
			pen.blend_add = false
		# ===== v1.17: EFEITOS DE ESPADA =====
		"corte_lua":
			# lua crescente: grossa no meio, fina nas pontas; "se desenha" em 3 quadros
			var aw1 := a1 if dir == 1 else 180 - a1
			var aw2 := a2 if dir == 1 else 180 - a2
			var rl := raio * tam * (1 + 0.18 * (1 - pow(1 - p01, 2)))
			V117.lua_crescente(x, y, rl, aw1, aw2, (15.0 if forte else 11.0) * tam, estilo, 1 - p01, (t + 1) / 3.0)
		"corte_x":
			var kx := 1 - p01
			var comp := 62 * tam * (0.4 + 0.6 * clampf(t / 3.0, 0, 1)) * (1 + 0.2 * p01)
			var wx := 3.4 * tam * kx
			var bx := 0.0 if dir == 1 else 180.0
			var pen: Pen = G.pen
			pen.blend_add = true
			for r2 in 2:
				var angx: float = bx + (38.0 if r2 == 0 else -38.0) + angulo_x[r2]
				var ddx := lengthdir_x(comp, angx)
				var ddy := lengthdir_y(comp, angx)
				V117.fx_losango(x - ddx, y - ddy, x + ddx, y + ddy, wx * 3, estilo.brilho, kx * 0.45)
				V117.fx_losango(x - ddx, y - ddy, x + ddx, y + ddy, wx, estilo.miolo, kx)
			pen.circulo(x, y, 16 * tam * (1 + p01), estilo.brilho, kx * 0.55, false)
			pen.circulo(x, y, 7 * tam * (1 + 0.5 * p01), estilo.miolo, kx * 0.8, false)
			pen.circulo(x, y, 10 + 34 * tam * p01, estilo.miolo, kx * 0.6, true)
			pen.blend_add = false
		"explosao_fogo":
			# v1.17: o golpe acerta: bola de fogo crescendo, línguas de fogo saindo e
			# subindo com o calor, brasas voando (tudo aditivo: nada escuro na tela)
			var kf := 1 - p01
			var ce := 1 - pow(1 - clampf(t / 6.0, 0, 1), 2)
			var rr := 15 * tam * (0.45 + 0.75 * ce)
			var pen: Pen = G.pen
			pen.blend_add = true
			for item in raios:
				var rl: Dictionary = item
				var ang: float = angulo + rl.ang
				var ln: float = rr * (1.25 + 0.9 * ce) * rl.len
				var tx := x + lengthdir_x(ln, ang)
				var ty := y + lengthdir_y(ln, ang) - 10 * tam * p01
				var wl: float = rr * 0.42 * rl.larg * kf
				var nx := lengthdir_x(wl, ang + 90)
				var ny := lengthdir_y(wl, ang + 90)
				pen.triangulo(x + nx, y + ny, x - nx, y - ny, tx, ty, estilo.brilho, 0.55 * kf, false)
				pen.triangulo(x + nx * 0.5, y + ny * 0.5, x - nx * 0.5, y - ny * 0.5, lerpf(x, tx, 0.7), lerpf(y, ty, 0.7), estilo.meio, 0.75 * kf, false)
			pen.circulo(x, y - 3 * p01, rr * 1.35, estilo.brilho, 0.35 * kf, false)
			pen.circulo(x, y - 4 * p01, rr, estilo.meio, 0.7 * kf, false)
			pen.circulo(x, y - 5 * p01, rr * 0.55, estilo.miolo, pow(kf, 1.5), false)
			if flash > 0:
				pen.circulo(x, y, rr * 0.8, Color.WHITE, flash / 6.0 * 0.8, false)
			for item2 in parts:
				var pb: Part = item2
				var kb := clampf(pb.v / pb.vmax, 0, 1)
				pen.circulo(pb.x, pb.y, pb.r, (estilo.brilho as Color).lerp(estilo.miolo, kb), kb, false)
			pen.blend_add = false
		"rajada":
			var kr := 1 - p01
			var cr := 1 - pow(1 - clampf(t / 4.0, 0, 1), 2)
			var ll := 170 * tam * cr
			var hr := 9 * tam * kr
			var x2r := x + dir * ll
			var xm := lerpf(x, x2r, 0.7)
			var pen: Pen = G.pen
			pen.blend_add = true
			var camr := [[2.2, estilo.brilho, 0.4], [1.0, estilo.meio, 0.85], [0.35, estilo.miolo, 1.0]]
			for c in 3:
				var cl: Array = camr[c]
				var hh: float = hr * cl[0]
				pen.triangulo(x, y, xm, y - hh, xm, y + hh, cl[1], kr * cl[2], false)
				pen.triangulo(x2r, y, xm, y - hh, xm, y + hh, cl[1], kr * cl[2], false)
			for z in raios.size() - 1:
				var z1: Dictionary = raios[z]
				var z2: Dictionary = raios[z + 1]
				if z2.f > cr:
					break
				pen.linha(x + dir * z1.f * 170 * tam, y + z1.o * tam, x + dir * z2.f * 170 * tam, y + z2.o * tam, estilo.miolo, kr * 0.9, 1.5)
			pen.blend_add = false
		"chamas_morte":
			var pen: Pen = G.pen
			pen.blend_add = true
			# clarão branco-amarelado no instante da morte
			if flash > 0:
				var ff := flash / 9.0
				pen.circulo(x, y, 26 * tam * (1.5 - ff * 0.5), Color8(255, 236, 190), ff * 0.8, false)
				pen.circulo(x, y, 10 * tam, c_white, ff, false)
			# cada chama: gota de fogo em 3 camadas (vermelho, laranja, miolo amarelo)
			for p: Part in parts:
				var k := clampf(p.v / p.vmax, 0, 1)
				var cresce := sin(PI * minf(1.0, (1 - k) * 1.6 + 0.15))
				var tremula := 0.85 + 0.15 * sin(t * 1.3 + p.fase * 7)
				var ponta := sin((t + p.fase * 4) / 3.0) * p.r * 0.5
				var ak := minf(1.0, k * 1.8)
				for c in 3:
					var esc: float = CHAMA_ESC[c]
					var rr: float = p.r * esc * (0.4 + 0.6 * k)
					var hh: float = p.d * esc * cresce * tremula
					var cor: Color = CHAMA_COR[c]
					var al: float = CHAMA_ALFA[c] * ak
					pen.circulo(p.x, p.y, rr, cor, al, false)
					pen.triangulo(p.x - rr, p.y, p.x + rr, p.y, p.x + ponta, p.y - rr - hh, cor, al, false)
			pen.blend_add = false
		"poeira":
			for p in parts:
				draw_set_alpha(clampf(p.v / 34.0, 0, 1) * 0.45)
				draw_set_color(Color8(120, 104, 92))
				draw_circle(p.x, p.y, p.r, false)
		"onda_chao":
			gpu_set_blendmode(bm_add)
			var e := 1 - pow(1 - p01, 2)
			var rx := (24 + 150 * e) * tam
			var ry := (8 + 20 * e) * tam
			draw_set_alpha((1 - p01) * 0.8)
			draw_set_color(Color8(255, 120, 60))
			draw_ellipse(x - rx, y - ry, x + rx, y + ry * 0.5, true)
			draw_ellipse(x - rx + 2, y - ry + 1, x + rx - 2, y + ry * 0.5 - 1, true)
			draw_set_alpha((1 - p01) * 0.35)
			draw_set_color(Color8(255, 200, 140))
			draw_ellipse(x - rx * 0.7, y - ry * 0.7, x + rx * 0.7, y + ry * 0.35, false)
			for l in [-1.0, 1.0]:
				var cx: float = x + l * rx
				var h := 34 * tam * (1 - p01)
				draw_set_alpha((1 - p01) * 0.7)
				draw_set_color(Color8(255, 90, 40))
				draw_triangle(cx - 6, y, cx + 6, y, cx, y - h, false)
			gpu_set_blendmode(bm_normal)
		"rachaduras":
			var brilho := 1 - p01
			for pts in fendas:
				var cresce := clampf(t / 8.0, 0, 1)
				var np := maxi(2, int(floor((pts.size() - 1) * cresce)) + 1)
				for k in range(1, np):
					var a: Array = pts[k - 1]
					var b: Array = pts[k]
					draw_set_alpha(0.85 * clampf(brilho * 1.6, 0, 1))
					draw_set_color(c_black)
					draw_line_width(x + a[0], y + a[1], x + b[0], y + b[1], 3)
					gpu_set_blendmode(bm_add)
					draw_set_alpha(brilho)
					draw_set_color(merge_color(Color8(255, 70, 20), Color8(255, 210, 120), brilho))
					draw_line_width(x + a[0], y + a[1] - 1, x + b[0], y + b[1] - 1, 1.5)
					gpu_set_blendmode(bm_normal)
		"faiscas_tela", "carga":
			gpu_set_blendmode(bm_add)
			for s in parts:
				var a2: float = 0.8 if tipo == "carga" else clampf(s.v / 40.0, 0, 1) * (0.6 + 0.4 * sin((t + s.fase) * 0.5))
				var cor: Color = Color8(255, 170, 70) if tipo == "carga" else s.cor
				draw_set_alpha(a2)
				draw_set_color(cor)
				draw_circle(s.x, s.y, s.r, false)
				if G.cfg_qualidade == 2:
					draw_set_alpha(a2 * 0.25)
					draw_circle(s.x, s.y, s.r * 3, false)
					draw_set_alpha(a2 * 0.5)
					draw_line_width(s.x, s.y, s.x - s.vx * 3, s.y - s.vy * 3, s.r * 0.8)
			gpu_set_blendmode(bm_normal)
		"pedras":
			for pd in parts:
				draw_set_alpha(clampf(pd.v / 20.0, 0, 1))
				draw_set_color(Color8(88, 74, 66))
				var r2: float = pd.r
				var c: float = dcos(pd.rot) * r2
				var sn: float = dsin(pd.rot) * r2
				draw_triangle(pd.x + c, pd.y + sn, pd.x - sn, pd.y + c, pd.x - c, pd.y - sn, false)
				draw_triangle(pd.x - c, pd.y - sn, pd.x + sn, pd.y - c, pd.x + c, pd.y + sn, false)
	draw_set_alpha(1)
	draw_set_color(c_white)
	gpu_set_blendmode(bm_normal)
