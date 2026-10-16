// =====================================================================
//  obj_esqueleto — ESQUELETO GUERREIRO (filho do obj_inimigo_01)
//  * rápido e com GOLPE DUPLO: corte largo (quadros 2-3) e estocada (6-7)
//  * MECÂNICA NOVA — REERGUER: derrubado por golpes comuns, ele desmonta
//    numa pilha de ossos e se levanta ~3,5 s depois com metade da vida
//    (uma vez só). Golpear a pilha, especiais, a Fúria, o finalizador e
//    projéteis rebatidos acabam com ele de vez.
//  * surge de um portal de magia (pela besta) e tem nível (Nv 1 a 5)
// =====================================================================
event_inherited();       // obj_inimigo_01

// ===== MÁSCARA E DESENHO (arte HD k = 2 desenhada a 1,6x) =====
mask_index = spr_mascara_esqueleto;
image_xscale = 1;
image_yscale = 1;
escala_vis = 1.6;
topo_vis = 74;
sombra_larg = 13;
usa_hud_nivel = true;

// ===== COMBATE (dificuldade + nível) =====
inimigo_status(45);
dano_ataque = inimigo_dano(7);
recarga_max = round(40 * dif_recarga_inimigo());
vel_correr = 2.3;            // mais rápido que a besta
zona_pulo_max = 0;           // não tem o salto de ataque (só pula caixotes)
alcance_ataque = 46;
distancia_minima = 34;

// golpe duplo: corte largo e estocada com a lâmina
golpe_janelas = [[2, 3], [6, 7]];
golpe_caixa = [4, 44, -50, -6];
vel_ataque = 0.7;

// ===== REERGUER =====
reerguido = false;           // true = já se levantou (ou é invocado): a próxima queda é de vez
caido_t = 0;
caido_dur = 210;             // 3,5 s como pilha de ossos
erguer_t = 0;
andar_t = 0;                 // depois de se erguer, cambaleia andando por ~1 s
andar_img = 0;

// ===== FALAS =====
falas = falas_esqueleto();
cor_fala = cor_fala_esqueleto();

// ===== SPRITES =====
spr_ia_parado = spr_esqueleto_parado;
spr_ia_andar  = spr_esqueleto_andando;
spr_ia_correr = spr_esqueleto_correndo;
spr_ia_ataque = spr_esqueleto_ataque;
spr_ia_pular  = spr_esqueleto_correndo;     // pula caixotes correndo
spr_ia_atordoado = spr_esqueleto_dano;
vel_atordoado = 0.9;
spr_morrer    = spr_esqueleto_morrendo;
sprite_index = spr_ia_parado;
image_index = irandom(sprite_get_number(spr_ia_parado) - 1);
image_speed = 1;

// Reação a um golpe
reagir_dano = function(_dano, _dir, _forca)
{
    // golpe na pilha de ossos: agora acabou de vez
    if (estado_ia == "caido" or estado_ia == "erguendo")
    {
        vida = 0;
        som_em("osso_quebra", x, y, 0.95);
        inimigo_morrer(_dir);
        velh = 0;
        image_index = sprite_get_number(spr_morrer) - 1;
        image_speed = 0;
        morte_fim = true;
        repeat (global.cfg_qualidade == 0 ? 3 : 7)
        {
            var _f = instance_create_depth(x + random_range(-16, 16), y - random_range(4, 20), -100, obj_fagulha);
            _f.cor = choose(make_color_rgb(230, 220, 200), make_color_rgb(200, 40, 30));
        }
        return;
    }

    empurrao = _dir * _forca * 0.45;
    inimigo_atordoar(30);
    if (vida <= 0)
    {
        if (!reerguido and !finalizado and !golpe_e_forte(ultimo_golpe))
        {
            // REERGUER: desmonta numa pilha de ossos (ainda não foi derrotado)
            estado_ia = "caido";
            caido_t = 0;
            vida = 1;
            barra_tempo = 0;
            atordoado = 0;
            finalizavel = false;
            executando = false;
            pulando = false;
            pode_lancar = false;
            tempo_invencivel = 18;
            velh = _dir * 1.2;
            empurrao = 0;
            sprite_index = spr_morrer;
            image_index = 0;
            image_speed = 0;
            som_em("osso_desmonta", x, y, 0.9);
            fala_aleatoria(id, falas_esqueleto_cai(), cor_fala, 0.6);
            return;
        }
        inimigo_morrer(_dir);
        som_em("osso_desmonta", x, y, 0.8);
    }
    else if (random(1) < 0.12) fala_dizer(id, choose("Clec!", "Crac!", "Meus ossos!"), cor_fala);
};

// Brilho da pilha de ossos (vai se levantar) e névoa ao se erguer
desenhar_extra = function()
{
    if (estado_ia == "caido")
    {
        var _r = clamp((caido_t - (caido_dur - 80)) / 80, 0, 1);
        if (_r > 0)
        {
            var _pu = 0.5 + 0.5 * sin(current_time / 70);
            gpu_set_blendmode(bm_add);
            draw_set_alpha(_r * (0.25 + 0.25 * _pu));
            draw_set_color(make_color_rgb(200, 40, 40));
            draw_ellipse(x - 22, y - 16, x + 22, y + 2, false);
            draw_set_alpha(_r * 0.8);
            draw_set_color(make_color_rgb(255, 90, 70));
            draw_circle(x + dir * 4, y - 9, 1.6 + _pu, false);      // os olhos acendendo
            draw_circle(x + dir * 9, y - 9, 1.6 + _pu, false);
            gpu_set_blendmode(bm_normal);
            draw_set_alpha(1);
        }
    }
    else if (estado_ia == "erguendo")
    {
        var _e = clamp(erguer_t / 45, 0, 1);
        gpu_set_blendmode(bm_add);
        draw_set_color(make_color_rgb(190, 50, 255));
        for (var _k = 0; _k < 5; _k++)
        {
            var _fy = y - ((erguer_t * 2.2 + _k * 13) mod 64);
            draw_set_alpha(0.45 * (1 - _e * 0.5) * (1 - (y - _fy) / 64));
            draw_circle(x + sin(erguer_t * 0.2 + _k * 1.7) * 14, _fy, 2.5, false);
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
};
