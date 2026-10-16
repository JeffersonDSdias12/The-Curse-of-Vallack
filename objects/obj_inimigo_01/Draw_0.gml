// ===== AINDA NO CHÃO: portal de magia e a besta subindo =====
if (!ativo)
{
    inimigo_portal_desenhar(spr_ia_parado, escala_vis, cor_base);
    exit;
}

// portal se fechando depois que a besta saiu
if (portal_raio > 0) desenhar_portal(x, y, portal_raio, current_time / 16);

// ===== SOMBRA =====
if (place_meeting(x, y + 2, obj_chao))
{
    draw_set_alpha(0.3 * image_alpha * inimigo_sombra_alpha());
    draw_set_color(c_black);
    draw_ellipse(x - sombra_larg, y - 3, x + sombra_larg, y + 3, false);
    draw_set_alpha(1);
}

// ===== BESTA (espelhada pela direção; máscara fixa) =====
var _tremor = (atordoado > 0) ? sin(atordoado_anim * 1.4) * 1.5 : 0;
var _cor = (atordoado > 0) ? merge_color(cor_base, make_color_rgb(205, 205, 255), 0.6) : cor_base;
if (imune_atordoar > 0 and !morrendo) _cor = make_color_rgb(255, 170, 150);   // acabou de se libertar
if (executando) _tremor = random_range(-1.5, 1.5);
if (morrendo and morte_fim) _cor = merge_color(cor_base, make_color_rgb(90, 80, 80), 0.35);     // corpo no chão
if (flash_dano > 0 and !morrendo)
{
    gpu_set_fog(true, c_white, 0, 0);
    draw_sprite_hd(sprite_index, image_index, x + _tremor, y, dir * escala_vis, escala_vis, 0, c_white, image_alpha);
    gpu_set_fog(false, c_white, 0, 0);
}
else inimigo_corpo_desenhar(sprite_index, image_index, x + _tremor, y, dir * escala_vis, escala_vis, 0, _cor, image_alpha);   // morto: evapora na fumaça

desenhar_extra();          // escudo (inimigo 03) e outros detalhes

if (morrendo) exit;

var _topo = y - topo_vis;
gpu_set_texfilter(true);

if (usa_hud_nivel) inimigo_hud(_topo, 46);       // v1.8: inimigos novos (barra com o nível)
else
{
    // ===== SE LIBERTOU DO ATORDOAMENTO (onda vermelha) =====
    if (libertou_fx > 0)
    {
        var _lf = 1 - libertou_fx / 20;
        draw_set_alpha(1 - _lf);
        draw_set_color(make_color_rgb(255, 80, 60));
        draw_circle(x, y - 30, 12 + 30 * _lf, true);
        draw_set_alpha(1);
    }

    // ===== ESTRELAS DE ATORDOAMENTO =====
    if (atordoado > 0)
    {
        draw_set_color(make_color_rgb(255, 230, 110));
        for (var _k = 0; _k < 3; _k++)
        {
            var _ang = atordoado_anim * 7 + _k * 120;
            var _sx = x + lengthdir_x(15, _ang);
            var _sy = _topo + 4 + lengthdir_y(4, _ang);
            draw_set_alpha(0.65 + 0.35 * dsin(_ang));
            draw_triangle(_sx - 4, _sy, _sx + 4, _sy, _sx, _sy - 4, false);
            draw_triangle(_sx - 4, _sy, _sx + 4, _sy, _sx, _sy + 4, false);
            draw_triangle(_sx, _sy - 4, _sx, _sy + 4, _sx - 4, _sy, false);
            draw_triangle(_sx, _sy - 4, _sx, _sy + 4, _sx + 4, _sy, false);
        }
        draw_set_alpha(1);
    }

    // ===== FINALIZADOR: ícone do botão sobre a cabeça =====
    if (finalizavel) desenhar_icone_finalizador(x, _topo - 16);

    // ===== ALERTA "!" =====
    if (alerta_fx > 0)
    {
        var _aa = clamp(alerta_fx / 12, 0, 1);
        txt(x, _topo - 8 - (40 - alerta_fx) * 0.2, "!", FONTE.MEDIA, make_color_rgb(255, 80, 60), _aa, fa_center, fa_bottom, 0.8);
    }

    // ===== BARRA DE VIDA =====
    if (barra_tempo > 0 and vida > 0)
    {
        var _a = min(1, barra_tempo / 24);
        var _larg = 52;
        var _bx = x - _larg / 2;
        var _by = _topo - 6;
        vida_atraso = lerp_dt(vida_atraso, vida, 0.06);
        draw_set_alpha(_a);
        draw_set_color(c_black);
        draw_rectangle(_bx - 2, _by - 2, _bx + _larg + 2, _by + 6, false);
        draw_set_color(c_white);
        draw_rectangle(_bx, _by, _bx + _larg * clamp(vida_atraso / vida_max, 0, 1), _by + 4, false);
        draw_rectangle_color(_bx, _by, _bx + _larg * clamp(vida / vida_max, 0, 1), _by + 4,
            make_color_rgb(230, 80, 65), make_color_rgb(230, 80, 65),
            make_color_rgb(120, 20, 20), make_color_rgb(120, 20, 20), false);
        draw_set_color(make_color_rgb(176, 141, 70));
        draw_rectangle(_bx - 2, _by - 2, _bx + _larg + 2, _by + 6, true);
        draw_set_alpha(1);
    }
}

// ===== AVISO DE GOLPE QUE NÃO PODE SER DEFENDIDO =====
if (estado_ia == "atacar" and !ataque_bloqueavel and image_index < golpe_janelas[array_length(golpe_janelas) - 1][1] + 1)
{
    var _pa = 0.75 + 0.25 * sin(current_time / 60);
    draw_set_alpha(_pa);
    draw_set_color(make_color_rgb(255, 70, 40));
    draw_circle(x, _topo - 14, 3, false);
    txt(x, _topo - 20, "QUEBRA-GUARDA", FONTE.MINI, make_color_rgb(255, 90, 60), _pa, fa_center, fa_bottom, 0.55);
}

// ===== DEPURAÇÃO (F1) =====
if (global.debug_hitbox)
{
    draw_set_alpha(0.9);
    draw_set_color(c_red);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    if (estado_ia == "atacar")
    {
        var _x1 = x + dir * golpe_caixa[0];
        var _x2 = x + dir * golpe_caixa[1];
        var _fd = floor(image_index);
        var _ativo_golpe = false;
        for (var _w = 0; _w < array_length(golpe_janelas); _w++) if (_fd >= golpe_janelas[_w][0] and _fd <= golpe_janelas[_w][1]) _ativo_golpe = true;
        draw_set_color(_ativo_golpe ? c_orange : c_gray);
        draw_rectangle(min(_x1, _x2), y + golpe_caixa[2], max(_x1, _x2), y + golpe_caixa[3], true);
    }
    txt(x, bbox_bottom + 4, estado_ia + (atordoado > 0 ? " (atordoado)" : "") + (imune_atordoar > 0 ? " (imune)" : "") + (usa_hud_nivel ? "  Nv " + string(nivel) : ""), FONTE.MINI, c_yellow, 1, fa_center, fa_top, 0.45);
}

gpu_set_texfilter(false);
desenho_resetar();
