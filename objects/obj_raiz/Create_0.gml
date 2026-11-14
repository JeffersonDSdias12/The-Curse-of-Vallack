// =====================================================================
//  obj_raiz — raiz da Árvore Amaldiçoada que rompe o chão
//  aviso (coluna de luz roxa + "!" + som) -> sobe (fere) -> desce
//  v1.12: maior (96 px) e com um aviso bem mais visível
// =====================================================================
dano = 14;
atraso = 0;
t = 0;
estado = "aviso";
sobe = 0;
atingidos = [];
semente = random(100);
aviso_t = 50;            // quadros de aviso antes de subir
alt = 96;                // altura da raiz
meia = 18;               // meia largura da área de dano
som_tocou = false;
