extends Lib
# =====================================================================
#  obj_morador — morador da vila (v1.12)
#  Quando Twilight chega perto, conversa com ele e foge para a ponte do
#  norte. A conversa acontece uma vez (fica no save).
# =====================================================================

var estado := "parado"
var dir := 1.0
var chave := ""


func ev_create() -> void:
	sprite_index = Spr.spr_morador_parado
	image_speed = 1
	estado = "parado"
	dir = 1
	depth = 120
	chave = aberto_chave("morador", xstart, ystart)
	if aberto_tem(chave):
		instance_destroy()


func ev_step() -> void:
	var dt := G.dt
	var p = instance_find("obj_player", 0)
	match estado:
		"parado":
			if p != null:
				dir = -1.0 if p.x < x else 1.0
			if p != null and not p.morto and absf(p.x - x) < 120 and absf(p.y - y) < 90 \
					and not instance_exists("obj_dialogo") and not instance_exists("obj_pausa") \
					and not instance_exists("obj_loading") and not instance_exists("obj_save_menu"):
				estado = "conversando"
				var d = dialogo_iniciar("morador", func():
					for m in todos("obj_morador"):
						m.estado = "fugindo"
						m.sprite_index = Spr.spr_morador_correndo
						m.image_index = 0
						aberto_marcar(m.chave))
				if d == null:
					estado = "parado"
		"fugindo":
			dir = -1
			x -= 3.4 * dt
			if x < -40 or x < G.view_x - 60:
				instance_destroy()


func ev_draw() -> void:
	if not cenario_na_tela(x - 40, x + 40):
		return
	draw_set_alpha(0.3)
	draw_set_color(c_black)
	draw_ellipse(x - 12, y - 3, x + 12, y + 3, false)
	draw_set_alpha(1)
	cenario_luz(x + dir * 9, y - 28, 64, 0.8 + 0.1 * sin(current_time() / 90.0), Color8(255, 190, 90))
	draw_sprite_hd(sprite_index, image_index, x, y, dir, 1, 0, c_white, 1)
	if estado == "parado":
		gpu_set_texfilter(true)
		txt_sombra(x, y - 78, "!", FONTE.MEDIA, Color8(255, 230, 140), 0.6 + 0.4 * sin(current_time() / 200.0), fa_center, fa_bottom, 0.7)
		gpu_set_texfilter(false)
	desenho_resetar()
