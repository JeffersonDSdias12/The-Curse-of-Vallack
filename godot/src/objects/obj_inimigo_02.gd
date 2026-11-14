class_name ObjInimigo02
extends ObjInimigoBase
# =====================================================================
#  obj_inimigo_02 — arqueiro esqueleto
#  * só atira de longe e só quando está no campo de visão (a câmera)
#  * foge quando o jogador chega perto
#  * surge do chão por um portal de magia, como a besta
#  Estados: parado, fugir, aproximar, atirar, (atordoado), morrendo
# =====================================================================

var escala := 1.55
var dano_flecha := 5.0
var recarga_max := 420.0
var cor_ia := Color(1, 1, 1)
var velocidade_flecha := 8.0
var distancia_fuga := 170.0
var distancia_segura := 320.0
var vel_fuga := 2.7 * dif_velocidade()
var distancia_ideal := 300.0
var distancia_max := 430.0
var vel_aproximar := 2.2 * dif_velocidade()
var flecha_solta := false
var viu := false
var spr_ia_parado: GMSprite
var spr_ia_andar: GMSprite
var spr_ia_correr: GMSprite
var spr_ia_ataque: GMSprite
var spr_ia_dano: GMSprite


func ev_create() -> void:
	super()
	# A instância foi aumentada na sala de forma desigual: usa a ALTURA, uniforme
	escala = absf(image_yscale)
	if escala < 0.5:
		escala = 1.55
	image_xscale = escala
	image_yscale = escala
	mask_index = Spr.spr_mascara_arqueiro
	dir = -1
	inimigo_status(30)
	dano_flecha = inimigo_dano(5)
	recarga = randi_range(90, 200)
	recarga_max = round(420 * dif_recarga_inimigo())     # v1.12: 7 s no MÉDIO
	cor_ia = c_white
	velocidade_flecha = 8
	estado_ia = "parado"
	grav_ia = 0.4
	flecha_solta = false
	alerta_fx = 0
	viu = false
	inimigo_portal_iniciar()
	spr_ia_parado = Spr.spr_inimigo02_parado
	spr_ia_andar = Spr.spr_inimigo02_correndo
	spr_ia_correr = Spr.spr_inimigo02_correndo
	spr_ia_ataque = Spr.spr_inimigo02_atacando
	spr_ia_dano = Spr.spr_inimigo02_sofrendo_dano
	spr_morrer = Spr.spr_inimigo02_morrendo
	sprite_index = spr_ia_parado
	image_index = randi_range(0, spr_ia_parado.n - 1)
	image_speed = 1


# Há espaço para fugir nessa direção? (parede ou borda do mapa = encurralado)
func pode_fugir(d: float) -> bool:
	var nx := x + d * 32
	if place_meeting(nx, y - 2, "obj_chao") or nx < 48 or nx > G.room_width - 48:
		return false
	if arena_limitar_x(nx, 24) != nx:
		return false
	var b = instance_find("obj_boss_01", 0)
	if b != null and not b.morrendo and nx > b.barreira_x - 24:
		return false
	return true


func pode_andar(d: float) -> bool:
	var nx := x + d * 32
	if nx < 48 or nx > G.room_width - 48:
		return false
	if arena_limitar_x(nx, 24) != nx:
		return false
	var b = instance_find("obj_boss_01", 0)
	if b != null and not b.morrendo and nx > b.barreira_x - 24:
		return false
	return true


func reagir_dano(_dano: float, d: float, forca: float) -> void:
	empurrao = d * forca * 0.3
	inimigo_atordoar(26)
	if vida <= 0:
		inimigo_morrer(d)
		return
	if atordoado > 0:
		sprite_index = spr_ia_dano
		image_index = 0
		image_speed = 1.4


# v1.12: o disparo virou uma função (o alquimista troca a flecha pelo frasco)
func disparar(bx: float, by: float, alvo) -> void:
	som_em("sfx_flecha", x, y, 0.7)
	var tx := bx + dir * 300
	var ty := by
	if alvo != null:
		tx = alvo.x
		ty = alvo.y - 34
	var dist := point_distance(bx, by, tx, ty)
	var tempo := dist / velocidade_flecha
	ty -= 0.5 * 0.05 * tempo * tempo
	var ang := point_direction(bx, by, tx, ty)
	# v1.13: no DIFÍCIL sai uma 2ª flecha um pouco mais alta; no EXTREMO, 3 em leque
	for desvio in dif_valor([[0.0], [0.0], [0.0, 6.0], [0.0, -7.0, 7.0]]):
		var f = instance_create_depth(bx, by, depth - 1, "obj_flecha")
		f.dano = dano_flecha
		f.escala = escala * 0.85
		f.vx = lengthdir_x(velocidade_flecha, ang + desvio)
		f.vy = lengthdir_y(velocidade_flecha, ang + desvio)
		f.alcance = G.view_w * 1.1


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
	if barra_tempo > 0:
		barra_tempo -= dt
	if flash_dano > 0:
		flash_dano -= dt
	if alerta_fx > 0:
		alerta_fx -= dt
	if libertou_fx > 0:
		libertou_fx -= dt
	var no_chao := place_meeting(x, y + 1, "obj_chao")
	# ===== PRESO NO FINALIZADOR DE TWILIGHT =====
	if inimigo_finalizador_step():
		if sprite_index != spr_ia_dano:
			sprite_index = spr_ia_dano
			image_index = 0
		image_speed = 0.5
		atordoado = maxf(atordoado, 2)
		if not no_chao:
			velv += grav_ia * dt
		elif velv > 0:
			velv = 0
		image_xscale = escala
		image_yscale = escala
		return
	var p = instance_find("obj_player", 0)
	var tem_alvo: bool = p != null and not p.morto
	var dx := 0.0
	var dy := 0.0
	if tem_alvo:
		dx = p.x - x
		dy = p.y - y
	var adx := absf(dx)
	# ===== CAMPO DE VISÃO = a mesma área da câmera do jogador =====
	var ve := false
	if tem_alvo:
		ve = x >= G.view_x and x <= G.view_x + G.view_w and y - 20 >= G.view_y and y - 60 <= G.view_y + G.view_h
	if ve and not viu:
		viu = true
		alerta_fx = 40
	if tem_alvo:
		inimigo_regra_atordoamento(p)
	var estava_atordoado := atordoado > 0
	if inimigo_atordoamento_step(dt):
		if no_chao:
			velh = 0
		if sprite_index != spr_ia_dano:
			sprite_index = spr_ia_dano
			image_index = 0
		image_speed = 1.4
	else:
		if estava_atordoado:
			estado_ia = "fugir" if adx < distancia_fuga else "parado"
			image_speed = 1
		match estado_ia:
			"parado":
				velh = 0
				if sprite_index != spr_ia_dano:
					trocar_sprite(spr_ia_parado, 1)
				if tem_alvo and viu and adx > distancia_max and adx < 900 and absf(dy) < 200:
					estado_ia = "aproximar"
				elif ve:
					inimigo_virar(dx)
					var lado_fuga := -1.0 if dx >= 0 else 1.0
					if adx < distancia_fuga and pode_fugir(lado_fuga):
						estado_ia = "fugir"
					elif recarga <= 0 and absf(dy) < 160 and instance_number("obj_flecha") + instance_number("obj_frasco_veneno") < dif_valor([2, 2, 3, 4]):
						estado_ia = "atirar"
						flecha_solta = false
						fala_ataque(self, falas_arqueiro(), Color8(70, 40, 100), 0.35)  # v1.18
						sprite_index = spr_ia_ataque
						image_index = 0
						image_speed = 1.8
			"fugir":
				var fuga := -1.0 if dx >= 0 else 1.0
				if not tem_alvo or adx >= distancia_segura or not pode_fugir(fuga):
					if tem_alvo and not pode_fugir(fuga):
						recarga = minf(recarga, 70)
					estado_ia = "parado"
					velh = 0
					if tem_alvo:
						inimigo_virar(dx, true)
				else:
					dir = fuga
					velh_para(fuga * vel_fuga, 0.4, 0.6)
					trocar_sprite(spr_ia_correr, 1.3)
			"aproximar":
				if not tem_alvo or adx <= distancia_ideal or absf(dy) >= 200:
					estado_ia = "parado"
					velh = 0
					recarga = minf(recarga, 100)
				else:
					inimigo_virar(dx, true)
					if place_meeting(x + dir * 12, y - 2, "obj_chao") or not pode_andar(dir):
						estado_ia = "parado"
						velh = 0
					else:
						velh_para(dir * vel_aproximar, 0.4, 0.6)
						trocar_sprite(spr_ia_correr, 1.3)
			"atirar":
				velh = 0
				image_speed = 1.8
				if not flecha_solta and image_index >= 5:
					flecha_solta = true
					disparar(x + dir * 17 * escala, y - 21 * escala, p if tem_alvo else null)
	if empurrao != 0:
		velh += empurrao
		empurrao = lerp_dt(empurrao, 0, 0.16)
		if absf(empurrao) < 0.2:
			empurrao = 0
	if not no_chao:
		velv += grav_ia * dt
	elif velv > 0:
		velv = 0
	image_xscale = escala
	image_yscale = escala


func ev_anim_end() -> void:
	if not ativo:
		return
	if morrendo:
		if sprite_index == spr_morrer:
			image_index = image_number - 1
			image_speed = 0
			morte_fim = true
		return
	if estado_ia == "atirar" and sprite_index == spr_ia_ataque:
		estado_ia = "parado"
		recarga = recarga_max
		trocar_sprite(spr_ia_parado, 1)
		return
	if sprite_index == spr_ia_dano and atordoado <= 0:
		trocar_sprite(spr_ia_parado, 1)


func ev_draw() -> void:
	if not ativo:
		inimigo_portal_desenhar(spr_ia_parado, escala)
		return
	if portal_raio > 0:
		desenhar_portal(x, y, portal_raio, current_time() / 16.0)
	if place_meeting(x, y + 2, "obj_chao"):
		draw_set_alpha(0.3 * image_alpha * inimigo_sombra_alpha())
		draw_set_color(c_black)
		draw_ellipse(x - 14, y - 3, x + 14, y + 3, false)
		draw_set_alpha(1)
	var trem := sin(atordoado_anim * 1.4) * 1.2 if atordoado > 0 else 0.0
	if flash_dano > 0 and not morrendo:
		gpu_set_fog(true, c_white)
		draw_sprite_hd(sprite_index, image_index, x + trem, y, dir * escala, escala, 0, c_white, image_alpha)
		gpu_set_fog(false, c_white)
	else:
		var cor2 := merge_color(cor_ia, Color8(255, 170, 150), 0.7) if imune_atordoar > 0 else cor_ia
		if morrendo and morte_fim:
			cor2 = Color8(170, 160, 160)
		if executando:
			trem = randf_range(-1.5, 1.5)
		inimigo_corpo_desenhar(sprite_index, image_index, x + trem, y, dir * escala, escala, 0, cor2, image_alpha)
	if morrendo:
		return
	var topo := bbox_top - 10
	gpu_set_texfilter(true)
	if finalizavel:
		desenhar_icone_finalizador(x, topo - 18)
	if alerta_fx > 0:
		txt(x, topo - (40 - alerta_fx) * 0.2, "!", FONTE.MEDIA, Color8(255, 170, 60), clampf(alerta_fx / 12.0, 0, 1), fa_center, fa_bottom, 0.8)
	if estado_ia == "atirar" and not flecha_solta:
		var ma := clampf(image_index / 5.0, 0, 1)
		gpu_set_blendmode(bm_add)
		draw_set_alpha(ma * 0.8)
		draw_set_color(Color8(255, 120, 60))
		draw_circle(x + dir * 20 * escala, y - 21 * escala, 2 + 2 * ma, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	if barra_tempo > 0 and vida > 0:
		var a := minf(1, barra_tempo / 24.0)
		var larg := 40.0
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
	if atordoado > 0:
		draw_set_color(Color8(255, 230, 110))
		for k in 3:
			var ang := atordoado_anim * 7 + k * 120
			var sx := x + lengthdir_x(12, ang)
			var sy := topo - 14 + lengthdir_y(3, ang)
			draw_set_alpha(0.65 + 0.35 * dsin(ang))
			draw_circle(sx, sy, 2.5, false)
		draw_set_alpha(1)
	if G.debug_hitbox:
		draw_set_alpha(0.9)
		draw_set_color(c_orange)
		draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true)
		txt(x, bbox_bottom + 4, estado_ia + "  recarga " + str(int(maxf(0, ceil(recarga / 60.0)))) + "s", FONTE.MINI, c_yellow, 1, fa_center, fa_top, 0.45)
	gpu_set_texfilter(false)
	desenho_resetar()
