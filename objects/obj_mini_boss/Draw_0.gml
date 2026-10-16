var _t = current_time / 16;
// sombra
if (place_meeting(x, y + 2, obj_chao))
{
    draw_set_alpha(0.32 * image_alpha * inimigo_sombra_alpha());
    draw_set_color(c_black);
    draw_ellipse(x - 28, y - 4, x + 28, y + 4, false);
    draw_set_alpha(1);
}
var _tremor = (atordoado > 0) ? sin(atordoado_anim * 1.4) * 1.5 : 0;
if (executando) _tremor = random_range(-2, 2);
var _cor = enfurecido ? merge_color(cor_base, make_color_rgb(255, 120, 110), 0.45) : cor_base;
if (estado_ia == "dormindo") _cor = merge_color(cor_base, c_black, 0.25);
if (morrendo and morte_fim) _cor = merge_color(cor_base, make_color_rgb(90, 80, 80), 0.4);

// brilho vermelho antes da investida e na fúria
if (!morrendo and (estado_ia == "investida_preparo" or enfurecido))
{
    gpu_set_blendmode(bm_add);
    var _ia = (estado_ia == "investida_preparo") ? 0.45 + 0.25 * sin(_t / 2) : 0.18 + 0.08 * sin(_t / 6);
    draw_sprite_hd(sprite_index, image_index, x + _tremor, y, dir * escala * 1.05, escala * 1.03, 0, make_color_rgb(220, 30, 10), _ia);
    gpu_set_blendmode(bm_normal);
}
if (flash_dano > 0 and !morrendo)
{
    gpu_set_fog(true, c_white, 0, 0);
    draw_sprite_hd(sprite_index, image_index, x + _tremor, y, dir * escala, escala, 0, c_white, image_alpha);
    gpu_set_fog(false, c_white, 0, 0);
}
else inimigo_corpo_desenhar(sprite_index, image_index, x + _tremor, y, dir * escala, escala, 0, _cor, image_alpha);   // morto: evapora na fumaça

if (morrendo) exit;
var _topo = y - 72 * escala;

// aviso de quebra-guarda
if (estado_ia == "atacar" and !ataque_bloqueavel and image_index < 6)
{
    var _pa = 0.75 + 0.25 * sin(current_time / 60);
    gpu_set_texfilter(true);
    txt(x, _topo - 6, "QUEBRA-GUARDA", FONTE.MINI, make_color_rgb(255, 90, 60), _pa, fa_center, fa_bottom, 0.6);
    gpu_set_texfilter(false);
}
// atordoado / exausto
if (atordoado > 0)
{
    draw_set_color(make_color_rgb(255, 230, 110));
    for (var _k = 0; _k < 3; _k++)
    {
        var _ang = atordoado_anim * 7 + _k * 120;
        draw_set_alpha(0.65 + 0.35 * dsin(_ang));
        draw_circle(x + lengthdir_x(20, _ang), _topo + 6 + lengthdir_y(5, _ang), 3, false);
    }
    draw_set_alpha(1);
}
if (finalizavel) desenhar_icone_finalizador(x, _topo - 12);
if (global.debug_hitbox)
{
    draw_set_color(c_red);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_line(arena_x1, y - 200, arena_x1, y);
    draw_line(arena_x2, y - 200, arena_x2, y);
    gpu_set_texfilter(true);
    txt(x, bbox_bottom + 4, estado_ia + "  ações " + string(acoes), FONTE.MINI, c_yellow, 1, fa_center, fa_top, 0.45);
    gpu_set_texfilter(false);
}
desenho_resetar();
