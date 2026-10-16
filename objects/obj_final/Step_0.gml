var _dt = global.dt_real;
tempo += _dt;

switch (fase)
{
    case "escurecer":
        // o último inimigo caiu: a tela escurece devagar
        if (tempo >= 150)
        {
            mundo_pausar();          // congela tudo (menos este objeto)
            fase = "continua";
            tempo = 0;
        }
    break;

    case "continua":
        if (tempo >= duracao_texto)
        {
            fase = "sair";
            tempo = 0;
        }
    break;

    case "sair":
        if (tempo >= 50)
        {
            var _l = instance_create_depth(0, 0, -11000, obj_loading);
            _l.modo = "menu";
            _l.destino = rm_menu;
            _l.fundo_preto = true;
            instance_destroy();
        }
    break;
}

// brasas vermelhas subindo
if (fase != "escurecer" and global.cfg_qualidade > 0 and array_length(brasas) < 50 and random(1) < 0.5 * _dt)
{
    array_push(brasas, { x: random(display_get_gui_width()), y: GUI_ALTURA + 6, vy: random_range(-1.4, -0.4), vida: irandom_range(80, 200), vmax: 200 });
}
for (var _i = array_length(brasas) - 1; _i >= 0; _i--)
{
    var _b = brasas[_i];
    _b.y += _b.vy * _dt;
    _b.vida -= _dt;
    if (_b.vida <= 0) array_delete(brasas, _i, 1);
}
