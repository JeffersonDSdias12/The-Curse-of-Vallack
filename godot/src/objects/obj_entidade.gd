class_name ObjEntidade
extends Lib
# =====================================================================
#  obj_entidade — física e colisão com o chão (jogador e inimigos)
# =====================================================================

var velh := 0.0     # velocidade horizontal (pixels por quadro de 60 FPS)
var velv := 0.0     # velocidade vertical
var vel := 3.0      # velocidade base
var grav := 0.25    # gravidade (acumula a cada quadro)
var hs_on := false  # animação congelada pelo impacto / câmera lenta
var hs_vel := 1.0
# v1.14: velocidade de ANDAR (velh_para): acelera, freia e, para virar de lado,
# passa pelo zero; o empurrão e a separação somam por cima sem acumular
var anda_v := 0.0
var anda_vivo := false       # velh_para foi chamado neste quadro
var anda_vivo_ant := false   # ... e no quadro anterior (senão parte do zero)

func ev_create() -> void:
	velh = 0
	velv = 0
	vel = 3
	grav = 0.25


# v1.14: o ANDAR obedece a velocidade (velh). Em vez de trocar +v por -v num
# quadro (o corpo "teletransportava" ao virar), a velocidade de andar sobe com
# acel e cai com frear por quadro de 60 FPS; para virar ela freia até zero e
# só então acelera para o outro lado.
func velh_para(alvo: float, acel: float, frear: float) -> void:
	# sem andar no quadro anterior (golpe, esquiva, empurrão): parte do velh atual,
	# limitado à velocidade de andar (a esquiva emenda na corrida sem tranco)
	var v := anda_v if anda_vivo_ant else clampf(velh, -absf(alvo), absf(alvo))
	var a := frear if ((v != 0 and signf(alvo) != signf(v)) or absf(alvo) < absf(v)) else acel
	a *= G.dt
	v = minf(v + a, alvo) if v < alvo else maxf(v - a, alvo)
	anda_v = v
	anda_vivo = true
	velh = v


# Golpe recebido (o jogador e os inimigos implementam)
func levar_dano(_dano: float, _origem_x = null, _bloqueavel := true, _forca := 4.0, _atacante = null, _golpe = null) -> void:
	pass


# ===== COLISÃO COM O CHÃO — End Step =====
# Move pixel a pixel até encostar, nunca "teleporta" para a ponta do bloco.
func ev_step_end() -> void:
	var dt := G.dt
	# 0) Rede de segurança: se ficou dentro do chão/parede, sai pelo caminho mais curto
	if place_meeting(x, y, "obj_chao"):
		var livre := false
		for i in range(1, 17):
			if not place_meeting(x, y - i, "obj_chao"):
				y -= i
				livre = true
				break
		if not livre:
			for i in range(1, 25):
				if not place_meeting(x - i, y, "obj_chao"):
					x -= i
					livre = true
					break
				elif not place_meeting(x + i, y, "obj_chao"):
					x += i
					livre = true
					break
		var saida := 0
		while not livre and place_meeting(x, y, "obj_chao") and saida < 200:
			y -= 1
			saida += 1
	velv = minf(velv, 12)
	var no_chao := velv >= 0 and (place_meeting(x, y + 1, "obj_chao") or plataforma_sob_pes() != null)
	# 1) Movimento horizontal
	var mh := velh * dt
	if place_meeting(x + mh, y, "obj_chao"):
		# v1.13: degrau baixo (escadaria) é subido andando, sem pular
		var sobe := 0
		if no_chao and mh != 0:
			for d in range(1, DEGRAU_MAX + 1):
				if not place_meeting(x + mh, y - d, "obj_chao"):
					sobe = d
					break
		if sobe > 0:
			y -= sobe
			x += mh
		else:
			var ph := signf(mh)
			var seg := 0
			while ph != 0 and not place_meeting(x + ph, y, "obj_chao") and seg < 64:
				x += ph
				seg += 1
			velh = 0
			anda_v = 0              # bateu na parede: o passo morre aqui
	else:
		x += mh
	# 2) Movimento vertical
	var mv := velv * dt
	var pl = plataforma_pouso(mv)        # v1.13: herói caindo sobre uma plataforma de mão única
	if pl != null and not place_meeting(x, pl.y, "obj_chao"):
		y = pl.y
		velv = 0
	elif place_meeting(x, y + mv, "obj_chao"):
		var pv := signf(mv)
		var seg2 := 0
		while pv != 0 and not place_meeting(x, y + pv, "obj_chao") and seg2 < 64:
			y += pv
			seg2 += 1
		velv = 0
	else:
		y += mv
	# 3) descendo a escadaria: fica colado nos degraus em vez de "cair" a cada um
	if no_chao and velv >= 0 and not place_meeting(x, y + 1, "obj_chao") and plataforma_sob_pes() == null:
		for d in range(2, DEGRAU_MAX + 2):
			if place_meeting(x, y + d, "obj_chao"):
				y += d - 1
				velv = 0
				break
	anda_vivo_ant = anda_vivo
	anda_vivo = false
