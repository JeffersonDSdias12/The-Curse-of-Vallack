var _s = 1 / escala_hd;
var _cx1 = 0;
var _cx2 = room_width;
if (view_camera[0] != -1)
{
    _cx1 = camera_get_view_x(view_camera[0]);
    _cx2 = _cx1 + camera_get_view_width(view_camera[0]);
}
var _h = sprite_get_height(spr_fundo_hd);
gpu_set_texfilter(true);
for (var _i = 0; _i < sprite_get_number(spr_fundo_hd); _i++)
{
    var _wx = _i * larg_q * _s;
    var _ww = larg_q * _s;
    if (_wx > _cx2 or _wx + _ww < _cx1) continue;     // só os pedaços que aparecem
    draw_sprite_part_ext(spr_fundo_hd, _i, margem, 0, larg_q, _h, _wx, y0, _s, _s, c_white, 1);
}
gpu_set_texfilter(false);
