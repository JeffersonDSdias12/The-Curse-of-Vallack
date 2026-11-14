class_name GMSprite
extends RefCounted
# =====================================================================
#  Sprite do GameMaker: quadros, origem, caixa de colisão e velocidade.
#  As texturas são carregadas só quando usadas pela primeira vez.
# =====================================================================

var nome := ""
var w := 0.0
var h := 0.0
var xo := 0.0
var yo := 0.0
var bl := 0.0
var bt := 0.0
var br := 0.0
var bb := 0.0
var n := 1
var spd := 0.0          # quadros por segundo da animação (image_speed = 1)
var k := 1.0            # escala HD (scr_hd): pixels da sprite por pixel do mundo
var pad := 0            # pixels acrescentados em volta (contorno do tratamento visual)
var _tex: Array = []


func _init(_nome: String, d: Dictionary) -> void:
	nome = _nome
	w = float(d["w"])
	h = float(d["h"])
	xo = float(d["xo"])
	yo = float(d["yo"])
	bl = float(d["bl"])
	bt = float(d["bt"])
	br = float(d["br"])
	bb = float(d["bb"])
	n = maxi(1, int(d["n"]))
	spd = float(d["spd"])
	pad = int(d.get("pad", 0))
	k = float(d.get("k", 1.0))      # o importador da arte grava a escala HD no sprites.json
	_tex.resize(n)


func tex(i: int) -> Texture2D:
	i = posmod(i, n)
	var t = _tex[i]
	if t == null:
		t = load("res://assets/sprites/%s/%d.png" % [nome, i])
		_tex[i] = t
	return t


func precarregar() -> void:
	for i in n:
		tex(i)
