// a sequência acabou (ou o chefe sumiu): os outros inimigos voltam a lutar
if (global.qte_alvo == alvo) global.qte_alvo = noone;
if (instance_exists(alvo) and alvo.em_qte) with (alvo) em_qte = false;
