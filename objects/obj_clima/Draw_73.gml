// DRAW END: tempestade por cima do mundo
if (view_camera[0] == -1) exit;
var _vx = camera_get_view_x(view_camera[0]);
var _vy = camera_get_view_y(view_camera[0]);
var _vw = camera_get_view_width(view_camera[0]);
var _vh = camera_get_view_height(view_camera[0]);

// clarão: dois piscos (forte, apaga, forte de novo, some)
var _flash = 0;
if (relampago > 0)
{
    var _p = 1 - relampago / relampago_max;           // 0 -> 1
    if (_p < 0.12) _flash = 1;
    else if (_p < 0.22) _flash = 0.25;
    else if (_p < 0.34) _flash = 0.85;
    else _flash = max(0, 1 - (_p - 0.34) / 0.66) * 0.6;
}

// tom de tempestade: cena mais escura e fria (o clarão tira a escuridão)
draw_set_alpha(0.26 * (1 - _flash * 0.8));
draw_set_color(make_color_rgb(14, 18, 40));
draw_rectangle(_vx - 4, _vy - 4, _vx + _vw + 4, _vy + _vh + 4, false);

// névoa rente ao chão
if (chao_y >= 0) retangulo_gradiente(_vx - 4, chao_y - 110, _vx + _vw + 4, chao_y + 12, make_color_rgb(120, 130, 160), 0, make_color_rgb(120, 130, 160), 0.24);

// v1.19: chuva e respingos em POUCOS lotes (alfa por vértice). Antes cada gota
// trocava o alfa e virava um desenho separado (centenas de lotes por quadro)
draw_set_alpha(1);
// chuva: camada de trás (fina) — uma lista de linhas
var _ct = make_color_rgb(165, 185, 225);
draw_primitive_begin(pr_linelist);
for (var _i = 0; _i < array_length(gotas); _i++)
{
    var _g = gotas[_i];
    if (_g.perto) continue;
    var _ga = min(1, _g.a * (1 + _flash * 0.6));
    draw_vertex_colour(_g.x, _g.y, _ct, _ga);
    draw_vertex_colour(_g.x - vento / _g.vel * _g.comp, _g.y - _g.comp, _ct, _ga);
}
draw_primitive_end();
// chuva: camada da frente (mais clara e mais longa) — outra lista de linhas
// (no modo VM cada vértice é uma chamada: 2 por gota é o mais barato)
var _cf = make_color_rgb(205, 220, 250);
draw_primitive_begin(pr_linelist);
for (var _i2 = 0; _i2 < array_length(gotas); _i2++)
{
    var _g2 = gotas[_i2];
    if (!_g2.perto) continue;
    var _ga2 = min(1, _g2.a * (1 + _flash * 0.5));
    draw_vertex_colour(_g2.x, _g2.y, _cf, _ga2);
    draw_vertex_colour(_g2.x - vento * 1.3 / _g2.vel * _g2.comp, _g2.y - _g2.comp, _cf, _ga2);
}
draw_primitive_end();

// respingos no chão — uma lista de linhas (a coroa dos grossos: um losango achatado)
var _cr = make_color_rgb(205, 220, 245);
draw_primitive_begin(pr_linelist);
for (var _r = 0; _r < array_length(respingos); _r++)
{
    var _s = respingos[_r];
    var _q = _s.t / 12;
    var _k = _s.g ? 1.5 : 1;
    var _ra = 0.65 * (1 - _q), _d = (3 + 3 * _q) * _k;
    draw_vertex_colour(_s.x, _s.y, _cr, _ra); draw_vertex_colour(_s.x - _d, _s.y - _d, _cr, _ra);
    draw_vertex_colour(_s.x, _s.y, _cr, _ra); draw_vertex_colour(_s.x + _d, _s.y - _d, _cr, _ra);
    if (_s.g)
    {
        var _ex = 4 * _q + 1;
        draw_vertex_colour(_s.x - _ex, _s.y, _cr, _ra); draw_vertex_colour(_s.x, _s.y - 1, _cr, _ra);
        draw_vertex_colour(_s.x, _s.y - 1, _cr, _ra); draw_vertex_colour(_s.x + _ex, _s.y, _cr, _ra);
        draw_vertex_colour(_s.x + _ex, _s.y, _cr, _ra); draw_vertex_colour(_s.x, _s.y + 1, _cr, _ra);
        draw_vertex_colour(_s.x, _s.y + 1, _cr, _ra); draw_vertex_colour(_s.x - _ex, _s.y, _cr, _ra);
    }
}
draw_primitive_end();

// relâmpago: clarão que ilumina a tela e raio com galhos
if (_flash > 0)
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_flash * 0.5);
    draw_set_color(make_color_rgb(190, 205, 255));
    draw_rectangle(_vx - 4, _vy - 4, _vx + _vw + 4, _vy + _vh + 4, false);
    if (_flash > 0.5 and array_length(raio) > 1)
    {
        // brilho em volta do raio
        draw_set_alpha(0.35 * _flash);
        draw_set_color(make_color_rgb(140, 160, 255));
        for (var _k2 = 0; _k2 < array_length(raio) - 1; _k2++) draw_line_width(raio[_k2][0], raio[_k2][1], raio[_k2 + 1][0], raio[_k2 + 1][1], 7);
        draw_set_alpha(_flash);
        draw_set_color(make_color_rgb(240, 245, 255));
        for (var _k3 = 0; _k3 < array_length(raio) - 1; _k3++) draw_line_width(raio[_k3][0], raio[_k3][1], raio[_k3 + 1][0], raio[_k3 + 1][1], 2.2);
        draw_set_alpha(_flash * 0.8);
        for (var _b = 0; _b < array_length(galhos); _b++)
        {
            var _gl = galhos[_b];
            for (var _m = 0; _m < array_length(_gl) - 1; _m++) draw_line_width(_gl[_m][0], _gl[_m][1], _gl[_m + 1][0], _gl[_m + 1][1], 1.2);
        }
    }
    gpu_set_blendmode(bm_normal);
}
desenho_resetar();
