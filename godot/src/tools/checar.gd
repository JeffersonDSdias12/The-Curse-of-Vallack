extends Node
# Ferramenta de desenvolvimento: carrega todos os scripts para achar erros
# de compilação. Uso:
#   godot --headless --path godot res://src/tools/checar.tscn -- checar


func _ready() -> void:
	var falhas := 0
	var total := 0
	for arq in _listar("res://src"):
		if arq.ends_with("checar.gd"):
			continue
		total += 1
		var s = load(arq)
		if s == null or (s is GDScript and not s.can_instantiate()):
			falhas += 1
			print("FALHOU: ", arq)
	print("scripts: ", total, "  com erro: ", falhas)
	get_tree().quit()


func _listar(dir: String) -> Array:
	var r := []
	var d := DirAccess.open(dir)
	if d == null:
		return r
	for f in d.get_files():
		if f.ends_with(".gd"):
			r.append(dir + "/" + f)
	for sub in d.get_directories():
		r.append_array(_listar(dir + "/" + sub))
	return r
