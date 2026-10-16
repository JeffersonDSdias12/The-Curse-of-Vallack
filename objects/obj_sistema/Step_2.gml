// ===== END STEP: impacto (hit-stop) e câmera lenta também param as animações =====
// O Begin Step devolve a velocidade original no quadro seguinte.
var _f = 1;
if (global.hitstop > 0) _f = 0;
else if (global.lenta_t > 0) _f = global.lenta_fator;
if (_f < 1)
{
    with (obj_entidade)
    {
        hs_vel = image_speed;
        hs_on = true;
        image_speed = hs_vel * _f;
    }
    with (obj_bola_fogo)
    {
        hs_vel = image_speed;
        hs_on = true;
        image_speed = hs_vel * _f;
    }
}
