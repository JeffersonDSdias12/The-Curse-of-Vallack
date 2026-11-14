class_name ObjPlayer
extends ObjEntidade
# =====================================================================
#  obj_player — o herói (Twilight Vetrus)
# =====================================================================

# ===== ESCALA, MÁSCARA E DIREÇÃO =====
var escala := 1.25
var facing := 1.0
# ===== MOVIMENTO =====
var vel_correr := 3.6
var vel_agachado := 0.75
var vel_jump := 7.0
var coyote := 0.0
var buffer_pulo := 0.0
var pouso := 0.0
var no_ar_tempo := 0.0
var tempo_fase := 0.0
var anim_passo := 0.0
var atravessar_t := 0.0     # v1.13: descendo por uma plataforma de mão única (▼ + PULO)
# ===== VIDA =====
var vida_max := 100.0
var vida := 100.0
var vida_atraso := 100.0
var tempo_invencivel := 0.0
var tempo_sem_dano := 0.0
var empurrao := 0.0
var empurrao_ult := 0.0     # v1.17: o empurrão somado ao velh no quadro anterior (não acumula no ar)
var machucado := false
var morto := false
var tempo_morte := 0.0
var cura_restante := 0.0
var cura_fx := 0.0
# ===== COMBATE =====
var atacando := false
var especial := false
var armadura := false
var bloqueando := false
var agachado := false
var golpe = null
var golpe_i := 0
var golpe_t := 0.0
var golpe_grupo := -1
var cadeia := ""
var cadeia_janela := 0.0
var buffer_golpe := ""
var buffer_golpe_t := 0.0
var atingidos: Array = []
var combo_nome := ""
var combo_nome_t := 0.0
var sprite_defesa: GMSprite
var defesa_fx := 0.0
var barreira_aviso := 0.0
var brilho_golpe := 0.0
var carga_fx := 0.0
var bloqueado_aviso := 0.0
var bloqueado_txt := ""
# ESQUIVA (rolagem)
var rolando := false
var rolar_t := 0.0
var rolar_dir := 1.0
var rolar_recarga := 0.0
var rolar_buffer := 0.0
var rolar_buffer_dir := 0
var fantasmas: Array = []
# TEIA da Mulher-Aranha
var enredado := 0.0
var enredado_max := 1.0
var enredado_fx := 0.0
var teia_imune := 0.0
var esquivou := false
var esquiva_fx := 0.0
# APARAR (parry)
var janela_aparar := 0.0
var aparar_recarga := 0.0
var aparar_fx := 0.0
# FINALIZADOR
var alvo_final = null
# ===== v1.12 =====
var furia_modo := false
var recuando := false
var recuar_t := 0.0
var pesado_t := 0.0
var pulo_t := 0.0
var golpe_idade := 0.0
var golpe_letra := ""
var aereo_n := 0
var contra_t := 0.0
var contra_alvo = null
var furia := 0.0
var furia_cheia_fx := 0.0
var especial_carga := 10.0
var especial_pronto_fx := 0.0
var alvo_interacao = null
var ondas: Array = []
var rastros: Array = []
var faiscas_espada: Array = []      # v1.14: faíscas e brasas que o corte solta
# v1.17: RASTRO DE FOGO: o caminho que a lâmina percorre no corte, em chamas
var fogo_rastro: Array = []         # amostras [cx, cy, px, py, idade, vmax, ini]
var fogo_chamas: Array = []         # línguas de fogo (PackedFloat32Array: x, y, vx, vy, v, vmax, r, s)
var lamina_ant: Array = []
var lamina_img := -1
var lamina_spr: GMSprite = null
var fogo_ult := 99.0
var escalando := false              # v1.14: subindo / descendo escada de mão, corda ou corrente
var escala_i := -1
var escala_anim := 0.0
var escala_agarrar := 0.0       # v1.17: quadros da animação de pular e agarrar a corda
var escala_desce := false       # v1.17: descendo a escada (animação própria)
var objetivo_txt := ""          # HUD: a faixa do objetivo aparece quando ele muda e some
var objetivo_t := 0.0
var debug_golpe: Array = []
var spawn_x := 0.0
var spawn_y := 0.0


func ev_create() -> void:
	super()
	globais_iniciar()
	if not instance_exists("obj_sistema"):
		instance_create_depth(0, 0, 0, "obj_sistema")
	escala = 1.25
	image_xscale = 1
	image_yscale = 1
	mask_index = Spr.spr_mascara_player
	facing = 1
	grav = 0.25
	vida_max = 100
	vida = vida_max
	if G.vida_carregada > 0:
		vida = clampf(G.vida_carregada, 1, vida_max)
		G.vida_carregada = -1
	vida_atraso = vida
	sprite_defesa = Spr.spr_player_defendendo
	especial_carga = ESPECIAL_SEGUNDOS
	image_speed = 1
	# ===== POSIÇÃO INICIAL / CHECKPOINT =====
	if G.checkpoint_ativo and G.room == G.checkpoint_room:
		x = G.checkpoint_x
		y = G.checkpoint_y
	spawn_x = x
	spawn_y = y
	G.capitulo = maxi(1, fase_numero(G.room))
	G.camera_zoom = 1
	G.cam_snap = true
	G.ultimo_x = x
	G.ultimo_y = y
	G.ultima_vida = vida


func trocar_animacao(s: GMSprite, v: float) -> void:
	if sprite_index != s:
		sprite_index = s
		image_index = 0
	image_speed = v


# ---------------------------------------------------------------------
# GOLPES (a tabela de cada golpe fica em Lib / scr_combate)
# ---------------------------------------------------------------------
func golpe_iniciar(chave: String) -> bool:
	var g = golpe_criar(chave)
	if g == null:
		return false
	golpe = g
	golpe_i = 0
	golpe_t = 0
	golpe_idade = 0
	golpe_letra = ""
	golpe_grupo = -1
	atingidos = []
	atacando = true
	especial = g.especial
	armadura = g.armadura
	bloqueando = false
	agachado = false
	sprite_index = g.spr
	image_speed = 0
	image_index = g.seq[0].q
	if not g.no_ar:
		velh = 0
	if g.especial:
		especial_carga = maxf(0, especial_carga - especial_custo(g.acao_esp) * ESPECIAL_SEGUNDOS)
		G.camera_impact = maxf(G.camera_impact, 8)
	elif g.chave != "ira" and g.chave != "finalizador":
		G.attacks_total += 1
	if g.combo > 0:
		combo_nome = "COMBO " + str(g.combo) + "  ·  " + g.nome
		combo_nome_t = 110
	var som_g := golpe_som(g.chave)
	if som_g != "":
		som(som_g, 0.95 if g.pesado else 0.8)
	golpe_entrar_quadro()
	return true


# Encerra o golpe atual (fim da animação, dano recebido ou queda do mapa)
func golpe_cancelar() -> void:
	if golpe != null and golpe.chave == "finalizador" and G.existe(alvo_final):
		alvo_final.executando = false
	golpe = null
	atacando = false
	especial = false
	armadura = false
	brilho_golpe = 0
	carga_fx = 0
	image_speed = 1
	G.camera_zoom = 1


# Ao entrar num quadro da tabela: eventos e mudança de grupo de acerto
func golpe_entrar_quadro() -> void:
	var e: Dictionary = golpe.seq[golpe_i]
	image_index = e.q
	var gr = e.get("grupo", 0)
	if e.has("hit") and gr != golpe_grupo:
		golpe_grupo = gr
		atingidos = []
		rastro_criar()
	if e.has("ev"):
		golpe_evento(e.ev)
	golpe_acertar()


# Aplica a área de acerto do quadro atual (cada inimigo 1x por grupo)
func golpe_acertar() -> void:
	if golpe == null:
		return
	var e: Dictionary = golpe.seq[golpe_i]
	if not e.has("hit"):
		return
	var h: Array = e.hit
	var dm: float = e.get("dm", 1.0)
	var x1: float = x + facing * h[0]
	var x2: float = x + facing * h[1]
	var g = golpe
	for alvo in collision_rectangle_list(minf(x1, x2), y + h[2], maxf(x1, x2), y + h[3], "obj_inimigo_base"):
		if atingidos.has(alvo):
			continue
		if alvo.morrendo or not alvo.ativo:
			continue
		atingidos.append(alvo)
		# v1.12: CRÍTICO com a ponta da espada
		var dmx := dm
		if g.dano > 0 and not g.especial and g.chave != "contra":
			var borda: float = alvo.bbox_left if facing > 0 else alvo.bbox_right
			if (borda - x) * facing >= maxf(absf(h[0]), absf(h[1])) * CRITICO_PONTA:
				dmx = dm * CRITICO_MULT
				popup_criar(alvo.x, alvo.bbox_top - 6, "CRÍTICO!", Color8(255, 230, 120), 1)
				som("sfx_critico", 0.8)
				fx_criar("faiscas_golpe", lerpf(x, alvo.x, 0.7), (alvo.bbox_top + alvo.bbox_bottom) / 2.0, 1.6)
		golpe_ferir(alvo, g, dmx, x)
	for d in collision_rectangle_list(minf(x1, x2), y + h[2], maxf(x1, x2), y + h[3], "obj_destrutivel"):
		if atingidos.has(d):
			continue
		atingidos.append(d)
		d.destrutivel_bater(2 if (g.pesado or g.especial or g.chave == "ira") else 1, x)
	debug_golpe = [minf(x1, x2), y + h[2], maxf(x1, x2), y + h[3], 6.0]


# DANO DOS GOLPES (scr_combate)
func dano_golpe(g, alvo, dm: float) -> float:
	var mini: bool = alvo.obj == "obj_mini_boss"
	var bruto: bool = alvo.obj == "obj_porco"
	if g.chave == "ira":
		if alvo.eh_boss:
			return maxf(1, round(alvo.vida_max * 0.10))
		if mini:
			return maxf(1, round(alvo.vida_max * 0.20))
		if bruto:
			return maxf(1, ceil(alvo.vida_max * 0.5))
		if alvo.obj == "obj_inimigo_03":
			return maxf(1, ceil(alvo.vida_max * 0.7))
		return alvo.vida_max
	if g.especial:
		var p: float = g.porcento * (1 + 0.05 * (G.espada_nivel - 1))
		if alvo.eh_boss:
			return maxf(1, round(alvo.vida_max * p * 0.15))
		if mini:
			return maxf(1, round(alvo.vida_max * p * 0.3))
		if bruto:
			return maxf(1, round(alvo.vida_max * p * 0.6))
		return maxf(1, ceil(alvo.vida_max * p))
	var fm := 1.5 if furia_modo else 1.0
	if g.chave == "contra":
		var pc := 0.35
		if alvo.eh_boss:
			pc = 0.05
		elif mini:
			pc = 0.08
		elif bruto:
			pc = 0.15
		return maxf(18, round(alvo.vida_max * pc * espada_dano_mult() * fm))
	return maxf(1, round(g.dano * dm * espada_dano_mult() * fm))


# Dano de um golpe num inimigo
func golpe_ferir(alvo, g, dm: float, origem_x: float) -> void:
	var dano := dano_golpe(g, alvo, dm)
	var lanca: float = g.lanca
	var atord: float = g.atordoa
	var forca: float = g.forca
	var vida_antes: float = alvo.vida
	alvo.levar_dano(dano, origem_x, not g.especial, forca, self, g)
	if not alvo.morrendo and not alvo.eh_boss and lanca > 0 and alvo.pode_lancar:
		alvo.velv = minf(alvo.velv, -lanca)
	if not alvo.morrendo and not alvo.eh_boss and atord > 0:
		alvo.inimigo_atordoar(atord)
	var acertou: bool = G.existe(alvo) and (alvo.vida < vida_antes or alvo.morrendo)
	var cx: float = (alvo.bbox_left + alvo.bbox_right) / 2.0
	var cy: float = (alvo.bbox_top + alvo.bbox_bottom) / 2.0
	var px := lerpf(x + facing * 20, cx, 0.6)
	if acertou:
		# peso: pausa maior nos golpes pesados e a câmera "leva" a pancada
		impacto(8 if g.pesado else (5 if g.especial else 4))
		camera_empurrar(facing, 5.0 if g.pesado else (4.0 if g.especial else 2.5))
		if g.pesado or g.especial:
			som("hit_pesado", 0.8 if g.especial else 1.0)
		else:
			som_var("hit", 3, 0.85)
		fx_criar("faiscas_golpe", px, cy, 1.3 if g.pesado else 1.0)
		var corte = fx_criar("corte", px, cy, 1.35 if (g.pesado or g.especial) else 1.0)
		corte.forte = g.pesado or g.especial
		# v1.17: estrela de impacto, cortes em X, raios de tinta (finalizações) e a rajada
		var nivel_fx := 2 if (g.combo > 0 or g.chave == "finalizador" or (G.existe(alvo) and alvo.morrendo and alvo.eh_boss)) else (1 if (g.pesado or g.especial or dm > 1) else 0)
		var rajada: bool = g.chave in ["rasteira", "rasteira_sangrenta", "mergulho", "contra"]
		V117.espada_fx_impacto(px, cy, facing, nivel_fx, rajada)
		furia_ganhar(0.5 if g.especial else (1.5 if g.pesado else 1.0))
		# v1.12: MODO FÚRIA — roubo de vida a cada golpe e petrificação
		if furia_modo:
			vida = minf(vida_max, vida + (5 if (G.existe(alvo) and alvo.morrendo) else 2))
			if G.existe(alvo):
				alvo.inimigo_petrificar()
			impacto(2)
			fx_criar("sangue", px, cy, 0.8)
		# v1.12: COMBO AÉREO
		if G.existe(alvo) and not alvo.morrendo and not alvo.eh_boss and alvo.pode_lancar:
			var alvo_no_ar: bool = not alvo.place_meeting(alvo.x, alvo.y + 1, "obj_chao")
			if g.chave == "lancador":
				alvo.velv = -7.4
				alvo.empurrao = 0
			elif g.chave == "corte_aereo" and alvo_no_ar:
				alvo.velv = -1.6
				alvo.empurrao *= 0.3
				alvo.inimigo_suspender(22)
		if g.chave == "corte_aereo" and not place_meeting(x, y + 1, "obj_chao"):
			velv = minf(velv, -1.2)
	if g.combo > 0 or g.especial:
		G.camera_impact = maxf(G.camera_impact, 9)


# Dano em área ao redor de um ponto (golpes que batem no chão)
func golpe_area(cx: float, raio: float, altura: float) -> void:
	if golpe == null:
		return
	var g = golpe
	for alvo in collision_rectangle_list(cx - raio, y - altura, cx + raio, y + 12, "obj_inimigo_base"):
		if atingidos.has(alvo):
			continue
		if alvo.morrendo or not alvo.ativo:
			continue
		atingidos.append(alvo)
		golpe_ferir(alvo, g, 1, cx)
	for d in collision_rectangle_list(cx - raio, y - altura, cx + raio, y + 12, "obj_destrutivel"):
		if atingidos.has(d):
			continue
		atingidos.append(d)
		d.destrutivel_bater(3, cx)
	debug_golpe = [cx - raio, y - altura, cx + raio, y + 12, 20.0]


func furia_ganhar(n: float) -> void:
	if furia >= 100 or furia_modo:
		return
	furia = minf(100, furia + n * furia_ganho_mult())
	if furia >= 100:
		furia_cheia_fx = 60
		som("esp_carga", 0.5)


# Eventos dos quadros (saltos, impactos, efeitos)
func golpe_evento(ev: String) -> void:
	match ev:
		"zoom":
			G.camera_impact = maxf(G.camera_impact, 6)
		"brilho":
			brilho_golpe = 14
		"salto":
			velv = -6.0
			velh = facing * 2.4
			brilho_golpe = 10
			som("sfx_pulo", 0.7)
		"lancar":
			velv = -6.6
			velh = facing * 0.6
			brilho_golpe = 10
			aereo_n = 0
			som("sfx_pulo", 0.6)
			fx_criar("poeira", x, y, 0.6)
		"contra":
			brilho_golpe = 14
			tempo_invencivel = maxf(tempo_invencivel, 30)
			G.camera_zoom = 1.12
			G.camera_impact = maxf(G.camera_impact, 10)
			som("sfx_contra", 1)
		"bumerangue":
			var bm = instance_create_depth(x + facing * 22, y - 40, depth - 1, "obj_bumerangue")
			bm.dir = facing
			bm.dono = self
			som("bumerangue", 0.9)
		"chama":
			var ch = instance_create_depth(x + facing * 40, y, depth - 1, "obj_chama_sylla")
			ch.dir = facing
			som("chama_sylla", 1)
			G.camera_impact = maxf(G.camera_impact, 6)
		"mergulho":
			velv = maxf(velv, 8.5)
			velh = facing * 1.6
		"impacto_leve":
			G.camera_impact = maxf(G.camera_impact, 7)
			fx_criar("poeira", x + facing * 40, y, 0.8)
			som("sfx_pouso", 0.9)
		"impacto_carrasco":
			velh = 0
			G.camera_impact = maxf(G.camera_impact, 10)
			fx_criar("onda_chao", x + facing * 16, y, 0.75)
			fx_criar("poeira", x + facing * 16, y, 1)
			som("sfx_pouso", 1)
			som("sfx_impacto", 0.55)
		"impacto_quebra":
			velh = 0
			G.camera_impact = maxf(G.camera_impact, 16)
			fx_criar("onda_chao", x + facing * 16, y, 1.1)
			fx_criar("poeira", x + facing * 16, y, 1.4)
			fx_criar("rachaduras", x + facing * 16, y, 0.9)
			som("sfx_impacto", 0.8)
			G.vibrar(40)
		"onda", "onda_baixa":
			G.camera_impact = maxf(G.camera_impact, 16)
			var baixa := ev == "onda_baixa"
			ondas.append({"x0": x, "dir": facing, "dist": 30.0, "dist_max": 132.0,
				"y_topo": -46.0 if baixa else -80.0, "y_base": -2.0, "raio": 22.0 if baixa else 34.0,
				"vida": 16.0, "vmax": 16.0, "atingidos": []})
			som("esp_onda", 1)
		"salto_queda":
			velv = -7.2
			velh = facing * 1.3
			som("sfx_pulo", 0.8)
		"mergulho_queda":
			velv = maxf(velv, 12)
			velh = 0
		"impacto_queda":
			velh = 0
			G.camera_impact = maxf(G.camera_impact, 20)
			G.terremoto = maxf(G.terremoto, 18)
			golpe_area(x + facing * 14, 130, 90)
			fx_criar("onda_chao", x + facing * 14, y, 1.3)
			fx_criar("poeira", x + facing * 14, y, 1.5)
			fx_criar("rachaduras", x + facing * 14, y, 1)
			som("esp_queda", 1)
			G.vibrar(60)
		"faiscas":
			fx_criar("faiscas_tela", x, y, 1)
		"carga":
			carga_fx = 1
			fx_criar("carga", x, y - 40, 1)
			som("esp_carga", 0.85)
		"carga_max":
			carga_fx = 2
			G.terremoto = maxf(G.terremoto, 10)
		"impacto_tremor":
			carga_fx = 0
			velh = 0
			G.camera_impact = maxf(G.camera_impact, 22)
			G.terremoto = maxf(G.terremoto, 70)
			golpe_area(x, 250, 100)
			fx_criar("onda_chao", x + facing * 10, y, 2.2)
			fx_criar("rachaduras", x + facing * 10, y, 1.8)
			fx_criar("poeira", x + facing * 10, y, 2)
			fx_criar("pedras", x + facing * 10, y, 1)
			som("esp_tremor", 1)
			G.vibrar(90)
		"fin_inicio":
			tempo_invencivel = maxf(tempo_invencivel, 90)
			G.camera_zoom = 1.25
			som("atk_pesado", 1)
		"fin_golpe":
			G.camera_zoom = 1.3
			impacto(12)
			camera_lenta(40, 0.35)
			G.camera_impact = maxf(G.camera_impact, 18)
			som("sfx_finalizador", 1)
			G.vibrar(60)
			if G.existe(alvo_final):
				var a = alvo_final
				var cy: float = (a.bbox_top + a.bbox_bottom) / 2.0
				fx_criar("sangue", a.x, cy, 1.6)
				fx_criar("faiscas_golpe", a.x, cy, 2)
				a.executando = false
				a.finalizado = true
				a.levar_dano(a.inimigo_dano_finalizador(), x, false, 10, self, golpe)
				vida = minf(vida_max, vida + round(vida_max * 0.08))
				furia_ganhar(4)
				V117.perfil_somar("execucoes")       # v1.17: conquista EXECUTOR
				V117.espada_fx_impacto(a.x, cy, facing, 2)
		"fin_fim":
			G.camera_zoom = 1
			alvo_final = null
		"ira_carga":
			tempo_invencivel = maxf(tempo_invencivel, 80)
			furia = 100
			furia_modo = true
			G.camera_zoom = 1.2
			camera_lenta(30, 0.5)
			G.camera_impact = maxf(G.camera_impact, 10)
			som("furia_inicio", 1)
			aviso_mostrar("MODO FÚRIA", false)     # a fúria tem o som próprio (furia_inicio)
			V117.conquista("furia")                  # v1.17
			fx_criar("carga", x, y - 40, 1.6)
			carga_fx = 2
		"ira_golpe":
			carga_fx = 0
			G.camera_zoom = 1
			impacto(10)
			G.camera_impact = maxf(G.camera_impact, 26)
			G.terremoto = maxf(G.terremoto, 40)
			G.last_hit_flash = 18
			golpe_area(x, 320, 150)
			for l in [-1.0, 1.0]:
				ondas.append({"x0": x, "dir": l, "dist": 30.0, "dist_max": 300.0, "y_topo": -96.0, "y_base": -2.0, "raio": 44.0, "vida": 26.0, "vmax": 26.0, "atingidos": [], "ira": true})
			fx_criar("onda_chao", x, y, 2.6)
			fx_criar("faiscas_tela", x, y, 1)
			som("esp_furia_impacto", 1)
			G.vibrar(120)


# Efeito visual (obj_fx)
func fx_criar(tipo: String, px: float, py: float, tam: float):
	var f = instance_create_depth(px, py, depth - 2, "obj_fx")
	f.tipo = tipo
	f.tam = tam
	f.dir = facing
	f.fx_iniciar()
	return f


# Rastro da espada (arco) do golpe atual
# v1.17: com a lâmina medida (LaminaDados) quem desenha o caminho do golpe é o
# RASTRO DE FOGO (fogo_emitir); o arco antigo fica só para sprites sem medida
func rastro_criar() -> void:
	if golpe == null or golpe.arco == null:
		return
	if sprite_index != null and LaminaDados.D.has(sprite_index.nome):
		return
	var a: Array = golpe.arco
	var forte: bool = golpe.combo > 0 or golpe.chave == "finalizador"
	rastros.append({"x": x, "y": y, "dir": facing, "a1": a[0], "a2": a[1], "r": a[2], "h": a[3],
		"cor": golpe.cor, "forte": forte, "vida": 15.0, "vmax": 15.0})
	# v1.14: o corte solta faíscas douradas e brasas da maldição ao longo do arco
	var n: int = [3, 6, 10][G.cfg_qualidade] + (4 if forte else 0)
	var cx := x + facing * 8
	var cy := y - float(a[3])
	for k in n:
		var ang := lerpf(a[0], a[1], randf())
		var angw := ang if facing == 1 else 180 - ang
		var v := randf_range(1.2, 3.6)
		faiscas_espada.append({"x": cx + lengthdir_x(a[2], angw), "y": cy + lengthdir_y(a[2], angw),
			"vx": lengthdir_x(v, angw) + facing * randf() * 1.2, "vy": lengthdir_y(v, angw) - randf() * 1.4,
			"vida": randf_range(16, 34), "vmax": 34.0, "brasa": randf() < 0.35})


# v1.17: RASTRO DE FOGO. Ao entrar num quadro de corte, a lâmina gira (em volta
# do cabo) do quadro anterior até o atual: cada passo vira uma amostra da fita
# de fogo e solta línguas de fogo e brasas pela ponta. (O mesmo da versão PC.)
func fogo_emitir(a: Array, b: Array) -> void:
	var forte: bool = golpe.especial or golpe.combo > 0 or golpe.pesado or golpe.chave == "finalizador" or golpe.chave == "ira"
	var a0 := point_direction(a[0], a[1], a[2], a[3])
	var a1v := point_direction(b[0], b[1], b[2], b[3])
	var l0 := point_distance(a[0], a[1], a[2], a[3])
	var l1 := point_distance(b[0], b[1], b[2], b[3])
	var d := angle_difference(a1v, a0)
	var sent := -float(facing)
	if golpe.arco != null:
		sent = (-1.0 if golpe.arco[1] < golpe.arco[0] else 1.0) * facing
	if absf(d) > 40 and signf(d) != sent:
		d += 360 * sent
	var n := clampi(int(ceil(absf(d) / 9.0)), 1, 18)
	var novo := fogo_ult > 3 or fogo_rastro.is_empty()
	var vmax := 26.0 if forte else 20.0
	var q := G.cfg_qualidade
	var chance := 0.3 if q == 0 else (0.6 if q == 1 else 1.0)
	var maxc := 24 if q == 0 else (48 if q == 1 else 72)
	var px_ant: float = a[2]
	var py_ant: float = a[3]
	for k in range(0 if novo else 1, n + 1):
		var t := float(k) / n
		var cx := lerpf(a[0], b[0], t)
		var cy := lerpf(a[1], b[1], t)
		var ang := a0 + d * t
		var ln := lerpf(l0, l1, t)
		var px := cx + lengthdir_x(ln, ang)
		var py := cy + lengthdir_y(ln, ang)
		fogo_rastro.append([cx, cy, px, py, (n - k) * 0.3, vmax, k == 0])
		if randf() < chance and fogo_chamas.size() < maxc:
			var f := randf_range(0.65, 1.02)
			var v := randf_range(14, 26)
			var ch := PackedFloat32Array([lerpf(cx, px, f) + randf_range(-2, 2), lerpf(cy, py, f) + randf_range(-2, 2),
				(px - px_ant) * 0.12 + randf_range(-0.4, 0.4), (py - py_ant) * 0.12 - randf_range(0.6, 1.6),
				v, v, randf_range(2.2, 4.2) * (1.25 if forte else 1.0), randf() * 6.28])
			fogo_chamas.append(ch)
		if q > 0 and randf() < 0.35:
			faiscas_espada.append({"x": px, "y": py, "vx": (px - px_ant) * 0.2 + randf_range(-1, 1), "vy": (py - py_ant) * 0.2 - randf() * 1.5,
				"vida": randf_range(16, 30), "vmax": 30.0, "brasa": true})
		px_ant = px
		py_ant = py
	while fogo_rastro.size() > 70:
		fogo_rastro.remove_at(0)
	fogo_ult = 0.0


func fogo_espada_step(dt: float) -> void:
	fogo_ult += dt
	var lam: Array = V117.lamina_mundo(sprite_index, image_index, x, y, facing * escala, escala) if (golpe != null and not morto) else []
	if lam.is_empty():
		lamina_ant = []
		lamina_img = -1
	else:
		var img := int(image_index)
		if img != lamina_img or sprite_index != lamina_spr:
			if not lamina_ant.is_empty() and sprite_index == lamina_spr and V117.golpe_quadro_fogo(golpe, golpe_i):
				fogo_emitir(lamina_ant, lam)
			lamina_img = img
			lamina_spr = sprite_index
		lamina_ant = lam
	var i := fogo_rastro.size() - 1
	while i >= 0:
		var s: Array = fogo_rastro[i]
		s[4] += dt
		if s[4] >= s[5]:
			fogo_rastro.remove_at(i)
			if i == 0 and not fogo_rastro.is_empty():
				fogo_rastro[0][6] = true
		i -= 1
	var c := fogo_chamas.size() - 1
	var amort := pow(0.95, dt)
	while c >= 0:
		var p: PackedFloat32Array = fogo_chamas[c]
		p[0] += p[2] * dt
		p[1] += p[3] * dt
		p[2] *= amort
		p[3] -= 0.035 * dt
		p[4] -= dt
		if p[4] <= 0:
			fogo_chamas.remove_at(c)
		else:
			fogo_chamas[c] = p
		c -= 1


# Inimigo que pode levar o finalizador (perto e à frente / dos lados)
func alvo_finalizavel():
	var melhor = null
	var dist := 78.0
	for e in todos("obj_inimigo_base"):
		if not e.finalizavel or e.morrendo or not e.ativo or e.em_qte:
			continue
		# v1.17: a Árvore só entra cambaleando (sequência de golpes); como é
		# enorme, conta a distância até a borda do tronco
		if e.eh_boss and not e.qte_pronto:
			continue
		var d: float = maxf(0, maxf(e.bbox_left - x, x - e.bbox_right)) if e.eh_boss else absf(e.x - x)
		var alt_ok: bool = (y > e.bbox_top and y < e.bbox_bottom + 40) if e.eh_boss else absf(e.y - y) < 50
		if d <= dist and alt_ok:
			dist = d
			melhor = e
	return melhor


# =====================================================================
#  scr_dano: parte do JOGADOR
# =====================================================================
# A rolagem está no trecho em que nada acerta Twilight?
# Twilight caiu num abismo: morte na hora (nem a rolagem nem a fúria salvam)
func jogador_cair_abismo() -> void:
	if morto:
		return
	rolando = false
	recuando = false
	tempo_invencivel = 0
	levar_dano(vida + 9999, x, false, 0)
	som("sfx_derrota", 0.7, 0)


func jogador_intangivel() -> bool:
	return (rolando and rolar_t >= ROLAR_INVENC_INI and rolar_t <= ROLAR_INVENC_FIM) \
		or (recuando and recuar_t <= RECUAR_INVENC)


func levar_dano(dano: float, origem_x = null, bloqueavel := true, forca := 4.0, atacante = null, _golpe = null) -> void:
	if vida <= 0:
		return
	if origem_x == null:
		origem_x = x
	var d := signf(x - origem_x)
	if d == 0:
		d = 1
	var cy := (bbox_top + bbox_bottom) / 2.0
	if morto or G.transicao_fase or instance_exists("obj_final") or instance_exists("obj_resultado"):
		return
	# ----- ESQUIVA: no meio da rolagem nada acerta Twilight -----
	if jogador_intangivel():
		if not esquivou:
			esquivou = true
			esquiva_fx = 18
			camera_lenta(16, 0.55)
		return
	if tempo_invencivel > 0:
		return
	var de_frente: bool = origem_x == x or signf(origem_x - x) == facing
	# ----- APARAR (parry): defesa apertada na hora certa -----
	if janela_aparar > 0 and de_frente and atacante != null and G.existe(atacante):
		jogador_aparou(atacante)
		return
	# ----- DEFESA MÁGICA -----
	if bloqueando and bloqueavel and de_frente:
		jogador_bloqueou(origem_x)
		if atacante != null and G.existe(atacante) and atacante.has_method("inimigo_ricochete"):
			atacante.inimigo_ricochete(signf(atacante.x - x))
		return
	# v1.12: MODO FÚRIA = super armadura (metade do dano)
	if furia_modo:
		dano = maxf(1, round(dano * 0.5))
	vida = maxf(0, vida - dano)
	G.dano_na_luta += dano      # v1.17: conquista INTOCÁVEL (zera quando o Carrasco acorda)
	tempo_invencivel = 60
	tempo_sem_dano = 0
	G.combo = 0
	G.combo_tempo = 0
	G.last_hit_flash = 12
	G.last_hit_damage = dano
	G.camera_impact = 8
	impacto(6)
	camera_empurrar(d, 5, 0.2)          # a pancada empurra a tela junto
	som("sfx_dano", 0.9)
	G.vibrar(50)
	furia_ganhar(2)
	var sangue = instance_create_depth(x, cy, -100, "obj_fagulha")
	sangue.cor = Color8(255, 60, 50)
	# durante especiais, fúria e finalizador Twilight não é interrompido
	if (armadura or furia_modo) and vida > 0:
		tempo_invencivel = 30
		return
	empurrao = d * forca
	golpe_cancelar()
	cadeia = ""
	buffer_golpe = ""
	bloqueando = false
	rolando = false
	recuando = false
	contra_t = 0
	if vida <= 0:
		morto = true
		machucado = false
		tempo_invencivel = 0
		cura_restante = 0
		sprite_index = Spr.spr_player_morte
		image_index = 0
		image_speed = 1
		camera_lenta(50, 0.4)
		G.vibrar(200)
	else:
		machucado = true
		sprite_index = Spr.spr_player_dano
		image_index = 0
		image_speed = 1


# O jogador segurou um golpe/projétil na defesa mágica
func bloqueou(origem_x: float) -> void:
	var d := signf(x - origem_x)
	if d == 0:
		d = -facing
	empurrao = d * 1.8
	tempo_invencivel = 12
	defesa_fx = 16
	G.camera_impact = maxf(G.camera_impact, 5)
	var cy := (bbox_top + bbox_bottom) / 2.0
	var f = instance_create_depth(x + facing * 22, cy, -100, "obj_fagulha")
	f.cor = Color8(140, 200, 255)
	som("sfx_bloqueio", 0.8)


# APARAR: o golpe é rebatido (o inimigo fica atordoado; ver Lib.jogador_aparou)
func aparou(atacante) -> void:
	janela_aparar = 0
	aparar_recarga = 0
	machucado = false
	aparar_fx = 24
	defesa_fx = 16
	tempo_invencivel = maxf(tempo_invencivel, 24)
	bloqueando = false
	impacto(9)
	camera_lenta(34, 0.35)
	G.camera_impact = maxf(G.camera_impact, 10)
	G.last_hit_flash = 8
	som("sfx_aparar", 1)
	V117.perfil_somar("aparos")      # v1.17: conquista LÂMINA DE ESPELHO
	G.vibrar(30)
	var cy := (bbox_top + bbox_bottom) / 2.0
	fx_criar("aparar", x + facing * 20, cy - 6, 1)
	furia_ganhar(6)
	trocar_animacao(Spr.spr_player_defendendo, 1)
	image_index = 2
	# v1.12: CONTRA-ATAQUE: 8 quadros depois do aparar, Twilight revida sozinho
	if G.existe(atacante) and atacante.e_um("obj_inimigo_base") and absf(atacante.x - x) < 140:
		contra_t = 8
		contra_alvo = atacante


# TEIA: lento, sem pulo e sem rolagem
func enredar(quadros: float) -> void:
	if morto:
		return
	if enredado <= 0:
		enredado_max = quadros
		som("teia_prende", 0.85)
	enredado = maxf(enredado, quadros)
	enredado_max = maxf(enredado_max, enredado)
	enredado_fx = 10


# =====================================================================
#  STEP
# =====================================================================
func ev_step() -> void:
	var dt := G.dt
	if atravessar_t > 0:
		atravessar_t -= dt
	var chao := place_meeting(x, y + 1, "obj_chao") or plataforma_sob_pes() != null

	# ----- ENTRADAS -----
	var livre := not instance_exists("obj_final") and not instance_exists("obj_loading") and not instance_exists("obj_resultado") and G.bloqueio_input <= 0
	var left := livre and input_segurado(ACAO.ESQUERDA)
	var right := livre and input_segurado(ACAO.DIREITA)
	var jump := livre and input_apertado(ACAO.PULAR)
	var abaixar := livre and input_segurado(ACAO.AGACHAR)
	var bloqueio := livre and input_segurado(ACAO.DEFENDER)
	var aparar := livre and input_apertado(ACAO.DEFENDER)
	var interagir := livre and input_apertado(ACAO.INTERAGIR)
	var esquiva := livre and (input_apertado(ACAO.ESQUIVA) or G.esquiva_stick != 0)
	var furia_btn := livre and input_apertado(ACAO.FURIA)
	var botao := ""
	if livre:
		if input_apertado(ACAO.ATACAR):
			botao = "Q"
		if input_apertado(ACAO.ATAQUE_FORTE):
			botao = "T"
		if input_apertado(ACAO.ATAQUE_SALTO):
			botao = "C"
	var esp := -1
	if livre:
		if input_apertado(ACAO.ESPECIAL):
			esp = ACAO.ESPECIAL
		if input_apertado(ACAO.ESPECIAL_2):
			esp = ACAO.ESPECIAL_2
		if input_apertado(ACAO.ESPECIAL_3):
			esp = ACAO.ESPECIAL_3

	var dir_agora := int(right) - int(left)

	# ----- v1.12: LANÇADOR = PULAR + PESADO quase juntos (ou cima + PESADO) -----
	if botao == "T":
		pesado_t = 8
	else:
		pesado_t = maxf(0, pesado_t - dt)
	if jump and (chao or coyote > 0):
		pulo_t = 8
	else:
		pulo_t = maxf(0, pulo_t - dt)
	var cima := livre and G.inp_cima
	# v1.14: escalando: sem golpes, defesa, esquiva, fúria nem interação
	if escalando:
		botao = ""
		esp = -1
		esquiva = false
		bloqueio = false
		aparar = false
		furia_btn = false
		interagir = false
	# ----- MENUS: pausa (opções) · armas e evolução -----
	if livre and not morto and not instance_exists("obj_pausa") and not instance_exists("obj_save_menu") and not instance_exists("obj_menu_armas"):
		if input_pausa_apertada():
			instance_create_depth(0, 0, -10000, "obj_pausa")
			return
		if input_armas_apertado():
			instance_create_depth(0, 0, -10000, "obj_menu_armas")
			return

	# ----- INTERAGIR: cristal dourado (salvar) e baús de vida -----
	alvo_interacao = null
	if not morto and chao and golpe == null and not rolando:
		var bau = instance_nearest(x, y, "obj_bau")
		if bau != null and bau.estado == "fechado" and bau.visivel and absf(bau.x - x) < 46 and absf(bau.y - y) < 40:
			alvo_interacao = bau
		else:
			var sp = instance_nearest(x, y, "obj_save_point")
			if sp != null and point_distance(x, y, sp.x, sp.y) < 70:
				alvo_interacao = sp
	var interagir_livre := interagir and alvo_interacao == null
	if interagir and alvo_interacao != null and not instance_exists("obj_save_menu") and not instance_exists("obj_pausa"):
		if alvo_interacao.obj == "obj_bau":
			facing = signf(alvo_interacao.x - x)
			if facing == 0:
				facing = 1
			alvo_interacao.bau_abrir(self)
			velh = 0
		else:
			if dif_cristal_cura():
				vida = vida_max
				vida_atraso = vida
			var menu_salvar = instance_create_depth(0, 0, -10000, "obj_save_menu")
			menu_salvar.modo = "salvar"
			return

	# ----- TEMPORIZADORES -----
	if tempo_invencivel > 0:
		tempo_invencivel = maxf(0, tempo_invencivel - dt)
	if buffer_pulo > 0:
		buffer_pulo -= dt
	if buffer_golpe_t > 0:
		buffer_golpe_t -= dt
		if buffer_golpe_t <= 0:
			buffer_golpe = ""
	if cadeia_janela > 0:
		cadeia_janela -= dt
		if cadeia_janela <= 0 and golpe == null:
			cadeia = ""
	if combo_nome_t > 0:
		combo_nome_t -= dt
	if objetivo_t > 0:
		objetivo_t -= G.dt_real
	if brilho_golpe > 0:
		brilho_golpe -= dt
	if pouso > 0:
		pouso -= dt
	if especial_pronto_fx > 0:
		especial_pronto_fx -= dt
	if defesa_fx > 0:
		defesa_fx -= dt
	if barreira_aviso > 0:
		barreira_aviso -= dt
	if bloqueado_aviso > 0:
		bloqueado_aviso -= dt
	if rolar_recarga > 0:
		rolar_recarga -= dt
	if janela_aparar > 0:
		janela_aparar -= dt
	if aparar_recarga > 0:
		aparar_recarga -= dt
	if aparar_fx > 0:
		aparar_fx -= dt
	if esquiva_fx > 0:
		esquiva_fx -= G.dt_real
	if furia_cheia_fx > 0:
		furia_cheia_fx -= dt
	if cura_fx > 0:
		cura_fx -= dt
	if G.combo_tempo > 0:
		G.combo_tempo -= dt
		if G.combo_tempo <= 0:
			G.combo = 0
	if G.last_hit_flash > 0:
		G.last_hit_flash = maxf(0, G.last_hit_flash - G.dt_real)
	if G.camera_impact > 0:
		G.camera_impact = maxf(0, G.camera_impact - G.dt_real)
	if G.terremoto > 0:
		G.terremoto = maxf(0, G.terremoto - G.dt_real)
	if debug_golpe.size() > 4:
		debug_golpe[4] -= dt
		if debug_golpe[4] <= 0:
			debug_golpe = []
	# faíscas do corte: voam, caem e somem
	for fe in range(faiscas_espada.size() - 1, -1, -1):
		var fs: Dictionary = faiscas_espada[fe]
		fs.x += fs.vx * dt
		fs.y += fs.vy * dt
		fs.vy += (0.05 if fs.brasa else 0.14) * dt
		fs.vx *= pow(0.95, dt)
		fs.vida -= dt
		if fs.vida <= 0:
			faiscas_espada.remove_at(fe)
	for r in range(rastros.size() - 1, -1, -1):
		rastros[r].vida -= dt
		if rastros[r].vida <= 0:
			rastros.remove_at(r)
	for fa in range(fantasmas.size() - 1, -1, -1):
		fantasmas[fa].vida -= dt
		if fantasmas[fa].vida <= 0:
			fantasmas.remove_at(fa)

	# ----- CURA AOS POUCOS (magia do baú entrando em Twilight) -----
	if cura_restante > 0 and not morto:
		var c := minf(cura_restante, 0.55 * dt)
		vida = minf(vida_max, vida + c)
		cura_restante -= c
		if vida >= vida_max:
			cura_restante = 0

	if livre and not morto:
		tempo_fase += dt

	# ----- BARRA DE MAGIA DOS ESPECIAIS: enche em 10 segundos -----
	if not especial and especial_carga < ESPECIAL_SEGUNDOS:
		var antes := especial_carga
		especial_carga = minf(ESPECIAL_SEGUNDOS, especial_carga + dt / 60.0)
		if especial_carga >= ESPECIAL_SEGUNDOS and antes < ESPECIAL_SEGUNDOS:
			especial_pronto_fx = 50

	# ----- v1.12: MODO FÚRIA: dura 12 s (a barra esvazia) -----
	if furia_modo:
		furia -= 100.0 / FURIA_MODO_QUADROS * dt
		if randf() < 0.3 * dt:
			var fg = instance_create_depth(x + randf_range(-14, 14), y - randf_range(10, 60), depth - 1, "obj_fagulha")
			fg.cor = choose([Color8(255, 40, 30), Color8(200, 10, 10)])
		if furia <= 0:
			furia = 0
			furia_modo = false
			som("furia_fim", 0.8)

	# zoom dramático durante os especiais
	if instance_exists("obj_qte"):
		var qte = instance_find("obj_qte", 0)
		G.camera_zoom = 1.0 if qte.estado == "falha" else 1.24     # v1.17: sequência de golpes de perto
	elif golpe == null or (golpe.chave != "finalizador" and golpe.chave != "ira"):
		G.camera_zoom = 1.14 if especial else 1.0

	if not morto:
		tempo_sem_dano += dt

	# ----- CAIU DO MAPA: volta ao checkpoint -----
	if not morto and y > G.room_height + 160:
		var rx := spawn_x
		var ry := spawn_y
		if G.checkpoint_ativo and G.room == G.checkpoint_room:
			rx = G.checkpoint_x
			ry = G.checkpoint_y
		x = rx
		y = ry
		velh = 0
		velv = 0
		empurrao = 0
		tempo_invencivel = 60
		machucado = false
		bloqueando = false
		rolando = false
		golpe_cancelar()
		cadeia = ""
		trocar_animacao(Spr.spr_player_parado, 1)
		G.cam_snap = true

	# ----- FIM DA FASE 1: chegou ao fim do caminho depois de vencer o boss -----
	if not morto and livre and G.room == "Room1" and x >= G.room_width - 100 and not G.transicao_fase and instance_number("obj_boss_01") == 0:
		G.transicao_fase = true
		if DEMO_FIM_NA_FASE_1:
			instance_create_depth(0, 0, -10500, "obj_resultado")
		else:
			G.capitulo = 2
			G.checkpoint_ativo = false
			som("fase_concluida", 1, 0)
			var load_ = instance_create_depth(0, 0, -10000, "obj_loading")
			load_.modo = "transicao"
			load_.destino = "Room2"

	# ----- FIM DO JOGO NA FASE 2: não resta nenhum inimigo vivo -----
	if not morto and livre and G.room == "Room2" and not G.transicao_fase and inimigos_vivos() == 0:
		instance_create_depth(0, 0, -10500, "obj_final")

	# =====================================================================
	# MORTE
	# =====================================================================
	if morto:
		velh = 0
		if not chao:
			velv += grav * dt
		tempo_morte += dt
		if tempo_morte >= 90 and not instance_exists("obj_game_over"):
			instance_create_depth(0, 0, -10000, "obj_game_over")
		return

	if machucado:
		velh = 0
	var pode_agir := not machucado

	# ----- TEIA DA MULHER-ARANHA: lento, sem pulo e sem rolagem -----
	if teia_imune > 0:
		teia_imune = maxf(0, teia_imune - dt)
	if enredado_fx > 0:
		enredado_fx = maxf(0, enredado_fx - dt)
	if enredado > 0:
		enredado = maxf(0, enredado - dt)
		if jump or esquiva or botao != "" or furia_btn:
			enredado = maxf(0, enredado - 13)
			enredado_fx = 6
		jump = false
		esquiva = false
		rolar_buffer = 0
		buffer_pulo = 0
		if enredado <= 0:
			teia_imune = 40
			som("teia_disparo", 0.35)

	# =====================================================================
	# v1.12: BACKDASH — salto rápido para trás (ESQUIVA sem direção)
	# =====================================================================
	if recuando:
		var ra := recuar_t
		recuar_t += dt
		var rp := clampf(recuar_t / RECUAR_DURACAO, 0, 1)
		velh = -facing * RECUAR_VEL * pow(1 - rp, 1.4)
		if floor(ra / 3.0) != floor(recuar_t / 3.0):
			fantasmas.append({"x": x, "y": y, "ang": 0.0, "dir": facing, "vida": 10.0, "vmax": 10.0, "spr": Spr.spr_player_jump, "img": 1})
		if not chao:
			velv += grav * dt
		elif velv > 0:
			velv = 0
		if recuar_t >= 8 and (botao != "" or buffer_golpe != ""):
			recuando = false
			trocar_animacao(Spr.spr_player_parado, 1)
		elif recuar_t >= RECUAR_DURACAO:
			recuando = false
			rolar_recarga = 2
			trocar_animacao(Spr.spr_player_parado if chao else Spr.spr_player_fall, 1)
		if recuando:
			return

	# =====================================================================
	# ESQUIVA (rolagem): quadros 2-19 de 26 sem levar dano
	# =====================================================================
	if rolando:
		var t_antes := rolar_t
		rolar_t += dt
		var p := clampf(rolar_t / ROLAR_DURACAO, 0, 1)
		velh = rolar_dir * ROLAR_VEL * (1 - 0.72 * p)
		if floor(t_antes / 3.0) != floor(rolar_t / 3.0):
			fantasmas.append({"x": x, "y": y, "ang": rolar_angulo(p, rolar_dir), "dir": rolar_dir, "vida": 12.0, "vmax": 12.0})
		if chao and floor(t_antes / 7.0) != floor(rolar_t / 7.0):
			fx_criar("poeira", x - rolar_dir * 10, y, 0.35)
		if rolar_t >= ROLAR_DURACAO:
			rolando = false
			rolar_recarga = 3
			if chao:
				fx_criar("poeira", x, y, 0.6)
			trocar_animacao(Spr.spr_player_parado, 1)
		if not chao:
			velv += grav * dt
		elif velv > 0:
			velv = 0
		return
	if esquiva:
		rolar_buffer = ROLAR_BUFFER
		rolar_buffer_dir = G.esquiva_stick
	elif rolar_buffer > 0:
		rolar_buffer -= dt
	var pode_rolar: bool = chao and pode_agir and rolar_recarga <= 0 and (golpe == null or not golpe.armadura)
	# v1.12: sem direção apertada, a esquiva vira BACKDASH
	if rolar_buffer > 0 and pode_rolar and rolar_buffer_dir == 0 and dir_agora == 0:
		rolar_buffer = 0
		golpe_cancelar()
		cadeia = ""
		buffer_golpe = ""
		recuando = true
		recuar_t = 0
		esquivou = false
		bloqueando = false
		agachado = false
		velv = -2.4
		chao = false
		sprite_index = Spr.spr_player_jump
		image_index = 1
		image_speed = 0
		som("sfx_backdash", 0.8)
		fx_criar("poeira", x + facing * 6, y, 0.4)
		return
	if rolar_buffer > 0 and pode_rolar:
		rolar_buffer = 0
		golpe_cancelar()
		cadeia = ""
		buffer_golpe = ""
		rolando = true
		rolar_t = 0
		esquivou = false
		rolar_dir = float(rolar_buffer_dir) if rolar_buffer_dir != 0 else (float(dir_agora) if dir_agora != 0 else facing)
		facing = rolar_dir
		bloqueando = false
		agachado = false
		sprite_index = Spr.spr_player_agaichar
		image_speed = 0
		som("sfx_esquiva", 0.9)
		fx_criar("poeira", x - rolar_dir * 10, y, 0.5)
		return

	# ----- APARAR: apertar a defesa na hora certa -----
	if aparar and chao and pode_agir and aparar_recarga <= 0 and golpe == null:
		janela_aparar = APARAR_JANELA
		aparar_recarga = APARAR_RECARGA

	# =====================================================================
	# GOLPES
	# =====================================================================
	if botao != "":
		buffer_golpe = botao
		buffer_golpe_t = 18

	# ----- v1.12: CONTRA-ATAQUE automático logo depois de aparar -----
	if contra_t > 0:
		contra_t -= dt
		if contra_t <= 0 and G.existe(contra_alvo) and not contra_alvo.morrendo and pode_agir:
			facing = signf(contra_alvo.x - x)
			if facing == 0:
				facing = 1
			golpe_cancelar()
			golpe_iniciar("contra")
			cadeia = ""
			buffer_golpe = ""
			popup_criar(x + facing * 30, y - 80, "CONTRA-ATAQUE!", Color8(140, 200, 255), 1)

	# ----- v1.12: LANÇADOR -----
	if ((pesado_t > 0 and pulo_t > 0) or (botao == "T" and cima)) and no_ar_tempo < 10 and pode_agir and not bloqueando \
			and (golpe == null or (not golpe.armadura and golpe.chave != "lancador")):
		golpe_cancelar()
		golpe_iniciar("lancador")
		golpe_letra = "T"
		pesado_t = 0
		pulo_t = 0
		buffer_pulo = 0
		buffer_golpe = ""
		cadeia = ""

	var livre_para_golpe: bool = golpe == null or (not golpe.armadura and not especial and golpe_i >= golpe.cancel)

	# ----- FINALIZADOR: BOLA (ou INTERAGIR) perto de um inimigo marcado -----
	var executou := false
	if (buffer_golpe == "C" or interagir_livre) and chao and pode_agir and livre_para_golpe:
		var fin = alvo_finalizavel()
		if fin != null:
			facing = signf(fin.x - x)
			if facing == 0:
				facing = 1
			golpe_cancelar()
			# v1.17: Carrasco (com 1/4 da vida) e Árvore (cambaleando): SEQUÊNCIA DE GOLPES.
			# Acima disso, o Carrasco aparado leva o finalizador de sempre (25% da vida).
			if fin.usa_qte and (fin.eh_boss or fin.vida <= fin.vida_max * 0.25 + 1):
				V117.qte_iniciar(fin)
			else:
				alvo_final = fin
				fin.executando = true
				fin.finalizavel = false
				fin.velh = 0
				fin.empurrao = 0
				golpe_iniciar("finalizador")
			cadeia = ""
			buffer_golpe = ""
			livre_para_golpe = false
			executou = true

	# ----- v1.12: SUB-ARMAS (INTERAGIR longe de baús e cristais) -----
	if interagir_livre and not executou and pode_agir and livre_para_golpe:
		var agach := abaixar and chao
		var custo := subarma_custo(agach)
		if not agach and instance_exists("obj_bumerangue"):
			bloqueado_txt = "A LÂMINA AINDA NÃO VOLTOU"
			bloqueado_aviso = 45
			som("sfx_negado", 0.5, 0)
		elif G.essencia < custo:
			bloqueado_txt = subarma_nome(agach) + ": ESSÊNCIA INSUFICIENTE (" + str(custo) + ")"
			bloqueado_aviso = 70
			som("sfx_negado", 0.6, 0)
		else:
			G.essencia -= custo
			G.essencia_fx = 14
			if right != left:
				facing = 1.0 if right else -1.0
			golpe_cancelar()
			golpe_iniciar("arremesso_chama" if agach else "arremesso")
			cadeia = ""
			buffer_golpe = ""
			livre_para_golpe = false

	# ----- FÚRIA: barra cheia + botão de fúria -----
	if furia_btn and furia >= 100 and not furia_modo and chao and pode_agir and livre_para_golpe:
		golpe_cancelar()
		golpe_iniciar("ira")
		cadeia = ""
		buffer_golpe = ""
		livre_para_golpe = false
	elif furia_btn and furia < 100 and not furia_modo and livre:
		bloqueado_txt = "A FÚRIA AINDA NÃO ESTÁ CHEIA"
		bloqueado_aviso = 70
		som("sfx_negado", 0.6, 0)

	# ----- ESPECIAIS -----
	if esp != -1 and pode_agir and (golpe == null or (not especial and not golpe.armadura and golpe_i >= golpe.cancel)):
		if not especial_liberado(esp):
			bloqueado_txt = especial_nome(esp) + ": EVOLUA A ESPADA ATÉ O NÍVEL " + str(especial_nivel_req(esp)) + "  (" + botao_menu_armas() + ")"
			bloqueado_aviso = 110
			som("sfx_negado", 0.6, 0)
		elif especial_carga < especial_custo(esp) * ESPECIAL_SEGUNDOS:
			bloqueado_txt = "MAGIA INSUFICIENTE"
			bloqueado_aviso = 60
			som("sfx_negado", 0.5, 0)
		elif chao:
			var ch := "tremor"
			if esp == ACAO.ESPECIAL:
				ch = "onda_agachado" if abaixar else "onda"
			if esp == ACAO.ESPECIAL_2:
				ch = "queda"
			if right != left:
				facing = 1.0 if right else -1.0
			golpe_cancelar()
			golpe_iniciar(ch)
			cadeia = ""
			buffer_golpe = ""

	# ----- ATAQUES: QUADRADO / TRIÂNGULO / BOLA e os combos -----
	var pode_golpear := pode_agir and not bloqueando
	if buffer_golpe != "" and pode_golpear:
		var livre_golpe: bool = golpe == null
		if not livre_golpe and not especial and not golpe.armadura and golpe_i >= golpe.cancel:
			livre_golpe = true
		if livre_golpe:
			var cad := cadeia if (cadeia_janela > 0 or golpe != null) else ""
			var prox := combo_proximo(cad, buffer_golpe, not chao, abaixar and chao)
			if prox == "corte_aereo" and aereo_n >= AEREO_MAX:
				prox = ""
				buffer_golpe = ""
			if prox != "":
				if prox == "corte_aereo":
					aereo_n += 1
				var letra_g := buffer_golpe
				if right != left:
					facing = 1.0 if right else -1.0
				golpe_cancelar()
				golpe_iniciar(prox)
				var letra := "C" if (prox == "rasteira" and buffer_golpe == "Q") else buffer_golpe
				cadeia = "" if (golpe.combo > 0 or not chao) else (cad + letra).right(3)     # v1.17: 3 letras (4 toques)
				buffer_golpe = ""
				golpe_letra = letra_g

	# ----- v1.12: PULO CANCELA golpes no chão -----
	if buffer_pulo > 0 and chao and golpe != null and not golpe.armadura and not golpe.no_ar and pode_agir and not abaixar \
			and (golpe_idade <= 7 or golpe_i >= golpe.cancel):
		var lg := golpe_letra
		var cedo := golpe_idade <= 7
		golpe_cancelar()
		cadeia = ""
		velv = -vel_jump
		buffer_pulo = 0
		coyote = 0
		chao = false
		pouso = 0
		sprite_index = Spr.spr_player_jump
		image_index = 1
		som("sfx_pulo", 0.5)
		if cedo and lg != "":
			buffer_golpe = lg
			buffer_golpe_t = 10

	# =====================================================================
	# GOLPE EM ANDAMENTO: a animação segue a tabela de quadros
	# =====================================================================
	if golpe != null:
		var g = golpe
		var e: Dictionary = g.seq[golpe_i]
		if not g.no_ar or chao:
			velh = 0
		else:
			# v1.17: no ar o impulso do pulo continua, mas o empurrão do quadro anterior
			# sai antes de somar o deste (antes ele se acumulava a cada quadro e
			# Twilight saía voando para trás ao bater num escudo / na estátua no pulo)
			velh -= empurrao_ult
		if e.has("av"):
			velh = facing * e.av
		if g.chave == "finalizador" and G.existe(alvo_final) and not alvo_final.eh_boss:     # a Árvore não sai do lugar
			if not alvo_final.morrendo:
				alvo_final.x = lerpf(alvo_final.x, x + facing * 34, 0.25)
				alvo_final.velh = 0
		golpe_t += dt * (1.35 if furia_modo else 1.0)
		golpe_idade += dt
		var seguro := 0
		while golpe != null and seguro < 8:
			seguro += 1
			e = golpe.seq[golpe_i]
			if golpe_t < e.d:
				break
			var ok := true
			if e.has("esp"):
				var no_chao := (place_meeting(x, y + 1, "obj_chao") or plataforma_sob_pes() != null) and velv >= 0
				if e.esp == "apice":
					ok = velv >= 0
				if e.esp == "descendo":
					ok = velv >= 0 or no_chao
				if e.esp == "chao":
					ok = no_chao
			if not ok:
				golpe_t = e.d
				break
			golpe_t -= e.d
			golpe_i += 1
			if golpe_i >= golpe.seq.size():
				golpe_cancelar()
				cadeia_janela = 16
				trocar_animacao(Spr.spr_player_parado if chao else Spr.spr_player_fall, 1)
				break
			golpe_entrar_quadro()
		if golpe != null:
			golpe_acertar()

	# ----- ONDAS (especial Onda Carmesim e Ira de Vallack) -----
	for o in range(ondas.size() - 1, -1, -1):
		var on: Dictionary = ondas[o]
		var ira: bool = on.has("ira")
		on.dist = minf(on.dist_max, on.dist + (12.0 if ira else 8.0) * dt)
		on.vida -= dt
		var ox1: float = on.x0 + on.dir * (on.dist - 20)
		var ox2: float = on.x0 + on.dir * (on.dist + 10)
		var gw := {"chave": "ira", "especial": false, "pesado": true, "porcento": 0, "dano": 0, "combo": 0} if ira \
			else {"chave": "onda", "especial": true, "pesado": false, "porcento": 0.30, "dano": 0, "combo": 0}
		for alvo in collision_rectangle_list(minf(ox1, ox2), y + on.y_topo, maxf(ox1, ox2), y + on.y_base, "obj_inimigo_base"):
			if on.atingidos.has(alvo) or atingidos.has(alvo) or alvo.morrendo or not alvo.ativo:
				continue
			on.atingidos.append(alvo)
			atingidos.append(alvo)
			var de := dano_golpe(gw, alvo, 1)
			alvo.levar_dano(de, x, false, 9, self, gw)
			if not alvo.morrendo and not alvo.eh_boss:
				alvo.inimigo_atordoar(60)
			impacto(3)
			fx_criar("faiscas_golpe", alvo.x, (alvo.bbox_top + alvo.bbox_bottom) / 2.0, 1)
		for d in collision_rectangle_list(minf(ox1, ox2), y + on.y_topo, maxf(ox1, ox2), y + on.y_base, "obj_destrutivel"):
			if on.atingidos.has(d):
				continue
			on.atingidos.append(d)
			d.destrutivel_bater(2, x)
		if on.vida <= 0:
			ondas.remove_at(o)

	# =====================================================================
	# v1.14: ESCALAR — escadas de mão, cordas e correntes (dados no obj_terreno).
	# PULO / cima segurado perto delas agarra e sobe; ▼ desce; PULO + lado salta
	# para fora; no alto, Twilight passa para a plataforma; um golpe o derruba.
	# =====================================================================
	var sobe := livre and (input_segurado(ACAO.PULAR) or G.inp_cima)
	if not escalando and not morto and not machucado and not rolando and golpe == null:
		for ei in G.escalaveis.size():
			var es: Array = G.escalaveis[ei]
			if absf(x - es[0]) > 13:
				continue
			var no_trecho: bool = y > es[1] + 2 and y <= es[2] + 2
			var no_topo: bool = absf(y - es[1]) <= 2 and chao
			var agarra: bool = no_trecho and sobe and ((jump or G.inp_cima) if chao else velv > -3)
			if agarra or (no_topo and abaixar):
				escalando = true
				escala_i = ei
				escala_agarrar = 0.0 if es[3] == "escada" else 18.0     # v1.17: pula e agarra a corda / corrente
				escala_desce = not agarra
				if not agarra:
					y += 4            # desce pela borda de cima
				velh = 0
				velv = 0
				anda_v = 0
				buffer_pulo = 0
				coyote = 0
				atravessar_t = 10
				agachado = false
				break
	# Atingido (ou morto / em golpe) pendurado: solta ANTES de trocar a sprite.
	# Antes o bloco abaixo sobrescrevia spr_player_dano pela sprite da corda com
	# image_speed = 0; a animação de dano nunca terminava (ev_anim_end) e Twilight
	# caía preso com machucado = true, sem poder fazer nada.
	if escalando and (machucado or morto or golpe != null):
		escalando = false
		escala_i = -1
	if escalando:
		var es: Array = G.escalaveis[escala_i]
		x = lerpf(x, es[0], 0.4)
		if absf(x - es[0]) < 0.6:
			x = es[0]
		var vy := 0.0
		if sobe:
			vy = -2.2
		elif abaixar:
			vy = 2.6
		velh = 0
		velv = vy
		empurrao = 0
		if vy != 0:
			escala_anim += absf(vy) * dt
		# v1.17: animações da equipe: de costas subindo / descendo a escada de mão;
		# na corda e na corrente, primeiro pula e agarra, depois segura e sobe
		image_speed = 0
		if es[3] == "escada":
			if vy > 0:
				escala_desce = true
			elif vy < 0:
				escala_desce = false
			sprite_index = Spr.spr_player_descendo_escada if escala_desce else Spr.spr_player_subindo_escada
			image_index = int(escala_anim / 9.0) % sprite_index.n
		elif escala_agarrar > 0:
			escala_agarrar = maxf(0, escala_agarrar - dt)
			sprite_index = Spr.spr_player_pular_e_agarrar_cordas
			image_index = mini(4, int((1 - escala_agarrar / 18.0) * 5))
		else:
			sprite_index = Spr.spr_player_segurando_e_subindo_cordas
			image_index = int(escala_anim / 10.0) % 6
		var sai := false
		if machucado or morto or golpe != null:
			sai = true
		elif jump and (left or right):
			# salta para fora da escada / corda
			sai = true
			facing = int(right) - int(left)
			velv = -vel_jump * 0.85
			velh = facing * vel_correr
			anda_v = velh
			som("sfx_pulo", 0.5)
		elif y + vy * dt <= es[1]:
			# chegou ao alto: passa para a plataforma
			sai = true
			y = es[1]
			velv = 0
			x += float(es[4]) * 22
			if es[4] != 0:
				facing = es[4]
			pouso = 4
		elif vy > 0 and place_meeting(x, y + 2, "obj_chao"):
			sai = true                # chegou embaixo
		if sai:
			escalando = false
			escala_i = -1

	# =====================================================================
	# DEFESA E AGACHAR (sem golpe em andamento)
	# =====================================================================
	var em_golpe := golpe != null
	bloqueando = (bloqueio or janela_aparar > 0) and chao and not em_golpe and pode_agir
	if bloqueando:
		velh = 0
		trocar_animacao(sprite_defesa, 1)
	agachado = abaixar and chao and not em_golpe and pode_agir and not bloqueando
	# v1.14: abaixado, a caixa que leva golpes encolhe junto com o corpo (pés no lugar;
	# o desenho não usa image_yscale). Antes a flecha "acertava a cabeça" que já tinha descido.
	if agachado or sprite_index == Spr.spr_player_agaichar or sprite_index == Spr.spr_player_atacar_agaichado:
		image_yscale = 0.65
	elif sprite_index == Spr.spr_player_atacar_agaichado_especial:
		image_yscale = 0.8
	else:
		image_yscale = 1

	# =====================================================================
	# MOVIMENTO
	# =====================================================================
	if chao:
		coyote = 6
		aereo_n = 0
	else:
		coyote = maxf(0, coyote - dt)
	if jump:
		buffer_pulo = 12
	if not chao:
		no_ar_tempo += dt
	else:
		if no_ar_tempo > 14:
			pouso = 7
			som("sfx_pouso", 0.45)
		no_ar_tempo = 0

	if not em_golpe and not machucado and not bloqueando and not escalando:
		var mov := int(right) - int(left)
		var v := vel_correr
		if agachado:
			v = vel_agachado
		if enredado > 0:
			v *= 0.35
		# v1.14: acelera e freia (para virar, freia até zero e acelera para o outro
		# lado em ~0,1 s) em vez de trocar +v por -v num quadro; no ar, menos controle
		if chao:
			velh_para(mov * v, 1.0, 1.3)
		else:
			velh_para(mov * v, 0.55, 0.5)
		if mov != 0:
			facing = mov
			pouso = 0
		# v1.13: ▼ + PULO numa passarela ou ilha de mão única: desce por ela
		if buffer_pulo > 0 and abaixar and chao and plataforma_sob_pes() != null:
			atravessar_t = 14
			buffer_pulo = 0
			coyote = 0
			y += 2
			velv = 1
			chao = false
		if buffer_pulo > 0 and coyote > 0 and not abaixar:
			velv = -vel_jump
			buffer_pulo = 0
			coyote = 0
			chao = false
			pouso = 0
			sprite_index = Spr.spr_player_jump
			image_index = 1
			som("sfx_pulo", 0.5)
		if chao:
			if agachado:
				trocar_animacao(Spr.spr_player_agaichar, 0)
			elif velh != 0:
				# a corrida avança a animação pela distância percorrida
				# v1.19: abaixo de 60% da corrida (teia, arrancada, freada) ele anda;
				# a fase do passo (fração do ciclo) continua ao trocar entre os dois
				var andando := absf(velh) < vel_correr * 0.6
				if sprite_index != Spr.spr_player_andar and sprite_index != Spr.spr_player_corrida:
					anim_passo = 0
				sprite_index = Spr.spr_player_andar if andando else Spr.spr_player_corrida
				image_speed = 0
				var ciclo := 64.0 if andando else 92.0   # px por ciclo completo (2 passadas)
				anim_passo = fposmod(anim_passo + absf(velh) * dt / ciclo, 1.0)
				image_index = anim_passo * sprite_index.n
			elif pouso > 0:
				sprite_index = Spr.spr_player_fall
				image_index = 3
				image_speed = 0
			else:
				trocar_animacao(Spr.spr_player_parado, 1)
		else:
			if velv < 0:
				if sprite_index != Spr.spr_player_jump:
					sprite_index = Spr.spr_player_jump
					image_index = 1
				image_speed = 1.4
				if image_index >= 4.9:
					image_index = 4
			else:
				if sprite_index != Spr.spr_player_fall:
					sprite_index = Spr.spr_player_fall
					image_index = 0
				image_speed = 1
				if image_index >= 2.9:
					image_index = 0

	# ----- EMPURRÃO E GRAVIDADE -----
	velh += empurrao
	empurrao_ult = empurrao
	empurrao = lerp_dt(empurrao, 0, 0.12)
	if absf(empurrao) < 0.2:
		empurrao = 0
	if not chao and not escalando:
		velv += grav * dt
	elif velv > 0 and not escalando:
		velv = 0
	# ----- v1.17: RASTRO DE FOGO DA ESPADA (segue a lâmina de cada quadro) -----
	fogo_espada_step(dt)


# ===== END STEP =====
func ev_step_end() -> void:
	super()
	# BARREIRA DO GUARDIÃO: enquanto o boss da fase vive, não dá para seguir
	var boss = instance_find("obj_boss_01", 0)
	if boss != null and not boss.morrendo and x > boss.barreira_x - 14:
		x = boss.barreira_x - 14
		if velh > 0:
			velh = 0
		if empurrao > 0:
			empurrao = 0
		if barreira_aviso <= 0:
			som_mensagem()     # v1.16: o alerta da barreira aparece
		barreira_aviso = 90
	camera_atualizar(self)
	G.ultimo_x = x
	G.ultimo_y = y
	G.ultima_vida = vida


# ===== ANIMATION END =====
func ev_anim_end() -> void:
	if sprite_index == Spr.spr_player_dano:
		machucado = false
		trocar_animacao(Spr.spr_player_parado, 1)
	elif sprite_index == Spr.spr_player_morte:
		image_index = image_number - 1
		image_speed = 0


# =====================================================================
#  DRAW
# =====================================================================
func ev_draw() -> void:
	# ===== SOMBRA =====
	if place_meeting(x, y + 2, "obj_chao") or plataforma_sob_pes() != null:
		draw_set_alpha(0.45)
		draw_set_color(c_black)
		draw_ellipse(x - 18, y - 4, x + 18, y + 3, false)
		draw_set_alpha(1)
	var esc := escala * sprite_fator(sprite_index, image_index)
	var t := current_time()
	# ===== AURA DOS ESPECIAIS =====
	if especial:
		gpu_set_blendmode(bm_add)
		var pul := 0.35 + 0.2 * sin(t / 50.0)
		var cor_aura := Color8(200, 20, 30)
		if golpe != null and golpe.chave == "tremor":
			cor_aura = Color8(255, 120, 30)
		if golpe != null and golpe.chave == "queda":
			cor_aura = Color8(255, 60, 20)
		draw_sprite_hd(sprite_index, image_index, x, y, facing * esc * 1.06, esc * 1.04, 0, cor_aura, pul)
		gpu_set_blendmode(bm_normal)
	# ===== ENERGIA JUNTANDO (especial 3 carregando) =====
	if carga_fx > 0:
		gpu_set_blendmode(bm_add)
		var cy0 := y - 44
		var t0 := t / 60.0
		for k in 10:
			var ang := t0 * 9 + k * 36
			var dist := 46 - fmod(t0 * 6 + k * 7, 40)
			draw_set_alpha(0.25 + 0.5 * (1 - dist / 46.0))
			draw_set_color(Color8(255, 150 + 10 * (k % 3), 60))
			draw_circle(x + lengthdir_x(dist, ang), cy0 + lengthdir_y(dist * 0.8, ang), 2 + carga_fx, false)
		draw_set_alpha(0.18 * carga_fx)
		draw_set_color(Color8(255, 110, 30))
		draw_circle(x, cy0, 16 + 6 * carga_fx + 3 * sin(t / 40.0), false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# ===== v1.12: MODO FÚRIA: aura de sangue forte =====
	if furia_modo and not morto:
		gpu_set_blendmode(bm_add)
		var fm := 0.4 + 0.2 * sin(t / 35.0)
		draw_sprite_hd(sprite_index, image_index, x + randf_range(-1.5, 1.5), y, facing * esc * 1.12, esc * 1.08, 0, Color8(255, 20, 10), fm)
		draw_sprite_hd(sprite_index, image_index, x, y - 2, facing * esc * 1.2, esc * 1.14, 0, Color8(140, 0, 0), fm * 0.5)
		gpu_set_blendmode(bm_normal)
	elif furia >= 100 and not morto:
		gpu_set_blendmode(bm_add)
		var fp := 0.25 + 0.15 * sin(t / 45.0)
		draw_sprite_hd(sprite_index, image_index, x + randf_range(-1, 1), y, facing * esc * 1.08, esc * 1.05, 0, Color8(255, 30, 10), fp)
		gpu_set_blendmode(bm_normal)
	# ===== CURA =====
	if cura_restante > 0 or cura_fx > 0:
		gpu_set_blendmode(bm_add)
		var ca := 0.25 + 0.15 * sin(t / 80.0)
		draw_sprite_hd(sprite_index, image_index, x, y, facing * esc * 1.05, esc * 1.03, 0, Color8(255, 150, 60), ca)
		for cp in 4:
			var cf := frac(t / 900.0 + cp / 4.0)
			draw_set_alpha((1 - cf) * 0.8)
			draw_set_color(Color8(255, 200, 110))
			draw_circle(x + sin(cp * 2.1 + t / 300.0) * 12, y - 10 - cf * 60, 2, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# ===== GUERREIRO =====
	var cor := c_white
	if tempo_invencivel > 0 and not morto and not rolando and int(floor(tempo_invencivel / 4.0)) % 2 == 0:
		cor = Color8(255, 95, 95)
	if fantasmas.size() > 0:
		var kf := hd_escala(Spr.spr_player_agaichar)
		var hf := Spr.spr_player_agaichar.h / kf * esc * 0.5 * 0.86
		for fa in fantasmas:
			var ga: float = fa.ang
			if fa.has("spr"):
				draw_sprite_hd(fa.spr, fa.img, fa.x, fa.y, fa.dir * esc, esc, 0, Color8(140, 170, 255), 0.35 * fa.vida / fa.vmax)
				continue
			draw_sprite_hd(Spr.spr_player_agaichar, 0, fa.x + lengthdir_x(hf, 270 + ga), fa.y - hf + lengthdir_y(hf, 270 + ga), fa.dir * esc, esc * 0.86, ga, Color8(140, 170, 255), 0.35 * fa.vida / fa.vmax)
	if rolando:
		var p := clampf(rolar_t / ROLAR_DURACAO, 0, 1)
		var sq := 1 - 0.16 * sin(PI * p)
		var k := hd_escala(sprite_index)
		var hh := sprite_index.h / k * esc * 0.5 * sq
		var cy0 := y - hh
		var ang := rolar_angulo(p, rolar_dir)
		var cr := Color8(200, 215, 255) if jogador_intangivel() else c_white
		draw_sprite_hd(sprite_index, 0, x + lengthdir_x(hh, 270 + ang), cy0 + lengthdir_y(hh, 270 + ang), facing * esc * (1 + 0.06 * sin(PI * p)), esc * sq, ang, cr, image_alpha)
	else:
		draw_sprite_hd(sprite_index, image_index, x, y, facing * esc, esc, 0, cor, image_alpha)
	# esquiva perfeita: brilho azul
	if esquiva_fx > 0:
		gpu_set_blendmode(bm_add)
		draw_set_alpha(esquiva_fx / 18.0 * 0.7)
		draw_set_color(Color8(120, 170, 255))
		draw_circle(x, y - 30, 20 + (18 - esquiva_fx) * 2, true)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# APARAR: brilho azul
	if aparar_fx > 0:
		gpu_set_blendmode(bm_add)
		draw_sprite_hd(sprite_index, image_index, x, y, facing * esc, esc, 0, Color8(140, 200, 255), clampf(aparar_fx / 24.0, 0, 1) * 0.8)
		gpu_set_blendmode(bm_normal)
	# brilho da espada antes dos finalizadores
	if brilho_golpe > 0:
		gpu_set_blendmode(bm_add)
		draw_sprite_hd(sprite_index, image_index, x, y, facing * esc, esc, 0, Color8(255, 170, 120), clampf(brilho_golpe / 14.0, 0, 1) * 0.55)
		gpu_set_blendmode(bm_normal)
	# ===== RASTRO DA ESPADA =====
	if rastros.size() > 0:
		gpu_set_blendmode(bm_add)
		for rs in rastros:
			var p: float = 1 - rs.vida / rs.vmax
			var a: float = (1 - p) * (1.0 if rs.forte else 0.8)
			var cx: float = rs.x + rs.dir * 8
			var cy: float = rs.y - rs.h
			var seg := 14
			var fim: float = lerpf(rs.a1, rs.a2, minf(1, 0.35 + p * 1.6))
			# v1.14: aura de magia carmesim, larga, por fora de tudo
			draw_primitive_begin(pr_trianglestrip)
			for s in seg + 1:
				var tt := float(s) / seg
				var ang: float = lerpf(rs.a1, fim, tt)
				var angw: float = ang if rs.dir == 1 else 180 - ang
				var lm: float = (16 + 22 * tt) * (1.3 if rs.forte else 1.0)
				draw_vertex_color(cx + lengthdir_x(rs.r + 10, angw), cy + lengthdir_y(rs.r + 10, angw), Color8(200, 30, 90), 0.0)
				draw_vertex_color(cx + lengthdir_x(rs.r - lm, angw), cy + lengthdir_y(rs.r - lm, angw), Color8(200, 30, 90), a * tt * 0.22)
			draw_primitive_end()
			# brilho largo e suave por fora do arco
			draw_primitive_begin(pr_trianglestrip)
			for s in seg + 1:
				var tt := float(s) / seg
				var ang: float = lerpf(rs.a1, fim, tt)
				var angw: float = ang if rs.dir == 1 else 180 - ang
				var larg: float = (8 + 16 * tt) * (1.4 if rs.forte else 1.0)
				draw_vertex_color(cx + lengthdir_x(rs.r + 4, angw), cy + lengthdir_y(rs.r + 4, angw), rs.cor, a * tt * 0.0)
				draw_vertex_color(cx + lengthdir_x(rs.r - larg, angw), cy + lengthdir_y(rs.r - larg, angw), rs.cor, a * tt * 0.28)
			draw_primitive_end()
			draw_primitive_begin(pr_trianglestrip)
			for s in seg + 1:
				var tt := float(s) / seg
				var ang: float = lerpf(rs.a1, fim, tt)
				var angw: float = ang if rs.dir == 1 else 180 - ang
				var espx: float = (3 + 10 * tt) * (1.4 if rs.forte else 1.0)
				var ext: float = rs.r
				var inte: float = rs.r - espx
				draw_vertex_color(cx + lengthdir_x(ext, angw), cy + lengthdir_y(ext, angw), rs.cor, a * tt)
				draw_vertex_color(cx + lengthdir_x(inte, angw), cy + lengthdir_y(inte, angw), c_white, a * tt * 0.5)
			draw_primitive_end()
			# fio de luz branco na borda cortante
			draw_primitive_begin(pr_trianglestrip)
			for s in seg + 1:
				var tt := float(s) / seg
				var ang: float = lerpf(rs.a1, fim, tt)
				var angw: float = ang if rs.dir == 1 else 180 - ang
				draw_vertex_color(cx + lengthdir_x(rs.r + 0.5, angw), cy + lengthdir_y(rs.r + 0.5, angw), c_white, a * tt * 0.9)
				draw_vertex_color(cx + lengthdir_x(rs.r - 1.6 * tt - 0.4, angw), cy + lengthdir_y(rs.r - 1.6 * tt - 0.4, angw), c_white, a * tt * 0.9)
			draw_primitive_end()
		gpu_set_blendmode(bm_normal)
	# v1.17: RASTRO DE FOGO: o caminho que a lâmina percorreu, em chamas
	if fogo_rastro.size() > 1 or not fogo_chamas.is_empty():
		var est := V117.espada_estilo_atual()
		V117.fogo_rastro_desenhar(fogo_rastro, est)
		V117.fogo_chamas_desenhar(fogo_chamas, est)
	# v1.14: faíscas douradas (estrelinhas) e brasas da maldição soltas pelo corte
	if faiscas_espada.size() > 0:
		gpu_set_blendmode(bm_add)
		for fs in faiscas_espada:
			var fa := clampf(fs.vida / fs.vmax, 0, 1)
			if fs.brasa:
				draw_set_color(Color8(255, 90, 40))
				draw_set_alpha(fa * 0.9)
				draw_rectangle(fs.x - 0.8, fs.y - 0.8, fs.x + 0.8, fs.y + 0.8, false)
				draw_set_alpha(fa * 0.25)
				draw_circle(fs.x, fs.y, 2.6, false)
			else:
				var tam := 1.2 + 2.2 * fa
				draw_set_color(Color8(255, 226, 150))
				draw_set_alpha(fa)
				draw_line(fs.x - tam, fs.y, fs.x + tam, fs.y)
				draw_line(fs.x, fs.y - tam, fs.x, fs.y + tam)
				draw_set_color(c_white)
				draw_set_alpha(fa * 0.3)
				draw_circle(fs.x, fs.y, 1.8, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)	# ===== DEFESA MÁGICA =====
	if bloqueando or defesa_fx > 0:
		var cyd := (bbox_top + bbox_bottom) / 2.0
		var sx := x + facing * 18 * escala
		gpu_set_blendmode(bm_add)
		if janela_aparar > 0:
			draw_set_alpha(0.35 * janela_aparar / APARAR_JANELA)
			draw_set_color(Color8(190, 230, 255))
			draw_ellipse(sx - 16, cyd - 40, sx + 16, cyd + 40, false)
		if bloqueando:
			draw_set_alpha(0.12 + 0.05 * sin(t / 70.0))
			draw_set_color(Color8(90, 160, 255))
			draw_ellipse(sx - 14, cyd - 38, sx + 14, cyd + 38, false)
		if defesa_fx > 0:
			var o := 1 - defesa_fx / 16.0
			draw_set_alpha(1 - o)
			draw_set_color(Color8(170, 220, 255))
			draw_ellipse(sx - 10 - 18 * o, cyd - 34 - 14 * o, sx + 10 + 18 * o, cyd + 34 + 14 * o, true)
			draw_ellipse(sx - 8 - 14 * o, cyd - 30 - 10 * o, sx + 8 + 14 * o, cyd + 30 + 10 * o, true)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# ===== ONDAS DO ESPECIAL 1 =====
	if ondas.size() > 0:
		gpu_set_blendmode(bm_add)
		for on in ondas:
			var aa := clampf(on.vida / on.vmax, 0, 1)
			var rr: float = on.raio
			var ocx: float = on.x0 + on.dir * (on.dist - rr)
			var ocy: float = y + (on.y_topo + on.y_base) / 2.0
			var ang0 := 0.0 if on.dir == 1 else 180.0
			draw_primitive_begin(pr_trianglestrip)
			for k2 in range(-6, 7):
				var ang2 := ang0 + k2 * 12
				var t2 := 1 - absf(k2) / 6.0
				var esp2 := 3 + 11 * t2
				draw_vertex_color(ocx + lengthdir_x(rr, ang2), ocy + lengthdir_y(rr * 1.25, ang2), Color8(255, 40, 40), aa * (0.25 + 0.75 * t2))
				draw_vertex_color(ocx + lengthdir_x(rr - esp2, ang2), ocy + lengthdir_y((rr - esp2) * 1.25, ang2), Color8(255, 220, 210), aa * 0.9 * t2)
			draw_primitive_end()
		gpu_set_blendmode(bm_normal)
	# ===== TEIA DA MULHER-ARANHA =====
	if enredado > 0:
		var ea := clampf(enredado / 20.0, 0, 1) * 0.85
		var tr := randf_range(-1.5, 1.5) if enredado_fx > 0 else 0.0
		var ey1 := bbox_top + 8
		var ey2 := bbox_bottom - 4
		gpu_set_texfilter(true)
		draw_set_alpha(ea)
		draw_set_color(Color8(235, 235, 240))
		for wl in 5:
			var wy := lerpf(ey1, ey2, wl / 4.0)
			draw_line(x - 15 + tr, wy - 4, x + 15 + tr, wy + 4)
			draw_line(x - 15 + tr, wy + 4, x + 15 + tr, wy - 4)
		draw_line(x - 13 + tr, ey1, x - 11 + tr, ey2)
		draw_line(x + 13 + tr, ey1, x + 11 + tr, ey2)
		draw_set_alpha(1)
		var ba := 0.7 + 0.3 * sin(t / 60.0)
		txt(x, bbox_top - 14, "SOLTE-SE!", FONTE.MINI, Color8(235, 235, 255), ba, fa_center, fa_bottom, 0.55)
		draw_set_alpha(0.8)
		draw_set_color(c_black)
		draw_rectangle(x - 16, bbox_top - 10, x + 16, bbox_top - 7, false)
		draw_set_color(Color8(235, 235, 240))
		draw_rectangle(x - 16, bbox_top - 10, x - 16 + 32 * clampf(enredado / maxf(1, enredado_max), 0, 1), bbox_top - 7, false)
		draw_set_alpha(1)
		gpu_set_texfilter(false)
	# ===== DEPURAÇÃO (F1) =====
	if G.debug_hitbox:
		draw_set_alpha(0.9)
		draw_set_color(c_lime)
		draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true)
		draw_line(x - 4, y, x + 4, y)
		if debug_golpe.size() > 4:
			draw_set_color(c_yellow)
			draw_rectangle(debug_golpe[0], debug_golpe[1], debug_golpe[2], debug_golpe[3], true)
		for w in ondas:
			var wx1: float = w.x0 + w.dir * (w.dist - 20)
			var wx2: float = w.x0 + w.dir * (w.dist + 10)
			draw_set_color(c_orange)
			draw_rectangle(minf(wx1, wx2), y + w.y_topo, maxf(wx1, wx2), y + w.y_base, true)
		if golpe != null:
			txt(x, bbox_top - 6, golpe.nome + "  q" + str(golpe.seq[golpe_i].q) + "  [" + cadeia + "]", FONTE.MINI, c_yellow, 1, fa_center, fa_bottom, 0.45)
		draw_set_alpha(1)
	desenho_resetar()


# =====================================================================
#  HUD (interface com 720 de altura; a largura acompanha a proporção)
# =====================================================================
# objetivo mostrado no topo da tela
func objetivo_texto(fase: int) -> String:
	var objt := fase_objetivo(fase)
	if fase == 1:
		var boss = instance_find("obj_boss_01", 0)
		var mini = instance_find("obj_mini_boss", 0)
		if boss == null:
			objt = "O caminho está livre: siga para o castelo  »"
		elif boss.acordado or boss.estado_ia == "despertar":
			objt = "Derrote a " + boss.nome_boss
		elif mini != null and mini.acordado and not mini.morrendo:
			objt = "Derrote " + mini.nome_boss
		# v1.14: o portão trancado e a chave no baú do forte
		elif G.arena_chave:
			objt = "Derrote os guardiões do baú"
		elif G.portao_visto:
			var portao_o = instance_find("obj_portao_trancado", 0)
			if portao_o != null and portao_o.estado == "trancado":
				objt = "Volte ao portão com a chave  »" if G.chave_portao else "Ache a chave do portão: suba ao forte de madeira"
	if fase == 2:
		var vivos := 0
		for e in todos("obj_inimigo_base"):
			if not e.morrendo:
				vivos += 1
		objt = "INIMIGOS RESTANTES: " + str(vivos)
	return objt


# algum chefe com a barra na tela: a faixa do objetivo dá lugar à barra dele
func hud_chefe_alfa() -> float:
	var a := 0.0
	var boss = instance_find("obj_boss_01", 0)
	if boss != null:
		a = maxf(a, boss.hud_alpha)
	var mini = instance_find("obj_mini_boss", 0)
	if mini != null and not mini.morrendo:
		a = maxf(a, mini.hud_alpha)
	return clampf(a, 0, 1)


# a bússola aponta para o chefe acordado, para o inimigo mais perto (fase 2) ou para o leste
func objetivo_angulo(fase: int) -> float:
	var alvo = null
	if fase == 1:
		var boss = instance_find("obj_boss_01", 0)
		var mini = instance_find("obj_mini_boss", 0)
		if boss != null and (boss.acordado or boss.estado_ia == "despertar"):
			alvo = boss
		elif mini != null and mini.acordado and not mini.morrendo:
			alvo = mini
	elif fase == 2:
		var dm := INF
		for e in todos("obj_inimigo_base"):
			if not e.morrendo and absf(e.x - x) < dm:
				dm = absf(e.x - x)
				alvo = e
	if alvo != null and alvo.x < x - 8:
		return PI
	return 0.0


# o HUD só é redesenhado quando muda (no celular cada milissegundo conta);
# com qualquer animação na tela ele é redesenhado todo quadro
func gui_chave():
	if absf(vida_atraso - vida) > 0.05 or especial_pronto_fx > 0 or furia_cheia_fx > 0 or furia >= 100 or furia_modo \
			or G.orbs_fx > 0 or G.essencia_fx > 0 or bloqueado_aviso > 0 or G.combo >= 2 or combo_nome_t > 0 \
			or barreira_aviso > 0 or G.last_hit_flash > 0 or (cadeia != "" and (cadeia_janela > 0 or golpe != null)) \
			or (vida <= vida_max * 0.3 and vida > 0) or alvo_interacao != null or objetivo_t > 0:
		return null          # (perto do baú o botão ABRIR pulsa; a faixa do objetivo some aos poucos)
	var toque := G.usando_toque and not usando_controle()
	var prox_n := G.espada_nivel + 1
	if not toque and prox_n <= ESPADA_NIVEL_MAX and G.orbs >= espada_custo(prox_n):
		return null          # a dica de evoluir pisca
	var ca := hud_chefe_alfa()
	if ca > 0.0 and ca < 1.0:
		return null          # a barra do chefe está entrando ou saindo
	var fase := fase_numero(G.room)
	var toque_vis: bool = G.toque != null and G.toque.calcular_modo() == "jogo"
	return [vida, vida_max, int(especial_carga / ESPECIAL_SEGUNDOS * 300), furia, G.orbs, G.espada_nivel, G.essencia,
		G.nome_guerreiro, toque_vis, toque, G.usando_pad, G.pad_slot, G.teclas, G.botoes,
		objetivo_texto(fase) if fase > 0 else "", objetivo_angulo(fase), ca, G.room, agachado]


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var ouro := Color8(255, 210, 90)
	var ouro2 := Color8(176, 141, 70)
	var fase := fase_numero(G.room)
	var t := current_time()
	var toque_vis: bool = G.toque != null and G.toque.calcular_modo() == "jogo"
	var toque := G.usando_toque and not usando_controle()
	# ===== MOLDURA GÓTICA (estilo Castlevania): placa, brasão e sub-arma =====
	var bx := 14.0
	var by := 10.0
	var bw := 96.0
	var x0 := bx + bw + 8
	hud_placa(bx + bw - 14, by + 2, x0 + 340, by + 94, 0.95)
	hud_brasao(bx, by, bw, G.espada_nivel)
	var nome := G.nome_guerreiro.to_upper()
	if txt_largura(nome, FONTE.PEQUENA) > 200:
		nome = NOME_CURTO.to_upper()
	txt_sombra(x0 + 2, by + 3, nome, FONTE.PEQUENA, UI.MARFIM, 1, fa_left, fa_top)
	# ===== VIDA =====
	vida_atraso = lerp_dt(vida_atraso, vida, 0.05)
	var pct := clampf(vida / vida_max, 0, 1)
	var hy := by + 32
	var c1 := Color8(255, 96, 72) if pct <= 0.3 else Color8(232, 58, 50)
	hud_barra(x0, hy, 290, 20, pct, vida_atraso / vida_max, c1, Color8(112, 10, 16), 1.0, false, 16)
	txt_sombra(x0 + 272, hy + 10, str(int(ceil(vida))) + " / " + str(int(vida_max)), FONTE.MINI, Color8(255, 242, 228), 1, fa_right, fa_middle, 0.95)
	# ===== MAGIA (marcas no custo de cada especial liberado) =====
	var my := hy + 28
	var mw := 252.0
	var pct_es := clampf(especial_carga / ESPECIAL_SEGUNDOS, 0, 1)
	hud_barra(x0, my, mw, 12, pct_es, 0, Color8(120, 190, 255), Color8(24, 54, 160))
	for am in [ACAO.ESPECIAL_3, ACAO.ESPECIAL, ACAO.ESPECIAL_2]:
		if not especial_liberado(am):
			continue
		var mx := x0 + mw * especial_custo(am)
		draw_set_alpha(0.95)
		draw_set_color(UI.OURO_CLARO if pct_es >= especial_custo(am) else Color8(70, 56, 50))
		draw_rectangle(mx - 1, my - 3, mx, my + 14, false)
	txt_sombra(x0 + mw + 14, my + 6, "MAGIA", FONTE.MINI, Color8(160, 204, 255), 1, fa_left, fa_middle, 0.75)
	if especial_pronto_fx > 0:
		gpu_set_blendmode(bm_add)
		draw_set_alpha(clampf(especial_pronto_fx / 50.0, 0, 1) * 0.45)
		draw_set_color(Color8(120, 170, 255))
		draw_rectangle(x0 - 4, my - 4, x0 + mw + 8, my + 16, false)
		gpu_set_blendmode(bm_normal)
	# ===== FÚRIA =====
	var fy := my + 20
	var fw := 214.0
	var pf := clampf(furia / 100.0, 0, 1)
	var f1 := Color8(255, 140, 48)
	if furia_modo:
		f1 = merge_color(Color8(255, 40, 20), Color8(255, 210, 160), 0.5 + 0.5 * sin(t / 50.0))
	elif pf >= 1:
		f1 = merge_color(Color8(255, 110, 40), c_white, 0.3 + 0.3 * sin(t / 70.0))
	hud_barra(x0, fy, fw, 8, pf, 0, f1, Color8(140, 24, 10))
	if furia_modo or pf >= 1:
		var fx := x0 + fw + 14
		var ftxt := "MODO FÚRIA" if furia_modo else "IRA DE VALLACK!"
		if not furia_modo and not toque:
			fx += desenhar_icone_acao(fx, fy + 4, ACAO.FURIA, 16, 0.8 + 0.2 * sin(t / 90.0)) + 6
		txt_sombra(fx, fy + 4, ftxt, FONTE.MINI, merge_color(Color8(255, 90, 50), c_white, 0.4 + 0.4 * sin(t / 80.0)), 1, fa_left, fa_middle, 0.9)
	else:
		txt_sombra(x0 + fw + 14, fy + 4, "FÚRIA", FONTE.MINI, Color8(255, 160, 100), 1, fa_left, fa_middle, 0.75)
	if furia_cheia_fx > 0:
		gpu_set_blendmode(bm_add)
		draw_set_alpha(furia_cheia_fx / 60.0 * 0.6)
		draw_set_color(Color8(255, 60, 30))
		draw_rectangle(x0 - 4, fy - 4, x0 + fw + 8, fy + 12, false)
		gpu_set_blendmode(bm_normal)
	# ===== SUB-ARMA: quadro ao lado da placa (agachado mostra a Chama de Sylla) =====
	var sub_pode := G.essencia >= subarma_custo(agachado)
	var qx := x0 + 352
	var qy := by + 4
	hud_quadro_subarma(qx, qy, 62, 1 if agachado else 0, sub_pode, G.essencia, G.essencia_fx)
	txt_sombra(qx + 6, qy + 10, str(subarma_custo(agachado)), FONTE.MINI, Color8(165, 212, 255), 0.9, fa_left, fa_middle, 0.8)
	if not toque:
		var wk := icone_acao_largura(ACAO.INTERAGIR, 16)
		desenhar_icone_acao(qx + 62 - wk + 4, qy + 62 - 4, ACAO.INTERAGIR, 16, 1.0 if sub_pode else 0.45)
	# ===== ORBS (pagam a evolução da espada), embaixo da placa =====
	var cy := by + 114
	var oe := 1 + 0.25 * clampf(G.orbs_fx / 20.0, 0, 1)
	var orbs_txt := str(int(G.orbs))
	var w_cont := 44.0 + txt_largura(orbs_txt, FONTE.PEQUENA, 0.85)
	hud_forma(hud_barra_pts(x0 - 4, cy - 12, w_cont, 24), cy - 12, 24, Color8(10, 6, 7), Color8(10, 6, 7), 0.6)
	hud_orbe(x0 + 8, cy, 7 * oe)
	txt_sombra(x0 + 20, cy, orbs_txt, FONTE.PEQUENA, Color8(255, 150, 120), 1, fa_left, fa_middle, 0.85 * oe)
	# evoluir a espada: dica no teclado / controle (no toque o botão ARMAS ganha um ponto vermelho)
	var prox_n := G.espada_nivel + 1
	if not toque and prox_n <= ESPADA_NIVEL_MAX and G.orbs >= espada_custo(prox_n):
		txt_sombra(x0 + w_cont + 10, cy, botao_menu_armas() + ": EVOLUIR A ESPADA", FONTE.MINI, ouro, 0.6 + 0.4 * sin(t / 200.0), fa_left, fa_middle, 0.9)
	# ===== v1.14: a CHAVE DO PORTÃO, quando Twilight está com ela =====
	var portao = instance_find("obj_portao_trancado", 0)
	if G.chave_portao and portao != null and portao.estado == "trancado":
		var ky := cy + 30
		hud_forma(hud_barra_pts(x0 - 4, ky - 12, 96, 24), ky - 12, 24, Color8(10, 6, 7), Color8(10, 6, 7), 0.6)
		desenhar_chave(x0 + 8, ky - 1, 0.95, 1)
		txt_sombra(x0 + 22, ky, "CHAVE", FONTE.MINI, Color8(250, 210, 120), 0.8 + 0.2 * sin(t / 180.0), fa_left, fa_middle, 0.9)
	# ===== AVISO: especial bloqueado / sem magia / sem fúria =====
	if bloqueado_aviso > 0 and bloqueado_txt != "":
		var ba2 := clampf(bloqueado_aviso / 15.0, 0, 1)
		txt_sombra(gw / 2.0, gh * 0.62, bloqueado_txt, FONTE.PEQUENA, Color8(255, 140, 110), ba2, fa_center, fa_middle, minf(1, (gw - 60) / maxf(1, txt_largura(bloqueado_txt, FONTE.PEQUENA))))
	# ===== COMBO (à direita; abaixo de PAUSA / ARMAS no toque) =====
	var cy0 := 104.0 if toque_vis else 20.0
	if G.combo >= 2:
		var pulo := 1 + 0.12 * clampf(G.combo_tempo - 100, 0, 20) / 20.0
		txt_sombra(gw - 26, cy0, str(G.combo) + " GOLPES", FONTE.MEDIA, Color8(255, 132, 72), 1, fa_right, fa_top, 0.85 * pulo)
	if cadeia != "" and (cadeia_janela > 0 or golpe != null):
		var cxr := gw - 26
		for ci in range(cadeia.length(), 0, -1):
			var ac := combo_acao_da_letra(cadeia[ci - 1])
			var wci := icone_acao_largura(ac, 24)
			cxr -= wci
			desenhar_icone_acao(cxr, cy0 + 50, ac, 24, 0.95)
			cxr -= 6
		txt_sombra(cxr - 4, cy0 + 50, "COMBO", FONTE.MINI, ouro2, 0.9, fa_right, fa_middle)
	# ===== NOME DO COMBO =====
	if combo_nome_t > 0 and combo_nome != "":
		var cn := clampf(combo_nome_t / 20.0, 0, 1) * clampf((110 - combo_nome_t) / 8.0, 0, 1)
		var ce := 1 + 0.25 * clampf((combo_nome_t - 95) / 15.0, 0, 1)
		gpu_set_blendmode(bm_add)
		txt(gw / 2.0, gh * 0.27, combo_nome, FONTE.MEDIA, Color8(160, 10, 10), cn * 0.8, fa_center, fa_middle, ce * 1.08)
		gpu_set_blendmode(bm_normal)
		txt_sombra(gw / 2.0, gh * 0.27, combo_nome, FONTE.MEDIA, Color8(255, 205, 120), cn, fa_center, fa_middle, ce)
	# ===== OBJETIVO: faixa com bússola no topo; aparece quando o objetivo muda
	# (7 s) e some, para a luta ficar limpa como nos Castlevania =====
	var ca := hud_chefe_alfa()
	var objt := objetivo_texto(fase) if fase > 0 else ""
	if objt != objetivo_txt:
		# v1.16: objetivo novo toca a mensagem importante (a contagem de inimigos
		# da fase 2 só atualiza a faixa, sem som a cada inimigo)
		if objt != "" and (objetivo_txt == "" or fase != 2):
			som_mensagem()
		objetivo_txt = objt
		objetivo_t = 420
	var oa := (1.0 - ca) * clampf(objetivo_t / 40.0, 0, 1)
	if fase > 0 and oa > 0.01:
		var cap := "CAPÍTULO " + ("I" if fase == 1 else "II") + "  ·  " + fase_nome(fase)
		var esq := 556.0             # depois da moldura e do quadro da sub-arma
		var dir := gw - 200.0
		var wt := maxf(txt_largura(cap, FONTE.MINI), txt_largura(objt, FONTE.PEQUENA))
		var w := minf(dir - esq, wt + 120)
		var e_txt := minf(1.0, (w - 120) / maxf(1, wt))
		var cxb := clampf(gw / 2.0, esq + w / 2.0, dir - w / 2.0)
		var y1 := 8.0
		var y2 := 64.0
		hud_faixa(cxb - w / 2.0, y1, cxb + w / 2.0, y2, oa)
		var bcx := cxb - w / 2.0 + 44
		hud_bussola(bcx, (y1 + y2) / 2.0, 22, objetivo_angulo(fase), oa)
		var tx := (bcx + 28 + cxb + w / 2.0 - 24) / 2.0
		txt(tx, y1 + 17, cap, FONTE.MINI, UI.OURO, oa, fa_center, fa_middle, e_txt)
		txt_sombra(tx, y1 + 38, objt, FONTE.PEQUENA, UI.MARFIM, oa, fa_center, fa_middle, e_txt)
	# ===== BARREIRA DO GUARDIÃO =====
	if barreira_aviso > 0:
		var ba := clampf(barreira_aviso / 20.0, 0, 1)
		txt_sombra(gw / 2.0, gh * 0.42, "Uma barreira amaldiçoada bloqueia o caminho.", FONTE.PEQUENA, Color8(255, 120, 100), ba, fa_center, fa_middle)
		txt_sombra(gw / 2.0, gh * 0.42 + 28, "Derrote o guardião para seguir em frente.", FONTE.MINI, c_white, ba, fa_center, fa_middle)
	# ===== BOTÃO ABRIR: aparece sobre o baú quando Twilight está perto =====
	# (no toque o botão INTERAGIR também vira um ABRIR grande pulsando)
	if alvo_interacao != null and G.existe(alvo_interacao) and alvo_interacao.obj == "obj_bau":
		var ax: float = (alvo_interacao.x - G.view_x) * gw / G.view_w
		var ay: float = (alvo_interacao.bbox_top - G.view_y) * gh / G.view_h
		hud_botao_contexto(ax, ay - 18, "ABRIR", not toque)
	# ===== POUCA VIDA: vinheta vermelha pulsando =====
	if pct <= 0.3 and vida > 0:
		var pv := 0.35 + 0.25 * (0.5 + 0.5 * sin(t / 150.0))
		desenhar_vinheta(gw, gh, pv, Color8(170, 0, 0))
	# ===== FLASH DE IMPACTO =====
	if G.last_hit_flash > 0:
		draw_set_alpha(minf(0.2, G.last_hit_flash / 50.0))  # v1.18: mais fraco (em grupo a tela piscava branca sem parar)
		draw_set_color(c_white)
		draw_rectangle(0, 0, gw, gh, false)
		draw_set_alpha(1)
	desenho_resetar()