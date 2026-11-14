var _t = current_time / 16;
var _sx = (tremor > 0) ? random_range(-tremor, tremor) : 0;
var _xs = -dir * escala;          // as sprites olham para a esquerda
var _cor = (estado_ia == "dormindo") ? make_color_rgb(125, 105, 105) : c_white;
if (furia and !morrendo) _cor = make_color_rgb(255, 190, 180);
if (morrendo) _cor = merge_color(c_white, make_color_rgb(80, 50, 40), clamp(morte_tempo / 200, 0, 1));

// aura vermelha pulsando (acordada; mais forte na fúria)
if (acordado and !morrendo and global.cfg_qualidade > 0)
{
    gpu_set_blendmode(bm_add);
    var _aa = furia ? 0.32 + 0.14 * sin(_t / 5) : 0.18 + 0.08 * sin(_t / 9);
    draw_sprite_hd(sprite_index, image_index, x + _sx, y + afundar, _xs * 1.03, escala * 1.02, 0, furia ? make_color_rgb(220, 30, 10) : make_color_rgb(150, 20, 10), _aa);
    gpu_set_blendmode(bm_normal);
}

if (flash_dano > 0 and !morrendo)
{
    gpu_set_fog(true, make_color_rgb(255, 230, 200), 0, 0);
    draw_sprite_hd(sprite_index, image_index, x + _sx, y + afundar, _xs, escala, 0, c_white, image_alpha);
    gpu_set_fog(false, c_white, 0, 0);
}
else inimigo_corpo_desenhar(sprite_index, image_index, x + _sx, y + afundar, _xs, escala, 0, _cor, image_alpha);   // morto: evapora na fumaça

// fúria: onda vermelha saindo do tronco
if (furia_fx > 0)
{
    var _k = 1 - furia_fx / 90;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(1 - _k);
    draw_set_color(make_color_rgb(255, 50, 20));
    draw_circle(x, y - 40 * escala / 2, 30 + 300 * _k, true);
    draw_circle(x, y - 40 * escala / 2, 26 + 260 * _k, true);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// v1.12: AVISO da bola de fogo: a mão acende em roxo antes de lançar
if (estado_ia == "atacando" and !golpe_lancado and !morrendo)
{
    var _hk = clamp(image_index / 6, 0, 1);
    var _hx = x + dir * 30 * escala;
    var _hy = y - 36 * escala;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.35 + 0.45 * _hk);
    draw_set_color(make_color_rgb(150, 50, 255));
    draw_circle(_hx, _hy, 10 + 26 * _hk + 3 * sin(_t / 2), false);
    draw_set_alpha(0.6 * _hk);
    draw_set_color(make_color_rgb(235, 200, 255));
    draw_circle(_hx, _hy, 5 + 10 * _hk, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// v1.19: CHUVA DE BRASAS: o chão brilha onde cada brasa vai cair (cresce até ela sair)
if (array_length(chuva_fila) > 0 and !morrendo)
{
    gpu_set_blendmode(bm_add);
    for (var _c = 0; _c < array_length(chuva_fila); _c++)
    {
        var _cx = chuva_fila[_c][0];
        var _ck = clamp(1 - chuva_fila[_c][1] / (CHUVA_AVISO + 20), 0, 1);   // 0 = acabou de marcar, 1 = vai cair
        var _cy = chuva_fila[_c][2];
        draw_set_alpha(0.25 + 0.5 * _ck + 0.15 * sin(_t / 2 + _c));
        draw_set_color(make_color_rgb(255, 110, 30));
        draw_ellipse(_cx - 10 - 18 * _ck, _cy - 3 - 3 * _ck, _cx + 10 + 18 * _ck, _cy + 3 + 3 * _ck, false);
        draw_set_alpha(0.35 * _ck);
        draw_rectangle(_cx - 2, _cy - 160 * _ck, _cx + 2, _cy, false);     // coluna de luz: a brasa vem daqui
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// v1.17: CAMBALEANDO: brilho dourado no tronco e o ícone da execução sobre ela
if (estado_ia == "vulneravel" and !morrendo and !em_qte)
{
    var _vk = 1 - vulneravel_t / 420;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.25 + 0.2 * sin(_t / 3));
    draw_set_color(make_color_rgb(255, 170, 60));
    draw_circle(x - 10 * escala, y - 40 * escala, 60 + 10 * sin(_t / 4), false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    desenhar_icone_finalizador(x - 10 * escala, bbox_top - 14);
    desenhar_anel(x - 10 * escala, bbox_top - 14, 26, 4, _vk, make_color_rgb(255, 200, 90), 0.9);
}

// chama nas raízes durante a invocação
if (estado_ia == "invocando")
{
    desenhar_portal(x, y_chao, min(1, image_index / 3), _t);
}

// ===== BARREIRA QUE BLOQUEIA A SAÍDA (antes da luta; depois as muralhas mágicas) =====
if (!arena_fechada)
{
    var _p = instance_find(obj_player, 0);
    if (_p != noone)
    {
        var _ba = clamp(1 - abs(_p.x - barreira_x) / 520, 0.12, 1);
        desenhar_barreira(barreira_x, y_chao - 240, y_chao, _ba, _t);
    }
}

if (global.debug_hitbox)
{
    draw_set_alpha(0.9);
    draw_set_color(c_fuchsia);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_set_color(c_orange);
    draw_circle(x, y - 36 * escala, alcance_visao, true);
    draw_line(arena_esq, y_chao - 300, arena_esq, y_chao);
    gpu_set_texfilter(true);
    txt(x, bbox_top - 20, estado_ia + "  vida " + string(vida) + "/" + string(vida_max) + "  fase " + string(fase) + "  ataque " + string(ataque_n), FONTE.MINI, c_yellow, 1, fa_center, fa_bottom, 0.5);
    gpu_set_texfilter(false);
}
desenho_resetar();
