// =====================================================================
//  obj_aranha — MULHER-ARANHA
//  * ágil: mantém distância, avança e recua de frente para Twilight
//  * GARRA de perto e BOTE (salta com as garras) de média distância
//  * MECÂNICA NOVA — TEIA: cospe teia em arco. Se acertar, Twilight fica
//    PRESO (lento, sem pular e sem rolar) por ~1,5 s; apertar os botões
//    rasga a teia mais rápido. Teia que cai no chão vira uma armadilha
//    pegajosa por 4 s. A defesa segura a teia; aparada na hora certa, ela
//    volta e prende a própria aranha.
//  * surge de um portal de magia e tem nível (Nv 1 a 5)
// =====================================================================
event_inherited();       // obj_inimigo_base

mask_index = spr_mascara_aranha;
image_xscale = 1;
image_yscale = 1;
escala = 1.45;           // a arte HD (k = 2) é desenhada a 1,45x
dir = -1;                // as sprites olham para a direita

// ===== COMBATE (dificuldade + nível) =====
inimigo_status(50);
dano_garra = inimigo_dano(8);
dano_bote = inimigo_dano(10);
dano_teia = inimigo_dano(3);
recarga = irandom_range(30, 70);
recarga_garra = round(44 * dif_recarga_inimigo());
recarga_teia_max = round(250 * dif_recarga_inimigo());
recarga_teia = irandom_range(50, 110);
recarga_bote_max = round(180 * dif_recarga_inimigo());
recarga_bote = irandom_range(80, 150);
teia_quadros = dif_valor([60, 80, 95, 110]);     // tempo preso na teia

// ===== IA =====
estado_ia = "parado";
campo = 520;
campo_altura = 150;
vel_andar = 2.5;
dist_ideal_min = 120;
dist_ideal_max = 230;
alerta_fx = 0;
viu = false;
ataque_t = 0;
golpe_dado = false;
teia_solta = false;
bote_no_ar = 0;
grav_ia = 0.4;
morte_anim = 0;

falas = falas_aranha();
cor_fala = cor_fala_aranha();

// ===== SURGIR DO CHÃO (portal de magia; scr_dano) =====
inimigo_portal_iniciar();

// ===== SPRITES =====
spr_ia_parado = spr_aranha_parada;
spr_ia_andar  = spr_aranha_andando;
spr_ia_ataque = spr_aranha_ataque;
spr_morrer    = spr_aranha_parada;     // a morte é desenhada no código (vira de patas para cima)
sprite_index = spr_ia_parado;
image_index = irandom(3);
image_speed = 1;

trocar_sprite = function(_spr, _vel)
{
    if (sprite_index != _spr)
    {
        sprite_index = _spr;
        image_index = 0;
    }
    image_speed = _vel;
};

reagir_dano = function(_dano, _dir, _forca)
{
    empurrao = _dir * _forca * 0.55;
    inimigo_atordoar(24);
    if (vida <= 0)
    {
        inimigo_morrer(_dir);
        image_speed = 0;
        morte_anim = 0;
        som_em("aranha_chiado", x, y, 0.9);
        return;
    }
    if (random(1) < 0.15) fala_dizer(id, choose("Ssssh!", "Insolente!", "Minhas patas!"), cor_fala);
};
