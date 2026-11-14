class_name V117
extends RefCounted
# =====================================================================
#  V117 — v1.17 (o mesmo de scripts/scr_v117 da versão PC)
#   * SEQUÊNCIA DE GOLPES (QTE) no Carrasco e na Árvore
#   * ORBES DE VIDA (verdes) do Carrasco
#   * EFEITOS DE ESPADA: estilos de lâmina (cores) e os impactos
#   * PERFIL DO JOGADOR: nome (só nas conquistas), CONQUISTAS e RECOMPENSAS
#   * o MAPA das 18 fases, o dragão, o menu com fogo e as DICAS do carregamento
#  Funções de desenho usam o Pen direto (G.pen), sem depender da instância.
# =====================================================================

const A := GMObj.ACAO
const PERFIL_ARQ := "perfil.ini"
const PERFIL_NOME_MAX := 14
const MAPA_FASES := 18


# ---------------------------------------------------------------------
# SEQUÊNCIA DE GOLPES (QTE)
# ---------------------------------------------------------------------
# Quantos botões e quantos quadros (60 = 1 s) para cada um. O mesmo da versão
# PC (qte_parametros em scr_v117). Retorna [quantidade, quadros por botão].
static func qte_parametros(eh_boss: bool) -> Array:
	# v1.17: curva nivelada (a mesma da versão PC)
	if eh_boss:
		return [Lib.dif_valor([5, 6, 7, 8]), Lib.dif_valor([90, 72, 60, 50])]
	return [Lib.dif_valor([3, 4, 5, 5]), Lib.dif_valor([100, 84, 70, 60])]


# v1.19: cada sequência completada cura Twilight (fração da vida máxima).
# Soma com os 8% que o golpe finalizador já devolve. O mesmo da versão PC.
const QTE_CURA := 0.30


static func qte_curar(p) -> void:
	if p == null or not G.existe(p) or p.morto:
		return
	var ganho := minf(p.vida_max - p.vida, round(p.vida_max * QTE_CURA))
	p.vida += ganho
	p.cura_fx = maxf(p.cura_fx, 45)
	LibBase.som("sfx_cura", 0.9, 0)
	if ganho > 0 and G.lib != null:
		G.lib.aviso_mostrar("SEQUÊNCIA COMPLETA  ·  +" + str(int(ganho)) + " DE VIDA")


# os 4 botões que existem em todo lugar (teclado, controle e o toque)
static func qte_acoes() -> Array:
	return [A.ATACAR, A.ATAQUE_FORTE, A.PULAR, A.DEFENDER]


static func qte_iniciar(alvo):
	if G.existe_obj("obj_qte") or not G.existe(alvo):
		return null
	var q = G.criar(0, 0, -10050, "obj_qte")
	q.alvo = alvo
	var par := qte_parametros(alvo.eh_boss)
	var n := maxi(2, int(round(par[0])))
	q.tempo_botao = maxf(20.0, par[1])
	var ac := qte_acoes()
	var seq: Array = []
	for k in n:
		var a: int = ac[randi() % ac.size()]
		# nunca o mesmo botão 3 vezes seguidas
		if k >= 2 and seq[k - 1] == a and seq[k - 2] == a:
			a = ac[(ac.find(a) + 1 + randi() % 3) % ac.size()]
		seq.append(a)
	q.seq = seq
	alvo.em_qte = true
	alvo.finalizavel = false
	alvo.qte_pronto = false
	alvo.velh = 0.0
	alvo.empurrao = 0.0
	for av in G.todos("obj_aviso"):
		G.destruir(av)
	G.qte_alvo = alvo
	LibBase.som("sfx_finalizador", 0.8, 0)
	return q


static func qte_x_frente(alvo, px: float) -> float:
	var lado := signf(px - alvo.x)
	if lado == 0:
		lado = -1
	return alvo.bbox_right + 18.0 if lado > 0 else alvo.bbox_left - 18.0


# anel do tempo (frac: quanto resta, de 1 a 0)
static func desenhar_anel(px: float, py: float, r: float, esp: float, frac: float, cor: Color, alfa: float) -> void:
	var pen: Pen = G.pen
	var n := 48
	var m := maxi(1, int(round(n * clampf(frac, 0, 1))))
	pen.prim_comecar(GMObj.pr_trianglestrip)
	for i in m + 1:
		var a := 90.0 + 360.0 * i / n
		pen.prim_vertice(px + GMObj.lengthdir_x(r, a), py + GMObj.lengthdir_y(r, a), cor, alfa)
		pen.prim_vertice(px + GMObj.lengthdir_x(r - esp, a), py + GMObj.lengthdir_y(r - esp, a), cor, alfa)
	pen.prim_terminar()


# ---------------------------------------------------------------------
# v1.19: TRANSIÇÕES ENTRE TELAS — cortina escura em diagonal com a borda
# em brasa. O carregamento das fases a usa (entra pela esquerda, sai pela
# direita) e o véu revela a tela nova no menu, no mapa e no perfil.
# O mesmo de transicao_cortina_desenhar() em scr_menu (PC).
# ---------------------------------------------------------------------
# cobre k (0..1) da tela; da_direita = a cortina fica presa ao lado direito
static func transicao_cortina_desenhar(k: float, da_direita := false) -> void:
	if k <= 0:
		return
	var pen: Pen = G.pen
	var gw := G.gui_w
	var gh := G.gui_h
	var s := gh * 0.35                                   # inclinação da borda
	var e := -s / 2.0 + clampf(k, 0, 1) * (gw + s)       # meio da borda
	var sx := -1.0 if da_direita else 1.0                # espelho: x na tela = ox + sx * x
	var ox := gw if da_direita else 0.0
	var x0 := ox + sx * (-s)
	var xt := ox + sx * (e + s / 2.0)                    # borda no alto
	var xb := ox + sx * (e - s / 2.0)                    # borda embaixo
	var add_antes := pen.blend_add
	pen.blend_add = false
	pen.triangulo(x0, 0, xt, 0, xb, gh, Color.BLACK, 1.0, false)
	pen.triangulo(x0, 0, xb, gh, x0, gh, Color.BLACK, 1.0, false)
	if k >= 1:
		pen.blend_add = add_antes
		return
	# a brasa: faixas de luz à frente da borda, cada vez mais fracas
	var t := Time.get_ticks_msec() / 16.67
	var bd := [0.0, 5.0, 14.0, 28.0, 46.0]
	var ba := [0.55, 0.32, 0.18, 0.08]
	pen.blend_add = true
	for i in 4:
		var d1: float = sx * bd[i]
		var d2: float = sx * bd[i + 1]
		var c := Color8(255, 120, 40).lerp(Color8(150, 10, 10), i / 3.0)
		pen.triangulo(xt + d1, 0, xt + d2, 0, xb + d2, gh, c, ba[i], false)
		pen.triangulo(xt + d1, 0, xb + d2, gh, xb + d1, gh, c, ba[i], false)
	pen.linha(xt, 0, xb, gh, Color8(255, 190, 110), 0.9, 2)
	# faíscas soltando da borda e subindo
	for f in 22:
		var fy := fposmod(f * 0.6180339 - t * 0.006 * (1 + f % 3), 1.0) * gh
		var vida := fposmod(f * 0.37 + t * 0.013, 1.0)
		var fx := lerpf(xt, xb, fy / gh) + sx * (4 + vida * 46)
		var cf := Color8(255, 230, 160) if f % 4 == 0 else Color8(255, 120, 40)
		pen.circulo(fx, fy, 1.5 + (f % 3) * 0.8, cf, (1 - vida) * 0.9, false)
	pen.blend_add = add_antes


# a tela acabou de mudar: a cortina cobre tudo e sai para a direita revelando a nova
static func transicao_revelar(dur := 24.0) -> void:
	G.veu_dur = dur
	G.veu_t = 0.0


# desenhado pelo G depois de toda a GUI (camada própria, por cima de tudo)
static func transicao_veu_desenhar() -> void:
	if G.veu_t >= G.veu_dur:
		return
	var p := clampf(G.veu_t / maxf(1, G.veu_dur), 0, 1)
	transicao_cortina_desenhar(pow(1 - p, 3), true)     # sai rápido e freia no fim


# ---------------------------------------------------------------------
# ORBES DE VIDA
# ---------------------------------------------------------------------
static func orbs_vida_soltar(px: float, py: float, n: int, cura := 6.0) -> void:
	for i in n:
		var o = G.criar(px + randf_range(-10, 10), py + randf_range(-10, 10), -121, "obj_orb")
		o.tipo = "vida"
		o.valor = cura
		o.vx = randf_range(-3, 3)
		o.vy = randf_range(-4.8, -1.8)
		o.espera = 26.0 + i * 3


# ---------------------------------------------------------------------
# EFEITOS DE ESPADA
# ---------------------------------------------------------------------
static func espada_estilos() -> Array:
	return [
		{"id": "carmesim", "nome": "LÂMINA CARMESIM", "brilho": Color8(255, 46, 36), "meio": Color8(255, 120, 70), "miolo": Color8(255, 238, 214)},
		{"id": "violeta", "nome": "LUA VIOLETA", "brilho": Color8(140, 60, 255), "meio": Color8(255, 90, 210), "miolo": Color8(214, 232, 255)},
		{"id": "glacial", "nome": "LÂMINA GLACIAL", "brilho": Color8(30, 140, 255), "meio": Color8(120, 222, 255), "miolo": Color.WHITE},
		{"id": "dourada", "nome": "FÚRIA DOURADA", "brilho": Color8(255, 120, 10), "meio": Color8(255, 196, 50), "miolo": Color8(255, 250, 200)},
		{"id": "esmeralda", "nome": "RELÂMPAGO ESMERALDA", "brilho": Color8(70, 220, 30), "meio": Color8(196, 255, 70), "miolo": Color8(240, 255, 214)},
		{"id": "sombria", "nome": "CHAMA SOMBRIA", "brilho": Color8(150, 20, 90), "meio": Color8(210, 60, 200), "miolo": Color8(255, 205, 255)},     # v1.17: fogo do inferno (sem tinta preta)
	]


static func espada_estilo(eid: String) -> Dictionary:
	var l := espada_estilos()
	for e in l:
		if e.id == eid:
			return e
	return l[0]


static func espada_estilo_atual() -> Dictionary:
	if G.perfil.is_empty():
		perfil_carregar()
	return espada_estilo(G.perfil.espada_fx)


static func espada_estilo_liberado(eid: String) -> bool:
	if eid == "carmesim":
		return true
	for c in conquistas_lista():
		if c.rtipo == "espada" and c.rval == eid:
			return conquista_tem(c.id)
	return false


# a lua crescente do corte (o arco vem da tabela do golpe)
static func espada_fx_corte(px: float, py: float, d: float, a1: float, a2: float, r: float, forte: bool) -> void:
	var f = G.criar(px, py, -128, "obj_fx")
	f.tipo = "corte_lua"
	f.dir = d
	f.a1 = a1
	f.a2 = a2
	f.raio = r
	f.forte = forte
	f.tam = 1.25 if forte else 1.0
	f.fx_iniciar()


# impacto: nivel 0 comum, 1 pesado / crítico, 2 finalizador / sequência / combo
# v1.17: a lâmina em chamas explode em fogo no ponto do golpe (sem a tinta preta)
static func espada_fx_impacto(px: float, py: float, d: float, nivel: int, rajada := false) -> void:
	var lib = G.lib
	var tamanhos := [0.75, 1.05, 1.45]
	lib.fx_em("explosao_fogo", px, py, tamanhos[clampi(nivel, 0, 2)], d, -131)
	if nivel >= 1:
		lib.fx_em("corte_x", px, py, 1.0 if nivel == 1 else 1.3, d, -132)
	if rajada:
		lib.fx_em("rajada", px - d * 70, py, 1.0, d, -130)


# ---------------------------------------------------------------------
# RASTRO DE FOGO DA ESPADA (o mesmo da versão PC)
# ---------------------------------------------------------------------
# lâmina deste quadro no mundo: [cabo_x, cabo_y, ponta_x, ponta_y] ou []
static func lamina_mundo(s: GMSprite, img: float, px: float, py: float, xs: float, ys: float) -> Array:
	if s == null or not LaminaDados.D.has(s.nome):
		return []
	var d: Array = LaminaDados.D[s.nome]
	var q: Array = d[clampi(int(img), 0, d.size() - 1)]
	var k: float = s.k
	return [px + q[0] * xs / k, py + q[1] * ys / k, px + q[2] * xs / k, py + q[3] * ys / k]


# este quadro do golpe faz parte do CORTE?
static func golpe_quadro_fogo(g, i: int) -> bool:
	if g == null or i < 0 or i >= g.seq.size():
		return false
	match g.chave:
		"tremor", "queda":
			return i == 5 or i == 6
		"finalizador":
			return i == 7 or i == 8
		"ira":
			return i >= 2 and i <= 4
		"arremesso", "arremesso_chama":
			return false
	return g.seq[i].has("hit")


static func fogo_cor(e: Dictionary, k: float) -> Color:
	if k > 0.55:
		return (e.meio as Color).lerp(e.miolo, (k - 0.55) / 0.45)
	return (e.brilho as Color).lerp(e.meio, k / 0.55)


# a fita de fogo: amostras [cx, cy, px, py, t, vmax, ini]
static func fogo_rastro_desenhar(r: Array, e: Dictionary) -> void:
	var n := r.size()
	if n < 2:
		return
	var pen: Pen = G.pen
	var tt := GMObj.current_time() / 45.0
	pen.blend_add = true
	var i0 := 0
	while i0 < n:
		var i1 := i0 + 1
		while i1 < n and not r[i1][6]:
			i1 += 1
		if i1 - i0 >= 2:
			for cam in 3:
				pen.prim_comecar(GMObj.pr_trianglestrip)
				for i in range(i0, i1):
					var s: Array = r[i]
					var f := clampf(1 - s[4] / s[5], 0, 1)
					var dx: float = s[2] - s[0]
					var dy: float = s[3] - s[1]
					var sobe := (1 - f) * 7
					var trem := 0.06 + 0.09 * (0.5 + 0.5 * sin(tt + i * 1.7))
					var de := 0.25
					var ate := 1.14 + trem
					var ci: Color = e.brilho
					var co: Color = e.meio
					var ai := 0.12 * f
					var ao := 0.55 * f
					if cam == 1:
						de = 0.45
						ate = 1.05 + trem
						ci = e.meio
						co = fogo_cor(e, f)
						ai = 0.3 * f
						ao = f
					elif cam == 2:
						de = 0.78
						ate = 1.0
						ci = fogo_cor(e, f)
						co = e.miolo
						ai = 0.7 * pow(f, 1.2)
						ao = pow(f, 1.2)
					pen.prim_vertice(s[0] + dx * de, s[1] + dy * de - sobe * 0.4, ci, ai)
					pen.prim_vertice(s[0] + dx * ate, s[1] + dy * ate - sobe, co, ao)
				pen.prim_terminar()
		i0 = i1
	pen.blend_add = false


# línguas de fogo soltas: [x, y, vx, vy, v, vmax, r, s]
static func fogo_chamas_desenhar(c: Array, e: Dictionary) -> void:
	if c.is_empty():
		return
	var pen: Pen = G.pen
	pen.blend_add = true
	var tt := GMObj.current_time() / 70.0
	for item in c:
		var p: PackedFloat32Array = item
		var k := clampf(p[4] / p[5], 0, 1)
		var a := minf(1, (p[5] - p[4]) / 3.0) * minf(1, k * 1.7)
		var rr := p[6] * (0.5 + 0.5 * k)
		var bal := sin(tt + p[7]) * rr * 0.55
		var cor := fogo_cor(e, k)
		pen.circulo(p[0], p[1], rr * 1.6, cor, 0.4 * a, false)
		pen.triangulo(p[0] - rr, p[1], p[0] + rr, p[1], p[0] + bal, p[1] - rr * 2.9, cor, 0.9 * a, false)
		pen.circulo(p[0], p[1], rr, cor, 0.9 * a, false)
	pen.blend_add = false


# losango de luz entre dois pontos
static func fx_losango(x1: float, y1: float, x2: float, y2: float, w: float, cor: Color, alfa: float) -> void:
	var pen: Pen = G.pen
	var ang := GMObj.point_direction(x1, y1, x2, y2) + 90
	var mx := (x1 + x2) / 2.0
	var my := (y1 + y2) / 2.0
	var nx := GMObj.lengthdir_x(w, ang)
	var ny := GMObj.lengthdir_y(w, ang)
	pen.triangulo(x1, y1, mx + nx, my + ny, mx - nx, my - ny, cor, alfa, false)
	pen.triangulo(x2, y2, mx + nx, my + ny, mx - nx, my - ny, cor, alfa, false)


# a lua crescente (usada no corte e na amostra da tela de LÂMINAS)
static func lua_crescente(px: float, py: float, r: float, aw1: float, aw2: float, larg: float, e: Dictionary, k: float, mostra: float) -> void:
	var pen: Pen = G.pen
	var nseg := 18
	var ate := maxi(1, int(round(nseg * clampf(mostra, 0, 1))))
	var cam := [[1.9, e.brilho, 0.3, true], [1.0, e.meio, 0.7, true], [0.32, e.miolo, 0.95, true]]     # v1.17: todas aditivas
	for c in 3:
		var cl: Array = cam[c]
		var cor: Color = cl[1]
		pen.blend_add = cl[3]
		pen.prim_comecar(GMObj.pr_trianglestrip)
		for s in ate + 1:
			var f := float(s) / nseg
			var ang := lerpf(aw1, aw2, f)
			var gr: float = larg * cl[0] * pow(sin(PI * f), 0.8)
			var al: float = k * cl[2] * (0.25 + 0.75 * f)
			var rf := r + larg * 0.35 if c == 2 else r + gr * 0.35
			var rd := rf - gr if c == 2 else r - gr * 0.65
			pen.prim_vertice(px + GMObj.lengthdir_x(rf, ang), py + GMObj.lengthdir_y(rf, ang), cor, al)
			pen.prim_vertice(px + GMObj.lengthdir_x(rd, ang), py + GMObj.lengthdir_y(rd, ang), cor, al * 0.35)
		pen.prim_terminar()
	pen.blend_add = false


static func lamina_amostra(px: float, py: float, r: float, e: Dictionary, t: float, alfa: float) -> void:
	var ini := fmod(t * 4.0, 360.0)
	lua_crescente(px, py, r, ini, ini - 150, 13, e, alfa, 1.0)


# ---------------------------------------------------------------------
# PERFIL DO JOGADOR (perfil.ini; no teste automático, teste_perfil.ini)
# ---------------------------------------------------------------------
static func perfil_stats_nomes() -> Array:
	return ["inimigos", "javalis", "execucoes", "aparos", "orbs", "segredos", "sequencias", "fases", "maior_combo"]


static func perfil_carregar() -> void:
	G.perfil = {"nome": "", "espada_fx": "carmesim", "titulo": "", "conquistas": {}, "stats": {}, "sujo": false, "ultimo_slot": 0, "fase_max": 1}
	for s in perfil_stats_nomes():
		G.perfil.stats[s] = 0.0
	if not G.arquivo_existe(PERFIL_ARQ):
		return
	var c := G.ini_abrir(PERFIL_ARQ)
	G.perfil.nome = str(c.get_value("perfil", "nome", "")).substr(0, PERFIL_NOME_MAX)
	G.perfil.espada_fx = str(c.get_value("perfil", "espada", "carmesim"))
	G.perfil.titulo = str(c.get_value("perfil", "titulo", ""))
	G.perfil.ultimo_slot = int(c.get_value("perfil", "ultimo_slot", 0))     # v1.20: o progresso é do perfil
	G.perfil.fase_max = int(c.get_value("perfil", "fase_max", 1))
	for cq in conquistas_lista():
		var d := str(c.get_value("conquistas", cq.id, ""))
		if d != "":
			G.perfil.conquistas[cq.id] = d
	for s in perfil_stats_nomes():
		G.perfil.stats[s] = float(c.get_value("stats", s, 0.0))
	if not espada_estilo_liberado(G.perfil.espada_fx):
		G.perfil.espada_fx = "carmesim"


static func perfil_salvar() -> void:
	if G.perfil.is_empty():
		return
	var c := ConfigFile.new()
	c.set_value("perfil", "nome", G.perfil.nome)
	c.set_value("perfil", "espada", G.perfil.espada_fx)
	c.set_value("perfil", "titulo", G.perfil.titulo)
	c.set_value("perfil", "ultimo_slot", int(G.perfil.get("ultimo_slot", 0)))
	c.set_value("perfil", "fase_max", int(G.perfil.get("fase_max", 1)))
	for k in G.perfil.conquistas.keys():
		c.set_value("conquistas", k, G.perfil.conquistas[k])
	for s in perfil_stats_nomes():
		c.set_value("stats", s, G.perfil.stats.get(s, 0.0))
	G.ini_salvar(c, PERFIL_ARQ)
	G.perfil.sujo = false


static func perfil_salvar_se_mudou() -> void:
	if not G.perfil.is_empty() and G.perfil.sujo:
		perfil_salvar()


static func perfil_nome_exibir() -> String:
	if G.perfil.is_empty():
		perfil_carregar()
	return "JOGADOR" if G.perfil.nome == "" else G.perfil.nome


static func perfil_somar(stat: String, n := 1.0) -> void:
	if G.perfil.is_empty():
		perfil_carregar()
	var v: float = G.perfil.stats.get(stat, 0.0) + n
	G.perfil.stats[stat] = v
	G.perfil.sujo = true
	match stat:
		"inimigos":
			if v >= 1:
				conquista("primeiro_sangue")
			if v >= 100:
				conquista("ceifador")
		"javalis":
			if v >= 10:
				conquista("javalis")
		"execucoes":
			if v >= 10:
				conquista("executor")
		"aparos":
			if v >= 15:
				conquista("aparar")
		"orbs":
			if v >= 3000:
				conquista("colecionador")
		"segredos":
			if v >= 1:
				conquista("segredo")
		"sequencias":
			if v >= 1:
				conquista("sequencia")


static func perfil_maximo(stat: String, v: float) -> void:
	if G.perfil.is_empty():
		perfil_carregar()
	if v > G.perfil.stats.get(stat, 0.0):
		G.perfil.stats[stat] = v
		G.perfil.sujo = true
	if stat == "maior_combo" and v >= 20:
		conquista("combo20")


# ---------------------------------------------------------------------
# CONQUISTAS E RECOMPENSAS
# ---------------------------------------------------------------------
static func conquistas_lista() -> Array:
	return [
		{"id": "primeiro_sangue", "nome": "PRIMEIRO SANGUE", "desc": "Derrote o primeiro inimigo.", "rtipo": "orbs", "rval": 100},
		{"id": "ceifador", "nome": "CEIFADOR DE VALLACK", "desc": "Derrote 100 inimigos (somando todas as partidas).", "rtipo": "espada", "rval": "sombria"},
		{"id": "javalis", "nome": "CAÇADOR DE JAVALIS", "desc": "Derrote 10 javalis de guerra.", "rtipo": "orbs", "rval": 150},
		{"id": "escalador", "nome": "ALÉM DA PALIÇADA", "desc": "Suba ao forte de madeira da vila.", "rtipo": "orbs", "rval": 80},
		{"id": "chave", "nome": "CHAVE DO BASTIÃO", "desc": "Abra o portão trancado.", "rtipo": "orbs", "rval": 150},
		{"id": "segredo", "nome": "OLHOS DE CAÇADOR", "desc": "Encontre um muro secreto.", "rtipo": "orbs", "rval": 100},
		{"id": "furia", "nome": "IRA DESPERTA", "desc": "Ative o Modo Fúria.", "rtipo": "orbs", "rval": 100},
		{"id": "combo20", "nome": "TEMPESTADE DE AÇO", "desc": "Faça um combo de 20 golpes.", "rtipo": "espada", "rval": "glacial"},
		{"id": "aparar", "nome": "LÂMINA DE ESPELHO", "desc": "Apare 15 golpes.", "rtipo": "espada", "rval": "esmeralda"},
		{"id": "executor", "nome": "EXECUTOR", "desc": "Execute 10 inimigos com o finalizador.", "rtipo": "titulo", "rval": "O EXECUTOR"},
		{"id": "carrasco", "nome": "O CARRASCO CAIU", "desc": "Derrote o Carrasco de Vallack.", "rtipo": "espada", "rval": "dourada"},
		{"id": "intocavel", "nome": "INTOCÁVEL", "desc": "Derrote o Carrasco sem levar dano.", "rtipo": "titulo", "rval": "O INTOCÁVEL"},
		{"id": "sequencia", "nome": "MÃOS DE AÇO", "desc": "Complete uma sequência de golpes.", "rtipo": "orbs", "rval": 200},
		{"id": "arvore", "nome": "RAÍZES EM CINZAS", "desc": "Derrote a Árvore Amaldiçoada.", "rtipo": "espada", "rval": "violeta"},
		{"id": "perfeita", "nome": "SEQUÊNCIA PERFEITA", "desc": "Derrote a Árvore sem errar a sequência de golpes.", "rtipo": "titulo", "rval": "O IMPLACÁVEL"},
		{"id": "espada_max", "nome": "AÇO LENDÁRIO", "desc": "Evolua a espada até o nível máximo.", "rtipo": "orbs", "rval": 300},
		{"id": "fase1", "nome": "A VILA FOI VINGADA", "desc": "Conclua a fase 1.", "rtipo": "titulo", "rval": "HERÓI DA VILA"},
		{"id": "veloz", "nome": "CORRIDA CONTRA A MALDIÇÃO", "desc": "Conclua a fase 1 em menos de 15 minutos.", "rtipo": "orbs", "rval": 250},
		{"id": "dificil", "nome": "SANGUE DE AÇO", "desc": "Conclua a fase 1 no DIFÍCIL ou no EXTREMO.", "rtipo": "titulo", "rval": "SANGUE DE AÇO"},
		{"id": "extremo", "nome": "LENDA DE VALLACK", "desc": "Conclua a fase 1 no EXTREMO.", "rtipo": "titulo", "rval": "LENDA DE VALLACK"},
		{"id": "colecionador", "nome": "ALMAS SEM FIM", "desc": "Colete 3000 orbs (somando todas as partidas).", "rtipo": "titulo", "rval": "COLECIONADOR DE ALMAS"},
	]


static func conquista_dados(cid: String):
	for c in conquistas_lista():
		if c.id == cid:
			return c
	return null


static func conquista_tem(cid: String) -> bool:
	if G.perfil.is_empty():
		perfil_carregar()
	return G.perfil.conquistas.has(cid)


static func conquistas_feitas() -> int:
	if G.perfil.is_empty():
		perfil_carregar()
	return G.perfil.conquistas.size()


static func recompensa_texto(c: Dictionary) -> String:
	match c.rtipo:
		"orbs":
			return "+" + str(c.rval) + " ORBS"
		"espada":
			return "NOVA LÂMINA: " + espada_estilo(c.rval).nome
		"titulo":
			return "TÍTULO: " + str(c.rval)
	return ""


static func titulos_liberados() -> Array:
	var r: Array = []
	for c in conquistas_lista():
		if c.rtipo == "titulo" and conquista_tem(c.id):
			r.append(c.rval)
	return r


static func conquista_data_hoje() -> String:
	var d := Time.get_date_dict_from_system()
	return "%02d/%02d/%04d" % [d.day, d.month, d.year]


static func conquista(cid: String) -> bool:
	if G.perfil.is_empty():
		perfil_carregar()
	if conquista_tem(cid):
		return false
	var c = conquista_dados(cid)
	if c == null:
		return false
	G.perfil.conquistas[cid] = conquista_data_hoje()
	if c.rtipo == "orbs" and G.room != "rm_menu":
		G.orbs += c.rval
		G.orbs_fx = 20
	if c.rtipo == "titulo" and G.perfil.titulo == "":
		G.perfil.titulo = c.rval
	G.conquistas_fila.append({"id": cid, "t": 0.0})
	LibBase.som("sfx_important_message", 0.75, 0)
	# v1.18: TRAVADAS — gravar no meio da luta engasgava (e um combo libera
	# várias de uma vez). Agora grava uma vez só, 2 s depois (obj_sistema), ou
	# antes se o app for para o fundo (G._notification).
	G.perfil.sujo = true
	G.perfil_salvar_t = 120.0
	return true


# emblema dourado (escudo com uma estrela de 5 pontas)
static func conquista_emblema(px: float, py: float, r: float, alfa: float, t: float, apagado := false) -> void:
	var pen: Pen = G.pen
	var ouro := Color8(90, 80, 74) if apagado else Color8(236, 186, 84)
	var esc := Color8(34, 30, 30) if apagado else Color8(92, 24, 18)
	if not apagado:
		pen.blend_add = true
		pen.circulo(px, py, r * 1.45, Color8(255, 150, 60), alfa * (0.18 + 0.08 * sin(t / 9.0)), false)
		pen.blend_add = false
	pen.circulo(px, py, r, ouro, alfa, false)
	pen.circulo(px, py, r * 0.8, esc, alfa, false)
	for k in 5:
		var a := 90.0 + k * 72
		var tx := px + GMObj.lengthdir_x(r * 0.66, a)
		var ty := py + GMObj.lengthdir_y(r * 0.66, a)
		pen.triangulo(px, py, tx, ty, px + GMObj.lengthdir_x(r * 0.27, a + 36), py + GMObj.lengthdir_y(r * 0.27, a + 36), ouro, alfa, false)
		pen.triangulo(px, py, tx, ty, px + GMObj.lengthdir_x(r * 0.27, a - 36), py + GMObj.lengthdir_y(r * 0.27, a - 36), ouro, alfa, false)


# aviso de conquista no canto direito (chamado pelo obj_sistema no Draw GUI)
static func conquistas_toast_desenhar() -> void:
	if G.conquistas_fila.is_empty():
		return
	var c: Dictionary = G.conquistas_fila[0]
	c.t += G.dt_real
	var dur := 280.0
	if c.t >= dur:
		G.conquistas_fila.remove_at(0)
		return
	var d = conquista_dados(c.id)
	if d == null:
		G.conquistas_fila.remove_at(0)
		return
	var gw := G.gui_w
	var k := minf(clampf(c.t / 18.0, 0, 1), clampf((dur - c.t) / 18.0, 0, 1))
	var e := 1.0 - pow(1.0 - k, 3)
	var w := 500.0
	var h := 108.0
	var x2 := gw - 18 + (1 - e) * (w + 40)
	var x1 := x2 - w
	var y1 := 120.0
	G.lib.hud_faixa(x1, y1, x2, y1 + h, 0.97 * k)
	conquista_emblema(x1 + 56, y1 + h / 2, 30, k, GMObj.current_time() / 16.0)
	var ouro := Color8(236, 186, 84)
	var nome := perfil_nome_exibir()
	LibBase.txt(x1 + 100, y1 + 22, "CONQUISTA DESBLOQUEADA", GMObj.FONTE.MINI, ouro, k, 0, 1)
	LibBase.txt(x2 - 18, y1 + 22, nome, GMObj.FONTE.MINI, Color8(200, 180, 170), k, 2, 1, minf(1, 150 / maxf(1, LibBase.txt_largura(nome, GMObj.FONTE.MINI))))
	LibBase.txt_sombra(x1 + 100, y1 + 52, d.nome, GMObj.FONTE.PEQUENA, Color8(252, 244, 230), k, 0, 1, minf(1, (w - 120) / maxf(1, LibBase.txt_largura(d.nome, GMObj.FONTE.PEQUENA))))
	LibBase.txt(x1 + 100, y1 + 82, recompensa_texto(d), GMObj.FONTE.MINI, Color8(255, 140, 100), k, 0, 1)
	LibBase.desenho_resetar()


# ---------------------------------------------------------------------
# O MAPA (18 fases num caminho em chamas)
# ---------------------------------------------------------------------
static func fases_mapa() -> Array:
	return [
		{"nome": "A CAMINHO DO CASTELO", "desc": "A vila de Twilight arde na maldição de Vallack. Atravesse as ruas em chamas, enfrente o Carrasco e derrube a Árvore Amaldiçoada que guarda a estrada."},
		{"nome": "O SALÃO REAL EM RUÍNAS", "desc": "No coração do castelo, a maldição aguarda. O salão do rei virou ninho de monstros."},
		{"nome": "AS MURALHAS DE VALLACK", "desc": "As muralhas tomadas por esqueletos e arqueiros. Escale as torres sob a chuva de flechas."},
		{"nome": "O PÂNTANO DOS AFOGADOS", "desc": "Névoa venenosa e almas presas na lama. Nada sob a água está realmente morto."},
		{"nome": "A FLORESTA DE ESPINHOS", "desc": "Árvores que sangram e raízes que caçam. Dizem que a maldição nasceu aqui."},
		{"nome": "AS MINAS DE CINZA", "desc": "Túneis de carvão em brasa, onde os mineiros nunca pararam de cavar."},
		{"nome": "A CATEDRAL PARTIDA", "desc": "Vitrais quebrados e um coro de mortos. A fé de Vallack virou pó."},
		{"nome": "O CEMITÉRIO DOS REIS", "desc": "Tumbas abertas e reis sem descanso, ainda de coroa."},
		{"nome": "A PONTE DO ABISMO", "desc": "Uma ponte de correntes sobre o nada. Cada passo acorda o que mora embaixo."},
		{"nome": "AS TERRAS QUEIMADAS", "desc": "Campos de batalha que ainda ardem. O vento traz os gritos de guerras antigas."},
		{"nome": "A FORJA DOS CONDENADOS", "desc": "Ferreiros acorrentados forjam, dia e noite, as armas da maldição."},
		{"nome": "O LAGO DE GELO NEGRO", "desc": "Gelo escuro sobre um lago sem fundo. Os afogados olham de baixo."},
		{"nome": "A TORRE DO ALQUIMISTA", "desc": "Frascos, venenos e experimentos que escaparam das jaulas."},
		{"nome": "O LABIRINTO DE OSSOS", "desc": "Corredores erguidos com os restos de um exército inteiro."},
		{"nome": "O PORTO FANTASMA", "desc": "Navios sem tripulação atracados na névoa. Os sinos tocam sozinhos."},
		{"nome": "O SANTUÁRIO DE SYLLA", "desc": "O templo da chama sagrada, agora corrompida pela maldição."},
		{"nome": "O TRONO DE VALLACK", "desc": "O salão do rei que trouxe a maldição. Ele ainda espera."},
		{"nome": "O COVIL DO DRAGÃO", "desc": "Além do trono, sob o céu em chamas, o dragão de Vallack desperta. O chefão de toda a maldição."},
	]


static func fase_mapa_livre(i: int) -> bool:
	return i == 0


static func romano(n: int) -> String:
	var v := [10, 9, 5, 4, 1]
	var s := ["X", "IX", "V", "IV", "I"]
	var r := ""
	for i in 5:
		while n >= v[i]:
			r += s[i]
			n -= v[i]
	return r


static func moldura_dourada(x1: float, y1: float, x2: float, y2: float, alfa: float, brilho := 0.0) -> void:
	var pen: Pen = G.pen
	var ouro := Color8(196, 150, 70)
	var esc := Color8(40, 22, 16)
	pen.retangulo(x1 - 7, y1 - 7, x2 + 7, y2 + 7, esc, alfa, false)
	pen.retangulo(x1 - 5, y1 - 5, x2 + 5, y2 + 5, ouro, alfa, true)
	pen.retangulo(x1 - 2, y1 - 2, x2 + 2, y2 + 2, ouro, alfa, true)
	for cs in [Vector2(x1, y1), Vector2(x2, y1), Vector2(x1, y2), Vector2(x2, y2)]:
		var p: Vector2 = cs
		pen.retangulo(p.x - 8, p.y - 8, p.x + 8, p.y + 8, ouro, alfa, false)
		pen.retangulo(p.x - 4, p.y - 4, p.x + 4, p.y + 4, esc, alfa, false)
	if brilho > 0:
		pen.blend_add = true
		pen.retangulo(x1 - 10, y1 - 10, x2 + 10, y2 + 10, Color8(255, 120, 40), alfa * brilho * 0.5, true)
		pen.retangulo(x1 - 12, y1 - 12, x2 + 12, y2 + 12, Color8(255, 120, 40), alfa * brilho * 0.5, true)
		pen.blend_add = false


static func cadeado_grande(px: float, py: float, s: float, alfa: float) -> void:
	var pen: Pen = G.pen
	var ouro := Color8(206, 166, 84)
	var esc := Color8(34, 24, 18)
	pen.circulo(px, py - 10 * s, 13 * s, esc, alfa, false)
	pen.circulo(px, py - 10 * s, 13 * s, ouro, alfa, true)
	pen.circulo(px, py - 10 * s, 10 * s, ouro, alfa, true)
	pen.circulo(px, py - 10 * s, 8 * s, esc, alfa, false)
	pen.retangulo_arredondado(px - 17 * s, py - 4 * s, px + 17 * s, py + 22 * s, 5 * s, 5 * s, esc, alfa, false)
	pen.retangulo_arredondado(px - 15 * s, py - 2 * s, px + 15 * s, py + 20 * s, 4 * s, 4 * s, ouro, alfa, false)
	pen.retangulo(px - 15 * s, py + 12 * s, px + 15 * s, py + 20 * s, Color8(150, 108, 46), alfa, false)
	pen.circulo(px, py + 5 * s, 3.5 * s, esc, alfa, false)
	pen.retangulo(px - 1.5 * s, py + 5 * s, px + 1.5 * s, py + 13 * s, esc, alfa, false)


# o DRAGÃO de Vallack (silhueta animada ao lado da última fase)
static func dragao_desenhar(px: float, py: float, s: float, d: float, t: float, fogo := 0.0) -> void:
	var pen: Pen = G.pen
	var corpo := Color8(30, 10, 14)
	var membrana := Color8(58, 14, 20)
	var bater := sin(t * 0.16)
	var ombro_x := px + d * 2 * s
	var ombro_y := py - 8 * s
	var pontas := [Vector2(-34, -58), Vector2(-6, -70), Vector2(22, -52)]
	for asa in 2:
		var k := 0.8 if asa == 0 else 1.0
		var flap: float = bater * 0.85 if asa == 0 else bater
		var cor: Color = membrana.lerp(Color.BLACK, 0.45) if asa == 0 else membrana
		var ox := ombro_x + (d * 6 * s if asa == 0 else 0.0)
		var oy := ombro_y - (3 * s if asa == 0 else 0.0)
		var cx := ox + d * -10 * s * k
		var cy := oy + (-34 - 22 * flap) * s * k
		var ant_x := ox + d * 26 * s
		var ant_y := oy + 6 * s
		for p in 3:
			var pv: Vector2 = pontas[p]
			var qx := cx + d * pv.x * 0.6 * s * k
			var qy := cy + (pv.y * 0.45 - 40 * flap * (0.4 + 0.3 * p)) * s * k + 30 * s * k
			pen.triangulo(cx, cy, qx, qy, ant_x, ant_y, cor, 1.0, false)
			pen.linha(cx, cy, qx, qy, corpo, 1.0, 2 * s)
			ant_x = qx
			ant_y = qy
		pen.triangulo(cx, cy, ant_x, ant_y, ox - d * 30 * s, oy + 4 * s, cor, 1.0, false)
		pen.linha(ox, oy, cx, cy, corpo, 1.0, 4 * s)
		if asa == 0:
			pen.elipse(px - 38 * s, py - 13 * s, px + 34 * s, py + 11 * s, corpo, 1.0, false)
			var tx := px - d * 34 * s
			var ty := py
			for c in range(1, 10):
				var nx := px - d * (34 + c * 9) * s
				var ny := py + sin(t * 0.12 + c * 0.65) * c * 1.5 * s
				pen.linha(tx, ty, nx, ny, corpo, 1.0, (9 - c * 0.8) * s)
				tx = nx
				ty = ny
			pen.triangulo(tx, ty, tx - d * 12 * s, ty - 7 * s, tx - d * 10 * s, ty + 7 * s, corpo, 1.0, false)
			var hx := px + d * 30 * s
			var hy := py - 4 * s
			for c2 in range(1, 5):
				var nx2 := px + d * (30 + c2 * 8) * s
				var ny2 := py - (4 + c2 * 5 + sin(t * 0.1) * 2) * s
				pen.linha(hx, hy, nx2, ny2, corpo, 1.0, (11 - c2 * 1.4) * s)
				hx = nx2
				hy = ny2
			pen.elipse(hx - 8 * s, hy - 6 * s, hx + 8 * s, hy + 5 * s, corpo, 1.0, false)
			pen.triangulo(hx + d * 4 * s, hy - 4 * s, hx + d * 22 * s, hy + 1 * s, hx + d * 4 * s, hy + 5 * s, corpo, 1.0, false)
			pen.triangulo(hx - d * 2 * s, hy - 4 * s, hx - d * 14 * s, hy - 14 * s, hx - d * 6 * s, hy - 1 * s, corpo, 1.0, false)
			pen.blend_add = true
			pen.circulo(hx + d * 5 * s, hy - 2 * s, 1.8 * s, Color8(255, 170, 50), 0.9, false)
			pen.circulo(hx + d * 5 * s, hy - 2 * s, 5 * s, Color8(255, 170, 50), 0.3, false)
			if fogo > 0:
				var bx := hx + d * 20 * s
				var by := hy + 2 * s
				var cores := [Color8(200, 40, 10), Color8(255, 130, 30), Color8(255, 230, 140)]
				for f in 3:
					var w := (26 - f * 8) * s * fogo
					var comp := 120 * s * fogo * (1 - f * 0.2)
					pen.triangulo(bx, by, bx + d * comp, by - w + sin(t * 0.7 + f) * 4 * s, bx + d * comp, by + w + sin(t * 0.9 + f) * 4 * s, cores[f], 0.55 + 0.15 * f, false)
			pen.blend_add = false


# ---------------------------------------------------------------------
# MENU INICIAL MAIS VIVO (m = o obj_menu)
# ---------------------------------------------------------------------
static func menu_braseiros() -> Array:
	return [Vector2(G.gui_w * 0.57, G.gui_h - 50), Vector2(G.gui_w * 0.95, G.gui_h - 50)]


static func menu_tochas() -> Array:
	var mx := maxf(70, G.gui_w * 0.075)
	return [Vector2(mx - 42, 352), Vector2(mx + 372, 352)]


static func menu_fogo_atualizar(m, mx: float, my: float, mexeu: bool, clique: bool, dt: float) -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var q := G.cfg_qualidade
	var maximo := 60 if q == 0 else (130 if q == 1 else 220)
	m.ponteiro_x = lerpf(m.ponteiro_x, mx, 1 - pow(0.92, dt))
	m.ponteiro_y = lerpf(m.ponteiro_y, my, 1 - pow(0.92, dt))
	m.paralaxe_x = clampf((m.ponteiro_x - gw / 2.0) / (gw / 2.0), -1, 1)
	m.paralaxe_y = clampf((m.ponteiro_y - gh / 2.0) / (gh / 2.0), -1, 1)
	var cores := [Color8(255, 200, 90), Color8(255, 130, 40), Color8(255, 70, 30)]
	var parts: Array = m.fogo_part
	if mexeu and parts.size() < maximo:
		for i in 2:
			parts.append({"x": mx + randf_range(-5, 5), "y": my + randf_range(-5, 5), "vx": randf_range(-0.8, 0.8), "vy": randf_range(-2.2, -0.6), "v": randf_range(24, 48), "vmax": 48.0, "r": randf_range(1.2, 2.6), "cor": cores[randi() % 3]})
	if clique:
		m.fogo_ondas.append({"x": mx, "y": my, "t": 0.0})
		for i in (10 if q == 0 else 24):
			var ang := randf() * 360.0
			var v := randf_range(1.5, 6)
			parts.append({"x": mx, "y": my, "vx": GMObj.lengthdir_x(v, ang), "vy": GMObj.lengthdir_y(v, ang) - 1, "v": randf_range(30, 60), "vmax": 60.0, "r": randf_range(1.4, 3), "cor": cores[randi() % 3]})
	for b in menu_braseiros():
		var bv: Vector2 = b
		if randf() < 0.45 * dt and parts.size() < maximo:
			parts.append({"x": bv.x + randf_range(-20, 20), "y": bv.y - 26, "vx": randf_range(-0.5, 0.5), "vy": randf_range(-2.8, -1.1), "v": randf_range(50, 100), "vmax": 100.0, "r": randf_range(1, 2.3), "cor": cores[randi() % 3]})
	var tempo := GMObj.current_time() / 300.0
	for i in range(parts.size() - 1, -1, -1):
		var p: Dictionary = parts[i]
		p.x += (p.vx + sin(tempo + i) * 0.15) * dt
		p.y += p.vy * dt
		p.vy -= 0.012 * dt
		p.vx *= pow(0.98, dt)
		p.v -= dt
		if p.v <= 0:
			parts.remove_at(i)
	var ondas: Array = m.fogo_ondas
	for o in range(ondas.size() - 1, -1, -1):
		ondas[o].t += dt
		if ondas[o].t > 30:
			ondas.remove_at(o)


static func menu_fogo_desenhar(m, a: float, t: float, com_tochas: bool) -> void:
	if a <= 0:
		return
	var pen: Pen = G.pen
	var lib = G.lib
	for b in menu_braseiros():
		var bv: Vector2 = b
		var fl := 0.8 + 0.2 * sin(t / 7.0 + bv.x) * sin(t / 17.0 + bv.x * 2)
		pen.blend_add = true
		for cl in 5:
			pen.circulo(bv.x, bv.y - 36, 130 - cl * 24, Color8(255, 110, 30), 0.045 * fl * a, false)
		pen.blend_add = false
		var esc := Color8(22, 14, 12)
		pen.linha(bv.x - 26, bv.y + 4, bv.x - 36, bv.y + 46, esc, a, 4)
		pen.linha(bv.x + 26, bv.y + 4, bv.x + 36, bv.y + 46, esc, a, 4)
		pen.linha(bv.x, bv.y + 4, bv.x, bv.y + 46, esc, a, 4)
		lib.desenhar_chamas(bv.x, bv.y - 6, 30, 62 + 8 * sin(t / 11.0 + bv.x), t + bv.x, a, bv.x * 0.01, 2)
		pen.elipse(bv.x - 40, bv.y - 12, bv.x + 40, bv.y + 14, Color8(34, 22, 18), a, false)
		pen.elipse(bv.x - 40, bv.y - 12, bv.x + 40, bv.y + 2, Color8(70, 50, 40), a, true)
		pen.elipse(bv.x - 34, bv.y - 9, bv.x + 34, bv.y - 1, Color8(255, 120, 40), 0.7 * a, false)
	if com_tochas:
		var k := 0
		for tc in menu_tochas():
			var tv: Vector2 = tc
			var f2 := 0.8 + 0.2 * sin(t / 5.0 + k * 3) * sin(t / 13.0 + k)
			pen.blend_add = true
			for cl2 in 5:
				pen.circulo(tv.x, tv.y - 36, 115 - cl2 * 21, Color8(255, 120, 40), 0.04 * f2 * a, false)
			pen.blend_add = false
			pen.retangulo(tv.x - 10, tv.y + 26, tv.x + 10, tv.y + 34, Color8(26, 20, 18), a, false)
			pen.linha(tv.x, tv.y + 30, tv.x, tv.y + 4, Color8(26, 20, 18), a, 3)
			pen.triangulo(tv.x - 6, tv.y - 26, tv.x + 6, tv.y - 26, tv.x + 3, tv.y + 12, Color8(92, 58, 32), a, false)
			pen.triangulo(tv.x - 6, tv.y - 26, tv.x + 3, tv.y + 12, tv.x - 3, tv.y + 12, Color8(92, 58, 32), a, false)
			pen.retangulo(tv.x - 8, tv.y - 30, tv.x + 8, tv.y - 22, Color8(60, 40, 30), a, false)
			lib.desenhar_chamas(tv.x, tv.y - 28, 11, 34 + 6 * sin(t / 7.0 + k), t + k * 25, a, 3 + k, 2)
			k += 1
	pen.blend_add = true
	for item in m.fogo_part:
		var p: Dictionary = item
		pen.circulo(p.x, p.y, p.r, p.cor, clampf(p.v / (p.vmax * 0.5), 0, 1) * 0.9 * a, false)
	for item2 in m.fogo_ondas:
		var o: Dictionary = item2
		var ko: float = o.t / 30.0
		pen.circulo(o.x, o.y, 8 + 60 * ko, Color8(255, 140, 50), (1 - ko) * 0.7 * a, true)
		pen.circulo(o.x, o.y, 7 + 56 * ko, Color8(255, 140, 50), (1 - ko) * 0.7 * a, true)
		pen.circulo(o.x, o.y, 20 * (1 - ko), Color8(255, 140, 50), (1 - ko) * 0.25 * a, false)
	pen.blend_add = false


# ---------------------------------------------------------------------
# DICAS DA TELA DE CARREGAMENTO
# ---------------------------------------------------------------------
static func dicas_carregamento() -> Array:
	var l: Array = []
	for c in Lib.combos_lista():
		l.append({"ic": c.seq, "n": "COMBO  ·  " + str(c.nome), "t": c.desc})
	l.append({"ic": [A.PULAR, A.ATAQUE_FORTE], "n": "LANÇADOR", "t": "Quase juntos: o inimigo voa e Twilight sobe junto para o combo aéreo."})
	l.append({"ic": [A.ATACAR], "n": "CORTE AÉREO", "t": "No ar, até 3 cortes seguidos seguram o inimigo lá em cima."})
	l.append({"ic": [A.ATAQUE_FORTE], "n": "MERGULHO", "t": "PESADO no ar: Twilight despenca com a espada e abre o chão."})
	l.append({"ic": [A.ATAQUE_SALTO], "n": "RASTEIRA", "t": "Desliza por baixo dos golpes e joga os inimigos para cima."})
	l.append({"ic": [A.DEFENDER], "n": "APARAR E CONTRA-ATACAR", "t": "Defenda na hora exata do golpe: o inimigo fica tonto e Twilight revida sozinho."})
	l.append({"ic": [A.INTERAGIR], "n": "EXECUÇÃO", "t": "Inimigo com contorno vermelho: execute-o para recuperar vida e ganhar mais orbs."})
	l.append({"ic": qte_acoes(), "n": "SEQUÊNCIA DE GOLPES", "t": "Chefe cambaleando: execute e aperte cada botão na hora. Errou? Ele se solta e volta a atacar."})
	l.append({"ic": [A.ESQUIVA], "n": "ESQUIVA", "t": "No meio da rolagem nada acerta Twilight. Parado, ela vira um salto para trás."})
	l.append({"ic": [A.FURIA], "n": "MODO FÚRIA", "t": "Fúria cheia: golpes mais rápidos, metade do dano recebido e roubo de vida."})
	l.append({"ic": [A.ESPECIAL_3], "n": "MAGIA", "t": "Os especiais gastam a barra azul e quebram qualquer guarda."})
	l.append({"ic": [A.ATACAR], "n": "GOLPE CRÍTICO", "t": "Acertar com a ponta da espada causa dano crítico."})
	return l
