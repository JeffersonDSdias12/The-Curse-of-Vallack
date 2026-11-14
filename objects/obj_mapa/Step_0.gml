// ===== O MAPA DE VALLACK — Step =====
var _dt = global.dt_real;
t += _dt;
entrada = min(1, entrada + _dt / 24);
if (aviso_t > 0) aviso_t -= _dt;
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

// brasas subindo do caminho (só perto da tela)
var _max_b = (global.cfg_qualidade == 0) ? 20 : (global.cfg_qualidade == 1 ? 45 : 80);
if (array_length(brasas) < _max_b and random(1) < 0.6 * _dt)
{
    var _cp = caminho[irandom(array_length(caminho) - 1)];
    if (_cp[0] > cam_x - 40 and _cp[0] < cam_x + _gw + 40)
        array_push(brasas, { x: _cp[0] + random_range(-10, 10), y: _cp[1], vx: random_range(-0.4, 0.4), vy: random_range(-1.6, -0.5), v: random_range(50, 110), r: random_range(1, 2.4) });
}
for (var _b = array_length(brasas) - 1; _b >= 0; _b--)
{
    var _br = brasas[_b];
    _br.x += (_br.vx + sin((t + _b * 13) / 20) * 0.3) * _dt;
    _br.y += _br.vy * _dt;
    _br.v -= _dt;
    if (_br.v <= 0) array_delete(brasas, _b, 1);
}

// ----- saindo: escurece e começa a fase (o menu cuida do slot e da cutscene) -----
if (saindo >= 0)
{
    saindo += _dt;
    if (saindo >= 30)
    {
        var _m = instance_find(obj_menu, 0);
        instance_destroy();
        if (_m != noone) with (_m) comecar_pelo_mapa();
    }
    exit;
}

// ----- entradas -----
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _apertou = mouse_check_button_pressed(mb_left);
var _segura = mouse_check_button(mb_left);
var _soltou = mouse_check_button_released(mb_left);
var _ok = global.nav_ok;
var _voltar = global.nav_voltar;
var _sel_antes = sel;
var _dif_antes = dif;
if (global.nav_esq) sel = max(0, sel - 1);
if (global.nav_dir) sel = min(n - 1, sel + 1);
if (global.nav_cima) dif = (dif + DIF.TOTAL - 1) mod DIF.TOTAL;
if (global.nav_baixo) dif = (dif + 1) mod DIF.TOTAL;
if (mouse_wheel_up()) cam_alvo -= GAP * 0.8;
if (mouse_wheel_down()) cam_alvo += GAP * 0.8;

// botões do painel de baixo (dificuldade e JOGAR), em coordenadas da tela
var _py = _gh - 196;
var _bj = [_gw - 300, _py + 118, _gw - 50, _py + 172];         // JOGAR
var _bd1 = [_gw - 470, _py + 40, _gw - 420, _py + 90];          // « dificuldade
var _bd2 = [_gw - 100, _py + 40, _gw - 50, _py + 90];           // dificuldade »
var _bv = [24, 22, 170, 66];                                    // VOLTAR
var _no_painel = (_my >= _py);

// arrastar o mapa (mouse / dedo); um toque sem arrastar escolhe a fase
if (_apertou and !_no_painel and !point_in_rectangle(_mx, _my, _bv[0], _bv[1], _bv[2], _bv[3]))
{
    arrastando = true;
    arraste_x0 = _mx;
    arraste_cam0 = cam_x;
    arraste_dist = 0;
    arraste_vel = 0;
    mouse_ant_x = _mx;
    toque_no = -1;
    for (var _i = 0; _i < n; _i++)
    {
        var _nx = no_x(_i) - cam_x;
        var _ny = no_y(_i);
        if (abs(_mx - _nx) < FOTO_W / 2 + 10 and _my > _ny - FOTO_H / 2 - 30 and _my < _ny + 120) toque_no = _i;
    }
}
if (arrastando)
{
    if (_segura)
    {
        cam_x = arraste_cam0 - (_mx - arraste_x0);
        arraste_dist = max(arraste_dist, abs(_mx - arraste_x0));
        arraste_vel = lerp(arraste_vel, -(_mx - mouse_ant_x), 0.5);
        cam_alvo = cam_x;
    }
    else
    {
        arrastando = false;
        if (arraste_dist < 12 and toque_no != -1)
        {
            // toque: escolhe a fase; tocar de novo na fase aberta já escolhida = jogar
            if (toque_no == sel and fase_mapa_livre(sel)) jogar();
            else sel = toque_no;
        }
        else cam_alvo = cam_x + arraste_vel * 14;      // inércia
    }
    mouse_ant_x = _mx;
}
if (_apertou and _no_painel)
{
    if (point_in_rectangle(_mx, _my, _bj[0], _bj[1], _bj[2], _bj[3])) _ok = true;
    if (point_in_rectangle(_mx, _my, _bd1[0], _bd1[1], _bd1[2], _bd1[3])) dif = (dif + DIF.TOTAL - 1) mod DIF.TOTAL;
    if (point_in_rectangle(_mx, _my, _bd2[0], _bd2[1], _bd2[2], _bd2[3])) dif = (dif + 1) mod DIF.TOTAL;
}
if (_apertou and point_in_rectangle(_mx, _my, _bv[0], _bv[1], _bv[2], _bv[3])) _voltar = true;

if (sel != _sel_antes)
{
    som("tit_mover", 0.6, 0.03);
    cam_alvo = no_x(sel) - _gw / 2;
}
if (dif != _dif_antes) som("tit_alterar", 0.7, 0.03);

if (_voltar and entrada >= 1)
{
    som("tit_voltar", 0.8, 0.02);
    with (obj_menu) { mudar_estado("menu", 0, false); }
    transicao_revelar(24);     // v1.19: o menu volta atrás da cortina
    instance_destroy();
    exit;
}
if (_ok and entrada >= 1 and !arrastando) jogar();

// a câmera desliza até o alvo (sem passar das pontas)
var _max_cam = max(0, mundo_w - _gw);
cam_alvo = clamp(cam_alvo, 0, _max_cam);
if (!arrastando) cam_x = lerp(cam_x, cam_alvo, 1 - power(0.86, _dt));
cam_x = clamp(cam_x, -60, _max_cam + 60);
