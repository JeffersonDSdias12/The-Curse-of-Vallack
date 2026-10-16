// =====================================================================
//  obj_espinhos — espinhos que saem do chão em ciclos
//  baixo -> aviso (tremem e soltam poeira) -> alto (ferem) -> descendo
// =====================================================================
sprite_index = spr_espinhos;
image_speed = 0;
estado = "baixo";
t = (x mod 97);            // espinhos vizinhos não sobem juntos
sobe = 0;                  // 0..1
atingidos = [];
