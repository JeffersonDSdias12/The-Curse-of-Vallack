// ===== AINDA NO CHÃO: portal de magia e a estátua subindo =====
if (!ativo)
{
    inimigo_portal_desenhar(spr_estatua, escala);
    exit;
}
if (portal_raio > 0) desenhar_portal(x, y, portal_raio, current_time / 16);

inimigo_sombra(24);

var _k = hd_escala(spr_estatua);
var _e = escala / _k;

// ===== MORTE: desmorona de cima para baixo; sobra o entulho =====
if (morrendo)
{
    var _m = clamp(morte_anim / 50, 0, 1);
    var _w = sprite_get_width(spr_estatua);
    var _h = sprite_get_height(spr_estatua);
    var _ox = sprite_get_xoffset(spr_estatua);
    var _oy = sprite_get_yoffset(spr_estatua);
    var _resta = lerp(_oy, _oy * 0.26, 1 - power(1 - _m, 2));    // linhas que ainda estão de pé
    var _topo_p = max(0, floor(_oy - _resta));
    var _tr = morte_fim ? 0 : random_range(-1.5, 1.5) * (1 - _m);
    // v1.10: o entulho também evapora na fumaça negra da maldição
    var _ev = evaporar;
    var _sai = clamp((_ev - 0.4) / 0.6, 0, 1);
    var _al = image_alpha * (1 - _sai * (2 - _sai));
    var _sub = 10 * _sai;
    _tr += random_range(-1, 1) * _ev;
    gpu_set_texfilter(true);
    if (_al > 0.01)
    {
        draw_sprite_part_ext(spr_estatua, 0, 0, _topo_p, _w, _h - _topo_p,
            x + _tr - dir * _ox * _e, y - _sub - (_oy - _topo_p) * _e, dir * _e, _e,
            merge_color(c_white, make_color_rgb(90, 85, 80), _m * 0.7), _al);
        if (_ev > 0)
        {
            gpu_set_fog(true, make_color_rgb(10, 0, 14), 0, 0);
            draw_sprite_part_ext(spr_estatua, 0, 0, _topo_p, _w, _h - _topo_p,
                x + _tr - dir * _ox * _e, y - _sub - (_oy - _topo_p) * _e, dir * _e, _e, c_white, _al * min(1, _ev * 2.2));
            gpu_set_fog(false, c_white, 0, 0);
        }
    }
    gpu_set_texfilter(false);
    exit;
}

// ===== ESTÁTUA =====
var _tremor = (tinido_t > 0) ? random_range(-1, 1) : 0;
if (estado_ia == "desperta" and !orbe_solto) _tremor += random_range(-0.6, 0.6);
var _cor = c_white;
if (estado_ia == "pedra" and vulneravel_t <= 0 and rachada_t <= 0) _cor = make_color_rgb(200, 205, 195);   // pedra: mais apagada
if (rachada_t > 0) _cor = make_color_rgb(255, 190, 180);
inimigo_desenhar_corpo(spr_estatua, image_index, x + _tremor, y, dir * escala, escala, 0, _cor, image_alpha);

gpu_set_texfilter(true);
// rachaduras (orbe rebatido)
if (rachada_t > 0)
{
    draw_set_alpha(min(1, rachada_t / 30));
    draw_set_color(make_color_rgb(40, 20, 20));
    draw_line_width(x - 8, y - 70, x + 2, y - 52, 2);
    draw_line_width(x + 2, y - 52, x - 4, y - 36, 2);
    draw_line_width(x + 2, y - 52, x + 14, y - 44, 1.5);
    draw_set_alpha(1);
}
// carga do orbe entre os olhos
if (estado_ia == "desperta" and !orbe_solto)
{
    var _c = clamp(anim_t / 40, 0, 1);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.25 + 0.5 * _c);
    draw_set_color(make_color_rgb(255, 40, 60));
    draw_circle(x + dir * 4, y - 64, 3 + 9 * _c, false);
    draw_set_alpha(0.6 * _c);
    draw_set_color(make_color_rgb(255, 200, 200));
    draw_circle(x + dir * 4, y - 64, 2 + 3 * _c, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
// aviso: vulnerável agora (os olhos brilham) — escrito aos pés, longe da barra e do "!"
if (estatua_vulneravel())
{
    var _va = 0.6 + 0.4 * sin(current_time / 70);
    txt(x, y + 5, "VULNERÁVEL", FONTE.MINI, make_color_rgb(255, 120, 90), _va, fa_center, fa_top, 0.5);
}
gpu_set_texfilter(false);

inimigo_hud(y - 92, 46);
inimigo_debug(estatua_vulneravel() ? "  (vulnerável)" : "  (pedra)");
desenho_resetar();
