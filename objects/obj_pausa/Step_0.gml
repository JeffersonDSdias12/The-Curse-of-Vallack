var _dt = global.dt_real;
tempo += _dt;
var _gw = display_get_gui_width();
var _cx = _gw / 2;
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _clicou = mouse_check_button_pressed(mb_left);
var _mexeu = (mouse_antes_x != -1) and (_mx != mouse_antes_x or _my != mouse_antes_y);
mouse_antes_x = _mx;
mouse_antes_y = _my;
var _total = array_length(opcoes);

// brasas no rastro do mouse (clicar solta uma explosão)
repeat (_clicou ? 12 : (_mexeu ? 2 : 0))
{
    array_push(faiscas, { x: _mx + random_range(-5, 5), y: _my + random_range(-5, 5),
        vx: random_range(-0.8, 0.8), vy: random_range(-2.2, -0.6), vida: irandom_range(30, 70), vmax: 70 });
}
for (var _i = array_length(faiscas) - 1; _i >= 0; _i--)
{
    var _f = faiscas[_i];
    _f.x += _f.vx * _dt;
    _f.y += _f.vy * _dt;
    _f.vida -= _dt;
    if (_f.vida <= 0) array_delete(faiscas, _i, 1);
}

// ----- ANIMAÇÃO DE ABRIR / FECHAR -----
if (fechando)
{
    fechar_t += _dt;
    abre = max(0, 1 - fechar_t / 12);
    if (fechar_t >= 12)
    {
        switch (acao_ao_fechar)
        {
            case "continuar": continuar(); break;
            case "reiniciar":
                progresso_reverter();
                mundo_retomar();
                io_clear();
                room_restart();
                instance_destroy();
            break;
            case "menu":
                var _l = instance_create_depth(0, 0, -11000, obj_loading);
                _l.modo = "menu";
                _l.destino = rm_menu;
                instance_destroy();
            break;
            case "sair": game_end(); break;
        }
    }
    exit;
}
abre = min(1, abre + _dt / 14);

// ESC / SELECT / BOLA continuam o jogo (espera alguns quadros para não fechar ao abrir)
if (tempo > 8 and (input_pausa_apertada() or (global.pad_slot >= 0 and gamepad_button_check_pressed(global.pad_slot, gp_face2))))
{
    fechar_com("continuar");
    exit;
}

var _sel_antes = selecionado;
if (global.nav_cima)  { selecionado = (selecionado + _total - 1) mod _total; confirmar = -1; }
if (global.nav_baixo) { selecionado = (selecionado + 1) mod _total; confirmar = -1; }
var _confirmou = global.nav_ok;
var _passo = global.nav_dir - global.nav_esq;

for (var _o = 0; _o < _total; _o++)
{
    var _oy = opcao_y(_o);
    if (point_in_rectangle(_mx, _my, _cx - 250, _oy - 24, _cx + 250, _oy + 24))
    {
        if (_mexeu and selecionado != _o) { selecionado = _o; confirmar = -1; }
        if (_clicou)
        {
            selecionado = _o;
            if (_o == PAUSA_MUSICA or _o == PAUSA_EFEITOS)
            {
                // clique na barra: ajusta direto pela posição do mouse
                var _bx1 = _cx + 20;
                var _bx2 = _cx + 200;
                if (_mx >= _bx1 - 10)
                {
                    var _v = clamp(round((_mx - _bx1) / (_bx2 - _bx1) * 10) / 10, 0, 1);
                    if (_o == PAUSA_MUSICA) global.cfg_vol_musica = _v;
                    else { global.cfg_vol_efeitos = _v; som("atk_corte_1", 0.9); }
                    mudou_config = true;
                }
                else _passo = 1;
            }
            else _confirmou = true;
        }
    }
}
if (selecionado != _sel_antes) som("sfx_menu_mover", 0.5, 0);

// volumes: « » alteram
if ((selecionado == PAUSA_MUSICA or selecionado == PAUSA_EFEITOS) and _passo != 0) mudar_volume(selecionado, _passo);

if (_confirmou and tempo > 8 and selecionado != PAUSA_MUSICA and selecionado != PAUSA_EFEITOS)
{
    // opções que perdem o progresso não salvo pedem confirmação
    if (selecionado >= 4 and confirmar != selecionado)
    {
        confirmar = selecionado;
        som("sfx_menu_mover", 0.7, 0);
    }
    else
    {
        som("sfx_menu_ok", 0.7, 0);
        switch (selecionado)
        {
            case 0: fechar_com("continuar"); exit;

            case 3:   // COMANDOS E COMBOS: o livro de pergaminhos do tutorial
                if (mudou_config) { config_salvar(); mudou_config = false; }
                var _g = instance_create_depth(0, 0, -10500, obj_pergaminho);
                _g.paginas = tutorial_todas();
                _g.modo_livro = true;
                _g.veio_da_pausa = true;
                _g.foto_externa = foto;
                exit;

            case 4: fechar_com("reiniciar"); exit;   // volta ao último checkpoint / save
            case 5: fechar_com("menu"); exit;
            case 6: fechar_com("sair"); exit;
        }
    }
}

for (var _a = 0; _a < _total; _a++) anim[_a] = lerp_dt(anim[_a], (_a == selecionado) ? 1 : 0, 0.2);
