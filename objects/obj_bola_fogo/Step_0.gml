var _dt = global.dt;
if (!explodindo)
{
    x += vx * _dt;
    y += vy * _dt;
    dist += sqrt(vx * vx + vy * vy) * _dt;
    ang = point_direction(0, 0, vx, vy);
    if (image_index >= 6.9) image_index = 0;          // voo: quadros 0-6

    var _p = instance_find(obj_player, 0);
    var _intang = false;
    if (_p != noone) with (_p) _intang = jogador_intangivel();
    var _toca = (_p != noone and !_p.morto and !refletida
        and point_in_rectangle(x, y, _p.bbox_left - 6, _p.bbox_top - 6, _p.bbox_right + 6, _p.bbox_bottom + 6));
    // bola de fogo de volta contra o boss
    if (refletida)
    {
        var _b = collision_point(x, y, obj_inimigo_base, false, true);
        if (_b != noone and !_b.morrendo and _b.ativo)
        {
            var _gw = { chave: "fogo", especial: false, pesado: true, porcento: 0, dano: 0, combo: 0 };
            var _dn = _b.eh_boss ? max(1, round(_b.vida_max * 0.04)) : _b.vida_max;
            with (_b) levar_dano(_dn, other.x - other.vx, false, 6, noone, _gw);
            explodir(false);
            exit;
        }
    }
    if (_toca and _intang) _toca = false;
    if (_toca and _p.janela_aparar > 0 and sign(x - _p.x) == _p.facing)
    {
        // APARADA: a bola de fogo volta para a Árvore
        jogador_aparou(noone);
        refletida = true;
        vx = -vx * 1.25;
        vy = -vy * 0.6;
        dist = 0;
        alcance = 900;
    }
    else if (_toca and _p.bloqueando and sign(x - _p.x) == _p.facing)
    {
        jogador_bloqueou(x);          // a defesa mágica segura a bola de fogo
        explodir(false);
    }
    else if (_toca) explodir(true);
    else if (dist >= alcance or position_meeting(x, y + 6, obj_chao) or y > room_height) explodir(true);
}
else
{
    // o quadro 10 da sprite está com defeito (faixas): termina no 9
    if (image_index >= 9.8) instance_destroy();
}
