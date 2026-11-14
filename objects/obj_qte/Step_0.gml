// ===== SEQUÊNCIA DE GOLPES — Step (em tempo real: a câmera lenta não atrasa o botão) =====
var _dt = global.dt_real;
t += _dt;
if (acerto_fx > 0) acerto_fx -= _dt;
var _p = instance_find(obj_player, 0);
if (!instance_exists(alvo) or (alvo.morrendo and estado != "sucesso") or _p == noone or _p.morto)
{
    if (instance_exists(alvo)) with (alvo) { em_qte = false; executando = false; }
    instance_destroy();
    exit;
}

if (estado != "sucesso" and estado != "falha")
{
    // Twilight só obedece à sequência; nada o acerta; fica colado no chefe, de frente
    global.bloqueio_input = max(global.bloqueio_input, 2);
    var _tx = qte_x_frente(alvo, _p.x);
    with (_p)
    {
        tempo_invencivel = max(tempo_invencivel, 20);
        x = lerp(x, _tx, 0.3);
        velh = 0;
        empurrao = 0;
        facing = sign(other.alvo.x - x);
        if (facing == 0) facing = 1;
    }
}

switch (estado)
{
    case "entrada":
        if (t >= 34) { estado = "botao"; t = 0; }
    break;

    case "botao":
        var _certo = seq[i];
        var _ap = -1;
        var _todas = [ACAO.ATACAR, ACAO.ATAQUE_FORTE, ACAO.PULAR, ACAO.DEFENDER, ACAO.ESQUIVA, ACAO.ATAQUE_SALTO, ACAO.INTERAGIR, ACAO.ESPECIAL, ACAO.ESPECIAL_2, ACAO.ESPECIAL_3, ACAO.FURIA];
        for (var _k = 0; _k < array_length(_todas); _k++) if (global.inp_apertado[_todas[_k]]) { _ap = _todas[_k]; break; }
        if (_ap != -1 and t > 3)
        {
            // no toque, o botão de esquiva sem direção vira defesa (vale para o botão DEFESA)
            if (_ap == _certo or (_certo == ACAO.DEFENDER and _ap == ACAO.ESQUIVA))
            {
                i += 1;
                acerto_fx = 16;
                estado = "golpe";
                t = 0;
                // o golpe de cinema (a vida quem tira é a sequência: o chefe está em_qte)
                var _ch = golpes[(i - 1) mod array_length(golpes)];
                with (_p) { golpe_cancelar(); golpe_iniciar(_ch); }
                var _n = array_length(seq);
                var _rest = _n - i + 1;
                with (alvo)
                {
                    if (barra_tempo <= 0) vida_atraso = vida;
                    barra_tempo = 180;
                    flash_dano = eh_boss ? 3 : 5;
                    vida = max(1, vida - max(1, round((vida - 1) / max(1, _rest))));
                }
                var _cx = alvo.x;
                var _cy = (alvo.bbox_top + alvo.bbox_bottom) / 2;
                if (alvo.eh_boss) _cx = (_p.x < alvo.x) ? alvo.bbox_left + 26 : alvo.bbox_right - 26;
                espada_fx_impacto(_cx, _cy, _p.facing, (i >= _n) ? 2 : 1);
                fx_em("sangue", _cx, _cy, alvo.eh_boss ? 1.4 : 1.1, _p.facing, -129);
                impacto(i >= _n ? 10 : 6);
                global.camera_impact = max(global.camera_impact, i >= _n ? 16 : 9);
                som("hit_pesado", 0.85, 0.06);
            }
            else
            {
                // ERROU: o chefe se solta
                errado = _ap;
                perfeita = false;
                estado = "falha";
                t = 0;
                qte_falhou_agora = true;
            }
        }
        else if (t >= tempo_botao)
        {
            perfeita = false;
            estado = "falha";
            t = 0;
            qte_falhou_agora = true;
        }
    break;

    case "golpe":
        if (t >= 24)
        {
            if (i >= array_length(seq))
            {
                // SEQUÊNCIA COMPLETA: o finalizador derruba o chefe
                estado = "sucesso";
                t = 0;
                global.qte_alvo = noone;
                var _a = alvo;
                with (_p) golpe_cancelar();
                with (_a) { em_qte = false; qte_vencido = true; executando = true; finalizavel = false; qte_pronto = false; tempo_invencivel = 0; }
                with (_p) { alvo_final = _a; golpe_iniciar("finalizador"); }
                // v1.19: cada sequência completada devolve vida a Twilight
                qte_curar(_p);
                perfil_somar("sequencias");
                if (perfeita and _a.object_index == obj_boss_01) conquista("perfeita");
                som("espada_evoluir", 0.6, 0);
            }
            else { estado = "botao"; t = 0; }
        }
    break;

    case "sucesso":
        if (t >= 70) instance_destroy();
    break;

    case "falha":
        if (t >= 50) instance_destroy();
    break;
}

// a falha acontece uma vez: o chefe se solta, empurra Twilight e volta a lutar
if (qte_falhou_agora)
{
    qte_falhou_agora = false;
    global.qte_alvo = noone;
    som("sfx_negado", 0.9, 0);
    global.camera_impact = max(global.camera_impact, 14);
    with (_p) { golpe_cancelar(); tempo_invencivel = 0; }
    with (alvo)
    {
        em_qte = false;
        executando = false;
        finalizavel = false;
        qte_pronto = false;
        qte_falhou();
    }
}
