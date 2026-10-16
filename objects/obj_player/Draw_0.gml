// ===== SOMBRA =====
if (place_meeting(x, y + 2, obj_chao))
{
    draw_set_alpha(0.32);
    draw_set_color(c_black);
    draw_ellipse(x - 16, y - 3, x + 16, y + 3, false);
    draw_set_alpha(1);
}

// tamanho igualado entre as sprites (scr_combate: sprite_fator)
var _esc = escala * sprite_fator(sprite_index, image_index);

// ===== AURA DOS ESPECIAIS =====
if (especial)
{
    gpu_set_blendmode(bm_add);
    var _pul = 0.35 + 0.2 * sin(current_time / 50);
    var _cor_aura = make_color_rgb(200, 20, 30);
    if (!is_undefined(golpe) and golpe.chave == "tremor") _cor_aura = make_color_rgb(255, 120, 30);
    if (!is_undefined(golpe) and golpe.chave == "queda") _cor_aura = make_color_rgb(255, 60, 20);
    draw_sprite_hd(sprite_index, image_index, x, y, facing * _esc * 1.06, _esc * 1.04, 0, _cor_aura, _pul);
    gpu_set_blendmode(bm_normal);
}

// ===== ENERGIA JUNTANDO (especial 3 carregando) =====
if (carga_fx > 0)
{
    gpu_set_blendmode(bm_add);
    var _cy0 = y - 44;
    var _t0 = current_time / 60;
    for (var _k = 0; _k < 10; _k++)
    {
        var _ang = _t0 * 9 + _k * 36;
        var _dist = 46 - ((_t0 * 6 + _k * 7) mod 40);
        draw_set_alpha(0.25 + 0.5 * (1 - _dist / 46));
        draw_set_color(make_color_rgb(255, 150 + 10 * (_k mod 3), 60));
        draw_circle(x + lengthdir_x(_dist, _ang), _cy0 + lengthdir_y(_dist * 0.8, _ang), 2 + carga_fx, false);
    }
    draw_set_alpha(0.18 * carga_fx);
    draw_set_color(make_color_rgb(255, 110, 30));
    draw_circle(x, _cy0, 16 + 6 * carga_fx + 3 * sin(current_time / 40), false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ===== FÚRIA CHEIA: aura vermelha tremendo =====
if (furia >= 100 and !morto)
{
    gpu_set_blendmode(bm_add);
    var _fp = 0.25 + 0.15 * sin(current_time / 45);
    draw_sprite_hd(sprite_index, image_index, x + random_range(-1, 1), y, facing * _esc * 1.08, _esc * 1.05, 0, make_color_rgb(255, 30, 10), _fp);
    gpu_set_blendmode(bm_normal);
}

// ===== CURA: a magia do baú envolvendo Twilight =====
if (cura_restante > 0 or cura_fx > 0)
{
    gpu_set_blendmode(bm_add);
    var _ca = 0.25 + 0.15 * sin(current_time / 80);
    draw_sprite_hd(sprite_index, image_index, x, y, facing * _esc * 1.05, _esc * 1.03, 0, make_color_rgb(255, 150, 60), _ca);
    for (var _cp = 0; _cp < 4; _cp++)
    {
        var _cf = frac(current_time / 900 + _cp / 4);
        draw_set_alpha((1 - _cf) * 0.8);
        draw_set_color(make_color_rgb(255, 200, 110));
        draw_circle(x + sin(_cp * 2.1 + current_time / 300) * 12, y - 10 - _cf * 60, 2, false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ===== GUERREIRO (escala uniforme, espelhado pela direção) =====
var _cor = c_white;
if (tempo_invencivel > 0 and !morto and !rolando and (floor(tempo_invencivel / 4) mod 2) == 0) _cor = make_color_rgb(255, 95, 95);
// rastro da esquiva: os "fantasmas" somem aos poucos (mesmo depois da rolagem)
if (array_length(fantasmas) > 0)
{
    var _kf = hd_escala(spr_player_agaichar);
    var _hf = sprite_get_height(spr_player_agaichar) / _kf * _esc * 0.5 * 0.86;
    for (var _g = 0; _g < array_length(fantasmas); _g++)
    {
        var _fa = fantasmas[_g];
        var _ga = _fa.ang;
        draw_sprite_hd(spr_player_agaichar, 0, _fa.x + lengthdir_x(_hf, 270 + _ga), _fa.y - _hf + lengthdir_y(_hf, 270 + _ga), _fa.dir * _esc, _esc * 0.86, _ga, make_color_rgb(140, 170, 255), 0.35 * _fa.vida / _fa.vmax);
    }
}
if (rolando)
{
    // ESQUIVA: Twilight se encolhe e rola em volta do centro do corpo
    var _p = clamp(rolar_t / ROLAR_DURACAO, 0, 1);
    var _sq = 1 - 0.16 * sin(pi * _p);            // encolhido no meio da rolagem
    var _k = hd_escala(sprite_index);
    var _hh = sprite_get_height(sprite_index) / _k * _esc * 0.5 * _sq;
    var _cy0 = y - _hh;
    var _ang = rolar_angulo(_p);
    var _cr = jogador_intangivel() ? make_color_rgb(200, 215, 255) : c_white;
    draw_sprite_hd(sprite_index, 0, x + lengthdir_x(_hh, 270 + _ang), _cy0 + lengthdir_y(_hh, 270 + _ang), facing * _esc * (1 + 0.06 * sin(pi * _p)), _esc * _sq, _ang, _cr, image_alpha);
}
else draw_sprite_hd(sprite_index, image_index, x, y, facing * _esc, _esc, 0, _cor, image_alpha);

// esquiva perfeita: brilho azul
if (esquiva_fx > 0)
{
    gpu_set_blendmode(bm_add);
    draw_set_alpha(esquiva_fx / 18 * 0.7);
    draw_set_color(make_color_rgb(120, 170, 255));
    draw_circle(x, y - 30, 20 + (18 - esquiva_fx) * 2, true);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// APARAR: brilho azul no corpo e no escudo
if (aparar_fx > 0)
{
    gpu_set_blendmode(bm_add);
    draw_sprite_hd(sprite_index, image_index, x, y, facing * _esc, _esc, 0, make_color_rgb(140, 200, 255), clamp(aparar_fx / 24, 0, 1) * 0.8);
    gpu_set_blendmode(bm_normal);
}

// brilho da espada antes dos finalizadores
if (brilho_golpe > 0)
{
    gpu_set_blendmode(bm_add);
    draw_sprite_hd(sprite_index, image_index, x, y, facing * _esc, _esc, 0, make_color_rgb(255, 170, 120), clamp(brilho_golpe / 14, 0, 1) * 0.55);
    gpu_set_blendmode(bm_normal);
}

// ===== RASTRO DA ESPADA (arco de luz em cada golpe) =====
if (array_length(rastros) > 0)
{
    gpu_set_blendmode(bm_add);
    for (var _r = 0; _r < array_length(rastros); _r++)
    {
        var _rs = rastros[_r];
        var _p = 1 - _rs.vida / _rs.vmax;              // 0 -> 1
        var _a = (1 - _p) * (_rs.forte ? 1 : 0.8);
        var _cx = _rs.x + _rs.dir * 8;
        var _cy = _rs.y - _rs.h;
        var _seg = 14;
        var _fim = lerp(_rs.a1, _rs.a2, min(1, 0.35 + _p * 1.6));   // o arco "corre" com o golpe
        draw_primitive_begin(pr_trianglestrip);
        for (var _s = 0; _s <= _seg; _s++)
        {
            var _t = _s / _seg;
            var _ang = lerp(_rs.a1, _fim, _t);
            var _angw = (_rs.dir == 1) ? _ang : 180 - _ang;
            var _esp = (3 + 10 * _t) * (_rs.forte ? 1.4 : 1);
            var _ext = _rs.r;
            var _int = _rs.r - _esp;
            draw_vertex_color(_cx + lengthdir_x(_ext, _angw), _cy + lengthdir_y(_ext, _angw), _rs.cor, _a * _t);
            draw_vertex_color(_cx + lengthdir_x(_int, _angw), _cy + lengthdir_y(_int, _angw), make_color_rgb(255, 255, 255), _a * _t * 0.5);
        }
        draw_primitive_end();
    }
    gpu_set_blendmode(bm_normal);
}

// ===== DEFESA MÁGICA =====
// (o escudo faz parte da sprite spr_player_defendendo; aqui ficam o brilho
//  e a onda quando um golpe ou projétil é segurado)
if (bloqueando or defesa_fx > 0)
{
    var _cyd = (bbox_top + bbox_bottom) / 2;
    var _sx = x + facing * 18 * escala;
    gpu_set_blendmode(bm_add);
    if (janela_aparar > 0)
    {
        // a janela do aparar: o escudo brilha forte por um instante
        draw_set_alpha(0.35 * janela_aparar / APARAR_JANELA);
        draw_set_color(make_color_rgb(190, 230, 255));
        draw_ellipse(_sx - 16, _cyd - 40, _sx + 16, _cyd + 40, false);
    }
    if (bloqueando)
    {
        draw_set_alpha(0.12 + 0.05 * sin(current_time / 70));
        draw_set_color(make_color_rgb(90, 160, 255));
        draw_ellipse(_sx - 14, _cyd - 38, _sx + 14, _cyd + 38, false);
    }
    if (defesa_fx > 0)
    {
        var _o = 1 - defesa_fx / 16;
        draw_set_alpha(1 - _o);
        draw_set_color(make_color_rgb(170, 220, 255));
        draw_ellipse(_sx - 10 - 18 * _o, _cyd - 34 - 14 * _o, _sx + 10 + 18 * _o, _cyd + 34 + 14 * _o, true);
        draw_ellipse(_sx - 8 - 14 * _o, _cyd - 30 - 10 * _o, _sx + 8 + 14 * _o, _cyd + 30 + 10 * _o, true);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ===== ONDAS DO ESPECIAL 1 (meia-lua carmesim) =====
if (array_length(ondas) > 0)
{
    gpu_set_blendmode(bm_add);
    for (var _o2 = 0; _o2 < array_length(ondas); _o2++)
    {
        var _on = ondas[_o2];
        var _aa = clamp(_on.vida / _on.vmax, 0, 1);
        var _rr = _on.raio;
        var _ocx = _on.x0 + _on.dir * (_on.dist - _rr);
        var _ocy = y + (_on.y_topo + _on.y_base) / 2;
        var _ang0 = (_on.dir == 1) ? 0 : 180;
        draw_primitive_begin(pr_trianglestrip);
        for (var _k2 = -6; _k2 <= 6; _k2++)
        {
            var _ang2 = _ang0 + _k2 * 12;
            var _t2 = 1 - abs(_k2) / 6;
            var _esp2 = 3 + 11 * _t2;
            draw_vertex_color(_ocx + lengthdir_x(_rr, _ang2), _ocy + lengthdir_y(_rr * 1.25, _ang2), make_color_rgb(255, 40, 40), _aa * (0.25 + 0.75 * _t2));
            draw_vertex_color(_ocx + lengthdir_x(_rr - _esp2, _ang2), _ocy + lengthdir_y((_rr - _esp2) * 1.25, _ang2), make_color_rgb(255, 220, 210), _aa * 0.9 * _t2);
        }
        draw_primitive_end();
    }
    gpu_set_blendmode(bm_normal);
}

// ===== TEIA DA MULHER-ARANHA (presa no corpo) =====
if (enredado > 0)
{
    var _ea = clamp(enredado / 20, 0, 1) * 0.85;
    var _tr = (enredado_fx > 0) ? random_range(-1.5, 1.5) : 0;
    var _ey1 = bbox_top + 8;
    var _ey2 = bbox_bottom - 4;
    gpu_set_texfilter(true);
    draw_set_alpha(_ea);
    draw_set_color(make_color_rgb(235, 235, 240));
    for (var _wl = 0; _wl < 5; _wl++)
    {
        var _wy = lerp(_ey1, _ey2, _wl / 4);
        draw_line(x - 15 + _tr, _wy - 4, x + 15 + _tr, _wy + 4);
        draw_line(x - 15 + _tr, _wy + 4, x + 15 + _tr, _wy - 4);
    }
    draw_line(x - 13 + _tr, _ey1, x - 11 + _tr, _ey2);
    draw_line(x + 13 + _tr, _ey1, x + 11 + _tr, _ey2);
    draw_set_alpha(1);
    // dica: aperte os botões para se soltar
    var _ba = 0.7 + 0.3 * sin(current_time / 60);
    txt(x, bbox_top - 14, "SOLTE-SE!", FONTE.MINI, make_color_rgb(235, 235, 255), _ba, fa_center, fa_bottom, 0.55);
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(x - 16, bbox_top - 10, x + 16, bbox_top - 7, false);
    draw_set_color(make_color_rgb(235, 235, 240));
    draw_rectangle(x - 16, bbox_top - 10, x - 16 + 32 * clamp(enredado / max(1, enredado_max), 0, 1), bbox_top - 7, false);
    draw_set_alpha(1);
    gpu_set_texfilter(false);
}

// ===== DEPURAÇÃO (F1): máscara, golpe e quadro da animação =====
if (global.debug_hitbox)
{
    draw_set_alpha(0.9);
    draw_set_color(c_lime);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_line(x - 4, y, x + 4, y);
    if (array_length(debug_golpe) > 4)
    {
        draw_set_color(c_yellow);
        draw_rectangle(debug_golpe[0], debug_golpe[1], debug_golpe[2], debug_golpe[3], true);
    }
    for (var _o3 = 0; _o3 < array_length(ondas); _o3++)
    {
        var _w = ondas[_o3];
        var _wx1 = _w.x0 + _w.dir * (_w.dist - 20);
        var _wx2 = _w.x0 + _w.dir * (_w.dist + 10);
        draw_set_color(c_orange);
        draw_rectangle(min(_wx1, _wx2), y + _w.y_topo, max(_wx1, _wx2), y + _w.y_base, true);
    }
    if (!is_undefined(golpe))
        txt(x, bbox_top - 6, golpe.nome + "  q" + string(golpe.seq[golpe_i].q) + "  [" + cadeia + "]", FONTE.MINI, c_yellow, 1, fa_center, fa_bottom, 0.45);
    draw_set_alpha(1);
}
desenho_resetar();
