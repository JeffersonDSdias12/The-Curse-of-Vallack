extends ObjParedeQuebravel
# =====================================================================
#  obj_muro_segredo — muro rachado AO FUNDO (não bloqueia o caminho)
#  Quebrado com golpes, revela um esconderijo com orbs.
# =====================================================================


func ev_create() -> void:
	super()
	if _destruido:
		return
	solido_remover(solido)
	solido = null
	sprite_index = Spr.spr_muro_segredo
	segredo = true
	vida = 5
	vida_max = 5
	orbs_valor = ORBS_SEGREDO
	image_blend = Color8(150, 140, 138)
