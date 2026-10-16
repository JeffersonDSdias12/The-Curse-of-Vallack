// Desenha ATRÁS da arte do salão (profundidade 450; tiles "fundo" = 400)
if (view_camera[0] == -1) exit;
var _cam = view_camera[0];
var _vx = camera_get_view_x(_cam);
var _vy = camera_get_view_y(_cam);
var _vw = camera_get_view_width(_cam);
var _vh = camera_get_view_height(_cam);
var _x1 = _vx - 4;
var _x2 = _vx + _vw + 4;
var _y2 = _vy + _vh + 4;

// 1) base escura em toda a visão
draw_set_alpha(1);
draw_set_color(make_color_rgb(10, 6, 8));
draw_rectangle(_x1, _vy - 4, _x2, _y2, false);

// 2) salão distante: a mesma arte ampliada e escurecida, com paralaxe
var _esc  = 1.7;
var _sw   = sprite_get_width(spr_fundo_fase2) * _esc;
var _base = banda_topo + 150;          // a parte de baixo fica escondida atrás da arte principal
var _off  = _vx * 0.6;                 // anda mais devagar que a câmera (profundidade)
var _k0   = floor((_x1 - _off) / _sw) - 1;
var _k1   = ceil((_x2 - _off) / _sw) + 1;
for (var _k = _k0; _k <= _k1; _k++)
{
    // origem do sprite = centro da base
    draw_sprite_ext(spr_fundo_fase2, 0, _off + _k * _sw, _base, _esc, _esc, 0, make_color_rgb(92, 66, 70), 1);
}

// 3) escuridão do teto (degradê)
retangulo_gradiente(_x1, _vy - 4, _x2, banda_topo, make_color_rgb(6, 3, 5), 0.88, make_color_rgb(30, 12, 14), 0.35);

// 4) piso de pedra abaixo da arte (antes era azul)
var _cor_piso = make_color_rgb(150, 112, 118);
var _src_y = 590;
var _src_h = 86;
var _src_w = sprite_get_width(spr_fundo);
var _pe    = 0.65;
var _tw    = _src_w * _pe;
var _j0 = floor(_x1 / _tw);
var _j1 = ceil(_x2 / _tw);
draw_set_color(make_color_rgb(14, 10, 12));
draw_rectangle(_x1, chao_y, _x2, _y2, false);
for (var _j = _j0; _j <= _j1; _j++)
{
    draw_sprite_part_ext(spr_fundo, 0, 0, _src_y, _src_w, _src_h, _j * _tw, chao_y, _pe, _pe, _cor_piso, 1);
}
retangulo_gradiente(_x1, chao_y + 6, _x2, _y2, c_black, 0, c_black, 0.75);

desenho_resetar();
