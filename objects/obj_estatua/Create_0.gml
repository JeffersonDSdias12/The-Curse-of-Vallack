// =====================================================================
//  obj_estatua — ESTÁTUA ENFEITIÇADA (torre parada)
//  * MECÂNICA NOVA — PEDRA: enquanto dorme, é pedra pura e os golpes
//    comuns só tiram faíscas. Quando os OLHOS ACENDEM ela desperta,
//    carrega e dispara um ORBE de magia que persegue Twilight: só nesse
//    momento (e logo depois do disparo) ela pode ser ferida.
//  * especiais, a Fúria e projéteis rebatidos ferem sempre
//  * a defesa segura o orbe; aparado na hora certa, o orbe volta, racha
//    a estátua e a deixa vulnerável por alguns segundos
//  * surge de um portal de magia e tem nível (Nv 1 a 5)
// =====================================================================
event_inherited();       // obj_inimigo_base

mask_index = spr_mascara_estatua;
image_xscale = 1;
image_yscale = 1;
escala = 1.25;           // a arte HD (k = 2) é desenhada a 1,25x
dir = -1;
resiste_atordoar = true;
pode_lancar = false;

// ===== COMBATE (dificuldade + nível) =====
inimigo_status(70);
dano_orbe = inimigo_dano(10);
recarga = irandom_range(40, 90);
recarga_max = round(170 * dif_recarga_inimigo());

// ===== IA =====
estado_ia = "pedra";
estado_ao_surgir = "pedra";
campo = 600;
anim_t = 0;
orbe_solto = false;
vulneravel_t = 0;        // depois do disparo continua vulnerável um pouco
rachada_t = 0;           // orbe rebatido: rachada e vulnerável
tinido_t = 0;
falou = false;
alerta_fx = 0;
morte_anim = 0;
grav_ia = 0.4;

falas = falas_estatua();
cor_fala = cor_fala_estatua();

// ===== SURGIR DO CHÃO (portal de magia; scr_dano) =====
inimigo_portal_iniciar();

// ===== SPRITE (8 quadros: 0 pedra, 1-5 olhos acesos, 6-7 apagando) =====
spr_ia_parado = spr_estatua;
spr_morrer = spr_estatua;
sprite_index = spr_estatua;
image_index = 0;
image_speed = 0;

estatua_vulneravel = function()
{
    return (estado_ia == "desperta") or (vulneravel_t > 0) or (rachada_t > 0);
};

// PEDRA: golpes comuns não ferem (só faíscas e um tinido)
bloquear_golpe = function(_golpe, _origem_x)
{
    if (estatua_vulneravel() or golpe_e_forte(_golpe)) return false;
    tinido_t = 10;
    som_em("pedra_tinido", x, y, 0.8);
    var _lado = (_origem_x == x) ? -dir : sign(_origem_x - x);
    repeat (3)
    {
        var _f = instance_create_depth(x + _lado * 20, y - random_range(30, 70), -100, obj_fagulha);
        _f.cor = choose(make_color_rgb(255, 230, 160), make_color_rgb(180, 170, 150));
    }
    if (!is_undefined(_golpe)) with (obj_player) empurrao = -facing * 1.6;
    if (random(1) < 0.3) fala_aleatoria(id, falas_estatua_imune(), cor_fala, 1);
    return true;
};

reagir_dano = function(_dano, _dir, _forca)
{
    if (vida <= 0)
    {
        inimigo_morrer(_dir);
        velh = 0;
        image_speed = 0;
        morte_anim = 0;
        som_em("pedra_desmorona", x, y, 1);
        fx_em("entulho", x, y, 0.8);
        fala_dizer(id, "A maldição... se parte...", cor_fala, true);
        return;
    }
    if (random(1) < 0.12) fala_dizer(id, choose("Crac!", "Minha pedra!"), cor_fala);
};
