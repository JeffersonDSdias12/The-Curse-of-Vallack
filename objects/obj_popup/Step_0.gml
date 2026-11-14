vida -= global.dt_real;
y += vy * global.dt_real;
vy *= power(0.95, global.dt_real);
if (vida <= 0) instance_destroy();
