extends ObjInimigoBase
# =====================================================================
#  obj_boss_01 — ÁRVORE AMALDIÇOADA (boss da Fase 1)
#  dormindo -> despertar (diálogo; a arena se fecha) -> parado <-> atacando /
#  raizes / galho -> (66% e 33% da vida) nova fase -> ... -> morrendo
#  v1.12: SEM HORDAS. 3 FASES, cada uma com uma sequência fixa:
#    fase 1: bola de fogo, bola de fogo, raiz
#    fase 2: galho varredor, 2 bolas de fogo, 3 raízes
#    fase 3: galho mais rápido, onda de 5 raízes, 3 bolas de fogo em leque
# =====================================================================

var nome_boss := "ÁRVORE AMALDIÇOADA"
var titulo_boss := "GUARDIÃ DA ESTRADA DE VALLACK"
var escala := 1.0
var dano_fogo := 16.0
var dano_raiz := 14.0
var recarga_max := 110.0
var alcance_visao := 760.0
var alcance_fogo := 600.0
var barreira_x := 0.0
var arena_esq := 0.0
var arena_fechada := false
var y_chao := 0.0
var onda_espera := 210.0
var onda_tempo := 0.0
var onda_numero := 0
var invocacao_feita := false
var fase := 1
var ataque_n := 0
var rajada_desvios: Array = [0]
# v1.13: a MESMA árvore em todos os estados (antes ela virava outra árvore ao
# atacar e parecia sumir); na fase 3 a chama de Vallack toma a árvore
var spr_parado: GMSprite = Spr.spr_boss_01_parado
var spr_acao: GMSprite = Spr.spr_boss_01
var spr_ataque: GMSprite = Spr.spr_boss_01_atacando
var dialogo_fim_feito := false
var furia := false
var furia_fx := 0.0
var raiz_recarga := 240.0
var perto_tempo := 0.0
var rajada := 0
var acordado := false
var golpe_lancado := false
var hud_alpha := 0.0
var titulo_tempo := 0.0
var afundar := 0.0
var explosoes_t := 0.0
var orbs_soltas := false
var fala_t := 600.0
var sementes_lancadas := false
# v1.17: com 12% da vida ela CAMBALEIA e só cai pela SEQUÊNCIA DE GOLPES.
# Errou ou demorou: ela se recupera (25% da vida), empurra Twilight e volta a atacar.
const VULNERAVEL_PCT := 0.12
var vulneravel_t := 0.0
# v1.19: CHUVA DE BRASAS (fases 2 e 3): bolas de fogo caem do céu em volta de
# Twilight; uma marca brilha no chão antes de cada uma ([x, espera, y do chão])
const CHUVA_AVISO := 46.0
const CHUVA_INTERVALO := 9.0
const CHUVA_VEL := 5.4
var chuva_fila: Array = []
# v1.19: INVOCAÇÃO CONTRA QUEM SE APROVEITA DA LUTA: colado no tronco batendo sem
# parar, ou parado num canto onde os ataques não chegam ("procurando um bug")
var golpeada_t := 0.0           # > 0: levou golpe há pouco
var acampar_t := 0.0            # tempo de Twilight colado batendo no tronco
var canto_t := 0.0              # tempo de Twilight parado no mesmo lugar sem levar dano
var canto_x := -10000.0
var canto_y := -10000.0
var vida_jogador_ant := -1.0
var invocar_recarga := 600.0    # a primeira invocação só depois de ~10 s de luta
var invocacao_motivo := "perto"
const INVOCAR_PERTO := 240.0    # 4 s colado batendo
const INVOCAR_CANTO := 480.0    # 8 s parado sem levar dano
# v1.19: CHUVA DE FOGO nos momentos marcados (85%, 50% e 22% da vida) e de tempos em tempos
const CHUVA_MARCOS := [0.85, 0.5, 0.22]
var chuva_marco_i := 0
var chuva_grande_t := 1800.0    # a primeira por tempo: 30 s depois de acordar


func ev_create() -> void:
	super()
	eh_boss = true
	# v1.13: tamanho fixo (o mesmo da versão PC): com a câmera mais perto, a árvore
	# inteira cabe na tela; antes vinha da escala da instância na sala
	escala = 2.4
	image_xscale = escala
	image_yscale = escala
	mask_index = Spr.spr_mascara_boss
	dir = -1
	vida_max = round(1900 * dif_vida_boss())     # v1.17: 1200 -> 1900 (não morre fácil)
	vida = vida_max
	vida_atraso = vida
	usa_qte = true
	dano_fogo = maxf(1, round(16 * dif_dano_inimigo()))
	dano_raiz = maxf(1, round(14 * dif_dano_inimigo()))
	recarga_max = dif_boss_recarga()
	recarga = 70
	barreira_x = x + 130
	arena_esq = x - 760
	y_chao = chao_abaixo(x, y - 160)
	estado_ia = "dormindo"
	sprite_index = spr_parado
	image_index = 0
	image_speed = 0.35


func despertar() -> void:
	if acordado or estado_ia == "despertar" or morrendo:
		return
	estado_ia = "despertar"
	sprite_index = spr_acao
	image_index = 0
	image_speed = 1.2
	titulo_tempo = 210
	G.camera_impact = maxf(G.camera_impact, 14)
	som("sfx_rugido", 1, 0)
	musica("bgm_final_boss_phase1", 1500)     # v1.16: trilha do chefe final da fase 1
	if not arena_fechada:
		arena_fechada = true
		arena_fechar(arena_esq, barreira_x, y_chao, self)
	dialogo_iniciar("arvore_inicio")


func lancar_bola_fogo(alvo, desvio: float) -> void:
	var sx := x + dir * 30 * escala
	var sy := y - 36 * escala
	var b = instance_create_depth(sx, sy, depth - 5, "obj_bola_fogo")
	b.dano = dano_fogo
	b.alcance = alcance_fogo
	var tx := sx + dir * 400
	var ty := y_chao - 30
	if G.existe(alvo):
		tx = alvo.x
		ty = alvo.y - 34
		# DIFÍCIL e EXTREMO: mira um pouco à frente de quem corre
		if G.dificuldade >= DIF.DIFICIL:
			tx += alvo.velh * point_distance(sx, sy, tx, ty) / 4.6 * 0.7
	if signf(tx - sx) != dir:
		tx = sx + dir * 160
	var ang := point_direction(sx, sy, tx, ty) + desvio
	var vels := [4.6, 5.0, 5.5]
	var v: float = vels[clampi(fase - 1, 0, 2)]
	b.vx = lengthdir_x(v, ang)
	b.vy = lengthdir_y(v, ang)
	G.camera_impact = maxf(G.camera_impact, 5)
	som_em("fogo_bola", x, y, 0.9)


# NOVO ATAQUE — SEMENTES DA MALDIÇÃO. A árvore cospe sementes em arco; ao
# cair, cada uma finca uma raiz menor no chão. Há espaço entre os alvos para o
# jogador escolher se esquiva, bloqueio da semente ou salto sobre a raiz.
func lancar_sementes(alvo) -> void:
	var total := 3 if fase >= 3 else 2
	var sx := x + dir * 22 * escala
	var sy := y - 48 * escala
	for i in total:
		var deslocamento := (i - (total - 1) * 0.5) * 86.0
		var tx := sx + dir * (260 + i * 50)
		var ty := y_chao - 4
		if G.existe(alvo):
			tx = clampf(alvo.x + deslocamento + alvo.velh * 9, arena_esq + 42, barreira_x - 42)
			# A raiz nasce no chão da arena, não na altura momentânea do herói.
			ty = chao_abaixo(tx, y_chao - 130, 300)
		var tempo := clampf(absf(tx - sx) / 4.6, 40, 78)
		var b = instance_create_depth(sx, sy, depth - 5, "obj_bola_fogo")
		b.variante = "semente"
		b.raiz_ao_pousar = true
		b.gravidade = 0.18
		b.dano = maxf(1, round(dano_raiz * 0.72))
		b.raio_explosao = 34
		b.alcance = 760
		b.vx = (tx - sx) / tempo
		b.vy = (ty - sy - 0.5 * b.gravidade * tempo * tempo) / tempo
	G.camera_impact = maxf(G.camera_impact, 7)
	som_em("fogo_bola", x, y, 0.8)


func servos_vivos() -> int:
	var n := 0
	for e in todos("obj_inimigo_base"):
		if e.invocado and not e.morrendo and not e.eh_boss:
			n += 1
	return n


# ONDA de servos (v1.12: desligada; continua aqui para outras fases)
func invocar_servos() -> void:
	onda_numero += 1
	var lista := []
	for i in BOSS_ONDA_BESTAS:
		lista.append("obj_inimigo_01")
	for i in BOSS_ONDA_ARQUEIROS:
		lista.append("obj_inimigo_02")
	for i in dif_valor(BOSS_ONDA_ESQUELETOS):
		lista.append("obj_esqueleto")
	if onda_numero >= 2:
		for i in dif_valor(BOSS_ONDA_ARANHAS):
			lista.append("obj_aranha")
	var p = instance_find("obj_player", 0)
	var px: float = p.x if p != null else x - 300
	for i in lista.size():
		var o: String = lista[i]
		var sx: float
		if o == "obj_inimigo_02" or o == "obj_aranha":
			sx = arena_esq + 50 + randf() * 160 + ((i % 2) * 420)
		else:
			sx = arena_esq + 60 + randf() * (barreira_x - arena_esq - 120)
		if absf(sx - px) < 70:
			sx += -90 if sx < px else 90
		sx = clampf(sx, arena_esq + 40, barreira_x - 40)
		var sy := chao_abaixo(sx, y_chao - 120, 300)
		var e = instance_create_depth(sx, sy, 100, o)
		e.invocado = true
		e.surgir_agora = true
		e.surgir_atraso = i * 9
		e.dir = signf(px - sx)
		if e.dir == 0:
			e.dir = -1
		e.vida_max = maxf(1, round(e.vida_max * 0.7))
		e.vida = e.vida_max
		e.vida_atraso = e.vida
		if o == "obj_inimigo_02":
			e.recarga_max = 380
			e.recarga = randi_range(90, 300)
		if o == "obj_esqueleto":
			e.reerguido = true
		if o == "obj_aranha":
			e.recarga_teia = randi_range(120, 260)


# v1.19: GUARDAS DA RAIZ — poucos servos, escalando pelos portais perto de Twilight.
# "perto" (colado batendo no tronco): bestas e esqueleto dos dois lados dele;
# "canto" (parado onde os ataques não chegam): arqueiros, que alcançam o alto, e uma besta
func invocar_guardas(motivo: String) -> void:
	var p = instance_find("obj_player", 0)
	if p == null:
		return
	var lista: Array
	if motivo == "canto":
		lista = ["obj_inimigo_02", "obj_inimigo_01", "obj_inimigo_02"]
	else:
		lista = ["obj_inimigo_01", "obj_esqueleto"]
	if fase >= 2:
		lista.append("obj_inimigo_01" if motivo == "canto" else "obj_aranha")
	if G.dificuldade >= DIF.DIFICIL:
		lista.append("obj_inimigo_01")
	for i in lista.size():
		var o: String = lista[i]
		var lado := -1.0 if i % 2 == 0 else 1.0
		var sx: float = p.x + lado * (130 + 50 * floor(i / 2.0) + randf() * 40)
		# não nasce dentro do tronco: do lado da árvore, vai para o outro lado
		if sx > x - 110:
			sx = p.x - (150 + 40 * i)
		sx = clampf(sx, arena_esq + 40, barreira_x - 60)
		var sy := chao_abaixo(sx, y_chao - 120, 300)
		var e = instance_create_depth(sx, sy, 100, o)
		e.invocado = true
		e.surgir_agora = true
		e.surgir_atraso = 10 + i * 14          # os portais abrem um depois do outro
		e.dir = signf(p.x - sx)
		if e.dir == 0:
			e.dir = 1
		e.vida_max = maxf(1, round(e.vida_max * 0.8))
		e.vida = e.vida_max
		e.vida_atraso = e.vida
		if o == "obj_inimigo_02":
			e.recarga_max = 260
			e.recarga = randi_range(60, 140)
		if o == "obj_esqueleto":
			e.reerguido = true
		if o == "obj_aranha":
			e.recarga_teia = randi_range(120, 220)


# v1.19: CHUVA DE FOGO na arena inteira: as marcas acendem da árvore para a
# esquerda (dá para ler e correr) e as duas últimas caem em cima de Twilight
func chuva_grande() -> void:
	var n := 9 + fase * 3
	var x1 := arena_esq + 40
	var x2 := barreira_x - 40
	for i in n:
		var cx := x1 + (i + 0.5) / n * (x2 - x1) + randf_range(-14, 14)
		chuva_fila.append([cx, CHUVA_AVISO + 16 + (n - 1 - i) * 5, chao_abaixo(cx, y_chao - 60, 160)])
	var p = instance_find("obj_player", 0)
	if p != null:
		for k in 2:
			var cx2 := clampf(p.x + (0.0 if k == 0 else randf_range(-50, 50)), x1, x2)
			chuva_fila.append([cx2, CHUVA_AVISO + 16 + n * 5 + k * 22, chao_abaixo(cx2, y_chao - 60, 160)])
	som("sfx_rugido", 0.9, 0)
	som_em("boss_carga", x, y, 1)
	G.camera_impact = maxf(G.camera_impact, 12)
	G.terremoto = maxf(G.terremoto, 40)
	aviso_mostrar("CHUVA DE FOGO!  ·  FIQUE LONGE DAS MARCAS")


# Raízes saem do chão embaixo de Twilight. n = 1, 3 ou 5 (onda)
func raizes_lancar(n := 1) -> void:
	var p = instance_find("obj_player", 0)
	if p == null:
		return
	var onda := n >= 5
	for i in n:
		var rx: float = (p.x + 160 - i * 80) if onda else (p.x + (i - (n - 1) / 2.0) * 76)
		rx = clampf(rx, arena_esq + 30, barreira_x - 30)
		var r = instance_create_depth(rx, chao_abaixo(rx, y_chao - 100, 300), depth - 2, "obj_raiz")
		r.dano = dano_raiz
		r.atraso = i * 12 if onda else i * 8


# GALHO VARREDOR (fases 2 e 3): varre a arena rente ao chão. Pule ou role.
func galho_lancar() -> void:
	var xb := x - 40 * escala / 3.7
	var g = instance_create_depth(xb, y_chao, depth - 3, "obj_galho")
	g.dono = self
	g.dir = -1
	g.x_base = xb
	g.ponta = xb
	g.x_fim = arena_esq + 20
	g.y_chao = y_chao
	g.vel = 18.0 if fase >= 3 else 14.0      # v1.19: era 16 / 13
	g.dano = maxf(1, round(15 * dif_dano_inimigo()))


func chuva_lancar(n: int) -> void:
	var p = instance_find("obj_player", 0)
	var px: float = p.x if p != null else x - 300
	for i in n:
		# uma em cima de Twilight, as outras espalhadas dos dois lados
		var off := 0.0
		if i > 0:
			off = (1.0 if i % 2 == 1 else -1.0) * (60 + 70 * floor((i - 1) / 2.0)) + randf_range(-14, 14)
		var cx := clampf(px + off, arena_esq + 30, barreira_x - 30)
		chuva_fila.append([cx, CHUVA_AVISO + i * CHUVA_INTERVALO, chao_abaixo(cx, y_chao - 60, 160)])
	som_em("boss_carga", x, y, 0.9)


# v1.19: luta mais intensa: sequências mais longas e a chuva de brasas
func boss_proximo_ataque() -> String:
	var seq: Array
	match fase:
		1:
			seq = ["fogo", "fogo2", "raiz1", "fogo", "raiz3"]
		2:
			seq = ["galho", "fogo2", "sementes", "raiz3", "chuva", "fogo3"]
		_:
			seq = ["galho", "raiz5", "sementes", "fogo3", "chuva", "galho", "fogo3"]
	var a: String = seq[ataque_n % seq.size()]
	ataque_n += 1
	return a


func reagir_dano(_dano: float, _d: float, _forca: float) -> void:
	tremor = 3
	golpeada_t = 150.0          # v1.19: Twilight está batendo (conta para a invocação)
	if not acordado:
		despertar()
	# v1.17: só morre pela SEQUÊNCIA DE GOLPES (o finalizador dela é o golpe final)
	if vida <= 0 and qte_vencido:
		boss_morrer()
		return
	vida = maxf(1, vida)
	if estado_ia == "vulneravel":
		return
	if vida <= vida_max * VULNERAVEL_PCT:
		boss_vulneravel()
		return
	if fase == 1 and vida <= vida_max * 0.66:
		boss_fase(2)
	elif fase == 2 and vida <= vida_max * 0.33:
		boss_fase(3)


# v1.17: CAMBALEANDO: os ataques param, a árvore treme e espera a sequência de golpes
func boss_vulneravel() -> void:
	estado_ia = "vulneravel"
	vulneravel_t = 0
	finalizavel = true
	qte_pronto = true
	chuva_fila.clear()
	for r in todos("obj_raiz"):
		instance_destroy(r)
	for g in todos("obj_galho"):
		instance_destroy(g)
	for b in todos("obj_bola_fogo"):
		if not b.explodindo:
			instance_destroy(b)
	sprite_index = spr_acao
	image_index = 0
	image_speed = 0.35
	tremor = 4
	G.camera_impact = maxf(G.camera_impact, 16)
	camera_lenta(30, 0.45)
	som("sfx_rugido", 0.8, 0)
	G.vibrar(80)
	aviso_mostrar("A ÁRVORE CAMBALEIA  ·  EXECUTE A SEQUÊNCIA DE GOLPES!")


# v1.17: a árvore se recupera (errou a sequência ou demorou): volta com 25% da
# vida, solta uma onda que empurra Twilight e ataca de novo
func boss_recuperar() -> void:
	finalizavel = false
	qte_pronto = false
	vida = maxf(vida, round(vida_max * 0.25))
	vida_atraso = vida
	estado_ia = "transicao"
	sprite_index = spr_acao
	image_index = 0
	image_speed = 1
	recarga = 40
	tempo_invencivel = 60
	furia = true
	furia_fx = 90
	G.camera_impact = maxf(G.camera_impact, 20)
	G.terremoto = maxf(G.terremoto, 30)
	som("sfx_rugido", 1, 0)
	fx_em("onda_chao", x - 60, y_chao, 2)
	var p = instance_find("obj_player", 0)
	if p != null and not p.morto:
		var forte := absf(p.x - x) < 420
		p.levar_dano(dano_raiz if forte else 1.0, x, false, 12 if forte else 6, self)
	aviso_mostrar("A ÁRVORE SE RECUPEROU!")


func qte_falhou() -> void:
	boss_recuperar()


# Troca de fase: rugido, os ataques somem e a árvore fica invulnerável
func boss_fase(n: int) -> void:
	fase = n
	furia = true
	furia_fx = 90
	ataque_n = 0
	recarga_max = round(dif_boss_recarga() * (0.5 if n >= 3 else 0.66))     # v1.19: era 0,62 / 0,8
	raiz_recarga = 200
	chuva_fila.clear()
	perto_tempo = 0
	for r in todos("obj_raiz"):
		instance_destroy(r)
	for g in todos("obj_galho"):
		instance_destroy(g)
	for b in todos("obj_bola_fogo"):
		if not b.explodindo:
			instance_destroy(b)
	estado_ia = "transicao"
	if n >= 3:
		spr_parado = Spr.spr_boss_fogo_parado
		spr_acao = Spr.spr_boss_fogo
		spr_ataque = Spr.spr_boss_fogo_atacando
	sprite_index = spr_acao
	image_index = 0
	image_speed = 1
	tempo_invencivel = 90
	G.camera_impact = maxf(G.camera_impact, 20)
	G.terremoto = maxf(G.terremoto, 40)
	camera_lenta(40, 0.45)
	som("sfx_rugido", 1, 0)
	aviso_mostrar("A ÁRVORE AMALDIÇOADA SE ENFURECEU!" if n == 2 else "A CHAMA DE VALLACK TOMA A ÁRVORE!")
	dialogo_iniciar("arvore_fase2" if n == 2 else "arvore_fase3")


func boss_morrer() -> void:
	morrendo = true
	estado_ia = "morrendo"
	morte_tempo = 0
	morte_t = 0
	evaporar = 0
	evaporar_tam = 4.2
	sprite_index = spr_acao
	image_index = 0
	image_speed = 0.8
	G.camera_impact = 26
	G.inimigos_derrotados += 1
	impacto(14)
	camera_lenta(90, 0.3)
	som("sfx_rugido", 1, 0)
	musica("", 2500)     # v1.16: chefe derrotado: a trilha some (fade-out)
	V117.conquista("arvore")     # v1.17
	finalizavel = false
	qte_pronto = false
	chuva_fila.clear()
	G.vibrar(250)
	for r in todos("obj_raiz"):
		instance_destroy(r)
	for g in todos("obj_galho"):
		instance_destroy(g)
	for e in todos("obj_inimigo_base"):
		if e.invocado and not e.morrendo and not e.eh_boss:
			if e.ativo:
				e.inimigo_morrer(1, false)
			else:
				instance_destroy(e)


func ev_step() -> void:
	var dt := G.dt
	if tempo_invencivel > 0:
		tempo_invencivel = maxf(0, tempo_invencivel - dt)
	if flash_dano > 0:
		flash_dano -= dt
	if barra_tempo > 0:
		barra_tempo -= dt
	if titulo_tempo > 0:
		titulo_tempo -= dt
	if furia_fx > 0:
		furia_fx -= dt
	tremor = maxf(0, tremor - 0.3 * dt)
	hud_alpha = lerp_dt(hud_alpha, 1.0 if ((acordado or estado_ia == "despertar") and not morrendo) else 0.0, 0.08)
	image_xscale = escala
	image_yscale = escala
	# v1.17: presa na SEQUÊNCIA DE GOLPES: treme e espera (o obj_qte comanda)
	if em_qte and not morrendo:
		tremor = maxf(tremor, 1.5)
		image_speed = 0.2
		return
	# ===== MORTE: brasas, tremor, afunda e evapora na fumaça da maldição =====
	if morrendo:
		morte_tempo += dt
		tremor = 3
		explosoes_t -= dt
		if explosoes_t <= 0 and morte_tempo < 150:
			explosoes_t = 14
			var ex := x + randf_range(-30, 30) * escala / 2.0
			var ey := y - randf_range(15, 80) * escala
			fx_em("faiscas_golpe", ex, ey, 1.6, choose([-1.0, 1.0]))
			fx_em("brasas", ex, ey, 1.5)
			som_em(choose(["fogo_explosao", "hit_3"]), x, y, 0.6)
			G.camera_impact = maxf(G.camera_impact, 8)
		if G.cfg_qualidade > 0 and randf() < 0.4 * dt:
			var f = instance_create_depth(x + randf_range(-45, 45) * escala / 3.0, y - randf_range(20, 85) * escala, depth - 5, "obj_fagulha")
			f.cor = choose([Color8(255, 120, 30), Color8(255, 60, 40), Color8(255, 210, 90)])
		if morte_tempo > 45 and not dialogo_fim_feito:
			dialogo_fim_feito = true
			dialogo_iniciar("arvore_fim")
		if morte_tempo > 90 and not orbs_soltas:
			orbs_soltas = true
			orbs_soltar(x - 40, y - 60, ORBS_BOSS)
		if morte_tempo > 110:
			afundar = minf(afundar + 0.35 * dt, 34)
		if inimigo_evaporar(dt, 110, 240):
			aviso_mostrar("O GUARDIÃO CAIU  ·  O CAMINHO ESTÁ LIVRE")
			G.camera_impact = 10
			arena_abrir(self)
			progresso_marcar()
			instance_destroy()
		return
	var p = instance_find("obj_player", 0)
	var tem_alvo: bool = p != null and not p.morto
	var dx := 0.0
	var dy := 0.0
	if tem_alvo:
		dx = p.x - x
		dy = p.y - y
	var adx := absf(dx)
	# o boss só desperta/ataca quando já aparece na tela
	var na_tela := bbox_left < G.view_x + G.view_w - 30 and bbox_right > G.view_x + 30
	if acordado and tem_alvo and dx != 0 and estado_ia != "atacando":
		dir = signf(dx)
	# v1.19: CHUVA DE BRASAS: cada marca no chão vira uma bola de fogo caindo do céu
	for c in range(chuva_fila.size() - 1, -1, -1):
		var ch: Array = chuva_fila[c]
		ch[1] -= dt
		if ch[1] > 0:
			continue
		var b = instance_create_depth(ch[0] + randf_range(-8, 8), G.view_y - 24, depth - 5, "obj_bola_fogo")
		b.dano = dano_fogo
		b.alcance = 2000
		b.vx = randf_range(-0.4, 0.4)
		b.vy = CHUVA_VEL + fase * 0.4
		som_em("fogo_bola", ch[0], y_chao, 0.5)
		chuva_fila.remove_at(c)
	# v1.19: fase 3: a chama de Vallack faz chover brasas na arena (só enfeite)
	if fase >= 3 and acordado and randf() < 0.25 * dt:
		fx_em("brasas", G.view_x + randf() * G.view_w, G.view_y + randf() * 120, 0.8)
	# raízes: sempre que Twilight fica colado no tronco
	if acordado and tem_alvo:
		if raiz_recarga > 0:
			raiz_recarga -= dt
		if adx < 150:
			perto_tempo += dt
		else:
			perto_tempo = maxf(0, perto_tempo - dt)
		if raiz_recarga <= 0 and perto_tempo > 70 and estado_ia == "parado" and not instance_exists("obj_raiz"):
			estado_ia = "raizes"
			sprite_index = spr_acao
			image_index = 0
			image_speed = 1.3
			raizes_lancar(3 if fase >= 2 else 1)
			raiz_recarga = 170.0 if fase >= 2 else 240.0     # v1.19: pune mais rápido quem fica colado
			perto_tempo = 0
			G.camera_impact = maxf(G.camera_impact, 6)
	# v1.19: INVOCAÇÃO contra quem se aproveita da luta: colado no tronco batendo
	# sem parar, ou parado num lugar onde os ataques não chegam (procurando um "bug")
	if acordado and tem_alvo and not finalizavel:
		if golpeada_t > 0:
			golpeada_t -= dt
		if invocar_recarga > 0:
			invocar_recarga -= dt
		if adx < 190 and golpeada_t > 0:
			acampar_t += dt
		else:
			acampar_t = maxf(0, acampar_t - dt * 0.25)
		if Vector2(p.x, p.y).distance_to(Vector2(canto_x, canto_y)) > 90:
			canto_x = p.x
			canto_y = p.y
			canto_t = 0
		else:
			canto_t += 2 * dt if dy < -170 else dt      # no alto, longe do chão da arena, conta em dobro
		if vida_jogador_ant >= 0 and p.vida < vida_jogador_ant:
			canto_t = 0          # está sendo acertado: não é esconderijo
		vida_jogador_ant = p.vida
		var motivo := "perto" if acampar_t >= INVOCAR_PERTO else ("canto" if canto_t >= INVOCAR_CANTO else "")
		if motivo != "" and invocar_recarga <= 0 and estado_ia == "parado" and servos_vivos() < 2 and not instance_exists("obj_qte"):
			estado_ia = "invocando"
			invocacao_feita = false
			invocacao_motivo = motivo
			sprite_index = spr_acao
			image_index = 0
			image_speed = 1.0
			acampar_t = 0
			canto_t = 0
			invocar_recarga = 960.0 - fase * 120.0          # 16 / 14 / 12 s entre uma e outra
			tremor = 3
			G.camera_impact = maxf(G.camera_impact, 12)
			G.terremoto = maxf(G.terremoto, 24)
			som("sfx_rugido", 0.9, 0)
			fala_balao(self, "Acha que pode se esconder de mim?" if motivo == "canto" else "Servos... protejam a raiz!", Color8(150, 20, 20), 150)
			aviso_mostrar("A ÁRVORE CONVOCA SEUS SERVOS!")
	match estado_ia:
		"dormindo":
			if tem_alvo and na_tela and p.x > arena_esq + 70 and absf(dy) < 320:
				despertar()
		# v1.17: CAMBALEANDO (12% da vida): espera a sequência; se demorar, se recupera
		"vulneravel":
			vulneravel_t += dt
			tremor = maxf(tremor, 1.2)
			if image_index >= image_number - 1:
				image_index = image_number - 2
			if vulneravel_t >= 420:
				boss_recuperar()
		"parado":
			if sprite_index != spr_parado:
				sprite_index = spr_parado
				image_index = 0
			image_speed = 1.4 if furia else 1.0
			if recarga > 0:
				recarga -= dt
			# v1.19: CHUVA DE FOGO nos momentos marcados (85%, 50%, 22% da vida) e de tempos em tempos
			if chuva_grande_t > 0:
				chuva_grande_t -= dt
			var pede_chuva: bool = (chuva_marco_i < CHUVA_MARCOS.size() and vida <= vida_max * CHUVA_MARCOS[chuva_marco_i]) or chuva_grande_t <= 0
			if pede_chuva and tem_alvo and na_tela and chuva_fila.is_empty():
				while chuva_marco_i < CHUVA_MARCOS.size() and vida <= vida_max * CHUVA_MARCOS[chuva_marco_i]:
					chuva_marco_i += 1
				chuva_grande_t = 1080.0 if fase >= 3 else (1440.0 if fase == 2 else 1800.0)     # 18 / 24 / 30 s
				estado_ia = "chuva"
				sprite_index = spr_acao
				image_index = 0
				image_speed = 1.0
				chuva_grande()
			elif tem_alvo and na_tela and adx <= alcance_visao and absf(dy) < 320 and recarga <= 0:
				var atq := boss_proximo_ataque()
				if atq.begins_with("fogo"):
					estado_ia = "atacando"
					golpe_lancado = false
					rajada = 3 if atq == "fogo3" else (2 if atq == "fogo2" else 1)
					rajada_desvios = [-10, 0, 10] if rajada == 3 else ([-5, 5] if rajada == 2 else [0])
					sprite_index = spr_ataque
					image_index = 0
					image_speed = 1.5 if fase >= 3 else 1.25
					som_em("boss_carga", x, y, 0.9)
				elif atq.begins_with("raiz"):
					estado_ia = "raizes"
					sprite_index = spr_acao
					image_index = 0
					image_speed = 1.3
					raizes_lancar(int(atq.substr(4)))
					G.camera_impact = maxf(G.camera_impact, 6)
				elif atq == "sementes":
					estado_ia = "semeando"
					sementes_lancadas = false
					sprite_index = spr_ataque
					image_index = 0
					image_speed = 1.15
					som_em("boss_carga", x, y, 0.7)
				elif atq == "chuva":
					# v1.19: ergue os galhos e chama a chuva de brasas
					estado_ia = "chuva"
					sprite_index = spr_acao
					image_index = 0
					image_speed = 1.2
					chuva_lancar(7 if fase >= 3 else 4)
					G.camera_impact = maxf(G.camera_impact, 8)
					G.terremoto = maxf(G.terremoto, 16)
				else:
					estado_ia = "galho"
					sprite_index = spr_acao
					image_index = 0
					image_speed = 0.9
					galho_lancar()
					G.camera_impact = maxf(G.camera_impact, 8)
		"atacando":
			if not golpe_lancado and image_index >= 6:
				golpe_lancado = true
				for dsv in rajada_desvios:
					lancar_bola_fogo(p if tem_alvo else null, dsv)
		"semeando":
			if not sementes_lancadas and image_index >= 4:
				sementes_lancadas = true
				lancar_sementes(p if tem_alvo else null)
		"invocando":
			if not invocacao_feita and image_index >= 4:
				invocacao_feita = true
				invocar_guardas(invocacao_motivo)     # v1.19: poucos servos, perto de Twilight


# End Step vazio de propósito: o boss é uma árvore enraizada (sem física)
func ev_step_end() -> void:
	pass


func ev_anim_end() -> void:
	if morrendo:
		image_index = image_number - 1
		image_speed = 0
		return
	match estado_ia:
		"despertar":
			estado_ia = "parado"
			acordado = true
			recarga = 50
			onda_tempo = 0
			sprite_index = spr_parado
			image_index = 0
			image_speed = 1
		"atacando", "semeando", "invocando", "raizes", "galho", "chuva", "transicao":
			if estado_ia == "atacando" or estado_ia == "semeando":
				recarga = recarga_max
			else:
				recarga = maxf(recarga, 20.0 if fase >= 3 else (30.0 if fase == 2 else 40.0))   # v1.19: menos respiro
			estado_ia = "parado"
			sprite_index = spr_parado
			image_index = 0
			image_speed = 1


func ev_draw() -> void:
	var t := current_time() / 16.0
	var sx := randf_range(-tremor, tremor) if tremor > 0 else 0.0
	var xs := -dir * escala
	var cor := Color8(125, 105, 105) if estado_ia == "dormindo" else c_white
	if furia and not morrendo:
		cor = Color8(255, 190, 180)
	if morrendo:
		cor = merge_color(c_white, Color8(80, 50, 40), clampf(morte_tempo / 200.0, 0, 1))
	if acordado and not morrendo and G.cfg_qualidade > 0:
		gpu_set_blendmode(bm_add)
		var aa := 0.32 + 0.14 * sin(t / 5.0) if furia else 0.18 + 0.08 * sin(t / 9.0)
		draw_sprite_hd(sprite_index, image_index, x + sx, y + afundar, xs * 1.03, escala * 1.02, 0, Color8(220, 30, 10) if furia else Color8(150, 20, 10), aa)
		gpu_set_blendmode(bm_normal)
	if flash_dano > 0 and not morrendo:
		gpu_set_fog(true, Color8(255, 230, 200))
		draw_sprite_hd(sprite_index, image_index, x + sx, y + afundar, xs, escala, 0, c_white, image_alpha)
		gpu_set_fog(false, c_white)
	else:
		inimigo_corpo_desenhar(sprite_index, image_index, x + sx, y + afundar, xs, escala, 0, cor, image_alpha)
	if furia_fx > 0:
		var k := 1 - furia_fx / 90.0
		gpu_set_blendmode(bm_add)
		draw_set_alpha(1 - k)
		draw_set_color(Color8(255, 50, 20))
		draw_circle(x, y - 40 * escala / 2.0, 30 + 300 * k, true)
		draw_circle(x, y - 40 * escala / 2.0, 26 + 260 * k, true)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# AVISO da bola de fogo: a mão acende em roxo antes de lançar
	if (estado_ia == "atacando" or estado_ia == "semeando") and not (golpe_lancado or sementes_lancadas) and not morrendo:
		var hk := clampf(image_index / 6.0, 0, 1)
		var hx := x + dir * 30 * escala
		var hy := y - 36 * escala
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.35 + 0.45 * hk)
		draw_set_color(Color8(110, 220, 90) if estado_ia == "semeando" else Color8(150, 50, 255))
		draw_circle(hx, hy, 10 + 26 * hk + 3 * sin(t / 2.0), false)
		draw_set_alpha(0.6 * hk)
		draw_set_color(Color8(235, 200, 255))
		draw_circle(hx, hy, 5 + 10 * hk, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# v1.19: CHUVA DE BRASAS: o chão brilha onde cada brasa vai cair (cresce até ela sair)
	if not chuva_fila.is_empty() and not morrendo:
		gpu_set_blendmode(bm_add)
		for c in chuva_fila.size():
			var cx: float = chuva_fila[c][0]
			var ck := clampf(1.0 - chuva_fila[c][1] / (CHUVA_AVISO + 20.0), 0, 1)
			var cy: float = chuva_fila[c][2]
			draw_set_alpha(0.25 + 0.5 * ck + 0.15 * sin(t / 2.0 + c))
			draw_set_color(Color8(255, 110, 30))
			draw_ellipse(cx - 10 - 18 * ck, cy - 3 - 3 * ck, cx + 10 + 18 * ck, cy + 3 + 3 * ck, false)
			draw_set_alpha(0.35 * ck)
			draw_rectangle(cx - 2, cy - 160 * ck, cx + 2, cy, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# v1.17: CAMBALEANDO: brilho dourado no tronco e o ícone da execução sobre ela
	if estado_ia == "vulneravel" and not morrendo and not em_qte:
		var vk := 1.0 - vulneravel_t / 420.0
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.25 + 0.2 * sin(t / 3.0))
		draw_set_color(Color8(255, 170, 60))
		draw_circle(x - 10 * escala, y - 40 * escala, 60 + 10 * sin(t / 4.0), false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
		desenhar_icone_finalizador(x - 10 * escala, bbox_top - 14)
		V117.desenhar_anel(x - 10 * escala, bbox_top - 14, 26, 4, vk, Color8(255, 200, 90), 0.9)
	if estado_ia == "invocando":
		desenhar_portal(x, y_chao, minf(1, image_index / 3.0), t)
	# BARREIRA QUE BLOQUEIA A SAÍDA (antes da luta)
	if not arena_fechada:
		var p = instance_find("obj_player", 0)
		if p != null:
			var ba := clampf(1 - absf(p.x - barreira_x) / 520.0, 0.12, 1)
			desenhar_barreira(barreira_x, y_chao - 240, y_chao, ba, t)
	if G.debug_hitbox:
		draw_set_alpha(0.9)
		draw_set_color(c_fuchsia)
		draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true)
		draw_set_color(c_orange)
		draw_circle(x, y - 36 * escala, alcance_visao, true)
		draw_line(arena_esq, y_chao - 300, arena_esq, y_chao)
		gpu_set_texfilter(true)
		txt(x, bbox_top - 20, estado_ia + "  vida " + str(int(vida)) + "/" + str(int(vida_max)) + "  fase " + str(fase) + "  ataque " + str(ataque_n), FONTE.MINI, c_yellow, 1, fa_center, fa_bottom, 0.5)
		gpu_set_texfilter(false)
	desenho_resetar()


# ===== BARRA DE VIDA DO BOSS =====
func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	if hud_alpha > 0.01:
		vida_atraso = lerp_dt(vida_atraso, vida, 0.035)
		var marcas := []
		for m in 2:
			marcas.append([[0.66, 0.33][m], Color8(190, 80, 255) if fase >= m + 2 else Color8(255, 210, 90)])
		var ft := "FASE " + ("I" if fase == 1 else ("II" if fase == 2 else "III"))
		var cf := merge_color(Color8(190, 80, 255), c_white, 0.4 + 0.4 * sin(current_time() / 100.0)) if fase >= 2 else Color8(255, 210, 90)
		hud_barra_chefe(nome_boss, ft, cf, vida / vida_max, vida_atraso / vida_max, Color8(240, 64, 44), Color8(104, 8, 18),
			marcas, str(int(ceil(vida))) + " / " + str(int(vida_max)), hud_alpha)
	if titulo_tempo > 0:
		var ta := minf(clampf((210 - titulo_tempo) / 20.0, 0, 1), clampf(titulo_tempo / 30.0, 0, 1))
		var esc := minf(1, (gw * 0.8) / maxf(1, txt_largura(nome_boss, FONTE.GRANDE)))
		txt_amaldicoado(gw / 2.0, gh * 0.30, nome_boss, FONTE.GRANDE, Color8(235, 45, 35), 210 - titulo_tempo, 3, esc, ta)
		txt(gw / 2.0, gh * 0.30 + 46, titulo_boss, FONTE.PEQUENA, Color8(255, 210, 90), ta, fa_center, fa_middle)
	desenho_resetar()
