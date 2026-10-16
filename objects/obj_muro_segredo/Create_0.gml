// =====================================================================
//  obj_muro_segredo — muro rachado AO FUNDO (não bloqueia o caminho)
//  Quebrado com golpes, revela um esconderijo com orbs.
// =====================================================================
event_inherited();            // obj_parede_quebravel (cria o bloco sólido)
solido_remover(solido);       // este fica ao fundo: não é sólido
solido = noone;
sprite_index = spr_muro_segredo;
segredo = true;
vida = 5;
vida_max = 5;
orbs_valor = ORBS_SEGREDO;
image_blend = make_color_rgb(150, 140, 138);   // mais escuro: fica "ao fundo"
