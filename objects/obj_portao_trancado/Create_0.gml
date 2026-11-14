// =====================================================================
//  obj_portao_trancado — o PORTÃO da paliçada no meio da fase 1 (v1.14)
//  Trancado: ninguém passa (a paliçada sobe além da câmera). Chegando
//  perto sem a chave: "ACHE A CHAVE DO PORTÃO" (ela está no baú selado no
//  alto do forte de madeira). Com a chave: a grade sobe e o caminho abre.
//  Fica aberto no save (aberto_chave). Criado pelo obj_terreno.
// =====================================================================
y_topo = y - 540;               // a paliçada passa do alto da câmera
estado = "trancado";            // trancado -> abrindo -> aberto
sobe = 0;                       // a grade subindo (0 a 1)
t = 0;
aviso_dado = false;
chave = aberto_chave("portao", x, y);
solido = noone;
if (aberto_tem(chave))
{
    estado = "aberto";
    sobe = 1;
    solido = solido_criar(x - 14, y_topo, x + 14, y - 112);      // só a paliçada em cima da passagem
}
else solido = solido_criar(x - 14, y_topo, x + 14, y);