// =====================================================================
//  obj_clima — TEMPESTADE da Fase 1 (v1.4: chuva mais nítida e intensa)
//  * duas camadas de chuva (longe: fina; perto: grossa e brilhante)
//  * rajadas de vento mudam a inclinação da chuva
//  * relâmpagos com clarão duplo que ilumina a tela, raio com galhos
//    e TROVÃO com atraso (quanto mais perto, mais alto e mais rápido)
//  * som de chuva em loop
//  Criado pelo sala_preparar() na Room1. Desenha no Draw End.
// =====================================================================
chao_y = chao_da_sala();      // -1 = chão ainda desativado: o Step mede de novo
vento = -2.2;
vento_base = -2.2;
rajada = 0;
prox_rajada = irandom_range(240, 600);
var _qtd = [140, 300, 480];
n_gotas = _qtd[clamp(global.cfg_qualidade, 0, 2)];
gotas = [];
respingos = [];
relampago = 0;
relampago_max = 1;
prox_relampago = irandom_range(160, 360);
raio = [];
galhos = [];
trovoes = [];            // [atraso, volume]
t = 0;

nova_gota = function(_em_qualquer_altura)
{
    var _vx = 0, _vy = 0, _vw = 960, _vh = 420;
    if (view_camera[0] != -1)
    {
        _vx = camera_get_view_x(view_camera[0]);
        _vy = camera_get_view_y(view_camera[0]);
        _vw = camera_get_view_width(view_camera[0]);
        _vh = camera_get_view_height(view_camera[0]);
    }
    var _perto = (random(1) < 0.3);       // camada da frente: gotas maiores e mais claras
    return {
        x: _vx - 80 + random(_vw + 200),
        y: _em_qualquer_altura ? _vy + random(_vh) : _vy - random(90),
        vel: _perto ? random_range(14, 18) : random_range(10, 13),
        comp: _perto ? random_range(18, 28) : random_range(9, 15),
        a: _perto ? random_range(0.45, 0.75) : random_range(0.22, 0.42),
        larg: _perto ? 2 : 1,
        perto: _perto
    };
};
for (var _i = 0; _i < n_gotas; _i++) array_push(gotas, nova_gota(true));

// cria um raio com galhos na tela (x da câmera)
raio_criar = function(_vx, _vy, _vw)
{
    raio = [];
    galhos = [];
    var _rx = _vx + random_range(_vw * 0.1, _vw * 0.9);
    var _ry = _vy - 10;
    var _fim = _vy + random_range(140, 240);
    while (_ry < _fim)
    {
        array_push(raio, [_rx, _ry]);
        if (random(1) < 0.3)
        {
            // galho
            var _g = [[_rx, _ry]];
            var _gx = _rx;
            var _gy = _ry;
            var _gd = choose(-1, 1);
            repeat (irandom_range(2, 4))
            {
                _gx += _gd * random_range(8, 18);
                _gy += random_range(8, 16);
                array_push(_g, [_gx, _gy]);
            }
            array_push(galhos, _g);
        }
        _rx += random_range(-18, 18);
        _ry += random_range(10, 22);
    }
    array_push(raio, [_rx, _fim]);
};
