class_name ObjInimigoBase
extends ObjEntidade
# =====================================================================
#  obj_inimigo_base — pai de todos os inimigos (01, 02, novos e chefes)
#  * herda a física/colisão do obj_entidade
#  * os golpes do jogador procuram por este objeto
#  * aqui ficam as funções de scr_dano / scr_inimigos_novos / scr_v112
#    que rodam "dentro" do inimigo (dano, atordoamento, finalizador,
#    escudo, portal, morte, evaporação, HUD e elites)
# =====================================================================

var ativo := true
var morrendo := false
var morte_fim := false
var morte_tempo := 0.0
var morte_t := 0.0
var evaporar := 0.0
var evaporar_fx := 0.0
var evaporar_tam := 0.0
var eh_boss := false
var invocado := false

var vida := 1.0
var vida_max := 1.0
var vida_atraso := 1.0
var tempo_invencivel := 0.0
var barra_tempo := 0.0
var flash_dano := 0.0
var empurrao := 0.0
var dir := -1.0
var virar_t := 0.0          # v1.14: reação antes de virar (inimigo_virar)
var limite_x1 := -1.0       # v1.14: área em que o inimigo fica (arena da chave no alto do forte)
var limite_x2 := -1.0

var atordoado := 0.0
var atordoado_anim := 0.0
var atordoado_acumulado := 0.0
var imune_atordoar := 0.0
var libertou_fx := 0.0
var estado_ia := "parado"
var golpe_dado := false
var som_golpe_tocou := false
var recarga := 0.0

var finalizavel := false
var executando := false
var finalizado := false
# v1.17: SEQUÊNCIA DE GOLPES (Carrasco e Árvore): só caem por ela
var usa_qte := false
var qte_pronto := false
var em_qte := false
var qte_vencido := false
var pode_lancar := true
var aparado_t := 0.0
var resiste_atordoar := false
var escudo_vida := 0
var escudo_max := 0
var escudo_quebrado := false
var escudo_quebrado_t := 0.0
var escudo_fx := 0.0
var grav_ia := 0.4
var tremor := 0.0

var nivel := 1
var ultimo_golpe = null
var estado_ao_surgir := ""

var elite := false
var petrif := 0
var petrif_t := 0.0
var petrificado := false
var suspenso_t := 0.0
var grav_ia_base := 0.4

# portal de magia (inimigo_portal_iniciar)
var surgir_fase := "ativo"
var surgir_t := 0.0
var surgir_agora := false
var surgir_atraso := 0.0
var distancia_surgir := 420.0
var portal_raio := 0.0

# usados por vários inimigos (no GameMaker eram criados em cada um)
var alerta_fx := 0.0
var alertado := false
var pulando := false
var spr_morrer: GMSprite = null
var dano_ataque := 1.0
var escala_vis := 1.0
var topo_vis := 72.0
var cor_base := Color(1, 1, 1)
var usa_hud_nivel := false


func ev_create() -> void:
	super()
	globais_iniciar()


# cada inimigo redefine como reage a um golpe
func reagir_dano(_dano: float, _dir: float, _forca: float) -> void:
	pass


# v1.17: o que o chefe faz quando o jogador erra a sequência de golpes
func qte_falhou() -> void:
	pass


# golpes que não ferem (ex.: estátua de pedra). true = o golpe foi segurado
func bloquear_golpe(_golpe, _origem_x: float) -> bool:
	return false


# v1.14: VIRAR DE LADO com reação. O inimigo só vira com o alvo a mais de 8 px
# do outro lado e depois de um instante (antes ele virava no mesmo quadro em
# que o herói passava por ele e o corpo piscava de um lado para o outro).
# ja: vira na hora (ataque, pulo), mas ainda com a margem de 8 px.
func inimigo_virar(dx: float, ja := false) -> void:
	if absf(dx) <= 8 or signf(dx) == dir:
		virar_t = 0
		return
	virar_t += G.dt
	if ja or virar_t >= 7:
		dir = signf(dx)
		virar_t = 0


func trocar_sprite(s: GMSprite, v: float) -> void:
	if sprite_index != s:
		sprite_index = s
		image_index = 0
	image_speed = v


# =====================================================================
#  End Step (v1.12): petrificação, empurrão limitado e combo aéreo
# =====================================================================
func ev_step_end() -> void:
	var dt := G.dt
	if petrif_t > 0:
		petrif_t -= dt
		if petrif_t <= 0:
			petrif = 0
			petrificado = false
	if petrificado and atordoado <= 0:
		petrificado = false
		petrif = 0
	if petrif > 0 and not morrendo:
		velh *= (1 - 0.22 * petrif)
	empurrao = clampf(empurrao, -2.6, 2.6)
	if suspenso_t > 0:
		suspenso_t -= dt
		if suspenso_t <= 0 or morrendo:
			suspenso_t = 0
			grav_ia = grav_ia_base
	super()
	if limite_x2 > limite_x1:
		x = clampf(x, limite_x1, limite_x2)


# =====================================================================
#  DANO (scr_dano: levar_dano, parte dos inimigos)
# =====================================================================
func levar_dano(dano: float, origem_x = null, _bloqueavel := true, forca := 4.0, _atacante = null, golpe = null) -> void:
	if vida <= 0:
		return
	if origem_x == null:
		origem_x = x
	var d := signf(x - origem_x)
	if d == 0:
		d = 1
	var cy := (bbox_top + bbox_bottom) / 2.0
	if morrendo or not ativo:
		return
	if em_qte:
		return      # v1.17: na sequência de golpes quem tira a vida é a sequência
	if tempo_invencivel > 0:
		return
	# durante o finalizador só o golpe final acerta este inimigo
	if executando and (golpe == null or golpe.chave != "finalizador"):
		return
	# ESCUDO (inimigo 03): segura golpes de frente até a guarda quebrar
	if escudo_vida > 0 and golpe != null:
		var frente: bool = signf(origem_x - x) == dir or origem_x == x
		var quebra_tudo: bool = golpe.especial or golpe.chave == "ira" or golpe.chave == "finalizador"
		if quebra_tudo:
			escudo_quebrar(d)
		elif frente and atordoado <= 0:
			escudo_bater(2 if golpe.pesado else 1, d)
			return
	# DEFESA PRÓPRIA (a estátua em forma de pedra)
	if bloquear_golpe(golpe, origem_x):
		return
	if barra_tempo <= 0:
		vida_atraso = vida
	vida = maxf(0, vida - dano)
	tempo_invencivel = 6
	barra_tempo = 180
	flash_dano = 4 if eh_boss else 8
	G.combo += 1
	G.combo_tempo = 120
	V117.perfil_maximo("maior_combo", G.combo)     # v1.17: conquista TEMPESTADE DE AÇO
	G.hits_total += 1
	G.last_hit_flash = 5
	G.last_hit_damage = dano
	G.camera_impact = maxf(G.camera_impact, 4)
	var f = instance_create_depth(x, cy, -100, "obj_fagulha")
	f.cor = c_white
	ultimo_golpe = golpe
	reagir_dano(dano, d, forca)


# ---------------------------------------------------------------------
# ATORDOAMENTO
# ---------------------------------------------------------------------
func inimigo_atordoar(quadros: float, forcar := false) -> void:
	if morrendo or not ativo or eh_boss:
		return
	if resiste_atordoar and not forcar:
		return
	if imune_atordoar > 0 and not forcar:
		return
	quadros = round(quadros * dif_atordoamento())
	if elite and not forcar:
		quadros = round(quadros * 0.6)
	if atordoado <= 0:
		atordoado_anim = 0
	atordoado = maxf(atordoado, quadros)
	if estado_ia in ["atacar", "atirar", "pular_preparo", "pular_pouso", "investida"]:
		estado_ia = "perseguir"
		golpe_dado = false


# SE o jogador está atacando ENTÃO os inimigos à frente ficam atordoados
func inimigo_regra_atordoamento(p) -> void:
	if not G.existe(p):
		return
	if p.morto or not (p.atacando or p.especial):
		return
	if escudo_vida > 0:
		return
	var frente: float = (x - p.x) * p.facing
	if frente >= -16 and frente <= 72 and absf(y - p.y) <= 70:
		inimigo_atordoar(10)


# Controle do atordoamento a cada quadro. Retorna true enquanto atordoado.
func inimigo_atordoamento_step(dt: float) -> bool:
	if imune_atordoar > 0:
		imune_atordoar -= dt
	if aparado_t > 0:
		aparado_t = maxf(0, aparado_t - dt)
	if atordoado <= 0:
		atordoado_acumulado = maxf(0, atordoado_acumulado - dt * 2)
		return false
	atordoado -= dt
	atordoado_anim += dt
	# v1.17: o Carrasco de joelhos (exausto) espera a sequência de golpes o tempo todo
	if aparado_t <= 0 and estado_ia != "exausto":
		atordoado_acumulado += dt
	if atordoado_acumulado >= 150:
		atordoado = 0
		atordoado_acumulado = 0
		imune_atordoar = 80
		libertou_fx = 20
		recarga = 0
	if atordoado <= 0:
		atordoado = 0
		return false
	return true


# Golpe batendo na defesa mágica: o inimigo é arremessado e fica tonto
func inimigo_ricochete(d: float) -> void:
	if morrendo or not ativo or eh_boss:
		return
	if d == 0:
		d = -dir
	empurrao = d * (2.2 if resiste_atordoar else 3.6)
	velv = minf(velv, -2.2)
	imune_atordoar = 0
	inimigo_atordoar(24)
	flash_dano = 6


# O golpe foi APARADO: atordoado por 2 s e pronto para o finalizador
func inimigo_aparado(d: float) -> void:
	if morrendo or not ativo:
		return
	if eh_boss:
		tremor = 4
		flash_dano = 8
		recarga = maxf(recarga, 60)
		return
	if d == 0:
		d = -dir
	empurrao = d * 1.8
	imune_atordoar = 0
	atordoado_acumulado = 0
	aparado_t = 70 if resiste_atordoar else 120
	inimigo_atordoar(aparado_t, true)
	flash_dano = 8
	golpe_dado = true


# Retorna true enquanto está preso no finalizador (a IA não roda)
func inimigo_finalizador_step() -> bool:
	# v1.17: SEQUÊNCIA DE GOLPES: o chefe fica preso nela e os outros inimigos esperam
	if em_qte or (G.qte_alvo != null and G.qte_alvo != self and G.existe(G.qte_alvo)):
		finalizavel = false
		velh = 0
		empurrao = 0
		return true
	if executando:
		finalizavel = false
		velh = 0
		empurrao = 0
		var p = instance_find("obj_player", 0)
		if p == null or p.golpe == null or p.golpe.chave != "finalizador":
			executando = false
		return executando
	var fraco := vida <= vida_max * (0.25 if resiste_atordoar else 0.34)
	var executavel := not resiste_atordoar and (elite or obj == "obj_porco" or obj == "obj_inimigo_03" or obj == "obj_estatua") and vida <= vida_max * 0.25
	finalizavel = ativo and not morrendo and not eh_boss and ((atordoado > 0 and (aparado_t > 0 or escudo_quebrado_t > 0 or fraco)) or executavel)
	if escudo_quebrado_t > 0:
		escudo_quebrado_t = maxf(0, escudo_quebrado_t - G.dt)
	return false


# Dano do finalizador: derrota os comuns; no mini-boss tira 25% da vida máxima
func inimigo_dano_finalizador() -> float:
	if resiste_atordoar:
		return maxf(1, round(vida_max * 0.25))
	return vida


# ---------------------------------------------------------------------
# ESCUDO (inimigo 03)
# ---------------------------------------------------------------------
func escudo_bater(forca: int, d: float) -> void:
	escudo_vida = maxi(0, escudo_vida - forca)
	escudo_fx = 10
	som("sfx_bloqueio", 0.9)
	impacto(2)
	var f = instance_create_depth(x + dir * 20, y - 40, -100, "obj_fagulha")
	f.cor = Color8(255, 220, 140)
	for p in todos("obj_player"):
		p.empurrao = -p.facing * 1.6
	empurrao = d * 0.8
	recarga = minf(recarga, 14)
	if randf() < 0.2:
		fala_aleatoria(self, falas_escudo(), Color8(70, 60, 30), 1)
	if escudo_vida <= 0:
		escudo_quebrar(d)


func escudo_quebrar(d: float) -> void:
	if escudo_vida <= 0 and escudo_quebrado:
		return
	escudo_vida = 0
	escudo_quebrado = true
	escudo_quebrado_t = 150
	som("sfx_escudo_quebra", 1)
	impacto(6)
	G.camera_impact = maxf(G.camera_impact, 8)
	imune_atordoar = 0
	atordoado_acumulado = 0
	inimigo_atordoar(110, true)
	empurrao = d * 1.6
	for i in 6:
		var f = instance_create_depth(x + dir * 18, y - 40, -100, "obj_fagulha")
		f.cor = choose([Color8(190, 190, 200), Color8(255, 220, 140)])
	var pd = instance_create_depth(x + dir * 18, y - 38, depth - 1, "obj_fx")
	pd.tipo = "escudo_quebrado"
	pd.tam = 1
	pd.dir = dir
	pd.fx_iniciar()


# ---------------------------------------------------------------------
# MORTE: o corpo fica no mapa e solta orbs
# ---------------------------------------------------------------------
func inimigo_morrer(d: float, soltar_orbs := true) -> void:
	if not morrendo:
		G.inimigos_derrotados += 1
		# v1.17: números do PERFIL (conquistas)
		V117.perfil_somar("inimigos")
		if obj == "obj_porco":
			V117.perfil_somar("javalis")
		if soltar_orbs:
			var total: float = 3 if invocado else orbs_do_inimigo(self)
			if finalizado:
				total *= ORBS_FINALIZADOR
			orbs_soltar(x, y - 30, total)
			var ess := essencia_do_inimigo(self)
			if ess > 0:
				essencia_soltar(x, y - 34, ess)
		var sg := sangue_do_inimigo(self)
		if sg > 0:
			sangue_soltar(x, y - 30, sg)
		# GOLPE FATAL: pausa, câmera lenta e o monstro explode em chamas
		var alt := maxf(20.0, bbox_bottom - bbox_top)
		golpe_fatal(x, (bbox_top + bbox_bottom) / 2.0, 1.0 if d == 0 else signf(d), clampf(alt / 64.0, 0.8, 2.4))
		camera_soco(0.07 if inimigos_vivos() > 1 else 0.12)     # v1.20: o último do grupo fecha mais a câmera
	morrendo = true
	pulando = false
	atordoado = 0
	finalizavel = false
	executando = false
	estado_ia = "morrendo"
	velh = d * 1.6
	velv = minf(velv, 0)
	empurrao = 0
	morte_fim = false
	morte_tempo = 0
	morte_t = 0
	evaporar = 0
	sprite_index = spr_morrer
	image_index = 0
	image_speed = 1
	G.camera_impact = maxf(G.camera_impact, 7)
	for i in (2 if G.cfg_qualidade == 0 else 5):
		var f = instance_create_depth(x + randf_range(-14, 14), y - randf_range(14, 50), -100, "obj_fagulha")
		f.cor = Color8(200, 30, 30)


# Corpo no chão: para de deslizar e, 3 s depois da morte, evapora
func inimigo_corpo_step(dt: float) -> void:
	velh = lerp_dt(velh, 0, 0.12)
	if not place_meeting(x, y + 1, "obj_chao"):
		velv += grav_ia * dt
	elif velv > 0:
		velv = 0
	if morte_fim:
		morte_tempo += dt
	if inimigo_evaporar(dt, EVAPORAR_INI, EVAPORAR_FIM):
		instance_destroy()


# Avança a evaporação e solta a fumaça. Retorna true quando o corpo sumiu.
func inimigo_evaporar(dt: float, ini: float, fim: float) -> bool:
	morte_t += dt
	var e := clampf((morte_t - ini) / maxf(1, fim - ini), 0, 1)
	var comecou := evaporar <= 0 and e > 0
	evaporar = e
	if e <= 0:
		return false
	var tam := evaporar_tam if evaporar_tam > 0 else clampf((bbox_bottom - bbox_top) / 62.0, 0.7, 2.5)
	var alt := 62 * tam
	var larg := 34 * tam
	if comecou:
		som_em("maldicao_grande" if tam >= 1.8 else "maldicao_evaporar", x, y, 0.9)
	evaporar_fx -= dt
	if evaporar_fx <= 0:
		# fumaça discreta: poucos sopros (antes 5 / 8 quadros e até 140 na tela poluíam o cenário)
		evaporar_fx = 20 if G.cfg_qualidade == 0 else 13
		# v1.17: o corpo ARDE em chamas (antes: fumaça negra, uma mancha escura na tela)
		var n := 0
		for fx in todos("obj_fx"):
			n += fx.contar("chamas_corpo")
		if n < 36 or randf() < 0.15:
			fx_em("chamas_corpo", x + randf_range(-larg, larg) * 0.5, y - randf() * alt * (1 - 0.35 * e), tam * (0.7 + 0.5 * e))
	if morte_t >= fim:
		fx_em("chamas_estouro", x, y - alt * 0.45, tam)
		return true
	return false


# Desenha o corpo; morto, ele escurece, brilha roxo nas bordas e se desfaz
func inimigo_corpo_desenhar(s: GMSprite, img: float, px: float, py: float, xs: float, ys: float, rot: float, cor: Color, alfa: float) -> void:
	if not morrendo or evaporar <= 0:
		# v1.12: ELITE: brilho vermelho em volta do corpo
		if elite and not morrendo:
			gpu_set_blendmode(bm_add)
			gpu_set_fog(true, Color8(200, 30, 20))
			var ea := alfa * (0.22 + 0.08 * sin(current_time() / 160.0))
			draw_sprite_hd(s, img, px - 2, py, xs, ys, rot, c_white, ea)
			draw_sprite_hd(s, img, px + 2, py, xs, ys, rot, c_white, ea)
			gpu_set_fog(false, c_white)
			gpu_set_blendmode(bm_normal)
		# v1.12: pode ser executado: contorno vermelho piscando
		if finalizavel and not morrendo:
			var pa := alfa * (0.55 + 0.45 * sin(current_time() / 70.0))
			gpu_set_fog(true, Color8(255, 40, 30))
			draw_sprite_hd(s, img, px - 3, py, xs, ys, rot, c_white, pa)
			draw_sprite_hd(s, img, px + 3, py, xs, ys, rot, c_white, pa)
			draw_sprite_hd(s, img, px, py - 3, xs, ys, rot, c_white, pa)
			draw_sprite_hd(s, img, px, py + 2, xs, ys, rot, c_white, pa)
			gpu_set_fog(false, c_white)
		draw_sprite_hd(s, img, px, py, xs, ys, rot, cor, alfa)
		# v1.12: PETRIFICAÇÃO (Modo Fúria): o corpo vai virando pedra
		if petrif > 0 and not morrendo:
			gpu_set_fog(true, Color8(130, 128, 120))
			draw_sprite_hd(s, img, px, py, xs, ys, rot, c_white, alfa * (0.85 if petrificado else 0.22 * petrif))
			gpu_set_fog(false, c_white)
		return
	var e := evaporar
	var sai := clampf((e - 0.4) / 0.6, 0, 1)
	var a := alfa * (1 - sai * (2 - sai))
	if a <= 0.01:
		return
	var k := maxf(1, evaporar_tam)
	var tr := randf_range(-1.2, 1.2) * e * k
	var xx := px + tr
	var yy := py - 14 * k * sai
	var sx := xs * (1 - 0.3 * sai)
	var sy := ys * (1 + 0.22 * sai)
	# v1.17: o corpo ARDE em brasa (antes virava uma silhueta negra: a "mancha
	# preta" na tela). Escurece só um pouco (carbonizando) e brilha em laranja.
	draw_sprite_hd(s, img, xx, yy, sx, sy, rot, merge_color(cor, Color8(120, 46, 30), minf(1, e * 1.6)), a)
	var g := a * (0.3 + 0.5 * sin(PI * minf(1, e * 1.2)))
	if g > 0.02:
		gpu_set_blendmode(bm_add)
		gpu_set_fog(true, merge_color(Color8(255, 70, 20), Color8(255, 170, 60), e))
		draw_sprite_hd(s, img, xx, yy, sx, sy, rot, c_white, g * 0.75)
		draw_sprite_hd(s, img, xx, yy - 2 * k, sx, sy, rot, c_white, g * 0.35)
		gpu_set_fog(false, c_white)
		gpu_set_blendmode(bm_normal)


func inimigo_sombra_alpha() -> float:
	return (1 - evaporar) if morrendo else 1.0


# ---------------------------------------------------------------------
# PORTAL DE MAGIA: bestas e arqueiros surgem do chão
# ---------------------------------------------------------------------
const SURGIR_SUBIDA := 60.0   # quadros escalando para fora do buraco (era 42, subida reta)
const SURGIR_PUXOES := 3      # quantos puxões até sair
const SURGIR_GRITO := 26.0    # quadros gritando antes de atacar
const GRITOS := ["GRRAAAH!", "RAAARGH!", "AAARGH!", "HRRAAA!"]
var surgir_puxao := -1


# progresso da escalada (0 = enterrado, 1 = fora): cada puxão sobe rápido
# e segura um instante, como alguém se içando pela borda (igual ao PC)
func surgir_progresso(t: float) -> float:
	var seg := SURGIR_SUBIDA / SURGIR_PUXOES
	var i := mini(SURGIR_PUXOES - 1, int(floor(t / seg)))
	var f := clampf((t - i * seg) / (seg * 0.6), 0, 1)
	return (i + 1 - pow(1 - f, 3)) / SURGIR_PUXOES


func inimigo_portal_iniciar() -> void:
	ativo = false
	surgir_fase = "escondido"
	surgir_puxao = -1
	surgir_t = 0
	surgir_agora = false
	surgir_atraso = 0
	distancia_surgir = 420
	portal_raio = 0


# Retorna true enquanto o inimigo ainda está escondido / surgindo
func inimigo_portal_step(dt: float) -> bool:
	if ativo:
		if portal_raio > 0:
			portal_raio = maxf(0, portal_raio - 0.04 * dt)
		return false
	var pj = instance_find("obj_player", 0)
	match surgir_fase:
		"escondido":
			var abrir := false
			if surgir_agora:
				surgir_atraso -= dt
				abrir = surgir_atraso <= 0
			elif pj != null and not pj.morto and absf(pj.x - x) <= distancia_surgir and absf(pj.y - y) <= 200:
				abrir = x > G.view_x + 24 and x < G.view_x + G.view_w - 24
			if abrir:
				surgir_fase = "portal"
				surgir_t = 0
				som_em("sfx_portal", x, y, 0.45)
				# v1.19: a primeira leva da fase -> Twilight fala antes da luta
				if not surgir_agora and pj != null and G.fala_batalha_room != G.room:
					G.fala_batalha_room = G.room
					fala_balao(pj, "Servos de Vallack... irão pagar com a vida!", Color8(150, 20, 20), 170)
					G.grito_espera = maxf(G.grito_espera, 40)
		"portal":
			surgir_t += dt
			portal_raio = minf(1, surgir_t / 24.0)
			if surgir_t >= 30:
				surgir_fase = "subindo"
				surgir_t = 0
				surgir_puxao = -1
				if pj != null and pj.x != x:
					dir = signf(pj.x - x)
		"subindo":
			# v1.19: escala para fora do submundo em puxões; cada um solta terra
			surgir_t += dt
			var px := mini(SURGIR_PUXOES - 1, int(floor(surgir_t / (SURGIR_SUBIDA / SURGIR_PUXOES))))
			if px != surgir_puxao:
				surgir_puxao = px
				fx_em("pedras", x + randf_range(-14, 14), y - 2, 0.6)
				fx_em("poeira", x, y - 2, 0.7)
			if surgir_t >= SURGIR_SUBIDA:
				surgir_fase = "grito"
				surgir_t = 0
				G.camera_impact = maxf(G.camera_impact, 3)
				if G.grito_espera <= 0:
					G.grito_espera = 45
					som_em("sfx_rugido", x, y, 0.5)
					fala_balao(self, GRITOS[randi() % GRITOS.size()], Color8(120, 10, 10), 40)
		"grito":
			surgir_t += dt
			if surgir_t >= SURGIR_GRITO:
				surgir_fase = "ativo"
				ativo = true
				if estado_ao_surgir != "":
					estado_ia = estado_ao_surgir
				else:
					estado_ia = "parado" if obj == "obj_inimigo_02" else "perseguir"
				alertado = true
				alerta_fx = 40
				recarga = maxf(recarga, 24)
				G.camera_impact = maxf(G.camera_impact, 2)
	velh = 0
	if not place_meeting(x, y + 1, "obj_chao"):
		velv += grav_ia * dt
	elif velv > 0:
		velv = 0
	return true


# Desenha o portal e o inimigo saindo do buraco (só a parte acima do chão)
func inimigo_portal_desenhar(s: GMSprite, esc: float, cor_final := Color(1, 1, 1)) -> void:
	if surgir_fase == "escondido":
		return
	desenhar_portal(x, y, portal_raio, current_time() / 16.0)
	if surgir_fase == "subindo" or surgir_fase == "grito":
		var grito := surgir_fase == "grito"
		var ease := 1.0 if grito else surgir_progresso(surgir_t)
		var k := hd_escala(s)
		var e := esc / k
		var h := s.h
		var ox := s.xo
		var oy := s.yo
		var sobe := (1 - ease) * h
		var vis := clampf(oy - sobe, 0, h)
		# balanço lateral da escalada / tremor do grito
		var bx := randf_range(-1, 1) if grito else sin(surgir_t * 0.35) * 2 * (1 - ease)
		var sy := 1.0
		if grito:
			sy = 1 + 0.08 * sin(clampf(surgir_t / SURGIR_GRITO, 0, 1) * PI)   # estufa ao gritar
		if vis >= 1:
			gpu_set_texfilter(k > 1)
			draw_sprite_part_ext(s, 0, 0, 0, s.w, vis, x + bx - dir * ox * e, y + (sobe - oy) * e * sy, dir * e, e * sy,
				merge_color(Color8(200, 120, 255), cor_final, ease), 1)
			gpu_set_texfilter(false)
		if grito:
			# ondas do grito saindo da boca
			var cy := y - oy * e * 0.75
			gpu_set_blendmode(bm_add)
			draw_set_color(Color8(255, 80, 60))
			for o in 2:
				var f := fposmod(surgir_t / 16.0 + o * 0.5, 1.0)
				draw_set_alpha(0.45 * (1 - f))
				draw_circle(x + dir * 10, cy, 8 + f * 34, true)
			gpu_set_blendmode(bm_normal)
			draw_set_alpha(1)
			return
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.6 * (1 - ease))
		draw_set_color(Color8(220, 90, 255))
		draw_ellipse(x - 30, y - 6, x + 30, y + 6, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)


# =====================================================================
#  scr_inimigos_novos (parte que roda no inimigo)
# =====================================================================
func inimigo_nivel_calcular() -> int:
	var p := clampf(x / maxf(1, G.room_width), 0, 0.999)
	var n := 1 + int(floor(p * 3))
	if G.room == "Room2":
		n += 2
	return clampi(n, 1, NIVEL_MAX)


func inimigo_status(v: float) -> void:
	nivel = inimigo_nivel_calcular()
	vida_max = maxf(1, round(v * dif_vida_inimigo() * nivel_vida(nivel)))
	vida = vida_max
	vida_atraso = vida


func inimigo_dano(d: float) -> float:
	return maxf(1, round(d * dif_dano_inimigo() * nivel_dano(nivel)))


func inimigo_na_tela(margem := 0.0) -> bool:
	return x >= G.view_x - margem and x <= G.view_x + G.view_w + margem \
		and y - 20 >= G.view_y - margem and y - 60 <= G.view_y + G.view_h + margem


# Pode andar nessa direção sem sair do mapa / da arena / passar da barreira?
func inimigo_pode_andar(d: float, passo := 32.0) -> bool:
	var nx := x + d * passo
	if nx < 48 or nx > G.room_width - 48:
		return false
	if arena_limitar_x(nx, 24) != nx:
		return false
	if place_meeting(nx, y - 4, "obj_chao"):
		return false
	var b = instance_find("obj_boss_01", 0)
	if b != null and not b.morrendo and nx > b.barreira_x - 24:
		return false
	return true


# HUD sobre o inimigo: atordoamento, finalizador, alerta, barra de vida e nível
func inimigo_hud(topo: float, larg := 46.0) -> void:
	gpu_set_texfilter(true)
	if libertou_fx > 0:
		var lf := 1 - libertou_fx / 20.0
		draw_set_alpha(1 - lf)
		draw_set_color(Color8(255, 80, 60))
		draw_circle(x, (y + topo) / 2.0, 12 + 30 * lf, true)
		draw_set_alpha(1)
	if atordoado > 0:
		draw_set_color(Color8(255, 230, 110))
		for k in 3:
			var ang := atordoado_anim * 7 + k * 120
			var sx := x + lengthdir_x(15, ang)
			var sy := topo + 4 + lengthdir_y(4, ang)
			draw_set_alpha(0.65 + 0.35 * dsin(ang))
			draw_triangle(sx - 4, sy, sx + 4, sy, sx, sy - 4, false)
			draw_triangle(sx - 4, sy, sx + 4, sy, sx, sy + 4, false)
		draw_set_alpha(1)
	if finalizavel:
		desenhar_icone_finalizador(x, topo - 16)
	if alerta_fx > 0:
		var aa := clampf(alerta_fx / 12.0, 0, 1)
		txt(x, topo - 8 - (40 - alerta_fx) * 0.2, "!", FONTE.MEDIA, Color8(255, 80, 60), aa, fa_center, fa_bottom, 0.8)
	var mostra := barra_tempo > 0 and vida > 0
	var a := minf(1, barra_tempo / 24.0) if mostra else clampf(alerta_fx / 20.0, 0, 1)
	if a > 0:
		var bx := x - larg / 2.0
		var by := topo - 6
		if mostra:
			vida_atraso = lerp_dt(vida_atraso, vida, 0.06)
			draw_set_alpha(a)
			draw_set_color(c_black)
			draw_rectangle(bx - 2, by - 2, bx + larg + 2, by + 6, false)
			draw_set_color(c_white)
			draw_rectangle(bx, by, bx + larg * clampf(vida_atraso / vida_max, 0, 1), by + 4, false)
			draw_rectangle_color(bx, by, bx + larg * clampf(vida / vida_max, 0, 1), by + 4,
				Color8(230, 80, 65), Color8(230, 80, 65), Color8(120, 20, 20), Color8(120, 20, 20), false)
			draw_set_color(Color8(176, 141, 70))
			draw_rectangle(bx - 2, by - 2, bx + larg + 2, by + 6, true)
			draw_set_alpha(1)
		var nx := bx - 6
		var ny := by + 2
		if elite:
			txt(x, by - 4, "ELITE", FONTE.MINI, Color8(255, 90, 70), a, fa_center, fa_bottom, 0.6)
		if not mostra:
			gpu_set_texfilter(false)
			return
		draw_set_alpha(a)
		draw_set_color(c_black)
		draw_circle(nx, ny, 7, false)
		draw_set_color(nivel_cor(nivel))
		draw_circle(nx, ny, 7, true)
		draw_set_alpha(1)
		txt(nx, ny + 1, str(nivel), FONTE.MINI, nivel_cor(nivel), a, fa_center, fa_middle, 0.5)
	gpu_set_texfilter(false)


# Desenha o inimigo (com o clarão branco ao levar golpe)
func inimigo_desenhar_corpo(s: GMSprite, img: float, px: float, py: float, xs: float, ys: float, rot: float, cor: Color, alfa: float) -> void:
	if flash_dano > 0 and not morrendo:
		gpu_set_fog(true, c_white)
		draw_sprite_hd(s, img, px, py, xs, ys, rot, c_white, alfa)
		gpu_set_fog(false, c_white)
	else:
		inimigo_corpo_desenhar(s, img, px, py, xs, ys, rot, cor, alfa)


func inimigo_sombra(larg: float) -> void:
	if not place_meeting(x, y + 2, "obj_chao"):
		return
	draw_set_alpha(0.3 * image_alpha * inimigo_sombra_alpha())
	draw_set_color(c_black)
	draw_ellipse(x - larg, y - 3, x + larg, y + 3, false)
	draw_set_alpha(1)


func inimigo_debug(extra := "") -> void:
	if not G.debug_hitbox:
		return
	draw_set_alpha(0.9)
	draw_set_color(c_red)
	draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true)
	draw_set_alpha(1)
	txt(x, bbox_bottom + 4, estado_ia + "  Nv " + str(nivel) + (" (atordoado)" if atordoado > 0 else "") + extra, FONTE.MINI, c_yellow, 1, fa_center, fa_top, 0.45)


# =====================================================================
#  scr_v112 (parte que roda no inimigo)
# =====================================================================
# Petrificação: cada golpe no Modo Fúria endurece o inimigo um pouco
func inimigo_petrificar() -> void:
	if morrendo or not ativo or eh_boss:
		return
	petrif = mini(3, petrif + 1)
	petrif_t = 150
	if petrif >= 3 and not petrificado:
		petrificado = true
		inimigo_atordoar(50 if resiste_atordoar else 110, true)
		som_em("sfx_petrificar", x, y, 0.8)
		fx_em("pedras", x, y - 30, 0.5)


# ELITES (no Create dos inimigos de elite)
func elite_aplicar() -> void:
	elite = true
	vida_max = maxf(1, round(vida_max * 2.4))
	vida = vida_max
	vida_atraso = vida
	dano_ataque = maxf(1, round(dano_ataque * 1.3))
	escala_vis *= 1.15
	topo_vis *= 1.15
	cor_base = merge_color(cor_base, Color8(255, 90, 80), 0.35)
	usa_hud_nivel = true


# COMBO AÉREO: o inimigo atingido no ar fica "suspenso" (gravidade baixa)
func inimigo_suspender(quadros: float) -> void:
	if suspenso_t <= 0:
		grav_ia_base = grav_ia
	grav_ia = 0.14
	suspenso_t = maxf(suspenso_t, quadros)
