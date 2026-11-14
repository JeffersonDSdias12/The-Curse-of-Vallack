extends Node
# Monta o vídeo: um quadro JPG por quadro do Movie Maker (--fixed-fps 24) + o WAV.
# Uso: godot --path videotool --write-movie saida.ogv --fixed-fps 24 -- quadros=<pasta> audio=<wav>

var pasta := ""
var n := 0
var ret: TextureRect


func _ready() -> void:
	var audio := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("quadros="):
			pasta = a.substr(8)
		elif a.begins_with("audio="):
			audio = a.substr(6)
	ret = TextureRect.new()
	ret.set_anchors_preset(Control.PRESET_FULL_RECT)
	ret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ret.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(ret)
	var s := AudioStreamWAV.load_from_file(audio)
	var p := AudioStreamPlayer.new()
	p.stream = s
	add_child(p)
	p.play()
	_mostrar()


func _mostrar() -> void:
	var arq := pasta.path_join("q%04d.jpg" % n)
	if not FileAccess.file_exists(arq):
		get_tree().quit()
		return
	ret.texture = ImageTexture.create_from_image(Image.load_from_file(arq))


func _process(_dt: float) -> void:
	n += 1
	_mostrar()
