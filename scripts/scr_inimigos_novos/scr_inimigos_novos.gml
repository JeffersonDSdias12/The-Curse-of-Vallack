// =====================================================================
//  scr_inimigos_novos (v1.8)
//  Esqueleto Guerreiro, Mulher-Aranha, Porco Corrompido e Estátua
//  Enfeitiçada:
//  * NÍVEL do inimigo (Nv 1 a 5) conforme o avanço no mapa
//  * falas próprias de cada um
//  * HUD (barra de vida com o nível), teia que prende Twilight
//  * projéteis de magia (obj_magia): orbe, teia e onda roxa
// =====================================================================

#macro NIVEL_MAX        5      // (as orbs de cada um estão em scr_progresso)

// ---------------------------------------------------------------------
// NÍVEL: fase 1 = Nv 1 no começo, Nv 2 no meio e Nv 3 perto do guardião;
// fase 2 = Nv 3 a 5. Cada nível dá +15% de vida e +10% de dano (além da
// dificuldade escolhida).
// ---------------------------------------------------------------------
function inimigo_nivel_calcular()
{
    var _p = clamp(x / max(1, room_width), 0, 0.999);
    var _n = 1 + floor(_p * 3);
    if (room == Room2) _n += 2;
    return clamp(_n, 1, NIVEL_MAX);
}

function nivel_vida(_n) { return 1 + 0.15 * (_n - 1); }
function nivel_dano(_n) { return 1 + 0.10 * (_n - 1); }

function nivel_cor(_n)
{
    switch (_n)
    {
        case 1: return make_color_rgb(205, 205, 205);
        case 2: return make_color_rgb(140, 225, 120);
        case 3: return make_color_rgb(255, 210, 90);
        case 4: return make_color_rgb(255, 130, 60);
    }
    return make_color_rgb(235, 100, 255);
}

// Vida pela dificuldade e pelo nível (executado no inimigo, no Create)
function inimigo_status(_vida)
{
    nivel = inimigo_nivel_calcular();
    vida_max = max(1, round(_vida * dif_vida_inimigo() * nivel_vida(nivel)));
    vida = vida_max;
    vida_atraso = vida;
}

// Dano pela dificuldade e pelo nível
function inimigo_dano(_dano)
{
    return max(1, round(_dano * dif_dano_inimigo() * nivel_dano(nivel)));
}

// Golpes que atravessam a pedra da estátua e impedem o esqueleto de se
// reerguer: especiais, Fúria, finalizador e projéteis rebatidos
function golpe_e_forte(_g)
{
    if (is_undefined(_g)) return false;
    if (variable_struct_exists(_g, "especial") and _g.especial) return true;
    var _c = _g[$ "chave"];
    return _c == "ira" or _c == "finalizador" or _c == "flecha" or _c == "fogo" or _c == "orbe" or _c == "teia";
}

// Inimigo dentro da tela (a câmera do jogador)?
function inimigo_na_tela(_margem = 0)
{
    if (!view_enabled or view_camera[0] == -1) return true;
    var _cam = view_camera[0];
    var _cx = camera_get_view_x(_cam);
    var _cy = camera_get_view_y(_cam);
    return x >= _cx - _margem and x <= _cx + camera_get_view_width(_cam) + _margem
        and y - 20 >= _cy - _margem and y - 60 <= _cy + camera_get_view_height(_cam) + _margem;
}

// Pode andar nessa direção sem sair do mapa / da arena / passar da barreira?
function inimigo_pode_andar(_d, _passo = 32)
{
    var _nx = x + _d * _passo;
    if (_nx < 48 or _nx > room_width - 48) return false;
    if (arena_limitar_x(_nx, 24) != _nx) return false;
    if (place_meeting(_nx, y - 4, obj_chao)) return false;
    var _b = instance_find(obj_boss_01, 0);
    if (_b != noone and !_b.morrendo and _nx > _b.barreira_x - 24) return false;
    return true;
}

// Cria um projétil de magia (obj_magia)
function magia_criar(_tipo, _x, _y, _vx, _vy, _dano, _dono)
{
    var _m = instance_create_depth(_x, _y, -60, obj_magia);
    _m.tipo = _tipo;
    _m.vx = _vx;
    _m.vy = _vy;
    _m.dano = _dano;
    _m.dono = _dono;
    if (view_camera[0] != -1) _m.alcance = camera_get_view_width(view_camera[0]) * 1.2;
    return _m;
}

// ---------------------------------------------------------------------
// TEIA: Twilight fica lento, não pula e não rola. Apertar os botões
// (pulo, ataques, esquiva) rasga a teia mais rápido.
// ---------------------------------------------------------------------
function jogador_enredar(_quadros)
{
    with (obj_player)
    {
        if (!morto)
        {
            if (enredado <= 0)
            {
                enredado_max = _quadros;
                som("teia_prende", 0.85);
            }
            enredado = max(enredado, _quadros);
            enredado_max = max(enredado_max, enredado);
            enredado_fx = 10;
        }
    }
}

// ---------------------------------------------------------------------
// HUD sobre o inimigo: atordoamento, finalizador, alerta, barra de vida
// com o nível (executado no Draw do inimigo)
// ---------------------------------------------------------------------
function inimigo_hud(_topo, _larg = 46)
{
    gpu_set_texfilter(true);

    // se libertou do atordoamento (onda vermelha)
    if (libertou_fx > 0)
    {
        var _lf = 1 - libertou_fx / 20;
        draw_set_alpha(1 - _lf);
        draw_set_color(make_color_rgb(255, 80, 60));
        draw_circle(x, (y + _topo) / 2, 12 + 30 * _lf, true);
        draw_set_alpha(1);
    }

    // estrelas de atordoamento
    if (atordoado > 0)
    {
        draw_set_color(make_color_rgb(255, 230, 110));
        for (var _k = 0; _k < 3; _k++)
        {
            var _ang = atordoado_anim * 7 + _k * 120;
            var _sx = x + lengthdir_x(15, _ang);
            var _sy = _topo + 4 + lengthdir_y(4, _ang);
            draw_set_alpha(0.65 + 0.35 * dsin(_ang));
            draw_triangle(_sx - 4, _sy, _sx + 4, _sy, _sx, _sy - 4, false);
            draw_triangle(_sx - 4, _sy, _sx + 4, _sy, _sx, _sy + 4, false);
        }
        draw_set_alpha(1);
    }

    if (finalizavel) desenhar_icone_finalizador(x, _topo - 16);

    // alerta "!"
    if (alerta_fx > 0)
    {
        var _aa = clamp(alerta_fx / 12, 0, 1);
        txt(x, _topo - 8 - (40 - alerta_fx) * 0.2, "!", FONTE.MEDIA, make_color_rgb(255, 80, 60), _aa, fa_center, fa_bottom, 0.8);
    }

    // barra de vida + nível
    var _mostra = (barra_tempo > 0 and vida > 0);
    var _a = _mostra ? min(1, barra_tempo / 24) : clamp(alerta_fx / 20, 0, 1);
    if (_a > 0)
    {
        var _bx = x - _larg / 2;
        var _by = _topo - 6;
        if (_mostra)
        {
            vida_atraso = lerp_dt(vida_atraso, vida, 0.06);
            draw_set_alpha(_a);
            draw_set_color(c_black);
            draw_rectangle(_bx - 2, _by - 2, _bx + _larg + 2, _by + 6, false);
            draw_set_color(c_white);
            draw_rectangle(_bx, _by, _bx + _larg * clamp(vida_atraso / vida_max, 0, 1), _by + 4, false);
            draw_rectangle_color(_bx, _by, _bx + _larg * clamp(vida / vida_max, 0, 1), _by + 4,
                make_color_rgb(230, 80, 65), make_color_rgb(230, 80, 65),
                make_color_rgb(120, 20, 20), make_color_rgb(120, 20, 20), false);
            draw_set_color(make_color_rgb(176, 141, 70));
            draw_rectangle(_bx - 2, _by - 2, _bx + _larg + 2, _by + 6, true);
            draw_set_alpha(1);
        }
        // selo do nível à esquerda da barra
        var _nx = _bx - 6;
        var _ny = _by + 2;
        draw_set_alpha(_a);
        draw_set_color(c_black);
        draw_circle(_nx, _ny, 7, false);
        draw_set_color(nivel_cor(nivel));
        draw_circle(_nx, _ny, 7, true);
        draw_set_alpha(1);
        txt(_nx, _ny + 1, string(nivel), FONTE.MINI, nivel_cor(nivel), _a, fa_center, fa_middle, 0.5);
    }
    gpu_set_texfilter(false);
}

// Desenha o inimigo (com o clarão branco ao levar golpe)
function inimigo_desenhar_corpo(_spr, _img, _x, _y, _xs, _ys, _rot, _cor, _alpha)
{
    if (flash_dano > 0 and !morrendo)
    {
        gpu_set_fog(true, c_white, 0, 0);
        draw_sprite_hd(_spr, _img, _x, _y, _xs, _ys, _rot, c_white, _alpha);
        gpu_set_fog(false, c_white, 0, 0);
    }
    else inimigo_corpo_desenhar(_spr, _img, _x, _y, _xs, _ys, _rot, _cor, _alpha);   // morto: evapora na fumaça
}

// Sombra no chão
function inimigo_sombra(_larg)
{
    if (!place_meeting(x, y + 2, obj_chao)) return;
    draw_set_alpha(0.3 * image_alpha * inimigo_sombra_alpha());
    draw_set_color(c_black);
    draw_ellipse(x - _larg, y - 3, x + _larg, y + 3, false);
    draw_set_alpha(1);
}

// Caixa de colisão e estado (F1)
function inimigo_debug(_extra = "")
{
    if (!global.debug_hitbox) return;
    draw_set_alpha(0.9);
    draw_set_color(c_red);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_set_alpha(1);
    txt(x, bbox_bottom + 4, estado_ia + "  Nv " + string(nivel) + (atordoado > 0 ? " (atordoado)" : "") + _extra, FONTE.MINI, c_yellow, 1, fa_center, fa_top, 0.45);
}

// ---------------------------------------------------------------------
// FALAS
// ---------------------------------------------------------------------
function falas_esqueleto()        { return ["Clec, clec, clec!", "Seus ossos serão meus!", "Pelo senhor Vallack!", "Ossos e aço!", "Junte-se a nós!"]; }
function falas_esqueleto_ergue()  { return ["Ossos não morrem!", "Eu me levanto!", "Vallack me ergue de novo!", "Ainda não acabou!"]; }
function falas_esqueleto_cai()    { return ["Ainda... não...", "Clec...", "Eu... volto..."]; }
function falas_aranha()           { return ["Venha para a minha teia...", "Sssss!", "Que presa saborosa!", "Oito patas, nenhuma saída!", "Fique quietinho..."]; }
function falas_aranha_teia()      { return ["Preso!", "Enrolado como um casulo!", "Não adianta se debater!"]; }
function falas_porco()            { return ["GRRROINC!", "Vou te esmagar!", "Carne para a maldição!", "Saia da minha frente!"]; }
function falas_porco_salto()      { return ["Terra, trema!", "Lá vou eu!", "ESMAGAR!"]; }
function falas_porco_onda()       { return ["Sinta a corrupção!", "Corte roxo!", "Pule, se puder!"]; }
function falas_porco_furia()      { return ["AGORA EU FIQUEI BRAVO!", "Ossos, venham a mim!", "A maldição me fortalece!"]; }
function falas_estatua()          { return ["Quem perturba a pedra?", "Seus passos me acordaram.", "A pedra vê tudo.", "Queime!"]; }
function falas_estatua_imune()    { return ["Pedra não sangra.", "Inútil!", "Espere meus olhos brilharem..."]; }

function cor_fala_esqueleto() { return make_color_rgb(150, 30, 25); }
function cor_fala_aranha()    { return make_color_rgb(90, 60, 120); }
function cor_fala_porco()     { return make_color_rgb(140, 30, 20); }
function cor_fala_estatua()   { return make_color_rgb(70, 80, 40); }
