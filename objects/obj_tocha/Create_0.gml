// =====================================================================
//  obj_tocha — tocha de parede (v1.11)
//  Começa apagada (só uma brasa) e ACENDE quando Twilight chega perto:
//  "fuuum", faíscas e brasas subindo. Acesa, ilumina a parede em volta
//  e entra no som do fogo da fase (obj_vila). A posição é a boca da tocha.
// =====================================================================
image_speed = 0;
depth = 240;
acesa = false;
luz = 0;                // 0 apagada .. 1 acesa
brasa_t = 0;
semente = random(100);
