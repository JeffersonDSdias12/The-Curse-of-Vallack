var _dt = global.dt_real;
tempo += _dt;
var _n = array_length(imagens);
var _passar = global.nav_ok or keyboard_check_pressed(ord("X")) or mouse_check_button_pressed(mb_left);
var _pular = global.nav_voltar;

switch (fase)
{
    // a tela preta clareia na primeira imagem
    case "entrando":
        if (tempo >= 50) { fase = "mostrando"; tempo = 0; }
    break;

    // espera o jogador apertar X / ENTER (um instante antes, para não passar sem querer)
    case "mostrando":
        if (_pular and tempo > 10) { fase = "saindo"; tempo = 0; som("cut_passar", 0.7, 0); break; }
        if (_passar and tempo > 20)
        {
            som("cut_passar", 0.8, 0.03);
            if (indice < _n - 1) { fase = "trocando"; troca = 0; tempo = 0; }
            else { fase = "saindo"; tempo = 0; }
        }
    break;

    // a próxima imagem aparece por cima da atual
    case "trocando":
        troca += _dt / 26;
        if (troca >= 1) { troca = 0; indice += 1; fase = "mostrando"; tempo = 0; }
    break;

    // escurece e começa o carregamento da fase 1
    case "saindo":
        if (tempo >= 45) { fase = "fim"; tempo = 0; }
    break;

    case "fim":
        if (!carregamento_criado)
        {
            carregamento_criado = true;
            var _l = instance_create_depth(0, 0, -10000, obj_loading);
            _l.modo = "novo_jogo";
            _l.destino = Room1;
        }
    break;
}
