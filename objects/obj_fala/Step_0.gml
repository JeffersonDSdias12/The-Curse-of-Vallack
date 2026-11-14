var _dt = global.dt_real;
t += _dt;
vida -= _dt;
if (instance_exists(alvo))
{
    ax = alvo.x;
    ay = alvo.bbox_top;
    // o balão também serve ao jogador (fala de batalha), que não tem estas variáveis
    if (variable_instance_exists(alvo, "morrendo") and alvo.morrendo and !alvo.eh_boss) vida = min(vida, 12);
}
else vida = min(vida, 12);
if (vida <= 0) instance_destroy();
