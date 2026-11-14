extends ObjInimigo02
# =====================================================================
#  obj_alquimista — ESQUELETO ALQUIMISTA (v1.12, filho do arqueiro)
#  Mantém distância e foge como o arqueiro, mas joga FRASCOS DE VENENO em
#  arco. O veneno atravessa a defesa e vira uma poça no chão: é preciso
#  ROLAR. Ele surge no começo da fase para ensinar a esquiva.
# =====================================================================

var dano_frasco := 6.0


func ev_create() -> void:
	super()
	cor_ia = Color8(150, 235, 120)
	dano_frasco = maxf(1, round(6 * dif_dano_inimigo()))
	recarga_max = 360
	estado_ao_surgir = "parado"
	distancia_surgir = 200
	recarga = 30
	distancia_fuga = 110
	distancia_segura = 240


func disparar(bx: float, by: float, alvo) -> void:
	var f = instance_create_depth(bx, by - 6, depth - 1, "obj_frasco_veneno")
	f.dano = dano_frasco
	var tx: float = alvo.x if alvo != null else bx + dir * 200
	var ty: float = alvo.y - 10 if alvo != null else by
	var tempo := clampf(absf(tx - bx) / 5.0, 30, 64)
	f.vx = (tx - bx) / tempo
	f.vy = (ty - (by - 6) - 0.5 * f.g * tempo * tempo) / tempo
	som_em("veneno_frasco", x, y, 0.8)
