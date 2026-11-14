extends ObjInimigoBase
# =====================================================================
#  obj_estatua — ESTÁTUA ENFEITIÇADA (torre parada)
#  * PEDRA: enquanto dorme, os golpes comuns só tiram faíscas. Quando os
#    OLHOS ACENDEM ela desperta, carrega e dispara um ORBE que persegue
#    Twilight: só nesse momento (e logo depois) ela pode ser ferida.
#  * especiais, a Fúria e projéteis rebatidos ferem sempre
#  * aparado na hora certa, o orbe volta, racha a estátua e a deixa
#    vulnerável por alguns segundos
# =====================================================================

var escala := 1.25
var dano_orbe := 10.0
var recarga_max := 170.0
var campo := 600.0
var anim_t := 0.0
var orbe_solto := false
var vulneravel_t := 0.0
var rachada_t := 0.0
var tinido_t := 0.0
var falou := false
var morte_anim := 0.0
var falas: Array = []
var cor_fala := Color(1, 1, 1)
var spr_ia_parado: GMSprite


func ev_create() -> void:
	super()
	mask_index = Spr.spr_mascara_estatua
	image_xscale = 1
	image_yscale = 1
	escala = 1.25
	dir = -1
	resiste_atordoar = true
	pode_lancar = false
	inimigo_status(70)
	dano_orbe = inimigo_dano(10)
	recarga = randi_range(40, 90)
	recarga_max = round(170 * dif_recarga_inimigo())
	estado_ia = "pedra"
	estado_ao_surgir = "pedra"
	grav_ia = 0.4
	falas = falas_estatua()
	cor_fala = cor_fala_estatua()
	inimigo_portal_iniciar()
	spr_ia_parado = Spr.spr_estatua
	spr_morrer = Spr.spr_estatua
	sprite_index = Spr.spr_estatua
	image_index = 0
	image_speed = 0


func estatua_vulneravel() -> bool:
	return estado_ia == "desperta" or vulneravel_t > 0 or rachada_t > 0


# PEDRA: golpes comuns não ferem (só faíscas e um tinido)
func bloquear_golpe(golpe, origem_x: float) -> bool:
	if estatua_vulneravel() or golpe_e_forte(golpe):
		return false
	tinido_t = 10
	som_em("pedra_tinido", x, y, 0.8)
	var lado := -dir if origem_x == x else signf(origem_x - x)
	for i in 3:
		var f = instance_create_depth(x + lado * 20, y - randf_range(30, 70), -100, "obj_fagulha")
		f.cor = choose([Color8(255, 230, 160), Color8(180, 170, 150)])
	if golpe != null:
		for p in todos("obj_player"):
			p.empurrao = -p.facing * 1.6
	if randf() < 0.3:
		fala_aleatoria(self, falas_estatua_imune(), cor_fala, 1)
	return true


func reagir_dano(_dano: float, d: float, _forca: float) -> void:
	if vida <= 0:
		inimigo_morrer(d)
		velh = 0
		image_speed = 0
		morte_anim = 0
		som_em("pedra_desmorona", x, y, 1)
		fx_em("entulho", x, y, 0.8)
		fala_dizer(self, "A maldição... se parte...", cor_fala, true)
		return
	if randf() < 0.12:
		fala_dizer(self, choose(["Crac!", "Minha pedra!"]), cor_fala)


func ev_step() -> void:
	var dt := G.dt
	if inimigo_portal_step(dt):
		return
	if morrendo:
		inimigo_corpo_step(dt)
		velh = 0
		morte_anim += dt
		if morte_anim >= 50:
			morte_fim = true
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
	if vulneravel_t > 0:
		vulneravel_t = maxf(0, vulneravel_t - dt)
	if rachada_t > 0:
		rachada_t = maxf(0, rachada_t - dt)
	if tinido_t > 0:
		tinido_t = maxf(0, tinido_t - dt)
	atordoado = 0
	inimigo_finalizador_step()
	var no_chao := place_meeting(x, y + 1, "obj_chao")
	var p = instance_find("obj_player", 0)
	var tem_alvo: bool = p != null and not p.morto
	var dx := 0.0
	var dy := 0.0
	if tem_alvo:
		dx = p.x - x
		dy = p.y - y
	var dentro := tem_alvo and absf(dx) <= campo and absf(dy) <= 220 and inimigo_na_tela(-24)
	match estado_ia:
		"pedra":
			image_index = 0
			if tem_alvo and dx != 0:
				dir = signf(dx)
			if dentro and recarga <= 0:
				# OS OLHOS ACENDEM: desperta e começa a carregar o orbe
				estado_ia = "desperta"
				anim_t = 0
				orbe_solto = false
				alerta_fx = 30
				som_em("estatua_carga", x, y, 0.75)
				if not falou:
					fala_dizer(self, falas[randi() % falas.size()], cor_fala)
					falou = true
				else:
					fala_aleatoria(self, falas, cor_fala, 0.2)
		"desperta":
			anim_t += dt
			image_index = clampf(1 + anim_t * 0.075, 1, 5.99)
			if not orbe_solto and anim_t >= 40:
				orbe_solto = true
				vulneravel_t = 50
				var bx := x + dir * 4
				var by := y - 64
				var tx := bx + dir * 200
				var ty := by
				if tem_alvo:
					tx = p.x
					ty = p.y - 34
				var ang := point_direction(bx, by, tx, ty)
				var v := 4.4
				magia_criar("orbe", bx, by, lengthdir_x(v, ang), lengthdir_y(v, ang), dano_orbe, self)
				som_em("estatua_disparo", x, y, 0.85)
			if anim_t >= 66:
				estado_ia = "esfriando"
				anim_t = 0
		"esfriando":
			anim_t += dt
			image_index = 6 + minf(1.99, anim_t * 0.066)
			if anim_t >= 30:
				estado_ia = "pedra"
				recarga = recarga_max + randi_range(0, 50)
	velh = 0
	empurrao = 0
	if not no_chao:
		velv += grav_ia * dt
	elif velv > 0:
		velv = 0
	image_xscale = 1
	image_yscale = 1


func ev_draw() -> void:
	if not ativo:
		inimigo_portal_desenhar(Spr.spr_estatua, escala)
		return
	if portal_raio > 0:
		desenhar_portal(x, y, portal_raio, current_time() / 16.0)
	inimigo_sombra(24)
	var s := Spr.spr_estatua
	var k := hd_escala(s)
	var e := escala / k
	# ===== MORTE: desmorona de cima para baixo; sobra o entulho =====
	if morrendo:
		var m := clampf(morte_anim / 50.0, 0, 1)
		var w := s.w
		var h := s.h
		var ox := s.xo
		var oy := s.yo
		var resta := lerpf(oy, oy * 0.26, 1 - pow(1 - m, 2))
		var topo_p := maxf(0, floor(oy - resta))
		var tr := 0.0 if morte_fim else randf_range(-1.5, 1.5) * (1 - m)
		var ev := evaporar
		var sai := clampf((ev - 0.4) / 0.6, 0, 1)
		var al := image_alpha * (1 - sai * (2 - sai))
		var sub := 10 * sai
		tr += randf_range(-1, 1) * ev
		gpu_set_texfilter(true)
		if al > 0.01:
			draw_sprite_part_ext(s, 0, 0, topo_p, w, h - topo_p, x + tr - dir * ox * e, y - sub - (oy - topo_p) * e, dir * e, e,
				merge_color(c_white, Color8(90, 85, 80), m * 0.7), al)
			if ev > 0:
				# v1.17: o entulho arde em brasa (antes: silhueta negra)
				gpu_set_blendmode(bm_add)
				gpu_set_fog(true, merge_color(Color8(255, 70, 20), Color8(255, 170, 60), ev))
				draw_sprite_part_ext(s, 0, 0, topo_p, w, h - topo_p, x + tr - dir * ox * e, y - sub - (oy - topo_p) * e, dir * e, e, c_white, al * 0.6 * sin(PI * minf(1, ev * 1.2)))
				gpu_set_fog(false, c_white)
				gpu_set_blendmode(bm_normal)
		gpu_set_texfilter(false)
		return
	# ===== ESTÁTUA =====
	var trem := randf_range(-1, 1) if tinido_t > 0 else 0.0
	if estado_ia == "desperta" and not orbe_solto:
		trem += randf_range(-0.6, 0.6)
	var cor := c_white
	if estado_ia == "pedra" and vulneravel_t <= 0 and rachada_t <= 0:
		cor = Color8(200, 205, 195)
	if rachada_t > 0:
		cor = Color8(255, 190, 180)
	inimigo_desenhar_corpo(s, image_index, x + trem, y, dir * escala, escala, 0, cor, image_alpha)
	gpu_set_texfilter(true)
	if rachada_t > 0:
		draw_set_alpha(minf(1, rachada_t / 30.0))
		draw_set_color(Color8(40, 20, 20))
		draw_line_width(x - 8, y - 70, x + 2, y - 52, 2)
		draw_line_width(x + 2, y - 52, x - 4, y - 36, 2)
		draw_line_width(x + 2, y - 52, x + 14, y - 44, 1.5)
		draw_set_alpha(1)
	if estado_ia == "desperta" and not orbe_solto:
		var c := clampf(anim_t / 40.0, 0, 1)
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.25 + 0.5 * c)
		draw_set_color(Color8(255, 40, 60))
		draw_circle(x + dir * 4, y - 64, 3 + 9 * c, false)
		draw_set_alpha(0.6 * c)
		draw_set_color(Color8(255, 200, 200))
		draw_circle(x + dir * 4, y - 64, 2 + 3 * c, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	if estatua_vulneravel():
		var va := 0.6 + 0.4 * sin(current_time() / 70.0)
		txt(x, y + 5, "VULNERÁVEL", FONTE.MINI, Color8(255, 120, 90), va, fa_center, fa_top, 0.5)
	gpu_set_texfilter(false)
	inimigo_hud(y - 92, 46)
	inimigo_debug("  (vulnerável)" if estatua_vulneravel() else "  (pedra)")
	desenho_resetar()
