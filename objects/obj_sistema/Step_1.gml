// ===== BEGIN STEP: roda antes de todos os objetos =====
// dt "real" (30 ou 60 FPS) e dt do jogo, que para por alguns quadros no
// impacto dos golpes (hit-stop) e fica mais lento na câmera lenta.
global.dt_real = clamp(60 / max(1, game_get_speed(gamespeed_fps)), 0.5, 3);

// as animações que o End Step congelou (impacto / câmera lenta) voltam ao normal
with (obj_entidade) if (variable_instance_exists(id, "hs_on") and hs_on) { image_speed = hs_vel; hs_on = false; }
with (obj_bola_fogo) if (variable_instance_exists(id, "hs_on") and hs_on) { image_speed = hs_vel; hs_on = false; }
global.dt = global.dt_real;
if (global.hitstop > 0)
{
    global.hitstop = max(0, global.hitstop - global.dt_real);
    global.dt = 0;
}
else if (global.lenta_t > 0)
{
    global.lenta_t = max(0, global.lenta_t - global.dt_real);
    global.dt = global.dt_real * global.lenta_fator;
    if (global.lenta_t <= 0) global.lenta_fator = 1;
}
if (room == rm_menu) { global.hitstop = 0; global.lenta_t = 0; global.lenta_fator = 1; global.dt = global.dt_real; }

// tempo de jogo (só conta com o jogador ativo: pausas e menus não contam)
if (instance_exists(obj_player)) global.tempo_jogo += global.dt_real / 60;

// áudio: música, ambientes e a pausa abafando o som
global.audio_pausa = instance_exists(obj_pausa) or instance_exists(obj_menu_armas) or instance_exists(obj_save_menu) or instance_exists(obj_pergaminho);
audio_atualizar();
if (global.orbs_fx > 0) global.orbs_fx = max(0, global.orbs_fx - global.dt_real);
if (global.fala_espera > 0) global.fala_espera -= global.dt;
if (global.orb_som_t > 0) global.orb_som_t -= global.dt_real;
else if (!instance_exists(obj_orb)) global.orb_seq = 0;

input_atualizar();
if (global.bloqueio_input > 0) global.bloqueio_input -= global.dt;
tela_atualizar();

// F11: alterna janela / tela cheia em qualquer tela
if (keyboard_check_pressed(vk_f11))
{
    global.cfg_tela_cheia = 1 - global.cfg_tela_cheia;
    config_aplicar();
    config_salvar();
}

// F1: mostra máscaras de colisão e hitboxes (verificação)
if (keyboard_check_pressed(vk_f1)) global.debug_hitbox = !global.debug_hitbox;
