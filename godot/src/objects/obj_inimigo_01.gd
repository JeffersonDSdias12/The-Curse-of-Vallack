class_name ObjInimigo01
extends ObjInimigoBase
# =====================================================================
#  obj_inimigo_01 — besta do caminho do castelo
#  Surge do chão por um portal de magia quando o jogador se aproxima.
#  Estados: parado, perseguir, atacar, pular_preparo, pular_ar,
#           pular_pouso, (atordoado), morrendo
# =====================================================================

var contador_ataques := 0
var ataque_bloqueavel := true
var recarga_max := 46.0
var campo := 480.0
var campo_altura := 130.0
var alcance_ataque := 50.0
var alcance_ataque_y := 44.0
var distancia_minima := 38.0
var vel_correr := 1.9 * dif_velocidade()
var separacao := 0.0
var zona_pulo_min := 85.0
var zona_pulo_max := 210.0
var forca_salto := 7.2
var recarga_salto := 0.0
var pulo_obstaculo := false
var falas: Array = []
var cor_fala := Color(1, 1, 1)
var spr_ia_parado: GMSprite
var spr_ia_andar: GMSprite
var spr_ia_correr: GMSprite
var spr_ia_ataque: GMSprite
var spr_ia_pular: GMSprite
var spr_ia_atordoado: GMSprite
var vel_atordoado := 0.4
var golpe_janelas: Array = [[3, 6]]
var golpe_caixa: Array = [6, 46, -52, -6]
var vel_ataque := 0.35
var golpe_janela := -1
var golpe_som_i := 0
var sombra_larg := 17.0


func ev_create() -> void:
	super()
	mask_index = Spr.spr_mascara_inimigo
	image_xscale = 1
	image_yscale = 1
	dir = choose([-1.0, 1.0])
	# ===== COMBATE (ajustado pela dificuldade) =====
	# v1.13: vida e dano pela dificuldade E pelo nível no mapa (a fase 2 é mais dura)
	inimigo_status(60)
	dano_ataque = inimigo_dano(8)
	contador_ataques = 0
	ataque_bloqueavel = true
	recarga = randi_range(0, 30)
	recarga_max = round(46 * dif_recarga_inimigo())
	# ===== IA =====
	estado_ia = "parado"
	alertado = false
	alerta_fx = 0
	pulando = false
	grav_ia = 0.4
	recarga_salto = randi_range(40, 120)
	falas = falas_besta()
	cor_fala = Color8(130, 20, 20)
	# ===== SURGIR DO CHÃO =====
	inimigo_portal_iniciar()
	# ===== SPRITES =====
	spr_ia_parado = Spr.spr_inimigo01_parado
	spr_ia_andar = Spr.spr_inimigo01_andar
	spr_ia_correr = Spr.spr_inimigo01_correndo
	spr_ia_ataque = Spr.spr_inimigo01_atacando
	spr_ia_pular = Spr.spr_inimigo01_pulando
	spr_morrer = Spr.spr_inimigo01_morrendo
	sprite_index = spr_ia_parado
	image_index = randi_range(0, spr_ia_parado.n - 1)
	image_speed = 1
	escala_vis = 1
	cor_base = c_white
	spr_ia_atordoado = spr_ia_parado
	topo_vis = 72
	usa_hud_nivel = false


# escudo (inimigo 03) e outros detalhes
func desenhar_extra() -> void:
	pass


# Reação a um golpe do jogador
func reagir_dano(_dano: float, d: float, forca: float) -> void:
	empurrao = d * forca * 0.25
	inimigo_atordoar(30)
	if vida <= 0:
		inimigo_morrer(d)
	elif randf() < 0.12:
		fala_dizer(self, choose(["Argh!", "Grrr!", "Maldito!"]), cor_fala)


func ev_step() -> void:
	var dt := G.dt
	# ===== AINDA ESCONDIDO: surge do chão por um portal de magia =====
	if inimigo_portal_step(dt):
		return
	# ===== MORTE =====
	if morrendo:
		inimigo_corpo_step(dt)
		return
	if y > G.room_height + 300:
		instance_destroy()
		return
	# ===== TEMPORIZADORES =====
	if tempo_invencivel > 0:
		tempo_invencivel = maxf(0, tempo_invencivel - dt)
	if recarga > 0:
		recarga -= dt
	if recarga_salto > 0:
		recarga_salto -= dt
	if barra_tempo > 0:
		barra_tempo -= dt
	if flash_dano > 0:
		flash_dano -= dt
	if alerta_fx > 0:
		alerta_fx -= dt
	if libertou_fx > 0:
		libertou_fx -= dt
	if escudo_fx > 0:
		escudo_fx -= dt
	var no_chao := place_meeting(x, y + 1, "obj_chao")
	# ===== PRESO NO FINALIZADOR DE TWILIGHT =====
	if inimigo_finalizador_step():
		pulando = false
		estado_ia = "perseguir"
		if sprite_index != spr_ia_atordoado:
			sprite_index = spr_ia_atordoado
			image_index = 0
		image_speed = 0.2
		atordoado = maxf(atordoado, 2)
		atordoado_anim += dt
		if not no_chao:
			velv += grav_ia * dt
		elif velv > 0:
			velv = 0
		return
	# ===== JOGADOR =====
	var p = instance_find("obj_player", 0)
	var tem_alvo: bool = p != null and not p.morto
	var dx := 0.0
	var dy := 0.0
	if tem_alvo:
		dx = p.x - x
		dy = p.y - y
	var adx := absf(dx)
	var dentro_campo := tem_alvo and adx <= campo and absf(dy) <= campo_altura
	# ===== REGRA DE ATORDOAMENTO =====
	if tem_alvo:
		inimigo_regra_atordoamento(p)
	var estava_atordoado := atordoado > 0
	if inimigo_atordoamento_step(dt):
		# ----- ATORDOADO: não anda e não ataca -----
		if no_chao:
			velh = 0
		pulando = false
		if estado_ia in ["pular_ar", "pular_pouso", "pular_preparo"]:
			estado_ia = "perseguir"
		if sprite_index != spr_ia_atordoado:
			sprite_index = spr_ia_atordoado
			image_index = 0
		image_speed = vel_atordoado
	else:
		if estava_atordoado:
			estado_ia = "perseguir" if dentro_campo else "parado"
			recarga = minf(recarga, randi_range(4, 18))
			image_speed = 1
		match estado_ia:
			"parado":
				velh = 0
				trocar_sprite(spr_ia_parado, 1)
				if dentro_campo:
					estado_ia = "perseguir"
					if not alertado:
						alerta_fx = 40
					alertado = true
			"perseguir":
				_perseguir(p, dx, dy, adx, dentro_campo, no_chao, dt)
			"atacar":
				velh = 0
				if sprite_index != spr_ia_ataque:
					sprite_index = spr_ia_ataque
					image_index = 0
				image_speed = vel_ataque
				var fa := int(floor(image_index))
				var nj := golpe_janelas.size()
				if golpe_som_i < nj and fa >= golpe_janelas[golpe_som_i][0] - 1:
					golpe_som_i += 1
					som_golpe_tocou = true
					som_em("sfx_inimigo_golpe", x, y, 0.55)
				for w in nj:
					var jw: Array = golpe_janelas[w]
					if fa < jw[0] or fa > jw[1]:
						continue
					if w != golpe_janela:
						golpe_janela = w
						golpe_dado = false
					if golpe_dado:
						continue
					var x1: float = x + dir * golpe_caixa[0]
					var x2: float = x + dir * golpe_caixa[1]
					var alvo = collision_rectangle(minf(x1, x2), y + golpe_caixa[2], maxf(x1, x2), y + golpe_caixa[3], "obj_player")
					if alvo != null:
						golpe_dado = true
						alvo.levar_dano(dano_ataque, x, ataque_bloqueavel, 5, self)
			"pular_preparo":
				velh = 0
				image_speed = 1.3
				if image_index >= 2:
					inimigo_virar(dx, true)
					var tempo_ar := 2 * forca_salto / grav_ia
					var dist := maxf(0, adx - 34)
					velh = dir * clampf(dist / tempo_ar, 1.2, 4.4)
					velv = -forca_salto
					pulando = true
					pulo_obstaculo = false
					estado_ia = "pular_ar"
			"pular_ar":
				image_speed = 1
				if pulo_obstaculo and velv < 1:
					velh = dir * 2.3
				if image_index >= 5.5:
					image_index = 5
				if no_chao and velv >= 0:
					pulando = false
					velh = 0
					estado_ia = "pular_pouso"
					image_index = 6
					image_speed = 1.4
					recarga_salto = randi_range(150, 260)
					if adx < 300:
						G.camera_impact = maxf(G.camera_impact, 3)
			"pular_pouso":
				velh = 0
	# ===== SEPARAÇÃO: os inimigos não ficam empilhados =====
	if atordoado <= 0 and no_chao and (estado_ia == "perseguir" or estado_ia == "parado"):
		separacao = 0
		for e in todos("obj_inimigo_base"):
			if e != self and not e.morrendo and e.ativo and not e.eh_boss:
				var d: float = x - e.x
				if absf(d) < 26 and absf(y - e.y) < 40:
					var lado := (1.0 if id > e.id else -1.0) if d == 0 else signf(d)
					separacao += lado * (26 - absf(d)) * 0.06
		velh += clampf(separacao, -1.2, 1.2)
	# ===== EMPURRÃO =====
	if empurrao != 0:
		velh += empurrao
		empurrao = lerp_dt(empurrao, 0, 0.16)
		if absf(empurrao) < 0.2:
			empurrao = 0
	# ===== GRAVIDADE =====
	if not no_chao:
		velv += grav_ia * dt
	elif velv > 0:
		velv = 0
	image_xscale = 1


func _perseguir(_p, dx: float, dy: float, adx: float, dentro_campo: bool, no_chao: bool, dt: float) -> void:
	if not dentro_campo:
		estado_ia = "parado"
		alertado = false
		velh = 0
		return
	inimigo_virar(dx)
	# limite de inimigos atacando ao mesmo tempo (depende da dificuldade)
	var ativos := 0
	for e in todos("obj_inimigo_01"):
		if e != self and e.ativo and e.estado_ia == "atacar":
			ativos += 1
	if no_chao and recarga <= 0 and adx <= alcance_ataque and absf(dy) <= alcance_ataque_y and ativos < dif_atacantes_max():
		estado_ia = "atacar"
		golpe_dado = false
		som_golpe_tocou = false
		golpe_janela = -1
		golpe_som_i = 0
		contador_ataques += 1
		ataque_bloqueavel = contador_ataques % dif_quebra_guarda() != 0
		fala_ataque(self, falas, cor_fala, 0.4)  # v1.18: balão ao começar o golpe
		velh = 0
		sprite_index = spr_ia_ataque
		image_index = 0
		image_speed = vel_ataque
		return
	# OBSTÁCULO (caixote) no caminho: pula por cima
	if no_chao and adx > distancia_minima and place_meeting(x + dir * 10, y - 2, "obj_chao") \
			and not place_meeting(x + dir * 10, y - 60, "obj_chao") and not place_meeting(x, y - 60, "obj_chao"):
		estado_ia = "pular_ar"
		pulo_obstaculo = true
		pulando = true
		velv = -6.9
		velh = dir * 2.3
		sprite_index = spr_ia_pular
		image_index = 4
		image_speed = 1
		return
	# PULO: só quando o jogador está na zona próxima
	if no_chao and dif_golpe_liberado(DIF.MEDIO) and recarga_salto <= 0 and adx >= zona_pulo_min and adx <= zona_pulo_max \
			and dy > -140 and dy < 50 and randf() < 0.035 * dt:
		estado_ia = "pular_preparo"
		velh = 0
		sprite_index = spr_ia_pular
		image_index = 0
		image_speed = 1.3
		return
	if adx > distancia_minima:
		velh_para(dir * vel_correr, 0.35, 0.55)
		trocar_sprite(spr_ia_correr, 1)
	else:
		velh_para(0, 0.35, 0.55)      # freia (ainda nas passadas) até parar
		trocar_sprite(spr_ia_correr if absf(velh) > 0.6 else spr_ia_parado, 1)


# ===== ANIMATION END =====
func ev_anim_end() -> void:
	if not ativo:
		return
	if morrendo:
		if sprite_index == spr_morrer:
			image_index = image_number - 1
			image_speed = 0
			morte_fim = true
		return
	if estado_ia == "atacar" and sprite_index == spr_ia_ataque:
		estado_ia = "perseguir"
		golpe_dado = false
		recarga = recarga_max + randi_range(0, 24)
		trocar_sprite(spr_ia_parado, 1)
		return
	if sprite_index == spr_ia_pular:
		if estado_ia == "pular_pouso":
			estado_ia = "perseguir"
			recarga = minf(recarga, 6)
			trocar_sprite(spr_ia_parado, 1)
		elif estado_ia == "pular_ar":
			image_index = 5


func ev_draw() -> void:
	# ===== AINDA NO CHÃO: portal de magia e a besta subindo =====
	if not ativo:
		inimigo_portal_desenhar(spr_ia_parado, escala_vis, cor_base)
		return
	if portal_raio > 0:
		desenhar_portal(x, y, portal_raio, current_time() / 16.0)
	# ===== SOMBRA =====
	if place_meeting(x, y + 2, "obj_chao"):
		draw_set_alpha(0.3 * image_alpha * inimigo_sombra_alpha())
		draw_set_color(c_black)
		draw_ellipse(x - sombra_larg, y - 3, x + sombra_larg, y + 3, false)
		draw_set_alpha(1)
	# ===== BESTA =====
	var trem := sin(atordoado_anim * 1.4) * 1.5 if atordoado > 0 else 0.0
	var cor := merge_color(cor_base, Color8(205, 205, 255), 0.6) if atordoado > 0 else cor_base
	if imune_atordoar > 0 and not morrendo:
		cor = Color8(255, 170, 150)
	if executando:
		trem = randf_range(-1.5, 1.5)
	if morrendo and morte_fim:
		cor = merge_color(cor_base, Color8(90, 80, 80), 0.35)
	if flash_dano > 0 and not morrendo:
		gpu_set_fog(true, c_white)
		draw_sprite_hd(sprite_index, image_index, x + trem, y, dir * escala_vis, escala_vis, 0, c_white, image_alpha)
		gpu_set_fog(false, c_white)
	else:
		inimigo_corpo_desenhar(sprite_index, image_index, x + trem, y, dir * escala_vis, escala_vis, 0, cor, image_alpha)
	desenhar_extra()
	if morrendo:
		return
	var topo := y - topo_vis
	gpu_set_texfilter(true)
	if usa_hud_nivel:
		inimigo_hud(topo, 46)
	else:
		if libertou_fx > 0:
			var lf := 1 - libertou_fx / 20.0
			draw_set_alpha(1 - lf)
			draw_set_color(Color8(255, 80, 60))
			draw_circle(x, y - 30, 12 + 30 * lf, true)
			draw_set_alpha(1)
		if atordoado > 0:
			draw_set_color(Color8(255, 230, 110))
			for k in 3:
				var ang := atordoado_anim * 7 + k * 120
				var sx := x + lengthdir_x(15, ang)
				var sy := topo + 4 + lengthdir_y(4, ang)
				draw_set_alpha(0.65 + 0.35 * dsin(ang))
				draw_triangle(sx - 4, sy, sx + 4, sy, sx, sy - 4, false)
				draw_triangle(sx - 4, sy, sx + 4, sy, sx, sy + 4, false)
				draw_triangle(sx, sy - 4, sx, sy + 4, sx - 4, sy, false)
				draw_triangle(sx, sy - 4, sx, sy + 4, sx + 4, sy, false)
			draw_set_alpha(1)
		if finalizavel:
			desenhar_icone_finalizador(x, topo - 16)
		if alerta_fx > 0:
			var aa := clampf(alerta_fx / 12.0, 0, 1)
			txt(x, topo - 8 - (40 - alerta_fx) * 0.2, "!", FONTE.MEDIA, Color8(255, 80, 60), aa, fa_center, fa_bottom, 0.8)
		if barra_tempo > 0 and vida > 0:
			var a := minf(1, barra_tempo / 24.0)
			var larg := 52.0
			var bx := x - larg / 2.0
			var by := topo - 6
			vida_atraso = lerp_dt(vida_atraso, vida, 0.06)
			draw_set_alpha(a)
			draw_set_color(c_black)
			draw_rectangle(bx - 2, by - 2, bx + larg + 2, by + 6, false)
			draw_set_color(c_white)
			draw_rectangle(bx, by, bx + larg * clampf(vida_atraso / vida_max, 0, 1), by + 4, false)
			draw_rectangle_color(bx, by, bx + larg * clampf(vida / vida_max, 0, 1), by + 4,
				Color8(230, 80, 65), Color8(230, 80, 65), Color8(120, 20, 20), Color8(120, 20, 20), false)
			draw_set_color(Color8(176, 141, 70))
			draw_rectangle(bx - 2, by - 2, bx + larg + 2, by + 6, true)
			draw_set_alpha(1)
	# ===== AVISO DE GOLPE QUE NÃO PODE SER DEFENDIDO =====
	if estado_ia == "atacar" and not ataque_bloqueavel and image_index < golpe_janelas[golpe_janelas.size() - 1][1] + 1:
		var pa := 0.75 + 0.25 * sin(current_time() / 60.0)
		draw_set_alpha(pa)
		draw_set_color(Color8(255, 70, 40))
		draw_circle(x, topo - 14, 3, false)
		txt(x, topo - 20, "QUEBRA-GUARDA", FONTE.MINI, Color8(255, 90, 60), pa, fa_center, fa_bottom, 0.55)
	if G.debug_hitbox:
		draw_set_alpha(0.9)
		draw_set_color(c_red)
		draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true)
		if estado_ia == "atacar":
			var x1: float = x + dir * golpe_caixa[0]
			var x2: float = x + dir * golpe_caixa[1]
			draw_set_color(c_orange)
			draw_rectangle(minf(x1, x2), y + golpe_caixa[2], maxf(x1, x2), y + golpe_caixa[3], true)
		txt(x, bbox_bottom + 4, estado_ia + (" (atordoado)" if atordoado > 0 else "") + (("  Nv " + str(nivel)) if usa_hud_nivel else ""), FONTE.MINI, c_yellow, 1, fa_center, fa_top, 0.45)
	gpu_set_texfilter(false)
	desenho_resetar()
