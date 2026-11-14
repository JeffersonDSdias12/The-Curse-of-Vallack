if (descartado) exit;    // v1.18: cortado pelo orçamento de efeitos
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
            case "chama":
                // v1.17: língua de fogo: branco-amarelo ao nascer, laranja, vermelho e some
                var _kc = clamp(_q.v / _q.vmax, 0, 1);
                var _ac = min(1, (_q.vmax - _q.v) / 4) * min(1, _kc * 1.6);
                var _cc1 = (_kc > 0.6) ? merge_color(make_color_rgb(255, 150, 50), make_color_rgb(255, 236, 170), (_kc - 0.6) / 0.4)
                    : merge_color(make_color_rgb(200, 40, 16), make_color_rgb(255, 150, 50), _kc / 0.6);
                var _rc = _q.r * (0.55 + 0.45 * _kc);
                var _bal = sin((t + _q.rot) * 0.3) * _rc * 0.5;
                draw_set_color(_cc1);
                draw_set_alpha(0.45 * _ac);
                draw_circle(_q.x, _q.y, _rc * 1.5, false);
                draw_set_alpha(0.9 * _ac);
                draw_triangle(_q.x - _rc, _q.y, _q.x + _rc, _q.y, _q.x + _bal, _q.y - _rc * 2.8, false);
                draw_circle(_q.x, _q.y, _rc, false);
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
    case "corte":
        // risco de luz em losango (brilho largo + miolo branco) e onda de choque
        var _ec = 1 - power(1 - _p01, 3);
        var _dlx = dcos(angulo);
        var _dly = -dsin(angulo);
        var _comp = (40 + 26 * tam) * (0.55 + 0.45 * _ec);
        var _larg = (5.5 * tam) * (1 - _p01);
        var _cor_brilho = forte ? make_color_rgb(255, 70, 40) : make_color_rgb(255, 196, 130);
        if (!is_undefined(estilo) and estilo.id != "carmesim") _cor_brilho = forte ? estilo.brilho : estilo.meio;     // v1.17
        var _ax1 = x - _dlx * _comp * 0.5;
        var _ay1 = y - _dly * _comp * 0.5;
        var _ax2 = x + _dlx * _comp * 0.5;
        var _ay2 = y + _dly * _comp * 0.5;
        gpu_set_blendmode(bm_add);
        var _camadas = [[2.6, _cor_brilho, 0.45], [1, c_white, 0.95]];
        for (var _cm = 0; _cm < 2; _cm++)
        {
            var _lw = _larg * _camadas[_cm][0];
            draw_set_color(_camadas[_cm][1]);
            draw_set_alpha((1 - _p01) * _camadas[_cm][2]);
            // normal do risco = (-dly, dlx)
            var _m1x = x - _dly * _lw;
            var _m1y = y + _dlx * _lw;
            var _m2x = x + _dly * _lw;
            var _m2y = y - _dlx * _lw;
            draw_triangle(_ax1, _ay1, _m1x, _m1y, _m2x, _m2y, false);
            draw_triangle(_ax2, _ay2, _m1x, _m1y, _m2x, _m2y, false);
        }
        // onda de choque
        var _ra = (6 + 30 * tam) * _ec;
        draw_set_color(_cor_brilho);
        draw_set_alpha((1 - _p01) * 0.55);
        draw_circle(x, y, _ra, true);
        draw_circle(x, y, max(0, _ra - 1), true);
        if (forte)
        {
            draw_set_color(c_white);
            draw_set_alpha((1 - _p01) * 0.4);
            draw_circle(x, y, _ra * 0.7, true);
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
        draw_set_color(c_white);
    break;

    // ===== v1.17: EFEITOS DE ESPADA =====
    case "corte_lua":
        // lua crescente: grossa no meio, fina nas pontas; a ponta (fim do golpe) brilha
        // mais. Ela "se desenha" em 3 quadros e abre um pouco enquanto some.
        var _el = estilo;
        var _kl = 1 - _p01;
        var _rl = raio * tam * (1 + 0.18 * (1 - power(1 - _p01, 2)));
        var _aw1 = (dir == 1) ? a1 : 180 - a1;
        var _aw2 = (dir == 1) ? a2 : 180 - a2;
        var _larg = (forte ? 15 : 11) * tam;
        var _nseg = 18;
        var _mostra = max(1, round(_nseg * clamp((t + 1) / 3, 0, 1)));
        // camadas: [largura, cor, alfa, aditivo] (v1.17: todas aditivas, nada escuro)
        var _caml = [[1.9, _el.brilho, 0.3, true], [1, _el.meio, 0.7, true], [0.32, _el.miolo, 0.95, true]];
        for (var _c = 0; _c < 3; _c++)
        {
            gpu_set_blendmode(_caml[_c][3] ? bm_add : bm_normal);
            draw_primitive_begin(pr_trianglestrip);
            for (var _s = 0; _s <= _mostra; _s++)
            {
                var _f = _s / _nseg;
                var _ang = lerp(_aw1, _aw2, _f);
                var _gr = _larg * _caml[_c][0] * power(sin(pi * _f), 0.8);
                var _al = _kl * _caml[_c][2] * (0.25 + 0.75 * _f);
                var _rf = (_c == 2) ? _rl + _larg * 0.35 : _rl + _gr * 0.35;
                var _rd = (_c == 2) ? _rf - _gr : _rl - _gr * 0.65;
                draw_vertex_color(x + lengthdir_x(_rf, _ang), y + lengthdir_y(_rf, _ang), _caml[_c][1], _al);
                draw_vertex_color(x + lengthdir_x(_rd, _ang), y + lengthdir_y(_rd, _ang), _caml[_c][1], _al * 0.35);
            }
            draw_primitive_end();
        }
        gpu_set_blendmode(bm_normal);
    break;

    case "corte_x":
        var _ex = estilo;
        var _kx = 1 - _p01;
        var _comp = 62 * tam * (0.4 + 0.6 * clamp(t / 3, 0, 1)) * (1 + 0.2 * _p01);
        var _wx = 3.4 * tam * _kx;
        var _bx = (dir == 1) ? 0 : 180;
        gpu_set_blendmode(bm_add);
        for (var _r2 = 0; _r2 < 2; _r2++)
        {
            var _angx = _bx + ((_r2 == 0) ? 38 : -38) + angulo_x[_r2];
            var _dx = lengthdir_x(_comp, _angx);
            var _dy = lengthdir_y(_comp, _angx);
            draw_set_color(_ex.brilho);
            draw_set_alpha(_kx * 0.45);
            fx_losango(x - _dx, y - _dy, x + _dx, y + _dy, _wx * 3);
            draw_set_color(_ex.miolo);
            draw_set_alpha(_kx);
            fx_losango(x - _dx, y - _dy, x + _dx, y + _dy, _wx);
        }
        draw_set_color(_ex.brilho);
        draw_set_alpha(_kx * 0.55);
        draw_circle(x, y, 16 * tam * (1 + _p01), false);
        draw_set_color(_ex.miolo);
        draw_set_alpha(_kx * 0.8);
        draw_circle(x, y, 7 * tam * (1 + 0.5 * _p01), false);
        draw_set_alpha(_kx * 0.6);
        draw_circle(x, y, 10 + 34 * tam * _p01, true);
        gpu_set_blendmode(bm_normal);
    break;

    case "explosao_fogo":
        // v1.17: o golpe acerta: bola de fogo crescendo, línguas de fogo saindo e
        // subindo com o calor, brasas voando (tudo aditivo: nada escuro na tela)
        var _ef = estilo;
        var _kf = 1 - _p01;
        var _ce = 1 - power(1 - clamp(t / 6, 0, 1), 2);
        var _R = 15 * tam * (0.45 + 0.75 * _ce);
        gpu_set_blendmode(bm_add);
        for (var _s = 0; _s < array_length(raios); _s++)
        {
            var _rl = raios[_s];
            var _ang = angulo + _rl.ang;
            var _len = _R * (1.25 + 0.9 * _ce) * _rl.len;
            var _tx = x + lengthdir_x(_len, _ang);
            var _ty = y + lengthdir_y(_len, _ang) - 10 * tam * _p01;
            var _w = _R * 0.42 * _rl.larg * _kf;
            var _nx = lengthdir_x(_w, _ang + 90);
            var _ny = lengthdir_y(_w, _ang + 90);
            draw_set_color(_ef.brilho);
            draw_set_alpha(0.55 * _kf);
            draw_triangle(x + _nx, y + _ny, x - _nx, y - _ny, _tx, _ty, false);
            draw_set_color(_ef.meio);
            draw_set_alpha(0.75 * _kf);
            draw_triangle(x + _nx * 0.5, y + _ny * 0.5, x - _nx * 0.5, y - _ny * 0.5, lerp(x, _tx, 0.7), lerp(y, _ty, 0.7), false);
        }
        draw_set_color(_ef.brilho);
        draw_set_alpha(0.35 * _kf);
        draw_circle(x, y - 3 * _p01, _R * 1.35, false);
        draw_set_color(_ef.meio);
        draw_set_alpha(0.7 * _kf);
        draw_circle(x, y - 4 * _p01, _R, false);
        draw_set_color(_ef.miolo);
        draw_set_alpha(power(_kf, 1.5));
        draw_circle(x, y - 5 * _p01, _R * 0.55, false);
        if (flash > 0)
        {
            draw_set_color(c_white);
            draw_set_alpha(flash / 6 * 0.8);
            draw_circle(x, y, _R * 0.8, false);
        }
        for (var _b = 0; _b < array_length(parts); _b++)
        {
            var _pb = parts[_b];
            var _kb = clamp(_pb.v / _pb.vmax, 0, 1);
            draw_set_color(merge_color(_ef.brilho, _ef.miolo, _kb));
            draw_set_alpha(_kb);
            draw_circle(_pb.x, _pb.y, _pb.r, false);
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
        draw_set_color(c_white);
    break;

    case "rajada":
        var _er = estilo;
        var _kr = 1 - _p01;
        var _cr = 1 - power(1 - clamp(t / 4, 0, 1), 2);
        var _L = 170 * tam * _cr;
        var _hr = 9 * tam * _kr;
        var _x2r = x + dir * _L;
        var _xm = lerp(x, _x2r, 0.7);
        gpu_set_blendmode(bm_add);
        var _camr = [[2.2, _er.brilho, 0.4], [1, _er.meio, 0.85], [0.35, _er.miolo, 1]];
        for (var _c = 0; _c < 3; _c++)
        {
            var _hh = _hr * _camr[_c][0];
            draw_set_color(_camr[_c][1]);
            draw_set_alpha(_kr * _camr[_c][2]);
            draw_triangle(x, y, _xm, y - _hh, _xm, y + _hh, false);
            draw_triangle(_x2r, y, _xm, y - _hh, _xm, y + _hh, false);
        }
        draw_set_color(_er.miolo);
        draw_set_alpha(_kr * 0.9);
        for (var _z = 0; _z < array_length(raios) - 1; _z++)
        {
            var _z1 = raios[_z];
            var _z2 = raios[_z + 1];
            if (_z2.f > _cr) break;
            draw_line_width(x + dir * _z1.f * 170 * tam, y + _z1.o * tam, x + dir * _z2.f * 170 * tam, y + _z2.o * tam, 1.5);
        }
        gpu_set_blendmode(bm_normal);
    break;

    case "chamas_morte":
        gpu_set_blendmode(bm_add);
        // clarão branco-amarelado no instante da morte
        if (flash > 0)
        {
            var _ff = flash / 9;
            draw_set_color(make_color_rgb(255, 236, 190));
            draw_set_alpha(_ff * 0.8);
            draw_circle(x, y, 26 * tam * (1.5 - _ff * 0.5), false);
            draw_set_color(c_white);
            draw_set_alpha(_ff);
            draw_circle(x, y, 10 * tam, false);
        }
        // cada chama: gota de fogo em 3 camadas (vermelho, laranja, miolo amarelo)
        var _cores = [make_color_rgb(200, 40, 18), make_color_rgb(255, 120, 30), make_color_rgb(255, 232, 150)];
        var _escs = [1, 0.68, 0.38];
        var _alfs = [0.55, 0.7, 0.85];
        for (var _i = 0; _i < array_length(parts); _i++)
        {
            var _p = parts[_i];
            var _k = clamp(_p.v / _p.vmax, 0, 1);
            var _cresce = sin(pi * min(1, (1 - _k) * 1.6 + 0.15));
            var _tremula = 0.85 + 0.15 * sin(t * 1.3 + _p.fase * 7);
            for (var _c = 0; _c < 3; _c++)
            {
                var _r = _p.w * _escs[_c] * (0.4 + 0.6 * _k);
                var _hh = _p.h * _escs[_c] * _cresce * _tremula;
                var _ponta = sin((t + _p.fase * 4) / 3) * _p.w * 0.5;
                draw_set_color(_cores[_c]);
                draw_set_alpha(_alfs[_c] * min(1, _k * 1.8));
                draw_circle(_p.x, _p.y, _r, false);
                draw_triangle(_p.x - _r, _p.y, _p.x + _r, _p.y, _p.x + _ponta, _p.y - _r - _hh, false);
            }
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
        draw_set_color(c_white);
    break;

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
