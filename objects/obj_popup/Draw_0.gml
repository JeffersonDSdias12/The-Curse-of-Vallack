var _a = clamp(vida / 15, 0, 1);
var _s = escala * (1 + 0.35 * clamp((vida - 40) / 10, 0, 1));
gpu_set_texfilter(true);
txt_sombra(x, y, texto, FONTE.MEDIA, cor, _a, fa_center, fa_bottom, 0.5 * _s);
gpu_set_texfilter(false);
desenho_resetar();
