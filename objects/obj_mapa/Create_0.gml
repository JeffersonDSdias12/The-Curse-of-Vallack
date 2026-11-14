// =====================================================================
//  obj_mapa — O MAPA DE VALLACK (v1.17): escolha da fase e da dificuldade
//  Um caminho em chamas liga as 18 fases. Só a primeira está aberta; as
//  outras têm cadeado e "EM DESENVOLVIMENTO". Na última, o covil do chefão,
//  o dragão voa ao lado. Cada fase tem nome, descrição e a foto do cenário
//  (mapa_fases.jpg: 6 x 3 fotos de 320 x 180, ferramentas/gerar_mapa.ps1).
//  Arraste (mouse / dedo) ou use a rodinha para deslizar o mapa; ◄ ►
//  escolhem a fase, ▲ ▼ a dificuldade; CONFIRMAR joga; VOLTAR volta ao menu.
//  Criado pelo obj_menu (NOVO JOGO). O mesmo da versão Android.
// =====================================================================
transicao_revelar(28);    // v1.19: o mapa surge atrás da cortina em brasa
fases = fases_mapa();
n = array_length(fases);
sel = 0;
dif = global.dificuldade;
t = 0;
entrada = 0;              // o mapa aparece (0 -> 1)
saindo = -1;              // >= 0: escurecendo para começar a fase
arrastando = false;
arraste_x0 = 0;
arraste_cam0 = 0;
arraste_dist = 0;
arraste_vel = 0;
mouse_ant_x = 0;
toque_no = -1;            // nó tocado no começo do arraste
aviso_txt = "";
aviso_t = 0;
brasas = [];
if (!variable_global_exists("img_mapa") or !sprite_exists(global.img_mapa)) global.img_mapa = imagem_carregar("mapa_fases.jpg");
img = global.img_mapa;
FOTO_W = 236;             // tamanho da foto no mapa (a original tem 320 x 180)
FOTO_H = 133;
GAP = 330;                // distância entre as fases no caminho

no_x = function(_i) { return 300 + _i * GAP; };
no_y = function(_i) { return 268 + sin(_i * 0.95 + 0.6) * 62; };
mundo_w = no_x(n - 1) + 520;      // espaço para o dragão voar ao lado da última fase
cam_x = 0;
cam_alvo = 0;

// o caminho em chamas: uma curva suave (Catmull-Rom) por baixo das fotos
caminho = [];
var _pts = [];
for (var _i = -1; _i <= n; _i++)
{
    var _k = clamp(_i, 0, n - 1);
    array_push(_pts, [no_x(_i), no_y(_k) + 96]);
}
for (var _s = 1; _s < array_length(_pts) - 2; _s++)
{
    var _p0 = _pts[_s - 1], _p1 = _pts[_s], _p2 = _pts[_s + 1], _p3 = _pts[_s + 2];
    for (var _u = 0; _u < 1; _u += 0.05)
    {
        var _u2 = _u * _u, _u3 = _u2 * _u;
        var _px = 0.5 * ((2 * _p1[0]) + (-_p0[0] + _p2[0]) * _u + (2 * _p0[0] - 5 * _p1[0] + 4 * _p2[0] - _p3[0]) * _u2 + (-_p0[0] + 3 * _p1[0] - 3 * _p2[0] + _p3[0]) * _u3);
        var _py = 0.5 * ((2 * _p1[1]) + (-_p0[1] + _p2[1]) * _u + (2 * _p0[1] - 5 * _p1[1] + 4 * _p2[1] - _p3[1]) * _u2 + (-_p0[1] + 3 * _p1[1] - 3 * _p2[1] + _p3[1]) * _u3);
        array_push(caminho, [_px, _py, random(100)]);
    }
}

aviso_mapa = function(_txt) { aviso_txt = _txt; aviso_t = 150; };

// começa a fase escolhida (só a 1 existe por enquanto)
jogar = function()
{
    if (!fase_mapa_livre(sel))
    {
        aviso_mapa(fases[sel].nome + " ESTÁ EM DESENVOLVIMENTO");
        som("tit_negado", 0.8, 0);
        return;
    }
    global.dificuldade = dif;
    som("tit_selecao", 0.9, 0);
    saindo = 0;
};
