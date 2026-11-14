extends Lib
# =====================================================================
#  obj_checkpoint — CRISTAL MÁGICO de checkpoint
#  Ao passar por ele o progresso é salvo automaticamente.
# =====================================================================

var ativado := false
var ativacao_fx := 0.0
var chao_y := 0.0


func ev_create() -> void:
	image_alpha = 0
	chao_y = chao_abaixo(x, y - 40)


func ev_step() -> void:
	if ativacao_fx > 0:
		ativacao_fx -= G.dt
	if not ativado and instance_exists("obj_player"):
		var entrou = collision_rectangle(x - 40, y - 90, x + 40, y + 30, "obj_player")
		if entrou != null and not entrou.morto:
			ativado = true
			ativacao_fx = 45
			G.checkpoint_ativo = true
			G.checkpoint_room = G.room
			G.checkpoint_x = entrou.x
			G.checkpoint_y = entrou.y
			salvar_slot(G.save_slot_atual, false)
			progresso_marcar()
			aviso_mostrar("CHECKPOINT SALVO AUTOMATICAMENTE", false)
			G.camera_impact = maxf(G.camera_impact, 4)


func ev_draw() -> void:
	var t := current_time() / 16.0
	var cor_cristal := Color8(70, 190, 255) if ativado else Color8(125, 80, 220)
	var cor_brilho := Color8(110, 230, 255) if ativado else Color8(170, 110, 255)
	var br := 1.0 if ativado else 0.5
	var cy := chao_y - 66 + sin(t * 0.05) * 4
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.22 * br)
	draw_set_color(cor_brilho)
	draw_ellipse(x - 34, chao_y - 7, x + 34, chao_y + 7, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(0.8 * br)
	draw_set_color(cor_brilho)
	draw_ellipse(x - 28, chao_y - 5, x + 28, chao_y + 5, true)
	for k in 6:
		var a := t * 1.5 + k * 60
		draw_circle(x + lengthdir_x(28, a), chao_y + lengthdir_y(5, a), 1.5, false)
	if ativado:
		gpu_set_blendmode(bm_add)
		retangulo_gradiente(x - 12, chao_y - 190, x + 12, chao_y, cor_brilho, 0, cor_brilho, 0.22 + 0.06 * sin(t * 0.1))
		gpu_set_blendmode(bm_normal)
	desenhar_cristal(x, cy, 10, cor_cristal, cor_brilho, br, t)
	gpu_set_blendmode(bm_add)
	draw_set_color(cor_brilho)
	for pi_ in (8 if ativado else 4):
		var f := frac(t / 120.0 + pi_ / 8.0)
		draw_set_alpha((1 - f) * 0.8 * br)
		draw_circle(x + sin(pi_ * 2.3 + t / 30.0) * 18, chao_y - f * 110, 1.4, false)
	if ativacao_fx > 0:
		var o := 1 - ativacao_fx / 45.0
		draw_set_alpha(1 - o)
		draw_circle(x, cy, 10 + 70 * o, true)
		draw_circle(x, cy, 8 + 60 * o, true)
	gpu_set_blendmode(bm_normal)
	var p = instance_find("obj_player", 0)
	if not ativado and p != null and absf(p.x - x) < 160:
		gpu_set_texfilter(true)
		txt(x, cy - 30, "CRISTAL MÁGICO · CHECKPOINT", FONTE.MINI, Color8(200, 170, 255), 0.9, fa_center, fa_bottom, 0.5)
		gpu_set_texfilter(false)
	desenho_resetar()
