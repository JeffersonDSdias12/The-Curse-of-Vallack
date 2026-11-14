// =====================================================================
//  obj_vila — o CENÁRIO da Fase 1 (a vila em chamas), desenhado por código
//  A arte vem de ferramentas/gerar_cenario.ps1 (atlas + JSON com as
//  âncoras dos efeitos), a mesma da versão Android. Duas instâncias,
//  criadas pelo sala_preparar():
//   camada "longe" (prof. 405): céu, lua, nuvens, montanhas, floresta e a
//      vila ao longe, com profundidade (parallax)
//   camada "perto" (prof. 396): casas, igreja, torre, ponte, barracas...
//      com o fogo, a fumaça e as janelas presos a cada peça; o muro da
//      frente e o chão
//  O clima de guerra (obj_guerra, 397) fica entre as duas. O som do fogo
//  aumenta perto das casas em chamas, do fogo no chão, das vigas e tochas.
// =====================================================================
camada = "perto";        // o sala_preparar troca para "longe" na instância do fundo
t = 0;
ok = cenario_carregar();
amb_particulas_iniciar();                 // v1.19: fumaça e brasas nativas
part_particles_clear(global.amb_ps);
if (!ok) exit;
pecas = global.cen.pecas;
layout = global.cen.layout;
emissao = array_create(array_length(layout), 0);
// faixa da frente: muro de pedra, cerca e sebes alternados pela fase toda
frente = [];
var _x = -40;
var _k = 0;
while (_x < room_width + 100)
{
    var _h = (_k * 7919 + 13) mod 10;
    var _nome = (_h < 4) ? "muro" : ((_h < 7) ? "cerca" : "sebe");
    array_push(frente, [_nome, _x]);
    _x += pecas[$ _nome].w - ((_nome == "sebe") ? 12 : 0) + ((_h == 9) ? 28 : 0);
    _k += 1;
}
// v1.20: onde a ponte desaba, a ponte pintada do cenário e a cerca da frente saem
vaos = terreno_dados(room).pontes_queda;