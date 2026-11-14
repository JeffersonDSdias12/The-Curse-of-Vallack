// =====================================================================
//  obj_terreno — ABISMOS mortais, PLATAFORMAS e os CAMINHOS POR CIMA
//  (estilo Castlevania). Criado pelo sala_preparar() nas fases. Abre os
//  vãos no chão, cria os blocos das plataformas, escadas, torres, pontes e
//  ilhas, tira os pedaços de castelo da vila, mata quem cai e desenha tudo (escadas,
//  torre e andaime de madeira, ilhas com as peças do Alex,
//  tábuas de madeira na vila; pedra presa por correntes no castelo). Os
//  dados ficam em terreno_dados() (scr_cenario).
//  Profundidade 280: na frente do chão (300), atrás dos personagens.
// =====================================================================
var _d = terreno_dados(room);
chao_y = _d.chao;
madeira = _d.madeira;
abismos = _d.abismos;
plataformas = _d.plataformas;
escadas = _d.escadas;
blocos = _d.blocos;
pontes = _d.pontes;
ilhas = _d.ilhas;
ruinas = _d.ruinas;
mover = _d.mover;
caixotes = _d.caixotes;
arvores = _d.arvores;
remover = _d.remover;
// v1.14: escadas de mão, cordas e correntes; pontes de corda; plataformas
// penduradas; o baú da chave (arena no alto do forte) e o portão trancado
escalar = _d.escalar;
pontes_corda = _d.pontes_corda;
suspensas = _d.suspensas;
chave_dados = _d.chave;
portao = _d.portao;
// v1.20: pontes que desabam e piso frágil (scr_cenario: quedas_*)
pontes_queda = _d.pontes_queda;
frageis_dados = _d.frageis;
pontes_q = [];
frageis = [];
vaos = [];                            // abismos e pontes em ordem de x (a terra abaixo da sala)
for (var _i = 0; _i < array_length(abismos); _i++) array_push(vaos, abismos[_i]);
for (var _i = 0; _i < array_length(pontes_queda); _i++) array_push(vaos, pontes_queda[_i]);
array_sort(vaos, function(_a, _b) { return _a[0] - _b[0]; });
global.escalaveis = escalar;          // o herói consulta para escalar (obj_player)
global.chave_portao = false;          // a chave do portão (no baú do forte)
global.portao_visto = false;          // o herói já chegou ao portão trancado
global.arena_chave = false;           // os guardiões do baú estão lutando
arena_estado = "espera";              // espera -> luta -> livre
arena_inimigos = [];
bau_chave = noone;
pecas_ok = pecas_carregar();
t = 0;
pronto = false;      // tudo entra no 1º passo, com a sala inteira já criada
