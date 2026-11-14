class_name GMObj
extends RefCounted
# =====================================================================
#  GMObj — instância no estilo do GameMaker.
#  Os objetos do jogo (src/objects) herdam daqui (através de Lib).
#  Eventos: ev_create, ev_step_begin, ev_step, ev_step_end, ev_anim_end,
#  ev_draw, ev_draw_end, ev_draw_gui, ev_room_start, ev_cleanup.
# =====================================================================

# ----- enums e constantes do jogo (scr_globais / scr_input) -----
enum ACAO { ESQUERDA, DIREITA, PULAR, ATACAR, ESPECIAL, DEFENDER, INTERAGIR, AGACHAR, ATAQUE_FORTE, ATAQUE_SALTO, ESPECIAL_2, ESPECIAL_3, ESQUIVA, FURIA, TOTAL }
enum DIF { FACIL, MEDIO, DIFICIL, EXTREMO, TOTAL }
enum FONTE { TITULO, GRANDE, MEDIA, PEQUENA, MINI, TOTAL }

const fa_left := 0
const fa_center := 1
const fa_right := 2
const fa_top := 0
const fa_middle := 1
const fa_bottom := 2
const bm_normal := 0
const bm_add := 1
const pr_trianglelist := 4
const pr_trianglestrip := 5

const c_white := Color(1, 1, 1)
const c_black := Color(0, 0, 0)
const c_gray := Color8(128, 128, 128)
const c_red := Color8(255, 0, 0)
const c_yellow := Color8(255, 255, 0)
const c_orange := Color8(255, 160, 64)
const c_lime := Color8(0, 255, 0)
const c_fuchsia := Color8(255, 0, 255)

# botões do controle (códigos do Godot; gatilhos são eixos)
const gp_face1 := 0
const gp_face2 := 1
const gp_face3 := 2
const gp_face4 := 3
const gp_select := 4
const gp_start := 6
const gp_stickl := 7
const gp_stickr := 8
const gp_shoulderl := 9
const gp_shoulderr := 10
const gp_padu := 11
const gp_padd := 12
const gp_padl := 13
const gp_padr := 14
const gp_shoulderlb := 100
const gp_shoulderrb := 101

# ----- variáveis embutidas de toda instância -----
var obj := ""
var id := 0
var x := 0.0
var y := 0.0
var xstart := 0.0
var ystart := 0.0
var depth := 0
var visible := true
var persistent := false
var sprite_index: GMSprite = null
var mask_index: GMSprite = null
var image_index := 0.0
var image_speed := 1.0
var image_xscale := 1.0
var image_yscale := 1.0
var image_angle := 0.0
var image_blend := Color(1, 1, 1)
var image_alpha := 1.0

# ----- uso interno do runtime -----
var _destruido := false
var _ativo := true
var _ev := ""                 # letras dos eventos que o objeto tem (G.EVENTOS)
var _cadeia: Array = []       # o objeto e os ancestrais
var _alvo_mundo = null
var _alvo_fim = null
var _alvo_gui = null
var _cache_padrao: Array = []
var _cache_gui = null
var _anim_livre := false        # sem lógica própria: só anima perto da câmera


# Desenho da GUI em cache: quem sobrescreve devolve um resumo do que a GUI
# mostra; se for igual ao do quadro anterior, o desenho anterior é mantido.
# null = redesenhar sempre (ex.: há animação na tela).
func gui_chave():
	return null


var image_number: int:
	get:
		return sprite_index.n if sprite_index != null else 0


# ---------------------------------------------------------------------
# EVENTOS (os objetos sobrescrevem; "super()" = event_inherited())
# ---------------------------------------------------------------------
func ev_create() -> void:
	pass

func ev_step_begin() -> void:
	pass

func ev_step() -> void:
	pass

func ev_step_end() -> void:
	pass

func ev_anim_end() -> void:
	pass

func ev_draw() -> void:
	draw_self()

func ev_draw_end() -> void:
	pass

func ev_draw_gui_begin() -> void:
	pass

func ev_draw_gui() -> void:
	pass

func ev_draw_gui_end() -> void:
	pass

func ev_room_start() -> void:
	pass

func ev_cleanup() -> void:
	pass


func _tem(letra: String) -> bool:
	return _ev.contains(letra)


func e_um(o: String) -> bool:
	return _cadeia.has(o)


# ---------------------------------------------------------------------
# ANIMAÇÃO (depois do End Step, como no GameMaker)
# ---------------------------------------------------------------------
func _animar() -> void:
	if sprite_index == null or image_speed == 0.0:
		return
	var n := sprite_index.n
	image_index += image_speed * sprite_index.spd / G.velocidade_jogo
	if image_index >= n:
		image_index -= n
		if _ev.contains("a"):
			ev_anim_end()
	elif image_index < 0.0:
		image_index += n
		if _ev.contains("a"):
			ev_anim_end()


# ---------------------------------------------------------------------
# CAIXA DE COLISÃO (bbox_right/bbox_bottom inclusivos, como no GameMaker)
# ---------------------------------------------------------------------
func _mascara() -> GMSprite:
	return mask_index if mask_index != null else sprite_index


# [esquerda, topo, direita, base] com direita/base exclusivas, na posição (px, py)
func _caixa(px: float, py: float) -> Array:
	var m := _mascara()
	if m == null:
		return [px, py, px, py]
	var a := (m.bl - m.xo) * image_xscale
	var b := (m.br + 1.0 - m.xo) * image_xscale
	var c := (m.bt - m.yo) * image_yscale
	var d := (m.bb + 1.0 - m.yo) * image_yscale
	return [px + minf(a, b), py + minf(c, d), px + maxf(a, b), py + maxf(c, d)]


var bbox_left: float:
	get:
		var m := _mascara()
		if m == null:
			return x
		return x + minf((m.bl - m.xo) * image_xscale, (m.br + 1.0 - m.xo) * image_xscale)

var bbox_right: float:
	get:
		var m := _mascara()
		if m == null:
			return x
		return x + maxf((m.bl - m.xo) * image_xscale, (m.br + 1.0 - m.xo) * image_xscale) - 1.0

var bbox_top: float:
	get:
		var m := _mascara()
		if m == null:
			return y
		return y + minf((m.bt - m.yo) * image_yscale, (m.bb + 1.0 - m.yo) * image_yscale)

var bbox_bottom: float:
	get:
		var m := _mascara()
		if m == null:
			return y
		return y + maxf((m.bt - m.yo) * image_yscale, (m.bb + 1.0 - m.yo) * image_yscale) - 1.0


# ---------------------------------------------------------------------
# INSTÂNCIAS
# ---------------------------------------------------------------------
func instance_create_depth(px: float, py: float, prof: int, o: String) -> GMObj:
	return G.criar(px, py, prof, o)


func instance_destroy(inst = null) -> void:
	G.destruir(self if inst == null else inst)


func instance_exists(a) -> bool:
	if a is String:
		return G.existe_obj(a)
	return G.existe(a)


func instance_find(o: String, n := 0):
	return G.achar(o, n)


func instance_number(o: String) -> int:
	return G.numero(o)


func instance_nearest(px: float, py: float, o: String):
	return G.mais_perto(px, py, o)


# "with (obj)": lista das instâncias ativas do objeto (e descendentes)
func todos(o: String) -> Array:
	return G.todos(o)


func object_is_ancestor(filho: String, pai: String) -> bool:
	return G.cadeia_de(filho).has(pai) and filho != pai


func variable_instance_exists(inst, nome: String) -> bool:
	return inst != null and (nome in inst)


# ---------------------------------------------------------------------
# COLISÃO
# ---------------------------------------------------------------------
func place_meeting(px: float, py: float, o: String) -> bool:
	return G.place_meeting(self, px, py, o)


func position_meeting(px: float, py: float, o: String) -> bool:
	return G.position_meeting(px, py, o)


func collision_rectangle(x1: float, y1: float, x2: float, y2: float, o: String, _prec := false, notme := true):
	return G.collision_rectangle(x1, y1, x2, y2, o, self if notme else null)


func collision_rectangle_list(x1: float, y1: float, x2: float, y2: float, o: String, _prec := false, notme := true) -> Array:
	return G.collision_rectangle_list(x1, y1, x2, y2, o, self if notme else null)


func collision_point(px: float, py: float, o: String, _prec := false, notme := true):
	return G.collision_point(px, py, o, self if notme else null)


# ---------------------------------------------------------------------
# DESENHO (mesma API do GameMaker)
# ---------------------------------------------------------------------
func draw_set_color(c: Color) -> void:
	G.cor_desenho = c

func draw_set_alpha(a: float) -> void:
	G.alfa_desenho = a

func draw_get_alpha() -> float:
	return G.alfa_desenho

func gpu_set_blendmode(m: int) -> void:
	G.pen.blend_add = (m == bm_add)

func gpu_set_fog(ligado: bool, c: Color, _a = 0, _b = 0) -> void:
	G.pen.fog = ligado
	G.pen.fog_cor = c

func gpu_set_texfilter(ligado: bool) -> void:
	G.pen.filtro = ligado

func gpu_get_texfilter() -> bool:
	return G.pen.filtro

func draw_rectangle(x1: float, y1: float, x2: float, y2: float, contorno: bool) -> void:
	G.pen.retangulo(x1, y1, x2, y2, G.cor_desenho, G.alfa_desenho, contorno)

func draw_rectangle_color(x1: float, y1: float, x2: float, y2: float, c1: Color, c2: Color, c3: Color, c4: Color, _contorno: bool) -> void:
	G.pen.retangulo_cores(x1, y1, x2, y2, c1, c2, c3, c4, G.alfa_desenho)

func draw_circle(px: float, py: float, r: float, contorno: bool) -> void:
	G.pen.circulo(px, py, r, G.cor_desenho, G.alfa_desenho, contorno)

func draw_ellipse(x1: float, y1: float, x2: float, y2: float, contorno: bool) -> void:
	G.pen.elipse(x1, y1, x2, y2, G.cor_desenho, G.alfa_desenho, contorno)

func draw_triangle(x1: float, y1: float, x2: float, y2: float, x3: float, y3: float, contorno: bool) -> void:
	G.pen.triangulo(x1, y1, x2, y2, x3, y3, G.cor_desenho, G.alfa_desenho, contorno)

func draw_line(x1: float, y1: float, x2: float, y2: float) -> void:
	G.pen.linha(x1, y1, x2, y2, G.cor_desenho, G.alfa_desenho, 1.0)

func draw_line_width(x1: float, y1: float, x2: float, y2: float, w: float) -> void:
	G.pen.linha(x1, y1, x2, y2, G.cor_desenho, G.alfa_desenho, w)

func draw_roundrect_ext(x1: float, y1: float, x2: float, y2: float, rx: float, ry: float, contorno: bool) -> void:
	G.pen.retangulo_arredondado(x1, y1, x2, y2, rx, ry, G.cor_desenho, G.alfa_desenho, contorno)

func draw_primitive_begin(tipo: int) -> void:
	G.pen.prim_comecar(tipo)

func draw_vertex_color(px: float, py: float, c: Color, a: float) -> void:
	G.pen.prim_vertice(px, py, c, a)

func draw_primitive_end() -> void:
	G.pen.prim_terminar()

func draw_sprite_ext(s: GMSprite, img: float, px: float, py: float, xs: float, ys: float, rot: float, c: Color, a: float) -> void:
	G.pen.sprite(s, img, px, py, xs, ys, rot, c, a)

func draw_sprite(s: GMSprite, img: float, px: float, py: float) -> void:
	G.pen.sprite(s, img, px, py, 1.0, 1.0, 0.0, c_white, G.alfa_desenho)

func draw_sprite_part_ext(s: GMSprite, img: float, l: float, t: float, w: float, h: float, px: float, py: float, xs: float, ys: float, c: Color, a: float) -> void:
	G.pen.sprite_parte(s, img, l, t, w, h, px, py, xs, ys, c, a)

func draw_self() -> void:
	if sprite_index != null:
		G.pen.sprite(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha)


# ---------------------------------------------------------------------
# MATEMÁTICA E ALEATÓRIOS (como no GameMaker)
# ---------------------------------------------------------------------
static func random(n: float) -> float:
	return randf() * n

static func random_range(a: float, b: float) -> float:
	return randf_range(a, b)

static func irandom(n: int) -> int:
	return randi_range(0, n)

static func irandom_range(a: int, b: int) -> int:
	return randi_range(a, b)

static func choose(lista: Array):
	return lista[randi() % lista.size()]

static func lengthdir_x(l: float, d: float) -> float:
	return l * cos(deg_to_rad(d))

static func lengthdir_y(l: float, d: float) -> float:
	return -l * sin(deg_to_rad(d))

static func point_direction(x1: float, y1: float, x2: float, y2: float) -> float:
	var a := rad_to_deg(atan2(-(y2 - y1), x2 - x1))
	return fposmod(a, 360.0)

static func point_distance(x1: float, y1: float, x2: float, y2: float) -> float:
	return sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))

static func angle_difference(a: float, b: float) -> float:
	return fposmod(a - b + 180.0, 360.0) - 180.0

static func dsin(d: float) -> float:
	return sin(deg_to_rad(d))

static func dcos(d: float) -> float:
	return cos(deg_to_rad(d))

static func frac(v: float) -> float:
	return v - float(int(v))

static func gm_mod(a: float, b: float) -> float:
	return fmod(a, b)

static func point_in_rectangle(px: float, py: float, x1: float, y1: float, x2: float, y2: float) -> bool:
	return px >= x1 and px <= x2 and py >= y1 and py <= y2

# 0 = fora, 1 = a origem está toda dentro do destino, 2 = só uma parte
static func rectangle_in_rectangle(sx1: float, sy1: float, sx2: float, sy2: float, dx1: float, dy1: float, dx2: float, dy2: float) -> int:
	if sx2 < dx1 or sx1 > dx2 or sy2 < dy1 or sy1 > dy2:
		return 0
	if sx1 >= dx1 and sx2 <= dx2 and sy1 >= dy1 and sy2 <= dy2:
		return 1
	return 2

static func make_color_rgb(r: int, g: int, b: int) -> Color:
	return Color8(r, g, b)

static func merge_color(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, clampf(t, 0.0, 1.0))

static func current_time() -> float:
	return float(Time.get_ticks_msec())

# string() do GameMaker: inteiros sem casas decimais, reais com até 2 casas
static func gs(v) -> String:
	if v is float:
		if is_equal_approx(v, round(v)) and absf(v) < 1e15:
			return str(int(round(v)))
		var s := "%.2f" % v
		while s.ends_with("0"):
			s = s.left(-1)
		if s.ends_with("."):
			s = s.left(-1)
		return s
	return str(v)

static func string_copy(s: String, pos: int, n: int) -> String:
	return s.substr(maxi(0, pos - 1), maxi(0, n))

static func string_char_at(s: String, i: int) -> String:
	if i < 1 or i > s.length():
		return ""
	return s[i - 1]

static func string_delete(s: String, pos: int, n: int) -> String:
	return s.left(maxi(0, pos - 1)) + s.substr(pos - 1 + n)
