var _p01 = clamp(t / vida, 0, 1);

// ----- partículas genéricas (v1.4) -----
if (gen)
{
    if (flash > 0)
    {
        gpu_set_blendmode(bm_add);
        var _fa = flash / ((tipo == "aparar") ? 10 : 7);
        draw_set_alpha(_fa);
        draw_set_color((tipo == "aparar") ? make_color_rgb(150, 210, 255) : ((tipo == "fumaca_maldita_estouro") ? make_color_rgb(170, 40, 200) : make_color_rgb(255, 230, 170)));
        var _fr = (tipo == "aparar" ? 26 : 12) * (1.4 - _fa * 0.4) * tam;
        draw_triangle(x - _fr * 1.8, y, x, y - _fr * 0.3, x, y + _fr * 0.3, false);
        draw_triangle(x + _fr * 1.8, y, x, y - _fr * 0.3, x, y + _fr * 0.3, false);
        draw_triangle(x, y - _fr, x - _fr * 0.25, y, x + _fr * 0.25, y, false);
        draw_triangle(x, y + _fr, x - _fr * 0.25, y, x + _fr * 0.25, y, false);
        draw_circle(x, y, _fr * 0.45, false);
        if (tipo == "aparar")
        {
            draw_set_alpha(_fa * 0.8);
            draw_circle(x, y, 10 + (1 - _fa) * 40, true);
            draw_circle(x, y, 8 + (1 - _fa) * 30, true);
        }
        gpu_set_blendmode(bm_normal);
    }
    for (var _g = 0; _g < array_length(parts); _g++)
    {
        var _q = parts[_g];
        var _qa = clamp(_q.v / (_q.vmax * 0.4), 0, 1);
        if (_q.add) gpu_set_blendmode(bm_add);
        draw_set_color(_q.cor);
        switch (_q.forma)
        {
            case "linha":
                draw_set_alpha(_qa);
                draw_line_width(_q.x, _q.y, _q.x - _q.vx * 2.2, _q.y - _q.vy * 2.2, _q.r);
            break;
            case "circulo":
                draw_set_alpha(_qa);
                draw_circle(_q.x, _q.y, _q.r, false);
            break;
            case "fumo":
                draw_set_alpha(0.32 * clamp(_q.v / _q.vmax * 1.6, 0, 1) * min(1, (_q.vmax - _q.v) / 12));
                draw_circle(_q.x, _q.y, _q.r, false);
            break;
            case "maldita":
                // fumaça negra e densa, com o miolo arroxeado e um halo roxo bem fraco
                var _ma = clamp(_q.v / _q.vmax * 1.5, 0, 1) * min(1, (_q.vmax - _q.v) / 8);
                if (global.cfg_qualidade > 0)
                {
                    gpu_set_blendmode(bm_add);
                    draw_set_alpha(0.16 * _ma);
                    draw_set_color(make_color_rgb(140, 25, 120));
                    draw_circle(_q.x, _q.y, _q.r * 1.2, false);
                    gpu_set_blendmode(bm_normal);
                }
                // três discos sobrepostos: borda mais suave e miolo bem escuro
                draw_set_color(_q.cor);
                draw_set_alpha(0.36 * _ma);
                draw_circle(_q.x, _q.y, _q.r, false);
                draw_set_alpha(0.36 * _ma);
                draw_circle(_q.x - _q.r * 0.08, _q.y + _q.r * 0.06, _q.r * 0.74, false);
                draw_set_alpha(0.4 * _ma);
                draw_set_color(make_color_rgb(40, 6, 36));
                draw_circle(_q.x + _q.r * 0.12, _q.y + _q.r * 0.16, _q.r * 0.46, false);
            break;
            case "ret":
                draw_set_alpha(_qa);
                var _c1 = dcos(_q.rot) * _q.r;
                var _s1 = dsin(_q.rot) * _q.r;
                draw_triangle(_q.x - _c1, _q.y - _s1 * 0.4, _q.x + _c1, _q.y + _s1 * 0.4, _q.x + _c1 - _s1 * 0.4, _q.y + _s1 * 0.4 + _c1 * 0.4, false);
                draw_triangle(_q.x - _c1, _q.y - _s1 * 0.4, _q.x - _c1 - _s1 * 0.4, _q.y - _s1 * 0.4 + _c1 * 0.4, _q.x + _c1 - _s1 * 0.4, _q.y + _s1 * 0.4 + _c1 * 0.4, false);
            break;
            default:    // "tri"
                draw_set_alpha(_qa);
                var _r = _q.r;
                var _cc = dcos(_q.rot) * _r;
                var _sn2 = dsin(_q.rot) * _r;
                draw_triangle(_q.x + _cc, _q.y + _sn2, _q.x - _sn2, _q.y + _cc, _q.x - _cc * 0.6, _q.y - _sn2 * 0.6, false);
        }
        if (_q.add) gpu_set_blendmode(bm_normal);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
    exit;
}

switch (tipo)
{
    case "poeira":
        for (var _i = 0; _i < array_length(parts); _i++)
        {
            var _p = parts[_i];
            draw_set_alpha(clamp(_p.v / 34, 0, 1) * 0.45);
            draw_set_color(make_color_rgb(120, 104, 92));
            draw_circle(_p.x, _p.y, _p.r, false);
        }
    break;

    case "onda_chao":
        // onda de choque correndo pelo chão para os dois lados
        gpu_set_blendmode(bm_add);
        var _e = 1 - power(1 - _p01, 2);
        var _rx = (24 + 150 * _e) * tam;
        var _ry = (8 + 20 * _e) * tam;
        draw_set_alpha((1 - _p01) * 0.8);
        draw_set_color(make_color_rgb(255, 120, 60));
        draw_ellipse(x - _rx, y - _ry, x + _rx, y + _ry * 0.5, true);
        draw_ellipse(x - _rx + 2, y - _ry + 1, x + _rx - 2, y + _ry * 0.5 - 1, true);
        draw_set_alpha((1 - _p01) * 0.35);
        draw_set_color(make_color_rgb(255, 200, 140));
        draw_ellipse(x - _rx * 0.7, y - _ry * 0.7, x + _rx * 0.7, y + _ry * 0.35, false);
        // colunas de energia saindo do chão nas pontas da onda
        for (var _l = -1; _l <= 1; _l += 2)
        {
            var _cx = x + _l * _rx;
            var _h = 34 * tam * (1 - _p01);
            draw_set_alpha((1 - _p01) * 0.7);
            draw_set_color(make_color_rgb(255, 90, 40));
            draw_triangle(_cx - 6, y, _cx + 6, y, _cx, y - _h, false);
        }
        gpu_set_blendmode(bm_normal);
    break;

    case "rachaduras":
        // fendas no chão que brilham e esfriam
        var _brilho = 1 - _p01;
        for (var _f = 0; _f < array_length(fendas); _f++)
        {
            var _pts = fendas[_f];
            var _cresce = clamp(t / 8, 0, 1);
            var _np = max(2, floor((array_length(_pts) - 1) * _cresce) + 1);
            for (var _k = 1; _k < _np; _k++)
            {
                var _a = _pts[_k - 1];
                var _b = _pts[_k];
                draw_set_alpha(0.85 * clamp(_brilho * 1.6, 0, 1));
                draw_set_color(c_black);
                draw_line_width(x + _a[0], y + _a[1], x + _b[0], y + _b[1], 3);
                gpu_set_blendmode(bm_add);
                draw_set_alpha(_brilho);
                draw_set_color(merge_color(make_color_rgb(255, 70, 20), make_color_rgb(255, 210, 120), _brilho));
                draw_line_width(x + _a[0], y + _a[1] - 1, x + _b[0], y + _b[1] - 1, 1.5);
                gpu_set_blendmode(bm_normal);
            }
        }
    break;

    case "faiscas_tela":
    case "carga":
        gpu_set_blendmode(bm_add);
        for (var _j = 0; _j < array_length(parts); _j++)
        {
            var _s = parts[_j];
            var _a2 = (tipo == "carga") ? 0.8 : clamp(_s.v / 40, 0, 1) * (0.6 + 0.4 * sin((t + _s.fase) * 0.5));
            var _cor = (tipo == "carga") ? make_color_rgb(255, 170, 70) : _s.cor;
            draw_set_alpha(_a2);
            draw_set_color(_cor);
            draw_circle(_s.x, _s.y, _s.r, false);
            if (global.cfg_qualidade == 2)
            {
                draw_set_alpha(_a2 * 0.25);
                draw_circle(_s.x, _s.y, _s.r * 3, false);
                draw_set_alpha(_a2 * 0.5);
                draw_line_width(_s.x, _s.y, _s.x - _s.vx * 3, _s.y - _s.vy * 3, _s.r * 0.8);
            }
        }
        gpu_set_blendmode(bm_normal);
    break;

    case "pedras":
        for (var _m = 0; _m < array_length(parts); _m++)
        {
            var _pd = parts[_m];
            draw_set_alpha(clamp(_pd.v / 20, 0, 1));
            draw_set_color(make_color_rgb(88, 74, 66));
            var _r = _pd.r;
            var _c = dcos(_pd.rot) * _r;
            var _sn = dsin(_pd.rot) * _r;
            draw_triangle(_pd.x + _c, _pd.y + _sn, _pd.x - _sn, _pd.y + _c, _pd.x - _c, _pd.y - _sn, false);
            draw_triangle(_pd.x - _c, _pd.y - _sn, _pd.x + _sn, _pd.y - _c, _pd.x + _c, _pd.y + _sn, false);
        }
    break;
}
draw_set_alpha(1);
draw_set_color(c_white);
gpu_set_blendmode(bm_normal);
