// =====================================================================
//  obj_inimigo_base — End Step (v1.12)
//  * petrificação do Modo Fúria: o inimigo fica lento e depois volta ao normal
//  * empurrão limitado: os golpes não jogam mais os inimigos para fora do combo
//  * combo aéreo: devolve a gravidade normal depois de ficar suspenso
//  Depois, o movimento e a colisão do obj_entidade.
// =====================================================================
var _dt = global.dt;
if (petrif_t > 0)
{
    petrif_t -= _dt;
    if (petrif_t <= 0) { petrif = 0; petrificado = false; }
}
if (petrificado and atordoado <= 0) { petrificado = false; petrif = 0; }
if (petrif > 0 and !morrendo) velh *= (1 - 0.22 * petrif);
empurrao = clamp(empurrao, -2.6, 2.6);
if (suspenso_t > 0)
{
    suspenso_t -= _dt;
    if (suspenso_t <= 0 or morrendo) { suspenso_t = 0; grav_ia = grav_ia_base; }
}
event_inherited();
if (limite_x2 > limite_x1) x = clamp(x, limite_x1, limite_x2);