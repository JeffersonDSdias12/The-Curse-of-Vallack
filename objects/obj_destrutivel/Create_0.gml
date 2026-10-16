// =====================================================================
//  obj_destrutivel — pai do cenário que quebra com golpes
//  (caixotes e paredes rachadas). Os golpes do jogador procuram por ele
//  e chamam destrutivel_bater() (scr_cenario).
// =====================================================================
vida = 2;
vida_max = 2;
quebrado = false;
tremor = 0;
flash = 0;
lado_golpe = 1;
solido = noone;

// cada filho redefine
pode_bater = function() { return true; };
ao_bater = function(_forca) {};
ao_quebrar = function(_lado) { instance_destroy(); };
