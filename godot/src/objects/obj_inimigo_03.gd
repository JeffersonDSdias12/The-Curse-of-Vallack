extends ObjInimigo01
# =====================================================================
#  obj_inimigo_03 — BESTA ESCUDEIRA (filha do obj_inimigo_01)
#  * um escudo de ferro segura os golpes que vêm da frente
#  * é preciso quebrar a guarda (pesados contam em dobro; especiais e a
#    Fúria quebram na hora) ou atacar pelas costas
# =====================================================================


func ev_create() -> void:
	super()
	inimigo_status(85)
	dano_ataque = inimigo_dano(10)
	recarga_max = round(60 * dif_recarga_inimigo())
	vel_correr = 1.5 * dif_velocidade()
	zona_pulo_max = 0
	escudo_max = dif_valor([3, 4, 5, 6])
	escudo_vida = escudo_max
	cor_base = Color8(165, 175, 190)
	sprite_index = spr_ia_parado
	falas = falas_escudo()
	cor_fala = Color8(70, 60, 30)


# o escudo na frente do corpo (racha conforme apanha)
func desenhar_extra() -> void:
	if escudo_vida <= 0 or (morrendo and morte_fim):
		return
	var q := clampi(int(floor((1 - float(escudo_vida) / escudo_max) * 3)), 0, 2)
	var ox := 18.0
	var oy := -38.0
	if estado_ia == "atacar" and image_index >= 3 and image_index < 7:
		ox = 28
	var tr := randf_range(-1.5, 1.5) if escudo_fx > 0 else 0.0
	draw_sprite_ext(Spr.spr_escudo, q, x + dir * ox + tr, y + oy, dir * 1.25, 1.25, 0, Color8(255, 230, 200) if escudo_fx > 0 else c_white, image_alpha)
