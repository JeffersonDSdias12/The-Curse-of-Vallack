// ===== ROOM START (a sala de destino acabou de ser criada) =====
// Congela a fase nova enquanto o título e o carregamento aparecem, senão os
// inimigos se mexeriam (e atacariam) escondidos atrás da tela preta.
// v1.9: o congelamento acontece no primeiro Step (não aqui). No Room Start a
// ordem entre os objetos não é garantida: se este evento rodasse antes do
// obj_sistema, a sala seria preparada (chuva, vila, checkpoint) com o chão e
// os inimigos já desativados — era por isso que a chuva caía só até a metade
// da tela (ou nem aparecia) no NOVO JOGO.
if (fase == "capitulo" or fase == "carregando")
{
    if (modo != "menu") congelou = false;      // o Step congela a sala no próximo quadro
}
