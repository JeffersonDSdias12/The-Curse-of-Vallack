// ===== GAME END (v1.18) =====
// Conquista liberada nos últimos 2 s ainda não foi gravada (conquista() adia
// a gravação para não engasgar a luta): grava antes de fechar.
if (variable_global_exists("perfil_salvar_t") and global.perfil_salvar_t > 0)
{
    global.perfil_salvar_t = 0;
    perfil_salvar_se_mudou();
}