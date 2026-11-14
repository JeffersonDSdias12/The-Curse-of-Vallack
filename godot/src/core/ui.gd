class_name UI
extends RefCounted
# =====================================================================
#  UI — arte da interface (SVGs em assets/ui) e a paleta do HUD
#  Ícones são silhuetas brancas: o jogo tinge com a cor que quiser.
# =====================================================================

const ACAO := GMObj.ACAO

const OURO := Color8(217, 181, 106)
const OURO_CLARO := Color8(247, 226, 168)
const OURO_ESCURO := Color8(122, 84, 34)
const MARFIM := Color8(242, 230, 204)
const FERRO := Color8(20, 14, 15)

const ARTES := ["aro", "aro_grande", "base", "brilho", "brasao", "brasao_fundo", "bussola", "dpad", "joy_base", "joy_pino",
	"ic_ataque", "ic_pesado", "ic_pulo", "ic_esquiva", "ic_defesa", "ic_rasteira", "ic_tremor", "ic_onda",
	"ic_queda", "ic_furia", "ic_acao", "ic_pausa", "ic_armas"]

static var _cache := {}


static func tex(nome: String) -> Texture2D:
	var t = _cache.get(nome)
	if t == null:
		t = load("res://assets/ui/%s.svg" % nome)
		_cache[nome] = t
	return t


# carrega tudo no início (sem engasgo na primeira vez que um botão aparece)
static func precarregar() -> void:
	for n in ARTES:
		tex(n)


static func icone(acao: int) -> String:
	match acao:
		ACAO.ATACAR:
			return "ic_ataque"
		ACAO.ATAQUE_FORTE:
			return "ic_pesado"
		ACAO.PULAR:
			return "ic_pulo"
		ACAO.ESQUIVA:
			return "ic_esquiva"
		ACAO.DEFENDER:
			return "ic_defesa"
		ACAO.ATAQUE_SALTO:
			return "ic_rasteira"
		ACAO.ESPECIAL_3:
			return "ic_tremor"
		ACAO.ESPECIAL:
			return "ic_onda"
		ACAO.ESPECIAL_2:
			return "ic_queda"
		ACAO.FURIA:
			return "ic_furia"
		ACAO.INTERAGIR:
			return "ic_acao"
	return "ic_acao"
