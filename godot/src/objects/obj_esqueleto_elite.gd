extends ObjEsqueleto
# obj_esqueleto_elite — ESQUELETO DE ELITE (v1.12). Mesmas regras da besta
# de elite (elite_aplicar).


func ev_create() -> void:
	super()
	elite_aplicar()
