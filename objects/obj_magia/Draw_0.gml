gpu_set_texfilter(true);
switch (tipo)
{
    // ------------------------------------------------------------------
    case "orbe":
        var _cor_b = refletida ? make_color_rgb(110, 190, 255) : make_color_rgb(255, 40, 60);
        if (estado == "fim")
        {
            var _f = fim_t / 16;
            gpu_set_blendmode(bm_add);
            draw_set_alpha(0.8 * (1 - _f));
            draw_set_color(_cor_b);
            draw_circle(x, y, 8 + 22 * _f, true);
            draw_circle(x, y, 6 + 14 * _f, false);
            gpu_set_blendmode(bm_normal);
            draw_set_alpha(1);
            break;
        }
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.3 + 0.1 * sin(t * 0.5));
        draw_set_color(_cor_b);
        draw_circle(x, y, 16, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
        // a arte do orbe tem a cauda à direita: gira conforme a direção do voo
        draw_sprite_hd(spr_estatua_orbe, 0, x, y, escala, escala, ang - 180, refletida ? make_color_rgb(170, 220, 255) : c_white, 1);
    break;

    // ------------------------------------------------------------------
    case "teia":
        var _cw = refletida ? make_color_rgb(200, 230, 255) : make_color_rgb(235, 235, 240);
        if (estado == "chao")
        {
            // armadilha pegajosa no chão
            var _va = clamp(vida_chao / 30, 0, 1) * 0.85;
            draw_set_alpha(_va);
            draw_set_color(_cw);
            draw_ellipse(x - 22, y - 5, x + 22, y + 2, true);
            draw_ellipse(x - 12, y - 3, x + 12, y + 1, true);
            for (var _r = 0; _r < 6; _r++)
            {
                var _ra = _r * 30;
                draw_line(x - lengthdir_x(22, _ra), y - 1.5 - lengthdir_y(3.5, _ra), x + lengthdir_x(22, _ra), y - 1.5 + lengthdir_y(3.5, _ra));
            }
            draw_set_alpha(1);
            break;
        }
        var _fa = (estado == "fim") ? 1 - fim_t / 16 : 1;
        var _rr = (estado == "fim") ? 6 + fim_t : 5;
        draw_set_alpha(_fa);
        draw_set_color(_cw);
        draw_circle(x, y, _rr, false);
        for (var _k = 0; _k < 8; _k++)
        {
            var _ka = _k * 45 + t * 6;
            draw_line(x, y, x + lengthdir_x(_rr + 5, _ka), y + lengthdir_y(_rr + 5, _ka));
        }
        // fio da teia atrás
        draw_set_alpha(0.35 * _fa);
        draw_line(x, y, x - vx * 4, y - vy * 4);
        draw_set_alpha(1);
    break;

    // ------------------------------------------------------------------
    case "onda":
        var _oa = (estado == "fim") ? 1 - fim_t / 16 : 1;
        var _sd = (vx >= 0) ? 1 : -1;
        var _cx = x - _sd * 8;
        var _cy = y - 18;
        gpu_set_blendmode(bm_add);
        // meia-lua roxa de pé, virada para onde ela anda
        draw_primitive_begin(pr_trianglestrip);
        for (var _i = 0; _i <= 10; _i++)
        {
            var _a = -80 + _i * 16;
            var _ox = lengthdir_x(1, _a) * _sd;
            var _oy = lengthdir_y(1, _a);
            var _l = 1 - abs(_i - 5) / 5.5;
            draw_vertex_color(_cx + _ox * 24, _cy + _oy * 22, make_color_rgb(230, 60, 255), 0.85 * _oa * _l);
            draw_vertex_color(_cx + _ox * 13, _cy + _oy * 15, make_color_rgb(255, 210, 255), 0.25 * _oa);
        }
        draw_primitive_end();
        draw_set_alpha(0.35 * _oa);
        draw_set_color(make_color_rgb(200, 50, 255));
        draw_ellipse(x - 20, y - 4, x + 20, y + 3, false);
        for (var _j = 0; _j < 3; _j++)
        {
            draw_circle(x - _sd * (14 + _j * 12), y - 6 - ((t * 2 + _j * 9) mod 22), 1.6, false);
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    break;
}
gpu_set_texfilter(false);
draw_set_alpha(1);
