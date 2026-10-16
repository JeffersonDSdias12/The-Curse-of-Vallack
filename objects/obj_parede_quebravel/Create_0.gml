// =====================================================================
//  obj_parede_quebravel — parede de pedra rachada que bloqueia o caminho
//  * golpes normais tiram 1, pesados 2 e especiais 3 (6 no total)
//  * quebrada, libera a passagem (e pode esconder orbs)
//  * fica gravada como quebrada no save
// =====================================================================
event_inherited();
vida = 6;
vida_max = 6;
sprite_index = spr_parede_rachada;
image_speed = 0;
image_index = 0;
segredo = false;           // obj_muro_segredo liga
orbs_valor = 15;
chave = aberto_chave("parede", xstart, ystart);
if (aberto_tem(chave)) { instance_destroy(); exit; }
solido = solido_criar(bbox_left, bbox_top, bbox_right + 1, bbox_bottom + 1);

ao_bater = function(_forca)
{
    image_index = clamp(floor((1 - vida / vida_max) * 3), 0, 2);
    som_em("dest_quique", x, y, 0.8, 0.12);
    fx_em("poeira", x - lado_golpe * 14, y - 40, 0.5, lado_golpe);
    global.camera_impact = max(global.camera_impact, 3);
};
ao_quebrar = function(_lado)
{
    aberto_marcar(chave);
    som_em("dest_pedra", x, y, 1, 0);              // destruição: pedra
    fx_em("entulho", x, y, 1.2, _lado);
    fx_em("poeira", x, y, 1.6, _lado);
    global.camera_impact = max(global.camera_impact, 10);
    if (orbs_valor > 0) orbs_soltar(x, y - 40, orbs_valor);
    if (segredo)
    {
        aviso_mostrar("SEGREDO ENCONTRADO!  +" + string(orbs_valor) + " ORBS");
        som("sfx_segredo", 0.8, 0);
    }
    solido_remover(solido);
    solido = noone;
    instance_destroy();
};
