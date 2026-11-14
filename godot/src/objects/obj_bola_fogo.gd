extends Lib
# =====================================================================
#  obj_bola_fogo — projétil do boss (spr_boss_01_bola_de_fogo)
#  Voa até "alcance" e estoura. A explosão só fere o jogador se ele
#  estiver DENTRO da área; fora dela, a bola apenas estoura.
# =====================================================================

var vx := 0.0
var vy := 0.0
var dano := 18.0
var alcance := 560.0
var dist := 0.0
var explodindo := false
var refletida := false
var raio_explosao := 54.0
var escala := 1.7
var ang := 0.0
var hs_on := false
var hs_vel := 1.0
# "semente" é a variação lançada pelo ataque novo da Árvore Amaldiçoada.
var variante := "fogo"
var gravidade := 0.0
var raiz_ao_pousar := false


func ev_create() -> void:
	sprite_index = Spr.spr_boss_01_bola_de_fogo
	image_index = 0
	image_speed = 1.4
	mask_index = Spr.spr_hitbox
	image_xscale = 1
	image_yscale = 1


func explodir(pode_ferir: bool) -> void:
	if explodindo:
		return
	explodindo = true
	image_index = 7
	image_speed = 1.3
	vx = 0
	vy = 0
	# A semente cria uma raiz menor depois de cair. A raiz conserva a própria
	# janela de aviso, portanto não existe dano invisível ao tocar o chão.
	if raiz_ao_pousar and not refletida:
		var solo := chao_abaixo(x, y - 80, 180)
		var r = instance_create_depth(x, solo, depth - 2, "obj_raiz")
		r.dano = maxf(1, round(dano * 0.9))
		r.atraso = 8
		r.alt = 72
		r.meia = 15
	var p = instance_find("obj_player", 0)
	if p != null and point_distance(x, y, p.x, p.y) < 500:
		G.camera_impact = maxf(G.camera_impact, 7)
	som_em("fogo_explosao", x, y, 0.8)
	if pode_ferir and not refletida and p != null and not p.morto:
		var cy: float = (p.bbox_top + p.bbox_bottom) / 2.0
		if point_distance(x, y, p.x, cy) <= raio_explosao + 10:
			p.levar_dano(dano, x, true, 6)


func ev_step() -> void:
	var dt := G.dt
	if not explodindo:
		if variante == "semente":
			vy += gravidade * dt
		x += vx * dt
		y += vy * dt
		dist += sqrt(vx * vx + vy * vy) * dt
		ang = point_direction(0, 0, vx, vy)
		if image_index >= 6.9:
			image_index = 0
		var p = instance_find("obj_player", 0)
		var intang: bool = p != null and p.jogador_intangivel()
		var toca: bool = p != null and not p.morto and not refletida \
			and point_in_rectangle(x, y, p.bbox_left - 6, p.bbox_top - 6, p.bbox_right + 6, p.bbox_bottom + 6)
		if refletida:
			var b = collision_point(x, y, "obj_inimigo_base")
			if b != null and not b.morrendo and b.ativo:
				var gw := {"chave": "fogo", "especial": false, "pesado": true, "porcento": 0, "dano": 0, "combo": 0}
				var dn: float = maxf(1, round(b.vida_max * 0.04)) if b.eh_boss else b.vida_max
				b.levar_dano(dn, x - vx, false, 6, null, gw)
				explodir(false)
				return
		if toca and intang:
			toca = false
		if toca and p.janela_aparar > 0 and signf(x - p.x) == p.facing:
			# APARADA: a bola de fogo volta para a Árvore
			jogador_aparou(null)
			refletida = true
			vx = -vx * 1.25
			vy = -vy * 0.6
			dist = 0
			alcance = 900
		elif toca and p.bloqueando and signf(x - p.x) == p.facing:
			jogador_bloqueou(x)
			explodir(false)
		elif toca:
			explodir(true)
		elif dist >= alcance or position_meeting(x, y + 6, "obj_chao") or y > G.room_height:
			explodir(true)
	else:
		# o quadro 10 da sprite está com defeito (faixas): termina no 9
		if image_index >= 9.8:
			instance_destroy()


func ev_draw() -> void:
	var e := escala * 1.35 if explodindo else escala
	var cor_proj := Color8(120, 235, 105) if variante == "semente" else Color8(205, 150, 255)
	gpu_set_blendmode(bm_add)
	if not explodindo:
		draw_set_alpha(0.45)
		draw_set_color(Color8(80, 220, 90) if variante == "semente" else Color8(150, 50, 255))
		draw_circle(x, y, 17, false)
		draw_set_alpha(0.5)
		draw_set_color(Color8(210, 255, 190) if variante == "semente" else Color8(230, 190, 255))
		draw_circle(x, y, 7, false)
	else:
		var p := clampf((image_index - 7) / 3.0, 0, 1)
		draw_set_alpha(0.45 * (1 - p))
		draw_set_color(Color8(100, 220, 80) if variante == "semente" else Color8(170, 70, 255))
		draw_circle(x, y, raio_explosao * (0.4 + 0.6 * p), false)
		draw_set_alpha(0.8 * (1 - p))
		draw_circle(x, y, raio_explosao * (0.4 + 0.6 * p), true)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_sprite_ext(sprite_index, image_index, x, y, e, e, 0.0 if explodindo else ang, cor_proj, 1)
	if G.debug_hitbox:
		draw_set_color(c_orange)
		draw_circle(x, y, raio_explosao, true)
	draw_set_color(c_white)
