// =====================================================================
//  scr_hd: texturas em ALTA DEFINIÇÃO dos personagens
//  As sprites do jogador, dos inimigos e do boss foram redesenhadas em
//  resolução maior (2x a 4x, com bordas suavizadas e mais detalhe).
//  Para o jogo não mudar de tamanho, elas são desenhadas com escala 1/k
//  e filtro suave; a colisão continua nas máscaras (spr_mascara_*).
// =====================================================================

function hd_iniciar()
{
    global.hd_k = {};
    hd_lista();               // gerado junto com as sprites (abaixo)
}

function hd_registrar(_spr, _k)
{
    global.hd_k[$ string(_spr)] = _k;
}

// v1.9: IGUALA O TAMANHO DO CORPO entre as animações de um personagem.
// Algumas animações vieram desenhadas em outra escala (a besta correndo,
// andando e atacando era ~25% menor que a besta parada; o porco parado era
// maior que o resto). _fator > 1 desenha a animação maior, < 1 menor.
// Os fatores foram medidos comparando a cabeça e o corpo em cada quadro.
function hd_ajustar(_spr, _fator)
{
    global.hd_k[$ string(_spr)] = hd_escala(_spr) / _fator;
}

// Quantos pixels da sprite valem 1 pixel do mundo (1 = sprite comum)
function hd_escala(_spr)
{
    if (!variable_global_exists("hd_k")) return 1;
    var _k = global.hd_k[$ string(_spr)];
    return is_undefined(_k) ? 1 : _k;
}

// draw_sprite_ext que já desconta a escala HD
function draw_sprite_hd(_spr, _img, _x, _y, _xs, _ys, _rot, _col, _alpha)
{
    var _k = hd_escala(_spr);
    if (_k > 1)
    {
        var _tf = gpu_get_texfilter();
        gpu_set_texfilter(true);
        draw_sprite_ext(_spr, _img, _x, _y, _xs / _k, _ys / _k, _rot, _col, _alpha);
        gpu_set_texfilter(_tf);
    }
    else draw_sprite_ext(_spr, _img, _x, _y, _xs, _ys, _rot, _col, _alpha);
}

// HD_LISTA_INICIO (gerado)
function hd_lista()
{
    hd_registrar(spr_player_idle, 3);
    hd_registrar(spr_player_run, 3);
    hd_registrar(spr_player_jump, 3);
    hd_registrar(spr_player_fall, 3);
    hd_registrar(spr_player_dano, 3);
    hd_registrar(spr_player_morte, 3);
    hd_registrar(spr_player_defendendo, 3);
    hd_registrar(spr_player_ataque, 3);
    hd_registrar(spr_player_especial, 3);
    hd_registrar(spr_player_agaichar, 3);
    hd_registrar(spr_player_atacar_agaichado, 3);
    hd_registrar(spr_player_atacar_agaichado_especial, 3);
    hd_registrar(spr_ataque_2, 3);
    hd_registrar(spr_ataque_especial_2, 3);
    hd_registrar(spr_player, 3);
    hd_registrar(spr_inimigo01_parado, 3);
    hd_registrar(spr_inimigo01_andar, 3);
    hd_registrar(spr_inimigo01_correndo, 3);
    hd_registrar(spr_inimigo01_atacando, 3);
    hd_registrar(spr_inimigo01_pulando, 3);
    hd_registrar(spr_inimigo01_morrendo, 3);
    hd_registrar(spr_inimigo02_parado, 3);
    hd_registrar(spr_inimigo02_correndo, 3);
    hd_registrar(spr_inimigo02_atacando, 3);
    hd_registrar(spr_inimigo02_morrendo, 3);
    hd_registrar(spr_inimigo02_sofrendo_dano, 3);
    hd_registrar(spr_boss_01, 4);
    hd_registrar(spr_boss_01_atacando, 4);
    hd_registrar(spr_boss_01_parado, 4);
    hd_registrar(spr_ataque_03, 3);
    // v1.8: novos inimigos (k = 2)
    hd_registrar(spr_esqueleto_parado, 2);
    hd_registrar(spr_esqueleto_andando, 2);
    hd_registrar(spr_esqueleto_correndo, 2);
    hd_registrar(spr_esqueleto_ataque, 2);
    hd_registrar(spr_esqueleto_dano, 2);
    hd_registrar(spr_esqueleto_morrendo, 2);
    hd_registrar(spr_aranha_parada, 2);
    hd_registrar(spr_aranha_andando, 2);
    hd_registrar(spr_aranha_ataque, 2);
    hd_registrar(spr_porco_parado, 2);
    hd_registrar(spr_porco_correndo, 2);
    hd_registrar(spr_porco_ataque, 2);
    hd_registrar(spr_porco_roxo, 2);
    hd_registrar(spr_porco_salto, 2);
    hd_registrar(spr_porco_furia, 2);
    hd_registrar(spr_porco_invocar, 2);
    hd_registrar(spr_porco_morrendo, 2);
    hd_registrar(spr_estatua, 2);
    hd_registrar(spr_estatua_orbe, 2);

    // v1.9: corpo do mesmo tamanho em todas as animações (ver hd_ajustar)
    hd_ajustar(spr_inimigo01_correndo, 1.36);
    hd_ajustar(spr_inimigo01_andar, 1.32);
    hd_ajustar(spr_inimigo01_atacando, 1.33);
    hd_ajustar(spr_inimigo01_pulando, 1.03);
    hd_ajustar(spr_inimigo01_morrendo, 1.6);
    hd_ajustar(spr_porco_parado, 0.87);
    hd_ajustar(spr_porco_ataque, 1.07);
    hd_ajustar(spr_porco_furia, 0.96);
    hd_ajustar(spr_porco_invocar, 0.95);
}
// HD_LISTA_FIM
