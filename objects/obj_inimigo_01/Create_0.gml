// =====================================================================
//  obj_inimigo_01 — besta do caminho do castelo
//  Surge do chão por um portal de magia quando o jogador se aproxima.
// =====================================================================
event_inherited();       // obj_inimigo_base

// ===== MÁSCARA DE COLISÃO (fixa e simétrica, do tamanho do corpo) =====
mask_index = spr_mascara_inimigo;
image_xscale = 1;
image_yscale = 1;
dir = choose(-1, 1);     // as sprites olham para a direita

// ===== COMBATE (ajustado pela dificuldade) =====
vida_max = round(60 * dif_vida_inimigo());
vida = vida_max;
vida_atraso = vida;
dano_ataque = max(1, round(8 * dif_dano_inimigo()));
contador_ataques = 0;
ataque_bloqueavel = true;
recarga = irandom(30);
recarga_max = round(46 * dif_recarga_inimigo());

// ===== IA =====
estado_ia = "parado";
alertado = false;
alerta_fx = 0;
campo = 480;
campo_altura = 130;
alcance_ataque = 50;
alcance_ataque_y = 44;
distancia_minima = 38;
vel_correr = 1.9;      // a besta sempre corre (não anda mais)
separacao = 0;

// ===== PULO (só quando o jogador está na zona próxima) =====
pulando = false;
zona_pulo_min = 85;
zona_pulo_max = 210;
forca_salto = 7.2;
grav_ia = 0.4;
recarga_salto = irandom_range(40, 120);
pulo_obstaculo = false;

// ===== FALAS (balão quando ataca) =====
falas = falas_besta();
cor_fala = make_color_rgb(130, 20, 20);

// ===== SURGIR DO CHÃO (portal de magia; scr_dano) =====
inimigo_portal_iniciar();

// ===== SPRITES =====
spr_ia_parado = spr_inimigo01_parado;
spr_ia_andar  = spr_inimigo01_andar;
spr_ia_correr = spr_inimigo01_correndo;
spr_ia_ataque = spr_inimigo01_atacando;
spr_ia_pular  = spr_inimigo01_pulando;
spr_morrer    = spr_inimigo01_morrendo;
sprite_index = spr_ia_parado;
image_index = irandom(sprite_get_number(spr_ia_parado) - 1);
image_speed = 1;

escala_vis = 1;           // tamanho do desenho (o mini-boss é maior)
cor_base = c_white;
desenhar_extra = function() {};

// ===== GOLPE (v1.8: parametrizado; o esqueleto guerreiro usa outros quadros) =====
golpe_janelas = [[3, 6]];          // quadros da animação que ferem (pode haver mais de um golpe)
golpe_caixa = [6, 46, -52, -6];    // área do golpe: x de/até (à frente) e y de/até
vel_ataque = 0.35;                 // velocidade da animação de ataque
golpe_janela = -1;                 // golpe (janela) em andamento
golpe_som_i = 0;                   // quantos sons de golpe já tocaram neste ataque
spr_ia_atordoado = spr_ia_parado;  // animação enquanto está atordoado
vel_atordoado = 0.4;
topo_vis = 72;                     // altura do topo (barra de vida, estrelas)
sombra_larg = 17;
usa_hud_nivel = false;             // v1.8: barra com o selo do nível (inimigos novos)

trocar_sprite = function(_spr, _vel)
{
    if (sprite_index != _spr)
    {
        sprite_index = _spr;
        image_index = 0;
    }
    image_speed = _vel;
};

// Reação a um golpe do jogador
reagir_dano = function(_dano, _dir, _forca)
{
    // empurrão pequeno: o inimigo continua ao alcance da espada
    empurrao = _dir * _forca * 0.45;
    inimigo_atordoar(30);
    if (vida <= 0) inimigo_morrer(_dir);
    else if (random(1) < 0.12) fala_dizer(id, choose("Argh!", "Grrr!", "Maldito!"), cor_fala);
};
