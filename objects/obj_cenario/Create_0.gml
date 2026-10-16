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
