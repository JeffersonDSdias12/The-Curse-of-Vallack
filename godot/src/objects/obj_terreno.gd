extends Lib
# =====================================================================
#  obj_terreno — ABISMOS mortais, PLATAFORMAS e os CAMINHOS POR CIMA
#  (estilo Castlevania). Criado pelo sala_preparar() nas fases. Abre os
#  vãos no chão, cria os blocos das plataformas, escadas, torres, pontes e
#  ilhas, tira os pedaços de castelo da vila, mata quem cai e desenha tudo (escadas,
#  torre e andaime de madeira, ilhas com as peças do Alex,
#  tábuas de madeira na vila; pedra presa por correntes no castelo). Os
#  dados ficam em Lib.terreno_dados() (a mesma tabela da versão PC).
#  Profundidade 280: na frente do chão (300), atrás dos personagens.
# =====================================================================

var chao_y := 0.0
var madeira := false
var abismos: Array = []
var plataformas: Array = []
var escadas: Array = []
var blocos: Array = []
var pontes: Array = []
var ilhas: Array = []
var ruinas: Array = []
var mover: Array = []
var caixotes: Array = []
var arvores: Array = []
var remover: Array = []
var pecas_ok := false
var t := 0.0
var pronto := false             # tudo entra no 1º passo, com a sala inteira já criada
# v1.14: escadas de mão, cordas e correntes; pontes de corda; plataformas
# penduradas; o baú da chave (arena no alto do forte) e o portão trancado
var escalar: Array = []
var pontes_corda: Array = []
var suspensas: Array = []
var chave_dados: Dictionary = {}
var portao: Array = []
var arena_estado := "espera"    # espera -> luta -> livre
var arena_inimigos: Array = []
var bau_chave = null
# v1.20: PONTES QUE DESABAM e PISO FRÁGIL (dados em Lib.terreno_dados)
#  ponte: {x1, x2, tipo, estado (inteira -> aviso -> caindo -> caida), t, frente, dir, segs}
#  trecho da ponte / laje frágil: {x, w, inst, estado, t, dy, vy}
var pontes_q: Array = []
var frageis: Array = []
const PQ_TRECHOS := 9            # trechos por ponte
const PQ_AVISO := 22.0           # quadros de aviso antes de começar a cair
const PQ_FUNDO := 250.0          # até onde o abismo das pontes é desenhado abaixo da sala
const FRAGIL_TEMPO := 34.0       # quadros que a laje aguenta com o herói em cima
const FRAGIL_VOLTA := 170.0      # quadros até a laje voltar


func ev_create() -> void:
	depth = 280
	var d := terreno_dados(G.room)
	chao_y = d["chao"]
	madeira = d["madeira"]
	abismos = d["abismos"]
	plataformas = d["plataformas"]
	escadas = d["escadas"]
	blocos = d["blocos"]
	pontes = d["pontes"]
	ilhas = d["ilhas"]
	ruinas = d["ruinas"]
	mover = d["mover"]
	caixotes = d["caixotes"]
	arvores = d["arvores"]
	remover = d["remover"]
	escalar = d["escalar"]
	pontes_corda = d["pontes_corda"]
	suspensas = d["suspensas"]
	chave_dados = d["chave"]
	portao = d["portao"]
	G.escalaveis = escalar          # o herói consulta para escalar (obj_player)
	G.chave_portao = false
	G.portao_visto = false
	G.arena_chave = false
	pecas_ok = pecas_carregar()


func ev_step() -> void:
	# no 1º passo todos os blocos de chão e a decoração da sala já existem
	if not pronto:
		pronto = true
		# v1.13: os pedaços de castelo espalhados pela vila saem da fase
		for o in remover:
			for i in todos(o):
				instance_destroy(i)
		for a in abismos:
			terreno_abrir(a[0], a[1], chao_y)
		_quedas_montar()
		for pl in plataformas:
			terreno_plataforma(pl[0], pl[1], pl[2])
		# caminhos por cima: escadarias, torres, passarelas e ilhas
		for e in escadas:
			terreno_limpar(minf(e[0], e[1]), maxf(e[0], e[1]))
			terreno_escada(e[0], e[1], e[2], chao_y)
		for b in blocos:
			terreno_limpar(b[0], b[1])
			terreno_bloco(b[0], b[1], b[2], chao_y)
		for p in pontes:
			terreno_ponte(p[0], p[1], p[2])
		for il in ilhas:
			var pc := peca(il[2]) if pecas_ok else []
			var lw: float = 60.0 if pc.is_empty() else pc[2] * PECA_ESC * 0.78
			terreno_ponte(il[0] - lw / 2, il[0] + lw / 2, il[1])
		# inimigos que ficam no alto (o arqueiro na torre)
		for m in mover:
			for o in todos(m[0]):
				if o.x >= m[1] and o.x <= m[2]:
					o.x = m[3]
					o.y = m[4]
					o.xstart = o.x
					o.ystart = o.y
		# v1.14: pontes de corda e plataformas penduradas (de mão única: o herói sobe
		# por baixo e desce com ▼ + PULO, como as passarelas)
		for pc2 in pontes_corda:
			terreno_ponte(pc2[0], pc2[1], pc2[2])
		for s in suspensas:
			terreno_ponte(s[0], s[1], s[2])
		# o baú da chave, selado até os guardiões caírem (aberto antes = a chave já é sua)
		if not chave_dados.is_empty():
			bau_chave = instance_create_depth(chave_dados["bau"][0], chave_dados["bau"][1], 150, "obj_bau")
			bau_chave.conteudo = "chave"
			bau_chave.selado = bau_chave.estado == "fechado"
			if not bau_chave.selado:
				G.chave_portao = true
				arena_estado = "livre"
		if portao.size() > 0:
			# o portão toma o lugar da parede quebrável que ficava ali
			for w in todos("obj_parede_quebravel"):
				if absf(w.x - portao[0]) < 48:
					instance_destroy(w)
			instance_create_depth(portao[0], chao_y, 140, "obj_portao_trancado")
		# recompensas no adarve
		for c in caixotes:
			var cx := instance_create_depth(c[0], c[1], 150, "obj_caixote")
			cx.conteudo = "orbs"
			cx.orbs_valor = 16
	t += G.dt
	_arena_chave()
	_quedas_passo(G.dt)
	# quem cai no abismo morre (Castlevania): o herói vai para o fim de jogo,
	# o monstro some e conta como derrotado
	var fundo := G.room_height + 6.0
	var p = instance_find("obj_player", 0)
	if p != null and not p.morto and p.bbox_top > fundo:
		p.jogador_cair_abismo()
	for e in todos("obj_inimigo_base"):
		if e.bbox_top > fundo:
			if not e.morrendo:
				G.inimigos_derrotados += 1
			instance_destroy(e)
	# o que mais cair lá some (orbs e cristais que rolaram para o vão)
	for tipo in ["obj_orb", "obj_essencia"]:
		for o in todos(tipo):
			if o.y > fundo + 40:
				instance_destroy(o)


func ev_draw() -> void:
	var pen: Pen = G.pen
	var vx := G.view_x
	var vy := G.view_y
	var vw := G.view_w
	var base := G.room_height + PQ_FUNDO      # v1.20: a câmera pode descer perto das pontes
	var filtro := pen.filtro
	# ===== RUÍNAS na frente das casas (mais destruição na vila) =====
	if pecas_ok:
		pen.filtro = true
		var tom_r := Color8(178, 160, 158)
		for i in ruinas.size():
			var r: Array = ruinas[i]
			var pc := peca(r[0])
			if pc.is_empty() or r[1] > vx + vw + 20 or r[1] + pc[2] * PECA_ESC < vx - 20:
				continue
			peca_desenhar(r[0], r[1], chao_y + 3, int(r[2]) == 1, tom_r)
			if r[0] == "parede35" or r[0] == "parede36":
				cenario_luz(r[1] + pc[2] * PECA_ESC * (0.3 if int(r[2]) == 1 else 0.7), chao_y + 3 - pc[3] * PECA_ESC * 0.62, 34, 0.8 + 0.2 * sin(t / 9.0 + i), Color8(255, 150, 60))
		pen.filtro = filtro
	# ===== ÁRVORES ASSOMBRADAS na estrada (balançam, olhos acesos) =====
	for i in arvores.size():
		var a: Array = arvores[i]
		if a[0] < vx - 140 or a[0] > vx + vw + 140:
			continue
		draw_sprite_hd(Spr.spr_arvore_assombrada, t / 12.0 + i * 3, a[0], chao_y + 3, -1.6 if int(a[1]) == 1 else 1.6, 1.6, 0, Color8(176, 164, 170), 1)
	# ===== ABISMOS: vão escuro, beiradas quebradas e o brilho lá do fundo =====
	for i in abismos.size():
		var x1: float = abismos[i][0]
		var x2: float = abismos[i][1]
		if x2 < vx - 40 or x1 > vx + vw + 40:
			continue
		var yt := chao_y - 1
		var esc := Color8(16, 9, 12)
		pen.retangulo_cores(x1, yt, x2, base, esc, esc, Color.BLACK, Color.BLACK, 1.0)
		var terra := Color8(44, 34, 32)
		for k in 5:
			var yy := yt + k * 9
			var pk := 7 - k
			pen.triangulo(x1, yy, x1 + pk + 3, yy + 4, x1, yy + 9, terra, 1.0, false)
			pen.triangulo(x2, yy, x2 - pk - 3, yy + 5, x2, yy + 9, terra, 1.0, false)
		pen.linha(x1 - 2, yt, x1 + 6, yt + 1, Color8(92, 78, 70), 1.0, 2.0)
		pen.linha(x2 - 6, yt + 1, x2 + 2, yt, Color8(92, 78, 70), 1.0, 2.0)
		# lá no fundo: brasas subindo (vila em chamas) ou névoa roxa (castelo)
		pen.blend_add = true
		var cor := Color8(255, 90, 30) if madeira else Color8(120, 40, 160)
		pen.elipse(x1 + 4, G.room_height - 18, x2 - 4, G.room_height + 30, cor, 0.16 + 0.05 * sin(t / 30.0 + i), false)
		var cb := Color8(255, 150, 60) if madeira else Color8(190, 110, 255)
		for k in 4:
			var f := fposmod(t / 140.0 + k / 4.0 + i * 0.37, 1.0)
			var bx := lerpf(x1 + 10, x2 - 10, fposmod(k * 0.618 + i * 0.3, 1.0)) + sin(t / 20.0 + k) * 4
			pen.circulo(bx, G.room_height + 10 - f * 50, 1.3, cb, (1 - f) * 0.6, false)
		pen.blend_add = false
	_quedas_desenhar(pen, vx, vw)
	_desenhar_madeira(pen, vx, vw)
	if pecas_ok:
		pen.filtro = true
		_desenhar_ilhas(pen, vx, vw)
		pen.filtro = filtro
	_desenhar_pontes(pen, vx, vw)
	_desenhar_plataformas(pen, vx, vy, vw)
	_desenhar_escalar(pen, vx, vw)


# escadarias de madeira, a torre de vigia e o andaime alto
func _desenhar_madeira(pen: Pen, vx: float, vw: float) -> void:
	# ===== ESCADARIAS de madeira: degraus que sobem do chão, fechados com tábuas =====
	for i in escadas.size():
		var e: Array = escadas[i]
		var xa: float = e[0]
		var xb: float = e[1]
		if maxf(xa, xb) < vx - 20 or minf(xa, xb) > vx + vw + 20:
			continue
		var n := maxi(1, roundi((chao_y - float(e[2])) / 8.0))
		var lw := absf(xb - xa) / n
		# o desenho fica meio herói (10 px) para o lado de baixo: a máscara pisa no
		# degrau com a quina de cima, então o degrau embaixo do CENTRO do corpo é o
		# que ele pisa de verdade (antes o pé parecia flutuar ou afundar na escada)
		var sb := signf(xb - xa)
		var xv := xa - sb * 10.0
		for k in n:
			var ult := 10.0 if k == n - 1 else 0.0      # o último degrau vai até a passarela / torre
			var sx1 := xv + k * lw if sb > 0 else xv - (k + 1) * lw - ult
			var sx2 := xv + (k + 1) * lw + ult if sb > 0 else xv - k * lw
			var sy := chao_y - (k + 1) * 8
			madeira_tabuas(sx1, sy + 3, sx2, chao_y, k)
			pen.retangulo(sx1 - 1, sy, sx2, sy + 3, Color8(150, 106, 64), 1.0, false)
			pen.linha(sx1 - 1, sy, sx2, sy, Color8(196, 150, 96), 1.0)
			pen.linha(sx1 - 1, sy + 3, sx2, sy + 3, Color8(30, 20, 12), 1.0)
		pen.linha(xv, chao_y, xb, float(e[2]) + 6, Color8(44, 28, 16), 1.0, 4.0)
		var xp := xb - 3 if xb > xa else xb + 3
		pen.retangulo(xp - 3, float(e[2]) - 18, xp + 3, chao_y, Color8(40, 26, 16), 1.0, false)
		pen.retangulo(xp - 2, float(e[2]) - 18, xp + 2, chao_y, Color8(96, 64, 38), 1.0, false)
	# ===== TORRE DE VIGIA de madeira (sólida): tábuas, postes, travas e o parapeito =====
	for i in blocos.size():
		var b: Array = blocos[i]
		var bx1: float = b[0]
		var bx2: float = b[1]
		var by: float = b[2]
		if bx2 < vx - 30 or bx1 > vx + vw + 30:
			continue
		madeira_tabuas(bx1, by + 4, bx2, chao_y, i * 3)
		var trava := Color8(44, 28, 16)
		pen.linha(bx1 + 4, by + 10, bx2 - 4, chao_y - 6, trava, 1.0, 3.0)
		pen.linha(bx2 - 4, by + 10, bx1 + 4, chao_y - 6, trava, 1.0, 3.0)
		pen.retangulo(bx1, by + 4, bx2, by + 8, trava, 1.0, false)
		pen.retangulo(bx1, (by + chao_y) / 2, bx2, (by + chao_y) / 2 + 3, trava, 1.0, false)
		for xp in [bx1 + 2, bx2 - 2]:
			pen.retangulo(xp - 3, by - 20, xp + 3, chao_y, Color8(36, 22, 14), 1.0, false)
			pen.retangulo(xp - 2, by - 20, xp + 2, chao_y, Color8(104, 70, 42), 1.0, false)
		pen.linha(bx1 + 2, by - 16, bx2 - 2, by - 16, Color8(120, 84, 50), 1.0, 2.0)
		pen.retangulo(bx1 - 5, by, bx2 + 5, by + 5, Color8(132, 92, 54), 1.0, false)
		pen.linha(bx1 - 5, by, bx2 + 5, by, Color8(190, 144, 90), 1.0)
		pen.retangulo(bx1 - 5, by, bx2 + 5, by + 5, Color8(24, 16, 10), 1.0, true)
	# ===== ANDAIME ALTO de madeira (laje sólida com postes até o chão) =====
	for pl in plataformas:
		if pl.size() < 4 or int(pl[3]) != 1:
			continue
		var x1: float = pl[0]
		var x2: float = pl[1]
		var yt: float = pl[2]
		if x2 < vx - 40 or x1 > vx + vw + 40:
			continue
		var yb := yt + PLATAFORMA_ALT
		var ym := (yb + chao_y) / 2
		var trava := Color8(46, 30, 18)
		var passo := (x2 - x1 - 12) / maxf(1, roundf((x2 - x1) / 96.0))
		var ant := -1.0
		var xp := x1 + 6
		while xp <= x2 - 5.5:
			if ant >= 0:
				pen.linha(ant, yb + 6, xp, ym, trava, 1.0, 3.0)
				pen.linha(xp, yb + 6, ant, ym, trava, 1.0, 3.0)
				pen.linha(ant, ym, xp, chao_y - 4, trava, 1.0, 3.0)
				pen.linha(xp, ym, ant, chao_y - 4, trava, 1.0, 3.0)
				pen.linha(ant, ym, xp, ym, trava, 1.0, 2.0)
			pen.retangulo(xp - 3, yb, xp + 3, chao_y, Color8(30, 20, 14), 1.0, false)
			pen.retangulo(xp - 2, yb, xp + 2, chao_y, Color8(88, 58, 34), 1.0, false)
			ant = xp
			xp += passo
		pen.retangulo(x1 + 3, yt + 5, x2 + 3, yb + 5, Color.BLACK, 0.35, false)
		var c1 := Color8(132, 92, 54)
		var c2 := Color8(78, 52, 30)
		pen.retangulo_cores(x1, yt, x2, yb, c1, c1, c2, c2, 1.0)
		var xx := x1 + 18
		while xx < x2 - 4:
			pen.linha(xx, yt + 2, xx, yb - 1, trava, 1.0)
			xx += 18
		pen.linha(x1, yt + PLATAFORMA_ALT * 0.55, x2, yt + PLATAFORMA_ALT * 0.55, trava, 1.0)
		pen.linha(x1, yt + 1, x2, yt + 1, Color8(186, 140, 86), 1.0, 2.0)
		pen.retangulo(x1, yt, x2, yb, Color8(24, 16, 10), 1.0, true)


# ilhas de terra flutuantes (mão única, peças do Alex)
func _desenhar_ilhas(pen: Pen, vx: float, vw: float) -> void:
	for i in ilhas.size():
		var il: Array = ilhas[i]
		var pc := peca(il[2])
		if pc.is_empty():
			continue
		var w: float = pc[2] * PECA_ESC
		var h: float = pc[3] * PECA_ESC
		if il[0] + w / 2 < vx - 20 or il[0] - w / 2 > vx + vw + 20:
			continue
		pen.elipse(il[0] - w * 0.4, chao_y - 3, il[0] + w * 0.4, chao_y + 3, Color.BLACK, 0.18, false)
		peca_desenhar(il[2], il[0] - w / 2, il[1] - h * 0.1 + h, i % 2 == 1)

# passarelas de madeira (mão única): tábuas, corrimão de corda e postes
func _desenhar_pontes(pen: Pen, vx: float, vw: float) -> void:
	for p in pontes:
		var x1: float = p[0]
		var x2: float = p[1]
		var yt: float = p[2]
		if x2 < vx - 40 or x1 > vx + vw + 40:
			continue
		var yb := yt + 10
		var px := x1 + 10
		while px < x2:
			pen.retangulo(px - 3, yb, px + 3, chao_y, Color8(30, 20, 14), 1.0, false)
			pen.retangulo(px - 2, yb, px + 2, chao_y, Color8(84, 56, 34), 1.0, false)
			px += 96
		pen.retangulo(x1 + 3, yt + 5, x2 + 3, yb + 5, Color.BLACK, 0.35, false)
		var c1 := Color8(132, 92, 54)
		var c2 := Color8(78, 52, 30)
		pen.retangulo_cores(x1, yt, x2, yb, c1, c1, c2, c2, 1.0)
		var xx := x1 + 12
		while xx < x2 - 2:
			pen.linha(xx, yt + 2, xx + (int(xx / 12.0) % 2), yb - 1, Color8(46, 30, 18), 1.0)
			xx += 12
		pen.linha(x1, yt + 1, x2, yt + 1, Color8(186, 140, 86), 1.0, 2.0)
		pen.retangulo(x1, yt, x2, yb, Color8(24, 16, 10), 1.0, true)
		# corrimão de corda entre postes baixos
		var ant := -1.0
		var pp := x1 + 4
		while pp <= x2 - 4:
			pen.retangulo(pp - 1, yt - 16, pp + 1, yt, Color8(64, 42, 26), 1.0, false)
			if ant >= 0:
				var mx := (ant + pp) / 2
				pen.linha(ant, yt - 15, mx, yt - 11, Color8(120, 96, 64), 1.0)
				pen.linha(mx, yt - 11, pp, yt - 15, Color8(120, 96, 64), 1.0)
			ant = pp
			pp += 48


func _desenhar_plataformas(pen: Pen, vx: float, vy: float, vw: float) -> void:
	var h := PLATAFORMA_ALT
	for p in plataformas:
		if p.size() >= 4 and int(p[3]) == 1:
			continue          # o adarve já foi desenhado
		var x1: float = p[0]
		var x2: float = p[1]
		var yt: float = p[2]
		if x2 < vx - 40 or x1 > vx + vw + 40:
			continue
		var yb := yt + h
		if madeira:
			# andaime de madeira: dois postes até o chão e tábuas por cima
			for px in [x1 + 8, x2 - 8]:
				pen.retangulo(px - 3, yb, px + 3, chao_y, Color8(30, 20, 14), 1.0, false)
				pen.retangulo(px - 2, yb, px + 2, chao_y, Color8(84, 56, 34), 1.0, false)
			pen.linha(x1 + 8, yb + 4, x2 - 8, chao_y - 10, Color8(64, 42, 26), 1.0, 2.0)
			pen.retangulo(x1 + 3, yt + 5, x2 + 3, yb + 5, Color.BLACK, 0.35, false)
			var c1 := Color8(132, 92, 54)
			var c2 := Color8(78, 52, 30)
			pen.retangulo_cores(x1, yt, x2, yb, c1, c1, c2, c2, 1.0)
			var junta := Color8(46, 30, 18)
			var xx := x1 + 18
			while xx < x2 - 4:
				pen.linha(xx, yt + 2, xx, yb - 1, junta, 1.0)
				xx += 18
			pen.linha(x1, yt + h * 0.55, x2, yt + h * 0.55, junta, 1.0)
			pen.linha(x1, yt + 1, x2, yt + 1, Color8(186, 140, 86), 1.0, 2.0)
			pen.retangulo(x1, yt, x2, yb, Color8(24, 16, 10), 1.0, true)
		else:
			# laje de pedra do castelo, presa por duas correntes que somem no alto
			for ax in [x1 + 9, x2 - 9]:
				var cy := yt - 4
				while cy > vy - 10:
					pen.retangulo(ax - 2, cy - 5, ax + 2, cy, Color8(20, 18, 20), 1.0, false)
					pen.retangulo(ax - 1, cy - 4, ax + 1, cy - 1, Color8(96, 92, 98), 1.0, int(cy / 7.0) % 2 == 0)
					cy -= 7
			pen.retangulo(x1 + 3, yt + 5, x2 + 3, yb + 5, Color.BLACK, 0.35, false)
			var s1 := Color8(84, 74, 80)
			var s2 := Color8(40, 34, 38)
			pen.retangulo_cores(x1, yt, x2, yb, s1, s1, s2, s2, 1.0)
			var junta2 := Color8(26, 21, 24)
			var xs := x1 + 22
			while xs < x2 - 4:
				pen.linha(xs, yt + 3, xs, yb - 1, junta2, 1.0)
				xs += 22
			pen.linha(x1, yt + 1, x2, yt + 1, Color8(164, 150, 154), 1.0, 2.0)
			pen.retangulo(x1, yt, x2, yb, Color8(14, 10, 12), 1.0, true)
			# mísulas (apoios) nas pontas
			var mis := Color8(52, 44, 48)
			pen.triangulo(x1 + 3, yb, x1 + 17, yb, x1 + 3, yb + 10, mis, 1.0, false)
			pen.triangulo(x2 - 3, yb, x2 - 17, yb, x2 - 3, yb + 10, mis, 1.0, false)


# v1.14: ARENA DA CHAVE — no alto do forte, os guardiões surgem dos portais; com
# todos derrotados o selo do baú se quebra (a chave do portão está nele)
func _arena_chave() -> void:
	if chave_dados.is_empty() or bau_chave == null or not G.existe(bau_chave):
		return
	var ar: Array = chave_dados["arena"]
	var pl = instance_find("obj_player", 0)
	# (o forte inteiro: chegando pela corda Twilight pisa bem na borda)
	if arena_estado == "espera" and pl != null and not pl.morto and pl.x > ar[0] - 14 and pl.x < ar[1] + 16 and absf(pl.y - ar[2]) < 4:
		arena_estado = "luta"
		G.arena_chave = true
		var g: Array = chave_dados["guardioes"]
		var n := mini(g.size(), int(dif_valor([2, 3, 3, 3])))
		for k in n:
			var e = instance_create_depth(g[k][1], ar[2] - 1, 100, g[k][0])
			e.limite_x1 = ar[0] + 8
			e.limite_x2 = ar[1] - 8
			if "surgir_agora" in e:
				e.surgir_agora = true
				e.surgir_atraso = 8 + k * 20
			arena_inimigos.append(e)
		aviso_mostrar("GUARDIÕES DO BAÚ  ·  DERROTE-OS PARA QUEBRAR O SELO")
		G.camera_impact = maxf(G.camera_impact, 5)
		V117.conquista("escalador")      # v1.17: chegou ao alto do forte
	elif arena_estado == "luta":
		var vivos := 0
		for e in arena_inimigos:
			if G.existe(e) and not e.morrendo:
				vivos += 1
		if vivos == 0:
			arena_estado = "livre"
			G.arena_chave = false
			bau_chave.selado = false
			bau_chave.selo_quebra = 40
			aviso_mostrar("O SELO SE QUEBROU  ·  ABRA O BAÚ")
			som_em("sfx_portal", bau_chave.x, bau_chave.y, 0.9, 0)
			fx_em("faiscas_golpe", bau_chave.x, bau_chave.y - 16, 1.2, 1)
			G.camera_impact = maxf(G.camera_impact, 6)


# v1.14: o forte da chave, plataformas penduradas, pontes de corda, escadas de
# mão, cordas e correntes (a mesma arte da versão PC)
func _desenhar_escalar(pen: Pen, vx: float, vw: float) -> void:
	# ----- o forte: estandarte rasgado, corrimão de troncos e tochas -----
	if not chave_dados.is_empty():
		var ar: Array = chave_dados["arena"]
		var fx1: float = ar[0] - 8
		var fx2: float = ar[1] + 8
		var fy: float = ar[2]
		if fx2 > vx - 60 and fx1 < vx + vw + 60:
			var mx := fx1 + 4
			pen.retangulo(mx - 2, fy - 70, mx + 2, fy, Color8(40, 26, 16), 1.0, false)
			var ond := sin(t / 14.0) * 3
			pen.triangulo(mx + 2, fy - 68, mx + 30 + ond, fy - 62, mx + 2, fy - 44, Color8(120, 16, 18), 1.0, false)
			pen.triangulo(mx + 30 + ond, fy - 62, mx + 26 + ond * 1.4, fy - 48, mx + 2, fy - 44, Color8(120, 16, 18), 1.0, false)
			var xx := fx1 + 14
			while xx < fx1 + 60:
				pen.retangulo(xx - 1, fy - 18, xx + 1, fy, Color8(64, 42, 26), 1.0, false)
				xx += 22
			pen.linha(fx1 + 14, fy - 17, fx1 + 58, fy - 17, Color8(64, 42, 26), 1.0, 2.0)
			for k in 2:
				var tx := fx1 + 70 if k == 0 else fx2 - 14
				pen.retangulo(tx - 1, fy - 26, tx + 1, fy, Color8(50, 34, 20), 1.0, false)
				cenario_luz(tx, fy - 30, 40, 0.75 + 0.25 * sin(t / 5.0 + k * 3), Color8(255, 150, 60))
				desenhar_chamas(tx, fy - 26, 7, 13, t + k * 40, 0.85, k * 5)
	# ----- plataformas penduradas: tábuas presas por cordas (no forte ou numa forca) -----
	for i in suspensas.size():
		var s: Array = suspensas[i]
		var x1: float = s[0]
		var x2: float = s[1]
		var yt: float = s[2]
		var ya: float = s[3]
		if x2 < vx - 60 or x1 > vx + vw + 60:
			continue
		var bal := sin(t / 40.0 + i) * 1.5
		if s[4] >= 0:
			var px: float = s[4]
			pen.retangulo(px - 4, ya - 6, px + 4, chao_y, Color8(30, 20, 14), 1.0, false)
			pen.retangulo(px - 4, ya - 6, x2 + 4, ya, Color8(30, 20, 14), 1.0, false)
			pen.retangulo(px - 3, ya - 6, px + 3, chao_y, Color8(88, 58, 34), 1.0, false)
			pen.retangulo(px - 3, ya - 5, x2 + 3, ya - 1, Color8(96, 64, 38), 1.0, false)
			pen.linha(px, ya + 22, px + 24, ya, Color8(46, 30, 18), 1.0, 3.0)
		pen.linha(x1 + 4, ya, x1 + 4 + bal, yt, Color8(150, 120, 80), 1.0, 1.5)
		pen.linha(x2 - 4, ya, x2 - 4 + bal, yt, Color8(150, 120, 80), 1.0, 1.5)
		pen.retangulo(x1 + 2 + bal, yt + 4, x2 + 2 + bal, yt + 10, Color.BLACK, 0.3, false)
		madeira_tabuas(x1 + bal, yt, x2 + bal, yt + 7, i)
		pen.linha(x1 + bal, yt, x2 + bal, yt, Color8(186, 140, 86), 1.0)
		pen.retangulo(x1 + bal, yt, x2 + bal, yt + 7, Color8(24, 16, 10), 1.0, true)
	# ----- pontes de corda: tábuas soltas com a barriga no meio e os corrimãos -----
	for b in pontes_corda:
		var x1: float = b[0]
		var x2: float = b[1]
		var yt: float = b[2]
		if x2 < vx - 60 or x1 > vx + vw + 60:
			continue
		var w := x2 - x1
		for k in 2:
			var px := x1 if k == 0 else x2
			pen.retangulo(px - 3, yt - 22, px + 3, chao_y, Color8(30, 20, 14), 1.0, false)
			pen.retangulo(px - 2, yt - 22, px + 2, chao_y, Color8(88, 58, 34), 1.0, false)
		var xx := x1 + 2
		while xx < x2 - 2:
			var yy := yt + 3 * sin((xx - x1) / w * PI)
			var ct := Color8(110, 76, 44) if int(xx / 7) % 2 == 0 else Color8(94, 64, 38)
			pen.retangulo(xx, yy, xx + 5, yy + 4, ct, 1.0, false)
			pen.retangulo(xx, yy, xx + 5, yy + 4, Color8(30, 20, 12), 1.0, true)
			xx += 7
		var corda := Color8(150, 120, 80)
		var ax := x1
		var ay := yt
		var ahy := yt - 20
		for si in range(1, 13):
			var u := si / 12.0
			var bx := x1 + w * u
			var by := yt + 3 * sin(u * PI)
			var hy := yt - 20 + 7 * sin(u * PI)
			pen.linha(ax, ay, bx, by, corda, 1.0)
			pen.linha(ax, ahy, bx, hy, corda, 1.0)
			if si % 2 == 0:
				pen.linha(bx, hy, bx, by, corda, 1.0)
			ax = bx
			ay = by
			ahy = hy
	# ----- escadas de mão, cordas e correntes -----
	for i in escalar.size():
		var e: Array = escalar[i]
		var ex: float = e[0]
		var y1: float = e[1]
		var y2: float = e[2]
		if ex < vx - 30 or ex > vx + vw + 30:
			continue
		if e[3] == "escada":
			pen.retangulo(ex - 10, y1 - 8, ex - 6, y2, Color8(30, 20, 14), 1.0, false)
			pen.retangulo(ex + 6, y1 - 8, ex + 10, y2, Color8(30, 20, 14), 1.0, false)
			pen.retangulo(ex - 9, y1 - 8, ex - 7, y2, Color8(104, 70, 42), 1.0, false)
			pen.retangulo(ex + 7, y1 - 8, ex + 9, y2, Color8(104, 70, 42), 1.0, false)
			var yy := y2 - 8
			while yy > y1 - 4:
				pen.retangulo(ex - 7, yy - 1, ex + 7, yy + 2, Color8(30, 20, 14), 1.0, false)
				pen.linha(ex - 6, yy, ex + 6, yy, Color8(132, 92, 54), 1.0)
				yy -= 10
		elif e[3] == "corda":
			var bal := sin(t / 30.0 + i * 2) * 2
			pen.retangulo(ex - 7, y1 - 6, ex + 7, y1 - 2, Color8(40, 28, 18), 1.0, false)
			var ax := ex
			var ay := y1 - 2
			for si in range(1, 17):
				var u := si / 16.0
				var bx := ex + bal * u * u
				var by := lerpf(y1 - 2, y2, u)
				pen.linha(ax, ay, bx, by, Color8(70, 52, 32), 1.0, 3.5)
				pen.linha(ax - 0.5, ay, bx - 0.5, by, Color8(168, 134, 88), 1.0, 1.5)
				ax = bx
				ay = by
			var yy := y1 + 14
			while yy < y2 - 4:
				var u := (yy - y1) / (y2 - y1)
				var nx := ex + bal * u * u
				pen.elipse(nx - 3, yy - 2, nx + 3, yy + 2, Color8(120, 92, 58), 1.0, false)
				yy += 18
			pen.linha(ax, y2, ax - 2, y2 + 5, Color8(168, 134, 88), 1.0)
			pen.linha(ax, y2, ax + 2, y2 + 5, Color8(168, 134, 88), 1.0)
		else:
			var yy := y1 - 4
			while yy < y2:
				pen.retangulo(ex - 3, yy, ex + 3, yy + 6, Color8(20, 18, 20), 1.0, false)
				pen.retangulo(ex - 2, yy + 1, ex + 2, yy + 5, Color8(110, 106, 112), 1.0, int(yy / 7) % 2 == 0)
				yy += 7

# =====================================================================
#  v1.20 — PONTES QUE DESABAM e PISO FRÁGIL
#  Ponte: um abismo bem mais fundo que os outros (a câmera desce para
#  mostrá-lo) com uma ponte de PQ_TRECHOS trechos sólidos. Quando o herói
#  entra nela, um aviso (tremor, poeira, som) e a ponte começa a cair do
#  lado por onde ele entrou: a frente do desabamento corre um pouco mais
#  devagar que Twilight. Quem para, cai junto.
#  Piso frágil: laje de mão única sobre um buraco; treme enquanto o herói
#  está em cima e cai depois de FRAGIL_TEMPO quadros; volta mais tarde.
# =====================================================================
func _quedas_montar() -> void:
	var d := terreno_dados(G.room)
	G.cam_baixo_alvo = 0.0
	# o que ficava em cima de um buraco novo vai para a beira (baús, caixotes, armadilhas)
	for a in abismos:
		for tipo in ["obj_bau", "obj_caixote", "obj_barril", "obj_fogo_chao", "obj_viga_fogo", "obj_espinhos", "obj_nevoa_veneno", "obj_save_point"]:
			for o in todos(tipo):
				if o.x > a[0] - 20 and o.x < a[1] + 20 and o.y > chao_y - 60:
					o.x = a[0] - 50.0
					o.xstart = o.x
	for pq in d.get("pontes_queda", []):
		var x1: float = pq[0]
		var x2: float = pq[1]
		terreno_abrir(x1, x2, chao_y)
		terreno_limpar(x1, x2)
		# o que ficava em cima do vão vai para a beira (baú, caixote, armadilhas)
		for tipo in ["obj_bau", "obj_caixote", "obj_fogo_chao", "obj_viga_fogo", "obj_espinhos"]:
			for o in todos(tipo):
				if o.x > x1 - 24 and o.x < x2 + 24:
					o.x = x1 - 60.0
					o.xstart = o.x
		var w := (x2 - x1) / PQ_TRECHOS
		var segs: Array = []
		for i in PQ_TRECHOS:
			var b = terreno_bloco(x1 + i * w, x1 + (i + 1) * w, chao_y, chao_y + 10)
			segs.append({"x": x1 + i * w, "w": w, "inst": b, "estado": "firme", "t": 0.0, "dy": 0.0, "vy": 0.0, "trem": 0.0})
		pontes_q.append({"x1": x1, "x2": x2, "tipo": pq[2], "estado": "inteira", "t": 0.0, "frente": x1, "dir": 1.0, "segs": segs})
	for fr in d.get("frageis", []):
		var pl = terreno_ponte(fr[0], fr[1], fr[2])
		frageis.append({"x": fr[0], "w": fr[1] - fr[0], "y": fr[2], "inst": pl, "estado": "firme", "t": 0.0, "dy": 0.0, "vy": 0.0, "trem": 0.0})
	if not pontes_q.is_empty():
		cenario_carregar()


func _quedas_passo(dt: float) -> void:
	var p = instance_find("obj_player", 0)
	var vivo: bool = p != null and not p.morto
	var cam := 0.0
	for pq in pontes_q:
		var x1: float = pq.x1
		var x2: float = pq.x2
		if p != null and p.x > x1 - 190 and p.x < x2 + 190:
			cam = 78.0
		match pq.estado:
			"inteira":
				if vivo and absf(p.y - chao_y) < 4 and p.x > x1 + 30 and p.x < x2 - 30:
					pq.estado = "aviso"
					pq.t = 0.0
					# cai a partir do lado por onde o herói entrou
					pq.dir = 1.0 if p.x < (x1 + x2) / 2.0 else -1.0
					pq.frente = x1 if pq.dir > 0 else x2
					som("viga_aviso", 1, 0)
					som("pedra_desmorona" if pq.tipo == "pedra" else "dest_viga", 0.7, 0)
					aviso_mostrar("A PONTE ESTÁ DESABANDO  ·  CORRA!")
					G.camera_impact = maxf(G.camera_impact, 9)
					G.terremoto = maxf(G.terremoto, 24)
					G.vibrar(60)
			"aviso":
				pq.t += dt
				G.terremoto = maxf(G.terremoto, 8)
				if randf() < 0.6 * dt:
					fx_em("poeira", pq.frente + pq.dir * randf() * 80.0, chao_y + 6, 0.5)
				if pq.t >= PQ_AVISO:
					pq.estado = "caindo"
					pq.t = 0.0
			"caindo":
				pq.t += dt
				# um pouco mais lenta que a corrida do herói (3,6) e vai apertando
				pq.frente += pq.dir * minf(3.5, 3.05 + pq.t * 0.004) * dt
				G.terremoto = maxf(G.terremoto, 7)
				var resta := 0
				for s in pq.segs:
					if s.estado != "firme":
						continue
					var borda: float = s.x if pq.dir > 0 else s.x + s.w
					if (pq.frente - borda) * pq.dir >= 0:
						s.estado = "tremendo"
						s.t = 0.0
					else:
						resta += 1
				if resta == 0:
					pq.estado = "caida"
		for s in pq.segs:
			_trecho_passo(s, dt, 12.0, pq.tipo == "pedra")
	# ===== PISO FRÁGIL =====
	for f in frageis:
		match f.estado:
			"firme":
				var em_cima: bool = vivo and absf(p.y - f.y) <= 1.5 and p.velv >= 0 \
					and p.bbox_right >= f.x and p.bbox_left <= f.x + f.w
				if em_cima:
					if f.t <= 0:
						som_em("dest_quique", f.x + f.w / 2.0, f.y, 0.7)
					f.t += dt
					f.trem = randf_range(-1.2, 1.2) * minf(1.0, f.t / 12.0)
					if randf() < 0.4 * dt:
						fx_em("poeira", f.x + randf() * f.w, f.y + 8, 0.3)
					if f.t >= FRAGIL_TEMPO:
						f.estado = "caindo"
						f.vy = 0.6
						f.dy = 0.0
						f.t = 0.0
						if G.existe(f.inst):
							instance_destroy(f.inst)
						f.inst = null
						som_em("dest_pedra", f.x + f.w / 2.0, f.y, 0.8)
						fx_em("poeira", f.x + f.w / 2.0, f.y + 6, 0.8)
						G.camera_impact = maxf(G.camera_impact, 5)
				else:
					# saiu de cima a tempo: a laje se acalma devagar
					f.t = maxf(0.0, f.t - dt * 0.5)
					f.trem = 0.0
			"caindo":
				f.vy = minf(f.vy + 0.45 * dt, 14.0)
				f.dy += f.vy * dt
				f.t += dt
				if f.t >= FRAGIL_VOLTA and not (vivo and p.bbox_right >= f.x - 4 and p.bbox_left <= f.x + f.w + 4 and p.y > f.y - 4 and p.y < f.y + 90):
					f.estado = "voltando"
					f.t = 0.0
					f.dy = 0.0
					f.inst = terreno_ponte(f.x, f.x + f.w, f.y)
					fx_em("poeira", f.x + f.w / 2.0, f.y + 4, 0.5)
			"voltando":
				f.t += dt
				if f.t >= 24:
					f.estado = "firme"
					f.t = 0.0
	if p != null:
		G.cam_baixo_alvo = cam


# um trecho de ponte: treme "espera" quadros e despenca (o sólido some na hora da queda)
func _trecho_passo(s: Dictionary, dt: float, espera: float, pedra: bool) -> void:
	match s.estado:
		"tremendo":
			s.t += dt
			s.trem = randf_range(-1.6, 1.6)
			if randf() < 0.5 * dt:
				fx_em("poeira", s.x + randf() * s.w, chao_y + 8, 0.35)
			if s.t >= espera:
				s.estado = "caindo"
				s.vy = 0.8
				s.trem = 0.0
				if G.existe(s.inst):
					instance_destroy(s.inst)
				s.inst = null
				G.chao_sujo = true
				som_em("dest_pedra" if pedra else "dest_madeira", s.x + s.w / 2.0, chao_y, 0.75)
				fx_em("poeira", s.x + s.w / 2.0, chao_y + 4, 0.9)
				if pedra:
					fx_em("lascas", s.x + s.w / 2.0, chao_y + 10, 0.8)
				G.camera_impact = maxf(G.camera_impact, 6)
		"caindo":
			s.vy = minf(s.vy + 0.5 * dt, 15.0)
			s.dy += s.vy * dt
			if s.dy > PQ_FUNDO + 120:
				s.estado = "sumiu"


func _quedas_desenhar(pen: Pen, vx: float, vw: float) -> void:
	var fundo := G.room_height + PQ_FUNDO
	var filtro := pen.filtro
	for pq in pontes_q:
		var x1: float = pq.x1
		var x2: float = pq.x2
		if x2 < vx - 60 or x1 > vx + vw + 60:
			continue
		var pedra: bool = pq.tipo == "pedra"
		# ===== A RAVINA: começa atrás da rua e desce no escuro =====
		var topo := chao_y - 30
		pen.retangulo_cores(x1, topo, x2, chao_y + 70, Color8(26, 17, 22), Color8(26, 17, 22), Color8(12, 7, 10), Color8(12, 7, 10), 1.0)
		pen.retangulo_cores(x1, chao_y + 70, x2, fundo, Color8(12, 7, 10), Color8(12, 7, 10), Color.BLACK, Color.BLACK, 1.0)
		# camadas de rocha na parede do fundo (dão a sensação de profundidade)
		for k in 7:
			var yy := chao_y + 14 + k * 30
			var enc := 6.0 + k * 5.0
			pen.linha(x1 + enc, yy, x2 - enc, yy + sin(k * 1.7) * 3.0, Color8(52, 38, 44), 0.5 - k * 0.06, 2.0)
		# paredões dos dois lados: pedra quebrada entrando no vão
		var rocha := Color8(54, 42, 40)
		var rocha2 := Color8(30, 22, 24)
		for k in 14:
			var yy2 := topo + k * 22.0
			var pk := 16.0 - k * 0.8 + sin(k * 2.3) * 5.0
			pen.triangulo(x1, yy2, x1 + pk, yy2 + 9, x1, yy2 + 24, rocha if k < 4 else rocha2, 1.0, false)
			pen.triangulo(x2, yy2, x2 - pk, yy2 + 11, x2, yy2 + 24, rocha if k < 4 else rocha2, 1.0, false)
		pen.linha(x1 - 2, topo, x1 + 8, topo + 1, Color8(96, 82, 74), 1.0, 2.0)
		pen.linha(x2 - 8, topo + 1, x2 + 2, topo, Color8(96, 82, 74), 1.0, 2.0)
		# lá no fundo: o clarão do incêndio, névoa e brasas subindo
		pen.blend_add = true
		var pulsa := 0.5 + 0.5 * sin(t / 34.0 + x1)
		pen.elipse(x1 + 10, fundo - 150, x2 - 10, fundo - 30, Color8(255, 84, 26), 0.10 + 0.05 * pulsa, false)
		pen.elipse(x1 + 50, fundo - 110, x2 - 50, fundo - 50, Color8(255, 150, 60), 0.10 + 0.04 * pulsa, false)
		pen.elipse(x1 - 10, chao_y + 90, x2 + 10, chao_y + 150, Color8(120, 60, 150), 0.05, false)
		for k in 9:
			var f := fposmod(t / 260.0 + k / 9.0, 1.0)
			var bx := lerpf(x1 + 14, x2 - 14, fposmod(k * 0.618, 1.0)) + sin(t / 26.0 + k) * 6.0
			pen.circulo(bx, fundo - 60 - f * 230, 1.4, Color8(255, 160, 70), (1 - f) * 0.7, false)
		pen.blend_add = false

		# ===== A PONTE =====
		if pedra:
			_ponte_pedra_desenhar(pen, pq)
		else:
			_ponte_madeira_desenhar(pen, pq)
		# aviso: o tabuleiro racha em brasa pouco antes de ceder
		if pq.estado == "aviso":
			pen.blend_add = true
			var ka: float = clampf(pq.t / PQ_AVISO, 0, 1)
			pen.retangulo(x1, chao_y - 2, x2, chao_y + 4, Color8(255, 120, 40), 0.25 * ka * (0.6 + 0.4 * sin(t * 0.9)), false)
			pen.blend_add = false
	pen.filtro = filtro
	# ===== PISO FRÁGIL: lajes de pedra rachada sobre os buracos =====
	for f in frageis:
		if f.x + f.w < vx - 30 or f.x > vx + vw + 30 or f.estado == "caindo" and f.dy > 200:
			continue
		var a := 1.0
		if f.estado == "caindo":
			a = clampf(1.0 - f.dy / 200.0, 0, 1)
		elif f.estado == "voltando":
			a = clampf(f.t / 24.0, 0, 1)
		var fx := float(f.x) + float(f.trem)
		var fy := float(f.y) + float(f.dy)
		var risco: float = clampf(f.t / FRAGIL_TEMPO, 0, 1) if f.estado == "firme" else 0.0
		pen.retangulo(fx + 2, fy + 3, fx + f.w + 2, fy + 13, Color.BLACK, 0.3 * a, false)
		pen.retangulo_cores(fx, fy, fx + f.w, fy + 10, Color8(118, 108, 112), Color8(118, 108, 112), Color8(62, 54, 60), Color8(62, 54, 60), a)
		pen.retangulo(fx, fy, fx + f.w, fy + 2, Color8(150, 140, 142), a, false)
		# rachaduras (ficam em brasa conforme a laje cede)
		var cr := Color8(30, 22, 26).lerp(Color8(255, 110, 40), risco)
		pen.linha(fx + f.w * 0.28, fy + 1, fx + f.w * 0.36, fy + 9, cr, a, 1.0)
		pen.linha(fx + f.w * 0.36, fy + 5, fx + f.w * 0.5, fy + 3, cr, a, 1.0)
		pen.linha(fx + f.w * 0.66, fy, fx + f.w * 0.6, fy + 9, cr, a, 1.0)


# ponte de pedra: a peça "ponte" do cenário cortada em tiras, uma por trecho; cada
# tira treme e despenca com o seu trecho. O pilar do meio desce pelo abismo.
func _ponte_pedra_desenhar(pen: Pen, pq: Dictionary) -> void:
	if cen.is_empty() or cen_tex == null:
		return
	var pc: Dictionary = cen["pecas"]["ponte"]
	var pw: float = pc["w"]
	var ph: float = pc["h"]
	var x1: float = pq.x1
	var n: int = pq.segs.size()
	var s: float = pq.segs[0].w / (pw / 10.0)        # cada trecho = 1/10 da peça (um arco a cada 5)
	var y0 := chao_y - 4.0 * s                         # as ameias ficam acima do tabuleiro, atrás do herói
	pen.filtro = false
	# pilares: o do meio e os dois encontros, descendo no escuro
	for k in [0, 5, n]:
		var seg: Dictionary = pq.segs[clampi(k, 0, n - 1)]
		if seg.estado == "sumiu":
			continue
		var cxp: float = x1 + k * float(seg.w)
		var lw := 13.0 * s if k == 5 else 7.0 * s
		var px1: float = cxp - lw / 2.0 if k == 5 else (cxp if k == 0 else cxp - lw)
		var py := y0 + ph * s - 2 + float(seg.dy)
		var ap := clampf(1.0 - float(seg.dy) / 220.0, 0, 1)
		pen.retangulo_cores(px1, py, px1 + lw, py + 230, Color8(74, 72, 80), Color8(74, 72, 80), Color8(8, 6, 10), Color8(8, 6, 10), ap)
		for j in 6:
			pen.linha(px1, py + 12 + j * 22, px1 + lw, py + 12 + j * 22, Color8(40, 38, 46), 0.6 * ap * (1 - j / 7.0), 1.0)
	for i in n:
		var seg2: Dictionary = pq.segs[i]
		if seg2.estado == "sumiu":
			continue
		var a2 := clampf(1.0 - float(seg2.dy) / 240.0, 0, 1)
		var cor := Color.WHITE if seg2.estado == "firme" else Color8(255, 214, 196)
		pen.textura_parte(cen_tex, float(pc["x"]) + (i % 10) * pw / 10.0, pc["y"], pw / 10.0, ph,
			float(seg2.x) + float(seg2.trem), y0 + float(seg2.dy), s, s, cor, a2)


# ponte de madeira: tábuas, vigas por baixo e corrimão de corda; cada trecho cai com as suas
func _ponte_madeira_desenhar(pen: Pen, pq: Dictionary) -> void:
	var x1: float = pq.x1
	var x2: float = pq.x2
	var n: int = pq.segs.size()
	# os dois postes das pontas ficam de pé
	for px in [x1 - 3.0, x2 + 3.0]:
		pen.retangulo(px - 3, chao_y - 30, px + 3, chao_y + 4, Color8(30, 20, 14), 1.0, false)
		pen.retangulo(px - 2, chao_y - 30, px + 2, chao_y + 4, Color8(92, 62, 36), 1.0, false)
	for i in n:
		var seg: Dictionary = pq.segs[i]
		if seg.estado == "sumiu":
			continue
		var sx := float(seg.x) + float(seg.trem)
		var sy := chao_y + float(seg.dy)
		# a tábua gira um pouco enquanto cai
		var torto := float(seg.dy) * 0.06 * (1.0 if i % 2 == 0 else -1.0)
		# viga e escora por baixo
		pen.retangulo(sx + 2, sy + 7, sx + seg.w - 2, sy + 11, Color8(44, 28, 16), 1.0, false)
		if i % 3 == 1:
			pen.linha(sx + seg.w * 0.5, sy + 11, sx + seg.w * 0.5 + torto, sy + 34, Color8(58, 38, 22), 1.0, 3.0)
		madeira_tabuas(sx, sy + torto * 0.3, sx + seg.w + 0.5, sy + 8 + torto * 0.3, i * 2)
		pen.linha(sx, sy, sx + seg.w, sy + torto * 0.3, Color8(150, 110, 66), 0.8, 1.0)
		# corrimão de corda (atrás do herói) com um montante a cada dois trechos
		var cy := sy - 24 + sin((i + 0.5) / n * PI) * 5.0
		var cy2 := sy - 24 + sin((i + 1.5) / n * PI) * 5.0
		pen.linha(sx, cy, sx + seg.w, cy2 if seg.estado == "firme" else cy + 6, Color8(150, 120, 78), 1.0, 1.5)
		if i % 2 == 0:
			pen.linha(sx + seg.w, cy2, sx + seg.w, sy, Color8(120, 92, 58), 1.0, 1.5)
