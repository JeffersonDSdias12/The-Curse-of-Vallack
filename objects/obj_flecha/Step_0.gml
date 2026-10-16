var _dt = global.dt;
switch (estado)
{
    case "voando":
        vy += 0.05 * _dt;
        x += vx * _dt;
        y += vy * _dt;
        dist += sqrt(vx * vx + vy * vy) * _dt;
        ang = point_direction(0, 0, vx, vy);
        var _px = x + lengthdir_x(12 * escala, ang);      // ponta
        var _py = y + lengthdir_y(12 * escala, ang);
        var _p = instance_find(obj_player, 0);
        var _intang = false;
        if (_p != noone) with (_p) _intang = jogador_intangivel();
        if (_p != noone and !_p.morto and !_intang and point_in_rectangle(_px, _py, _p.bbox_left, _p.bbox_top, _p.bbox_right, _p.bbox_bottom))
        {
            if (_p.janela_aparar > 0 and sign(x - _p.x) == _p.facing)
            {
                // APARADA: a flecha volta contra quem atirou
                jogador_aparou(noone);
                estado = "refletida";
                vx = -vx * 1.2;
                vy = -vy * 0.3 - 0.4;
                dist = 0;
                alcance = 700;
                exit;
            }
            if (_p.bloqueando and sign(x - _p.x) == _p.facing)
            {
                // a defesa mágica rebate a flecha
                jogador_bloqueou(x);
                estado = "ricochete";
                vx = -vx * 0.35;
                vy = -3.2;
                giro = 20 * sign(vx == 0 ? 1 : vx);
                vida = 50; vida_max = 50;
            }
            else
            {
                with (_p) levar_dano(other.dano, other.x, true, 2);
                instance_destroy();
                exit;
            }
        }
        else if (position_meeting(_px, _py, obj_chao))
        {
            estado = "cravada";
            vida = 120; vida_max = 120;
        }
        else if (dist >= alcance or y > room_height + 50)
        {
            estado = "caindo";
            vida = 30; vida_max = 30;
        }
    break;

    case "refletida":
        // flecha de Twilight: fere os inimigos
        vy += 0.02 * _dt;
        x += vx * _dt;
        y += vy * _dt;
        dist += sqrt(vx * vx + vy * vy) * _dt;
        ang = point_direction(0, 0, vx, vy);
        var _rx = x + lengthdir_x(12 * escala, ang);
        var _ry = y + lengthdir_y(12 * escala, ang);
        var _e = collision_point(_rx, _ry, obj_inimigo_base, false, true);
        if (_e != noone and !_e.morrendo and _e.ativo)
        {
            var _gw = { chave: "flecha", especial: false, pesado: true, porcento: 0, dano: 0, combo: 0 };
            var _dn = _e.eh_boss ? max(1, round(_e.vida_max * 0.02)) : max(1, round(_e.vida_max * 0.6));
            with (_e)
            {
                levar_dano(_dn, other.x - other.vx, false, 5, noone, _gw);
                if (!morrendo) inimigo_atordoar(80, true);
            }
            fx_em("faiscas_golpe", _rx, _ry, 1, sign(vx));
            som_em("hit_2", x, y, 0.9);
            instance_destroy();
            exit;
        }
        if (position_meeting(_rx, _ry, obj_chao)) { estado = "cravada"; vida = 120; vida_max = 120; }
        else if (dist >= alcance) { estado = "caindo"; vida = 30; vida_max = 30; }
    break;

    case "ricochete":
        vy += 0.3 * _dt;
        x += vx * _dt;
        y += vy * _dt;
        ang += giro * _dt;
        if (position_meeting(x, y, obj_chao)) { vx *= 0.5; vy = 0; giro *= 0.5; }
        vida -= _dt;
        if (vida <= 0) instance_destroy();
    break;

    case "cravada":
        vida -= _dt;
        if (vida <= 0) instance_destroy();
    break;

    case "caindo":
        vy += 0.25 * _dt;
        x += vx * 0.5 * _dt;
        y += vy * _dt;
        vida -= _dt;
        if (vida <= 0) instance_destroy();
    break;
}
