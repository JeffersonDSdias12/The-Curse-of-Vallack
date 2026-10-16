// =====================================================================
//  obj_inimigo_03 — BESTA ESCUDEIRA (filha do obj_inimigo_01)
//  * um escudo de ferro segura os golpes que vêm da frente
//  * é preciso quebrar a guarda (golpes pesados contam em dobro;
//    especiais e a Fúria quebram na hora) ou atacar pelas costas
//  * guarda quebrada: fica atordoada e pronta para o finalizador
// =====================================================================
event_inherited();       // obj_inimigo_01

vida_max = round(85 * dif_vida_inimigo());
vida = vida_max;
vida_atraso = vida;
dano_ataque = max(1, round(10 * dif_dano_inimigo()));
recarga_max = round(60 * dif_recarga_inimigo());
vel_correr = 1.5;      // com o escudo, corre um pouco mais devagar que a besta comum
zona_pulo_max = 0;           // pesada demais para o salto de ataque
escudo_max = dif_valor([3, 4, 5, 6]);
escudo_vida = escudo_max;

// mesmas sprites da besta com outra cor (pelagem escura e armadura de ferro)
cor_base = make_color_rgb(165, 175, 190);
sprite_index = spr_ia_parado;

falas = falas_escudo();
cor_fala = make_color_rgb(70, 60, 30);

// o escudo na frente do corpo (racha conforme apanha)
desenhar_extra = function()
{
    if (escudo_vida <= 0 or (morrendo and morte_fim)) return;
    var _q = clamp(floor((1 - escudo_vida / escudo_max) * 3), 0, 2);
    // v1.9: a besta correndo/atacando ficou do tamanho da parada: escudo maior e mais alto
    var _ox = 18;
    var _oy = -38;
    if (estado_ia == "atacar" and image_index >= 3 and image_index < 7) _ox = 28;     // empurra com o escudo
    var _tr = (escudo_fx > 0) ? random_range(-1.5, 1.5) : 0;
    draw_sprite_ext(spr_escudo, _q, x + dir * _ox + _tr, y + _oy, dir * 1.25, 1.25, 0, (escudo_fx > 0) ? make_color_rgb(255, 230, 200) : c_white, image_alpha);
};
