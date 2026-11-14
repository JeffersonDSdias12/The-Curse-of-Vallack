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

// v1.14: SELO de magia (correntes roxas em X e um círculo de runas girando)
if (selado or selo_quebra > 0)
{
    var _sa = selado ? (0.75 + 0.25 * sin(_t / 8)) : selo_quebra / 40;
    var _sr = selado ? 1 : 1 + (1 - selo_quebra / 40) * 0.8;
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(170, 60, 255));
    draw_set_alpha(0.25 * _sa);
    draw_ellipse(x - 30 * _sr, y - 30 * _sr, x + 30 * _sr, y + 6, false);
    draw_set_alpha(0.9 * _sa);
    draw_set_color(make_color_rgb(210, 140, 255));
    for (var _k = 0; _k < 8; _k++)
    {
        var _ang = _t * 1.6 + _k * 45;
        draw_circle(x + lengthdir_x(24 * _sr, _ang), y - 12 + lengthdir_y(10 * _sr, _ang), 1.5, false);
    }
    // as correntes cruzadas por cima do baú (elos)
    for (var _c = -1; _c <= 1; _c += 2)
        for (var _k = 0; _k <= 8; _k++)
        {
            var _cx = x - 16 + _k * 4;
            var _cy = y - 22 + _k * 2.4 * _c + ((_c > 0) ? 0 : 19);
            draw_ellipse(_cx - 2, _cy - 1.5, _cx + 2, _cy + 1.5, true);
        }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
// v1.14: a chave subindo do baú e voando até Twilight
if (chave_voo >= 0)
{
    var _kp = clamp(chave_voo / 70, 0, 1);
    var _kx = x, _ky = y - 20 - 40 * min(1, chave_voo / 30);
    if (chave_voo > 40 and instance_exists(alvo))
    {
        var _kk = (chave_voo - 40) / 30;
        _kx = lerp(_kx, alvo.x, _kk);
        _ky = lerp(_ky, alvo.bbox_top + 10, _kk);
    }
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(255, 210, 100));
    draw_set_alpha(0.35 * (1 - _kp * 0.5));
    draw_circle(_kx, _ky, 12, false);
    gpu_set_blendmode(bm_normal);
    desenhar_chave(_kx, _ky, 1, sin(chave_voo / 6));
}
// (o botão ABRIR, em destaque sobre o baú, é desenhado pelo HUD do jogador)
desenho_resetar();
