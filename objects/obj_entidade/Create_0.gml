velh = 0;    // velocidade horizontal (pixels por quadro de 60 FPS)
velv = 0;    // velocidade vertical
vel  = 3;    // velocidade base
grav = 0.25; // gravidade (acumula a cada quadro)
// v1.14: velocidade de ANDAR (velh_para): acelera, freia e, para virar de lado,
// passa pelo zero; o empurrão e a separação somam por cima sem acumular
anda_v = 0;
anda_vivo = false;       // velh_para foi chamado neste quadro
anda_vivo_ant = false;   // ... e no quadro anterior (senão parte do zero)
