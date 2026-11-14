extends Node
# =====================================================================
#  Spr — todas as sprites do jogo (os nomes são os mesmos do GameMaker)
# =====================================================================

var spr_aranha_andando: GMSprite
var spr_aranha_ataque: GMSprite
var spr_aranha_parada: GMSprite
var spr_ataque_03: GMSprite
var spr_ataque_2: GMSprite
var spr_ataque_especial_2: GMSprite
var spr_balaustrada: GMSprite
var spr_barril: GMSprite
var spr_bau: GMSprite
var spr_boss_01: GMSprite
var spr_boss_01_atacando: GMSprite
var spr_boss_01_bola_de_fogo: GMSprite
var spr_boss_01_parado: GMSprite
var spr_boss_fogo: GMSprite
var spr_boss_fogo_parado: GMSprite
var spr_boss_fogo_atacando: GMSprite
var spr_caixote: GMSprite
var spr_caverna: GMSprite
var spr_chao: GMSprite
var spr_coluna: GMSprite
var spr_escudo: GMSprite
var spr_espinhos: GMSprite
var spr_esqueleto_andando: GMSprite
var spr_esqueleto_ataque: GMSprite
var spr_esqueleto_correndo: GMSprite
var spr_esqueleto_dano: GMSprite
var spr_esqueleto_morrendo: GMSprite
var spr_esqueleto_parado: GMSprite
var spr_estatua: GMSprite
var spr_estatua_orbe: GMSprite
var spr_fundo: GMSprite
var spr_fundo_fase2: GMSprite
var spr_fundo_hd: GMSprite
var spr_hitbox: GMSprite
var spr_inimigo01_andar: GMSprite
var spr_inimigo01_atacando: GMSprite
var spr_inimigo01_correndo: GMSprite
var spr_inimigo01_morrendo: GMSprite
var spr_inimigo01_parado: GMSprite
var spr_inimigo01_pulando: GMSprite
var spr_inimigo02_atacando: GMSprite
var spr_inimigo02_correndo: GMSprite
var spr_inimigo02_morrendo: GMSprite
var spr_inimigo02_parado: GMSprite
var spr_inimigo02_sofrendo_dano: GMSprite
var spr_lampiao: GMSprite
var spr_lampiao_luz: GMSprite
var spr_level0: GMSprite
var spr_mascara_aranha: GMSprite
var spr_mascara_arqueiro: GMSprite
var spr_mascara_boss: GMSprite
var spr_mascara_esqueleto: GMSprite
var spr_mascara_estatua: GMSprite
var spr_mascara_inimigo: GMSprite
var spr_mascara_player: GMSprite
var spr_mascara_porco: GMSprite
var spr_mato: GMSprite
var spr_mato_normal: GMSprite
var spr_planta: GMSprite
var spr_planta_maldita: GMSprite
var spr_arvore_assombrada: GMSprite
var spr_morador_correndo: GMSprite
var spr_morador_parado: GMSprite
var spr_muralha: GMSprite
var spr_muro_segredo: GMSprite
var spr_nevoa_veneno: GMSprite
var spr_parede_rachada: GMSprite
var spr_pedras: GMSprite
var spr_placa: GMSprite
var spr_player: GMSprite
var spr_player_agaichar: GMSprite
var spr_player_atacar_agaichado: GMSprite
var spr_player_atacar_agaichado_especial: GMSprite
var spr_player_ataque: GMSprite
var spr_player_ataque_ar: GMSprite
# v1.17: escalada e ataques novos (ferramentas/importar_folhas.ps1)
var spr_player_subindo_escada: GMSprite
var spr_player_descendo_escada: GMSprite
var spr_player_pular_e_agarrar_cordas: GMSprite
var spr_player_segurando_e_subindo_cordas: GMSprite
var spr_player_ataque_rapido: GMSprite
var spr_player_ataque_duplo: GMSprite
var spr_player_ataque_triplo: GMSprite
var spr_player_ataque_frenetico: GMSprite
# v1.19: parado, andar e corrida novos (ferramentas/importar_movimento.ps1)
var spr_player_parado: GMSprite
var spr_player_andar: GMSprite
var spr_player_corrida: GMSprite
var spr_player_dano: GMSprite
var spr_player_defendendo: GMSprite
var spr_player_especial: GMSprite
var spr_player_fall: GMSprite
var spr_player_idle: GMSprite
var spr_player_jump: GMSprite
var spr_player_morte: GMSprite
var spr_player_run: GMSprite
var spr_porco_ataque: GMSprite
var spr_porco_correndo: GMSprite
var spr_porco_furia: GMSprite
var spr_porco_invocar: GMSprite
var spr_porco_morrendo: GMSprite
var spr_porco_parado: GMSprite
var spr_porco_roxo: GMSprite
var spr_porco_salto: GMSprite
var spr_portao: GMSprite
var spr_tocha: GMSprite
var spr_tronco: GMSprite
var spr_viga: GMSprite

var todas := {}


func _init() -> void:
	var txt := FileAccess.get_file_as_string("res://assets/data/sprites.json")
	var dados: Dictionary = JSON.parse_string(txt)
	for nome in dados:
		var s := GMSprite.new(nome, dados[nome])
		todas[nome] = s
		set(nome, s)
	_hd_iniciar()


func por_nome(nome: String) -> GMSprite:
	return todas.get(nome)


# ---------------------------------------------------------------------
# scr_hd: texturas em ALTA DEFINIÇÃO dos personagens (desenhadas com 1/k)
# ---------------------------------------------------------------------
func _hd_registrar(s: GMSprite, k: float) -> void:
	s.k = k


# v1.9: iguala o tamanho do corpo entre as animações de um personagem
func _hd_ajustar(s: GMSprite, fator: float) -> void:
	s.k = s.k / fator


# O herói, o homem-porco, a aranha, o esqueleto arqueiro e a árvore vêm do
# importador da arte (ferramentas/importar_arte.ps1, na raiz do projeto), que
# grava a escala HD ("k") e a origem no centro do corpo no sprites.json, na
# mesma escala em todas as animações. Aqui ficam só as sprites antigas.
func _hd_iniciar() -> void:
	# v1.8: novos inimigos (k = 2)
	for s in [spr_esqueleto_parado, spr_esqueleto_andando, spr_esqueleto_correndo, spr_esqueleto_ataque,
			spr_esqueleto_dano, spr_esqueleto_morrendo, spr_porco_parado, spr_porco_correndo,
			spr_porco_ataque, spr_porco_roxo, spr_porco_salto, spr_porco_furia, spr_porco_invocar,
			spr_porco_morrendo, spr_estatua, spr_estatua_orbe]:
		_hd_registrar(s, 2)
	# v1.12: morador da vila (desenhado em 2x)
	_hd_registrar(spr_morador_parado, 2)
	_hd_registrar(spr_morador_correndo, 2)
