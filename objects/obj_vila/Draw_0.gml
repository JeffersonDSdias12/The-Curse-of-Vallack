if (!ok or view_camera[0] == -1) exit;
var _cam = view_camera[0];
var _vx = camera_get_view_x(_cam);
var _vy = camera_get_view_y(_cam);
var _vw = camera_get_view_width(_cam);
var _vh = camera_get_view_height(_cam);
var _dy = _vy - (room_height - _vh);   // 0 com a câmera no chão (o horizonte não muda com o zoom)
gpu_set_texfilter(false);     // pixel art nítida

// =====================================================================
// LONGE: céu, lua, nuvens, montanhas, floresta e a vila ao longe
// =====================================================================
if (camada == "longe")
{
    var _c1 = make_color_rgb(24, 18, 36);
    var _c2 = make_color_rgb(76, 52, 76);
    var _c3 = make_color_rgb(146, 102, 106);
    draw_set_alpha(1);
    draw_rectangle_color(_vx - 2, _vy - 2, _vx + _vw + 2, _vy + _vh * 0.42, _c1, _c1, _c2, _c2, false);
    draw_rectangle_color(_vx - 2, _vy + _vh * 0.42, _vx + _vw + 2, _vy + _vh + 2, _c2, _c2, _c3, _c3, false);
    // lua cheia com o halo
    var _lx = _vx + _vw * 0.76;
    var _ly = _vy + _vh * 0.15;
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(200, 170, 170));
    for (var _k = 1; _k <= 4; _k++) { draw_set_alpha(0.05); draw_circle(_lx, _ly, 11 + _k * 9, false); }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(234, 224, 204));
    draw_circle(_lx, _ly, 11, false);
    draw_set_color(make_color_rgb(204, 192, 176));
    draw_circle(_lx - 3, _ly - 2, 2.5, false);
    draw_circle(_lx + 4, _ly + 3, 2, false);
    draw_circle(_lx + 1, _ly - 5, 1.5, false);
    // camadas com profundidade
    cenario_faixa(pecas.nuvens, _vx, _vw, 0.06, _vy + _vh * 0.28, t * 0.12);
    cenario_faixa(pecas.montanhas, _vx, _vw, 0.1, 606 + _dy * 0.8);
    cenario_faixa(pecas.floresta, _vx, _vw, 0.3, 652 + _dy * 0.65);
    cenario_faixa(pecas.vila_longe, _vx, _vw, 0.55, 672 + _dy * 0.45);
    // v1.14: o reino ardendo ao longe: o brilho dos incêndios nos escombros da
    // faixa distante e colunas de fumaça subindo (sem fumaça na qualidade baixa)
    var _vl = pecas.vila_longe;
    var _fgl = _vl.fogos;
    if (array_length(_fgl) > 0)
    {
        var _yl = 672 + _dy * 0.45 - _vl.h;
        var _oxl = _vx * (1 - 0.55);
        var _q = global.cfg_qualidade;
        for (var _xl = _oxl + floor((_vx - _oxl) / _vl.w) * _vl.w - _vl.w; _xl < _vx + _vw + 60; _xl += _vl.w)
        {
            for (var _j = 0; _j < array_length(_fgl); _j++)
            {
                var _f = _fgl[_j];
                var _fx = _xl + _f[0];
                if (_fx < _vx - 60 or _fx > _vx + _vw + 60) continue;
                var _fy = _yl + _f[1];
                var _fw = _f[2];
                var _sem = _j * 3.7;
                var _fl = 0.7 + 0.3 * sin(t * 0.09 + _sem) * sin(t * 0.031 + _sem * 2);
                gpu_set_blendmode(bm_add);
                draw_set_color(make_color_rgb(255, 96, 36));
                draw_set_alpha(0.16 * _fl);
                draw_ellipse(_fx - _fw * 0.9, _fy - 7, _fx + _fw * 0.9, _fy + 5, false);
                draw_set_color(make_color_rgb(255, 170, 80));
                draw_set_alpha(0.18 * _fl);
                draw_ellipse(_fx - _fw * 0.4, _fy - 3, _fx + _fw * 0.4, _fy + 2, false);
                gpu_set_blendmode(bm_normal);
                // coluna de fumaça (uma a cada duas fogueiras; mais alta na qualidade alta)
                if (_q > 0 and _j mod 2 == 0)
                {
                    var _n = (_q == 1) ? 6 : 10;
                    var _alt = (_q == 1) ? 150 : 210;
                    for (var _k = 0; _k < _n; _k++)
                    {
                        var _fase = t * 0.22 + _k * _alt / _n + _sem * 40;
                        _fase -= floor(_fase / _alt) * _alt;
                        draw_set_alpha(0.3 * (1 - _fase / _alt) * min(1, _fase / 18));
                        draw_set_color((_fase < 26) ? make_color_rgb(132, 66, 44) : make_color_rgb(64, 54, 62));     // a base iluminada pelo fogo
                        draw_circle(_fx + _fase * 0.16 + sin(t * 0.02 + _k + _sem) * 3, _fy - 6 - _fase, 5 + _fase * 0.12, false);
                    }
                }
            }
        }
        draw_set_alpha(1);
    }    draw_set_color(c_white);
    exit;
}

// =====================================================================
// PERTO: a vila de verdade, com os efeitos presos a cada peça
// =====================================================================
// terra escura atrás das casas (liga a vila ao longe ao chão)
draw_set_alpha(1);
draw_set_color(make_color_rgb(24, 26, 26));
draw_rectangle(_vx - 2, 641, _vx + _vw + 2, 700, false);
var _tt = current_time / 16;
var _forcas = [0.9, 0.65, 0.5, 0.4];      // força das chamas por fileira (0 = frente)
// v1.19: o fogo de cada fileira sai num lote só, depois das casas dessa fileira
// (e antes das da fileira da frente, que continuam cobrindo o fogo de trás)
var _fila_fogo = [];
var _plano_ant = -1;
for (var _i = 0; _i < array_length(layout); _i++)
{
    var _l = layout[_i];
    var _p = pecas[$ _l[0]];
    var _x = _l[1];
    var _b = _l[2];
    var _q = _l[3];
    var _e = _l[4];
    var _plano = (array_length(_l) > 5) ? _l[5] : 0;     // fileiras de trás: mais escuras (3 = a mais ao fundo)
    if (_plano != _plano_ant) { chamas_lote_desenhar(_fila_fogo); _fila_fogo = []; _plano_ant = _plano; }
    var _s = (array_length(_l) > 6) ? _l[6] : 1;         // v1.17: escala (casas 2x, o resto 1,5x)
    var _atras = _plano > 0;
    if (_x > _vx + _vw + 30 or _x + _p.w * _s < _vx - 30) continue;
    var _y0 = _b - _p.h * _s;
    var _sem = _i * 7.3;
    var _pisca = 0.75 + 0.25 * sin(_tt / 4 + _sem) * sin(_tt / 9.3 + _sem * 2);
    if (_l[0] == "ponte" and array_length(vaos) > 0) continue;     // v1.20: a ponte agora é de verdade (obj_terreno)
    // o rio passa por baixo da ponte
    if (_l[0] == "ponte")
    {
        var _ry = _b - 18;
        draw_set_color(make_color_rgb(28, 38, 58));
        draw_rectangle(_x - 30, _ry, _x + _p.w * _s + 30, _b + 8, false);
        gpu_set_blendmode(bm_add);
        draw_set_color(make_color_rgb(90, 110, 150));
        for (var _w = 0; _w < 9; _w++)
        {
            var _wx = _x - 20 + frac(_w * 0.37 + _tt * 0.004 * (1 + _w mod 3)) * (_p.w * _s + 40);
            draw_set_alpha(0.25);
            draw_line(_wx, _ry + 4 + (_w mod 4) * 4, _wx + 8 + (_w mod 3) * 4, _ry + 4 + (_w mod 4) * 4);
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
    // incêndio: a luz roxa da maldição sobe do telhado (v1.19: presa ao telhado,
    // não mais um oval em volta da casa inteira)
    if (_q == 1)
    {
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.12 * _pisca);
        draw_set_color(make_color_rgb(140, 40, 255));
        draw_ellipse(_x - _p.w * _s * 0.1, _y0 - 34 * _s, _x + _p.w * _s * 1.1, _y0 + _p.h * _s * 0.55, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
    var _tom = c_white;
    if (_plano == 3) _tom = make_color_rgb(62, 54, 76);
    else if (_plano == 2) _tom = make_color_rgb(84, 74, 96);
    else if (_atras) _tom = make_color_rgb(128, 116, 132);
    cenario_peca(_p, _x, _b, _e, _tom, _s);
    // v1.14: ruína fumegante: brasas brilhando no meio dos escombros
    if (_q == 2 and array_length(_p.fogos) > 0)
    {
        var _fr = _p.fogos[0];
        var _gx = cenario_ax(_p, _x, _e, _fr[0], _s);
        var _gy = _y0 + _fr[1] * _s;
        gpu_set_blendmode(bm_add);
        draw_set_color(make_color_rgb(255, 90, 30));
        draw_set_alpha((_atras ? 0.1 : 0.14) * _pisca);
        draw_ellipse(_gx - _fr[2] * 0.6 * _s, _gy - 6 * _s, _gx + _fr[2] * 0.6 * _s, _gy + 8 * _s, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
    gpu_set_blendmode(bm_add);
    // janelas acesas tremeluzindo (roxo-alaranjado nas casas em chamas)
    var _jan = _p.janelas;
    for (var _j = 0; _j < array_length(_jan); _j++)
    {
        var _jw = _jan[_j];
        var _jx = _e ? _x + (_p.w - _jw[0] - _jw[2]) * _s : _x + _jw[0] * _s;
        var _fl = 0.7 + 0.3 * sin(_tt / (3 + _j) + _sem + _j * 2);
        draw_set_alpha((_q == 1 ? 0.45 : 0.22) * _fl);
        draw_set_color((_q == 1) ? make_color_rgb(220, 110, 255) : make_color_rgb(255, 170, 70));
        draw_rectangle(_jx - 2 * _s, _y0 + (_jw[1] - 2) * _s, _jx + (_jw[2] + 1) * _s, _y0 + (_jw[1] + _jw[3] + 1) * _s, false);
    }
    // lampiões, lanternas e vitrais: halo de luz
    var _lz = _p.luzes;
    for (var _j = 0; _j < array_length(_lz); _j++)
    {
        var _lzx = cenario_ax(_p, _x, _e, _lz[_j][0], _s);
        var _lzy = _y0 + _lz[_j][1] * _s;
        var _r = _lz[_j][2] * _s;
        var _fl = 0.8 + 0.2 * sin(_tt / 5 + _j + _sem);
        draw_set_color((_l[0] == "igreja") ? make_color_rgb(200, 120, 255) : make_color_rgb(255, 170, 80));
        draw_set_alpha(0.07 * _fl);
        draw_circle(_lzx, _lzy, _r, false);
        draw_set_alpha(0.12 * _fl);
        draw_circle(_lzx, _lzy, _r * 0.5, false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    // chamas da maldição presas à construção (v1.19): saem dos rombos e das
    // janelas quebradas, correm pelo cume e por uma das águas, ardem nos escombros
    if (_q == 1 and (_plano < 3 or global.cfg_qualidade > 0))
    {
        // só a fileira da frente leva a camada do meio; as do fundo, o mínimo
        var _lod = (_plano >= 2) ? 2 : ((_plano == 1 or global.cfg_qualidade == 0) ? 1 : 0);
        var _fc = variable_struct_exists(_p, "focos") ? _p.focos : [];
        if (array_length(_fc) > 0)
        {
            for (var _j = 0; _j < array_length(_fc); _j++)
            {
                var _f = _fc[_j];
                if (_plano >= 2 and _f[5] == 2) continue;   // fileiras do fundo: o incêndio se lê pelos rombos e telhados
                // v1.19: vai para a fila da fileira (desenhada num lote só: chamas_lote_desenhar)
                array_push(_fila_fogo, [cenario_ax(_p, _x, _e, _f[0], _s), _y0 + _f[1] * _s, cenario_ax(_p, _x, _e, _f[2], _s), _y0 + _f[3] * _s,
                    _f[4] * _s * ((_f[5] == 1) ? 0.8 : 1), _tt + _sem * 10 + _j * 17, _forcas[_plano], _sem + _j * 3.1, 0, _f[5], _s, _lod]);
            }
        }
        else
        {
            var _fg = _p.fogos;
            for (var _j = 0; _j < array_length(_fg); _j++)
            {
                var _fx = cenario_ax(_p, _x, _e, _fg[_j][0], _s);
                desenhar_chamas(_fx, _y0 + _fg[_j][1] * _s, _fg[_j][2] * _s, (22 + _fg[_j][2] * 0.25) * _s, _tt + _sem * 10, _forcas[_plano], _sem);
            }
        }
    }
}
chamas_lote_desenhar(_fila_fogo);         // o fogo da última fileira
// muro, cerca e sebes da frente
for (var _i = 0; _i < array_length(frente); _i++)
{
    var _f = frente[_i];
    var _fp = pecas[$ _f[0]];
    if (_f[1] > _vx + _vw or _f[1] + _fp.w < _vx) continue;
    var _no_vao = false;      // v1.20: nada de muro ou cerca em cima do abismo
    for (var _v = 0; _v < array_length(vaos); _v++) if (_f[1] < vaos[_v][1] and _f[1] + _fp.w > vaos[_v][0]) _no_vao = true;
    if (_no_vao) continue;
    cenario_peca(_fp, _f[1], 680, false);     // v1.13: borda de trás da rua (o pé pisa dentro do calçamento)
}
// chão calçado (repete pela fase toda)
var _ch = pecas.chao;
for (var _cx = floor(_vx / _ch.w) * _ch.w; _cx < _vx + _vw; _cx += _ch.w) cenario_peca(_ch, _cx, 675 + _ch.h, false);
draw_set_color(c_white);
