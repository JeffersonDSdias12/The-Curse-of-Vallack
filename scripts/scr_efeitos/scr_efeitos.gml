// =====================================================================
//  scr_efeitos: efeitos visuais compartilhados (portal, cristal, barreira)
// =====================================================================

// Portal de magia no chão de onde as bestas surgem.
// _abre = 0..1 (tamanho), _t = tempo para a animação
function desenhar_portal(_x, _y, _abre, _t)
{
    if (_abre <= 0) return;
    var _rx = 34 * _abre;
    var _ry = 9 * _abre;
    // brilho e coluna de luz
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.32 * _abre);
    draw_set_color(make_color_rgb(170, 40, 200));
    draw_ellipse(_x - _rx * 1.6, _y - _ry * 1.6, _x + _rx * 1.6, _y + _ry * 1.6, false);
    retangulo_gradiente(_x - _rx * 0.8, _y - 80 * _abre, _x + _rx * 0.8, _y, make_color_rgb(200, 60, 255), 0, make_color_rgb(200, 60, 255), 0.32 * _abre);
    gpu_set_blendmode(bm_normal);
    // buraco escuro
    draw_set_alpha(0.92 * _abre);
    draw_set_color(make_color_rgb(18, 4, 24));
    draw_ellipse(_x - _rx, _y - _ry, _x + _rx, _y + _ry, false);
    // anel e runas girando
    draw_set_alpha(_abre);
    draw_set_color(make_color_rgb(230, 90, 255));
    draw_ellipse(_x - _rx, _y - _ry, _x + _rx, _y + _ry, true);
    draw_ellipse(_x - _rx - 1, _y - _ry - 1, _x + _rx + 1, _y + _ry + 1, true);
    for (var _k = 0; _k < 8; _k++)
    {
        var _a = _t * 4 + _k * 45;
        draw_circle(_x + lengthdir_x(_rx * 1.25, _a), _y + lengthdir_y(_ry * 1.25, _a), 1.6, false);
    }
    // faíscas subindo
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(240, 140, 255));
    for (var _k2 = 0; _k2 < 7; _k2++)
    {
        var _f = frac(_t / 40 + _k2 / 7);
        draw_set_alpha((1 - _f) * _abre);
        draw_circle(_x + sin(_k2 * 2.1 + _t / 9) * _rx * 0.7, _y - _f * 64, 1.5, false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// Cristal mágico flutuante (checkpoint). _cor1 = cor principal, _cor2 = brilho.
function desenhar_cristal(_x, _y, _tam, _cor1, _cor2, _brilho, _t)
{
    var _gira = 0.55 + 0.45 * abs(dcos(_t * 1.6));   // ilusão de rotação
    var _w = _tam * _gira;
    var _h = _tam * 1.9;
    // halo
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.22 * _brilho);
    draw_set_color(_cor2);
    draw_circle(_x, _y, _tam * 2.3, false);
    draw_set_alpha(0.3 * _brilho);
    draw_circle(_x, _y, _tam * 1.3, false);
    gpu_set_blendmode(bm_normal);
    // faces (losango alongado com duas tonalidades)
    draw_set_alpha(1);
    draw_set_color(merge_color(_cor1, c_black, 0.35));
    draw_triangle(_x - _w, _y, _x, _y - _h, _x, _y + _h * 0.75, false);
    draw_set_color(_cor1);
    draw_triangle(_x + _w, _y, _x, _y - _h, _x, _y + _h * 0.75, false);
    draw_set_color(merge_color(_cor1, c_white, 0.45));
    draw_triangle(_x - _w * 0.35, _y - _h * 0.1, _x, _y - _h * 0.85, _x + _w * 0.15, _y - _h * 0.1, false);
    // contorno
    draw_set_color(merge_color(_cor2, c_white, 0.5));
    draw_line(_x - _w, _y, _x, _y - _h);
    draw_line(_x, _y - _h, _x + _w, _y);
    draw_line(_x + _w, _y, _x, _y + _h * 0.75);
    draw_line(_x, _y + _h * 0.75, _x - _w, _y);
    // centelha central
    gpu_set_blendmode(bm_add);
    draw_set_alpha((0.5 + 0.5 * sin(_t * 0.15)) * _brilho);
    draw_set_color(c_white);
    draw_circle(_x, _y - _h * 0.15, 2.2, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// Barreira mágica vertical (bloqueia a saída enquanto o guardião vive)
function desenhar_barreira(_x, _y_topo, _y_base, _alpha, _t)
{
    if (_alpha <= 0) return;
    gpu_set_blendmode(bm_add);
    retangulo_gradiente_h(_x - 26, _y_topo, _x, _y_base, make_color_rgb(200, 20, 30), 0, make_color_rgb(200, 20, 30), 0.35 * _alpha);
    retangulo_gradiente_h(_x, _y_topo, _x + 26, _y_base, make_color_rgb(200, 20, 30), 0.35 * _alpha, make_color_rgb(200, 20, 30), 0);
    draw_set_color(make_color_rgb(255, 90, 70));
    for (var _i = 0; _i < 14; _i++)
    {
        var _f = frac(_t / 90 + _i / 14);
        var _yy = _y_base - _f * (_y_base - _y_topo);
        draw_set_alpha((1 - abs(_f - 0.5) * 2) * _alpha);
        var _ox = sin(_t / 12 + _i * 1.7) * 6;
        draw_line_width(_x + _ox - 4, _yy, _x + _ox + 4, _yy - 6, 2);
    }
    draw_set_alpha(0.6 * _alpha);
    draw_line_width(_x, _y_topo, _x, _y_base, 2);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// Ícone pulsando sobre um inimigo pronto para o FINALIZADOR (botão BOLA)
function desenhar_icone_finalizador(_x, _y)
{
    var _p = 0.5 + 0.5 * sin(current_time / 90);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.35 + 0.25 * _p);
    draw_set_color(make_color_rgb(255, 60, 40));
    draw_circle(_x, _y, 10 + 2 * _p, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    var _tf = gpu_get_texfilter();
    gpu_set_texfilter(true);
    var _a = 13;
    var _w = icone_acao_largura(ACAO.ATAQUE_SALTO, _a);
    desenhar_icone_acao(_x - _w / 2, _y, ACAO.ATAQUE_SALTO, _a, 1);
    gpu_set_texfilter(_tf);
    desenho_resetar();
}

// A Lâmina de Sylla grande (tela de armas): runas acendem a cada nível
function desenhar_espada_grande(_cx, _y1, _y2, _nivel, _alpha, _brilho, _t)
{
    var _h = _y2 - _y1;
    var _lam_fim = _y1 + _h * 0.70;      // fim da lâmina / guarda
    var _bw = 15;                         // meia largura da lâmina
    // aura
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_alpha * (0.10 + 0.04 * _nivel + 0.5 * _brilho));
    draw_set_color(make_color_rgb(220, 30, 20));
    draw_ellipse(_cx - 70, _y1 - 10, _cx + 70, _lam_fim + 20, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(_alpha);
    // lâmina
    var _c1 = make_color_rgb(205, 210, 220);
    var _c2 = make_color_rgb(120, 125, 140);
    draw_primitive_begin(pr_trianglelist);
    draw_vertex_color(_cx, _y1, c_white, _alpha);
    draw_vertex_color(_cx - _bw, _y1 + 40, _c1, _alpha);
    draw_vertex_color(_cx + _bw, _y1 + 40, _c2, _alpha);
    draw_vertex_color(_cx - _bw, _y1 + 40, _c1, _alpha);
    draw_vertex_color(_cx + _bw, _y1 + 40, _c2, _alpha);
    draw_vertex_color(_cx - _bw, _lam_fim, _c1, _alpha);
    draw_vertex_color(_cx + _bw, _y1 + 40, _c2, _alpha);
    draw_vertex_color(_cx - _bw, _lam_fim, _c1, _alpha);
    draw_vertex_color(_cx + _bw, _lam_fim, _c2, _alpha);
    draw_primitive_end();
    // sulco central
    draw_set_color(make_color_rgb(90, 92, 105));
    draw_rectangle(_cx - 2, _y1 + 30, _cx + 2, _lam_fim - 6, false);
    // runas (uma por nível)
    for (var _i = 0; _i < 5; _i++)
    {
        var _ry = _lam_fim - 26 - _i * ((_lam_fim - _y1 - 70) / 5);
        var _acesa = (_i < _nivel);
        if (_acesa)
        {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(_alpha * (0.5 + 0.3 * sin(_t / 9 + _i) + _brilho));
            draw_set_color(make_color_rgb(255, 50, 30));
            draw_circle(_cx, _ry, 8, false);
            gpu_set_blendmode(bm_normal);
        }
        draw_set_alpha(_alpha);
        draw_set_color(_acesa ? make_color_rgb(255, 120, 90) : make_color_rgb(70, 70, 80));
        draw_line_width(_cx - 5, _ry - 5, _cx + 5, _ry + 5, 2);
        draw_line_width(_cx + 5, _ry - 5, _cx - 5, _ry + 5, 2);
        draw_line_width(_cx, _ry - 7, _cx, _ry + 7, 2);
    }
    // guarda
    var _ouro = make_color_rgb(200, 150, 60);
    draw_set_color(_ouro);
    draw_triangle(_cx - 54, _lam_fim - 4, _cx, _lam_fim - 12, _cx, _lam_fim + 12, false);
    draw_triangle(_cx + 54, _lam_fim - 4, _cx, _lam_fim - 12, _cx, _lam_fim + 12, false);
    draw_set_color(make_color_rgb(120, 80, 30));
    draw_rectangle(_cx - 16, _lam_fim - 6, _cx + 16, _lam_fim + 8, false);
    draw_set_color(make_color_rgb(200, 20, 20));
    draw_circle(_cx, _lam_fim + 1, 6, false);
    // cabo
    var _cabo_fim = _y2 - 18;
    draw_set_color(make_color_rgb(50, 26, 18));
    draw_rectangle(_cx - 7, _lam_fim + 8, _cx + 7, _cabo_fim, false);
    draw_set_color(make_color_rgb(90, 50, 30));
    for (var _yy = _lam_fim + 12; _yy < _cabo_fim; _yy += 8) draw_line_width(_cx - 7, _yy, _cx + 7, _yy + 4, 2);
    // pomo
    draw_set_color(_ouro);
    draw_circle(_cx, _y2 - 10, 11, false);
    draw_set_color(make_color_rgb(200, 20, 20));
    draw_circle(_cx, _y2 - 10, 5, false);
    draw_set_alpha(1);
}

// Pote de orbs (HUD e tela de armas)
function desenhar_pote_orbs(_x, _y, _esc, _alpha, _fx)
{
    var _p = 1 + 0.15 * clamp(_fx / 20, 0, 1);
    var _r = 14 * _esc * _p;
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(40, 26, 20));
    draw_circle(_x, _y + 2, _r + 2, false);
    draw_set_color(make_color_rgb(120, 86, 46));
    draw_circle(_x, _y + 2, _r, false);
    draw_set_color(make_color_rgb(60, 36, 22));
    draw_rectangle(_x - _r * 0.55, _y - _r - 4 * _esc, _x + _r * 0.55, _y - _r + 4 * _esc, false);
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_alpha * (0.55 + 0.35 * clamp(_fx / 20, 0, 1)));
    draw_set_color(make_color_rgb(255, 40, 30));
    draw_circle(_x, _y + 3, _r * 0.65, false);
    draw_set_color(make_color_rgb(255, 200, 170));
    draw_circle(_x - _r * 0.2, _y, _r * 0.22, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// Cadeado pequeno (ação ainda bloqueada)
function desenhar_cadeado(_x, _y, _alpha = 1)
{
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(30, 24, 20));
    draw_roundrect_ext(_x - 7, _y - 3, _x + 7, _y + 8, 3, 3, false);
    draw_set_color(make_color_rgb(200, 170, 90));
    draw_roundrect_ext(_x - 6, _y - 2, _x + 6, _y + 7, 3, 3, false);
    draw_set_color(make_color_rgb(200, 170, 90));
    draw_circle(_x, _y - 4, 5, true);
    draw_circle(_x, _y - 4, 4, true);
    draw_set_color(make_color_rgb(60, 40, 20));
    draw_rectangle(_x - 1, _y + 1, _x + 1, _y + 4, false);
    draw_set_alpha(1);
}
