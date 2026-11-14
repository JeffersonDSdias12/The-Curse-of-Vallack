// =====================================================================
//  obj_guerra — clima de GUERRA ao fundo e na frente da cena
//  Fase 1: saraivadas de flechas incendiárias cruzando o céu ao longe,
//    bolas de fogo de catapulta (com clarão no horizonte), brilho de
//    incêndios distantes e brasas sopradas pela tela.
//  Fase 2: cinzas caindo no salão em ruínas.
//  Fundo (Draw, profundidade 397: atrás do chão e dos personagens) e
//  frente (Draw End). Leve: poucas dezenas de partículas.
//  Criado pelo sala_preparar(). Posições em coordenadas da visão.
// =====================================================================
t = 0;
flechas = [];          // {x, y, vx, vy, vida}
bolas = [];            // bolas de fogo de catapulta
claroes = [];          // clarões no horizonte {x, vida, vmax}
brasas = [];           // frente: brasas / cinzas
fase1 = (room == Room1);
view_ant = (view_camera[0] != -1) ? camera_get_view_x(view_camera[0]) : 0;
prox_saraivada = random_range(120, 300);
prox_catapulta = random_range(400, 800);

// quantidade de partículas conforme a qualidade
qtd = function()
{
    var _q = [0.4, 0.75, 1];
    return _q[clamp(global.cfg_qualidade, 0, 2)];
};
