// no 1º passo todos os blocos de chão e a decoração da sala já existem
if (!pronto)
{
    pronto = true;
    // v1.13: os pedaços de castelo espalhados pela vila saem da fase
    for (var _i = 0; _i < array_length(remover); _i++) with (remover[_i]) instance_destroy(id, false);
    quedas_preparar();     // v1.20: baús, caixotes e armadilhas saem de cima dos buracos novos
    for (var _i = 0; _i < array_length(abismos); _i++) terreno_abrir(abismos[_i][0], abismos[_i][1], chao_y);
    quedas_montar();       // v1.20: pontes que desabam e piso frágil
    for (var _i = 0; _i < array_length(plataformas); _i++) terreno_plataforma(plataformas[_i][0], plataformas[_i][1], plataformas[_i][2]);
    // caminhos por cima: escadarias, torres, passarelas e ilhas
    for (var _i = 0; _i < array_length(escadas); _i++)
    {
        var _e = escadas[_i];
        terreno_limpar(min(_e[0], _e[1]), max(_e[0], _e[1]));
        terreno_escada(_e[0], _e[1], _e[2], chao_y);
    }
    for (var _i = 0; _i < array_length(blocos); _i++)
    {
        var _b = blocos[_i];
        terreno_limpar(_b[0], _b[1]);
        terreno_bloco(_b[0], _b[1], _b[2], chao_y);
    }
    for (var _i = 0; _i < array_length(pontes); _i++) terreno_ponte(pontes[_i][0], pontes[_i][1], pontes[_i][2]);
    for (var _i = 0; _i < array_length(ilhas); _i++)
    {
        var _il = ilhas[_i];
        var _p = pecas_ok ? peca(_il[2]) : undefined;
        var _lw = is_undefined(_p) ? 60 : _p[2] * PECA_ESC * 0.78;
        terreno_ponte(_il[0] - _lw / 2, _il[0] + _lw / 2, _il[1]);
    }
    // inimigos que ficam no alto (o arqueiro na torre)
    for (var _i = 0; _i < array_length(mover); _i++)
    {
        var _m = mover[_i];
        with (_m[0]) if (x >= _m[1] and x <= _m[2]) { x = _m[3]; y = _m[4]; xstart = x; ystart = y; }
    }
    // v1.14: pontes de corda e plataformas penduradas (de mão única: o herói sobe
    // por baixo e desce com ▼ + PULO, como as passarelas)
    for (var _i = 0; _i < array_length(pontes_corda); _i++) terreno_ponte(pontes_corda[_i][0], pontes_corda[_i][1], pontes_corda[_i][2]);
    for (var _i = 0; _i < array_length(suspensas); _i++) terreno_ponte(suspensas[_i][0], suspensas[_i][1], suspensas[_i][2]);
    // o baú da chave, selado até os guardiões caírem (aberto antes = a chave já é sua)
    if (!is_undefined(chave_dados))
    {
        bau_chave = instance_create_depth(chave_dados.bau[0], chave_dados.bau[1], 150, obj_bau);
        bau_chave.conteudo = "chave";
        bau_chave.selado = (bau_chave.estado == "fechado");
        if (!bau_chave.selado) { global.chave_portao = true; arena_estado = "livre"; }
    }
    if (array_length(portao) > 0)
    {
        // o portão toma o lugar da parede quebrável que ficava ali
        with (obj_parede_quebravel) if (abs(x - other.portao[0]) < 48) instance_destroy(id, false);
        instance_create_depth(portao[0], chao_y, 140, obj_portao_trancado);
    }
    // recompensas no adarve
    for (var _i = 0; _i < array_length(caixotes); _i++)
    {
        var _c = instance_create_depth(caixotes[_i][0], caixotes[_i][1], 150, obj_caixote);
        _c.conteudo = "orbs";
        _c.orbs_valor = 16;
    }
}
t += global.dt;
// v1.14: ARENA DA CHAVE — no alto do forte, os guardiões surgem dos portais; com
// todos derrotados o selo do baú se quebra (a chave do portão está nele)
if (!is_undefined(chave_dados) and instance_exists(bau_chave))
{
    var _ar = chave_dados.arena;
    var _pl = instance_find(obj_player, 0);
    // (o forte inteiro: chegando pela corda Twilight pisa bem na borda)
    if (arena_estado == "espera" and _pl != noone and !_pl.morto and _pl.x > _ar[0] - 14 and _pl.x < _ar[1] + 16 and abs(_pl.y - _ar[2]) < 4)
    {
        arena_estado = "luta";
        global.arena_chave = true;
        var _g = chave_dados.guardioes;
        var _n = min(array_length(_g), dif_valor([2, 3, 3, 3]));
        for (var _k = 0; _k < _n; _k++)
        {
            var _e = instance_create_depth(_g[_k][1], _ar[2] - 1, 100, _g[_k][0]);
            _e.limite_x1 = _ar[0] + 8;
            _e.limite_x2 = _ar[1] - 8;
            if (variable_instance_exists(_e, "surgir_agora")) { _e.surgir_agora = true; _e.surgir_atraso = 8 + _k * 20; }
            array_push(arena_inimigos, _e);
        }
        aviso_mostrar("GUARDIÕES DO BAÚ  ·  DERROTE-OS PARA QUEBRAR O SELO");
        global.camera_impact = max(global.camera_impact, 5);
        conquista("escalador");          // v1.17: chegou ao alto do forte
    }
    else if (arena_estado == "luta")
    {
        var _vivos = 0;
        for (var _k = 0; _k < array_length(arena_inimigos); _k++)
            if (instance_exists(arena_inimigos[_k]) and !arena_inimigos[_k].morrendo) _vivos += 1;
        if (_vivos == 0)
        {
            arena_estado = "livre";
            global.arena_chave = false;
            bau_chave.selado = false;
            bau_chave.selo_quebra = 40;
            aviso_mostrar("O SELO SE QUEBROU  ·  ABRA O BAÚ");
            som_em("sfx_portal", bau_chave.x, bau_chave.y, 0.9, 0);
            fx_em("faiscas_golpe", bau_chave.x, bau_chave.y - 16, 1.2, 1);
            global.camera_impact = max(global.camera_impact, 6);
        }
    }
}
quedas_passo();            // v1.20
// quem cai no abismo morre (Castlevania): o herói vai para o fim de jogo,
// o monstro some e conta como derrotado
var _fundo = room_height + 6;
with (obj_player) if (!morto and bbox_top > _fundo) jogador_cair_abismo();
with (obj_inimigo_base) if (bbox_top > _fundo)
{
    if (!morrendo) global.inimigos_derrotados += 1;
    instance_destroy(id, false);
}
// o que mais cair lá some (orbs e cristais que rolaram para o vão)
with (obj_orb) if (y > _fundo + 40) instance_destroy(id, false);
with (obj_essencia) if (y > _fundo + 40) instance_destroy(id, false);
