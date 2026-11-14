// =====================================================================
//  obj_placa — placa de madeira com aviso (v1.11)
//  Quando Twilight chega perto, o aviso aparece num pergaminho acima da
//  placa. O texto fica na lista placa_texto() (scr_cenario): cada placa
//  usa o aviso do ponto mais perto dela.
// =====================================================================
image_speed = 0;
depth = 140;
texto = placa_texto(x);
mostrar = 0;
aviso_base = y - 66;      // v1.14: o aviso sobe para não cobrir a cabeça de Twilight
