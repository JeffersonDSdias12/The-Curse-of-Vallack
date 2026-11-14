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
usa_qte = true;          // v1.17: com 1/4 da vida, a SEQUÊNCIA DE GOLPES o derruba
porcos_1 = false;        // v1.17: convoca javalis de guerra com 50% e com 30% da vida
porcos_2 = false;
// v1.19: SEGUNDA VIDA: a primeira sequência completa não o mata; ele se ergue
// de novo, a barra enche e ele volta mais rápido. Só a segunda sequência mata.
segunda_vida = true;     // ainda tem a vida extra
na_segunda_vida = false; // já está na segunda vida (mais rápido, barra com aviso)
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
    musica("bgm_mini_boss", 1500);           // v1.16: trilha do mini boss ao entrar na arena
    som("sfx_rugido", 1, 0);
    global.camera_impact = max(global.camera_impact, 12);
    global.dano_na_luta = 0;                 // v1.17: conquista INTOCÁVEL
    dialogo_iniciar("carrasco_inicio");      // v1.12: caixa de diálogo
};

reagir_dano = function(_dano, _dir, _forca)
{
    // super armadura: não recua com golpes comuns
    empurrao = _dir * 0.4;
    if (!acordado) despertar();
    // v1.17: só cai pela SEQUÊNCIA DE GOLPES (até ela, a vida para em 1)
    if (estado_ia == "renascer") { vida = max(vida, 1); return; }
    if (vida <= 0)
    {
        if (qte_vencido)
        {
            // v1.19: a primeira sequência não mata: ele renasce com a barra cheia
            if (segunda_vida) { mini_renascer(); return; }
            mini_morrer(_dir);
            return;
        }
        vida = 1;
    }
    // v1.17: antes de cair, convoca os javalis de guerra
    if (!porcos_1 and vida <= vida_max * 0.5) { porcos_1 = true; invocar_porcos(dif_valor([1, 2, 2, 3])); }
    else if (!porcos_2 and vida <= vida_max * 0.3) { porcos_2 = true; invocar_porcos(dif_valor([2, 3, 3, 4])); }
    // v1.12: FASE 2 com 60% da vida: mais rápido e mais agressivo
    if (!enfurecido and vida <= vida_max * 0.6)
    {
        enfurecido = true;
        som("sfx_rugido", 0.9, 0);
        global.camera_impact = max(global.camera_impact, 10);
        aviso_mostrar("O CARRASCO SE ENFURECEU!");
        dialogo_iniciar("carrasco_fase2");
    }
    // 1/4 da vida: cai de joelhos e fica pronto para a SEQUÊNCIA DE GOLPES (v1.17)
    if (!exausto_usado and vida <= vida_max * 0.25)
    {
        exausto_usado = true;
        mudar("exausto");
        aparado_t = 0;
        inimigo_atordoar(260, true);
        global.camera_impact = max(global.camera_impact, 8);
        aviso_mostrar("O CARRASCO CAIU DE JOELHOS  ·  EXECUTE-O!");
    }
};

// v1.17: os JAVALIS DE GUERRA surgem nas pontas da arena, longe de Twilight
invocar_porcos = function(_n)
{
    var _p = instance_find(obj_player, 0);
    var _px = (_p != noone) ? _p.x : x;
    for (var _k = 0; _k < _n; _k++)
    {
        var _sx = (_k mod 2 == 0) ? arena_x1 + 70 + _k * 26 : arena_x2 - 70 - _k * 26;
        if (abs(_sx - _px) < 100) _sx += (_sx < _px) ? -110 : 110;
        _sx = clamp(_sx, arena_x1 + 40, arena_x2 - 40);
        var _sy = chao_abaixo(_sx, y_chao - 120, 300);
        var _e = instance_create_depth(_sx, _sy, 100, obj_porco);
        _e.invocado = true;
        _e.surgir_agora = true;
        _e.surgir_atraso = 6 + _k * 16;
        _e.dir = sign(_px - _sx);
        if (_e.dir == 0) _e.dir = -1;
        _e.vida_max = max(1, round(_e.vida_max * 0.6));
        _e.vida = _e.vida_max;
        _e.vida_atraso = _e.vida;
        _e.limite_x1 = arena_x1 + 24;
        _e.limite_x2 = arena_x2 - 24;
    }
    som("sfx_rugido", 1, 0);
    som("porco_grunhido", 0.9, 0.05);
    global.camera_impact = max(global.camera_impact, 12);
    aviso_mostrar("O CARRASCO CONVOCA OS JAVALIS DE GUERRA!");
};

// v1.17: a sequência de golpes falhou: levanta furioso, empurra Twilight e volta a lutar
qte_falhou = function()
{
    enfurecido = true;
    atordoado = 0;
    aparado_t = 0;
    atordoado_acumulado = 0;
    imune_atordoar = 90;
    vida = max(vida, round(vida_max * 0.4));
    vida_atraso = vida;
    exausto_usado = false;            // pode cair de joelhos de novo
    mudar("perseguir");
    recarga = 30;
    som("sfx_rugido", 1, 0);
    global.camera_impact = max(global.camera_impact, 14);
    fx_em("onda_chao", x, y, 1.2);
    var _p = instance_find(obj_player, 0);
    if (_p != noone) with (_p) levar_dano(max(1, round(other.dano_corte * 0.6)), other.x, false, 9, other.id);
    aviso_mostrar("O CARRASCO SE SOLTOU!");
};

// v1.19: SEGUNDA VIDA. Fica invulnerável no estado "renascer" (Step) enquanto a
// barra enche; depois volta à luta enfurecido e mais rápido.
mini_renascer = function()
{
    segunda_vida = false;
    na_segunda_vida = true;
    qte_vencido = false;
    finalizado = false;
    executando = false;
    finalizavel = false;
    qte_pronto = false;
    atordoado = 0;
    aparado_t = 0;
    atordoado_acumulado = 0;
    vida = 1;
    vida_atraso = 1;
    exausto_usado = false;          // pode cair de joelhos de novo (e levar a sequência final)
    porcos_1 = false;               // e convoca os javalis de novo
    porcos_2 = false;
    enfurecido = true;
    cor_base = make_color_rgb(215, 80, 80);
    mudar("renascer");
    tempo_invencivel = 30;
    with (obj_qte) instance_destroy();
    global.qte_alvo = noone;
    som("sfx_rugido", 1, 0);
    global.camera_impact = max(global.camera_impact, 18);
    global.terremoto = max(global.terremoto, 40);
    camera_lenta(50, 0.4);
    fx_em("fumaca_maldita_estouro", x, y - 50, 1.6);
    aviso_mostrar("O CARRASCO SE RECUSA A CAIR!");
};

mini_morrer = function(_dir)
{
    inimigo_morrer(_dir);
    evaporar_tam = 2.2;          // fumaça da maldição maior que a dos inimigos comuns
    aberto_marcar(chave);
    arena_abrir(id);
    musica(musica_fase(), 1500);             // de volta à trilha de batalha da fase
    progresso_marcar();
    camera_lenta(60, 0.35);
    aviso_mostrar("O CARRASCO CAIU  ·  +" + string(round(ORBS_MINI_BOSS * (finalizado ? ORBS_FINALIZADOR : 1))) + " ORBS");
    // v1.17: ORBES DE VIDA (verdes) e as conquistas
    orbs_vida_soltar(x, y - 50, dif_valor([8, 6, 5, 4]), 6);
    conquista("carrasco");
    if (global.dano_na_luta <= 0) conquista("intocavel");
    dialogo_fim_t = 50;          // v1.12: últimas palavras numa caixa de diálogo
};
dialogo_fim_t = 0;
