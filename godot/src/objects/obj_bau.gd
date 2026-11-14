extends Lib
# =====================================================================
#  obj_bau — BAÚ DE VIDA
#  * INTERAGIR perto dele: a tampa abre, sai um brilho e a magia flui do
#    baú até Twilight, curando aos poucos
#  * pode ficar escondido dentro de um caixote (aparece quando ele quebra)
#  * abre uma única vez (fica gravado no save)
# =====================================================================

var estado := "fechado"
var visivel := true
var revelar_t := 0.0
var t := 0.0
var alvo = null
var magia: Array = []
var magia_soltas := 0
var cura_total := 55.0
var chave := ""
# v1.14: o baú do forte guarda a CHAVE DO PORTÃO e fica selado (correntes de magia)
# até os guardiões caírem (obj_terreno)
var conteudo := "vida"       # "vida" ou "chave"
var selado := false
var selo_quebra := 0.0        # brilho quando o selo se parte
var chave_voo := -1.0         # a chave subindo do baú e voando até Twilight (quadros)


func ev_create() -> void:
	sprite_index = Spr.spr_bau
	image_speed = 0
	image_index = 0
	cura_total = dif_valor([90, 75, 60, 35])     # v1.22: era 70 55 45
	chave = aberto_chave("bau", xstart, ystart)
	if aberto_tem(chave):
		estado = "aberto"
		image_index = 3


func bau_revelar() -> void:
	if visivel:
		return
	visivel = true
	revelar_t = 30
	som_em("sfx_cura", x, y, 0.4)


# Twilight abre o baú: animação da tampa, depois a magia flui para ele
func bau_abrir(jogador) -> void:
	if estado != "fechado" or not visivel:
		return
	if selado:
		aviso_mostrar("O BAÚ ESTÁ SELADO  ·  DERROTE OS GUARDIÕES")     # com o som da mensagem importante
		return
	if conteudo == "chave":
		chave_voo = 0
	estado = "abrindo"
	t = 0
	alvo = jogador
	aberto_marcar(chave)
	som_em("sfx_bau", x, y, 1, 0)
	G.camera_impact = maxf(G.camera_impact, 3)


func ev_step() -> void:
	var dt := G.dt
	if revelar_t > 0:
		revelar_t -= dt
	if selo_quebra > 0:
		selo_quebra -= dt
	# v1.14: a chave sobe do baú, gira no ar e voa até Twilight
	if chave_voo >= 0:
		chave_voo += dt
		if chave_voo >= 70:
			chave_voo = -1
			G.chave_portao = true
			aviso_mostrar("CHAVE DO PORTÃO  ·  VOLTE AO PORTÃO TRANCADO")
			som("sfx_cura", 0.7, 0)
			G.camera_impact = maxf(G.camera_impact, 3)
	if not visivel:
		return
	if estado == "abrindo":
		t += dt
		image_index = minf(3, floor(t / 7.0) + 1)
		if t >= 22 and magia_soltas == 0:
			fx_em("faiscas_golpe", x, y - 16, 0.8, 1)
			G.camera_impact = maxf(G.camera_impact, 4)
		# (o baú da chave não cura: a chave é o tesouro)
		if conteudo == "chave" and t >= 22:
			estado = "aberto"
		elif t >= 22 and magia_soltas < BAU_PARTICULAS:
			var n := mini(BAU_PARTICULAS - magia_soltas, int(ceil(0.5 * dt)))
			for i in n:
				magia.append({"x": x + randf_range(-8, 8), "y": y - 16, "vx": randf_range(-1.5, 1.5), "vy": randf_range(-3.8, -2), "v": 0.0})
				magia_soltas += 1
		if estado == "abrindo" and magia_soltas >= BAU_PARTICULAS and magia.is_empty():
			estado = "aberto"
	# partículas: sobem, depois voam até o peito de Twilight
	for i in range(magia.size() - 1, -1, -1):
		var m: Dictionary = magia[i]
		m.v += dt
		if m.v < 16 or not G.existe(alvo):
			m.x += m.vx * dt
			m.y += m.vy * dt
			m.vy *= pow(0.93, dt)
			m.vx *= pow(0.95, dt)
			if m.v > 200:
				magia.remove_at(i)
			continue
		var tx: float = alvo.x
		var ty: float = (alvo.bbox_top + alvo.bbox_bottom) / 2.0
		var d := point_distance(m.x, m.y, tx, ty)
		var v := minf(12, 2 + m.v * 0.12)
		if d <= v * dt + 4:
			if not alvo.morto:
				alvo.cura_restante += cura_total / BAU_PARTICULAS
				alvo.cura_fx = 20
			if i % 6 == 0:
				som("sfx_cura", 0.35, 0.1)
			magia.remove_at(i)
			continue
		var ang := point_direction(m.x, m.y, tx, ty)
		m.vx = lerpf(m.vx, lengthdir_x(v, ang), 0.25)
		m.vy = lerpf(m.vy, lengthdir_y(v, ang), 0.25)
		m.x += m.vx * dt
		m.y += m.vy * dt


func ev_draw() -> void:
	if not visivel:
		return
	var t2 := current_time() / 16.0
	if revelar_t > 0:
		var ra := revelar_t / 30.0
		gpu_set_blendmode(bm_add)
		draw_set_alpha(ra * 0.6)
		draw_set_color(Color8(255, 200, 90))
		draw_rectangle(x - 10 * (1 - ra) - 4, y - 140, x + 10 * (1 - ra) + 4, y, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	if estado == "fechado":
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.16 + 0.08 * sin(t2 / 10.0))
		draw_set_color(Color8(255, 170, 60))
		draw_ellipse(x - 26, y - 34, x + 26, y + 4, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_white, 1)
	if estado == "abrindo":
		var k := clampf(t / 30.0, 0, 1)
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.5 * k)
		draw_set_color(Color8(255, 210, 120))
		draw_triangle(x - 12, y - 14, x + 12, y - 14, x + 30, y - 90, false)
		draw_triangle(x - 12, y - 14, x - 30, y - 90, x + 30, y - 90, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	if magia.size() > 0:
		gpu_set_blendmode(bm_add)
		for m in magia:
			draw_set_alpha(0.35)
			draw_set_color(Color8(255, 120, 60))
			draw_circle(m.x, m.y, 5, false)
			draw_set_alpha(0.9)
			draw_set_color(Color8(255, 230, 160))
			draw_circle(m.x, m.y, 2, false)
			draw_set_alpha(0.4)
			draw_line_width(m.x, m.y, m.x - m.vx * 2.5, m.y - m.vy * 2.5, 2)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# v1.14: SELO de magia (correntes roxas em X e um círculo de runas girando)
	if selado or selo_quebra > 0:
		var sa := (0.75 + 0.25 * sin(t2 / 8.0)) if selado else selo_quebra / 40.0
		var sr := 1.0 if selado else 1 + (1 - selo_quebra / 40.0) * 0.8
		gpu_set_blendmode(bm_add)
		draw_set_color(Color8(170, 60, 255))
		draw_set_alpha(0.25 * sa)
		draw_ellipse(x - 30 * sr, y - 30 * sr, x + 30 * sr, y + 6, false)
		draw_set_alpha(0.9 * sa)
		draw_set_color(Color8(210, 140, 255))
		for k in 8:
			var ang := t2 * 1.6 + k * 45
			draw_circle(x + lengthdir_x(24 * sr, ang), y - 12 + lengthdir_y(10 * sr, ang), 1.5, false)
		for c in [-1, 1]:
			for k in 9:
				var cx: float = x - 16 + k * 4
				var cy: float = y - 22 + k * 2.4 * c + (0.0 if c > 0 else 19.0)
				draw_ellipse(cx - 2, cy - 1.5, cx + 2, cy + 1.5, true)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	# v1.14: a chave subindo do baú e voando até Twilight
	if chave_voo >= 0:
		var kp := clampf(chave_voo / 70.0, 0, 1)
		var kx := x
		var ky := y - 20 - 40 * minf(1, chave_voo / 30.0)
		if chave_voo > 40 and G.existe(alvo):
			var kk := (chave_voo - 40) / 30.0
			kx = lerpf(kx, alvo.x, kk)
			ky = lerpf(ky, alvo.bbox_top + 10, kk)
		gpu_set_blendmode(bm_add)
		draw_set_color(Color8(255, 210, 100))
		draw_set_alpha(0.35 * (1 - kp * 0.5))
		draw_circle(kx, ky, 12, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
		desenhar_chave(kx, ky, 1, sin(chave_voo / 6.0))
	# (o botão ABRIR, em destaque sobre o baú, é desenhado pelo HUD do jogador)
	desenho_resetar()
