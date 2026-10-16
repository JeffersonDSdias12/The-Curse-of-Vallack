// =====================================================================
//  obj_bola_fogo — projétil do boss (spr_boss_01_bola_de_fogo)
//  Voa até "alcance" e estoura. A explosão só fere o jogador se ele
//  estiver DENTRO da área; fora dela, a bola apenas estoura.
// =====================================================================
vx = 0;
vy = 0;
dano = 18;
alcance = 560;
dist = 0;
explodindo = false;
refletida = false;          // aparada por Twilight: volta contra o boss
raio_explosao = 54;
escala = 1.7;
ang = 0;
sprite_index = spr_boss_01_bola_de_fogo;
image_index = 0;
image_speed = 1.4;
mask_index = spr_hitbox;
image_xscale = 1;
image_yscale = 1;

explodir = function(_pode_ferir)
{
    if (explodindo) return;
    explodindo = true;
    image_index = 7;            // quadros 7-9: explosão
    image_speed = 1.3;
    vx = 0;
    vy = 0;
    var _p = instance_find(obj_player, 0);
    if (_p != noone and point_distance(x, y, _p.x, _p.y) < 500) global.camera_impact = max(global.camera_impact, 7);
    som_em("fogo_explosao", x, y, 0.8);
    if (_pode_ferir and !refletida and _p != noone and !_p.morto)
    {
        var _cy = (_p.bbox_top + _p.bbox_bottom) / 2;
        if (point_distance(x, y, _p.x, _cy) <= raio_explosao + 10)
        {
            with (_p) levar_dano(other.dano, other.x, true, 6);
        }
    }
};
