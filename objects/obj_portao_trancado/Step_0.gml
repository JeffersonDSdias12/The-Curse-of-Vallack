var _dt = global.dt;
t += _dt;
var _p = instance_find(obj_player, 0);
if (estado == "trancado" and _p != noone and !_p.morto)
{
    if (abs(_p.x - x) < 70 and _p.y > y - 220)
    {
        global.portao_visto = true;
        if (global.chave_portao)
        {
            estado = "abrindo";
            aberto_marcar(chave);
            aviso_mostrar("O PORTÃO SE ABRIU");
            conquista("chave");          // v1.17
            som_em("sfx_portal", x, y - 40, 1, 0);
            global.camera_impact = max(global.camera_impact, 6);
        }
        else if (!aviso_dado)
        {
            aviso_dado = true;
            aviso_mostrar("PORTÃO TRANCADO  ·  ACHE A CHAVE DO PORTÃO");     // com o som da mensagem importante
        }
    }
    else if (abs(_p.x - x) > 180) aviso_dado = false;
}
if (estado == "abrindo")
{
    sobe = min(1, sobe + 0.016 * _dt);
    if (random(1) < 0.4 * _dt) fx_em("pedras", x + random_range(-16, 16), y - 4, 0.4);
    if (sobe >= 1)
    {
        estado = "aberto";
        solido_remover(solido);
        solido = solido_criar(x - 14, y_topo, x + 14, y - 112);
    }
}