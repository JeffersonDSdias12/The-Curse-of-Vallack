extends Lib
# =====================================================================
#  obj_qte — SEQUÊNCIA DE GOLPES (v1.17, como no God of War)
#  O Carrasco exausto e a Árvore cambaleando só caem por aqui: perto deles,
#  o botão do FINALIZADOR (BOLA / K, ou AÇÃO no toque) abre a sequência.
#  Cada botão certo na hora certa vira um golpe de cinema; no último,
#  Twilight executa o chefe. Errou ou demorou: o chefe se solta, empurra
#  Twilight e volta a lutar (até cair de novo e a sequência reaparecer).
#  Criado por V117.qte_iniciar(alvo). O mesmo da versão PC.
# =====================================================================

var alvo = null
var seq: Array = []
var i := 0
var estado := "entrada"       # entrada -> botao -> golpe -> ... -> sucesso | falha
var t := 0.0
var tempo_botao := 80.0
var perfeita := true
var acerto_fx := 0.0
var falhou_agora := false
const GOLPES := ["corte1", "corte2", "execucao", "corte2", "corte1", "execucao", "corte2", "corte1", "execucao", "corte2"]
const TODAS := [ACAO.ATACAR, ACAO.ATAQUE_FORTE, ACAO.PULAR, ACAO.DEFENDER, ACAO.ESQUIVA, ACAO.ATAQUE_SALTO, ACAO.INTERAGIR,
	ACAO.ESPECIAL, ACAO.ESPECIAL_2, ACAO.ESPECIAL_3, ACAO.FURIA]


func ev_step() -> void:
	var dt := G.dt_real
	t += dt
	if acerto_fx > 0:
		acerto_fx -= dt
	var p = instance_find("obj_player", 0)
	if not G.existe(alvo) or (alvo.morrendo and estado != "sucesso") or p == null or p.morto:
		if G.existe(alvo):
			alvo.em_qte = false
			alvo.executando = false
		instance_destroy()
		return
	if estado != "sucesso" and estado != "falha":
		# Twilight só obedece à sequência; nada o acerta; fica colado no chefe
		G.bloqueio_input = maxf(G.bloqueio_input, 2)
		var tx := V117.qte_x_frente(alvo, p.x)
		p.tempo_invencivel = maxf(p.tempo_invencivel, 20)
		p.x = lerpf(p.x, tx, 0.3)
		p.velh = 0.0
		p.empurrao = 0.0
		p.facing = signf(alvo.x - p.x)
		if p.facing == 0:
			p.facing = 1
	match estado:
		"entrada":
			if t >= 34:
				estado = "botao"
				t = 0
		"botao":
			var certo: int = seq[i]
			var ap := -1
			for a in TODAS:
				if G.inp_apertado[a]:
					ap = a
					break
			if ap != -1 and t > 3:
				# no toque, o botão de esquiva sem direção vira defesa (vale para DEFESA)
				if ap == certo or (certo == ACAO.DEFENDER and ap == ACAO.ESQUIVA):
					_acertou(p)
				else:
					perfeita = false
					estado = "falha"
					t = 0
					falhou_agora = true
			elif t >= tempo_botao:
				perfeita = false
				estado = "falha"
				t = 0
				falhou_agora = true
		"golpe":
			if t >= 24:
				if i >= seq.size():
					_concluir(p)
				else:
					estado = "botao"
					t = 0
		"sucesso":
			if t >= 70:
				instance_destroy()
		"falha":
			if t >= 50:
				instance_destroy()
	# a falha acontece uma vez: o chefe se solta, empurra Twilight e volta a lutar
	if falhou_agora:
		falhou_agora = false
		G.qte_alvo = null
		som("sfx_negado", 0.9, 0)
		G.camera_impact = maxf(G.camera_impact, 14)
		p.golpe_cancelar()
		p.tempo_invencivel = 0.0
		alvo.em_qte = false
		alvo.executando = false
		alvo.finalizavel = false
		alvo.qte_pronto = false
		alvo.qte_falhou()


func _acertou(p) -> void:
	i += 1
	acerto_fx = 16
	estado = "golpe"
	t = 0
	# o golpe de cinema (a vida quem tira é a sequência: o chefe está em_qte)
	p.golpe_cancelar()
	p.golpe_iniciar(GOLPES[(i - 1) % GOLPES.size()])
	var n := seq.size()
	var resta := n - i + 1
	if alvo.barra_tempo <= 0:
		alvo.vida_atraso = alvo.vida
	alvo.barra_tempo = 180.0
	alvo.flash_dano = 3.0 if alvo.eh_boss else 5.0
	alvo.vida = maxf(1, alvo.vida - maxf(1, round((alvo.vida - 1) / maxf(1, resta))))
	var cx: float = alvo.x
	var cy: float = (alvo.bbox_top + alvo.bbox_bottom) / 2.0
	if alvo.eh_boss:
		cx = alvo.bbox_left + 26 if p.x < alvo.x else alvo.bbox_right - 26
	V117.espada_fx_impacto(cx, cy, p.facing, 2 if i >= n else 1)
	fx_em("sangue", cx, cy, 1.4 if alvo.eh_boss else 1.1, p.facing, -129)
	impacto(10 if i >= n else 6)
	G.camera_impact = maxf(G.camera_impact, 16 if i >= n else 9)
	som("hit_pesado", 0.85, 0.06)


func _concluir(p) -> void:
	# SEQUÊNCIA COMPLETA: o finalizador derruba o chefe
	estado = "sucesso"
	t = 0
	G.qte_alvo = null
	var a = alvo
	p.golpe_cancelar()
	a.em_qte = false
	a.qte_vencido = true
	a.executando = true
	a.finalizavel = false
	a.qte_pronto = false
	a.tempo_invencivel = 0.0
	p.alvo_final = a
	p.golpe_iniciar("finalizador")
	# v1.19: cada sequência completada devolve vida a Twilight
	V117.qte_curar(p)
	V117.perfil_somar("sequencias")
	if perfeita and a.obj == "obj_boss_01":
		V117.conquista("perfeita")
	som("espada_evoluir", 0.6, 0)


func ev_cleanup() -> void:
	if G.qte_alvo == alvo:
		G.qte_alvo = null
	if G.existe(alvo) and alvo.em_qte:
		alvo.em_qte = false


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var pen: Pen = G.pen
	var ouro := Color8(236, 186, 84)
	var n := seq.size()
	var fx := 1.0
	if estado == "entrada":
		fx = clampf(t / 14.0, 0, 1)
	elif estado == "sucesso":
		fx = clampf(1 - (t - 40) / 30.0, 0, 1)
	elif estado == "falha":
		fx = clampf(1 - (t - 26) / 24.0, 0, 1)
	var lb := gh * 0.085 * fx
	pen.retangulo(0, 0, gw, lb, Color.BLACK, 0.92, false)
	pen.retangulo(0, gh - lb, gw, gh, Color.BLACK, 0.92, false)
	var ty := gh * 0.14
	txt_sombra(gw / 2.0, ty, "SEQUÊNCIA DE GOLPES", FONTE.MEDIA, ouro, fx, fa_center, fa_middle)
	for k in n:
		var px := gw / 2.0 + (k - (n - 1) / 2.0) * 30
		var py := ty + 34
		pen.circulo(px, py, 10, Color8(40, 22, 18), fx, false)
		if k < i:
			pen.circulo(px, py, 7, ouro, fx, false)
		elif k == i and estado == "botao":
			pen.circulo(px, py, 5 + 2 * sin(current_time() / 90.0), Color8(255, 120, 80), fx, false)
		pen.circulo(px, py, 10, ouro, fx, true)
	var cx := gw / 2.0
	var cy := gh * 0.33
	if estado == "botao" or estado == "entrada" or estado == "golpe":
		var ai := clampf(t / 20.0, 0, 1) if estado == "entrada" else 1.0
		var acao: int = seq[maxi(0, i - 1)] if estado == "golpe" else seq[mini(i, n - 1)]
		var frac := 1.0 - t / tempo_botao if estado == "botao" else 1.0
		var esc := 1 + 0.35 * clampf(1 - t / 12.0, 0, 1) if estado == "golpe" else 1 + 0.06 * sin(current_time() / 70.0)
		pen.blend_add = true
		pen.circulo(cx, cy, 70 * esc, ouro if estado == "golpe" else Color8(255, 70, 40), ai * (0.25 + 0.15 * sin(current_time() / 80.0)), false)
		pen.blend_add = false
		pen.circulo(cx, cy, 56 * esc, Color8(18, 10, 10), ai * 0.85, false)
		var cor_anel := merge_color(Color8(255, 50, 30), ouro, clampf(frac * 1.6, 0, 1))
		V117.desenhar_anel(cx, cy, 62 * esc, 7, frac, cor_anel, ai)
		var ia := 52 * esc
		var iw := icone_acao_largura(acao, ia)
		desenhar_icone_acao(cx - iw / 2.0, cy, acao, ia, ai)
		if estado == "botao":
			txt_sombra(cx, cy + 92, "TOQUE!" if G.usando_toque else "APERTE!", FONTE.PEQUENA, Color.WHITE, 0.7 + 0.3 * sin(current_time() / 60.0), fa_center, fa_middle)
		if acerto_fx > 0:
			pen.blend_add = true
			pen.circulo(cx, cy, 64 + (16 - acerto_fx) * 3, ouro, acerto_fx / 16.0, true)
			pen.circulo(cx, cy, 66 + (16 - acerto_fx) * 3, ouro, acerto_fx / 16.0, true)
			pen.blend_add = false
	if estado == "sucesso":
		var sa := clampf(t / 10.0, 0, 1) * clampf((70 - t) / 16.0, 0, 1)
		txt_sombra(cx, cy, "SEQUÊNCIA COMPLETA!", FONTE.GRANDE, ouro, sa, fa_center, fa_middle, 1 + 0.2 * clampf(1 - t / 10.0, 0, 1))
	if estado == "falha":
		var fa := clampf(t / 6.0, 0, 1) * clampf((50 - t) / 14.0, 0, 1)
		txt_sombra(cx, cy - 8, "FALHOU!", FONTE.GRANDE, Color8(255, 60, 40), fa, fa_center, fa_middle, 1 + 0.25 * clampf(1 - t / 8.0, 0, 1))
		txt_sombra(cx, cy + 48, "O inimigo se soltou: enfraqueça-o de novo", FONTE.PEQUENA, Color8(250, 230, 220), fa, fa_center, fa_middle)
	desenho_resetar()
