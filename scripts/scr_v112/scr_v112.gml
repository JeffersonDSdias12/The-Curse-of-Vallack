// =====================================================================
//  scr_v112: mecânicas da v1.12 (pedidos da fase de testes)
//  * diálogos em caixa (morador, Carrasco, Árvore Amaldiçoada)
//  * sub-armas com ESSÊNCIA (Lâmina Bumerangue e Chama de Sylla)
//  * MODO FÚRIA: super armadura, roubo de vida e petrificação
//  * crítico com a ponta da espada, combos aéreos e elites
//  * textos que sobem (CRÍTICO, CONTRA-ATAQUE)
// =====================================================================

#macro ESSENCIA_MAX        9
#macro ESSENCIA_INICIO     3
#macro FURIA_MODO_QUADROS  720     // 12 s de Modo Fúria
#macro CRITICO_PONTA       0.68    // acertar a partir de 68% do alcance do golpe
#macro CRITICO_MULT        1.5
#macro RECUAR_DURACAO      18      // backdash
#macro RECUAR_INVENC       10      // quadros do backdash sem levar dano
#macro RECUAR_VEL          7.4
#macro AEREO_MAX           3       // cortes aéreos seguidos antes de tocar o chão
#macro ESPINHOS_ESCALA     1.6     // espinhos do chão maiores (área de dano acompanha)

// ---------------------------------------------------------------------
// TEXTO QUE SOBE E SOME (só para o que importa: crítico e contra-ataque)
// ---------------------------------------------------------------------
function popup_criar(_x, _y, _texto, _cor, _escala = 1)
{
    var _p = instance_create_depth(_x, _y, -160, obj_popup);
    _p.texto = _texto;
    _p.cor = _cor;
    _p.escala = _escala;
    return _p;
}

// ---------------------------------------------------------------------
// DIÁLOGOS
// Cada fala: { q: quem fala, t: texto }. Quem: "twilight", "morador",
// "carrasco" ou "arvore". O diálogo pausa o mundo (como os pergaminhos).
// Para mudar uma fala, é só trocar o texto aqui.
// ---------------------------------------------------------------------
function dialogo_falas(_id)
{
    switch (_id)
    {
        case "morador":
            return [
                { q: "morador",  t: "Senhor! Graças aos céus... Os servos de Vallack invadiram a vila!" },
                { q: "twilight", t: "Leve todos para a ponte do norte. Ninguém fica nas ruas: eu cuido deles." },
                { q: "morador",  t: "E o fogo? Chove a noite inteira e as casas não param de queimar!" },
                { q: "twilight", t: "Não é fogo comum. Essas chamas roxas vêm do poder de Vallack. A chuva não as apaga." },
                { q: "morador",  t: "Os anciãos dizem que só a água mágica do templo de Sylla apaga a chama maldita..." },
                { q: "twilight", t: "Então vou buscá-la, depois de abrir caminho até o castelo. Agora vá!" }
            ];
        case "carrasco_inicio":
            return [
                { q: "carrasco", t: "Mais um herói vindo morrer na estrada de Vallack." },
                { q: "twilight", t: "Saia da frente, Carrasco. Esta vila não pertence ao seu mestre." },
                { q: "carrasco", t: "Tudo pertence a Vallack. Até a sua cabeça... quando eu a cortar!" }
            ];
        case "carrasco_fase2":
            return [ { q: "carrasco", t: "Você luta bem... Chega de brincadeira!" } ];
        case "carrasco_fim":
            return [
                { q: "carrasco", t: "Isso... não acaba aqui... A Árvore guarda a estrada..." },
                { q: "twilight", t: "Então ela é a próxima." }
            ];
        case "arvore_inicio":
            return [
                { q: "arvore",   t: "Pequeno guerreiro... Minhas raízes beberam o sangue de mil invasores." },
                { q: "twilight", t: "Foi você quem espalhou a chama maldita pela vila?" },
                { q: "arvore",   t: "A chama é de Vallack. Eu apenas a guardo. Nenhuma chuva vai apagá-la!" },
                { q: "twilight", t: "Então vou arrancá-la pela raiz." }
            ];
        case "arvore_fase2":
            return [ { q: "arvore", t: "Sinta a floresta inteira se erguer contra você!" } ];
        case "arvore_fase3":
            return [ { q: "arvore", t: "Vallack... me dê força... QUEIME!" } ];
        case "arvore_fim":
            return [
                { q: "arvore",   t: "A chama... não morre comigo... só a água do templo..." },
                { q: "twilight", t: "Então é para o templo que eu vou." }
            ];
    }
    return [];
}

function dialogo_nome(_q)
{
    switch (_q)
    {
        case "twilight": return string_upper(NOME_GUERREIRO);
        case "morador":  return "MORADOR DA VILA";
        case "carrasco": return "O CARRASCO DE VALLACK";
        case "arvore":   return "ÁRVORE AMALDIÇOADA";
    }
    return "";
}

function dialogo_cor(_q)
{
    switch (_q)
    {
        case "twilight": return make_color_rgb(255, 210, 90);
        case "morador":  return make_color_rgb(200, 190, 170);
        case "carrasco": return make_color_rgb(230, 90, 80);
        case "arvore":   return make_color_rgb(190, 110, 255);
    }
    return c_white;
}

// Retrato: [sprite, quadro, cor]
function dialogo_retrato(_q)
{
    switch (_q)
    {
        case "twilight": return [spr_player_idle, 0, c_white];
        case "morador":  return [spr_morador_parado, 0, c_white];
        case "carrasco": return [spr_inimigo01_parado, 0, make_color_rgb(175, 125, 140)];
        case "arvore":   return [spr_boss_01_parado, 0, c_white];
    }
    return [-1, 0, c_white];
}

// Abre um diálogo. _ao_fim (opcional): função chamada quando ele fecha.
function dialogo_iniciar(_id, _ao_fim = undefined)
{
    if (instance_exists(obj_dialogo)) return noone;
    var _falas = dialogo_falas(_id);
    if (array_length(_falas) == 0) return noone;
    var _d = instance_create_depth(0, 0, -10400, obj_dialogo);
    _d.falas = _falas;
    _d.ao_fim = _ao_fim;
    return _d;            // o obj_dialogo pausa o mundo no Step dele
}

// ---------------------------------------------------------------------
// ESSÊNCIA E SUB-ARMAS
// ---------------------------------------------------------------------
function essencia_ganhar(_n)
{
    global.essencia = clamp(global.essencia + _n, 0, ESSENCIA_MAX);
    global.essencia_coletada += _n;
    global.essencia_fx = 20;
}

// Solta cristais de essência que voam até Twilight (como as orbs)
function essencia_soltar(_x, _y, _n)
{
    repeat (_n)
    {
        var _e = instance_create_depth(_x + random_range(-6, 6), _y + random_range(-6, 6), -121, obj_essencia);
        _e.vx = random_range(-2.2, 2.2);
        _e.vy = random_range(-4.4, -2);
    }
}

// Quantos cristais um inimigo derrotado deixa (chance)
function essencia_do_inimigo(_inst)
{
    if (_inst.invocado or _inst.eh_boss) return 0;
    if (_inst.elite) return 3;
    switch (_inst.object_index)
    {
        case obj_porco:      return 2;
        case obj_inimigo_03: return (random(1) < 0.6) ? 1 : 0;
        case obj_estatua:    return (random(1) < 0.6) ? 1 : 0;
        case obj_mini_boss:  return 4;
    }
    return (random(1) < 0.35) ? 1 : 0;
}

function subarma_custo(_agachado) { return _agachado ? 2 : 1; }
function subarma_nome(_agachado) { return _agachado ? "CHAMA DE SYLLA" : "LÂMINA BUMERANGUE"; }

// ---------------------------------------------------------------------
// MODO FÚRIA (executado no jogador)
// ---------------------------------------------------------------------
function furia_modo_ativo()
{
    var _p = instance_find(obj_player, 0);
    return (_p != noone and _p.furia_modo);
}

// Sangue de um inimigo derrotado voando para a lâmina (enche a FÚRIA)
function sangue_soltar(_x, _y, _n)
{
    if (furia_modo_ativo()) return;      // durante o Modo Fúria a barra só esvazia
    var _q = (global.cfg_qualidade == 0) ? max(2, round(_n * 0.5)) : _n;
    var _valor = _n * 1.15 / _q;         // a soma é a mesma em qualquer qualidade
    repeat (_q)
    {
        var _s = instance_create_depth(_x + random_range(-10, 10), _y + random_range(-16, 8), -122, obj_sangue);
        _s.valor = _valor;
        _s.vx = random_range(-1.6, 1.6);
        _s.vy = random_range(-3, -1);
    }
}

function sangue_do_inimigo(_inst)
{
    if (_inst.invocado) return 2;
    if (_inst.elite) return 14;
    switch (_inst.object_index)
    {
        case obj_porco:      return 12;
        case obj_mini_boss:  return 30;
        case obj_boss_01:    return 0;
        case obj_inimigo_03: return 8;
        case obj_estatua:    return 8;
    }
    return 6;
}

// Petrificação: cada golpe no Modo Fúria endurece o inimigo um pouco.
// Com 3 golpes ele vira pedra por um instante (executado no inimigo).
function inimigo_petrificar()
{
    if (morrendo or !ativo or eh_boss) return;
    petrif = min(3, petrif + 1);
    petrif_t = 150;
    if (petrif >= 3 and !petrificado)
    {
        petrificado = true;
        inimigo_atordoar(resiste_atordoar ? 50 : 110, true);
        som_em("sfx_petrificar", x, y, 0.8);
        fx_em("pedras", x, y - 30, 0.5);
    }
}

// ---------------------------------------------------------------------
// ELITES (executado no Create dos inimigos de elite)
// ---------------------------------------------------------------------
function elite_aplicar()
{
    elite = true;
    vida_max = max(1, round(vida_max * 2.4));
    vida = vida_max;
    vida_atraso = vida;
    if (variable_instance_exists(id, "dano_ataque")) dano_ataque = max(1, round(dano_ataque * 1.3));
    if (variable_instance_exists(id, "escala_vis")) escala_vis *= 1.15;
    if (variable_instance_exists(id, "topo_vis")) topo_vis *= 1.15;
    if (variable_instance_exists(id, "cor_base")) cor_base = merge_color(cor_base, make_color_rgb(255, 90, 80), 0.35);
    usa_hud_nivel = true;
}

// ---------------------------------------------------------------------
// COMBO AÉREO: o inimigo atingido no ar fica "suspenso" (gravidade baixa)
// por alguns quadros, para Twilight continuar o combo lá em cima
// (executado no inimigo). obj_inimigo_base devolve a gravidade no End Step.
// ---------------------------------------------------------------------
function inimigo_suspender(_quadros)
{
    if (suspenso_t <= 0) grav_ia_base = grav_ia;
    grav_ia = 0.14;
    suspenso_t = max(suspenso_t, _quadros);
}

// Cristal de essência (no mundo e no HUD)
function essencia_desenhar(_x, _y, _k = 1, _alpha = 1)
{
    var _b = 0.7 + 0.3 * sin(current_time / 120);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.35 * _b * _alpha);
    draw_set_color(make_color_rgb(80, 160, 255));
    draw_circle(_x, _y, 9 * _k, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(60, 130, 255));
    draw_triangle(_x, _y - 7 * _k, _x + 5 * _k, _y, _x - 5 * _k, _y, false);
    draw_triangle(_x - 5 * _k, _y, _x + 5 * _k, _y, _x, _y + 7 * _k, false);
    draw_set_color(make_color_rgb(210, 235, 255));
    draw_triangle(_x, _y - 7 * _k, _x + 2 * _k, _y - 1 * _k, _x - 2 * _k, _y - 1 * _k, false);
    draw_set_color(c_white);
    draw_set_alpha(1);
}
