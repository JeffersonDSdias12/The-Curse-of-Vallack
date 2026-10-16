// =====================================================================
//  obj_inimigo_base — pai de todos os inimigos (01, 02 e boss)
//  * herda a física/colisão do obj_entidade
//  * os golpes do jogador procuram por este objeto
//  * a fase 2 termina quando não resta nenhuma instância dele
// =====================================================================
event_inherited();
globais_iniciar();

ativo = true;            // false = ainda escondido (inimigo 01 surge de um portal)
morrendo = false;
morte_fim = false;
morte_tempo = 0;
// v1.10: depois de morrer, o corpo evapora numa fumaça negra amaldiçoada e some
morte_t = 0;             // quadros desde a morte
evaporar = 0;            // 0 = corpo inteiro · 1 = sumiu na fumaça
evaporar_fx = 0;         // espera até o próximo sopro de fumaça
evaporar_tam = 0;        // tamanho da fumaça (0 = pelo tamanho da máscara; chefes usam maior)
eh_boss = false;
invocado = false;        // criado por invocação do boss

vida = 1;
vida_max = 1;
vida_atraso = 1;
tempo_invencivel = 0;
barra_tempo = 0;
flash_dano = 0;
empurrao = 0;
dir = -1;

// atordoamento (scr_dano)
atordoado = 0;
atordoado_anim = 0;
atordoado_acumulado = 0;
imune_atordoar = 0;
libertou_fx = 0;
estado_ia = "parado";
golpe_dado = false;
som_golpe_tocou = false;   // som do golpe (uma vez por ataque)
recarga = 0;

// v1.4: aparar, finalizador, escudo e falas
finalizavel = false;     // atordoado e fraco (ou aparado): BOLA perto = finalizador
executando = false;      // preso no finalizador de Twilight
finalizado = false;      // morreu no finalizador (solta mais orbs)
pode_lancar = true;      // golpes que lançam ao ar funcionam nele
aparado_t = 0;           // tempo atordoado depois de ter o golpe aparado
resiste_atordoar = false;// mini-boss: só fica atordoado se aparado ou exausto
escudo_vida = 0;         // inimigo 03: golpes que o escudo ainda aguenta
escudo_max = 0;
escudo_quebrado = false;
escudo_quebrado_t = 0;
escudo_fx = 0;
grav_ia = 0.4;
tremor = 0;

// v1.8: nível, último golpe recebido e defesas próprias
nivel = 1;                    // Nv 1 a 5 (scr_inimigos_novos); os antigos ficam no 1
ultimo_golpe = undefined;     // golpe (struct de scr_combate) do último dano
estado_ao_surgir = "";        // estado da IA ao sair do portal ("" = padrão)

// cada inimigo redefine como reage a um golpe
reagir_dano = function(_dano, _dir, _forca) {};
// golpes que não ferem (ex.: estátua de pedra). true = o golpe foi segurado
bloquear_golpe = function(_golpe, _origem_x) { return false; };
