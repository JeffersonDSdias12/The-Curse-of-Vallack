class_name Pen
extends RefCounted
# =====================================================================
#  Pen — desenho no estilo do GameMaker sobre o RenderingServer.
#  Cada instância tem um "alvo" por camada (mundo, Draw End e GUI).
#  Todos os desenhos usam um único shader de alfa pré-multiplicado: o blend
#  aditivo e o fog vão codificados no alfa da cor (+2 aditivo, +4 fog), então
#  normal e aditivo convivem no mesmo canvas item, na ordem do código original.
#  Só a troca do filtro de textura abre um novo segmento (canvas item filho).
# =====================================================================

const ESQ := 0
const CENTRO := 1
const DIR := 2
const TOPO := 0
const MEIO := 1
const BASE := 2


class Alvo:
	var raiz: RID
	var segs: Array = []
	var filtros: Array = []     # filtro de textura de cada segmento
	var usados := 0
	var mundo := false

	func _init(pai: RID, z: int, _mundo: bool) -> void:
		raiz = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(raiz, pai)
		RenderingServer.canvas_item_set_z_index(raiz, z)
		mundo = _mundo

	func definir_z(z: int) -> void:
		RenderingServer.canvas_item_set_z_index(raiz, z)

	func visivel(v: bool) -> void:
		RenderingServer.canvas_item_set_visible(raiz, v)

	func limpar() -> void:
		for i in usados:
			RenderingServer.canvas_item_clear(segs[i])
		usados = 0

	func liberar() -> void:
		for s in segs:
			RenderingServer.free_rid(s)
		segs.clear()
		RenderingServer.free_rid(raiz)


var alvo: Alvo = null
var blend_add := false
var fog := false
var fog_cor := Color.WHITE
var filtro := false
var escala_texto := 1.0         # escala da câmera quando o texto é desenhado no mundo

var _tem_seg := false
var _seg_rid: RID
var _seg_filtro := false

var mat: ShaderMaterial

# primitivas (draw_primitive_begin / draw_vertex_color)
var _prim_tipo := 0
var _prim_pts := PackedVector2Array()
var _prim_cores := PackedColorArray()

# filtro suave: usa mipmaps quando a textura tem (a arte SVG da interface)
const FILTRO_SUAVE := RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

const PR_TRIANGLESTRIP := 5
const PR_TRIANGLELIST := 4


func _init() -> void:
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
render_mode blend_premul_alpha;
varying flat float v_add;
varying flat float v_fog;
varying flat vec3 v_cor;
void vertex() {
	float a = COLOR.a;
	v_fog = 0.0;
	v_add = 0.0;
	if (a > 3.5) { v_fog = 1.0; a -= 4.0; }
	if (a > 1.5) { v_add = 1.0; a -= 2.0; }
	v_cor = COLOR.rgb;
	COLOR.a = a;
}
void fragment() {
	vec4 c = COLOR;
	if (v_fog > 0.5) { c.rgb = v_cor; }
	c.rgb *= c.a;
	if (v_add > 0.5) { c.a = 0.0; }
	COLOR = c;
}
"""
	mat = ShaderMaterial.new()
	mat.shader = sh
	# disco branco suave: círculos e elipses viram retângulos com textura,
	# que o renderizador agrupa (polígonos criariam um buffer novo por chamada)
	# (gerado pelo próprio Godot: montar pixel a pixel em GDScript atrasava a abertura)
	var ct := CanvasTexture.new()
	ct.diffuse_texture = textura_radial(128, [0.0, 0.984, 1.0], [1.0, 1.0, 0.0])
	ct.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	disco = ct
	_disco_rid = disco.get_rid()


# textura branca radial: alfa por distância do centro (0 = centro, 1 = borda)
static func textura_radial(tam: int, pos: Array, alfas: Array) -> GradientTexture2D:
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array(pos)
	var cores := PackedColorArray()
	for a in alfas:
		cores.append(Color(1, 1, 1, a))
	gr.colors = cores
	var t := GradientTexture2D.new()
	t.gradient = gr
	t.width = tam
	t.height = tam
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


var disco: CanvasTexture
var _disco_rid: RID
var _cores3 := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE])
var _cores4 := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
var _uv_vazio := PackedVector2Array()


func _tri(ci: RID, p1: Vector2, p2: Vector2, p3: Vector2, col: Color) -> void:
	_cores3.fill(col)
	RenderingServer.canvas_item_add_primitive(ci, PackedVector2Array([p1, p2, p3]), _cores3, _uv_vazio, RID())


# polígono convexo em leque de quads/triângulos (primitivas agrupadas);
# as cores já vêm de cor(), com o modo de blend codificado
func poligono_convexo(pts: PackedVector2Array, cores: PackedColorArray) -> void:
	if alvo == null or pts.size() < 3:
		return
	var ci := _seg()
	var i := 1
	while i + 1 < pts.size():
		if i + 2 < pts.size():
			RenderingServer.canvas_item_add_primitive(ci, PackedVector2Array([pts[0], pts[i], pts[i + 1], pts[i + 2]]),
				PackedColorArray([cores[0], cores[i], cores[i + 1], cores[i + 2]]), _uv_vazio, RID())
			i += 2
		else:
			RenderingServer.canvas_item_add_primitive(ci, PackedVector2Array([pts[0], pts[i], pts[i + 1]]),
				PackedColorArray([cores[0], cores[i], cores[i + 1]]), _uv_vazio, RID())
			i += 1


# v1.19: a língua de fogo (gota de 5 pontos: base, barriga e ponta) num caminho
# rápido: arrays reaproveitados, sem montar PackedArrays novos a cada chama
# (o incêndio da vila desenha centenas por quadro). Cores já vêm de cor().
var _g_q := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _g_qc := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
var _g_t := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _g_tc := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK])


func gota(bx: float, by: float, w: float, h: float, lean: float, cbase: Color, cbarriga: Color, cponta: Color) -> void:
	if alvo == null:
		return
	var ci := _seg()
	var yb := by - h * 0.28
	var xb := bx + lean * 0.18
	var b0 := Vector2(bx - w * 0.9, by)
	var tp := Vector2(bx + lean, by - h)
	_g_q[0] = b0
	_g_q[1] = Vector2(bx + w * 0.9, by)
	_g_q[2] = Vector2(xb + w, yb)
	_g_q[3] = tp
	_g_qc[0] = cbase
	_g_qc[1] = cbase
	_g_qc[2] = cbarriga
	_g_qc[3] = cponta
	RenderingServer.canvas_item_add_primitive(ci, _g_q, _g_qc, _uv_vazio, RID())
	_g_t[0] = b0
	_g_t[1] = tp
	_g_t[2] = Vector2(xb - w, yb)
	_g_tc[0] = cbase
	_g_tc[1] = cponta
	_g_tc[2] = cbarriga
	RenderingServer.canvas_item_add_primitive(ci, _g_t, _g_tc, _uv_vazio, RID())


func _contorno(ci: RID, pts: PackedVector2Array, col: Color) -> void:
	for i in pts.size() - 1:
		RenderingServer.canvas_item_add_line(ci, pts[i], pts[i + 1], col, 1.0)


func comecar(a: Alvo) -> void:
	alvo = a
	a.limpar()
	_tem_seg = false


func terminar() -> void:
	alvo = null
	_tem_seg = false


func _seg() -> RID:
	if _tem_seg and _seg_filtro == filtro:
		return _seg_rid
	var a := alvo
	var rid: RID
	var i := a.usados
	if i < a.segs.size():
		rid = a.segs[i]
		if a.filtros[i] != filtro:
			RenderingServer.canvas_item_set_default_texture_filter(rid, FILTRO_SUAVE if filtro else RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
			a.filtros[i] = filtro
	else:
		rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(rid, a.raiz)
		RenderingServer.canvas_item_set_draw_index(rid, i)
		RenderingServer.canvas_item_set_material(rid, mat.get_rid())
		RenderingServer.canvas_item_set_default_texture_filter(rid, FILTRO_SUAVE if filtro else RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
		a.segs.append(rid)
		a.filtros.append(filtro)
	a.usados += 1
	_seg_rid = rid
	_seg_filtro = filtro
	_tem_seg = true
	return rid


# a cor final leva o modo no alfa: 0..1 normal, +2 aditivo, +4 fog
func cor(c: Color, a: float) -> Color:
	var aa := clampf(a, 0.0, 1.0) + (2.0 if blend_add else 0.0)
	if fog:
		return Color(fog_cor.r, fog_cor.g, fog_cor.b, aa + 4.0)
	return Color(c.r, c.g, c.b, aa)


# ---------------------------------------------------------------------
# PRIMITIVAS
# ---------------------------------------------------------------------
func retangulo(x1: float, y1: float, x2: float, y2: float, c: Color, a: float, contorno: bool) -> void:
	if alvo == null or a <= 0.0:
		return
	var ci := _seg()
	var col := cor(c, a)
	var l := minf(x1, x2)
	var t := minf(y1, y2)
	var r := maxf(x1, x2)
	var b := maxf(y1, y2)
	if contorno:
		_contorno(ci, PackedVector2Array([Vector2(l + 0.5, t + 0.5), Vector2(r + 0.5, t + 0.5), Vector2(r + 0.5, b + 0.5), Vector2(l + 0.5, b + 0.5), Vector2(l + 0.5, t)]), col)
	else:
		RenderingServer.canvas_item_add_rect(ci, Rect2(l, t, r - l + 1.0, b - t + 1.0), col)


func retangulo_cores(x1: float, y1: float, x2: float, y2: float, c1: Color, c2: Color, c3: Color, c4: Color, a: float) -> void:
	# c1 topo-esq, c2 topo-dir, c3 base-dir, c4 base-esq
	if alvo == null or a <= 0.0 or x2 < x1 or y2 < y1:
		return
	var ci := _seg()
	var pts := PackedVector2Array([Vector2(x1, y1), Vector2(x2 + 1, y1), Vector2(x2 + 1, y2 + 1), Vector2(x1, y2 + 1)])
	var cs := PackedColorArray([cor(c1, a), cor(c2, a), cor(c3, a), cor(c4, a)])
	RenderingServer.canvas_item_add_primitive(ci, pts, cs, _uv_vazio, RID())


func linha(x1: float, y1: float, x2: float, y2: float, c: Color, a: float, w := 1.0) -> void:
	if alvo == null or a <= 0.0:
		return
	var ci := _seg()
	RenderingServer.canvas_item_add_line(ci, Vector2(x1, y1), Vector2(x2, y2), cor(c, a), maxf(0.5, w))


# muitos segmentos numa chamada só (chuva): pts em pares, uma cor por segmento
# (as cores já devem vir de cor(), com o modo de blend codificado)
func multilinha(pts: PackedVector2Array, cores_seg: PackedColorArray, w: float) -> void:
	if alvo == null or pts.size() < 2:
		return
	RenderingServer.canvas_item_add_multiline(_seg(), pts, cores_seg, w)


func circulo(x: float, y: float, r: float, c: Color, a: float, contorno: bool) -> void:
	if alvo == null or a <= 0.0 or r <= 0.0:
		return
	var ci := _seg()
	var col := cor(c, a)
	if not contorno:
		RenderingServer.canvas_item_add_texture_rect(ci, Rect2(x - r, y - r, r * 2.0, r * 2.0), _disco_rid, false, col)
		return
	var n := clampi(int(r * 0.75), 6, 32)
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in n + 1:
		var ang := TAU * i / n
		pts[i] = Vector2(x + cos(ang) * r, y + sin(ang) * r)
	_contorno(ci, pts, col)


func elipse(x1: float, y1: float, x2: float, y2: float, c: Color, a: float, contorno: bool) -> void:
	if alvo == null or a <= 0.0:
		return
	var cx := (x1 + x2) * 0.5
	var cy := (y1 + y2) * 0.5
	var rx := absf(x2 - x1) * 0.5
	var ry := absf(y2 - y1) * 0.5
	if rx <= 0.01 or ry <= 0.01:
		return
	var ci := _seg()
	var col := cor(c, a)
	if not contorno:
		RenderingServer.canvas_item_add_texture_rect(ci, Rect2(cx - rx, cy - ry, rx * 2.0, ry * 2.0), _disco_rid, false, col)
		return
	var n := clampi(int(maxf(rx, ry) * 0.75), 6, 32)
	var pts := PackedVector2Array()
	pts.resize(n + 1)
	for i in n + 1:
		var ang := TAU * i / n
		pts[i] = Vector2(cx + cos(ang) * rx, cy + sin(ang) * ry)
	_contorno(ci, pts, col)


func triangulo(x1: float, y1: float, x2: float, y2: float, x3: float, y3: float, c: Color, a: float, contorno: bool) -> void:
	if alvo == null or a <= 0.0:
		return
	var ci := _seg()
	var col := cor(c, a)
	if contorno:
		_contorno(ci, PackedVector2Array([Vector2(x1, y1), Vector2(x2, y2), Vector2(x3, y3), Vector2(x1, y1)]), col)
		return
	_tri(ci, Vector2(x1, y1), Vector2(x2, y2), Vector2(x3, y3), col)


func retangulo_arredondado(x1: float, y1: float, x2: float, y2: float, rx: float, ry: float, c: Color, a: float, contorno: bool) -> void:
	if alvo == null or a <= 0.0:
		return
	var l := minf(x1, x2)
	var t := minf(y1, y2)
	var r := maxf(x1, x2)
	var b := maxf(y1, y2)
	rx = minf(rx, (r - l) * 0.5)
	ry = minf(ry, (b - t) * 0.5)
	if rx <= 0.01 or ry <= 0.01:
		retangulo(l, t, r, b, c, a, contorno)
		return
	var ci := _seg()
	var col := cor(c, a)
	var pts := PackedVector2Array()
	var cantos := [[r - rx, t + ry, -90.0], [r - rx, b - ry, 0.0], [l + rx, b - ry, 90.0], [l + rx, t + ry, 180.0]]
	for k in cantos:
		for i in 7:
			var ang: float = deg_to_rad(k[2] + i * 15.0)
			pts.append(Vector2(k[0] + cos(ang) * rx, k[1] + sin(ang) * ry))
	if contorno:
		pts.append(pts[0])
		_contorno(ci, pts, col)
		return
	var n := pts.size()
	var vs := PackedVector2Array([Vector2((l + r) * 0.5, (t + b) * 0.5)])
	vs.append_array(pts)
	var ids := PackedInt32Array()
	for i in n:
		ids.append(0)
		ids.append(i + 1)
		ids.append((i + 1) % n + 1)
	var cs := PackedColorArray()
	cs.resize(n + 1)
	cs.fill(col)
	RenderingServer.canvas_item_add_triangle_array(ci, ids, vs, cs)


func prim_comecar(tipo: int) -> void:
	_prim_tipo = tipo
	_prim_pts.clear()
	_prim_cores.clear()


func prim_vertice(x: float, y: float, c: Color, a: float) -> void:
	_prim_pts.append(Vector2(x, y))
	_prim_cores.append(cor(c, a))


func prim_terminar() -> void:
	if alvo == null or _prim_pts.size() < 3:
		return
	# cada triângulo vira uma primitiva (agrupada pelo renderizador)
	var ci := _seg()
	var pp := _prim_pts
	var cc := _prim_cores
	if _prim_tipo == PR_TRIANGLESTRIP:
		for i in pp.size() - 2:
			RenderingServer.canvas_item_add_primitive(ci, PackedVector2Array([pp[i], pp[i + 1], pp[i + 2]]),
				PackedColorArray([cc[i], cc[i + 1], cc[i + 2]]), _uv_vazio, RID())
	else:
		var j := 0
		while j + 2 < pp.size():
			RenderingServer.canvas_item_add_primitive(ci, PackedVector2Array([pp[j], pp[j + 1], pp[j + 2]]),
				PackedColorArray([cc[j], cc[j + 1], cc[j + 2]]), _uv_vazio, RID())
			j += 3


# ---------------------------------------------------------------------
# SPRITES
# ---------------------------------------------------------------------
# v1.14: ESPELHAR COMO O GAMEMAKER. Com tamanho negativo o Godot espelha a
# textura, mas continua desenhando a partir da posição dada para a direita/baixo;
# no GameMaker o desenho espelhado vai para o OUTRO lado da posição. Sem esta
# correção todo sprite virado para a esquerda saía deslocado a largura inteira
# do desenho (o herói e os inimigos "teletransportavam" ao virar, e os inimigos
# ficavam longe da própria caixa de colisão).
static func _ret(x: float, y: float, w: float, h: float) -> Rect2:
	if w < 0.0:
		x += w
	if h < 0.0:
		y += h
	return Rect2(x, y, w, h)


func sprite(s: GMSprite, img: float, x: float, y: float, xs: float, ys: float, rot: float, c: Color, a: float) -> void:
	if alvo == null or s == null or a <= 0.0:
		return
	var t := s.tex(int(floor(img)))
	if t == null:
		return
	var ci := _seg()
	var m := cor(c, a)
	if rot == 0.0:
		RenderingServer.canvas_item_add_texture_rect(ci, _ret(x - s.xo * xs, y - s.yo * ys, s.w * xs, s.h * ys), t.get_rid(), false, m)
	else:
		RenderingServer.canvas_item_add_set_transform(ci, Transform2D(-deg_to_rad(rot), Vector2(xs, ys), 0.0, Vector2(x, y)))
		RenderingServer.canvas_item_add_texture_rect(ci, Rect2(-s.xo, -s.yo, s.w, s.h), t.get_rid(), false, m)
		RenderingServer.canvas_item_add_set_transform(ci, Transform2D.IDENTITY)


func sprite_parte(s: GMSprite, img: float, l: float, t: float, w: float, h: float, x: float, y: float, xs: float, ys: float, c: Color, a: float) -> void:
	if alvo == null or s == null or a <= 0.0 or w <= 0.0 or h <= 0.0:
		return
	var tx := s.tex(int(floor(img)))
	if tx == null:
		return
	var ci := _seg()
	RenderingServer.canvas_item_add_texture_rect_region(ci, _ret(x, y, w * xs, h * ys), tx.get_rid(), Rect2(l, t, w, h), cor(c, a))


# região (l, t, w, h) de uma textura solta (atlas); xs negativo espelha
func textura_parte(tx: Texture2D, l: float, t: float, w: float, h: float, x: float, y: float, xs: float, ys: float, c: Color, a: float) -> void:
	if alvo == null or tx == null or a <= 0.0 or w <= 0.0 or h <= 0.0:
		return
	RenderingServer.canvas_item_add_texture_rect_region(_seg(), _ret(x, y, w * xs, h * ys), tx.get_rid(), Rect2(l, t, w, h), cor(c, a))


func textura(tx: Texture2D, x: float, y: float, w: float, h: float, c: Color, a: float) -> void:
	if alvo == null or tx == null or a <= 0.0:
		return
	RenderingServer.canvas_item_add_texture_rect(_seg(), _ret(x, y, w, h), tx.get_rid(), false, cor(c, a))


# ---------------------------------------------------------------------
# TEXTO
# ---------------------------------------------------------------------
static func _tam(em: float, esc: float, k: float) -> int:
	# v1.18: TRAVADAS — cada tamanho em pixels é uma rasterização nova dos glifos
	# (cache de fonte). Textos que crescem/encolhem (títulos, CRÍTICO!, números)
	# criavam dezenas de tamanhos. Acima de 16 px o tamanho anda em degraus; o
	# fator k de quem chama compensa, então o tamanho na tela não muda.
	var t := em * esc * k
	if t <= 16.0:
		return maxi(1, int(round(t)))
	if t <= 48.0:
		return int(round(t / 2.0)) * 2
	return int(round(t / 4.0)) * 4


func texto(x: float, y: float, s: String, f: Font, em: float, c: Color, a: float, ha: int, va: int, esc: float) -> void:
	if alvo == null or s == "" or a <= 0.0 or esc <= 0.0:
		return
	var ci := _seg()
	var tam := _tam(em, esc, escala_texto)
	var k := (em * esc) / float(tam)
	var col := cor(c, a)
	var linhas := s.split("\n")
	var lh := f.get_height(tam) * k
	var asc := f.get_ascent(tam)
	var total := lh * linhas.size()
	var y0 := y
	if va == MEIO:
		y0 = y - total * 0.5
	elif va == BASE:
		y0 = y - total
	for i in linhas.size():
		var ln: String = linhas[i]
		var w := (_larg_linha(ln, f, tam) * k) if ha != ESQ else 0.0
		var x0 := x
		if ha == CENTRO:
			x0 = x - w * 0.5
		elif ha == DIR:
			x0 = x - w
		RenderingServer.canvas_item_add_set_transform(ci, Transform2D(0.0, Vector2(k, k), 0.0, Vector2(x0, y0 + i * lh)))
		f.draw_string(ci, Vector2(0, asc), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)
	RenderingServer.canvas_item_add_set_transform(ci, Transform2D.IDENTITY)


func texto_bloco(x: float, y: float, s: String, f: Font, em: float, c: Color, a: float, largura: float, ha: int, va: int) -> void:
	if alvo == null or s == "" or a <= 0.0:
		return
	var ci := _seg()
	var tam := _tam(em, 1.0, escala_texto)
	var k := em / float(tam)
	var larg_f := largura / k
	var al := HORIZONTAL_ALIGNMENT_LEFT
	var x0 := x
	if ha == CENTRO:
		al = HORIZONTAL_ALIGNMENT_CENTER
		x0 = x - largura * 0.5
	elif ha == DIR:
		al = HORIZONTAL_ALIGNMENT_RIGHT
		x0 = x - largura
	var y0 := y
	if va != TOPO:
		var hh := f.get_multiline_string_size(s, al, larg_f, tam).y * k
		y0 = y - (hh * 0.5 if va == MEIO else hh)
	RenderingServer.canvas_item_add_set_transform(ci, Transform2D(0.0, Vector2(k, k), 0.0, Vector2(x0, y0)))
	f.draw_multiline_string(ci, Vector2(0, f.get_ascent(tam)), s, al, larg_f, tam, -1, cor(c, a))
	RenderingServer.canvas_item_add_set_transform(ci, Transform2D.IDENTITY)


# medir texto é caro (o HUD e os menus medem as mesmas frases todo quadro)
static var _cache_larg := {}


static func _larg_linha(ln: String, f: Font, tam: int) -> float:
	var chave := "%d|%d|%s" % [f.get_instance_id(), tam, ln]
	var v = _cache_larg.get(chave)
	if v == null:
		if _cache_larg.size() > 4000:
			_cache_larg.clear()
		v = f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		_cache_larg[chave] = v
	return v


static func largura_texto(s: String, f: Font, em: float, esc: float) -> float:
	if s == "":
		return 0.0
	var tam := _tam(em, esc, 1.0)
	var k := (em * esc) / float(tam)
	if not s.contains("\n"):
		return _larg_linha(s, f, tam) * k
	var maior := 0.0
	for ln in s.split("\n"):
		maior = maxf(maior, _larg_linha(ln, f, tam) * k)
	return maior


static func altura_texto(s: String, f: Font, em: float, esc: float) -> float:
	var tam := _tam(em, esc, 1.0)
	var k := (em * esc) / float(tam)
	return f.get_height(tam) * k * maxi(1, s.split("\n").size())


static func altura_bloco(s: String, f: Font, em: float, largura: float) -> float:
	var tam := _tam(em, 1.0, 1.0)
	var k := em / float(tam)
	return f.get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, largura / k, tam).y * k
