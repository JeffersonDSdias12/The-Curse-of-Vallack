var _dt = global.dt;
t += _dt;
tick -= _dt;
var _x1 = min(x, x + dir * 90) - 16;
var _x2 = max(x, x + dir * 90) + 16;
if (tick <= 0)
{
    tick = 24;
    var _l = ds_list_create();
    var _n = collision_rectangle_list(_x1, y - 46, _x2, y, obj_inimigo_base, false, true, _l, false);
    var _g = { chave: "chama", especial: false, pesado: false, porcento: 0, dano: dano, combo: 0, no_ar: false };
    for (var _i = 0; _i < _n; _i++)
    {
        var _alvo = _l[| _i];
        if (_alvo.morrendo or !_alvo.ativo) continue;
        var _d = max(1, round(dano * espada_dano_mult()));
        with (_alvo)
        {
            levar_dano(_d, other.x, true, 0.5, noone, _g);
            if (!morrendo and !eh_boss) inimigo_atordoar(12);
        }
    }
    ds_list_destroy(_l);
}
if (t >= vida) instance_destroy();
