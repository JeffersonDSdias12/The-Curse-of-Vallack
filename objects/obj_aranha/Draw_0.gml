// ===== AINDA NO CHÃO: portal de magia e a aranha subindo =====
if (!ativo)
{
    inimigo_portal_desenhar(spr_ia_parado, escala);
    exit;
}
if (portal_raio > 0) desenhar_portal(x, y, portal_raio, current_time / 16);

inimigo_sombra(22);

// ===== MORTE: vira de patas para cima e encolhe as patas =====
if (morrendo)
{
    var _m = clamp(morte_anim / 36, 0, 1);
    var _e = 1 - power(1 - _m, 2);
    var _ys = escala * (1 - 1.5 * _e);                          // de 1 até -0,5 (de costas)
    var _hh = sprite_get_yoffset(spr_ia_parado) / hd_escala(spr_ia_parado);
    var _yd = y - max(0, -_ys) * _hh;                         // de costas, continua apoiada no chão
    var _cm = merge_color(c_white, make_color_rgb(110, 95, 110), _e * 0.6);
    inimigo_corpo_desenhar(spr_ia_parado, 0, x, _yd, dir * escala, _ys, 0, _cm, image_alpha);   // evapora na fumaça
    exit;
}

// ===== ARANHA =====
var _tremor = (atordoado > 0) ? sin(atordoado_anim * 1.6) * 1.5 : 0;
if (executando) _tremor = random_range(-1.5, 1.5);
var _cor = (imune_atordoar > 0) ? make_color_rgb(255, 170, 150) : c_white;
var _ys2 = escala;
if (estado_ia == "bote_prep") _ys2 = escala * (1 - 0.14 * clamp(ataque_t / 18, 0, 1));     // agacha antes do bote
if (estado_ia == "garra" and ataque_t < 16) _tremor += sin(ataque_t * 2) * 0.8;            // treme antes da garra
inimigo_desenhar_corpo(sprite_index, image_index, x + _tremor, y, dir * escala, _ys2, 0, _cor, image_alpha);

// ===== AVISO DA TEIA: brilho branco na boca enquanto prepara =====
if (estado_ia == "teia" and !teia_solta)
{
    var _ta = clamp(ataque_t / 22, 0, 1);
    gpu_set_texfilter(true);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.75 * _ta);
    draw_set_color(make_color_rgb(235, 235, 255));
    draw_circle(x + dir * 16, y - 46, 2 + 4 * _ta, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    gpu_set_texfilter(false);
}

inimigo_hud(y - 78, 40);
inimigo_debug(estado_ia == "teia" ? "" : "  teia " + string(max(0, ceil(recarga_teia / 60))) + "s");
desenho_resetar();
