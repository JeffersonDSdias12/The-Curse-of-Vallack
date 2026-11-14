extends ObjDestrutivel
# =====================================================================
#  obj_lampiao — poste com lanterna (v1.11)
#  A lanterna balança com o vento da tempestade. Se Twilight acerta o
#  poste, ela leva a pancada, balança forte e a luz pisca. Não quebra.
# =====================================================================

var ang := 0.0
var angv := 0.0
var pisca := 0.0
var semente := 0.0
var t := 0.0


func ev_create() -> void:
	super()
	vida = 1000000
	vida_max = 1000000
	image_speed = 0
	depth = 240
	semente = randf() * 100
	t = randf() * 1000


func ao_bater(forca: float) -> void:
	vida = vida_max
	angv += lado_golpe * (3 + 1.5 * forca)
	pisca = 18
	som_em("lampiao_bater", x, y - 90, 0.9)
	fx_em("faiscas_golpe", x + 12, y - 80, 0.6, lado_golpe, depth - 1)


func ev_step() -> void:
	super()
	var dt := G.dt
	t += dt
	var vento := -1.5
	for c in todos("obj_clima"):
		vento = c.vento
	var alvo := vento * 3 + 3 * sin(t / 47.0 + semente)
	angv += (alvo - ang) * 0.025 * dt
	angv *= pow(0.965, dt)
	ang = clampf(ang + angv * dt, -50, 50)
	if pisca > 0:
		pisca -= dt


func ev_draw() -> void:
	if not cenario_na_tela(x - 60, x + 60):
		return
	var tx := randf_range(-tremor, tremor) * 0.25 if tremor > 0 else 0.0
	var hx := x + 12 + tx
	var hy := y - 93
	var lx := hx + lengthdir_x(11, ang - 90)
	var ly := hy + lengthdir_y(11, ang - 90)
	var forca := 1.0
	if pisca > 0:
		forca = 0.35 if int(floor(pisca / 3.0)) % 2 == 0 else 1.2
	forca *= 0.9 + 0.1 * sin(current_time() / 90.0 + semente)
	cenario_luz(lx, ly, 80, forca, Color8(255, 190, 90))
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.1 * forca)
	draw_set_color(Color8(255, 170, 80))
	draw_ellipse(lx - 34, y - 6, lx + 34, y + 4, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_sprite(sprite_index, 0, x + tx, y)
	if flash > 0:
		gpu_set_fog(true, Color8(255, 230, 190))
		draw_sprite_ext(Spr.spr_lampiao_luz, 0, hx, hy, 1, 1, ang, c_white, 1)
		gpu_set_fog(false, c_white)
	else:
		draw_sprite_ext(Spr.spr_lampiao_luz, 0, hx, hy, 1, 1, ang, c_white, 1)
