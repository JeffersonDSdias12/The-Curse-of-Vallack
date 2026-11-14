extends ObjInimigoBase
# =====================================================================
#  obj_mini_boss — O CARRASCO DE VALLACK (mini-boss do meio da fase 1)
#  * espera perto do cristal do meio; quando Twilight entra, muralhas
#    mágicas fecham a arena
#  * golpe pesado (a cada 2, um quebra-guarda), salto com onda de choque
#    e investida; depois de 3 ações fica cansado por um instante
#  * não fica tonto com golpes comuns (só aparando ou exausto)
#  * com 1/4 da vida cai de joelhos: FINALIZADOR
# =====================================================================

var escala := 1.65
var nome_boss := "O CARRASCO DE VALLACK"
var titulo_boss := "GUARDIÃO DA VILA EM CHAMAS"
var dano_corte := 20.0
var dano_salto := 16.0
var dano_investida := 14.0
var arena_x1 := 0.0
var arena_x2 := 0.0
var arena_fechada := false
var y_chao := 0.0
var chave := ""
var acordado := false
var ataque_bloqueavel := true
var contador_ataques := 0
var acoes := 0
var t_estado := 0.0
var exausto_usado := false
var enfurecido := false
var hud_alpha := 0.0
var titulo_tempo := 0.0
var fala_t := 400.0
var investida_dir := 1.0
var onda_fx := 0.0
var spr_ia_parado: GMSprite
var spr_ia_andar: GMSprite
var spr_ia_correr: GMSprite
var spr_ia_ataque: GMSprite
var spr_ia_pular: GMSprite
var dialogo_fim_t := 0.0
var porcos_1 := false       # v1.17: convoca javalis de guerra com 50% e com 30% da vida
var porcos_2 := false
# v1.19: SEGUNDA VIDA: a primeira sequência completa não o mata; ele se ergue
# de novo, a barra enche e ele volta mais rápido. Só a segunda sequência mata.
var segunda_vida := true
var na_segunda_vida := false


func ev_create() -> void:
	super()
	escala = 1.65
	image_xscale = escala
	image_yscale = escala
	mask_index = Spr.spr_mascara_inimigo
	dir = -1
	resiste_atordoar = true
	pode_lancar = false
	usa_qte = true          # v1.17: com 1/4 da vida, a SEQUÊNCIA DE GOLPES o derruba
	vida_max = round(460 * dif_vida_inimigo())
	vida = vida_max
	vida_atraso = vida
	dano_corte = maxf(1, round(20 * dif_dano_inimigo()))
	dano_salto = maxf(1, round(16 * dif_dano_inimigo()))
	dano_investida = maxf(1, round(14 * dif_dano_inimigo()))
	grav_ia = 0.45
	arena_x1 = x - 340
	arena_x2 = x + 300
	arena_fechada = false
	y_chao = chao_abaixo(x, y - 60)
	chave = aberto_chave("mini", xstart, ystart)
	if aberto_tem(chave):
		instance_destroy()
		return
	estado_ia = "dormindo"
	recarga = 40
	spr_ia_parado = Spr.spr_inimigo01_parado
	spr_ia_andar = Spr.spr_inimigo01_andar
	spr_ia_correr = Spr.spr_inimigo01_correndo
	spr_ia_ataque = Spr.spr_inimigo01_atacando
	spr_ia_pular = Spr.spr_inimigo01_pulando
	spr_morrer = Spr.spr_inimigo01_morrendo
	cor_base = Color8(175, 125, 140)
	sprite_index = spr_ia_parado
	image_speed = 0.6


func mudar(e: String) -> void:
	estado_ia = e
	t_estado = 0
	golpe_dado = false
	som_golpe_tocou = false


func despertar() -> void:
	if acordado:
		return
	acordado = true
	mudar("apresentacao")
	titulo_tempo = 200
	arena_fechada = true
	arena_fechar(arena_x1, arena_x2, y_chao, self)
	musica("bgm_mini_boss", 1500)     # v1.16: trilha do mini boss ao entrar na arena
	som("sfx_rugido", 1, 0)
	G.camera_impact = maxf(G.camera_impact, 12)
	G.dano_na_luta = 0.0              # v1.17: conquista INTOCÁVEL
	dialogo_iniciar("carrasco_inicio")


func reagir_dano(_dano: float, d: float, _forca: float) -> void:
	empurrao = d * 0.4
	if not acordado:
		despertar()
	if estado_ia == "renascer":
		vida = maxf(vida, 1)
		return
	# v1.17: só cai pela SEQUÊNCIA DE GOLPES (até ela, a vida para em 1)
	if vida <= 0:
		if qte_vencido:
			# v1.19: a primeira sequência não mata: ele renasce com a barra cheia
			if segunda_vida:
				mini_renascer()
				return
			mini_morrer(d)
			return
		vida = 1
	# v1.17: antes de cair, convoca os javalis de guerra
	if not porcos_1 and vida <= vida_max * 0.5:
		porcos_1 = true
		invocar_porcos(dif_valor([1, 2, 2, 3]))
	elif not porcos_2 and vida <= vida_max * 0.3:
		porcos_2 = true
		invocar_porcos(dif_valor([2, 3, 3, 4]))
	# v1.12: FASE 2 com 60% da vida: mais rápido e mais agressivo
	if not enfurecido and vida <= vida_max * 0.6:
		enfurecido = true
		som("sfx_rugido", 0.9, 0)
		G.camera_impact = maxf(G.camera_impact, 10)
		aviso_mostrar("O CARRASCO SE ENFURECEU!")
		dialogo_iniciar("carrasco_fase2")
	# 1/4 da vida: cai de joelhos e fica pronto para a SEQUÊNCIA DE GOLPES (v1.17)
	if not exausto_usado and vida <= vida_max * 0.25:
		exausto_usado = true
		mudar("exausto")
		aparado_t = 0
		inimigo_atordoar(260, true)
		G.camera_impact = maxf(G.camera_impact, 8)
		aviso_mostrar("O CARRASCO CAIU DE JOELHOS  ·  EXECUTE-O!")


# v1.17: os JAVALIS DE GUERRA surgem nas pontas da arena, longe de Twilight
func invocar_porcos(nq: int) -> void:
	var p = instance_find("obj_player", 0)
	var px: float = p.x if p != null else x
	for k in nq:
		var sx: float = arena_x1 + 70 + k * 26 if k % 2 == 0 else arena_x2 - 70 - k * 26
		if absf(sx - px) < 100:
			sx += -110 if sx < px else 110
		sx = clampf(sx, arena_x1 + 40, arena_x2 - 40)
		var sy := chao_abaixo(sx, y_chao - 120, 300)
		var e = instance_create_depth(sx, sy, 100, "obj_porco")
		e.invocado = true
		e.surgir_agora = true
		e.surgir_atraso = 6.0 + k * 16
		e.dir = signf(px - sx)
		if e.dir == 0:
			e.dir = -1
		e.vida_max = maxf(1, round(e.vida_max * 0.6))
		e.vida = e.vida_max
		e.vida_atraso = e.vida
		e.limite_x1 = arena_x1 + 24
		e.limite_x2 = arena_x2 - 24
	som("sfx_rugido", 1, 0)
	som("porco_grunhido", 0.9, 0.05)
	G.camera_impact = maxf(G.camera_impact, 12)
	aviso_mostrar("O CARRASCO CONVOCA OS JAVALIS DE GUERRA!")


# v1.17: a sequência de golpes falhou: levanta furioso, empurra Twilight e volta a lutar
func qte_falhou() -> void:
	enfurecido = true
	atordoado = 0
	aparado_t = 0
	atordoado_acumulado = 0
	imune_atordoar = 90
	vida = maxf(vida, round(vida_max * 0.4))
	vida_atraso = vida
	exausto_usado = false
	mudar("perseguir")
	recarga = 30
	som("sfx_rugido", 1, 0)
	G.camera_impact = maxf(G.camera_impact, 14)
	fx_em("onda_chao", x, y, 1.2)
	var p = instance_find("obj_player", 0)
	if p != null:
		p.levar_dano(maxf(1, round(dano_corte * 0.6)), x, false, 9, self)
	aviso_mostrar("O CARRASCO SE SOLTOU!")


# v1.19: SEGUNDA VIDA. Fica invulnerável no estado "renascer" (ev_step) enquanto
# a barra enche; depois volta à luta enfurecido e mais rápido. Igual ao PC.
func mini_renascer() -> void:
	segunda_vida = false
	na_segunda_vida = true
	qte_vencido = false
	finalizado = false
	executando = false
	finalizavel = false
	qte_pronto = false
	atordoado = 0
	aparado_t = 0
	atordoado_acumulado = 0
	vida = 1
	vida_atraso = 1
	exausto_usado = false
	porcos_1 = false
	porcos_2 = false
	enfurecido = true
	cor_base = Color8(215, 80, 80)
	mudar("renascer")
	tempo_invencivel = 30
	for q in todos("obj_qte"):
		instance_destroy(q)
	G.qte_alvo = null
	som("sfx_rugido", 1, 0)
	G.camera_impact = maxf(G.camera_impact, 18)
	G.terremoto = maxf(G.terremoto, 40)
	camera_lenta(50, 0.4)
	fx_em("fumaca_maldita_estouro", x, y - 50, 1.6)
	aviso_mostrar("O CARRASCO SE RECUSA A CAIR!")


func mini_morrer(d: float) -> void:
	inimigo_morrer(d)
	evaporar_tam = 2.2
	aberto_marcar(chave)
	arena_abrir(self)
	musica(musica_fase(), 1500)     # de volta à trilha de batalha da fase
	progresso_marcar()
	camera_lenta(60, 0.35)
	aviso_mostrar("O CARRASCO CAIU  ·  +" + str(int(round(ORBS_MINI_BOSS * (ORBS_FINALIZADOR if finalizado else 1.0)))) + " ORBS")
	dialogo_fim_t = 50
	# v1.17: ORBES DE VIDA (verdes) e as conquistas
	V117.orbs_vida_soltar(x, y - 50, dif_valor([8, 6, 5, 4]), 6)
	V117.conquista("carrasco")
	if G.dano_na_luta <= 0:
		V117.conquista("intocavel")


func ev_step() -> void:
	var dt := G.dt
	if morrendo:
		if dialogo_fim_t > 0:
			dialogo_fim_t -= dt
			if dialogo_fim_t <= 0:
				dialogo_iniciar("carrasco_fim")
		inimigo_corpo_step(dt)
		return
	if tempo_invencivel > 0:
		tempo_invencivel = maxf(0, tempo_invencivel - dt)
	if recarga > 0:
		recarga -= dt
	if barra_tempo > 0:
		barra_tempo -= dt
	if flash_dano > 0:
		flash_dano -= dt
	if titulo_tempo > 0:
		titulo_tempo -= dt
	if onda_fx > 0:
		onda_fx -= dt
	if libertou_fx > 0:
		libertou_fx -= dt
	t_estado += dt
	hud_alpha = lerp_dt(hud_alpha, 1.0 if acordado else 0.0, 0.08)
	image_xscale = escala
	image_yscale = escala
	var no_chao := place_meeting(x, y + 1, "obj_chao")
	var p = instance_find("obj_player", 0)
	var tem: bool = p != null and not p.morto
	var dx: float = p.x - x if tem else 0.0
	var dy: float = p.y - y if tem else 0.0
	var adx := absf(dx)
	# ----- preso no finalizador -----
	if inimigo_finalizador_step():
		trocar_sprite(spr_ia_parado, 0.15)
		if not no_chao:
			velv += grav_ia * dt
		elif velv > 0:
			velv = 0
		return
	# ----- atordoado (aparado ou exausto) -----
	var estava := atordoado > 0
	if inimigo_atordoamento_step(dt):
		if no_chao:
			velh = 0
		trocar_sprite(spr_ia_parado, 0.15)
		if not no_chao:
			velv += grav_ia * dt
		elif velv > 0:
			velv = 0
		if empurrao != 0:
			velh += empurrao
			empurrao = lerp_dt(empurrao, 0, 0.16)
			if absf(empurrao) < 0.2:
				empurrao = 0
		return
	if estava and estado_ia != "dormindo":
		if estado_ia == "exausto":
			# não foi executado: levanta enfurecido, com um pouco de vida de volta (v1.17:
			# ele só cai pela sequência de golpes, então pode cair de joelhos de novo)
			vida = maxf(vida, round(vida_max * 0.35))
			vida_atraso = vida
			exausto_usado = false
			enfurecido = true
			som("sfx_rugido", 0.9, 0)
			G.camera_impact = maxf(G.camera_impact, 10)
		mudar("perseguir")
		recarga = 20
	var v := 2.3 if na_segunda_vida else (1.9 if enfurecido else 1.35)
	match estado_ia:
		# v1.19: SEGUNDA VIDA: de pé, invulnerável, a barra enche de novo (~1,5 s)
		"renascer":
			velh = 0
			tempo_invencivel = maxf(tempo_invencivel, 10)
			trocar_sprite(spr_ia_parado, 2)
			if tem and dx != 0:
				dir = signf(dx)
			vida = minf(vida_max, vida + vida_max / 90.0 * dt)
			vida_atraso = vida
			if randf() < 0.35 * dt:
				fx_em("fumaca_maldita", x + randf_range(-30, 30), y - randf() * 110, 0.9)
			if vida >= vida_max and t_estado >= 100:
				vida = vida_max
				vida_atraso = vida
				mudar("perseguir")
				recarga = 20
				# o grito do renascimento empurra Twilight para longe
				som("sfx_rugido", 1, 0)
				G.camera_impact = maxf(G.camera_impact, 16)
				fx_em("onda_chao", x, y, 1.4)
				if tem and adx < 260:
					p.empurrao = signf(p.x - x) * 6
				dialogo_iniciar("carrasco_fase2")
		"dormindo":
			trocar_sprite(spr_ia_parado, 0.5)
			velh = 0
			if tem and p.x > arena_x1 + 50 and p.x < arena_x2 and absf(dy) < 160:
				despertar()
		"apresentacao":
			velh = 0
			trocar_sprite(spr_ia_parado, 1.6)
			if tem and dx != 0:
				dir = signf(dx)
			if t_estado >= 100:
				mudar("perseguir")
				recarga = 30
		"perseguir":
			_perseguir(tem, dx, dy, adx, no_chao, v)
		"atacar":
			velh = 0
			var fa := int(floor(image_index))
			if fa == 3 and t_estado < 60:
				velh = dir * 1.5
			if not som_golpe_tocou and fa >= 3:
				som_golpe_tocou = true
				som("atk_pesado", 0.75, 0.1)
			if not golpe_dado and fa >= 4 and fa <= 6 and tem:
				var x1 := x + dir * 8
				var x2 := x + dir * 92
				if rectangle_in_rectangle(minf(x1, x2), y - 96, maxf(x1, x2), y - 4, p.bbox_left, p.bbox_top, p.bbox_right, p.bbox_bottom) > 0:
					golpe_dado = true
					p.levar_dano(dano_corte, x, ataque_bloqueavel, 7, self)
				if fa == 5 and t_estado > 1:
					G.camera_impact = maxf(G.camera_impact, 4)
		"salto_preparo":
			velh = 0
			if image_index >= 2:
				if tem and dx != 0:
					dir = signf(dx)
				var alvo_x: float = p.x if tem else x + dir * 200
				alvo_x = arena_limitar_x(alvo_x, 40)
				var tempo_ar := 2 * 9 / grav_ia
				velh = clampf((alvo_x - x) / tempo_ar, -5.5, 5.5)
				velv = -9
				mudar("salto_ar")
				image_index = 4
				som("sfx_pulo", 0.9, 0)
		"salto_ar":
			image_speed = 0.6
			if image_index >= 5.5:
				image_index = 5
			if no_chao and velv >= 0 and t_estado > 4:
				velh = 0
				mudar("salto_pouso")
				image_index = 6
				image_speed = 1
				# ONDA DE CHOQUE: pule ou role para escapar
				G.camera_impact = maxf(G.camera_impact, 16)
				G.terremoto = maxf(G.terremoto, 20)
				onda_fx = 30
				fx_em("onda_chao", x, y, 1.1)
				fx_em("poeira", x, y, 1.6)
				fx_em("rachaduras", x, y, 1.1)
				som("sfx_impacto", 0.9, 0.05)
				var lst := []
				if tem and p.y >= y - 30:
					armadilha_area(x - 105, y - 40, x + 105, y + 4, dano_salto / maxf(0.1, dif_dano_inimigo()), 0, lst, 7)
				acoes += 1
		"salto_pouso":
			velh = 0
		"investida_preparo":
			velh = 0
			trocar_sprite(spr_ia_parado, 2)
			if randf() < 0.4 * dt:
				fx_em("poeira", x - dir * 14, y, 0.4)
			if t_estado >= 34:
				mudar("investida")
				sprite_index = spr_ia_correr
				image_index = 0
				image_speed = 1.7
		"investida":
			dir = investida_dir
			velh = dir * (6.8 if na_segunda_vida else (6.0 if enfurecido else 5.2))
			if randf() < 0.5 * dt:
				fx_em("poeira", x - dir * 18, y, 0.35)
			var acabou := false
			if not golpe_dado and tem and rectangle_in_rectangle(x - 26, y - 90, x + 26, y, p.bbox_left, p.bbox_top, p.bbox_right, p.bbox_bottom) > 0:
				golpe_dado = true
				var vida_antes: float = p.vida
				var bloq: bool = p.bloqueando
				p.levar_dano(dano_investida, x, true, 9, self)
				if bloq and p.vida == vida_antes:
					# bateu no escudo: tropeça e cansa
					velh = 0
					empurrao = -dir * 3
					acoes = 3
					mudar("perseguir")
					acabou = true
			if not acabou and (place_meeting(x + dir * 6, y - 4, "obj_chao") or t_estado > 75):
				velh = 0
				if t_estado <= 75:
					G.camera_impact = maxf(G.camera_impact, 12)
					som("dest_pedra", 0.8, 0.05)
					fx_em("poeira", x + dir * 20, y - 30, 1)
					inimigo_atordoar(90, true)
				acoes += 1
				mudar("perseguir")
				recarga = 40
		"cansado":
			velh = 0
			trocar_sprite(spr_ia_parado, 0.35)
			if t_estado >= (38 if na_segunda_vida else (55 if enfurecido else 85)):
				mudar("perseguir")
				recarga = 10
	if empurrao != 0:
		velh += empurrao
		empurrao = lerp_dt(empurrao, 0, 0.16)
		if absf(empurrao) < 0.2:
			empurrao = 0
	# não sai da arena
	if arena_fechada:
		x = clampf(x, arena_x1 + 20, arena_x2 - 20)
	if not no_chao:
		velv += grav_ia * dt
	elif velv > 0:
		velv = 0


func _perseguir(tem: bool, dx: float, dy: float, adx: float, no_chao: bool, v: float) -> void:
	if not tem:
		velh = 0
		trocar_sprite(spr_ia_parado, 0.6)
		return
	inimigo_virar(dx)
	if acoes >= 3:
		acoes = 0
		mudar("cansado")
		velh = 0
		return
	if recarga <= 0 and no_chao:
		if adx <= 82 and absf(dy) < 70:
			mudar("atacar")
			contador_ataques += 1
			ataque_bloqueavel = contador_ataques % 2 != 0
			velh = 0
			sprite_index = spr_ia_ataque
			image_index = 0
			image_speed = 0.42 if na_segunda_vida else (0.36 if enfurecido else 0.28)
			som_em("boss_carga", x, y, 0.5)
			return
		if adx >= 130 and adx <= 340 and randf() < 0.6:
			mudar("salto_preparo")
			velh = 0
			sprite_index = spr_ia_pular
			image_index = 0
			image_speed = 0.8
			return
		if adx > 260:
			mudar("investida_preparo")
			velh = 0
			investida_dir = dir
			som("sfx_rugido", 0.5, 0.1)
			return
	if adx > 64:
		velh_para(dir * v, 0.3, 0.5)
		trocar_sprite(spr_ia_andar, 1.1)
	else:
		velh_para(0, 0.3, 0.5)
		trocar_sprite(spr_ia_andar if absf(velh) > 0.5 else spr_ia_parado, 0.8)


func ev_anim_end() -> void:
	if morrendo:
		if sprite_index == spr_morrer:
			image_index = image_number - 1
			image_speed = 0
			morte_fim = true
		return
	if estado_ia == "atacar" and sprite_index == spr_ia_ataque:
		acoes += 1
		recarga = 24 if enfurecido else 44
		mudar("perseguir")
		trocar_sprite(spr_ia_parado, 1)
	elif estado_ia == "salto_pouso" and sprite_index == spr_ia_pular:
		recarga = 20 if enfurecido else 36
		mudar("perseguir")
		trocar_sprite(spr_ia_parado, 1)


func ev_draw() -> void:
	var t := current_time() / 16.0
	if place_meeting(x, y + 2, "obj_chao"):
		draw_set_alpha(0.32 * image_alpha * inimigo_sombra_alpha())
		draw_set_color(c_black)
		draw_ellipse(x - 28, y - 4, x + 28, y + 4, false)
		draw_set_alpha(1)
	var trem := sin(atordoado_anim * 1.4) * 1.5 if atordoado > 0 else 0.0
	if executando:
		trem = randf_range(-2, 2)
	var renasce := estado_ia == "renascer" and not morrendo
	if renasce:
		trem = randf_range(-2.5, 2.5)      # v1.19: segunda vida se erguendo
	var cor := merge_color(cor_base, Color8(255, 120, 110), 0.45) if enfurecido else cor_base
	if estado_ia == "dormindo":
		cor = merge_color(cor_base, c_black, 0.25)
	if morrendo and morte_fim:
		cor = merge_color(cor_base, Color8(90, 80, 80), 0.4)
	if not morrendo and (estado_ia == "investida_preparo" or enfurecido):
		gpu_set_blendmode(bm_add)
		var ia := 0.45 + 0.25 * sin(t / 2.0) if estado_ia == "investida_preparo" else 0.18 + 0.08 * sin(t / 6.0)
		if renasce:
			ia = 0.5 + 0.3 * sin(t / 2.0)
		elif na_segunda_vida:
			ia += 0.1
		draw_sprite_hd(sprite_index, image_index, x + trem, y, dir * escala * 1.05, escala * 1.03, 0, Color8(220, 30, 10), ia)
		gpu_set_blendmode(bm_normal)
	if flash_dano > 0 and not morrendo:
		gpu_set_fog(true, c_white)
		draw_sprite_hd(sprite_index, image_index, x + trem, y, dir * escala, escala, 0, c_white, image_alpha)
		gpu_set_fog(false, c_white)
	else:
		inimigo_corpo_desenhar(sprite_index, image_index, x + trem, y, dir * escala, escala, 0, cor, image_alpha)
	if morrendo:
		return
	var topo := y - 72 * escala
	# v1.12: AVISO claro antes de cada ataque: clarão e um "!" grande
	var prep := (estado_ia == "atacar" and image_index < 4) or estado_ia == "salto_preparo" or estado_ia == "investida_preparo"
	if prep:
		var pa2 := 0.7 + 0.3 * sin(current_time() / 50.0)
		if t_estado < 8:
			gpu_set_blendmode(bm_add)
			gpu_set_fog(true, c_white)
			draw_sprite_hd(sprite_index, image_index, x + trem, y, dir * escala, escala, 0, c_white, 0.5 * (1 - t_estado / 8.0))
			gpu_set_fog(false, c_white)
			gpu_set_blendmode(bm_normal)
		gpu_set_texfilter(true)
		txt_sombra(x, topo - 16, "!", FONTE.GRANDE, Color8(255, 80, 50), pa2, fa_center, fa_bottom, 0.8)
		gpu_set_texfilter(false)
	if estado_ia == "atacar" and not ataque_bloqueavel and image_index < 6:
		var pa := 0.75 + 0.25 * sin(current_time() / 60.0)
		gpu_set_texfilter(true)
		txt(x, topo - 6, "QUEBRA-GUARDA", FONTE.MINI, Color8(255, 90, 60), pa, fa_center, fa_bottom, 0.6)
		gpu_set_texfilter(false)
	if atordoado > 0:
		draw_set_color(Color8(255, 230, 110))
		for k in 3:
			var ang := atordoado_anim * 7 + k * 120
			draw_set_alpha(0.65 + 0.35 * dsin(ang))
			draw_circle(x + lengthdir_x(20, ang), topo + 6 + lengthdir_y(5, ang), 3, false)
		draw_set_alpha(1)
	if finalizavel:
		desenhar_icone_finalizador(x, topo - 12)
	if G.debug_hitbox:
		draw_set_color(c_red)
		draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true)
		draw_line(arena_x1, y - 200, arena_x1, y)
		draw_line(arena_x2, y - 200, arena_x2, y)
		gpu_set_texfilter(true)
		txt(x, bbox_bottom + 4, estado_ia + "  ações " + str(acoes), FONTE.MINI, c_yellow, 1, fa_center, fa_top, 0.45)
		gpu_set_texfilter(false)
	desenho_resetar()


# ===== BARRA DE VIDA DO MINI-BOSS =====
func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	if hud_alpha > 0.01 and not morrendo:
		vida_atraso = lerp_dt(vida_atraso, vida, 0.04)
		var marcas := [[0.25, Color8(255, 210, 90)], [0.6, Color8(255, 80, 50) if enfurecido else Color8(255, 210, 90)]]
		# v1.19: quantas vidas ele ainda tem (a primeira sequência não o mata)
		var rot := "ÚLTIMA VIDA" if na_segunda_vida else ("MINI-BOSS  ·  2 VIDAS" if segunda_vida else "MINI-BOSS")
		hud_barra_chefe(nome_boss, rot, Color8(255, 110, 90) if na_segunda_vida else Color8(220, 200, 180), vida / vida_max, vida_atraso / vida_max,
			Color8(238, 120, 44), Color8(120, 30, 10), marcas, "", hud_alpha)
	if titulo_tempo > 0:
		var ta := minf(clampf((200 - titulo_tempo) / 20.0, 0, 1), clampf(titulo_tempo / 30.0, 0, 1))
		var esc := minf(1, (gw * 0.8) / maxf(1, txt_largura(nome_boss, FONTE.GRANDE)))
		txt_amaldicoado(gw / 2.0, gh * 0.30, nome_boss, FONTE.GRANDE, Color8(235, 90, 35), 200 - titulo_tempo, 3, esc, ta)
		txt(gw / 2.0, gh * 0.30 + 46, titulo_boss, FONTE.PEQUENA, Color8(255, 210, 90), ta, fa_center, fa_middle)
	desenho_resetar()
