var _dt = global.dt;
t += _dt;
var _p = instance_find(obj_player, 0);
switch (estado)
{
    case "esperando":
        // derruba quando Twilight chega perto (vindo de qualquer lado)
        if (_p != noone and !_p.morto and abs(_p.x - x) < dist_ativar and abs(_p.y - y) < 120)
        {
            estado = "aviso";
            t = 0;
            if (view_camera[0] != -1) y_viga = camera_get_view_y(view_camera[0]) - 30;
            som_em("fogo_whoosh", x, y, 0.7);
        }
    break;
    case "aviso":
        // poeira e brasas caindo do alto
        if (random(1) < 0.5 * _dt) fx_em("brasas", x + random_range(-30, 30), y_viga + 30, 0.6);
        if (random(1) < 0.3 * _dt) fx_em("poeira", x + random_range(-30, 30), y_viga + 40, 0.3);
        if (t >= 48) { estado = "caindo"; t = 0; vy = 2; }
    break;
    case "caindo":
        vy = min(vy + 0.55 * _dt, 16);
        y_viga += vy * _dt;
        ang = lerp(ang, 0, 0.05);
        if (y_viga >= y_chao - 7)
        {
            y_viga = y_chao - 7;
            estado = "queimando";
            t = 0;
            atingidos = [];
            armadilha_area(x - 40, y_chao - 60, x + 40, y_chao, 20, 45, atingidos, 6);
            som_em("dest_viga", x, y, 1);                 // a viga em chamas despenca
            som_em("fogo_explosao", x, y, 0.5);
            global.camera_impact = max(global.camera_impact, 10);
            fx_em("poeira", x, y_chao, 1.3);
            fx_em("faiscas_tela", x, y_chao, 0.5);
            fx_em("lascas", x, y_chao - 6, 0.8);
        }
    break;
    case "queimando":
        queima += _dt;
        // pisar no fogo queima (a cada 45 quadros)
        if (floor((queima - _dt) / 45) != floor(queima / 45)) atingidos = [];
        if (queima < 260) armadilha_area(x - 34, y_chao - 16, x + 34, y_chao, 6, 10, atingidos, 2);
        if (random(1) < 0.12 * _dt) fx_em("fumaca", x + random_range(-30, 30), y_chao - 10, 0.8);
        if (queima >= 360) { estado = "cinzas"; t = 0; }
    break;
}
