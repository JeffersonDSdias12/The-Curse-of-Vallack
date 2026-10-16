// =====================================================================
//  scr_input: teclado + controle (botões, analógico e direcional "hat"),
//  navegação de menus e nomes de teclas/botões para a interface.
//  * reconhece controles XInput (Xbox e compatíveis, slots 0-3) e
//    DirectInput / genéricos (slots 4-11 no Windows)
//  * qualquer botão de qualquer controle pode ser remapeado
// =====================================================================

// códigos especiais para os direcionais "hat" de controles genéricos
#macro PAD_HAT_BASE  2000

function acoes_nomes()
{
    return ["CORRER À ESQUERDA", "CORRER À DIREITA", "PULAR", "ATAQUE (COMBO)", "ESPECIAL · ONDA", "DEFENDER / APARAR", "INTERAGIR", "AGACHAR",
            "GOLPE PESADO", "RASTEIRA / FINALIZADOR", "ESPECIAL · QUEDA", "ESPECIAL · TREMOR", "ESQUIVA (ROLAR)", "FÚRIA"];
}

// ordem das ações na tela de remapeamento: coluna MOVIMENTO e coluna COMBATE
function acoes_ordem_tela()
{
    return [ACAO.ESQUERDA, ACAO.DIREITA, ACAO.PULAR, ACAO.AGACHAR, ACAO.ESQUIVA, ACAO.DEFENDER, ACAO.INTERAGIR,
            ACAO.ATACAR, ACAO.ATAQUE_FORTE, ACAO.ATAQUE_SALTO, ACAO.ESPECIAL_3, ACAO.ESPECIAL, ACAO.ESPECIAL_2, ACAO.FURIA];
}
#macro MAP_COL1 7      // quantas ações ficam na 1ª coluna da tela de remapeamento

// Teclado: A/D correm (Twilight sempre corre), W pula, S agacha, ESPAÇO esquiva, Q defende
// (apertar na hora certa apara), E interage, R fúria, J ataque, I golpe pesado,
// K rasteira/finalizador, U / L / O especiais (Tremor / Onda / Queda).
// ESC abre a pausa e TAB a tela de armas.
function teclas_padrao()
{
    return [ord("A"), ord("D"), ord("W"), ord("J"), ord("L"), ord("Q"), ord("E"), ord("S"),
            ord("I"), ord("K"), ord("O"), ord("U"), vk_space, ord("R")];
}

// Teclas extras fixas (setas), usadas só se não estiverem ocupadas por outra ação.
function teclas_secundarias()
{
    var _s = array_create(ACAO.TOTAL, -1);
    _s[ACAO.ESQUERDA] = vk_left;
    _s[ACAO.DIREITA]  = vk_right;
    _s[ACAO.PULAR]    = vk_up;
    _s[ACAO.AGACHAR]  = vk_down;
    return _s;
}

// Controle (nomes do PlayStation): QUADRADO ataca, TRIÂNGULO golpe pesado,
// BOLA rasteira / finalizador, X pula, L1 defende / apara, L2 esquiva,
// R1 / R2 / R3 especiais (Tremor / Onda / Queda), L3 fúria, D-pad cima interage.
// Twilight sempre corre: basta o analógico ou o D-pad para os lados.
// SELECT abre a pausa (opções) e START a tela de armas e evolução.
function botoes_padrao()
{
    return [gp_padl, gp_padr, gp_face1, gp_face3, gp_shoulderrb, gp_shoulderl, gp_padu, gp_padd,
            gp_face4, gp_face2, gp_stickr, gp_shoulderr, gp_shoulderlb, gp_stickl];
}

// Botões que podem ser escolhidos no remapeamento (START e SELECT abrem os menus)
function botoes_remapeaveis()
{
    return [gp_face1, gp_face2, gp_face3, gp_face4, gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb,
            gp_stickl, gp_stickr, gp_padu, gp_padd, gp_padl, gp_padr,
            PAD_HAT_BASE + 1, PAD_HAT_BASE + 2, PAD_HAT_BASE + 4, PAD_HAT_BASE + 8];
}

// Teclas que não podem ser usadas em ações (são do sistema)
function tecla_reservada(_k)
{
    return (_k == vk_escape or _k == vk_enter or _k == vk_tab or _k == vk_f1 or _k == vk_f11 or _k <= 0);
}

// ---------------------------------------------------------------------
// CONTROLES CONECTADOS
// ---------------------------------------------------------------------
function gamepad_slots_total()
{
    return max(12, gamepad_get_device_count());
}

function gamepad_slot_conectado()
{
    // XInput normalmente ocupa 0-3; DirectInput no Windows pode ocupar 4-11.
    var _n = gamepad_slots_total();
    for (var _i = 0; _i < _n; _i++) if (gamepad_is_connected(_i)) return _i;
    return -1;
}

// Algum botão (ou direcional) deste controle está apertado agora?
function gamepad_alguma_entrada(_pad)
{
    var _lista = botoes_remapeaveis();
    for (var _b = 0; _b < array_length(_lista); _b++) if (pad_entrada(_pad, _lista[_b])) return true;
    if (gamepad_button_check(_pad, gp_start) or gamepad_button_check(_pad, gp_select)) return true;
    return false;
}

// Escolhe o controle em uso: mantém o atual; se outro controle for usado,
// passa a ser ele (útil com mais de um controle conectado).
function gamepad_escolher()
{
    var _atual = global.pad_slot;
    if (_atual >= 0 and !gamepad_is_connected(_atual)) _atual = -1;
    var _n = gamepad_slots_total();
    var _conectados = 0;
    for (var _i = 0; _i < _n; _i++)
    {
        if (!gamepad_is_connected(_i)) continue;
        _conectados += 1;
        if (_atual == -1) _atual = _i;
        else if (_i != _atual and gamepad_alguma_entrada(_i)) _atual = _i;
    }
    if (_atual != global.pad_slot)
    {
        global.pad_slot = _atual;
        if (_atual >= 0)
        {
            gamepad_set_axis_deadzone(_atual, 0.25);
            global.pad_desc = gamepad_get_description(_atual);
            global.pad_botoes = gamepad_button_count(_atual);
        }
        else
        {
            global.pad_desc = "";
            global.pad_botoes = 0;
        }
    }
    return _atual;
}

// Estilo dos nomes/ícones: "ps" (PlayStation e genéricos) ou "xbox"
function pad_estilo()
{
    var _d = string_lower(global.pad_desc);
    if (string_pos("xbox", _d) > 0 or string_pos("xinput", _d) > 0 or string_pos("x-box", _d) > 0) return "xbox";
    if (os_type == os_windows and global.pad_slot >= 0 and global.pad_slot < 4
        and string_pos("sony", _d) == 0 and string_pos("dual", _d) == 0 and string_pos("playstation", _d) == 0 and string_pos("wireless controller", _d) == 0) return "xbox";
    return "ps";
}

function gamepad_descricao_conectado()
{
    var _slot = global.pad_slot;
    if (_slot < 0) return "NENHUM CONECTADO";
    var _d = global.pad_desc;
    if (_d == "") _d = "CONTROLE " + string(_slot + 1);
    if (string_length(_d) > 26) _d = string_copy(_d, 1, 24) + "..";
    return string_upper(_d);
}

// Estado de um botão (ou direcional "hat") do controle (-1 = sem botão)
function pad_entrada(_pad, _codigo)
{
    if (_pad < 0 or _codigo < 0) return false;
    if (_codigo >= PAD_HAT_BASE and _codigo < PAD_HAT_BASE + 16)
    {
        if (gamepad_hat_count(_pad) <= 0) return false;
        return (gamepad_hat_value(_pad, 0) & (_codigo - PAD_HAT_BASE)) != 0;
    }
    // gatilhos analógicos (L2/R2) contam como apertados a partir da metade
    if (_codigo == gp_shoulderlb or _codigo == gp_shoulderrb)
        return gamepad_button_check(_pad, _codigo) or gamepad_button_value(_pad, _codigo) > 0.45;
    if (gamepad_button_check(_pad, _codigo)) return true;
    // controles genéricos: o D-pad costuma chegar como direcional "hat" e não como botão.
    // Assim qualquer ação colocada no D-pad (ex.: INTERAGIR no D-pad cima) funciona nos dois tipos.
    if (_codigo == gp_padu or _codigo == gp_padd or _codigo == gp_padl or _codigo == gp_padr)
    {
        if (gamepad_hat_count(_pad) <= 0) return false;
        var _bit = (_codigo == gp_padu) ? 1 : ((_codigo == gp_padr) ? 2 : ((_codigo == gp_padd) ? 4 : 8));
        return (gamepad_hat_value(_pad, 0) & _bit) != 0;
    }
    return false;
}

// ---------------------------------------------------------------------
// Atualização (chamada 1x por quadro pelo obj_sistema, no Begin Step)
// ---------------------------------------------------------------------
function input_atualizar()
{
    var _pad = gamepad_escolher();
    var _ax = 0;
    var _ay = 0;
    var _hat = 0;
    if (_pad >= 0)
    {
        _ax = gamepad_axis_value(_pad, gp_axislh);
        _ay = gamepad_axis_value(_pad, gp_axislv);
        // controles genéricos: o direcional costuma ser um "hat"
        if (gamepad_hat_count(_pad) > 0) _hat = gamepad_hat_value(_pad, 0);
    }
    global.pad_eixo = abs(_ax);

    // analógico direito: um "toque" para o lado faz a esquiva (como no God of War 2)
    var _rx = (_pad >= 0) ? gamepad_axis_value(_pad, gp_axisrh) : 0;
    global.esquiva_stick = 0;
    if (abs(_rx) > 0.7 and abs(global.eixo_dir_antes) <= 0.7) global.esquiva_stick = sign(_rx);
    global.eixo_dir_antes = _rx;

    // de onde veio o último comando (troca os ícones da interface)
    if (keyboard_check_pressed(vk_anykey) or mouse_check_button_pressed(mb_any)) global.usando_pad = false;
    if (_pad >= 0 and (abs(_ax) > 0.5 or abs(_ay) > 0.5 or _hat != 0 or gamepad_alguma_entrada(_pad))) global.usando_pad = true;

    var _sec = teclas_secundarias();
    for (var _i = 0; _i < ACAO.TOTAL; _i++)
    {
        var _h = keyboard_check(global.teclas[_i]);
        var _k2 = _sec[_i];
        if (!_h and _k2 > 0 and !array_tem(global.teclas, _k2) and keyboard_check(_k2)) _h = true;
        var _hp = (_pad >= 0 and pad_entrada(_pad, global.botoes[_i]));
        // analógico: anda a partir de 35% (corre a partir de 80%, no obj_player);
        // agacha só com o analógico para BAIXO (não na diagonal de quem está correndo)
        if (_i == ACAO.ESQUERDA and (_ax < -0.35 or (_hat & 8) != 0)) _hp = true;
        if (_i == ACAO.DIREITA  and (_ax >  0.35 or (_hat & 2) != 0)) _hp = true;
        if (_i == ACAO.AGACHAR  and ((_ay > 0.65 and _ay > abs(_ax)) or (_hat & 4) != 0)) _hp = true;
        var _total = _h or _hp;
        global.inp_apertado[_i] = _total and !global.inp_segurado[_i];
        global.inp_pad_apertado[_i] = global.inp_apertado[_i] and _hp;
        global.inp_segurado[_i] = _total;
    }

    input_nav_atualizar(_pad, _ax, _ay, _hat);
}

function input_segurado(_acao) { return global.inp_segurado[_acao]; }
function input_apertado(_acao) { return global.inp_apertado[_acao]; }

// ESC / SELECT: pausa (menu de opções)
function input_pausa_apertada()
{
    return keyboard_check_pressed(vk_escape)
        or (global.pad_slot >= 0 and gamepad_button_check_pressed(global.pad_slot, gp_select));
}

// TAB / START: tela de armas e evolução
function input_armas_apertado()
{
    return keyboard_check_pressed(vk_tab)
        or (global.pad_slot >= 0 and gamepad_button_check_pressed(global.pad_slot, gp_start));
}

// fecha qualquer menu de jogo (ESC, TAB, START, SELECT ou BOLA)
function input_fechar_menu()
{
    return keyboard_check_pressed(vk_escape) or keyboard_check_pressed(vk_tab)
        or (global.pad_slot >= 0 and (gamepad_button_check_pressed(global.pad_slot, gp_start)
            or gamepad_button_check_pressed(global.pad_slot, gp_select) or gamepad_button_check_pressed(global.pad_slot, gp_face2)));
}

// ENTER ou X (cruz do PlayStation / A do Xbox): fecha o pergaminho
function input_confirmar_pergaminho()
{
    return keyboard_check_pressed(vk_enter)
        or (global.pad_slot >= 0 and gamepad_button_check_pressed(global.pad_slot, gp_face1));
}

// ---------------------------------------------------------------------
// Navegação de menus: setas/WASD/D-pad/analógico com repetição ao segurar
// ---------------------------------------------------------------------
function input_nav_iniciar()
{
    global.nav_cima = false;  global.nav_baixo = false;
    global.nav_esq  = false;  global.nav_dir   = false;
    global.nav_ok   = false;  global.nav_voltar = false;
    global.nav_seg  = [0, 0, 0, 0];   // tempo segurando cada direção
}

function input_nav_atualizar(_pad, _ax, _ay, _hat = 0)
{
    var _p = (_pad >= 0);
    var _dirs = [
        keyboard_check(vk_up)    or keyboard_check(ord("W")) or (_p and (gamepad_button_check(_pad, gp_padu) or _ay < -0.55 or (_hat & 1) != 0)),
        keyboard_check(vk_down)  or keyboard_check(ord("S")) or (_p and (gamepad_button_check(_pad, gp_padd) or _ay >  0.55 or (_hat & 4) != 0)),
        keyboard_check(vk_left)  or keyboard_check(ord("A")) or (_p and (gamepad_button_check(_pad, gp_padl) or _ax < -0.55 or (_hat & 8) != 0)),
        keyboard_check(vk_right) or keyboard_check(ord("D")) or (_p and (gamepad_button_check(_pad, gp_padr) or _ax >  0.55 or (_hat & 2) != 0))
    ];
    var _res = [false, false, false, false];
    for (var _i = 0; _i < 4; _i++)
    {
        if (_dirs[_i])
        {
            var _antes = global.nav_seg[_i];
            global.nav_seg[_i] += global.dt_real;
            // aperto inicial, depois repete a cada 6 quadros após 24 quadros segurando
            if (_antes == 0) _res[_i] = true;
            else if (global.nav_seg[_i] >= 24 and floor((global.nav_seg[_i] - 24) / 6) != floor((_antes - 24) / 6)) _res[_i] = true;
        }
        else global.nav_seg[_i] = 0;
    }
    global.nav_cima  = _res[0];
    global.nav_baixo = _res[1];
    global.nav_esq   = _res[2];
    global.nav_dir   = _res[3];
    global.nav_ok = keyboard_check_pressed(vk_enter) or keyboard_check_pressed(vk_space)
        or (_p and gamepad_button_check_pressed(_pad, gp_face1));
    global.nav_voltar = keyboard_check_pressed(vk_escape)
        or (_p and (gamepad_button_check_pressed(_pad, gp_face2) or gamepad_button_check_pressed(_pad, gp_select)));
}

// ---------------------------------------------------------------------
// Nomes de teclas e botões (somente caracteres latinos, aceitos pela fonte)
// ---------------------------------------------------------------------
function nome_tecla(_k)
{
    switch (_k)
    {
        case vk_shift: case vk_lshift: case vk_rshift:       return "SHIFT";
        case vk_control: case vk_lcontrol: case vk_rcontrol: return "CTRL";
        case vk_alt: case vk_lalt: case vk_ralt:             return "ALT";
        case vk_space:     return "ESPAÇO";
        case vk_enter:     return "ENTER";
        case vk_escape:    return "ESC";
        case vk_tab:       return "TAB";
        case vk_backspace: return "BACKSPACE";
        case vk_up:        return "SETA CIMA";
        case vk_down:      return "SETA BAIXO";
        case vk_left:      return "SETA ESQ.";
        case vk_right:     return "SETA DIR.";
        case vk_insert:    return "INSERT";
        case vk_delete:    return "DELETE";
        case vk_home:      return "HOME";
        case vk_end:       return "END";
        case vk_pageup:    return "PAGE UP";
        case vk_pagedown:  return "PAGE DOWN";
        case vk_add:       return "NUM +";
        case vk_subtract:  return "NUM -";
        case vk_multiply:  return "NUM *";
        case vk_divide:    return "NUM /";
        case vk_decimal:   return "NUM ,";
        case 186: return "Ç";
        case 187: return "=";
        case 188: return ",";
        case 189: return "-";
        case 190: return ".";
        case 191: return ";";
        case 192: return "'";
        case 193: return "/";
        case 219: return "´";
        case 220: return "]";
        case 221: return "[";
        case 222: return "~";
        case 226: return "\\";
    }
    if (_k >= vk_numpad0 and _k <= vk_numpad9) return "NUM " + string(_k - vk_numpad0);
    if (_k >= vk_f1 and _k <= vk_f12) return "F" + string(_k - vk_f1 + 1);
    if ((_k >= ord("A") and _k <= ord("Z")) or (_k >= ord("0") and _k <= ord("9"))) return chr(_k);
    return "TECLA " + string(_k);
}

// Nome completo do botão (telas de remapeamento)
function nome_pad(_b)
{
    var _ps = (pad_estilo() == "ps");
    switch (_b)
    {
        case gp_face1:      return _ps ? "X (CRUZ)"  : "A";
        case gp_face2:      return _ps ? "BOLA"      : "B";
        case gp_face3:      return _ps ? "QUADRADO"  : "X";
        case gp_face4:      return _ps ? "TRIÂNGULO" : "Y";
        case gp_shoulderl:  return _ps ? "L1" : "LB";
        case gp_shoulderr:  return _ps ? "R1" : "RB";
        case gp_shoulderlb: return _ps ? "L2" : "LT";
        case gp_shoulderrb: return _ps ? "R2" : "RT";
        case gp_start:      return _ps ? "OPTIONS" : "START";
        case gp_select:     return _ps ? "SHARE / SELECT" : "BACK";
        case gp_stickl:     return "L3";
        case gp_stickr:     return "R3";
        case gp_padu:       return "D-PAD CIMA";
        case gp_padd:       return "D-PAD BAIXO";
        case gp_padl:       return "D-PAD ESQ.";
        case gp_padr:       return "D-PAD DIR.";
        case PAD_HAT_BASE + 1: return "DIRECIONAL CIMA";
        case PAD_HAT_BASE + 2: return "DIRECIONAL DIR.";
        case PAD_HAT_BASE + 4: return "DIRECIONAL BAIXO";
        case PAD_HAT_BASE + 8: return "DIRECIONAL ESQ.";
        case -1:               return "ANALÓGICO";
    }
    return "BOTÃO " + string(_b);
}

// Rótulo curto da ação para textos (tecla ou botão, conforme o que está em uso)
// Rótulos dos botões de menu (mudam sozinhos entre teclado e controle)
function usando_controle() { return global.usando_pad and global.pad_slot >= 0; }
function nome_confirmar()  { return usando_controle() ? ((pad_estilo() == "ps") ? "X" : "A") : "ENTER"; }
function nome_voltar()     { return usando_controle() ? ((pad_estilo() == "ps") ? "BOLA" : "B") : "ESC"; }
function nome_pausa()      { return usando_controle() ? ((pad_estilo() == "ps") ? "SELECT" : "BACK") : "ESC"; }
function nome_setas()      { return usando_controle() ? "D-pad / analógico" : "Setas"; }

function rotulo_acao(_acao)
{
    if (global.usando_pad and global.pad_slot >= 0)
    {
        var _b = global.botoes[_acao];
        if (_b < 0) return "[ANALÓGICO]";
        var _ps = (pad_estilo() == "ps");
        if (_b == gp_face1) return _ps ? "[X]" : "[A]";
        return "[" + nome_pad(_b) + "]";
    }
    return "[" + nome_tecla(global.teclas[_acao]) + "]";
}
