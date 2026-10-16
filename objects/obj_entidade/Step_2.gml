// ===== COLISÃO COM O CHÃO (jogador e inimigos) — End Step =====
// Move pixel a pixel até encostar, nunca "teleporta" para a ponta do bloco.
// Velocidades são em quadros de 60 FPS e multiplicadas por global.dt.
var _dt = global.dt;

// 0) Rede de segurança: se ficou dentro do chão/parede, sai pelo caminho mais curto
if (place_meeting(x, y, obj_chao))
{
    var _livre = false;
    for (var _i = 1; _i <= 16 and !_livre; _i++)
    {
        if (!place_meeting(x, y - _i, obj_chao)) { y -= _i; _livre = true; }
    }
    for (var _i = 1; _i <= 24 and !_livre; _i++)
    {
        if (!place_meeting(x - _i, y, obj_chao)) { x -= _i; _livre = true; }
        else if (!place_meeting(x + _i, y, obj_chao)) { x += _i; _livre = true; }
    }
    var _saida = 0;
    while (!_livre and place_meeting(x, y, obj_chao) and _saida < 200) { y -= 1; _saida += 1; }
}

velv = min(velv, 12);   // velocidade terminal de queda

// 1) Movimento horizontal
var _mh = velh * _dt;
if (place_meeting(x + _mh, y, obj_chao))
{
    var _ph = sign(_mh);
    var _seg = 0;
    while (_ph != 0 and !place_meeting(x + _ph, y, obj_chao) and _seg < 64) { x += _ph; _seg += 1; }
    velh = 0;
}
else x += _mh;

// 2) Movimento vertical
var _mv = velv * _dt;
if (place_meeting(x, y + _mv, obj_chao))
{
    var _pv = sign(_mv);
    var _seg2 = 0;
    while (_pv != 0 and !place_meeting(x, y + _pv, obj_chao) and _seg2 < 64) { y += _pv; _seg2 += 1; }
    velv = 0;
}
else y += _mv;
