var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _ouro  = make_color_rgb(255, 210, 90);
var _ouro2 = make_color_rgb(176, 141, 70);
var _num   = max(1, fase_numero(destino));

// ----- escurecer / clarear -----
// v1.19: a cortina em brasa entra pela esquerda e, depois do carregamento, sai pela direita
if (fase == "inicio" or fase == "escurecer")
{
    var _ke = clamp(tempo / 45, 0, 1);
    transicao_cortina_desenhar((fase == "inicio") ? 0 : _ke * _ke * (3 - 2 * _ke));
    exit;
}
if (fase == "clarear")
{
    var _kc = clamp(tempo / 40, 0, 1);
    transicao_cortina_desenhar(1 - _kc * _kc * (3 - 2 * _kc), true);
    exit;
}

// ----- fundo preto com brilho vermelho amaldiçoado -----
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
var _pulso = 0.10 + 0.06 * sin(current_time / 400);
retangulo_gradiente(0, _gh * 0.45, _gw, _gh, make_color_rgb(90, 0, 10), 0, make_color_rgb(90, 0, 10), _pulso + 0.15);

// ----- TÍTULO DO CAPÍTULO (letra por letra, efeito amaldiçoado) -----
if (fase == "capitulo")
{
    var _sai = clamp((duracao_capitulo - tempo) / 30, 0, 1);
    var _a = min(clamp(tempo / 25, 0, 1), _sai);
    txt(_cx, _gh / 2 - 92, "CAPÍTULO " + string(_num), FONTE.MEDIA, _ouro, _a, fa_center, fa_middle);
    txt_amaldicoado(_cx, _gh / 2 - 30, fase_nome(_num), FONTE.GRANDE, c_white, tempo - 15, 3, min(1, (_gw * 0.9) / max(1, txt_largura(fase_nome(_num), FONTE.GRANDE))), _sai);
    desenhar_divisor(_cx, _gh / 2 + 22, 240, _a * clamp((tempo - 60) / 30, 0, 1));
    txt_bloco(_cx, _gh / 2 + 44, fase_sub(_num), FONTE.PEQUENA, make_color_rgb(210, 205, 205), _a * clamp((tempo - 70) / 30, 0, 1), min(_gw - 120, 820));
    desenho_resetar();
    exit;
}

// ----- CARREGANDO -----
// v1.13: nas fases, o único tutorial do jogo (COMO JOGAR) num pergaminho
if (tutorial)
{
    var _tam_w = min(_gw - 60, 880);
    var _tam_h = 650;
    var _tcy = _gh / 2 - 8;
    var _pag = tutorial_carregamento();
    var _ta = clamp(tempo / 12, 0, 1);
    var _pronto = (progresso >= 100 and tempo >= duracao_carregamento + 25);
    var _rodape = _pronto ? "COMEÇAR" : "";
    pergaminho_desenhar(_cx, _tcy, _tam_w, _tam_h, tutorial_abre, _pag, _ta, _rodape, "", 0.75 + 0.25 * sin(current_time / 160));
    // capítulo e progresso no pé do pergaminho (enquanto carrega)
    if (tutorial_abre >= 1 and !_pronto)
    {
        var _y2 = _tcy + _tam_h / 2;
        var _bw2 = 300;
        var _tinta2 = make_color_rgb(96, 64, 34);
        txt(_cx, _y2 - 48, "CAPÍTULO " + string(_num) + "  ·  " + fase_nome(_num) + "  ·  carregando " + string(floor(progresso)) + "%", FONTE.MINI, _tinta2, _ta, fa_center, fa_middle, min(1, (_tam_w - 200) / max(1, txt_largura("CAPÍTULO " + string(_num) + "  ·  " + fase_nome(_num) + "  ·  carregando 100%", FONTE.MINI))));
        draw_set_alpha(_ta);
        draw_set_color(make_color_rgb(150, 120, 80));
        draw_rectangle(_cx - _bw2 / 2, _y2 - 30, _cx + _bw2 / 2, _y2 - 26, false);
        draw_set_color(make_color_rgb(128, 18, 16));
        draw_rectangle(_cx - _bw2 / 2, _y2 - 30, _cx - _bw2 / 2 + _bw2 * progresso / 100, _y2 - 26, false);
        draw_set_alpha(1);
    }
    desenho_resetar();
    exit;
}

// v1.17: CARREGAMENTO DA FASE (30 s): a foto do cenário ao fundo (aproximando
// devagar), o capítulo, a barra e as DICAS de combos passando embaixo
if (modo != "menu")
{
    var _ent2 = clamp(tempo / 20, 0, 1);
    var _k = clamp(progresso / 100, 0, 1);
    if (variable_global_exists("img_mapa") and sprite_exists(global.img_mapa))
    {
        var _fi = clamp(_num - 1, 0, MAPA_FASES - 1);
        var _ez = max(_gw / 320, _gh / 180) * (1.06 + 0.1 * _k);
        gpu_set_texfilter(true);
        draw_sprite_part_ext(global.img_mapa, 0, (_fi mod 6) * 320, (_fi div 6) * 180, 320, 180, _cx - 160 * _ez - 30 * _k, _gh / 2 - 90 * _ez, _ez, _ez, make_color_rgb(150, 130, 140), 0.7 * _ent2);
        gpu_set_texfilter(false);
    }
    retangulo_gradiente(0, 0, _gw, _gh * 0.5, c_black, 0.8, c_black, 0.25);
    retangulo_gradiente(0, _gh * 0.5, _gw, _gh, c_black, 0.25, c_black, 0.92);
    txt(_cx, 96, "CAPÍTULO " + string(_num), FONTE.MEDIA, _ouro, _ent2, fa_center, fa_middle);
    var _fm = fases_mapa();
    var _nf = _fm[clamp(_num - 1, 0, MAPA_FASES - 1)].nome;
    txt_sombra(_cx, 150, _nf, FONTE.GRANDE, c_white, _ent2, fa_center, fa_middle, min(1, (_gw * 0.9) / max(1, txt_largura(_nf, FONTE.GRANDE))));
    desenhar_divisor(_cx, 196, 240, _ent2);
    // barra
    var _bw3 = min(_gw - 160, 640);
    var _by3 = _gh * 0.6;
    draw_set_alpha(_ent2);
    draw_set_color(make_color_rgb(30, 26, 26));
    draw_rectangle(_cx - _bw3 / 2, _by3, _cx + _bw3 / 2, _by3 + 12, false);
    var _fim3 = _cx - _bw3 / 2 + _bw3 * _k;
    draw_rectangle_color(_cx - _bw3 / 2, _by3, _fim3, _by3 + 12, make_color_rgb(150, 20, 25), make_color_rgb(255, 200, 80), make_color_rgb(255, 200, 80), make_color_rgb(150, 20, 25), false);
    gpu_set_blendmode(bm_add);
    draw_set_alpha((0.5 + 0.3 * sin(current_time / 90)) * _ent2);
    draw_set_color(make_color_rgb(255, 140, 60));
    draw_circle(_fim3, _by3 + 6, 9, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(_ent2);
    draw_set_color(_ouro2);
    draw_rectangle(_cx - _bw3 / 2 - 3, _by3 - 3, _cx + _bw3 / 2 + 3, _by3 + 15, true);
    txt(_cx, _by3 + 36, (_k >= 1) ? "PRONTO" : "Carregando...  " + string(floor(progresso)) + "%", FONTE.PEQUENA, make_color_rgb(190, 186, 190), _ent2, fa_center, fa_middle);
    // a dica da vez: entra deslizando da direita e sai pela esquerda
    if (array_length(dicas) > 0 and global.cfg_tutorial)
    {
        var _d = dicas[dica_i];
        var _kin = clamp(dica_t / 24, 0, 1);
        var _kout = clamp((DICA_TEMPO - dica_t) / 24, 0, 1);
        var _da = min(_kin, _kout) * _ent2;
        var _desl = (1 - _kin) * 140 - (1 - _kout) * 140;
        var _y1 = _gh - 150;
        hud_faixa(60, _y1, _gw - 60, _gh - 34, 0.92 * _ent2);
        txt(96, _y1 + 22, "DICA  ·  COMBOS E ATAQUES", FONTE.MINI, _ouro, _ent2, fa_left, fa_middle);
        var _ix = 96 + _desl;
        for (var _ic = 0; _ic < array_length(_d.ic); _ic++)
        {
            var _iw = icone_acao_largura(_d.ic[_ic], 34);
            desenhar_icone_acao(_ix, _y1 + 70, _d.ic[_ic], 34, _da);
            _ix += _iw + 8;
        }
        var _tx = max(_ix + 18, 96 + _desl + 180);
        txt_sombra(_tx, _y1 + 54, _d.n, FONTE.PEQUENA, c_white, _da, fa_left, fa_middle, min(1, (_gw - 100 - _tx) / max(1, txt_largura(_d.n, FONTE.PEQUENA))));
        txt(_tx, _y1 + 86, _d.t, FONTE.MINI, make_color_rgb(215, 205, 200), _da, fa_left, fa_middle, min(1, (_gw - 100 - _tx) / max(1, txt_largura(_d.t, FONTE.MINI))));
    }
    desenho_resetar();
    exit;
}

// sem o tutorial (volta ao menu, ou tutorial desligado): título e barra
var _titulo = (modo == "menu") ? "VOLTANDO AO MENU INICIAL" : "CARREGANDO  ·  CAPÍTULO " + string(_num);
var _sub    = (modo == "menu") ? JOGO_TITULO + "  ·  " + JOGO_SUBTITULO : fase_nome(_num);
var _ent = clamp(tempo / 20, 0, 1);
txt_sombra(_cx, _gh * 0.36, _titulo, FONTE.MEDIA, _ouro, _ent, fa_center, fa_middle);
txt(_cx, _gh * 0.36 + 36, _sub, FONTE.PEQUENA, make_color_rgb(200, 200, 205), _ent, fa_center, fa_middle);

// barra de progresso
var _bw = min(_gw - 160, 640);
var _by = _gh * 0.56;
draw_set_color(make_color_rgb(30, 26, 26));
draw_rectangle(_cx - _bw / 2, _by, _cx + _bw / 2, _by + 16, false);
var _fim = _cx - _bw / 2 + _bw * progresso / 100;
draw_rectangle_color(_cx - _bw / 2, _by, _fim, _by + 16, make_color_rgb(150, 20, 25), make_color_rgb(255, 200, 80), make_color_rgb(255, 200, 80), make_color_rgb(150, 20, 25), false);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.5 + 0.3 * sin(current_time / 90));
draw_set_color(make_color_rgb(255, 140, 60));
draw_circle(_fim, _by + 8, 10, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(_ouro2);
draw_rectangle(_cx - _bw / 2 - 3, _by - 3, _cx + _bw / 2 + 3, _by + 19, true);
var _estado = (progresso >= 100) ? "PRONTO" : "Carregando...  " + string(floor(progresso)) + "%";
txt(_cx, _by + 44, _estado, FONTE.PEQUENA, (progresso >= 100) ? c_white : make_color_rgb(170, 170, 175), 1, fa_center, fa_middle);

desenho_resetar();
