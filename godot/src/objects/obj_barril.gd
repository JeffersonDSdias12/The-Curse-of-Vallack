extends ObjCaixote
# =====================================================================
#  obj_barril — barril de madeira (v1.11). Filho do obj_caixote: quebra
#  com golpes, dá para subir nele, cai se perder o apoio e pode guardar
#  orbs (mais vezes que o caixote) ou esconder um baú de vida.
# =====================================================================


func ev_create() -> void:
	super()
	sprite_index = Spr.spr_barril
	conteudo = choose(["nada", "orbs", "orbs"])
	orbs_valor = randi_range(8, 16)
