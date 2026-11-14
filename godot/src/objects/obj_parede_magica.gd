extends Lib
# =====================================================================
#  obj_parede_magica — muralha mágica que fecha a arena do mini-boss e do
#  boss. Ninguém entra nem sai: quem encosta é jogado de volta.
# =====================================================================

var dono = null
var lado := -1.0
var ativa := false
var estado := "parada"
var sobe := 0.0
var altura := 300.0
var solido = null
var choque := 0.0
var t := 0.0


func parede_erguer() -> void:
	estado = "subindo"
	ativa = true
	if solido == null:
		solido = solido_criar(x - 9, y - altura, x + 9, y)


func parede_baixar() -> void:
	if estado == "descendo":
		return
	estado = "descendo"
	ativa = false
	solido_remover(solido)
	solido = null


func ev_cleanup() -> void:
	solido_remover(solido)


func ev_step() -> void:
	var dt := G.dt
	t += dt
	if choque > 0:
		choque -= dt
	match estado:
		"subindo":
			sobe = minf(1, sobe + 0.05 * dt)
			if sobe >= 1:
				estado = "ativa"
		"descendo":
			sobe = maxf(0, sobe - 0.03 * dt)
			if sobe <= 0:
				instance_destroy()
				return
	if not ativa:
		return
	var dentro := -lado
	for e in todos("obj_inimigo_base"):
		if e.morrendo or e.eh_boss:
			continue
		if absf(e.x - x) < 22 and e.y > y - altura:
			e.empurrao = dentro * 5
			e.x += dentro * 2
			choque = 12
	var p = instance_find("obj_player", 0)
	if p != null and absf(p.x - x) < 18 and p.y > y - altura:
		p.empurrao = dentro * 3
		if choque <= 0:
			som_em("sfx_bloqueio", x, y, 0.4, 0.2)
		choque = 12


func ev_draw() -> void:
	if sobe <= 0:
		return
	var tt := current_time() / 16.0
	var topo := y - altura * sobe
	var a := sobe * (0.8 + 0.2 * sin(tt / 7.0)) + choque / 12.0 * 0.5
	desenhar_barreira(x, topo, y, minf(1, a), tt + lado * 40)
	gpu_set_blendmode(bm_add)
	for i in 6:
		var f := frac(tt / 160.0 + i / 6.0)
		var ry := y - f * altura * sobe
		draw_set_alpha(sobe * (1 - absf(f - 0.5) * 2) * 0.9)
		draw_set_color(Color8(255, 120, 200))
		draw_circle(x, ry, 4, true)
		draw_line(x - 5, ry, x + 5, ry)
		draw_line(x, ry - 5, x, ry + 5)
	if choque > 0:
		draw_set_alpha(choque / 12.0)
		draw_set_color(Color8(255, 200, 220))
		draw_rectangle(x - 6, topo, x + 6, y, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
