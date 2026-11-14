// ===== DRAW GUI END =====
if (global.debug_hitbox)
{
    var _gw = display_get_gui_width();
    var _info = "DEPURAÇÃO (F1)  ·  " + string(fps) + " FPS  ·  janela " + string(window_get_width()) + "x" + string(window_get_height())
        + "  ·  render " + string(surface_get_width(application_surface)) + "x" + string(surface_get_height(application_surface))
        + "  ·  GUI " + string(display_get_gui_width()) + "x" + string(display_get_gui_height());
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(0, GUI_ALTURA - 26, _gw, GUI_ALTURA, false);
    txt(10, GUI_ALTURA - 13, _info, FONTE.MINI, make_color_rgb(120, 255, 140), 1, fa_left, fa_middle);
    desenho_resetar();
}
gamepad_diagnostico_desenhar();  // v1.19: F2
transicao_veu_desenhar();        // v1.19: a cortina que revela a tela nova (por cima de toda a GUI)
conquistas_toast_desenhar();     // v1.17: aviso de conquista (por cima de tudo)
gpu_set_texfilter(false);
