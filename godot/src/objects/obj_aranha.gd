extends ObjInimigoBase
# =====================================================================
#  obj_aranha — MULHER-ARANHA
#  * ágil: mantém distância, avança e recua de frente para Twilight
#  * GARRA de perto e BOTE (salta com as garras) de média distância
#  * TEIA: cospe teia em arco que PRENDE Twilight (lento, sem pular e sem
#    rolar); no chão vira uma armadilha pegajosa. A defesa segura a teia;
#    aparada na hora certa, ela volta e prende a própria aranha.
# =====================================================================

var escala := 1.45
var dano_garra := 8.0
var dano_bote := 10.0
var dano_teia := 3.0
var recarga_garra := 44.0
var recarga_teia_max := 250.0
var recarga_teia := 0.0
var recarga_bote_max := 180.0
var recarga_bote := 0.0
var teia_quadros := 80.0
var campo := 520.0
var campo_altura := 150.0
var vel_andar := 2.5 * dif_velocidade()
var dist_ideal_min := 120.0
var dist_ideal_max := 230.0
var viu := false
var ataque_t := 0.0
var teia_solta := false
var bote_no_ar := 0.0
var morte_anim := 0.0
var falas: Array = []
var cor_fala := Color(1, 1, 1)
var spr_ia_parado: GMSprite
var spr_ia_andar: GMSprite
var spr_ia_ataque: GMSprite


func ev_create() -> void:
	super()
	mask_index = Spr.spr_mascara_aranha
	image_xscale = 1
	image_yscale = 1
	escala = 1.45
	dir = -1
	inimigo_status(50)
	dano_garra = inimigo_dano(8)
	dano_bote = inimigo_dano(10)
	dano_teia = inimigo_dano(3)
	recarga = randi_range(30, 70)
	recarga_garra = round(44 * dif_recarga_inimigo())
	recarga_teia_max = round(250 * dif_recarga_inimigo())
	recarga_teia = randi_range(50, 110)
	recarga_bote_max = round(180 * dif_recarga_inimigo())
	recarga_bote = randi_range(80, 150)
	teia_quadros = dif_valor([60, 80, 95, 110])
	estado_ia = "parado"
	grav_ia = 0.4
	falas = falas_aranha()
	cor_fala = cor_fala_aranha()
	inimigo_portal_iniciar()
	spr_ia_parado = Spr.spr_aranha_parada
	spr_ia_andar = Spr.spr_aranha_andando
	spr_ia_ataque = Spr.spr_aranha_ataque
	spr_morrer = Spr.spr_aranha_parada
	sprite_index = spr_ia_parado
	image_index = randi_range(0, 3)
	image_speed = 1


func reagir_dano(_dano: float, d: float, forca: float) -> void:
	empurrao = d * forca * 0.3
	inimigo_atordoar(24)
	if vida <= 0:
		inimigo_morrer(d)
		image_speed = 0
		morte_anim = 0
		som_em("aranha_chiado", x, y, 0.9)
		return
	if randf() < 0.15:
		fala_dizer(self, choose(["Ssssh!", "Insolente!", "Minhas patas!"]), cor_fala)


func ev_step() -> void:
	var dt := G.dt
	if inimigo_portal_step(dt):
		return
	if morrendo:
		inimigo_corpo_step(dt)
		morte_anim += dt
		if morte_anim >= 36:
			morte_fim = true
		return
	if y > G.room_height + 300:
		instance_destroy()
		return
	if tempo_invencivel > 0:
		tempo_invencivel = maxf(0, tempo_invencivel - dt)
	if recarga > 0:
		recarga -= dt
	if recarga_teia > 0:
		recarga_teia -= dt
	if recarga_bote > 0:
		recarga_bote -= dt
	if barra_tempo > 0:
		barra_tempo -= dt
	if flash_dano > 0:
		flash_dano -= dt
	if alerta_fx > 0:
		alerta_fx -= dt
	if libertou_fx > 0:
		libertou_fx -= dt
	var no_chao := place_meeting(x, y + 1, "obj_chao")
	if inimigo_finalizador_step():
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
		fala_aleatoria(self, falas, cor_fala, 0.5)
	if tem_alvo:
		inimigo_regra_atordoamento(p)
	var estava_atordoado := atordoado > 0
	if inimigo_atordoamento_step(dt):
		if no_chao:
			velh = 0
		if estado_ia != "parado":
			estado_ia = "perseguir"
		trocar_sprite(spr_ia_parado, 0.5)
	else:
		if estava_atordoado:
			estado_ia = "perseguir" if dentro else "parado"
			recarga = minf(recarga, 14)
			image_speed = 1
		match estado_ia:
			"parado":
				velh = 0
				trocar_sprite(spr_ia_parado, 1)
				if dentro and viu:
					estado_ia = "perseguir"
			"perseguir":
				_perseguir(dentro, dx, dy, adx, no_chao)
			"garra":
				velh = 0
				ataque_t += dt
				if ataque_t < 16:
					image_index = 0
				else:
					image_index = minf(3, 1 + floor((ataque_t - 16) / 8.0))
				if not golpe_dado and ataque_t >= 16 and ataque_t < 26:
					if ataque_t - dt < 16:
						som_em("sfx_inimigo_golpe", x, y, 0.5)
					var x1 := x + dir * 4
					var x2 := x + dir * 50
					var alvo = collision_rectangle(minf(x1, x2), y - 50, maxf(x1, x2), y - 4, "obj_player")
					if alvo != null:
						golpe_dado = true
						alvo.levar_dano(dano_garra, x, true, 4, self)
				if ataque_t >= 40:
					estado_ia = "perseguir"
					recarga = recarga_garra + randi_range(0, 20)
					trocar_sprite(spr_ia_parado, 1)
			"teia":
				velh = 0
				ataque_t += dt
				if tem_alvo and not teia_solta and dx != 0:
					dir = signf(dx)
				if ataque_t < 22:
					image_index = 0
				else:
					image_index = minf(3, 1 + floor((ataque_t - 22) / 8.0))
				if not teia_solta and ataque_t >= 22:
					teia_solta = true
					var bx := x + dir * 16
					var by := y - 46
					var tx := bx + dir * 240
					var ty := y - 30
					if tem_alvo:
						tx = p.x
						ty = p.y - 30
					var vh := 5.6
					var tempo := maxf(8, absf(tx - bx) / vh)
					var vv := (ty - by) / tempo - 0.5 * 0.12 * tempo
					magia_criar("teia", bx, by, dir * vh, clampf(vv, -7, 4), dano_teia, self)
					som_em("teia_disparo", x, y, 0.75)
					fala_ataque(self, falas_aranha_teia(), cor_fala, 0.35)  # v1.18
				if ataque_t >= 46:
					estado_ia = "perseguir"
					recarga_teia = recarga_teia_max + randi_range(0, 60)
					recarga = maxf(recarga, 30)
					trocar_sprite(spr_ia_parado, 1)
			"bote_prep":
				velh = 0
				ataque_t += dt
				if tem_alvo:
					inimigo_virar(dx, true)
				if ataque_t >= 18:
					var forca := 5.4
					var tar := 2 * forca / grav_ia
					velh = dir * clampf((adx - 30) / tar, 2.5, 7)
					velv = -forca
					estado_ia = "bote"
					bote_no_ar = 0
					trocar_sprite(spr_ia_ataque, 0)
					image_index = 1
					som_em("aranha_chiado", x, y, 0.55)
			"bote":
				bote_no_ar += dt
				image_index = 1
				if not golpe_dado:
					var bx1 := x
					var bx2 := x + dir * 46
					var alvo_b = collision_rectangle(minf(bx1, bx2), y - 48, maxf(bx1, bx2), y - 2, "obj_player")
					if alvo_b != null:
						golpe_dado = true
						alvo_b.levar_dano(dano_bote, x, true, 6, self)
				if no_chao and velv >= 0 and bote_no_ar > 4:
					velh = 0
					estado_ia = "bote_fim"
					ataque_t = 0
					image_index = 2
					fx_em("poeira", x, y, 0.5)
				if velh != 0 and not inimigo_pode_andar(signf(velh), 18):
					velh = 0
			"bote_fim":
				velh = 0
				ataque_t += dt
				image_index = 2 if ataque_t < 10 else 3
				if ataque_t >= 22:
					estado_ia = "perseguir"
					recarga_bote = recarga_bote_max + randi_range(0, 60)
					recarga = maxf(recarga, 24)
					trocar_sprite(spr_ia_parado, 1)
	if empurrao != 0:
		velh += empurrao
		empurrao = lerp_dt(empurrao, 0, 0.16)
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
	if no_chao and recarga <= 0:
		if adx <= 62 and absf(dy) < 50:
			estado_ia = "garra"
			fala_ataque(self, falas, cor_fala, 0.3)  # v1.18: balão ao começar a garra
			ataque_t = 0
			golpe_dado = false
			velh = 0
			trocar_sprite(spr_ia_ataque, 0)
			image_index = 0
			return
		if recarga_bote <= 0 and adx >= 90 and adx <= 230 and absf(dy) < 60 and inimigo_pode_andar(dir, 64):
			estado_ia = "bote_prep"
			ataque_t = 0
			golpe_dado = false
			velh = 0
			trocar_sprite(spr_ia_parado, 0)
			image_index = 1
			fala_ataque(self, falas, cor_fala, 0.4)  # v1.18: balão ao começar o bote
			return
		if dif_golpe_liberado(DIF.MEDIO) and recarga_teia <= 0 and adx >= 110 and adx <= 430 and absf(dy) < 140 and inimigo_na_tela():
			estado_ia = "teia"
			ataque_t = 0
			teia_solta = false
			velh = 0
			trocar_sprite(spr_ia_ataque, 0)
			image_index = 0
			return
	# mantém a distância ideal, sempre de frente para Twilight
	var mv := 0.0
	if adx > dist_ideal_max:
		mv = dir
	elif recarga <= 0 and adx > 58:
		mv = dir
	elif adx < dist_ideal_min:
		mv = -dir
	if mv != 0 and not inimigo_pode_andar(mv):
		mv = 0
	if mv != 0:
		velh_para(mv * vel_andar * (1.0 if mv == dir else 0.75), 0.35, 0.5)
		trocar_sprite(spr_ia_andar, 1.5 if mv == dir else 1.1)
	else:
		velh_para(0, 0.35, 0.5)
		trocar_sprite(spr_ia_andar if absf(velh) > 0.5 else spr_ia_parado, 1)


func ev_draw() -> void:
	if not ativo:
		inimigo_portal_desenhar(spr_ia_parado, escala)
		return
	if portal_raio > 0:
		desenhar_portal(x, y, portal_raio, current_time() / 16.0)
	inimigo_sombra(22)
	# ===== MORTE: vira de patas para cima e encolhe as patas =====
	if morrendo:
		var m := clampf(morte_anim / 36.0, 0, 1)
		var e := 1 - pow(1 - m, 2)
		var ys := escala * (1 - 1.5 * e)
		var hh := spr_ia_parado.yo / hd_escala(spr_ia_parado)
		var yd := y - maxf(0, -ys) * hh
		var cm := merge_color(c_white, Color8(110, 95, 110), e * 0.6)
		inimigo_corpo_desenhar(spr_ia_parado, 0, x, yd, dir * escala, ys, 0, cm, image_alpha)
		return
	var trem := sin(atordoado_anim * 1.6) * 1.5 if atordoado > 0 else 0.0
	if executando:
		trem = randf_range(-1.5, 1.5)
	var cor := Color8(255, 170, 150) if imune_atordoar > 0 else c_white
	var ys2 := escala
	if estado_ia == "bote_prep":
		ys2 = escala * (1 - 0.14 * clampf(ataque_t / 18.0, 0, 1))
	if estado_ia == "garra" and ataque_t < 16:
		trem += sin(ataque_t * 2) * 0.8
	inimigo_desenhar_corpo(sprite_index, image_index, x + trem, y, dir * escala, ys2, 0, cor, image_alpha)
	if estado_ia == "teia" and not teia_solta:
		var ta := clampf(ataque_t / 22.0, 0, 1)
		gpu_set_texfilter(true)
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.75 * ta)
		draw_set_color(Color8(235, 235, 255))
		draw_circle(x + dir * 16, y - 46, 2 + 4 * ta, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
		gpu_set_texfilter(false)
	inimigo_hud(y - 78, 40)
	inimigo_debug("" if estado_ia == "teia" else "  teia " + str(int(maxf(0, ceil(recarga_teia / 60.0)))) + "s")
	desenho_resetar()
