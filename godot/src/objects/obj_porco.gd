extends ObjInimigoBase
# =====================================================================
#  obj_porco — PORCO CORROMPIDO (brutamontes)
#  * golpes comuns não o atordoam nem o lançam (só aparar ou a exaustão)
#  * CORTE VERMELHO de perto (um em cada três QUEBRA a guarda)
#  * SALTO ESMAGADOR: onda de choque ao cair (pule ou role)
#  * CORTE ROXO: onda de magia rente ao chão (pule ou role)
#  * FÚRIA: com metade da vida ruge, invoca esqueletos e fica mais rápido
# =====================================================================

var escala := 1.85
var dano_salto := 15.0
var dano_onda := 11.0
var recarga_max := 70.0
var recarga_salto_max := 330.0
var recarga_salto := 0.0
var recarga_onda_max := 280.0
var recarga_onda := 0.0
var contador_ataques := 0
var ataque_bloqueavel := true
var campo := 560.0
var campo_altura := 160.0
var vel_correr := 1.9 * dif_velocidade()
var alcance_ataque := 66.0
var viu := false
var forca_salto := 8.0
var golpe_janelas: Array = [[3, 4], [8, 8]]
var golpe_janela := -1
var golpe_som_i := 0
var onda_solta := false
var no_ar_t := 0.0
var furioso := false
var furia_pendente := false
var invocou := false
var aura_t := 0.0
var morte_anim := 0.0
var falas: Array = []
var cor_fala := Color(1, 1, 1)
var spr_ia_parado: GMSprite
var spr_ia_correr: GMSprite
var spr_ia_ataque: GMSprite


func ev_create() -> void:
	super()
	mask_index = Spr.spr_mascara_porco
	image_xscale = 1
	image_yscale = 1
	escala = 1.85
	dir = -1
	resiste_atordoar = true
	pode_lancar = false
	inimigo_status(160)
	dano_ataque = inimigo_dano(13)
	dano_salto = inimigo_dano(15)
	dano_onda = inimigo_dano(11)
	recarga = randi_range(30, 60)
	recarga_max = round(70 * dif_recarga_inimigo())
	recarga_salto_max = round(330 * dif_recarga_inimigo())
	recarga_salto = randi_range(120, 220)
	recarga_onda_max = round(280 * dif_recarga_inimigo())
	recarga_onda = randi_range(70, 150)
	estado_ia = "parado"
	grav_ia = 0.45
	falas = falas_porco()
	cor_fala = cor_fala_porco()
	inimigo_portal_iniciar()
	spr_ia_parado = Spr.spr_porco_parado
	spr_ia_correr = Spr.spr_porco_correndo
	spr_ia_ataque = Spr.spr_porco_ataque
	spr_morrer = Spr.spr_porco_morrendo
	sprite_index = spr_ia_parado
	image_index = randi_range(0, 2)
	image_speed = 1


func reagir_dano(_dano: float, d: float, forca: float) -> void:
	empurrao = d * forca * 0.15
	if vida <= 0:
		inimigo_morrer(d)
		velh = d * 0.6
		som_em("porco_grunhido", x, y, 1)
		fala_dizer(self, "Grr... oinc...", cor_fala, true)
		return
	if not invocou and vida <= vida_max * 0.5:
		furia_pendente = true
	elif randf() < 0.1:
		fala_dizer(self, choose(["Oinc!", "Grrr!", "Isso coçou!"]), cor_fala)


# MECÂNICA: invoca esqueletos por portais de magia em volta dele
func porco_invocar() -> void:
	var n: int = dif_valor([1, 2, 2, 3])
	var p = instance_find("obj_player", 0)
	for i in n:
		var lado: float = -dir if i % 2 == 0 else dir
		var sx: float = x + lado * (90 + 50 * floor(i / 2.0) + randf() * 30)
		sx = clampf(arena_limitar_x(sx, 40), 60, G.room_width - 60)
		if p != null and absf(sx - p.x) < 60:
			sx += -70 if sx < p.x else 70
		var sy := chao_abaixo(sx, y - 120, 300)
		var e = instance_create_depth(sx, sy, depth + 1, "obj_esqueleto")
		e.invocado = true
		e.reerguido = true
		e.surgir_agora = true
		e.surgir_atraso = 10 + i * 14
		e.dir = signf(p.x - sx) if p != null else -1.0
		if e.dir == 0:
			e.dir = -1


func ev_step() -> void:
	var dt := G.dt
	if inimigo_portal_step(dt):
		return
	if morrendo:
		inimigo_corpo_step(dt)
		return
	if y > G.room_height + 300:
		instance_destroy()
		return
	if tempo_invencivel > 0:
		tempo_invencivel = maxf(0, tempo_invencivel - dt)
	if recarga > 0:
		recarga -= dt
	if recarga_salto > 0:
		recarga_salto -= dt
	if recarga_onda > 0:
		recarga_onda -= dt
	if barra_tempo > 0:
		barra_tempo -= dt
	if flash_dano > 0:
		flash_dano -= dt
	if alerta_fx > 0:
		alerta_fx -= dt
	if libertou_fx > 0:
		libertou_fx -= dt
	aura_t += dt
	var no_chao := place_meeting(x, y + 1, "obj_chao")
	if not no_chao:
		no_ar_t += dt
	elif velv >= 0:
		no_ar_t = 0
	# ===== PRESO NO FINALIZADOR DE TWILIGHT =====
	if inimigo_finalizador_step():
		if estado_ia != "salto_ar":
			estado_ia = "perseguir"
		trocar_sprite(spr_ia_parado, 0.2)
		atordoado = maxf(atordoado, 2)
		atordoado_anim += dt
		if not no_chao:
			velv += grav_ia * dt
		elif velv > 0:
			velv = 0
		return
	var p = instance_find("obj_player", 0)
	var tem_alvo: bool = p != null and not p.morto
	var dx := 0.0
	var dy := 0.0
	if tem_alvo:
		dx = p.x - x
		dy = p.y - y
	var adx := absf(dx)
	var dentro := tem_alvo and adx <= campo and absf(dy) <= campo_altura
	if dentro and not viu and inimigo_na_tela():
		viu = true
		alerta_fx = 40
		som_em("porco_grunhido", x, y, 0.8)
		fala_aleatoria(self, falas, cor_fala, 0.6)
	# ===== ATORDOAMENTO (só aparando ou pela exaustão) =====
	var estava_atordoado := atordoado > 0
	if inimigo_atordoamento_step(dt):
		if no_chao:
			velh = 0
		if estado_ia == "rugir" or estado_ia == "invocar":
			furia_pendente = not invocou
		if estado_ia == "invocar" and invocou:
			furioso = true
			vel_correr = 2.5
		if estado_ia != "parado" and estado_ia != "salto_ar":
			estado_ia = "perseguir"
		trocar_sprite(spr_ia_parado, 0.3)
	else:
		if estava_atordoado:
			estado_ia = "perseguir" if dentro else "parado"
			recarga = minf(recarga, 12)
			image_speed = 1
		# FÚRIA (metade da vida): ruge e invoca esqueletos assim que estiver no chão
		if furia_pendente and dif_golpe_liberado(DIF.DIFICIL) and not invocou and no_chao and (estado_ia == "perseguir" or estado_ia == "parado"):
			furia_pendente = false
			estado_ia = "rugir"
			velh = 0
			sprite_index = Spr.spr_porco_furia
			image_index = 0
			image_speed = 0.8
			som_em("sfx_rugido", x, y, 0.9)
			G.camera_impact = maxf(G.camera_impact, 8)
			var ff := falas_porco_furia()
			fala_dizer(self, ff[randi() % ff.size()], cor_fala, true)
		match estado_ia:
			"parado":
				velh = 0
				trocar_sprite(spr_ia_parado, 1)
				if dentro and viu:
					estado_ia = "perseguir"
			"perseguir":
				_perseguir(dentro, dx, dy, adx, no_chao)
			"atacar":
				velh = 0
				if sprite_index != spr_ia_ataque:
					sprite_index = spr_ia_ataque
					image_index = 0
				var fa := int(floor(image_index))
				var nj := golpe_janelas.size()
				if golpe_som_i < nj and fa >= golpe_janelas[golpe_som_i][0] - 1:
					golpe_som_i += 1
					som_em("atk_pesado", x, y, 0.55)
				for w in nj:
					var jw: Array = golpe_janelas[w]
					if fa < jw[0] or fa > jw[1]:
						continue
					if w != golpe_janela:
						golpe_janela = w
						golpe_dado = false
					if golpe_dado:
						continue
					var x1 := x + dir * 2
					var x2 := x + dir * 64
					var alvo = collision_rectangle(minf(x1, x2), y - 72, maxf(x1, x2), y - 4, "obj_player")
					if alvo != null:
						golpe_dado = true
						alvo.levar_dano(dano_ataque, x, ataque_bloqueavel, 7, self)
			"salto_prep":
				velh = 0
				if tem_alvo:
					inimigo_virar(dx, true)
				if image_index >= 2:
					var tar := 2 * forca_salto / grav_ia
					velh = dir * clampf((adx - 20) / tar, 2, 8.5)
					velv = -forca_salto
					estado_ia = "salto_ar"
					no_ar_t = 0
					image_speed = 0.9
					som_em("sfx_pulo", x, y, 0.7)
					fx_em("poeira", x, y, 0.8)
			"salto_ar":
				if image_index >= 5.9:
					image_index = 5
				if velh != 0 and not inimigo_pode_andar(signf(velh), 26):
					velh = 0
				if no_chao and velv >= 0 and no_ar_t <= 0:
					# ATERRISSAGEM: onda de choque no chão (pule ou role para escapar)
					velh = 0
					estado_ia = "salto_pouso"
					image_index = 6
					image_speed = 0.8
					som_em("porco_impacto", x, y, 1)
					G.camera_impact = maxf(G.camera_impact, 9)
					fx_em("onda_chao", x, y, 1.2)
					fx_em("poeira", x, y, 1.2)
					if tem_alvo:
						var no_chao_p: bool = p.place_meeting(p.x, p.y + 2, "obj_chao")
						var intang: bool = p.jogador_intangivel()
						if no_chao_p and not intang and absf(p.x - x) <= 112 and absf(p.y - y) < 40:
							p.levar_dano(dano_salto, x, false, 8, null)
							if not p.morto:
								p.velv = minf(p.velv, -3)
			"salto_pouso":
				velh = 0
			"onda":
				velh = 0
				if not onda_solta and image_index >= 3:
					onda_solta = true
					magia_criar("onda", x + dir * 46, y, dir * (6.2 if furioso else 5.2), 0, dano_onda, self)
					som_em("magia_onda", x, y, 0.85)
			"rugir":
				velh = 0
				if int(floor(image_index)) == 4 and G.camera_impact < 4:
					G.camera_impact = 4
			"invocar":
				velh = 0
				if not invocou and image_index >= 5:
					invocou = true
					porco_invocar()
	if empurrao != 0:
		velh += empurrao
		empurrao = lerp_dt(empurrao, 0, 0.2)
		if absf(empurrao) < 0.2:
			empurrao = 0
	if not no_chao:
		velv += grav_ia * dt
	elif velv > 0:
		velv = 0
	image_xscale = 1
	image_yscale = 1


func _perseguir(dentro: bool, dx: float, dy: float, adx: float, no_chao: bool) -> void:
	if not dentro:
		estado_ia = "parado"
		velh = 0
		return
	inimigo_virar(dx)
	if no_chao:
		# CORTE VERMELHO: de perto
		if recarga <= 0 and adx <= alcance_ataque and absf(dy) < 60:
			estado_ia = "atacar"
			golpe_dado = false
			golpe_janela = -1
			golpe_som_i = 0
			contador_ataques += 1
			ataque_bloqueavel = contador_ataques % 3 != 0
			fala_ataque(self, falas, cor_fala, 0.4)  # v1.18: balão ao começar o golpe
			velh = 0
			sprite_index = spr_ia_ataque
			image_index = 0
			image_speed = 1.0 if furioso else 0.8
			return
		# SALTO ESMAGADOR: média distância
		if recarga_salto <= 0 and adx >= 130 and adx <= 360 and absf(dy) < 120 and inimigo_pode_andar(dir, 60):
			estado_ia = "salto_prep"
			velh = 0
			sprite_index = Spr.spr_porco_salto
			image_index = 0
			image_speed = 0.55
			fala_ataque(self, falas_porco_salto(), cor_fala, 0.5)  # v1.18
			return
		# CORTE ROXO: onda de magia rente ao chão
		if dif_golpe_liberado(DIF.MEDIO) and recarga_onda <= 0 and adx >= 150 and adx <= 520 and absf(dy) < 40 and inimigo_na_tela():
			estado_ia = "onda"
			onda_solta = false
			velh = 0
			sprite_index = Spr.spr_porco_roxo
			image_index = 0
			image_speed = 0.7
			fala_ataque(self, falas_porco_onda(), cor_fala, 0.45)  # v1.18
			return
	if adx > alcance_ataque - 12 and inimigo_pode_andar(dir, 24):
		velh_para(dir * vel_correr, 0.3, 0.5)
		trocar_sprite(spr_ia_correr, 1.25 if furioso else 1.0)
	else:
		velh_para(0, 0.3, 0.5)
		trocar_sprite(spr_ia_correr if absf(velh) > 0.6 else spr_ia_parado, 1)


func ev_anim_end() -> void:
	if not ativo:
		return
	if morrendo:
		if sprite_index == spr_morrer:
			image_index = image_number - 1
			image_speed = 0
			morte_fim = true
		return
	match estado_ia:
		"atacar":
			if sprite_index == spr_ia_ataque:
				estado_ia = "perseguir"
				golpe_dado = false
				recarga = round(recarga_max * (0.7 if furioso else 1.0)) + randi_range(0, 20)
				trocar_sprite(spr_ia_parado, 1)
		"onda":
			if sprite_index == Spr.spr_porco_roxo:
				estado_ia = "perseguir"
				recarga_onda = round(recarga_onda_max * (0.7 if furioso else 1.0)) + randi_range(0, 60)
				recarga = maxf(recarga, 30)
				trocar_sprite(spr_ia_parado, 1)
		"salto_pouso":
			if sprite_index == Spr.spr_porco_salto:
				estado_ia = "perseguir"
				recarga_salto = round(recarga_salto_max * (0.7 if furioso else 1.0)) + randi_range(0, 60)
				recarga = minf(recarga, 10)
				trocar_sprite(spr_ia_parado, 1)
		"salto_prep", "salto_ar":
			if sprite_index == Spr.spr_porco_salto:
				image_index = 5
		"rugir":
			if sprite_index == Spr.spr_porco_furia:
				estado_ia = "invocar"
				sprite_index = Spr.spr_porco_invocar
				image_index = 0
				image_speed = 0.8
		"invocar":
			if sprite_index == Spr.spr_porco_invocar:
				if not invocou:
					invocou = true
					porco_invocar()
				furioso = true
				vel_correr = 2.5
				estado_ia = "perseguir"
				recarga = 10
				trocar_sprite(spr_ia_parado, 1)


func ev_draw() -> void:
	if not ativo:
		inimigo_portal_desenhar(spr_ia_parado, escala)
		return
	if portal_raio > 0:
		desenhar_portal(x, y, portal_raio, current_time() / 16.0)
	inimigo_sombra(26)
	# ===== AURA DA FÚRIA (atrás do corpo) =====
	if furioso and not morrendo:
		var pu := 0.5 + 0.5 * sin(aura_t * 0.15)
		gpu_set_texfilter(true)
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.16 + 0.1 * pu)
		draw_set_color(Color8(230, 40, 30))
		draw_ellipse(x - 38, y - 92, x + 38, y + 4, false)
		draw_set_color(Color8(255, 120, 60))
		for k in 4:
			var fy := y - fmod(aura_t * 1.6 + k * 23, 90)
			draw_set_alpha(0.5 * (1 - (y - fy) / 90.0))
			draw_circle(x + sin(aura_t * 0.09 + k * 1.9) * 26, fy, 2, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
		gpu_set_texfilter(false)
	var trem := sin(atordoado_anim * 1.4) * 1.6 if atordoado > 0 else 0.0
	if executando:
		trem = randf_range(-1.5, 1.5)
	if estado_ia == "rugir":
		trem = randf_range(-1.2, 1.2)
	var cor := c_white
	if furioso:
		cor = Color8(255, 205, 195)
	if morrendo and morte_fim:
		cor = Color8(150, 130, 130)
	inimigo_desenhar_corpo(sprite_index, image_index, x + trem, y, dir * escala, escala, 0, cor, image_alpha)
	if morrendo:
		return
	gpu_set_texfilter(true)
	if estado_ia == "salto_ar" or estado_ia == "salto_prep":
		var pa := 0.35 + 0.25 * sin(current_time() / 50.0)
		var px := x + velh * 6 if estado_ia == "salto_ar" else x + dir * 40
		var gy := chao_abaixo(px, y - 10, 260)
		draw_set_alpha(pa)
		draw_set_color(Color8(255, 80, 50))
		draw_ellipse(px - 112, gy - 6, px + 112, gy + 6, true)
		draw_set_alpha(1)
	if estado_ia == "onda" and not onda_solta:
		var oa := clampf(image_index / 3.0, 0, 1)
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.7 * oa)
		draw_set_color(Color8(220, 60, 255))
		draw_circle(x + dir * 30, y - 40, 4 + 8 * oa, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	gpu_set_texfilter(false)
	var topo := y - 96
	inimigo_hud(topo, 60)
	if estado_ia == "atacar" and not ataque_bloqueavel and image_index < 9:
		var qa := 0.75 + 0.25 * sin(current_time() / 60.0)
		txt(x, topo - 20, "QUEBRA-GUARDA", FONTE.MINI, Color8(255, 90, 60), qa, fa_center, fa_bottom, 0.55)
	if estado_ia == "rugir":
		txt(x, topo - 20, "FÚRIA!", FONTE.PEQUENA, Color8(255, 80, 50), 0.85 + 0.15 * sin(current_time() / 50.0), fa_center, fa_bottom, 0.6)
	inimigo_debug("  (fúria)" if furioso else "")
	desenho_resetar()
