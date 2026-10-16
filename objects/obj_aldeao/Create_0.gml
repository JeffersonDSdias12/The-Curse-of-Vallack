// =====================================================================
//  obj_aldeao — aldeão fugindo da vila em chamas (só cenário)
// =====================================================================
dir = 1;
vel = random_range(1.6, 2.3);
sprite_index = choose(spr_aldeao_a, spr_aldeao_b);
image_speed = 0;
passo = random(100);
t = 0;
alpha = 0;
morrendo = false;        // (o balão de fala usa estes dois)
eh_boss = false;
gritou = false;
