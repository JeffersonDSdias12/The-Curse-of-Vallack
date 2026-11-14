extends Lib
# obj_aviso — faixa de aviso no alto da tela (JOGO SALVO, CHECKPOINT...)

var texto := ""
var tempo := 0.0


func ev_step() -> void:
	tempo += G.dt_real
	if tempo > 150:
		instance_destroy()


func ev_draw_gui() -> void:
	var alfa := 1.0
	if tempo < 20:
		alfa = tempo / 20.0
	if tempo > 110:
		alfa = (150 - tempo) / 40.0
	alfa = clampf(alfa, 0, 1)
	var gw := G.gui_w
	var esc := minf(1, (gw - 110) / maxf(1, txt_largura(texto, FONTE.MEDIA)))
	var w := txt_largura(texto, FONTE.MEDIA, esc) + 70
	draw_set_alpha(0.75 * alfa)
	draw_set_color(Color8(12, 9, 8))
	draw_rectangle(gw / 2 - w / 2, 106, gw / 2 + w / 2, 154, false)
	draw_set_color(Color8(176, 141, 70))
	draw_rectangle(gw / 2 - w / 2, 106, gw / 2 + w / 2, 154, true)
	txt_sombra(gw / 2, 130, texto, FONTE.MEDIA, Color8(255, 210, 90), alfa, fa_center, fa_middle, esc)
	desenho_resetar()
