// =====================================================================
//  obj_caixote — caixote de madeira (32 x 32)
//  * quebra com golpes (2 golpes normais ou 1 pesado/especial)
//  * jogador e inimigos sobem e andam em cima (bloco sólido)
//  * pode guardar orbs ou esconder um BAÚ DE VIDA (obj_bau no mesmo lugar)
//  * cai se o que está embaixo quebrar
// =====================================================================
event_inherited();
vida = 2;
vida_max = 2;
sprite_index = spr_caixote;
image_speed = 0;
image_index = 0;
// conteúdo: o baú escondido é ligado no primeiro quadro (scr_cenario)
conteudo = choose("nada", "nada", "orbs");
orbs_valor = irandom_range(6, 14);
bau = noone;
ligado = false;
velv = 0;
var _l = bbox_left;
var _t = bbox_top;
var _r = bbox_right + 1;
var _b = bbox_bottom + 1;
solido = solido_criar(_l, _t, _r, _b);
dx_solido = _l - x;
dy_solido = _t - y;

ao_bater = function(_forca)
{
    image_index = 1;          // rachado
    som_em("dest_quique", x, y, 0.7);            // pancada (rachou)
    fx_em("lascas", x, y - 16, 0.45, lado_golpe);
};
ao_quebrar = function(_lado) { caixote_quebrar(_lado); };
