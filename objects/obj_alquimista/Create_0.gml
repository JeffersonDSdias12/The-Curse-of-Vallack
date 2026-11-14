// =====================================================================
//  obj_alquimista — ESQUELETO ALQUIMISTA (v1.12, filho do arqueiro)
//  Mantém distância e foge como o arqueiro, mas joga FRASCOS DE VENENO em
//  arco. O veneno atravessa a defesa e vira uma poça no chão: é preciso
//  ROLAR. Ele surge no começo da fase para ensinar a esquiva.
// =====================================================================
event_inherited();
cor_ia = make_color_rgb(150, 235, 120);
dano_frasco = max(1, round(6 * dif_dano_inimigo()));
recarga_max = 360;
estado_ao_surgir = "parado";
distancia_surgir = 200;         // só surge quando Twilight chega perto da névoa de veneno
recarga = 30;                   // e joga o primeiro frasco logo depois de surgir
distancia_fuga = 110;           // deixa chegar mais perto antes de fugir (joga mais veneno)
distancia_segura = 240;
disparar = function(_bx, _by, _alvo)
{
    var _f = instance_create_depth(_bx, _by - 6, depth - 1, obj_frasco_veneno);
    _f.dano = dano_frasco;
    var _tx = (_alvo != noone) ? _alvo.x : _bx + dir * 200;
    var _ty = (_alvo != noone) ? _alvo.y - 10 : _by;
    var _tempo = clamp(abs(_tx - _bx) / 5, 30, 64);
    _f.vx = (_tx - _bx) / _tempo;
    _f.vy = (_ty - (_by - 6) - 0.5 * _f.g * _tempo * _tempo) / _tempo;
    som_em("veneno_frasco", x, y, 0.8);
};
