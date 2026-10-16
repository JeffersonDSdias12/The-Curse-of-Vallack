if (!visivel) exit;
var _t = current_time / 16;

// surgindo do caixote: coluna de luz
if (revelar_t > 0)
{
    var _ra = revelar_t / 30;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_ra * 0.6);
    draw_set_color(make_color_rgb(255, 200, 90));
    draw_rectangle(x - 10 * (1 - _ra) - 4, y - 140, x + 10 * (1 - _ra) + 4, y, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// aura dourada enquanto está fechado (chama a atenção)
if (estado == "fechado")
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.16 + 0.08 * sin(_t / 10));
    draw_set_color(make_color_rgb(255, 170, 60));
    draw_ellipse(x - 26, y - 34, x + 26, y + 4, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_white, 1);

// brilho saindo da tampa aberta
if (estado == "abrindo")
{
    var _k = clamp(t / 30, 0, 1);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.5 * _k * (estado == "abrindo" ? 1 : 0.3));
    draw_set_color(make_color_rgb(255, 210, 120));
    draw_triangle(x - 12, y - 14, x + 12, y - 14, x + 30, y - 90, false);
    draw_triangle(x - 12, y - 14, x - 30, y - 90, x + 30, y - 90, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// magia fluindo até Twilight
if (array_length(magia) > 0)
{
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < array_length(magia); _i++)
    {
        var _m = magia[_i];
        draw_set_alpha(0.35);
        draw_set_color(make_color_rgb(255, 120, 60));
        draw_circle(_m.x, _m.y, 5, false);
        draw_set_alpha(0.9);
        draw_set_color(make_color_rgb(255, 230, 160));
        draw_circle(_m.x, _m.y, 2, false);
        draw_set_alpha(0.4);
        draw_line_width(_m.x, _m.y, _m.x - _m.vx * 2.5, _m.y - _m.vy * 2.5, 2);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// dica: tecla de interagir
var _p = instance_find(obj_player, 0);
if (estado == "fechado" and _p != noone and _p.alvo_interacao == id)
{
    gpu_set_texfilter(true);
    txt(x, y - 38, rotulo_acao(ACAO.INTERAGIR) + " ABRIR O BAÚ DE VIDA", FONTE.MINI, c_white, 0.9 + 0.1 * sin(_t / 6), fa_center, fa_bottom, 0.55);
    gpu_set_texfilter(false);
}
desenho_resetar();
