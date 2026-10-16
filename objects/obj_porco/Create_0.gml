// =====================================================================
//  obj_porco — PORCO CORROMPIDO (brutamontes)
//  * pesado: golpes comuns não o atordoam nem o lançam (só aparar ou a
//    exaustão); recua pouco
//  * CORTE VERMELHO de perto (golpe duplo; um em cada três QUEBRA a guarda)
//  * MECÂNICA NOVA — SALTO ESMAGADOR: pula até Twilight e, ao cair, faz
//    uma onda de choque no chão (não dá para defender: pule ou role)
//  * MECÂNICA NOVA — CORTE ROXO: lança uma onda de magia rente ao chão
//    (não dá para defender: pule por cima ou role através dela)
//  * MECÂNICA NOVA — FÚRIA: com metade da vida ele ruge, invoca esqueletos
//    por portais de magia e fica mais rápido (aura vermelha)
//  * surge de um portal de magia e tem nível (Nv 1 a 5)
// =====================================================================
event_inherited();       // obj_inimigo_base

mask_index = spr_mascara_porco;
image_xscale = 1;
image_yscale = 1;
escala = 1.85;           // a arte HD (k = 2) é desenhada a 1,85x
dir = -1;
resiste_atordoar = true;
pode_lancar = false;

// ===== COMBATE (dificuldade + nível) =====
inimigo_status(160);
dano_ataque = inimigo_dano(13);
dano_salto = inimigo_dano(15);
dano_onda = inimigo_dano(11);
recarga = irandom_range(30, 60);
recarga_max = round(70 * dif_recarga_inimigo());
recarga_salto_max = round(330 * dif_recarga_inimigo());
recarga_salto = irandom_range(120, 220);
recarga_onda_max = round(280 * dif_recarga_inimigo());
recarga_onda = irandom_range(70, 150);
contador_ataques = 0;
ataque_bloqueavel = true;

// ===== IA =====
estado_ia = "parado";
campo = 560;
campo_altura = 160;
vel_correr = 1.9;
alcance_ataque = 66;
alerta_fx = 0;
viu = false;
grav_ia = 0.45;
forca_salto = 8;
golpe_janelas = [[3, 4], [8, 8]];     // corte de cima e estocada baixa
golpe_janela = -1;
golpe_som_i = 0;
onda_solta = false;
no_ar_t = 0;
furioso = false;
furia_pendente = false;
invocou = false;
aura_t = 0;
morte_anim = 0;

falas = falas_porco();
cor_fala = cor_fala_porco();

// ===== SURGIR DO CHÃO (portal de magia; scr_dano) =====
inimigo_portal_iniciar();

// ===== SPRITES =====
spr_ia_parado = spr_porco_parado;
spr_ia_correr = spr_porco_correndo;
spr_ia_ataque = spr_porco_ataque;
spr_morrer    = spr_porco_morrendo;
sprite_index = spr_ia_parado;
image_index = irandom(2);
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
    empurrao = _dir * _forca * 0.15;           // quase não recua
    if (vida <= 0)
    {
        inimigo_morrer(_dir);
        velh = _dir * 0.6;
        som_em("porco_grunhido", x, y, 1);
        fala_dizer(id, "Grr... oinc...", cor_fala, true);
        return;
    }
    if (!invocou and vida <= vida_max * 0.5) furia_pendente = true;
    else if (random(1) < 0.1) fala_dizer(id, choose("Oinc!", "Grrr!", "Isso coçou!"), cor_fala);
};

// MECÂNICA: invoca esqueletos por portais de magia em volta dele
porco_invocar = function()
{
    var _n = dif_valor([1, 2, 2, 3]);
    var _p = instance_find(obj_player, 0);
    for (var _i = 0; _i < _n; _i++)
    {
        var _lado = (_i mod 2 == 0) ? -dir : dir;
        var _sx = x + _lado * (90 + 50 * floor(_i / 2) + random(30));
        _sx = clamp(arena_limitar_x(_sx, 40), 60, room_width - 60);
        if (_p != noone and abs(_sx - _p.x) < 60) _sx += (_sx < _p.x) ? -70 : 70;
        var _sy = chao_abaixo(_sx, y - 120, 300);
        var _e = instance_create_depth(_sx, _sy, depth + 1, obj_esqueleto);
        _e.invocado = true;
        _e.reerguido = true;           // servos invocados não se levantam de novo
        _e.surgir_agora = true;
        _e.surgir_atraso = 10 + _i * 14;
        _e.dir = (_p != noone) ? sign(_p.x - _sx) : -1;
        if (_e.dir == 0) _e.dir = -1;
    }
};
