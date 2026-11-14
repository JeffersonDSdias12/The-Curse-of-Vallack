// =====================================================================
//  obj_lampiao — poste com lanterna (v1.11)
//  A lanterna balança com o vento da tempestade. Se Twilight acerta um
//  golpe no poste, ela leva a pancada (som de ferro e faíscas), balança
//  forte e a luz pisca. Não quebra. Ponha no chão (origem embaixo).
// =====================================================================
event_inherited();
vida = 1000000;
vida_max = 1000000;
image_speed = 0;
depth = 240;
ang = 0;                // inclinação da lanterna (graus)
angv = 0;
pisca = 0;
semente = random(100);
t = random(1000);
ao_bater = function(_forca)
{
    vida = vida_max;                                     // nunca quebra
    angv += lado_golpe * (3 + 1.5 * _forca);           // empurrada para longe do golpe
    pisca = 18;
    som_em("lampiao_bater", x, y - 90, 0.9);
    fx_em("faiscas_golpe", x + 12, y - 80, 0.6, lado_golpe, depth - 1);
};
