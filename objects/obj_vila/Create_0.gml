// =====================================================================
//  obj_vila — a vila em chamas ao fundo da Fase 1
//  As casas do cenário de fundo pegam fogo: chamas no telhado, janelas
//  acesas pelo incêndio, brilho alaranjado e fumaça subindo. Quando Twilight
//  se aproxima, aldeões saem correndo. O som do fogo aumenta perto.
//  Criado pelo sala_preparar() logo à frente do fundo (profundidade 398).
// =====================================================================
chao_y = chao_da_sala();      // -1 = chão ainda desativado: o Step mede de novo
// casas do desenho de fundo que estão queimando:
// x = centro do telhado, y = cumeeira, l = largura, f = aldeões que fogem
casas = [];
var _lista = [
    [300, 460, 120, 2], [540, 492, 140, 1], [940, 472, 90, 0], [1765, 462, 120, 2], [1885, 472, 100, 1],
    [2380, 468, 120, 2], [2725, 492, 150, 1], [3440, 502, 110, 2], [3680, 488, 110, 1], [3960, 458, 110, 0],
    [4560, 472, 110, 0], [4680, 458, 110, 0]
];
for (var _i = 0; _i < array_length(_lista); _i++)
{
    var _c = _lista[_i];
    array_push(casas, { x: _c[0], y: _c[1], l: _c[2], fogem: _c[3], fugiram: 0, fumaca: random(20), semente: random(100) });
}
aldeao_t = 0;
