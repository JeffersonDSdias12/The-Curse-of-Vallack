// =====================================================================
//  obj_frasco_veneno — frasco do Esqueleto Alquimista (v1.12)
//  Voa em arco. O veneno atravessa a defesa: só a esquiva escapa (rolando,
//  o frasco passa por Twilight). No chão, vira uma poça de veneno.
// =====================================================================
vx = 0;
vy = 0;
g = 0.25;
dano = 6;
ang = 0;
t = 0;
estourar = function()
{
    var _cy = chao_abaixo(x, y - 24, 220);
    var _pc = instance_create_depth(x, _cy, 140, obj_poca_veneno);
    som_em("veneno_poca", x, y, 0.8);
    repeat (6)
    {
        var _f = instance_create_depth(x + random_range(-8, 8), y - 6, -100, obj_fagulha);
        _f.cor = choose(make_color_rgb(120, 230, 80), make_color_rgb(70, 170, 50));
    }
    instance_destroy();
};
