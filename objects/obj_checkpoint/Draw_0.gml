// ===== CRISTAL MÁGICO =====
var _t = current_time / 16;
var _cor_cristal = ativado ? make_color_rgb(70, 190, 255) : make_color_rgb(125, 80, 220);
var _cor_brilho  = ativado ? make_color_rgb(110, 230, 255) : make_color_rgb(170, 110, 255);
var _br = ativado ? 1 : 0.5;
var _cy = chao_y - 66 + sin(_t * 0.05) * 4;

// círculo de runas no chão
gpu_set_blendmode(bm_add);
draw_set_alpha(0.22 * _br);
draw_set_color(_cor_brilho);
draw_ellipse(x - 34, chao_y - 7, x + 34, chao_y + 7, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(0.8 * _br);
draw_set_color(_cor_brilho);
draw_ellipse(x - 28, chao_y - 5, x + 28, chao_y + 5, true);
for (var _k = 0; _k < 6; _k++)
{
    var _a = _t * 1.5 + _k * 60;
    draw_circle(x + lengthdir_x(28, _a), chao_y + lengthdir_y(5, _a), 1.5, false);
}

// pilar de luz quando ativado
if (ativado)
{
    gpu_set_blendmode(bm_add);
    retangulo_gradiente(x - 12, chao_y - 190, x + 12, chao_y, _cor_brilho, 0, _cor_brilho, 0.22 + 0.06 * sin(_t * 0.1));
    gpu_set_blendmode(bm_normal);
}

// cristal flutuando
desenhar_cristal(x, _cy, 10, _cor_cristal, _cor_brilho, _br, _t);

// partículas subindo
gpu_set_blendmode(bm_add);
draw_set_color(_cor_brilho);
for (var _p = 0; _p < (ativado ? 8 : 4); _p++)
{
    var _f = frac(_t / 120 + _p / 8);
    draw_set_alpha((1 - _f) * 0.8 * _br);
    draw_circle(x + sin(_p * 2.3 + _t / 30) * 18, chao_y - _f * 110, 1.4, false);
}
// onda ao ativar
if (ativacao_fx > 0)
{
    var _o = 1 - ativacao_fx / 45;
    draw_set_alpha(1 - _o);
    draw_circle(x, _cy, 10 + 70 * _o, true);
    draw_circle(x, _cy, 8 + 60 * _o, true);
}
gpu_set_blendmode(bm_normal);

// nome quando o jogador está perto e ainda não ativou
if (!ativado and instance_exists(obj_player) and abs(obj_player.x - x) < 160)
{
    gpu_set_texfilter(true);
    txt(x, _cy - 30, "CRISTAL MÁGICO · CHECKPOINT", FONTE.MINI, make_color_rgb(200, 170, 255), 0.9, fa_center, fa_bottom, 0.5);
    gpu_set_texfilter(false);
}
desenho_resetar();
