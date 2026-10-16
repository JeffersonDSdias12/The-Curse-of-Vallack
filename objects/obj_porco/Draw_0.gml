// ===== AINDA NO CHÃO: portal de magia e o porco subindo =====
if (!ativo)
{
    inimigo_portal_desenhar(spr_ia_parado, escala);
    exit;
}
if (portal_raio > 0) desenhar_portal(x, y, portal_raio, current_time / 16);

inimigo_sombra(26);

// ===== AURA DA FÚRIA (atrás do corpo) =====
if (furioso and !morrendo)
{
    var _pu = 0.5 + 0.5 * sin(aura_t * 0.15);
    gpu_set_texfilter(true);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.16 + 0.1 * _pu);
    draw_set_color(make_color_rgb(230, 40, 30));
    draw_ellipse(x - 38, y - 92, x + 38, y + 4, false);
    draw_set_color(make_color_rgb(255, 120, 60));
    for (var _k = 0; _k < 4; _k++)
    {
        var _fy = y - ((aura_t * 1.6 + _k * 23) mod 90);
        draw_set_alpha(0.5 * (1 - (y - _fy) / 90));
        draw_circle(x + sin(aura_t * 0.09 + _k * 1.9) * 26, _fy, 2, false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    gpu_set_texfilter(false);
}

// ===== PORCO =====
var _tremor = (atordoado > 0) ? sin(atordoado_anim * 1.4) * 1.6 : 0;
if (executando) _tremor = random_range(-1.5, 1.5);
if (estado_ia == "rugir") _tremor = random_range(-1.2, 1.2);
var _cor = c_white;
if (furioso) _cor = make_color_rgb(255, 205, 195);
if (morrendo and morte_fim) _cor = make_color_rgb(150, 130, 130);
inimigo_desenhar_corpo(sprite_index, image_index, x + _tremor, y, dir * escala, escala, 0, _cor, image_alpha);

if (morrendo) exit;

// ===== AVISOS =====
gpu_set_texfilter(true);
// salto: poeira e círculo de alcance da onda de choque onde ele vai cair
if (estado_ia == "salto_ar" or estado_ia == "salto_prep")
{
    var _pa = 0.35 + 0.25 * sin(current_time / 50);
    var _px = (estado_ia == "salto_ar") ? x + velh * 6 : x + dir * 40;
    var _gy = chao_abaixo(_px, y - 10, 260);
    draw_set_alpha(_pa);
    draw_set_color(make_color_rgb(255, 80, 50));
    draw_ellipse(_px - 112, _gy - 6, _px + 112, _gy + 6, true);
    draw_set_alpha(1);
}
// corte roxo: brilho na lâmina enquanto prepara
if (estado_ia == "onda" and !onda_solta)
{
    var _oa = clamp(image_index / 3, 0, 1);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.7 * _oa);
    draw_set_color(make_color_rgb(220, 60, 255));
    draw_circle(x + dir * 30, y - 40, 4 + 8 * _oa, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
gpu_set_texfilter(false);

var _topo = y - 96;
inimigo_hud(_topo, 60);

// golpe que não pode ser defendido
if (estado_ia == "atacar" and !ataque_bloqueavel and image_index < 9)
{
    var _qa = 0.75 + 0.25 * sin(current_time / 60);
    txt(x, _topo - 20, "QUEBRA-GUARDA", FONTE.MINI, make_color_rgb(255, 90, 60), _qa, fa_center, fa_bottom, 0.55);
}
if (estado_ia == "rugir")
{
    txt(x, _topo - 20, "FÚRIA!", FONTE.PEQUENA, make_color_rgb(255, 80, 50), 0.85 + 0.15 * sin(current_time / 50), fa_center, fa_bottom, 0.6);
}

inimigo_debug(furioso ? "  (fúria)" : "");
if (global.debug_hitbox and estado_ia == "atacar")
{
    var _x1 = x + dir * 2;
    var _x2 = x + dir * 64;
    draw_set_color(c_orange);
    draw_rectangle(min(_x1, _x2), y - 72, max(_x1, _x2), y - 4, true);
}
desenho_resetar();
