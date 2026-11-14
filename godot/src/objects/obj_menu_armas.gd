extends Lib
# =====================================================================
#  obj_menu_armas — tela de ARMAS e EVOLUÇÃO (START / TAB / botão ARMAS)
#  * à esquerda: a Lâmina de Sylla, o nível e os bônus
#  * no meio: os 5 níveis da espada, o que cada um libera e o custo
#  * à direita: combos e especiais (liberados ou bloqueados)
#  * SEGURAR confirmar (ou o dedo na tela): as orbs evoluem a espada
# =====================================================================

var tempo := 0.0
var abre := 0.0
var fechando := false
var fechar_t := 0.0
var segurar := 0.0
var evoluiu_fx := 0.0
var evoluiu_txt := ""
var negado_fx := 0.0
var orbs_vis := 0.0
var fluxo: Array = []
var faiscas: Array = []
var selecionado := 1


func ev_create() -> void:
	globais_iniciar()
	orbs_vis = G.orbs
	selecionado = clampi(G.espada_nivel, 1, ESPADA_NIVEL_MAX - 1)
	mundo_pausar()
	G.io_clear()
	som("sfx_menu_abrir", 0.9, 0)


func fechar() -> void:
	if fechando:
		return
	fechando = true
	fechar_t = 0
	som("sfx_menu_fechar", 0.8, 0)


func finalizar() -> void:
	mundo_retomar()
	G.io_clear()
	G.bloqueio_input = 12
	instance_destroy()


func evoluir() -> bool:
	var prox := G.espada_nivel + 1
	if prox > ESPADA_NIVEL_MAX:
		return false
	var custo := espada_custo(prox)
	if G.orbs < custo:
		return false
	G.orbs -= custo
	G.espada_nivel = prox
	G.marca["orbs"] = maxf(0, G.marca.get("orbs", 0) - custo)
	G.marca["nivel"] = maxi(G.marca.get("nivel", 1), prox)
	evoluiu_fx = 90
	if prox >= ESPADA_NIVEL_MAX:
		V117.conquista("espada_max")     # v1.17
	var info: Dictionary = espada_niveis()[prox - 1]
	evoluiu_txt = "NÍVEL " + str(prox) + "!"
	for it in info.itens:
		evoluiu_txt += "  " + (("COMBO " + str(it.n) + " LIBERADO") if it.tipo == "combo" else (especial_nome(it.acao) + " LIBERADO"))
	som("espada_evoluir", 1, 0)
	G.vibrar(80)
	for i in 40:
		faiscas.append({"x": 250.0, "y": 330.0, "vx": randf_range(-6, 6), "vy": randf_range(-7, 3), "vida": float(randi_range(30, 70)), "vmax": 70.0})
	selecionado = clampi(G.espada_nivel, 1, ESPADA_NIVEL_MAX - 1)
	return true


func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	if evoluiu_fx > 0:
		evoluiu_fx -= dt
	if negado_fx > 0:
		negado_fx -= dt
	orbs_vis = lerpf(orbs_vis, G.orbs, 0.15)
	if absf(orbs_vis - G.orbs) < 0.5:
		orbs_vis = G.orbs
	for i in range(faiscas.size() - 1, -1, -1):
		var f: Dictionary = faiscas[i]
		f.x += f.vx * dt
		f.y += f.vy * dt
		f.vy += 0.15 * dt
		f.vida -= dt
		if f.vida <= 0:
			faiscas.remove_at(i)
	for j in range(fluxo.size() - 1, -1, -1):
		fluxo[j].t += dt / 26.0
		if fluxo[j].t >= 1:
			fluxo.remove_at(j)
	if fechando:
		fechar_t += dt
		abre = maxf(0, 1 - fechar_t / 14.0)
		if fechar_t >= 14:
			finalizar()
		return
	abre = minf(1, abre + dt / 16.0)
	if tempo < 10:
		return
	if input_fechar_menu() or (G.toque != null and G.toque.armas_apertada):
		fechar()
		return
	# SEGURAR para evoluir (ENTER / ESPAÇO / X / dedo na tela)
	var prox := G.espada_nivel + 1
	var pode := prox <= ESPADA_NIVEL_MAX and G.orbs >= espada_custo(prox)
	var segurando := G.keyboard_check(KEY_ENTER) or G.keyboard_check(KEY_SPACE) or G.mouse_segurado \
		or (G.pad_slot >= 0 and G.pad_botao(gp_face1))
	var apertou := G.keyboard_check_pressed(KEY_ENTER) or G.keyboard_check_pressed(KEY_SPACE) or G.mouse_apertado \
		or (G.pad_slot >= 0 and G.pad_botao_apertado(gp_face1))
	if segurando and pode:
		segurar = minf(1, segurar + dt / 70.0)
		if randf() < 0.7 * dt:
			fluxo.append({"t": 0.0, "ox": randf_range(-12, 12), "oy": randf_range(-8, 8)})
		if int(floor(tempo)) % 6 == 0:
			som("sfx_orb", 0.25, 0.2)
		if segurar >= 1:
			segurar = 0
			evoluir()
	else:
		segurar = maxf(0, segurar - dt / 20.0)
		if apertou and not pode:
			negado_fx = 30
			som("sfx_negado", 0.7, 0)


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var ouro := Color8(255, 210, 90)
	var ouro2 := Color8(176, 141, 70)
	var cinza := Color8(150, 145, 140)
	var ab := clampf(abre, 0, 1)
	var e := 1 - pow(1 - ab, 3)
	var t := current_time() / 16.0
	draw_set_alpha(0.8 * e)
	draw_set_color(Color8(14, 4, 4))
	draw_rectangle(0, 0, gw, gh, false)
	desenhar_vinheta(gw, gh, 0.75 * e, Color8(70, 0, 0))
	gpu_set_blendmode(bm_add)
	for n in 6:
		var nx := gw * frac(n * 0.37 + t / 1400.0)
		draw_set_alpha(0.05 * e)
		draw_set_color(Color8(200, 30, 20))
		draw_ellipse(nx - 260, gh - 260 - n * 30, nx + 260, gh + 40, false)
	gpu_set_blendmode(bm_normal)
	var corte := (1 - ab) if fechando else ab
	if corte < 1:
		gpu_set_blendmode(bm_add)
		var ly := lerpf(-40, gh + 40, corte)
		draw_set_alpha(0.7 * (1 - corte))
		draw_set_color(Color8(230, 40, 30))
		draw_rectangle(0, ly - 3, gw, ly + 3, false)
		gpu_set_blendmode(bm_normal)
	var desl := (1 - e) * 220
	txt_sombra(gw / 2, 44 - (1 - e) * 40, "ARMAS", FONTE.GRANDE, ouro, e, fa_center, fa_middle, 1.05)
	desenhar_divisor(gw / 2, 80 - (1 - e) * 40, 200, e)
	# ----- PAINEL DA ESPADA (esquerda) -----
	var px1 := 36 - desl
	var px2 := px1 + minf(420, gw * 0.32)
	var pcx := (px1 + px2) / 2
	desenhar_painel(px1, 104, px2, gh - 110, 0, e * 0.95)
	txt_sombra(pcx, 132, espada_nome(), FONTE.MEDIA, c_white, e, fa_center, fa_middle, minf(1, (px2 - px1 - 30) / maxf(1, txt_largura(espada_nome(), FONTE.MEDIA))))
	txt(pcx, 162, "NÍVEL " + str(G.espada_nivel) + " / " + str(ESPADA_NIVEL_MAX), FONTE.PEQUENA, ouro, e, fa_center, fa_middle)
	var sy1 := 190.0
	var sy2 := gh - 230
	var bri := evoluiu_fx / 90.0 if evoluiu_fx > 0 else 0.0
	desenhar_espada_grande(pcx, sy1, sy2, G.espada_nivel, e, bri, t)
	var by := gh - 200
	txt(pcx, by, "DANO  +" + str(int(round((espada_dano_mult() - 1) * 100))) + "%", FONTE.PEQUENA, c_white, e, fa_center, fa_middle)
	txt(pcx, by + 26, "ESPECIAIS  +" + str(5 * (G.espada_nivel - 1)) + "%", FONTE.MINI, Color8(230, 210, 200), e, fa_center, fa_middle)
	if G.espada_nivel >= 5:
		txt(pcx, by + 48, "FÚRIA ENCHE 35% MAIS RÁPIDO", FONTE.MINI, Color8(255, 140, 90), e, fa_center, fa_middle)
	# ----- NÍVEIS (meio) -----
	var mx1 := px2 + 24 + desl * 0.3
	var mx2 := mx1 + minf(470, gw * 0.36)
	if (gw - 36) - (mx2 + 24) <= 220:
		mx2 = gw - 36
	var niv := espada_niveis()
	var lh := 86.0
	var ly0 := 112.0
	for i in niv.size():
		var nv: Dictionary = niv[i]
		var y1 := ly0 + i * (lh + 6)
		var ao := clampf(e * 1.5 - i * 0.1, 0, 1)
		var tem: bool = G.espada_nivel >= nv.nivel
		var prox: bool = G.espada_nivel + 1 == nv.nivel
		desenhar_painel(mx1, y1, mx2, y1 + lh, 1.0 if prox else 0.0, ao * (0.95 if (tem or prox) else 0.6))
		var jx := mx1 + 34
		var jy := y1 + lh / 2
		var jc := Color8(230, 40, 30) if tem else (Color8(130, 50, 40) if prox else Color8(60, 50, 50))
		draw_set_alpha(ao)
		draw_set_color(ouro2)
		draw_triangle(jx, jy - 20, jx + 17, jy, jx, jy + 20, false)
		draw_triangle(jx, jy - 20, jx - 17, jy, jx, jy + 20, false)
		draw_set_color(jc)
		draw_triangle(jx, jy - 15, jx + 12, jy, jx, jy + 15, false)
		draw_triangle(jx, jy - 15, jx - 12, jy, jx, jy + 15, false)
		if tem:
			gpu_set_blendmode(bm_add)
			draw_set_alpha(ao * (0.3 + 0.2 * sin(t / 10.0 + i)))
			draw_circle(jx, jy, 22, false)
			gpu_set_blendmode(bm_normal)
		txt(jx, jy, str(nv.nivel), FONTE.PEQUENA, c_white if tem else cinza, ao, fa_center, fa_middle)
		var tx := mx1 + 66
		var desc := ""
		for k in nv.itens.size():
			var it: Dictionary = nv.itens[k]
			desc += ("  +  " if k > 0 else "") + (("COMBO " + str(it.n)) if it.tipo == "combo" else especial_nome(it.acao))
		txt(tx, y1 + 24, desc, FONTE.PEQUENA, ouro if tem else (c_white if prox else cinza), ao, fa_left, fa_middle, minf(1, (mx2 - tx - 16) / maxf(1, txt_largura(desc, FONTE.PEQUENA))))
		var st := "OBTIDO" if tem else (str(espada_custo(nv.nivel)) + " ORBS")
		var sc := Color8(140, 220, 120) if tem else (ouro if (G.orbs >= espada_custo(nv.nivel) and prox) else Color8(220, 120, 100))
		var wst := txt_largura(st, FONTE.PEQUENA)
		txt(tx, y1 + 58, nv.texto, FONTE.MINI, Color8(225, 215, 205) if tem else cinza, ao, fa_left, fa_middle, minf(1, (mx2 - tx - wst - 32) / maxf(1, txt_largura(nv.texto, FONTE.MINI))))
		txt(mx2 - 16, y1 + 58, st, FONTE.PEQUENA, sc, ao, fa_right, fa_middle)
		if prox and segurar > 0:
			draw_set_alpha(ao)
			draw_set_color(Color8(255, 60, 40))
			draw_rectangle(mx1 + 4, y1 + lh - 7, mx1 + 4 + (mx2 - mx1 - 8) * segurar, y1 + lh - 3, false)
	draw_set_alpha(1)
	# ----- GOLPES (direita) -----
	var rx1 := mx2 + 24 + desl
	var rx2 := gw - 36 + desl
	if rx2 - rx1 > 220:
		desenhar_painel(rx1, 104, rx2, gh - 110, 0, e * 0.95)
		var rcx := (rx1 + rx2) / 2
		txt(rcx, 128, "COMBOS", FONTE.PEQUENA, ouro, e, fa_center, fa_middle)
		var cb := combos_lista()
		var yy := 156.0
		for c in 3:
			var lb := combo_liberado(c + 1)
			var xx := rx1 + 18
			for s in cb[c].seq.size():
				xx += desenhar_icone_acao(xx, yy + 12, cb[c].seq[s], 22, e * (1.0 if lb else 0.4)) + 4
			txt(xx + 6, yy + 12, cb[c].nome if lb else ("NÍVEL " + str(combo_nivel_req(c + 1))), FONTE.MINI, c_white if lb else cinza, e, fa_left, fa_middle, minf(1, (rx2 - xx - 16) / maxf(1, txt_largura(cb[c].nome, FONTE.MINI))))
			yy += 40
		yy += 12
		txt(rcx, yy, "ESPECIAIS (MAGIA)", FONTE.PEQUENA, ouro, e, fa_center, fa_middle)
		yy += 28
		for ac in [ACAO.ESPECIAL_3, ACAO.ESPECIAL, ACAO.ESPECIAL_2]:
			var lib_ := especial_liberado(ac)
			var w := desenhar_icone_acao(rx1 + 18, yy + 12, ac, 24, e * (1.0 if lib_ else 0.4))
			var nm := especial_nome(ac)
			txt(rx1 + 28 + w, yy + 4, nm, FONTE.MINI, c_white if lib_ else cinza, e, fa_left, fa_middle, minf(1, (rx2 - rx1 - 40 - w) / maxf(1, txt_largura(nm, FONTE.MINI))))
			txt(rx1 + 28 + w, yy + 22, (str(int(round(especial_custo(ac) * 100))) + "% da magia") if lib_ else ("bloqueado: nível " + str(especial_nivel_req(ac))), FONTE.MINI, Color8(150, 200, 255) if lib_ else Color8(200, 110, 100), e * 0.9, fa_left, fa_middle, 0.85)
			yy += 46
		yy += 6
		txt(rcx, yy, "FÚRIA", FONTE.PEQUENA, ouro, e, fa_center, fa_middle)
		var wf := desenhar_icone_acao(rx1 + 18, yy + 30, ACAO.FURIA, 24, e)
		txt(rx1 + 28 + wf, yy + 30, "Ira de Vallack (barra cheia)", FONTE.MINI, c_white, e, fa_left, fa_middle, minf(1, (rx2 - rx1 - 44 - wf) / maxf(1, txt_largura("Ira de Vallack (barra cheia)", FONTE.MINI))))
	# ----- POTE DE ORBS e instrução -----
	var oy := gh - 64
	var ox := gw / 2 - 200
	desenhar_pote_orbs(ox, oy, 1.3, e, G.orbs_fx)
	txt_sombra(ox + 40, oy, str(int(round(orbs_vis))), FONTE.MEDIA, Color8(255, 120, 100), e, fa_left, fa_middle)
	txt(ox + 40, oy + 26, "ORBS", FONTE.MINI, ouro2, e, fa_left, fa_middle)
	var proxn := G.espada_nivel + 1
	var msg := ""
	var toque := G.usando_toque and not usando_controle()
	if proxn > ESPADA_NIVEL_MAX:
		msg = "A LÂMINA ESTÁ NO NÍVEL MÁXIMO"
	elif G.orbs >= espada_custo(proxn):
		msg = ("SEGURE O DEDO NA TELA PARA EVOLUIR AO NÍVEL " if toque else "SEGURE  PARA EVOLUIR AO NÍVEL ") + str(proxn)
	else:
		msg = "FALTAM " + str(int(espada_custo(proxn) - G.orbs)) + " ORBS PARA O NÍVEL " + str(proxn)
	var mc := Color8(255, 90, 70) if negado_fx > 0 else c_white
	var mxp := gw / 2 + 10
	if proxn <= ESPADA_NIVEL_MAX and G.orbs >= espada_custo(proxn) and not toque:
		var wi := desenhar_icone_pad(mxp, oy, gp_face1, 28, e) if (G.usando_pad and G.pad_slot >= 0) else desenhar_tecla(mxp, oy, "ENTER", 28, e)
		mxp += wi + 10
	txt_sombra(mxp, oy, msg, FONTE.PEQUENA, mc, e * (0.85 + 0.15 * sin(t / 8.0)), fa_left, fa_middle, minf(1, (gw - mxp - 30) / maxf(1, txt_largura(msg, FONTE.PEQUENA))))
	txt(gw / 2, gh - 22, ("VOLTAR fecha" if toque else botao_menu_armas() + " / " + nome_voltar() + " fecha"), FONTE.MINI, cinza, e, fa_center, fa_middle)
	gpu_set_blendmode(bm_add)
	for o in fluxo:
		var k: float = o.t
		var fx := lerpf(ox + o.ox, pcx, k)
		var fy := lerpf(oy + o.oy, (sy1 + sy2) / 2, k) - sin(k * PI) * 120
		draw_set_alpha(0.9 * (1 - k * 0.5))
		draw_set_color(Color8(255, 60, 40))
		draw_circle(fx, fy, 5, false)
		draw_set_color(Color8(255, 210, 180))
		draw_circle(fx, fy, 2, false)
	for fz in faiscas:
		draw_set_alpha(fz.vida / fz.vmax)
		draw_set_color(Color8(255, int(160 + 80 * (fz.vida / fz.vmax)), 60))
		draw_circle(pcx - 250 + fz.x, fz.y, 3, false)
	gpu_set_blendmode(bm_normal)
	if evoluiu_fx > 0:
		var ea := clampf(evoluiu_fx / 20.0, 0, 1) * clampf((90 - evoluiu_fx) / 8.0, 0, 1)
		var esc := 1 + 0.2 * clampf((evoluiu_fx - 75) / 15.0, 0, 1)
		draw_set_alpha(ea * 0.6)
		draw_set_color(c_black)
		draw_rectangle(0, gh / 2 - 44, gw, gh / 2 + 44, false)
		txt_sombra(gw / 2, gh / 2, evoluiu_txt, FONTE.MEDIA, ouro, ea, fa_center, fa_middle, minf(esc, (gw - 80) / maxf(1, txt_largura(evoluiu_txt, FONTE.MEDIA))))
	desenho_resetar()
