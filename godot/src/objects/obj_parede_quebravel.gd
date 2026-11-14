class_name ObjParedeQuebravel
extends ObjDestrutivel
# =====================================================================
#  obj_parede_quebravel — parede de pedra rachada que bloqueia o caminho
#  * golpes normais tiram 1, pesados 2 e especiais 3 (6 no total)
#  * quebrada, libera a passagem (e pode esconder orbs)
#  * fica gravada como quebrada no save
# =====================================================================

var segredo := false
var orbs_valor := 15
var chave := ""


func ev_create() -> void:
	super()
	vida = 6
	vida_max = 6
	sprite_index = Spr.spr_parede_rachada
	image_speed = 0
	image_index = 0
	chave = aberto_chave("parede", xstart, ystart)
	if aberto_tem(chave):
		instance_destroy()
		return
	solido = solido_criar(bbox_left, bbox_top, bbox_right + 1, bbox_bottom + 1)


func ao_bater(_forca: float) -> void:
	image_index = clampi(int(floor((1 - vida / vida_max) * 3)), 0, 2)
	som_em("dest_quique", x, y, 0.8, 0.12)
	fx_em("poeira", x - lado_golpe * 14, y - 40, 0.5, lado_golpe)
	G.camera_impact = maxf(G.camera_impact, 3)


func ao_quebrar(lado: float) -> void:
	aberto_marcar(chave)
	som_em("dest_pedra", x, y, 1, 0)
	fx_em("entulho", x, y, 1.2, lado)
	fx_em("poeira", x, y, 1.6, lado)
	G.camera_impact = maxf(G.camera_impact, 10)
	if orbs_valor > 0:
		orbs_soltar(x, y - 40, orbs_valor)
	if segredo:
		aviso_mostrar("SEGREDO ENCONTRADO!  +" + str(orbs_valor) + " ORBS")
		som("sfx_segredo", 0.8, 0)
		V117.perfil_somar("segredos")    # v1.17: conquista OLHOS DE CAÇADOR
	solido_remover(solido)
	solido = null
	instance_destroy()


func ev_draw() -> void:
	var tx := randf_range(-tremor, tremor) * 0.35 if tremor > 0 else 0.0
	if flash > 0:
		gpu_set_fog(true, Color8(255, 225, 200))
		draw_sprite_ext(sprite_index, image_index, x + tx, y, image_xscale, image_yscale, 0, image_blend, 1)
		gpu_set_fog(false, c_white)
	else:
		draw_sprite_ext(sprite_index, image_index, x + tx, y, image_xscale, image_yscale, 0, image_blend, 1)
	# luz vermelha passando pelas rachaduras (dica de que dá para quebrar)
	gpu_set_blendmode(bm_add)
	draw_set_alpha((0.10 + 0.07 * sin(current_time() / 300.0)) * (1 + floor(image_index)))
	draw_set_color(Color8(255, 60, 40) if segredo else Color8(255, 130, 60))
	var h := sprite_index.h * image_yscale
	draw_ellipse(x - 14, y - h * 0.75, x + 14, y - h * 0.2, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
