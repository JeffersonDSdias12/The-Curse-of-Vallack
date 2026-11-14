if (!cenario_na_tela(x, x + 32 * colunas)) exit;
for (var _i = 0; _i < colunas; _i++) draw_sprite_ext(sprite_index, 0, x + 32 * _i, y, 1, 1, 0, tom, 1);
