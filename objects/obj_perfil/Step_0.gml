// ===== PERFIL, CONQUISTAS E RECOMPENSAS — Step =====
var _dt = global.dt_real;
t += _dt;
entrada = min(1, entrada + _dt / 18);
if (mensagem_t > 0) mensagem_t -= _dt;
if (!iniciado)
{
    iniciado = true;
    if (modo == "primeiro") abrir_nome();
}
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _clique = mouse_check_button_pressed(mb_left);
var _ok = global.nav_ok;
var _voltar = global.nav_voltar;

// ===================== NOME (teclado na tela + teclado de verdade) =====================
if (estado == "nome")
{
    var _digitou = false;
    if (keyboard_string != "")
    {
        var _ks = string_upper(keyboard_string);
        keyboard_string = "";
        for (var _c = 1; _c <= string_length(_ks); _c++)
        {
            var _ch = string_char_at(_ks, _c);
            var _valido = (_ch == " ") or (ord(_ch) >= ord("A") and ord(_ch) <= ord("Z")) or (ord(_ch) >= ord("0") and ord(_ch) <= ord("9")) or string_pos(_ch, "ÇÃÉÍÁÓÚÂÊÔÕ") > 0;
            if (_valido and string_length(nome_edit) < PERFIL_NOME_MAX) nome_edit += _ch;
            _digitou = true;
        }
    }
    if (keyboard_check_pressed(vk_backspace)) { nome_edit = string_copy(nome_edit, 1, max(0, string_length(nome_edit) - 1)); _digitou = true; }
    if (keyboard_check_pressed(vk_enter)) { nome_salvar(); exit; }
    if (_voltar)
    {
        som("tit_voltar", 0.8, 0.02);
        if (modo == "primeiro") { with (obj_menu) mudar_estado("menu", 0, false); transicao_revelar(24); instance_destroy(); exit; }
        estado = "abas";
        exit;
    }
    // setas / controle andam pelo teclado da tela
    var _antes = tecla_sel;
    if (global.nav_esq) tecla_sel = (tecla_sel >= 40) ? max(40, tecla_sel - 1) : (tecla_sel div 10) * 10 + ((tecla_sel mod 10) + 9) mod 10;
    if (global.nav_dir) tecla_sel = (tecla_sel >= 40) ? min(42, tecla_sel + 1) : (tecla_sel div 10) * 10 + ((tecla_sel mod 10) + 1) mod 10;
    if (global.nav_cima) tecla_sel = (tecla_sel >= 40) ? 30 + (tecla_sel - 40) * 4 : max(0, tecla_sel - 10);
    if (global.nav_baixo) tecla_sel = (tecla_sel >= 30 and tecla_sel < 40) ? 40 + min(2, (tecla_sel - 30) div 4) : ((tecla_sel < 40) ? tecla_sel + 10 : tecla_sel);
    if (tecla_sel != _antes) som("tit_mover", 0.5, 0.03);
    if (_ok and !_digitou and !keyboard_check_pressed(vk_space)) tecla_apertar(tecla_sel);
    if (_clique)
    {
        for (var _i = 0; _i < array_length(teclas); _i++)
        {
            var _tp = tecla_pos(_i);
            if (point_in_rectangle(_mx, _my, _tp[0], _tp[1], _tp[0] + _tp[2], _tp[1] + _tp[3])) { tecla_sel = _i; tecla_apertar(_i); break; }
        }
    }
    exit;
}

// ===================== ABAS =====================
if (_voltar and entrada >= 1)
{
    som("tit_voltar", 0.8, 0.02);
    perfil_salvar();
    with (obj_menu) mudar_estado("menu", 2, false);
    transicao_revelar(24);     // v1.19: o menu volta atrás da cortina
    instance_destroy();
    exit;
}
// abas: ◄ ► ou clique; dentro da aba, ▲ ▼ escolhem
var _aba_antes = aba;
if (global.nav_esq) aba = (aba + 2) mod 3;
else if (global.nav_dir) aba = (aba + 1) mod 3;
for (var _a = 0; _a < 3; _a++)
{
    var _tx = _gw / 2 + (_a - 1) * 250;
    if (_clique and point_in_rectangle(_mx, _my, _tx - 115, 128, _tx + 115, 170)) aba = _a;
}
if (aba != _aba_antes) { sel = 0; rolagem_alvo = 0; som("tit_mover", 0.6, 0.03); }

switch (aba)
{
    case 0:     // CONQUISTAS: ▲ ▼ andam pela lista (a rolagem acompanha)
        var _n = array_length(lista);
        if (global.nav_cima) sel = max(0, sel - 1);
        if (global.nav_baixo) sel = min(_n - 1, sel + 1);
        // rodinha / arrastar
        if (mouse_wheel_up()) rolagem_alvo -= 120;
        if (mouse_wheel_down()) rolagem_alvo += 120;
        if (_clique and _my > 186 and _my < _gh - 60) { arrastando = true; arraste_y0 = _my; arraste_rol0 = rolagem; arraste_dist = 0; }
        if (arrastando)
        {
            if (mouse_check_button(mb_left)) { rolagem_alvo = arraste_rol0 - (_my - arraste_y0); rolagem = rolagem_alvo; arraste_dist = max(arraste_dist, abs(_my - arraste_y0)); }
            else arrastando = false;
        }
        var _linhas = ceil(_n / 2);
        var _max_rol = max(0, _linhas * 82 - (_gh - 60 - 196));
        if (global.nav_cima or global.nav_baixo)
        {
            var _cy = 196 + (sel div 2) * 82;
            rolagem_alvo = clamp(_cy - (_gh / 2 - 40), 0, _max_rol);
        }
        rolagem_alvo = clamp(rolagem_alvo, 0, _max_rol);
        if (!arrastando) rolagem = lerp(rolagem, rolagem_alvo, 1 - power(0.8, _dt));
    break;

    case 1:     // LÂMINAS: escolher o estilo do efeito da espada
        var _ne = array_length(estilos);
        if (global.nav_cima) sel = (sel + _ne - 1) mod _ne;
        if (global.nav_baixo) sel = (sel + 1) mod _ne;
        if (global.nav_cima or global.nav_baixo) som("tit_mover", 0.5, 0.03);
        var _escolher = _ok;
        for (var _i = 0; _i < _ne; _i++)
        {
            var _lp = lamina_pos(_i);
            if (_clique and point_in_rectangle(_mx, _my, _lp[0], _lp[1], _lp[0] + _lp[2], _lp[1] + _lp[3])) { sel = _i; _escolher = true; }
        }
        if (_escolher)
        {
            var _es = estilos[sel];
            if (espada_estilo_liberado(_es.id))
            {
                global.perfil.espada_fx = _es.id;
                perfil_salvar();
                som("espada_evoluir", 0.5, 0);
                som("tit_selecao", 0.8, 0.02);
                mensagem = "LÂMINA EQUIPADA: " + _es.nome;
                mensagem_t = 110;
            }
            else { som("tit_negado", 0.7, 0); mensagem = "Ganhe esta lâmina numa conquista"; mensagem_t = 110; }
        }
    break;

    case 2:     // PERFIL: ALTERAR NOME e o título
        if (global.nav_cima or global.nav_baixo) { sel = 1 - sel; som("tit_mover", 0.6, 0.03); }
        var _bn = [_gw / 2 - 160, 214, _gw / 2 + 160, 262];
        var _bt = [_gw / 2 - 260, 300, _gw / 2 + 260, 348];
        if (_clique and point_in_rectangle(_mx, _my, _bn[0], _bn[1], _bn[2], _bn[3])) { sel = 0; _ok = true; }
        var _mudar_titulo = 0;
        if (_clique and point_in_rectangle(_mx, _my, _bt[0], _bt[1], _bt[2], _bt[3])) { sel = 1; _mudar_titulo = 1; }
        if (_ok and sel == 0) { som("tit_selecao", 0.8, 0.02); abrir_nome(); }
        if (sel == 1 and _ok) _mudar_titulo = 1;
        if (_mudar_titulo != 0)
        {
            var _tl = titulos_liberados();
            if (array_length(_tl) == 0) { som("tit_negado", 0.7, 0); mensagem = "Ganhe títulos nas conquistas"; mensagem_t = 110; }
            else
            {
                var _idx = array_get_index(_tl, global.perfil.titulo);
                global.perfil.titulo = _tl[(_idx + 1) mod array_length(_tl)];
                perfil_salvar();
                som("tit_alterar", 0.7, 0.03);
            }
        }
    break;
}
