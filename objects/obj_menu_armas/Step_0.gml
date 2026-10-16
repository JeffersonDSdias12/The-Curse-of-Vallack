var _dt = global.dt_real;
tempo += _dt;
if (evoluiu_fx > 0) evoluiu_fx -= _dt;
if (negado_fx > 0) negado_fx -= _dt;
orbs_vis = lerp(orbs_vis, global.orbs, 0.15);
if (abs(orbs_vis - global.orbs) < 0.5) orbs_vis = global.orbs;

for (var _i = array_length(faiscas) - 1; _i >= 0; _i--)
{
    var _f = faiscas[_i];
    _f.x += _f.vx * _dt; _f.y += _f.vy * _dt; _f.vy += 0.15 * _dt; _f.vida -= _dt;
    if (_f.vida <= 0) array_delete(faiscas, _i, 1);
}
for (var _j = array_length(fluxo) - 1; _j >= 0; _j--)
{
    var _o = fluxo[_j];
    _o.t += _dt / 26;
    if (_o.t >= 1) array_delete(fluxo, _j, 1);
}

if (fechando)
{
    fechar_t += _dt;
    abre = max(0, 1 - fechar_t / 14);
    if (fechar_t >= 14) finalizar();
    exit;
}
abre = min(1, abre + _dt / 16);
if (tempo < 10) exit;

if (input_fechar_menu()) { fechar(); exit; }

// SEGURAR para evoluir (ENTER / ESPAÇO / X / clique)
var _prox = global.espada_nivel + 1;
var _pode = (_prox <= ESPADA_NIVEL_MAX) and (global.orbs >= espada_custo(_prox));
var _segurando = keyboard_check(vk_enter) or keyboard_check(vk_space) or mouse_check_button(mb_left)
    or (global.pad_slot >= 0 and gamepad_button_check(global.pad_slot, gp_face1));
var _apertou = keyboard_check_pressed(vk_enter) or keyboard_check_pressed(vk_space) or mouse_check_button_pressed(mb_left)
    or (global.pad_slot >= 0 and gamepad_button_check_pressed(global.pad_slot, gp_face1));
if (_segurando and _pode)
{
    segurar = min(1, segurar + _dt / 70);
    // orbs saindo do pote rumo à espada
    if (random(1) < 0.7 * _dt) array_push(fluxo, { t: 0, ox: random_range(-12, 12), oy: random_range(-8, 8) });
    if (floor(tempo) mod 6 == 0) som("sfx_orb", 0.25, 0.2);
    if (segurar >= 1)
    {
        segurar = 0;
        evoluir();
    }
}
else
{
    segurar = max(0, segurar - _dt / 20);
    if (_apertou and !_pode)
    {
        negado_fx = 30;
        som("sfx_negado", 0.7, 0);
    }
}
