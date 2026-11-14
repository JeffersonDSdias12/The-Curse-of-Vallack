// =====================================================================
//  obj_barril — barril de madeira (v1.11). Filho do obj_caixote: quebra
//  com golpes, dá para subir nele, cai se perder o apoio e pode guardar
//  orbs (mais vezes que o caixote) ou esconder um baú de vida.
// =====================================================================
event_inherited();
sprite_index = spr_barril;
conteudo = choose("nada", "orbs", "orbs");
orbs_valor = irandom_range(8, 16);
