// libera a "foto" do jogo (antes ficava na memória a cada pausa)
if (foto != -1 and sprite_exists(foto)) sprite_delete(foto);
foto = -1;
