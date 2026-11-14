extends Lib
# =====================================================================
#  obj_fundo_hd — fundo da fase 1 em alta definição
#  A spr_fundo_hd é a imagem do fundo ampliada 1,25x e suavizada,
#  desenhada por cima da camada de tiles original (y >= 280).
#  OPÇÕES > FUNDO HD desliga e volta ao fundo original.
# =====================================================================

var escala_hd := 1.25
var y0 := 280.0
var margem := 2.0
var larg_q := 0.0


func ev_create() -> void:
	larg_q = Spr.spr_fundo_hd.w - 2 * margem
	if G.cfg_fundo_hd == 0:
		instance_destroy()


func ev_draw() -> void:
	var s := 1.0 / escala_hd
	var cx1 := G.view_x
	var cx2 := cx1 + G.view_w
	var h := Spr.spr_fundo_hd.h
	gpu_set_texfilter(true)
	for i in Spr.spr_fundo_hd.n:
		var wx := i * larg_q * s
		var ww := larg_q * s
		if wx > cx2 or wx + ww < cx1:
			continue
		draw_sprite_part_ext(Spr.spr_fundo_hd, i, margem, 0, larg_q, h, wx, y0, s, s, c_white, 1)
	gpu_set_texfilter(false)
