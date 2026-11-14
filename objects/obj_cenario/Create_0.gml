// =====================================================================
//  obj_cenario — fundo da Fase 2 (O Salão Real em Ruínas)
//  A arte do salão (camada de tiles "fundo") cobre apenas a faixa
//  y = 464..688 da sala. Sem este objeto o resto da tela aparecia
//  azul-céu (cor da camada Background). Criado pelo sala_preparar().
// =====================================================================
banda_topo = 464;   // onde começa a arte do salão
banda_base = 688;   // onde ela termina
chao_y     = 682;   // topo da colisão do chão da Room2

// brasas e cinzas flutuando no salão
brasas = [];

// v1.13: a arte do salão em alta resolução (Castelo do Alex, em duas metades
// em datafiles/) no lugar dos tiles antigos. Mesmo período dos tiles: 1616 px.
castelo = [];
if (file_exists("castelo_a.png") and file_exists("castelo_b.png"))
{
    if (!variable_global_exists("castelo_spr")) global.castelo_spr = [sprite_add("castelo_a.png", 1, false, false, 0, 0), sprite_add("castelo_b.png", 1, false, false, 0, 0)];
    castelo = global.castelo_spr;
    var _lf = layer_get_id("fundo");
    if (_lf != -1) layer_set_visible(_lf, false);
}
