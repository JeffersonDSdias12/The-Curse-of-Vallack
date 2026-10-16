// =====================================================================
//  obj_menu_armas — tela de ARMAS e EVOLUÇÃO (START / TAB), estilo God of War 2
//  * à esquerda: a Lâmina de Sylla, o nível e os bônus
//  * no meio: os 5 níveis da espada, o que cada um libera e o custo em orbs
//  * à direita: combos e especiais (liberados ou bloqueados)
//  * SEGURAR confirmar: as orbs saem do pote e evoluem a espada
//  * efeito de abrir e fechar (painéis deslizam, corte carmesim)
// =====================================================================
globais_iniciar();
tempo = 0;
abre = 0;
fechando = false;
fechar_t = 0;
segurar = 0;             // 0..1 enchendo enquanto o botão é segurado
evoluiu_fx = 0;
evoluiu_txt = "";
negado_fx = 0;
orbs_vis = global.orbs;  // contador animado
fluxo = [];              // orbs voando do pote até a espada
faiscas = [];
selecionado = clamp(global.espada_nivel, 1, ESPADA_NIVEL_MAX - 1);   // linha do próximo nível (índice 0..4)

foto = -1;
if (surface_exists(application_surface))
{
    foto = sprite_create_from_surface(application_surface, 0, 0,
        surface_get_width(application_surface), surface_get_height(application_surface), false, false, 0, 0);
}
mundo_pausar();
io_clear();
som("sfx_menu_abrir", 0.9, 0);

fechar = function()
{
    if (fechando) return;
    fechando = true;
    fechar_t = 0;
    som("sfx_menu_fechar", 0.8, 0);
};

finalizar = function()
{
    if (foto != -1 and sprite_exists(foto)) sprite_delete(foto);
    foto = -1;
    mundo_retomar();
    io_clear();
    global.bloqueio_input = 12;
    instance_destroy();
};

// tenta evoluir para o próximo nível
evoluir = function()
{
    var _prox = global.espada_nivel + 1;
    if (_prox > ESPADA_NIVEL_MAX) return false;
    var _custo = espada_custo(_prox);
    if (global.orbs < _custo) return false;
    global.orbs -= _custo;
    global.espada_nivel = _prox;
    // o checkpoint também guarda a evolução (morrer não devolve as orbs gastas)
    global.marca.orbs = max(0, global.marca.orbs - _custo);
    global.marca.nivel = max(global.marca.nivel, _prox);
    evoluiu_fx = 90;
    var _niv = espada_niveis();
    var _info = _niv[_prox - 1];
    evoluiu_txt = "NÍVEL " + string(_prox) + "!";
    for (var _i = 0; _i < array_length(_info.itens); _i++)
    {
        var _it = _info.itens[_i];
        evoluiu_txt += "  " + ((_it.tipo == "combo") ? ("COMBO " + string(_it.n) + " LIBERADO") : (especial_nome(_it.acao) + " LIBERADO"));
    }
    som("espada_evoluir", 1, 0);      // evolução da espada
    repeat (40)
    {
        array_push(faiscas, { x: 250, y: 330, vx: random_range(-6, 6), vy: random_range(-7, 3), vida: irandom_range(30, 70), vmax: 70 });
    }
    selecionado = clamp(global.espada_nivel, 1, ESPADA_NIVEL_MAX - 1);
    return true;
};
