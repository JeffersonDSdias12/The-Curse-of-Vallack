// ===== AINDA NO CHÃO: portal de magia e o arqueiro subindo =====
if (!ativo)
{
    inimigo_portal_desenhar(spr_ia_parado, escala);
    exit;
}
if (portal_raio > 0) desenhar_portal(x, y, portal_raio, current_time / 16);

// ===== SOMBRA =====
if (place_meeting(x, y + 2, obj_chao))
{
    draw_set_alpha(0.3 * image_alpha * inimigo_sombra_alpha());
    draw_set_color(c_black);
    draw_ellipse(x - 14, y - 3, x + 14, y + 3, false);
    draw_set_alpha(1);
}

// ===== ARQUEIRO (escala uniforme, espelhado pela direção) =====
var _tremor = (atordoado > 0) ? sin(atordoado_anim * 1.4) * 1.2 : 0;
if (flash_dano > 0 and !morrendo)
{
    gpu_set_fog(true, c_white, 0, 0);
    draw_sprite_hd(sprite_index, image_index, x + _tremor, y, dir * escala, escala, 0, c_white, image_alpha);
    gpu_set_fog(false, c_white, 0, 0);
}
else
{
    var _cor2 = (imune_atordoar > 0) ? make_color_rgb(255, 170, 150) : c_white;
    if (morrendo and morte_fim) _cor2 = make_color_rgb(170, 160, 160);
    if (executando) _tremor = random_range(-1.5, 1.5);
    inimigo_corpo_desenhar(sprite_index, image_index, x + _tremor, y, dir * escala, escala, 0, _cor2, image_alpha);   // morto: evapora na fumaça
}

if (morrendo) exit;
var _topo = bbox_top - 10;
gpu_set_texfilter(true);

if (finalizavel) desenhar_icone_finalizador(x, _topo - 18);

// alerta ao entrar no campo de visão
if (alerta_fx > 0)
{
    txt(x, _topo - (40 - alerta_fx) * 0.2, "!", FONTE.MEDIA, make_color_rgb(255, 170, 60), clamp(alerta_fx / 12, 0, 1), fa_center, fa_bottom, 0.8);
}

// mira: brilho na ponta da flecha enquanto puxa a corda
if (estado_ia == "atirar" and !flecha_solta)
{
    var _ma = clamp(image_index / 5, 0, 1);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_ma * 0.8);
    draw_set_color(make_color_rgb(255, 120, 60));
    draw_circle(x + dir * 20 * escala, y - 21 * escala, 2 + 2 * _ma, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// barra de vida
if (barra_tempo > 0 and vida > 0)
{
    var _a = min(1, barra_tempo / 24);
    var _larg = 40;
    var _bx = x - _larg / 2;
    var _by = _topo - 6;
    vida_atraso = lerp_dt(vida_atraso, vida, 0.06);
    draw_set_alpha(_a);
    draw_set_color(c_black);
    draw_rectangle(_bx - 2, _by - 2, _bx + _larg + 2, _by + 6, false);
    draw_set_color(c_white);
    draw_rectangle(_bx, _by, _bx + _larg * clamp(vida_atraso / vida_max, 0, 1), _by + 4, false);
    draw_rectangle_color(_bx, _by, _bx + _larg * clamp(vida / vida_max, 0, 1), _by + 4,
        make_color_rgb(230, 80, 65), make_color_rgb(230, 80, 65), make_color_rgb(120, 20, 20), make_color_rgb(120, 20, 20), false);
    draw_set_color(make_color_rgb(176, 141, 70));
    draw_rectangle(_bx - 2, _by - 2, _bx + _larg + 2, _by + 6, true);
    draw_set_alpha(1);
}

// estrelas de atordoamento
if (atordoado > 0)
{
    draw_set_color(make_color_rgb(255, 230, 110));
    for (var _k = 0; _k < 3; _k++)
    {
        var _ang = atordoado_anim * 7 + _k * 120;
        var _sx = x + lengthdir_x(12, _ang);
        var _sy = _topo - 14 + lengthdir_y(3, _ang);
        draw_set_alpha(0.65 + 0.35 * dsin(_ang));
        draw_circle(_sx, _sy, 2.5, false);
    }
    draw_set_alpha(1);
}

if (global.debug_hitbox)
{
    draw_set_alpha(0.9);
    draw_set_color(c_orange);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    txt(x, bbox_bottom + 4, estado_ia + "  recarga " + string(max(0, ceil(recarga / 60))) + "s", FONTE.MINI, c_yellow, 1, fa_center, fa_top, 0.45);
}
gpu_set_texfilter(false);
desenho_resetar();
