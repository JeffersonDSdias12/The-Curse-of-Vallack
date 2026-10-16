var _dt = global.dt;
t += _dt;
x += dir * vel * _dt;
passo += vel * _dt;
image_index = (passo / 7) mod sprite_get_number(sprite_index);
alpha = min(1, t / 15);
if (!gritou and t > 20 and random(1) < 0.35)
{
    gritou = true;
    fala_dizer(id, choose("Socorro!", "Fujam!", "A vila está queimando!", "Os monstros!"), make_color_rgb(60, 40, 30), true, 90);
}
// some depois de correr um pouco (vai para longe, ao fundo)
if (t > 200) alpha = max(0, 1 - (t - 200) / 40);
if (t > 240 or x < 0 or x > room_width) instance_destroy();
