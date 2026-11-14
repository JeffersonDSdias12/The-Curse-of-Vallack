extends Lib
# obj_placa — placa de madeira com aviso (v1.11). Quando Twilight chega
# perto, o aviso aparece num pergaminho acima da placa.

var texto := ""
var mostrar := 0.0
var aviso_base := 0.0      # v1.14: o aviso sobe para não cobrir a cabeça de Twilight


func ev_create() -> void:
	image_speed = 0
	depth = 140
	texto = placa_texto(x)
	mostrar = 0
	aviso_base = y - 66


func ev_step() -> void:
	var p = instance_find("obj_player", 0)
	var perto: bool = p != null and absf(p.x - x) < 90 and absf(p.y - y) < 140
	# v1.14: com a dica do cristal de salvar na tela, o aviso da placa dá lugar a ela
	var sp = instance_nearest(x, y, "obj_save_point")
	if sp != null and sp.perto:
		perto = false
	mostrar = clampf(mostrar + (0.08 if perto else -0.06) * G.dt, 0, 1)
	# v1.14: com Twilight embaixo do pergaminho (subindo a escada ao lado da placa),
	# o aviso sobe acima da cabeça dele em vez de cobri-lo
	var alvo := y - 66
	if perto and p.bbox_bottom > alvo - 34 and p.bbox_top - 6 < alvo:
		alvo = p.bbox_top - 14
	aviso_base = lerp_dt(aviso_base, alvo, 0.25)


func ev_draw() -> void:
	if not cenario_na_tela(x - 120, x + 120):
		return
	draw_sprite(sprite_index, 0, x, y)


# o aviso fica na frente dos personagens
func ev_draw_end() -> void:
	placa_desenhar_aviso(x, aviso_base, texto, mostrar)
