// =====================================================================
//  obj_nevoa_veneno — névoa venenosa (v1.12)
//  Uma coluna de veneno no caminho. Andando, Twilight é empurrado de volta
//  e se fere; ROLANDO ele atravessa. É assim que a fase ensina a esquiva.
//  Na sala: Escala X = largura (1 = 68 px). Ponha no chão.
// =====================================================================
larg = 34 * max(1, abs(image_xscale));
alt = 150;
t = 0;
dano = 3;
aviso_t = 0;
image_speed = 0;
depth = 90;
