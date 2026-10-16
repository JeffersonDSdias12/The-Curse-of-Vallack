// =====================================================================
//  obj_mini_boss — O CARRASCO DE VALLACK (mini-boss do meio da fase 1)
//  * espera perto do cristal do meio; quando Twilight entra, muralhas
//    mágicas fecham a arena
//  * golpe pesado (a cada 2, um quebra-guarda), salto com onda de choque
//    e investida; depois de 3 ações fica cansado por um instante
//  * não fica tonto com golpes comuns (só aparando ou exausto)
//  * com 1/4 da vida cai de joelhos: FINALIZADOR
// =====================================================================
event_inherited();       // obj_inimigo_base

escala = 1.65;
image_xscale = escala;   // a máscara acompanha o tamanho
image_yscale = escala;
mask_index = spr_mascara_inimigo;
dir = -1;
resiste_atordoar = true;
pode_lancar = false;
nome_boss = "O CARRASCO DE VALLACK";
titulo_boss = "GUARDIÃO DA VILA EM CHAMAS";

vida_max = round(460 * dif_vida_inimigo());
vida = vida_max;
vida_atraso = vida;
dano_corte = max(1, round(20 * dif_dano_inimigo()));
dano_salto = max(1, round(16 * dif_dano_inimigo()));
dano_investida = max(1, round(14 * dif_dano_inimigo()));
grav_ia = 0.45;

// arena em volta do ponto onde ele espera
arena_x1 = x - 340;
arena_x2 = x + 300;
arena_fechada = false;
y_chao = chao_abaixo(x, y - 60);
chave = aberto_chave("mini", xstart, ystart);
if (aberto_tem(chave)) { instance_destroy(); exit; }

estado_ia = "dormindo";
acordado = false;
golpe_dado = false;
som_golpe_tocou = false;
ataque_bloqueavel = true;
contador_ataques = 0;
acoes = 0;               // depois de 3 ações ele cansa
recarga = 40;
t_estado = 0;
exausto_usado = false;
enfurecido = false;
hud_alpha = 0;
titulo_tempo = 0;
alerta_fx = 0;
fala_t = 400;
investida_dir = 1;
onda_fx = 0;

// as mesmas sprites (HD) da besta, maiores e com outra cor
spr_ia_parado = spr_inimigo01_parado;
spr_ia_andar  = spr_inimigo01_andar;
spr_ia_correr = spr_inimigo01_correndo;
spr_ia_ataque = spr_inimigo01_atacando;
spr_ia_pular  = spr_inimigo01_pulando;
spr_morrer    = spr_inimigo01_morrendo;
cor_base = make_color_rgb(175, 125, 140);
sprite_index = spr_ia_parado;
image_speed = 0.6;

trocar_sprite = function(_spr, _vel)
{
    if (sprite_index != _spr) { sprite_index = _spr; image_index = 0; }
    image_speed = _vel;
};

mudar = function(_estado)
{
    estado_ia = _estado;
    t_estado = 0;
    golpe_dado = false;
    som_golpe_tocou = false;
};

despertar = function()
{
    if (acordado) return;
    acordado = true;
    mudar("apresentacao");
    titulo_tempo = 200;
    arena_fechada = true;
    arena_fechar(arena_x1, arena_x2, y_chao, id);
    musica("mus_boss", 800);
    som("sfx_rugido", 1, 0);
    global.camera_impact = max(global.camera_impact, 12);
    fala_dizer(id, "Ninguém passa pelo Carrasco!", make_color_rgb(120, 20, 20), true, 140);
};

reagir_dano = function(_dano, _dir, _forca)
{
    // super armadura: não recua com golpes comuns
    empurrao = _dir * 0.4;
    if (!acordado) despertar();
    if (vida <= 0) { mini_morrer(_dir); return; }
    // 1/4 da vida: cai de joelhos (uma vez) e fica pronto para o finalizador
    if (!exausto_usado and vida <= vida_max * 0.25)
    {
        exausto_usado = true;
        mudar("exausto");
        aparado_t = 0;
        inimigo_atordoar(220, true);
        fala_dizer(id, "Argh... não...", make_color_rgb(120, 20, 20), true);
        global.camera_impact = max(global.camera_impact, 8);
    }
};

mini_morrer = function(_dir)
{
    inimigo_morrer(_dir);
    evaporar_tam = 2.2;          // fumaça da maldição maior que a dos inimigos comuns
    aberto_marcar(chave);
    arena_abrir(id);
    musica("mus_fase", 2500);
    progresso_marcar();
    camera_lenta(60, 0.35);
    aviso_mostrar("O CARRASCO CAIU  ·  +" + string(round(ORBS_MINI_BOSS * (finalizado ? ORBS_FINALIZADOR : 1))) + " ORBS");
    fala_dizer(id, "Vallack... reinará...", make_color_rgb(120, 20, 20), true);
};
