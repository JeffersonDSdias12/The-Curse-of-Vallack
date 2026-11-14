if (view_camera[0] == -1) exit;
var _cam = view_camera[0];
var _vx = camera_get_view_x(_cam);
var _vy = camera_get_view_y(_cam);
var _vw = camera_get_view_width(_cam);
var _base = room_height + 260;      // v1.20: a câmera desce perto das pontes e o abismo continua fundo
var _tf = gpu_get_texfilter();

// ===== RUÍNAS na frente das casas (arcos, pilares com tocha e estandarte,
// muros quebrados): mais destruição na vila =====
if (pecas_ok)
{
    gpu_set_texfilter(true);
    var _tom_r = make_color_rgb(178, 160, 158);
    for (var _i = 0; _i < array_length(ruinas); _i++)
    {
        var _r = ruinas[_i];
        var _p = peca(_r[0]);
        if (is_undefined(_p) or _r[1] > _vx + _vw + 20 or _r[1] + _p[2] * PECA_ESC < _vx - 20) continue;
        peca_desenhar(_r[0], _r[1], chao_y + 3, _r[2], _tom_r);
        // o fogo da tocha dos pilares
        if (_r[0] == "parede35" or _r[0] == "parede36")
            cenario_luz(_r[1] + _p[2] * PECA_ESC * (_r[2] ? 0.3 : 0.7), chao_y + 3 - _p[3] * PECA_ESC * 0.62, 34, 0.8 + 0.2 * sin(t / 9 + _i), make_color_rgb(255, 150, 60));
    }
    gpu_set_texfilter(_tf);
}

// ===== ÁRVORES ASSOMBRADAS na estrada (balançam, olhos acesos) =====
for (var _i = 0; _i < array_length(arvores); _i++)
{
    var _a = arvores[_i];
    if (_a[0] < _vx - 140 or _a[0] > _vx + _vw + 140) continue;
    draw_sprite_hd(spr_arvore_assombrada, t / 12 + _i * 3, _a[0], chao_y + 3, (_a[1] ? -1.6 : 1.6), 1.6, 0, make_color_rgb(176, 164, 170), 1);
}

// ===== ABISMOS: vão escuro, beiradas quebradas e o brilho lá do fundo =====
for (var _i = 0; _i < array_length(abismos); _i++)
{
    var _x1 = abismos[_i][0];
    var _x2 = abismos[_i][1];
    if (_x2 < _vx - 40 or _x1 > _vx + _vw + 40) continue;
    var _yt = chao_y - 1;
    var _escuro = make_color_rgb(16, 9, 12);
    draw_set_alpha(1);
    draw_rectangle_color(_x1, _yt, _x2, _base, _escuro, _escuro, c_black, c_black, false);
    // beiradas de terra e pedra caindo para dentro do vão
    draw_set_color(make_color_rgb(44, 34, 32));
    for (var _k = 0; _k < 5; _k++)
    {
        var _yy = _yt + _k * 9;
        var _pp = 7 - _k;
        draw_triangle(_x1, _yy, _x1 + _pp + 3, _yy + 4, _x1, _yy + 9, false);
        draw_triangle(_x2, _yy, _x2 - _pp - 3, _yy + 5, _x2, _yy + 9, false);
    }
    draw_set_color(make_color_rgb(92, 78, 70));
    draw_line_width(_x1 - 2, _yt, _x1 + 6, _yt + 1, 2);
    draw_line_width(_x2 - 6, _yt + 1, _x2 + 2, _yt, 2);
    // lá no fundo: brasas subindo (vila em chamas) ou névoa roxa (castelo)
    gpu_set_blendmode(bm_add);
    var _cor = madeira ? make_color_rgb(255, 90, 30) : make_color_rgb(120, 40, 160);
    draw_set_alpha(0.16 + 0.05 * sin(t / 30 + _i));
    draw_set_color(_cor);
    draw_ellipse(_x1 + 4, room_height - 18, _x2 - 4, room_height + 30, false);
    for (var _k = 0; _k < 4; _k++)
    {
        var _f = frac(t / 140 + _k / 4 + _i * 0.37);
        var _bx = lerp(_x1 + 10, _x2 - 10, frac(_k * 0.618 + _i * 0.3)) + sin(t / 20 + _k) * 4;
        draw_set_alpha((1 - _f) * 0.6);
        draw_set_color(madeira ? make_color_rgb(255, 150, 60) : make_color_rgb(190, 110, 255));
        draw_circle(_bx, room_height + 10 - _f * 50, 1.3, false);
    }
    gpu_set_blendmode(bm_normal);
}
draw_set_alpha(1);

// ===== v1.20: PONTES QUE DESABAM (ravina funda + ponte) e PISO FRÁGIL =====
quedas_desenhar(_vx, _vw);

// ===== ESCADARIAS de madeira: degraus que sobem do chão, fechados com tábuas =====
for (var _i = 0; _i < array_length(escadas); _i++)
{
    var _e = escadas[_i];
    var _xa = _e[0], _xb = _e[1];
    if (max(_xa, _xb) < _vx - 20 or min(_xa, _xb) > _vx + _vw + 20) continue;
    var _n = max(1, round((chao_y - _e[2]) / 8));
    var _lw = abs(_xb - _xa) / _n;
    // o desenho fica meio herói (10 px) para o lado de baixo: a máscara pisa no
    // degrau com a quina de cima, então o degrau embaixo do CENTRO do corpo é o
    // que ele pisa de verdade (antes o pé parecia flutuar ou afundar na escada)
    var _sb = sign(_xb - _xa);
    var _xv = _xa - _sb * 10;
    for (var _k = 0; _k < _n; _k++)
    {
        var _ult = (_k == _n - 1) ? 10 : 0;      // o último degrau vai até a passarela / torre
        var _sx1 = (_sb > 0) ? _xv + _k * _lw : _xv - (_k + 1) * _lw - _ult;
        var _sx2 = (_sb > 0) ? _xv + (_k + 1) * _lw + _ult : _xv - _k * _lw;
        var _sy = chao_y - (_k + 1) * 8;
        madeira_tabuas(_sx1, _sy + 3, _sx2, chao_y, _k);
        // o degrau: tábua clara com sombra embaixo
        draw_set_color(make_color_rgb(150, 106, 64));
        draw_rectangle(_sx1 - 1, _sy, _sx2, _sy + 3, false);
        draw_set_color(make_color_rgb(196, 150, 96));
        draw_line(_sx1 - 1, _sy, _sx2, _sy);
        draw_set_color(make_color_rgb(30, 20, 12));
        draw_line(_sx1 - 1, _sy + 3, _sx2, _sy + 3);
    }
    // viga diagonal (banzo) e o poste do alto
    draw_set_color(make_color_rgb(44, 28, 16));
    draw_line_width(_xv, chao_y, _xb, _e[2] + 6, 4);
    var _xp = (_xb > _xa) ? _xb - 3 : _xb + 3;
    draw_set_color(make_color_rgb(40, 26, 16));
    draw_rectangle(_xp - 3, _e[2] - 18, _xp + 3, chao_y, false);
    draw_set_color(make_color_rgb(96, 64, 38));
    draw_rectangle(_xp - 2, _e[2] - 18, _xp + 2, chao_y, false);
}

// ===== TORRE DE VIGIA de madeira (sólida): tábuas, postes, travas e o parapeito =====
for (var _i = 0; _i < array_length(blocos); _i++)
{
    var _b = blocos[_i];
    if (_b[1] < _vx - 30 or _b[0] > _vx + _vw + 30) continue;
    madeira_tabuas(_b[0], _b[2] + 4, _b[1], chao_y, _i * 3);
    draw_set_color(make_color_rgb(44, 28, 16));
    draw_line_width(_b[0] + 4, _b[2] + 10, _b[1] - 4, chao_y - 6, 3);
    draw_line_width(_b[1] - 4, _b[2] + 10, _b[0] + 4, chao_y - 6, 3);
    draw_rectangle(_b[0], _b[2] + 4, _b[1], _b[2] + 8, false);
    draw_rectangle(_b[0], (_b[2] + chao_y) / 2, _b[1], (_b[2] + chao_y) / 2 + 3, false);
    // postes dos cantos subindo acima do piso, com o parapeito
    for (var _k = 0; _k < 2; _k++)
    {
        var _xp = (_k == 0) ? _b[0] + 2 : _b[1] - 2;
        draw_set_color(make_color_rgb(36, 22, 14));
        draw_rectangle(_xp - 3, _b[2] - 20, _xp + 3, chao_y, false);
        draw_set_color(make_color_rgb(104, 70, 42));
        draw_rectangle(_xp - 2, _b[2] - 20, _xp + 2, chao_y, false);
    }
    draw_set_color(make_color_rgb(120, 84, 50));
    draw_line_width(_b[0] + 2, _b[2] - 16, _b[1] - 2, _b[2] - 16, 2);
    // piso de tábuas por cima (um pouco mais largo)
    draw_set_color(make_color_rgb(132, 92, 54));
    draw_rectangle(_b[0] - 5, _b[2], _b[1] + 5, _b[2] + 5, false);
    draw_set_color(make_color_rgb(190, 144, 90));
    draw_line(_b[0] - 5, _b[2], _b[1] + 5, _b[2]);
    draw_set_color(make_color_rgb(24, 16, 10));
    draw_rectangle(_b[0] - 5, _b[2], _b[1] + 5, _b[2] + 5, true);
}

// ===== ANDAIME ALTO de madeira (laje sólida com postes até o chão) =====
for (var _i = 0; _i < array_length(plataformas); _i++)
{
    var _pl = plataformas[_i];
    if (array_length(_pl) < 4 or _pl[3] != 1) continue;
    var _x1 = _pl[0], _x2 = _pl[1], _yt = _pl[2];
    if (_x2 < _vx - 40 or _x1 > _vx + _vw + 40) continue;
    var _yb = _yt + PLATAFORMA_ALT;
    // postes e travas em X entre eles
    var _ant = -1;
    for (var _xp = _x1 + 6; _xp <= _x2 - 5.5; _xp += (_x2 - _x1 - 12) / max(1, round((_x2 - _x1) / 96)))
    {
        if (_ant >= 0)
        {
            draw_set_color(make_color_rgb(46, 30, 18));
            var _ym = (_yb + chao_y) / 2;
            draw_line_width(_ant, _yb + 6, _xp, _ym, 3);
            draw_line_width(_xp, _yb + 6, _ant, _ym, 3);
            draw_line_width(_ant, _ym, _xp, chao_y - 4, 3);
            draw_line_width(_xp, _ym, _ant, chao_y - 4, 3);
            draw_line_width(_ant, _ym, _xp, _ym, 2);
        }
        draw_set_color(make_color_rgb(30, 20, 14));
        draw_rectangle(_xp - 3, _yb, _xp + 3, chao_y, false);
        draw_set_color(make_color_rgb(88, 58, 34));
        draw_rectangle(_xp - 2, _yb, _xp + 2, chao_y, false);
        _ant = _xp;
    }
    // piso de tábuas
    draw_set_alpha(0.35);
    draw_set_color(c_black);
    draw_rectangle(_x1 + 3, _yt + 5, _x2 + 3, _yb + 5, false);
    draw_set_alpha(1);
    draw_rectangle_color(_x1, _yt, _x2, _yb, make_color_rgb(132, 92, 54), make_color_rgb(132, 92, 54), make_color_rgb(78, 52, 30), make_color_rgb(78, 52, 30), false);
    draw_set_color(make_color_rgb(46, 30, 18));
    for (var _xx = _x1 + 18; _xx < _x2 - 4; _xx += 18) draw_line(_xx, _yt + 2, _xx, _yb - 1);
    draw_line(_x1, _yt + PLATAFORMA_ALT * 0.55, _x2, _yt + PLATAFORMA_ALT * 0.55);
    draw_set_color(make_color_rgb(186, 140, 86));
    draw_line_width(_x1, _yt + 1, _x2, _yt + 1, 2);
    draw_set_color(make_color_rgb(24, 16, 10));
    draw_rectangle(_x1, _yt, _x2, _yb, true);
}

// ===== ILHAS de terra flutuantes (mão única, peças do Alex) =====
if (pecas_ok)
{
    gpu_set_texfilter(true);
    for (var _i = 0; _i < array_length(ilhas); _i++)
    {
        var _il = ilhas[_i];
        var _p = peca(_il[2]);
        if (is_undefined(_p)) continue;
        var _w = _p[2] * PECA_ESC, _h = _p[3] * PECA_ESC;
        if (_il[0] + _w / 2 < _vx - 20 or _il[0] - _w / 2 > _vx + _vw + 20) continue;
        // sombra no chão lá embaixo
        draw_set_alpha(0.18);
        draw_set_color(c_black);
        draw_ellipse(_il[0] - _w * 0.4, chao_y - 3, _il[0] + _w * 0.4, chao_y + 3, false);
        draw_set_alpha(1);
        peca_desenhar(_il[2], _il[0] - _w / 2, _il[1] - _h * 0.1 + _h, (_i mod 2) == 1);
    }
    gpu_set_texfilter(_tf);
}
// ===== PASSARELAS de madeira (mão única): tábuas, corrimão de corda e postes =====
for (var _i = 0; _i < array_length(pontes); _i++)
{
    var _x1 = pontes[_i][0];
    var _x2 = pontes[_i][1];
    var _yt = pontes[_i][2];
    if (_x2 < _vx - 40 or _x1 > _vx + _vw + 40) continue;
    var _yb = _yt + 10;
    // postes até o chão
    for (var _px = _x1 + 10; _px < _x2; _px += 96)
    {
        draw_set_color(make_color_rgb(30, 20, 14));
        draw_rectangle(_px - 3, _yb, _px + 3, chao_y, false);
        draw_set_color(make_color_rgb(84, 56, 34));
        draw_rectangle(_px - 2, _yb, _px + 2, chao_y, false);
    }
    // sombra, tábuas e frestas
    draw_set_alpha(0.35);
    draw_set_color(c_black);
    draw_rectangle(_x1 + 3, _yt + 5, _x2 + 3, _yb + 5, false);
    draw_set_alpha(1);
    draw_rectangle_color(_x1, _yt, _x2, _yb, make_color_rgb(132, 92, 54), make_color_rgb(132, 92, 54), make_color_rgb(78, 52, 30), make_color_rgb(78, 52, 30), false);
    draw_set_color(make_color_rgb(46, 30, 18));
    for (var _xx = _x1 + 12; _xx < _x2 - 2; _xx += 12) draw_line(_xx, _yt + 2, _xx + ((_xx div 12) mod 2), _yb - 1);
    draw_set_color(make_color_rgb(186, 140, 86));
    draw_line_width(_x1, _yt + 1, _x2, _yt + 1, 2);
    draw_set_color(make_color_rgb(24, 16, 10));
    draw_rectangle(_x1, _yt, _x2, _yb, true);
    // corrimão de corda entre postes baixos
    var _ant = -1;
    for (var _px = _x1 + 4; _px <= _x2 - 4; _px += 48)
    {
        draw_set_color(make_color_rgb(64, 42, 26));
        draw_rectangle(_px - 1, _yt - 16, _px + 1, _yt, false);
        if (_ant >= 0)
        {
            draw_set_color(make_color_rgb(120, 96, 64));
            var _mx = (_ant + _px) / 2;
            draw_line(_ant, _yt - 15, _mx, _yt - 11);
            draw_line(_mx, _yt - 11, _px, _yt - 15);
        }
        _ant = _px;
    }
}

// ===== PLATAFORMAS =====
var _h = PLATAFORMA_ALT;
for (var _i = 0; _i < array_length(plataformas); _i++)
{
    var _x1 = plataformas[_i][0];
    var _x2 = plataformas[_i][1];
    var _yt = plataformas[_i][2];
    if (array_length(plataformas[_i]) >= 4 and plataformas[_i][3] == 1) continue;   // o adarve já foi desenhado
    if (_x2 < _vx - 40 or _x1 > _vx + _vw + 40) continue;
    var _yb = _yt + _h;
    if (madeira)
    {
        // andaime de madeira: dois postes até o chão e tábuas por cima
        draw_set_alpha(1);
        var _postes = [_x1 + 8, _x2 - 8];
        for (var _k = 0; _k < 2; _k++)
        {
            draw_set_color(make_color_rgb(30, 20, 14));
            draw_rectangle(_postes[_k] - 3, _yb, _postes[_k] + 3, chao_y, false);
            draw_set_color(make_color_rgb(84, 56, 34));
            draw_rectangle(_postes[_k] - 2, _yb, _postes[_k] + 2, chao_y, false);
        }
        draw_set_color(make_color_rgb(64, 42, 26));
        draw_line_width(_postes[0], _yb + 4, _postes[1], chao_y - 10, 2);
        draw_set_alpha(0.35);
        draw_set_color(c_black);
        draw_rectangle(_x1 + 3, _yt + 5, _x2 + 3, _yb + 5, false);
        draw_set_alpha(1);
        draw_rectangle_color(_x1, _yt, _x2, _yb, make_color_rgb(132, 92, 54), make_color_rgb(132, 92, 54), make_color_rgb(78, 52, 30), make_color_rgb(78, 52, 30), false);
        draw_set_color(make_color_rgb(46, 30, 18));
        for (var _xx = _x1 + 18; _xx < _x2 - 4; _xx += 18) draw_line(_xx, _yt + 2, _xx, _yb - 1);
        draw_line(_x1, _yt + _h * 0.55, _x2, _yt + _h * 0.55);
        draw_set_color(make_color_rgb(186, 140, 86));
        draw_line_width(_x1, _yt + 1, _x2, _yt + 1, 2);
        draw_set_color(make_color_rgb(24, 16, 10));
        draw_rectangle(_x1, _yt, _x2, _yb, true);
    }
    else
    {
        // laje de pedra do castelo, presa por duas correntes que somem no alto
        draw_set_alpha(1);
        var _ancoras = [_x1 + 9, _x2 - 9];
        for (var _k = 0; _k < 2; _k++)
        {
            for (var _cy = _yt - 4; _cy > _vy - 10; _cy -= 7)
            {
                draw_set_color(make_color_rgb(20, 18, 20));
                draw_rectangle(_ancoras[_k] - 2, _cy - 5, _ancoras[_k] + 2, _cy, false);
                draw_set_color(make_color_rgb(96, 92, 98));
                draw_rectangle(_ancoras[_k] - 1, _cy - 4, _ancoras[_k] + 1, _cy - 1, (_cy div 7) mod 2 == 0);
            }
        }
        draw_set_alpha(0.35);
        draw_set_color(c_black);
        draw_rectangle(_x1 + 3, _yt + 5, _x2 + 3, _yb + 5, false);
        draw_set_alpha(1);
        draw_rectangle_color(_x1, _yt, _x2, _yb, make_color_rgb(84, 74, 80), make_color_rgb(84, 74, 80), make_color_rgb(40, 34, 38), make_color_rgb(40, 34, 38), false);
        draw_set_color(make_color_rgb(26, 21, 24));
        for (var _xx = _x1 + 22; _xx < _x2 - 4; _xx += 22) draw_line(_xx, _yt + 3, _xx, _yb - 1);
        draw_set_color(make_color_rgb(164, 150, 154));
        draw_line_width(_x1, _yt + 1, _x2, _yt + 1, 2);
        draw_set_color(make_color_rgb(14, 10, 12));
        draw_rectangle(_x1, _yt, _x2, _yb, true);
        // mísulas (apoios) nas pontas
        draw_set_color(make_color_rgb(52, 44, 48));
        draw_triangle(_x1 + 3, _yb, _x1 + 17, _yb, _x1 + 3, _yb + 10, false);
        draw_triangle(_x2 - 3, _yb, _x2 - 17, _yb, _x2 - 3, _yb + 10, false);
    }
}
draw_set_alpha(1);
draw_set_color(c_white);

// =====================================================================
// v1.14: CAMINHOS DE ESCALAR, PONTES DE CORDA E PLATAFORMAS PENDURADAS
// =====================================================================
// ----- o forte da chave: estandarte rasgado, corrimão de troncos e tochas -----
if (!is_undefined(chave_dados))
{
    var _ar = chave_dados.arena;
    var _fx1 = _ar[0] - 8, _fx2 = _ar[1] + 8, _fy = _ar[2];
    if (_fx2 > _vx - 60 and _fx1 < _vx + _vw + 60)
    {
        var _mx = _fx1 + 4;
        draw_set_color(make_color_rgb(40, 26, 16));
        draw_rectangle(_mx - 2, _fy - 70, _mx + 2, _fy, false);
        var _ond = sin(t / 14) * 3;
        draw_set_color(make_color_rgb(120, 16, 18));
        draw_triangle(_mx + 2, _fy - 68, _mx + 30 + _ond, _fy - 62, _mx + 2, _fy - 44, false);
        draw_triangle(_mx + 30 + _ond, _fy - 62, _mx + 26 + _ond * 1.4, _fy - 48, _mx + 2, _fy - 44, false);
        draw_set_color(make_color_rgb(64, 42, 26));
        for (var _xx = _fx1 + 14; _xx < _fx1 + 60; _xx += 22) draw_rectangle(_xx - 1, _fy - 18, _xx + 1, _fy, false);
        draw_line_width(_fx1 + 14, _fy - 17, _fx1 + 58, _fy - 17, 2);
        for (var _k = 0; _k < 2; _k++)
        {
            var _tx = (_k == 0) ? _fx1 + 70 : _fx2 - 14;
            draw_set_color(make_color_rgb(50, 34, 20));
            draw_rectangle(_tx - 1, _fy - 26, _tx + 1, _fy, false);
            cenario_luz(_tx, _fy - 30, 40, 0.75 + 0.25 * sin(t / 5 + _k * 3), make_color_rgb(255, 150, 60));
            desenhar_chamas(_tx, _fy - 26, 7, 13, t + _k * 40, 0.85, _k * 5);
        }
    }
}
// ----- plataformas penduradas: tábuas presas por cordas (no forte ou numa forca) -----
for (var _i = 0; _i < array_length(suspensas); _i++)
{
    var _s = suspensas[_i];
    var _x1 = _s[0], _x2 = _s[1], _yt = _s[2], _ya = _s[3];
    if (_x2 < _vx - 60 or _x1 > _vx + _vw + 60) continue;
    var _bal = sin(t / 40 + _i) * 1.5;       // balanço leve (só no desenho)
    if (_s[4] >= 0)
    {
        // a forca: poste do chão até o alto, o braço por cima e a mão-francesa
        var _px = _s[4];
        draw_set_color(make_color_rgb(30, 20, 14));
        draw_rectangle(_px - 4, _ya - 6, _px + 4, chao_y, false);
        draw_rectangle(_px - 4, _ya - 6, _x2 + 4, _ya, false);
        draw_set_color(make_color_rgb(88, 58, 34));
        draw_rectangle(_px - 3, _ya - 6, _px + 3, chao_y, false);
        draw_set_color(make_color_rgb(96, 64, 38));
        draw_rectangle(_px - 3, _ya - 5, _x2 + 3, _ya - 1, false);
        draw_set_color(make_color_rgb(46, 30, 18));
        draw_line_width(_px, _ya + 22, _px + 24, _ya, 3);
    }
    draw_set_color(make_color_rgb(150, 120, 80));
    draw_line_width(_x1 + 4, _ya, _x1 + 4 + _bal, _yt, 1.5);
    draw_line_width(_x2 - 4, _ya, _x2 - 4 + _bal, _yt, 1.5);
    draw_set_alpha(0.3);
    draw_set_color(c_black);
    draw_rectangle(_x1 + 2 + _bal, _yt + 4, _x2 + 2 + _bal, _yt + 10, false);
    draw_set_alpha(1);
    madeira_tabuas(_x1 + _bal, _yt, _x2 + _bal, _yt + 7, _i);
    draw_set_color(make_color_rgb(186, 140, 86));
    draw_line(_x1 + _bal, _yt, _x2 + _bal, _yt);
    draw_set_color(make_color_rgb(24, 16, 10));
    draw_rectangle(_x1 + _bal, _yt, _x2 + _bal, _yt + 7, true);
}
// ----- pontes de corda: tábuas soltas com a barriga no meio e os corrimãos -----
for (var _i = 0; _i < array_length(pontes_corda); _i++)
{
    var _b = pontes_corda[_i];
    var _x1 = _b[0], _x2 = _b[1], _yt = _b[2];
    if (_x2 < _vx - 60 or _x1 > _vx + _vw + 60) continue;
    var _w = _x2 - _x1;
    for (var _k = 0; _k < 2; _k++)
    {
        var _px = (_k == 0) ? _x1 : _x2;
        draw_set_color(make_color_rgb(30, 20, 14));
        draw_rectangle(_px - 3, _yt - 22, _px + 3, chao_y, false);
        draw_set_color(make_color_rgb(88, 58, 34));
        draw_rectangle(_px - 2, _yt - 22, _px + 2, chao_y, false);
    }
    for (var _xx = _x1 + 2; _xx < _x2 - 2; _xx += 7)
    {
        var _yy = _yt + 3 * sin((_xx - _x1) / _w * pi);
        draw_set_color(((_xx div 7) mod 2 == 0) ? make_color_rgb(110, 76, 44) : make_color_rgb(94, 64, 38));
        draw_rectangle(_xx, _yy, _xx + 5, _yy + 4, false);
        draw_set_color(make_color_rgb(30, 20, 12));
        draw_rectangle(_xx, _yy, _xx + 5, _yy + 4, true);
    }
    draw_set_color(make_color_rgb(150, 120, 80));
    var _ax = _x1, _ay = _yt, _ahy = _yt - 20;
    for (var _s = 1; _s <= 12; _s++)
    {
        var _u = _s / 12;
        var _bx = _x1 + _w * _u;
        var _by = _yt + 3 * sin(_u * pi);
        var _hy = _yt - 20 + 7 * sin(_u * pi);
        draw_line(_ax, _ay, _bx, _by);
        draw_line(_ax, _ahy, _bx, _hy);
        if (_s mod 2 == 0) draw_line(_bx, _hy, _bx, _by);
        _ax = _bx; _ay = _by; _ahy = _hy;
    }
}
// ----- escadas de mão, cordas e correntes -----
for (var _i = 0; _i < array_length(escalar); _i++)
{
    var _e = escalar[_i];
    var _ex = _e[0], _y1 = _e[1], _y2 = _e[2];
    if (_ex < _vx - 30 or _ex > _vx + _vw + 30) continue;
    if (_e[3] == "escada")
    {
        draw_set_color(make_color_rgb(30, 20, 14));
        draw_rectangle(_ex - 10, _y1 - 8, _ex - 6, _y2, false);
        draw_rectangle(_ex + 6, _y1 - 8, _ex + 10, _y2, false);
        draw_set_color(make_color_rgb(104, 70, 42));
        draw_rectangle(_ex - 9, _y1 - 8, _ex - 7, _y2, false);
        draw_rectangle(_ex + 7, _y1 - 8, _ex + 9, _y2, false);
        for (var _yy = _y2 - 8; _yy > _y1 - 4; _yy -= 10)
        {
            draw_set_color(make_color_rgb(30, 20, 14));
            draw_rectangle(_ex - 7, _yy - 1, _ex + 7, _yy + 2, false);
            draw_set_color(make_color_rgb(132, 92, 54));
            draw_line(_ex - 6, _yy, _ex + 6, _yy);
        }
    }
    else if (_e[3] == "corda")
    {
        var _bal = sin(t / 30 + _i * 2) * 2;
        draw_set_color(make_color_rgb(40, 28, 18));
        draw_rectangle(_ex - 7, _y1 - 6, _ex + 7, _y1 - 2, false);          // a viga onde ela está amarrada
        var _ax = _ex, _ay = _y1 - 2;
        for (var _s = 1; _s <= 16; _s++)
        {
            var _u = _s / 16;
            var _bx = _ex + _bal * _u * _u;
            var _by = lerp(_y1 - 2, _y2, _u);
            draw_set_color(make_color_rgb(70, 52, 32));
            draw_line_width(_ax, _ay, _bx, _by, 3.5);
            draw_set_color(make_color_rgb(168, 134, 88));
            draw_line_width(_ax - 0.5, _ay, _bx - 0.5, _by, 1.5);
            _ax = _bx; _ay = _by;
        }
        draw_set_color(make_color_rgb(120, 92, 58));
        for (var _yy = _y1 + 14; _yy < _y2 - 4; _yy += 18)
        {
            var _u = (_yy - _y1) / (_y2 - _y1);
            draw_ellipse(_ex + _bal * _u * _u - 3, _yy - 2, _ex + _bal * _u * _u + 3, _yy + 2, false);
        }
        draw_set_color(make_color_rgb(168, 134, 88));
        draw_line(_ax, _y2, _ax - 2, _y2 + 5);
        draw_line(_ax, _y2, _ax + 2, _y2 + 5);
    }
    else
    {
        for (var _yy = _y1 - 4; _yy < _y2; _yy += 7)
        {
            draw_set_color(make_color_rgb(20, 18, 20));
            draw_rectangle(_ex - 3, _yy, _ex + 3, _yy + 6, false);
            draw_set_color(make_color_rgb(110, 106, 112));
            draw_rectangle(_ex - 2, _yy + 1, _ex + 2, _yy + 5, ((_yy div 7) mod 2) == 0);
        }
    }
}
draw_set_alpha(1);
draw_set_color(c_white);
