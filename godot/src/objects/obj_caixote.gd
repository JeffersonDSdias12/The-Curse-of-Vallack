class_name ObjCaixote
extends ObjDestrutivel
# =====================================================================
#  obj_caixote — caixote de madeira (32 x 32)
#  * quebra com golpes (2 golpes normais ou 1 pesado/especial)
#  * jogador e inimigos sobem e andam em cima (bloco sólido)
#  * pode guardar orbs ou esconder um BAÚ DE VIDA (obj_bau no mesmo lugar)
#  * cai se o que está embaixo quebrar
# =====================================================================

var conteudo := "nada"
var orbs_valor := 10
var bau = null
var ligado := false
var velv := 0.0
var dx_solido := 0.0
var dy_solido := 0.0
var _conferir := 0              # v1.19: passos até conferir de novo o apoio (parado)
var _sx_ant := -99999.0         # última posição em que o sólido foi movido
var _sy_ant := -99999.0


func ev_create() -> void:
	super()
	vida = 2
	vida_max = 2
	sprite_index = Spr.spr_caixote
	image_speed = 0
	image_index = 0
	conteudo = choose(["nada", "nada", "orbs"])
	orbs_valor = randi_range(6, 14)
	bau = null
	ligado = false
	velv = 0
	var l := bbox_left
	var t := bbox_top
	var r := bbox_right + 1
	var b := bbox_bottom + 1
	solido = solido_criar(l, t, r, b)
	dx_solido = l - x
	dy_solido = t - y


func ao_bater(_forca: float) -> void:
	image_index = 1
	som_em("dest_quique", x, y, 0.7)
	fx_em("lascas", x, y - 16, 0.45, lado_golpe)


func ao_quebrar(lado: float) -> void:
	caixote_quebrar(lado)


# Caixote: o que tem dentro ("nada", "orbs" ou "bau")
func caixote_quebrar(lado: float) -> void:
	som_em("dest_madeira", x, y, 1)
	fx_em("lascas", x, y - 16, 1.1, lado)
	fx_em("poeira", x, y, 0.7, lado)
	G.camera_impact = maxf(G.camera_impact, 3)
	if conteudo == "orbs":
		orbs_soltar(x, y - 18, orbs_valor)
	if randf() < 0.2:
		essencia_soltar(x, y - 20, 1)
	if G.existe(bau):
		bau.bau_revelar()
	solido_remover(solido)
	solido = null
	instance_destroy()


func ev_step() -> void:
	super()
	var dt := G.dt
	# liga o baú escondido dentro dele (colocado no mesmo lugar na sala)
	if not ligado:
		ligado = true
		var b = instance_nearest(x, y, "obj_bau")
		if b != null and absf(b.x - x) < 20 and absf(b.y - y) < 40 and b.estado == "fechado":
			bau = b
			conteudo = "bau"
			b.visivel = false
	# gravidade: cai quando não há nada embaixo (o próprio bloco sai da frente)
	if G.existe(solido):
		# v1.19 (60 FPS): parado, só confere o apoio a cada 4 passos; longe da
		# câmera, nem isso (eram ~20 consultas de colisão por quadro à toa)
		if velv == 0:
			if absf(x - (G.view_x + G.view_w * 0.5)) > 700:
				return
			_conferir -= 1
			if _conferir > 0:
				return
			_conferir = 4
		var livre := not G.chao_colide_inst(self, x, y + 1, solido)
		if livre or velv != 0:
			velv = minf(velv + 0.4 * dt, 10)
			var mv := velv * dt
			if G.chao_colide_inst(self, x, y + mv, solido):
				var s := 0
				while not G.chao_colide_inst(self, x, y + 1, solido) and s < 64:
					y += 1
					s += 1
				if velv > 3:
					som_em("dest_quique", x, y, 0.5)
					fx_em("poeira", x, y, 0.5)
				velv = 0
			else:
				y += mv
		if x != _sx_ant or y != _sy_ant:
			_sx_ant = x
			_sy_ant = y
			solido_mover(solido, x + dx_solido, y + dy_solido)
		if G.existe(bau) and not bau.visivel:
			bau.x = x
			bau.y = y
	if y > G.room_height + 100:
		instance_destroy()


func ev_draw() -> void:
	var tx := randf_range(-tremor, tremor) * 0.3 if tremor > 0 else 0.0
	if flash > 0:
		gpu_set_fog(true, Color8(255, 230, 190))
		draw_sprite_ext(sprite_index, image_index, x + tx, y, 1, 1, 0, c_white, 1)
		gpu_set_fog(false, c_white)
	else:
		draw_sprite_ext(sprite_index, image_index, x + tx, y, 1, 1, 0, c_white, 1)
	# brilho dourado nas frestas: tem um baú de vida dentro
	if conteudo == "bau":
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.25 + 0.15 * sin(current_time() / 220.0))
		draw_set_color(Color8(255, 190, 80))
		draw_rectangle(x - 13, y - 17, x + 13, y - 15, false)
		draw_rectangle(x - 13, y - 8, x + 13, y - 7, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
