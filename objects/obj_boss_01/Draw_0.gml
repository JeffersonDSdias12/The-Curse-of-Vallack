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
    txt(x, bbox_top - 20, estado_ia + "  vida " + string(vida) + "/" + string(vida_max) + "  onda " + string(onda_numero) + "  próxima " + string(floor(onda_tempo / 60)) + "s" + (furia ? "  FÚRIA" : ""), FONTE.MINI, c_yellow, 1, fa_center, fa_bottom, 0.5);
    gpu_set_texfilter(false);
}
desenho_resetar();
