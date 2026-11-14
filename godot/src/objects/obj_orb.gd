extends Lib
# =====================================================================
#  obj_orb — orb vermelha de alma (solta por inimigos, caixotes e segredos)
#  Salta um pouco e depois voa sozinha até Twilight.
# =====================================================================

var valor := 1.0
var tipo := "alma"           # v1.17: "alma" (vermelha, orbs) ou "vida" (verde, cura ao chegar)
var vx := 0.0
var vy := -3.0
var espera := 20.0
var t := 0.0
var fase := 0.0
var rastro: Array = []


func ev_create() -> void:
	fase = randf() * 100


func _raio() -> float:
	if tipo == "vida":
		return 4.2
	return 5.0 if valor >= 25 else (3.6 if valor >= 5 else 2.4)


func ev_step() -> void:
	var dt := G.dt
	t += dt
	var p = instance_find("obj_player", 0)
	var r := _raio()
	rastro.append([x, y])
	if rastro.size() > 6:
		rastro.remove_at(0)
	if t < espera or p == null or p.morto:
		# pula e quica no chão
		vy += 0.25 * dt
		vx *= pow(0.97, dt)
		if place_meeting(x + vx * dt, y, "obj_chao"):
			vx = -vx * 0.5
		if vy > 0 and position_meeting(x, y + vy * dt + r, "obj_chao"):
			vy = -absf(vy) * 0.45
			if absf(vy) < 0.8:
				vy = 0
		x += vx * dt
		y += vy * dt
		return
	# voa até o peito de Twilight, acelerando
	var tx: float = p.x
	var ty: float = (p.bbox_top + p.bbox_bottom) / 2.0
	var d := point_distance(x, y, tx, ty)
	var v := minf(14, 3 + (t - espera) * 0.25)
	if d <= v * dt + 6:
		if tipo == "vida":
			# v1.17: ORBE DE VIDA: cura Twilight
			p.vida = minf(p.vida_max, p.vida + valor)
			p.cura_fx = maxf(p.cura_fx, 20)
			if G.orb_som_t <= 0:
				som("sfx_cura", 0.4, 0.04)
				G.orb_som_t = 4
			instance_destroy()
			return
		orbs_ganhar(valor)
		# som em sequência sobe de tom (como no God of War)
		if G.orb_som_t <= 0:
			G.orb_seq = mini(G.orb_seq + 1, 10)
			var s = som("sfx_orb", 0.45, 0)
			if s != null:
				G.audio_sound_pitch(s, 1 + G.orb_seq * 0.04)
			G.orb_som_t = 3
		instance_destroy()
		return
	var ang := point_direction(x, y, tx, ty)
	vx = lerpf(vx, lengthdir_x(v, ang), 0.2)
	vy = lerpf(vy, lengthdir_y(v, ang), 0.2)
	x += vx * dt
	y += vy * dt


func ev_draw() -> void:
	var r := _raio()
	var pul := 1 + 0.15 * sin((current_time() / 16.0 + fase) / 5.0)
	var vd := tipo == "vida"      # v1.17: orbe de vida (verde)
	gpu_set_blendmode(bm_add)
	for i in rastro.size():
		var k := (i + 1.0) / rastro.size()
		draw_set_alpha(0.25 * k)
		draw_set_color(Color8(40, 255, 90) if vd else Color8(255, 40, 30))
		draw_circle(rastro[i][0], rastro[i][1], r * k, false)
	draw_set_alpha(0.35)
	draw_set_color(Color8(20, 200, 60) if vd else Color8(220, 20, 20))
	draw_circle(x, y, r * 2.2 * pul, false)
	draw_set_alpha(0.95)
	draw_set_color(Color8(90, 255, 120) if vd else Color8(255, 70, 50))
	draw_circle(x, y, r * pul, false)
	draw_set_color(Color8(220, 255, 220) if vd else Color8(255, 210, 180))
	draw_circle(x - r * 0.25, y - r * 0.25, r * 0.4, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(c_white)
