var _dt = global.dt;
if (tremor > 0) tremor = max(0, tremor - 0.6 * _dt);
if (flash > 0) flash -= _dt;
