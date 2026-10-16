// DRAW END: por cima da arte do salão, só na parte alta (não cobre personagens)
if (view_camera[0] == -1) exit;
var _cam = view_camera[0];
var _vx = camera_get_view_x(_cam);
var _vw = camera_get_view_width(_cam);
var _x1 = _vx - 4;
var _x2 = _vx + _vw + 4;

// suaviza a emenda entre o salão distante e a arte principal
retangulo_gradiente(_x1, banda_topo - 2, _x2, banda_topo + 34, make_color_rgb(10, 4, 6), 0.7, make_color_rgb(10, 4, 6), 0);

// brasas
gpu_set_blendmode(bm_add);
for (var _i = 0; _i < array_length(brasas); _i++)
{
    var _b = brasas[_i];
    var _a = clamp(_b.vida / _b.vmax, 0, 1) * 0.8;
    draw_set_alpha(_a);
    draw_set_color(make_color_rgb(255, 120, 40));
    draw_circle(_b.x, _b.y, 1.4, false);
    draw_set_alpha(_a * 0.3);
    draw_circle(_b.x, _b.y, 3.5, false);
}
gpu_set_blendmode(bm_normal);
desenho_resetar();
