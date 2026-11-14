// =====================================================================
//  obj_perfil — PERFIL, CONQUISTAS E RECOMPENSAS (v1.17)
//  * o NOME de quem joga: aparece só nas conquistas (o herói continua sendo
//    Twilight Vetrus). Na primeira partida (modo "primeiro") ele é pedido
//    antes do mapa; depois muda em PERFIL > ALTERAR NOME.
//  * abas: CONQUISTAS (as 21, com a data), LÂMINAS (estilos de efeito da
//    espada ganhos nas conquistas) e PERFIL (nome, título e números)
//  * teclado na tela (toque / controle / mouse) e o teclado de verdade
//  Criado pelo obj_menu. O mesmo da versão Android.
// =====================================================================
if (!variable_global_exists("perfil")) perfil_carregar();
transicao_revelar(24);    // v1.19: o perfil surge atrás da cortina em brasa
modo = "perfil";         // "perfil" (do menu) ou "primeiro" (antes do mapa)
estado = "abas";          // abas | nome
aba = 0;                  // 0 CONQUISTAS, 1 LÂMINAS, 2 PERFIL
sel = 0;                  // item escolhido na aba
rolagem = 0;              // rolagem da lista de conquistas (px)
rolagem_alvo = 0;
t = 0;
entrada = 0;
iniciado = false;         // o modo chega depois do Create: o primeiro Step decide
nome_edit = "";
tecla_sel = 0;
mensagem = "";
mensagem_t = 0;
arrastando = false;
arraste_y0 = 0;
arraste_rol0 = 0;
arraste_dist = 0;
lista = conquistas_lista();
estilos = espada_estilos();

// teclado na tela: 4 linhas de 10 teclas + ESPAÇO, APAGAR e PRONTO
teclas = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
    "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
    "U", "V", "W", "X", "Y", "Z", "Ç", "Ã", "É", "Í",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "ESPAÇO", "APAGAR", "PRONTO"
];
tecla_pos = function(_i)
{
    var _gw = display_get_gui_width();
    var _kw = 64;
    var _x0 = _gw / 2 - 5 * (_kw + 8) + 4;
    if (_i < 40) return [_x0 + (_i mod 10) * (_kw + 8), 330 + (_i div 10) * 64, _kw, 54];
    var _larg = [250, 190, 210];
    var _xs = [_gw / 2 - 340, _gw / 2 - 70, _gw / 2 + 140];
    return [_xs[_i - 40], 330 + 4 * 64, _larg[_i - 40], 54];
};

abrir_nome = function()
{
    estado = "nome";
    nome_edit = global.perfil.nome;
    tecla_sel = 0;
    keyboard_string = "";
};

tecla_apertar = function(_i)
{
    var _k = teclas[_i];
    if (_k == "APAGAR") { nome_edit = string_copy(nome_edit, 1, max(0, string_length(nome_edit) - 1)); som("tit_mover", 0.6, 0.03); return; }
    if (_k == "PRONTO") { nome_salvar(); return; }
    if (string_length(nome_edit) >= PERFIL_NOME_MAX) { som("tit_negado", 0.6, 0); return; }
    nome_edit += (_k == "ESPAÇO") ? " " : _k;
    som("tit_alterar", 0.6, 0.04);
};

nome_salvar = function()
{
    var _n = string_upper(string_trim(nome_edit));
    if (_n == "") _n = "JOGADOR";
    global.perfil.nome = _n;
    perfil_salvar();
    som("tit_selecao", 0.8, 0.02);
    if (modo == "primeiro")
    {
        // primeira vez: segue para o mapa
        instance_create_depth(0, 0, -10400, obj_mapa);
        instance_destroy();
        return;
    }
    estado = "abas";
    mensagem = "NOME SALVO: " + _n;
    mensagem_t = 120;
};

// cards da aba CONQUISTAS: 2 colunas
card_pos = function(_i)
{
    var _gw = display_get_gui_width();
    var _cw = min(600, (_gw - 100) / 2);
    var _x1 = _gw / 2 - _cw - 10 + (_i mod 2) * (_cw + 20);
    var _y1 = 196 + (_i div 2) * 82 - rolagem;
    return [_x1, _y1, _cw, 72];
};
lamina_pos = function(_i)
{
    var _gw = display_get_gui_width();
    var _cw = min(360, (_gw - 120) / 3);
    var _x1 = _gw / 2 - 1.5 * _cw - 20 + (_i mod 3) * (_cw + 20);
    var _y1 = 200 + (_i div 3) * 220;
    return [_x1, _y1, _cw, 200];
};
