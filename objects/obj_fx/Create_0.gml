// =====================================================================
//  obj_fx — efeitos dos golpes e especiais (desenhados por código)
//  tipos: poeira, onda_chao, rachaduras, faiscas_tela, carga, pedras
//         (v1.4) faiscas_golpe, sangue, aparar, escudo_quebrado, lascas,
//         fumaca, brasas, entulho, corte
// =====================================================================
tipo = "";
tam = 1;
dir = 1;
t = 0;
vida = 40;
parts = [];
fendas = [];
flash = 0;              // brilho no ponto do impacto
gen = false;            // partículas genéricas (gravidade, giro, cor própria)
forte = false;          // corte de golpe pesado / especial (vermelho e maior)
angulo = 0;             // direção do risco do corte
// v1.17: efeitos de espada (lua crescente, cortes em X, explosão de fogo, rajada)
a1 = 0;                 // arco da lua crescente (graus, para quem olha para a direita)
a2 = 0;
raio = 40;
raios = [];             // pontas da estrela / raios de tinta / zigue-zague da rajada
angulo_x = [0, 0];      // inclinação de cada risco do corte em X
estilo = undefined;     // cores do estilo de lâmina (scr_v117)
descartado = false;     // v1.18: cortado pelo orçamento de efeitos (some no próximo passo)

// partícula genérica
part_add = function(_x, _y, _vx, _vy, _r, _v, _cor, _g, _forma, _add)
{
    array_push(parts, { x: _x, y: _y, vx: _vx, vy: _vy, r: _r, v: _v, vmax: _v, cor: _cor, g: _g,
        rot: random(360), vr: random_range(-14, 14), forma: _forma, add: _add });
};

fx_iniciar = function()
{
    var _q = global.cfg_qualidade;           // 0 baixa, 1 média, 2 alta
    var _mult = (_q == 0) ? 0.4 : (_q == 1 ? 0.7 : 1);
    // v1.18: orçamento dos efeitos de combate (scr_cenario). Descartado, a instância
    // não desenha nada e se destrói no próximo passo (quem a criou ainda pode
    // escrever nela, como o "corte" faz com .forte, sem erro).
    var _orc = fx_orcamento(tipo, x, y);
    if (_orc <= 0) { descartado = true; return; }
    _mult *= _orc;
    switch (tipo)
    {
        case "poeira":
            vida = 34;
            repeat (round(14 * tam * _mult) + 3)
            {
                array_push(parts, { x: x + random_range(-24, 24) * tam, y: y - random(6), vx: random_range(-1.6, 1.6) * tam, vy: random_range(-1.4, -0.2),
                    r: random_range(5, 11) * tam, v: random_range(24, 34) });
            }
        break;

        case "onda_chao":
            vida = 28;
        break;

        case "corte":
            // risco de luz no ponto do acerto, na diagonal do golpe
            vida = 13;
            depth = -130;
            angulo = ((dir == 1) ? -28 : 208) + random_range(-14, 14);
            estilo = espada_estilo_atual();
        break;

        // ----- v1.17: EFEITOS DE ESPADA (cores do estilo de lâmina do PERFIL) -----
        case "corte_lua":           // a lua crescente do corte
            vida = forte ? 13 : 11;
            estilo = espada_estilo_atual();
        break;
        case "corte_x":             // dois riscos finos cruzados e o clarão no meio
            vida = 13;
            estilo = espada_estilo_atual();
            angulo_x = [random_range(-12, 12), random_range(-12, 12)];
        break;
        // ----- v1.17: FOGO (a espada em chamas) -----
        case "explosao_fogo":       // o golpe acerta: bola de fogo, línguas de fogo e brasas
            vida = 20;
            flash = 6;
            estilo = espada_estilo_atual();
            angulo = random(360);
            var _nl = (_q == 0) ? 7 : ((_q == 1) ? 10 : 13);
            for (var _s = 0; _s < _nl; _s++) array_push(raios, { ang: _s * 360 / _nl + random_range(-14, 14), len: random_range(0.7, 1.25), larg: random_range(0.7, 1.2) });
            repeat (round((6 + 6 * tam) * _mult))
            {
                var _ab = random(360);
                var _vb = random_range(1.2, 4.2) * tam;
                array_push(parts, { x: x, y: y, vx: lengthdir_x(_vb, _ab) + dir * 0.6, vy: lengthdir_y(_vb, _ab) - 1.2, r: random_range(1, 2.2), v: random_range(16, 30), vmax: 30 });
            }
        break;
        case "chamas_corpo":        // o inimigo derrotado ardendo (no lugar da fumaça negra)
            gen = true;
            vida = 10;
            var _rt3 = (tam <= 1.5) ? tam : 1.5 + (tam - 1.5) * 0.45;
            repeat (max(1, round((2 + 1.2 * tam) * _mult)))
                part_add(x + random_range(-12, 12) * tam, y + random_range(-8, 8) * tam, random_range(-0.35, 0.35), random_range(-1.9, -0.8),
                    random_range(3.5, 6.5) * _rt3, random_range(18, 30), c_white, -0.02, "chama", true);
            repeat (irandom_range(1, 2))
                part_add(x + random_range(-12, 12) * tam, y + random_range(-6, 6) * tam, random_range(-0.6, 0.6), random_range(-2.6, -1.1), random_range(0.9, 1.8), random_range(30, 55),
                    choose(make_color_rgb(255, 200, 90), make_color_rgb(255, 130, 40), make_color_rgb(255, 80, 30)), -0.012, "circulo", true);
        break;
        case "chamas_estouro":      // o último lampejo: o que sobrou do corpo vira brasa e some
            gen = true;
            vida = 10;
            flash = 7;
            var _rt4 = (tam <= 1.5) ? tam : 1.5 + (tam - 1.5) * 0.45;
            repeat (round((4 + 3 * tam) * _mult) + 2)
            {
                var _a5 = random(360);
                var _v5 = random_range(0.5, 2) * (0.8 + 0.25 * tam);
                part_add(x + lengthdir_x(random(10) * tam, _a5), y + lengthdir_y(random(14) * tam, _a5), lengthdir_x(_v5, _a5), lengthdir_y(_v5 * 0.6, _a5) - 1.2,
                    random_range(4, 7.5) * _rt4, random_range(18, 30), c_white, -0.025, "chama", true);
            }
            repeat (round((4 + 3 * tam) * _mult) + 2)
                part_add(x + random_range(-14, 14) * tam, y + random_range(-20, 20) * tam, random_range(-1.6, 1.6), random_range(-3.4, -1), random_range(1, 2.4), random_range(35, 70),
                    choose(make_color_rgb(255, 210, 100), make_color_rgb(255, 140, 40), make_color_rgb(255, 90, 30)), -0.012, "circulo", true);
        break;
        case "rajada":              // rajada de energia nas investidas (com relâmpagos)
            vida = 15;
            estilo = espada_estilo_atual();
            var _fz = 0;
            while (_fz < 1) { array_push(raios, { f: _fz, o: random_range(-14, 14) }); _fz += random_range(0.06, 0.12); }
            array_push(raios, { f: 1, o: 0 });
        break;

        case "chamas_morte":
            // golpe fatal (Castlevania): clarão e línguas de fogo subindo do corpo
            vida = 36;
            flash = 9;
            repeat (round(6 * tam * _mult) + 3)
            {
                var _vf = random_range(22, 36);
                array_push(parts, { x: x + random_range(-16, 16) * tam, y: y + random_range(-12, 24) * tam,
                    vy: random_range(-1.7, -0.6), h: random_range(18, 34) * tam, w: random_range(5, 9) * tam,
                    v: _vf, vmax: _vf, fase: random(10) });
            }
        break;

        case "rachaduras":
            vida = 70;
            var _n = 6;
            for (var _i = 0; _i < _n; _i++)
            {
                var _lado = (_i mod 2 == 0) ? 1 : -1;
                var _comp = random_range(40, 90) * tam;
                var _pts = [[0, 0]];
                var _px = 0;
                var _py = 0;
                var _passos = 5;
                for (var _k = 1; _k <= _passos; _k++)
                {
                    _px += _lado * _comp / _passos;
                    _py = random_range(-3, 4);
                    array_push(_pts, [_px, _py]);
                }
                array_push(fendas, _pts);
            }
        break;

        case "faiscas_tela":
            vida = 130;
            depth = -210;              // na frente da chuva
            faiscas_emitir(round(70 * _mult) + 10);
        break;

        case "carga":
            vida = 34;
            repeat (round(18 * _mult) + 4)
            {
                var _ang = random(360);
                var _d = random_range(50, 80);
                array_push(parts, { x: x + lengthdir_x(_d, _ang), y: y + lengthdir_y(_d, _ang), vx: 0, vy: 0, r: random_range(1.5, 3), v: 34, ang: _ang, d: _d });
            }
        break;

        case "faiscas_golpe":
            gen = true;
            vida = 10;
            flash = 7;
            repeat (round(12 * tam * _mult) + 4)
            {
                var _a = random_range(-55, 55) + ((dir == 1) ? 0 : 180);
                var _s = random_range(2.5, 7) * tam;
                part_add(x, y, lengthdir_x(_s, _a), lengthdir_y(_s, _a) - 1, random_range(1, 2.2), random_range(12, 26),
                    choose(make_color_rgb(255, 240, 180), make_color_rgb(255, 190, 80), c_white), 0.22, "linha", true);
            }
        break;

        case "sangue":
            gen = true;
            vida = 10;
            repeat (round(16 * tam * _mult) + 4)
            {
                var _a2 = random_range(-70, 70) + ((dir == 1) ? 0 : 180);
                var _s2 = random_range(1.5, 5.5) * tam;
                part_add(x, y, lengthdir_x(_s2, _a2), lengthdir_y(_s2, _a2) - 1.5, random_range(1.5, 3.2), random_range(24, 44),
                    choose(make_color_rgb(150, 10, 14), make_color_rgb(200, 20, 24), make_color_rgb(110, 0, 8)), 0.28, "circulo", false);
            }
        break;

        case "aparar":
            gen = true;
            vida = 22;
            flash = 10;
            repeat (round(16 * _mult) + 6)
            {
                var _a3 = random(360);
                var _s3 = random_range(2, 6.5);
                part_add(x, y, lengthdir_x(_s3, _a3), lengthdir_y(_s3, _a3), random_range(1, 2), random_range(14, 28),
                    choose(make_color_rgb(170, 220, 255), c_white, make_color_rgb(255, 230, 160)), 0.05, "linha", true);
            }
        break;

        case "escudo_quebrado":
            gen = true;
            vida = 10;
            repeat (round(10 * _mult) + 4)
            {
                part_add(x + random_range(-6, 6), y + random_range(-14, 14), dir * random_range(-1, 4) + random_range(-1.5, 1.5), random_range(-5.5, -2),
                    random_range(2.5, 5), random_range(50, 80), choose(make_color_rgb(150, 150, 160), make_color_rgb(95, 92, 100), make_color_rgb(190, 160, 90)), 0.3, "tri", false);
            }
        break;

        case "lascas":          // caixote quebrando
            gen = true;
            vida = 10;
            repeat (round(14 * tam * _mult) + 5)
            {
                part_add(x + random_range(-14, 14) * tam, y + random_range(-14, 10) * tam, random_range(-3.5, 3.5), random_range(-6, -1.5),
                    random_range(2, 5) * tam, random_range(40, 70), choose(make_color_rgb(120, 78, 40), make_color_rgb(150, 100, 52), make_color_rgb(84, 52, 26)), 0.3, "ret", false);
            }
        break;

        case "entulho":         // parede de pedra caindo
            gen = true;
            vida = 10;
            repeat (round(22 * tam * _mult) + 6)
            {
                part_add(x + random_range(-16, 16), y - random(110), random_range(-3, 3), random_range(-4, 0.5),
                    random_range(2.5, 6), random_range(50, 90), choose(make_color_rgb(92, 84, 80), make_color_rgb(70, 62, 60), make_color_rgb(120, 110, 100)), 0.3, "tri", false);
            }
        break;

        case "fumaca":
            gen = true;
            vida = 10;
            repeat (max(1, round(3 * tam * _mult)))
            {
                part_add(x + random_range(-10, 10) * tam, y, random_range(-0.3, 0.6), random_range(-1.1, -0.5), random_range(6, 11) * tam, random_range(70, 120),
                    choose(make_color_rgb(40, 36, 38), make_color_rgb(60, 54, 54), make_color_rgb(30, 28, 30)), -0.004, "fumo", false);
            }
        break;

        case "brasas":
            gen = true;
            vida = 10;
            repeat (max(1, round(4 * tam * _mult)))
            {
                part_add(x + random_range(-16, 16) * tam, y, random_range(-0.6, 0.9), random_range(-2.6, -0.8), random_range(1, 2), random_range(40, 80),
                    choose(make_color_rgb(190, 110, 255), make_color_rgb(150, 50, 255), make_color_rgb(235, 200, 255)), -0.01, "circulo", true);   // v1.12: brasas da chama maldita
            }
        break;

        case "fumaca_maldita":     // v1.10: corpo evaporando na maldição
            gen = true;
            vida = 10;
            // nos chefes a nuvem cresce mais em quantidade do que no tamanho de cada sopro
            // fumaça discreta: poucos sopros pequenos e curtos (não esconde o cenário)
            var _rt = (tam <= 1.5) ? tam : 1.5 + (tam - 1.5) * 0.45;
            repeat (max(1, round((1 + 0.8 * tam) * _mult)))
            {
                part_add(x + random_range(-10, 10) * tam, y + random_range(-8, 8) * tam, random_range(-0.45, 0.45), random_range(-1.7, -0.6) * (0.8 + 0.2 * _rt),
                    random_range(5, 8.5) * _rt, random_range(28, 44),
                    choose(make_color_rgb(40, 30, 48), make_color_rgb(52, 38, 60), make_color_rgb(64, 46, 70)), -0.004, "maldita", false);   // v1.12: mais clara (só visual, não fere)
            }
            repeat (irandom_range(0, 1))
            {
                part_add(x + random_range(-10, 10) * tam, y + random_range(-6, 6) * tam, random_range(-0.5, 0.5), random_range(-2.4, -1.0), random_range(1, 2.2), random_range(30, 60),
                    choose(make_color_rgb(190, 40, 255), make_color_rgb(255, 40, 70), make_color_rgb(150, 20, 200)), -0.01, "circulo", true);
            }
        break;

        case "fumaca_maldita_estouro":     // v1.10: o último sopro, quando o corpo some
            gen = true;
            vida = 10;
            flash = 6;
            var _rt2 = (tam <= 1.5) ? tam : 1.5 + (tam - 1.5) * 0.45;
            // o último sopro também ficou pequeno: some rápido
            repeat (round((5 + 3 * tam) * _mult) + 2)
            {
                var _ang = random(360);
                var _vel = random_range(0.6, 2.2) * (0.8 + 0.25 * tam);
                part_add(x + lengthdir_x(random(10) * tam, _ang), y + lengthdir_y(random(14) * tam, _ang), lengthdir_x(_vel, _ang), lengthdir_y(_vel * 0.7, _ang) - 0.8,
                    random_range(6, 11) * _rt2, random_range(38, 60),
                    choose(make_color_rgb(8, 4, 10), make_color_rgb(18, 6, 20), make_color_rgb(30, 8, 28)), -0.006, "maldita", false);
            }
            repeat (round((3 + 2 * tam) * _mult) + 1)
            {
                part_add(x + random_range(-14, 14) * tam, y + random_range(-20, 20) * tam, random_range(-1.4, 1.4), random_range(-3, -0.8), random_range(1.2, 2.6), random_range(35, 70),
                    choose(make_color_rgb(200, 50, 255), make_color_rgb(255, 50, 80), make_color_rgb(170, 30, 220)), -0.012, "circulo", true);
            }
        break;

        case "pedras":
            vida = 60;
            repeat (round(16 * _mult) + 4)
            {
                array_push(parts, { x: x + random_range(-60, 60), y: y - 2, vx: random_range(-2.2, 2.2), vy: random_range(-6.5, -3),
                    r: random_range(2, 4.5), v: 60, rot: random(360), vr: random_range(-12, 12) });
            }
        break;
    }
    // v1.18: um clarão decorativo por vez
    if (flash > 0 and fx_decorativo(tipo) and !fx_flash_livre()) flash = 0;
};

// faíscas subindo por toda a largura da tela (a partir do chão e da base da tela)
faiscas_emitir = function(_qt)
{
    var _cx1 = x - 300;
    var _cw = 600;
    var _base = y;
    if (view_camera[0] != -1)
    {
        _cx1 = camera_get_view_x(view_camera[0]);
        _cw = camera_get_view_width(view_camera[0]);
        _base = min(y + 8, camera_get_view_y(view_camera[0]) + camera_get_view_height(view_camera[0]));
    }
    repeat (_qt)
    {
        var _fx = _cx1 + random(_cw);
        var _perto = 1 - min(1, abs(_fx - x) / (_cw * 0.6));
        array_push(parts, { x: _fx, y: _base - random(20), vx: random_range(-0.5, 0.5), vy: -random_range(1.2, 3.2) - 2.2 * _perto,
            r: random_range(1.2, 2.8), v: random_range(70, 125), cor: choose(make_color_rgb(255, 210, 90), make_color_rgb(255, 140, 40), make_color_rgb(255, 80, 40), c_white), fase: random(100) });
    }
};
