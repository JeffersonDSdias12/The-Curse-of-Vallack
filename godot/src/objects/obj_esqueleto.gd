class_name ObjEsqueleto
extends ObjInimigo01
# =====================================================================
#  obj_esqueleto — ESQUELETO GUERREIRO (filho do obj_inimigo_01)
#  * rápido e com GOLPE DUPLO: corte largo (quadros 2-3) e estocada (6-7)
#  * REERGUER: derrubado por golpes comuns, desmonta numa pilha de ossos e
#    se levanta ~3,5 s depois com metade da vida (uma vez só). Golpear a
#    pilha, especiais, a Fúria, o finalizador e projéteis rebatidos acabam
#    com ele de vez.
# =====================================================================

var reerguido := false
var caido_t := 0.0
var caido_dur := 210.0
var erguer_t := 0.0
var andar_t := 0.0
var andar_img := 0.0


func ev_create() -> void:
	super()
	mask_index = Spr.spr_mascara_esqueleto
	image_xscale = 1
	image_yscale = 1
	escala_vis = 1.6
	topo_vis = 74
	sombra_larg = 13
	usa_hud_nivel = true
	inimigo_status(45)
	dano_ataque = inimigo_dano(7)
	recarga_max = round(40 * dif_recarga_inimigo())
	vel_correr = 2.3 * dif_velocidade()
	zona_pulo_max = 0
	alcance_ataque = 46
	distancia_minima = 34
	golpe_janelas = [[2, 3], [6, 7]]
	golpe_caixa = [4, 44, -50, -6]
	vel_ataque = 0.7
	falas = falas_esqueleto()
	cor_fala = cor_fala_esqueleto()
	spr_ia_parado = Spr.spr_esqueleto_parado
	spr_ia_andar = Spr.spr_esqueleto_andando
	spr_ia_correr = Spr.spr_esqueleto_correndo
	spr_ia_ataque = Spr.spr_esqueleto_ataque
	spr_ia_pular = Spr.spr_esqueleto_correndo
	spr_ia_atordoado = Spr.spr_esqueleto_dano
	vel_atordoado = 0.9
	spr_morrer = Spr.spr_esqueleto_morrendo
	sprite_index = spr_ia_parado
	image_index = randi_range(0, spr_ia_parado.n - 1)
	image_speed = 1


func reagir_dano(_dano: float, d: float, forca: float) -> void:
	# golpe na pilha de ossos: agora acabou de vez
	if estado_ia == "caido" or estado_ia == "erguendo":
		vida = 0
		som_em("osso_quebra", x, y, 0.95)
		inimigo_morrer(d)
		velh = 0
		image_index = spr_morrer.n - 1
		image_speed = 0
		morte_fim = true
		for i in (3 if G.cfg_qualidade == 0 else 7):
			var f = instance_create_depth(x + randf_range(-16, 16), y - randf_range(4, 20), -100, "obj_fagulha")
			f.cor = choose([Color8(230, 220, 200), Color8(200, 40, 30)])
		return
	empurrao = d * forca * 0.25
	inimigo_atordoar(30)
	if vida <= 0:
		if not reerguido and not finalizado and not golpe_e_forte(ultimo_golpe):
			# REERGUER: desmonta numa pilha de ossos (ainda não foi derrotado)
			estado_ia = "caido"
			caido_t = 0
			vida = 1
			barra_tempo = 0
			atordoado = 0
			finalizavel = false
			executando = false
			pulando = false
			pode_lancar = false
			tempo_invencivel = 18
			velh = d * 1.2
			empurrao = 0
			sprite_index = spr_morrer
			image_index = 0
			image_speed = 0
			som_em("osso_desmonta", x, y, 0.9)
			fala_aleatoria(self, falas_esqueleto_cai(), cor_fala, 0.6)
			return
		inimigo_morrer(d)
		som_em("osso_desmonta", x, y, 0.8)
	elif randf() < 0.12:
		fala_dizer(self, choose(["Clec!", "Crac!", "Meus ossos!"]), cor_fala)


# Brilho da pilha de ossos (vai se levantar) e névoa ao se erguer
func desenhar_extra() -> void:
	if estado_ia == "caido":
		var r := clampf((caido_t - (caido_dur - 80)) / 80.0, 0, 1)
		if r > 0:
			var pu := 0.5 + 0.5 * sin(current_time() / 70.0)
			gpu_set_blendmode(bm_add)
			draw_set_alpha(r * (0.25 + 0.25 * pu))
			draw_set_color(Color8(200, 40, 40))
			draw_ellipse(x - 22, y - 16, x + 22, y + 2, false)
			draw_set_alpha(r * 0.8)
			draw_set_color(Color8(255, 90, 70))
			draw_circle(x + dir * 4, y - 9, 1.6 + pu, false)
			draw_circle(x + dir * 9, y - 9, 1.6 + pu, false)
			gpu_set_blendmode(bm_normal)
			draw_set_alpha(1)
	elif estado_ia == "erguendo":
		var e := clampf(erguer_t / 45.0, 0, 1)
		gpu_set_blendmode(bm_add)
		draw_set_color(Color8(190, 50, 255))
		for k in 5:
			var fy := y - fmod(erguer_t * 2.2 + k * 13, 64)
			draw_set_alpha(0.45 * (1 - e * 0.5) * (1 - (y - fy) / 64.0))
			draw_circle(x + sin(erguer_t * 0.2 + k * 1.7) * 14, fy, 2.5, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)


func ev_step() -> void:
	var dt := G.dt
	if ativo and not morrendo and (estado_ia == "caido" or estado_ia == "erguendo"):
		if tempo_invencivel > 0:
			tempo_invencivel = maxf(0, tempo_invencivel - dt)
		if flash_dano > 0:
			flash_dano -= dt
		if alerta_fx > 0:
			alerta_fx -= dt
		atordoado = 0
		finalizavel = false
		barra_tempo = 0
		velh = lerp_dt(velh, 0, 0.15)
		if absf(velh) < 0.05:
			velh = 0
		var nc := place_meeting(x, y + 1, "obj_chao")
		if not nc:
			velv += grav_ia * dt
		elif velv > 0:
			velv = 0
		if y > G.room_height + 300:
			instance_destroy()
			return
		sprite_index = spr_morrer
		image_speed = 0
		var n := spr_morrer.n
		if estado_ia == "caido":
			caido_t += dt
			image_index = minf(n - 1, caido_t * 0.16)
			if caido_t >= caido_dur - 50 and floor((caido_t - dt) / 12.0) != floor(caido_t / 12.0):
				som_em("osso_chocalho", x, y, 0.45)
			if caido_t >= caido_dur:
				estado_ia = "erguendo"
				erguer_t = 0
				som_em("osso_ergue", x, y, 0.85)
				fala_aleatoria(self, falas_esqueleto_ergue(), cor_fala, 1)
		else:
			erguer_t += dt
			image_index = maxf(0, (n - 1) - erguer_t * 0.2)
			if erguer_t >= (n - 1) / 0.2:
				# de pé de novo, com metade da vida (não se levanta uma segunda vez)
				estado_ia = "perseguir"
				reerguido = true
				pode_lancar = true
				vida = maxf(1, round(vida_max * 0.5))
				vida_atraso = vida
				barra_tempo = 120
				imune_atordoar = 50
				recarga = 18
				alerta_fx = 40
				alertado = true
				andar_t = 66
				sprite_index = spr_ia_parado
				image_index = 0
				image_speed = 1
				G.camera_impact = maxf(G.camera_impact, 3)
				for i in (2 if G.cfg_qualidade == 0 else 5):
					var f = instance_create_depth(x + randf_range(-12, 12), y - randf_range(10, 50), -100, "obj_fagulha")
					f.cor = Color8(200, 70, 255)
		return
	super()
	# a animação de dano termina com o esqueleto desmontado: em loop só nos quadros 0-7
	if sprite_index == Spr.spr_esqueleto_dano and image_index >= 7.9:
		image_index = 1
	# recém-erguido: ainda cambaleia, ANDANDO, antes de voltar a correr
	if andar_t > 0:
		andar_t -= dt
		if sprite_index == spr_ia_correr and estado_ia == "perseguir":
			sprite_index = spr_ia_andar
			andar_img = fmod(andar_img + 0.17 * dt, spr_ia_andar.n)
			image_index = andar_img
			image_speed = 0
			velh = clampf(velh, -vel_correr * 0.45, vel_correr * 0.45)
			anda_v = velh
