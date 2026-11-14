/* =====================================================================
   CONFIGURAÇÃO — tudo o que muda a cada versão fica aqui
   ===================================================================== */
const CONFIG = {
  versao: "Beta 0.5.2",
  android: { url: "downloads/TheCurseOfVallack-Beta0.5.2-Android.apk", info: "Beta 0.5.2 · Instalador APK · Android 7 ou mais novo" },
  windows: { url: "downloads/TheCurseOfVallack-Beta0.5.2-Windows-Setup.exe", info: "Beta 0.5.2 · Instalador para Windows 10 e 11 (64 bits)" },
  // Etiqueta "ATUALIZAÇÃO DISPONÍVEL" e a lista de novidades do celular (vazio = sem etiqueta)
  novidades: {
    titulo: "NOVIDADES DA 0.5.2",
    itens: [
      "Cores de Twilight corrigidas no celular e no PC: parado, correndo, andando, combos e escalada com o mesmo vermelho da armadura",
      "Da 0.5.1: jogo bem mais fácil nos níveis Fácil, Médio e Difícil",
      "Inimigos e chefes com menos vida; menos dano em Twilight",
      "Mais tempo entre os ataques e só um inimigo ataca por vez no Médio",
      "Baús curam mais e a sequência de golpes dá mais tempo",
      "Modo Extremo continua com o desafio original"
    ]
  },
  // Endereço do banco de comentários (Firebase Realtime Database), sem barra no fim.
  // Vazio = os comentários ficam só no aparelho de quem escreve.
  comentariosUrl: "https://the-curse-of-vallack-default-rtdb.firebaseio.com"
};

// No GitHub Pages (usuario.github.io/repositorio) os instaladores vêm da Release mais
// recente do mesmo repositório: os arquivos anexados lá precisam ter estes mesmos nomes.
(() => {
  const m = location.hostname.match(/^([a-z0-9-]+)\.github\.io$/i);
  if (!m) return;
  const repo = location.pathname.split("/").filter(Boolean)[0] || location.hostname;
  const base = `https://github.com/${m[1]}/${repo}/releases/latest/download/`;
  for (const k of ["android", "windows"]) CONFIG[k].url = base + CONFIG[k].url.split("/").pop();
})();

const $ = (s, r = document) => r.querySelector(s);
const cria = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };

document.querySelectorAll("[data-versao]").forEach(e => e.textContent = e.classList.contains("selo") ? CONFIG.versao.toUpperCase() : CONFIG.versao);
document.querySelectorAll("[data-baixar]").forEach(a => {
  const p = CONFIG[a.dataset.baixar];
  if (a.closest(".pacote")) { a.href = p.url; a.setAttribute("download", ""); }
});
$("#infoAndroid").textContent = CONFIG.android.info;
(() => {
  const n = CONFIG.novidades, box = $("#novidades");
  if (!n || !n.itens || !n.itens.length) { box.remove(); document.querySelectorAll("[data-atualizacao]").forEach(e => e.remove()); return; }
  const ul = cria("ul"); n.itens.forEach(t => ul.appendChild(cria("li", "", t)));
  box.append(cria("b", "", n.titulo), ul);
})();
$("#infoWindows").textContent = CONFIG.windows.info;

/* ---------- menu do celular ---------- */
const menu = $("#menu"), menuBtn = $("#menuBtn");
menuBtn.addEventListener("click", () => { const a = menu.classList.toggle("aberto"); menuBtn.setAttribute("aria-expanded", a); });
menu.addEventListener("click", e => { if (e.target.tagName === "A") { menu.classList.remove("aberto"); menuBtn.setAttribute("aria-expanded", false); } });

/* ---------- brasas do topo ---------- */
(() => {
  const c = $("#brasas"), x = c.getContext("2d");
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  let w, h, ps = [];
  const mede = () => { w = c.width = c.offsetWidth; h = c.height = c.offsetHeight; };
  const nova = (emBaixo) => ({ x: Math.random() * w, y: emBaixo ? h + 8 : Math.random() * h, r: 0.8 + Math.random() * 2.2, vy: 0.3 + Math.random() * 1.1, vx: -0.3 + Math.random() * 0.6, a: 0.3 + Math.random() * 0.7, f: Math.random() * 6.28 });
  mede(); addEventListener("resize", mede);
  for (let i = 0; i < Math.min(90, Math.round(w / 14)); i++) ps.push(nova(false));
  let visivel = true;
  new IntersectionObserver(e => visivel = e[0].isIntersecting).observe(c);
  (function passo(t) {
    requestAnimationFrame(passo);
    if (!visivel) return;
    x.clearRect(0, 0, w, h);
    for (const p of ps) {
      p.y -= p.vy; p.x += p.vx + Math.sin(t / 700 + p.f) * 0.3;
      if (p.y < -10) Object.assign(p, nova(true));
      x.globalAlpha = p.a * Math.min(1, p.y / (h * 0.6));
      x.fillStyle = p.r > 2 ? "#ffb060" : "#ff6a2c";
      x.beginPath(); x.arc(p.x, p.y, p.r, 0, 6.283); x.fill();
    }
  })(0);
})();

/* ---------- prólogo ---------- */
const CENAS = [
  "Há mais de duzentos anos, o mundo conheceu uma criatura que nenhum exército era capaz de derrotar.",
  "Seu nome era Valack Britus, o Rei dos Dragões. Seu corpo carregava uma força ancestral, anterior aos próprios reinos humanos.",
  "Onde Valack passava, florestas desapareciam e cidades viravam ruínas. Reis, magos e cavaleiros tentaram enfrentá-lo... Todos falharam.",
  "Até que surgiu um homem: Darius VI. Ele reuniu guerreiros de diferentes raças, conhecidos depois como Os Cinco da Aurora. Entre eles, um misterioso cavaleiro elfo.",
  "Depois de anos de batalhas, Darius e seus companheiros finalmente encontraram Valack. A batalha durou sete dias.",
  "No último dia, Darius estava de joelhos, ferido e com a espada quebrada. Valack, pronto para o golpe final, rugiu: \"Você não pode me matar, humano... Eu existirei depois do seu reino.\"",
  "\"Estamos dando ao mundo mais duzentos anos.\" A magia explodiu e correntes de energia envolveram o dragão. Valack rugiu: \"EU VOLTAREI!\" E Darius respondeu: \"Então estaremos esperando.\" O dragão foi selado.",
  "E Darius VI desapareceu. A paz voltou ao mundo, mas ninguém percebeu: o selo não estava ficando mais forte, estava envelhecendo. O que fora criado para proteger virou algo muito pior. Uma maldição. A Maldição de Vallack.",
  "200 anos depois... A maldição começou a se espalhar. A jornada para quebrar o selo envelhecido começa agora."
];
(() => {
  const palco = $("#palco"), pontos = $("#pontos"), leg = $("#legenda"), btnAuto = $("#auto");
  let i = 0, timer = null;
  const imgs = CENAS.map((t, k) => { const im = cria("img"); im.src = `img/prologo_${k + 1}.jpg`; im.alt = t; im.loading = k ? "lazy" : "eager"; palco.insertBefore(im, palco.firstChild); return im; });
  const bts = CENAS.map((_, k) => { const b = cria("button"); b.setAttribute("aria-label", `Cena ${k + 1}`); b.onclick = () => vai(k, true); pontos.appendChild(b); return b; });
  function vai(k, manual) {
    i = (k + CENAS.length) % CENAS.length;
    imgs.forEach((im, n) => im.classList.toggle("ativa", n === i));
    bts.forEach((b, n) => b.classList.toggle("ativo", n === i));
    leg.innerHTML = ""; leg.append(cria("b", "", `CENA ${i + 1} DE ${CENAS.length}`), document.createTextNode(CENAS[i]));
    if (manual) para();
  }
  function para() { clearInterval(timer); timer = null; btnAuto.textContent = "▶ PASSAR SOZINHO"; }
  $("#ant").onclick = () => vai(i - 1, true);
  $("#prox").onclick = () => vai(i + 1, true);
  btnAuto.onclick = () => { if (timer) return para(); btnAuto.textContent = "❚❚ PAUSAR"; timer = setInterval(() => vai(i + 1), 6500); };
  palco.addEventListener("keydown", e => { if (e.key === "ArrowLeft") vai(i - 1, true); if (e.key === "ArrowRight") vai(i + 1, true); });
  let x0 = null;
  palco.addEventListener("touchstart", e => x0 = e.touches[0].clientX, { passive: true });
  palco.addEventListener("touchend", e => { if (x0 == null) return; const d = e.changedTouches[0].clientX - x0; if (Math.abs(d) > 40) vai(i + (d < 0 ? 1 : -1), true); x0 = null; });
  vai(0);
})();

/* ---------- lightbox ---------- */
const luz = $("#luz");
function abrirLuz(src, tit, txt) { $("#luzImg").src = src; $("#luzImg").alt = tit; $("#luzTit").textContent = tit; $("#luzTxt").textContent = txt || ""; luz.classList.add("aberta"); $("#fechar").focus(); }
function fecharLuz() { luz.classList.remove("aberta"); }
$("#fechar").onclick = fecharLuz;
luz.addEventListener("click", e => { if (e.target === luz) fecharLuz(); });
addEventListener("keydown", e => { if (e.key === "Escape") fecharLuz(); });

/* ---------- bestiário ---------- */
const BESTAS = [
  ["besta", "Besta", "inimigo", "Os javalis de guerra da maldição. Atacam em carga pelas ruas da vila."],
  ["besta_escudeira", "Besta Escudeira", "inimigo", "Avança atrás do escudo. É preciso quebrar a guarda ou achar a brecha."],
  ["esqueleto", "Esqueleto Guerreiro", "inimigo", "\"Ossos não morrem!\" Derrubado, ele pode se erguer de novo."],
  ["arqueiro", "Arqueiro Esqueleto", "inimigo", "Fica no alto das torres de vigia e cobre a rua de flechas."],
  ["aranha", "Mulher-Aranha", "inimigo", "Espreita perto do abismo da estrada e prende quem chega perto demais."],
  ["estatua", "Estátua Enfeitiçada", "inimigo", "Parece parte do cenário, até a maldição acordá-la."],
  ["porco", "Homem-Porco", "inimigo", "O Porco Corrompido. Bruto, pesado e difícil de derrubar."],
  ["carrasco", "O Carrasco de Vallack", "chefe", "O mini-chefe do Capítulo I. Fecha a arena no meio da vila e só um dos dois sai."],
  ["arvore", "A Árvore Amaldiçoada", "chefe", "A chefe que guarda a estrada do castelo. Invoca servos e faz chover fogo."]
];
(() => {
  const g = $("#bestas");
  BESTAS.forEach(([arq, nome, tipo, txt]) => {
    const b = cria("button", "besta revela"); b.dataset.t = tipo;
    const im = cria("img"); im.src = `img/${arq}.png`; im.alt = nome; im.loading = "lazy";
    b.append(im, cria("em", tipo === "chefe" ? "chefe" : "", tipo === "chefe" ? "CHEFE" : "INIMIGO"), cria("span", "", nome));
    b.onclick = () => abrirLuz(im.src, nome, txt);
    g.appendChild(b);
  });
  $("#filtros").addEventListener("click", e => {
    const f = e.target.dataset.f; if (!f) return;
    document.querySelectorAll("#filtros button").forEach(b => b.classList.toggle("ativo", b === e.target));
    g.querySelectorAll(".besta").forEach(b => b.hidden = f !== "todos" && b.dataset.t !== f);
  });
})();

/* ---------- galeria ---------- */
const TELAS = [
  ["vila", "A vila em chamas", "O cenário do Capítulo I: casas ardendo na chama roxa da maldição."],
  ["tela_combate", "Combate", "Golpe crítico em sequência contra as bestas, com a câmera fechada no duelo."],
  ["tela_ponte_madeira", "A ponte de madeira", "Ela desaba atrás de Twilight. Quem para, cai junto."],
  ["tela_ponte_pedra", "A ponte de pedra", "Os arcos caem um a um sobre o abismo."],
  ["tela_hud", "Controles de toque", "A HUD no celular no modo 4 dedos."],
  ["tela_editor_hud", "Editor da HUD", "Arraste cada botão para onde quiser e escolha o tamanho."],
  ["tela_menu", "Menu inicial", "O menu do jogo."],
  ["twilight", "Twilight Vetrus", "O herói e a Lâmina de Sylla."]
];
(() => {
  const g = $("#telas");
  TELAS.forEach(([arq, nome, txt]) => {
    const b = cria("button", "revela"); const im = cria("img"); im.src = `img/${arq}.png`; im.alt = nome; im.loading = "lazy";
    b.append(im, cria("span", "", nome)); b.onclick = () => abrirLuz(im.src, nome, txt); g.appendChild(b);
  });
})();

/* ---------- mapa ---------- */
const CAPITULOS = [
  ["A CAMINHO DO CASTELO", "A vila de Twilight arde na maldição de Vallack. Atravesse as ruas em chamas, enfrente o Carrasco e derrube a Árvore Amaldiçoada que guarda a estrada."],
  ["O SALÃO REAL EM RUÍNAS", "No coração do castelo, a maldição aguarda. O salão do rei virou ninho de monstros."],
  ["AS MURALHAS DE VALLACK", "As muralhas tomadas por esqueletos e arqueiros. Escale as torres sob a chuva de flechas."],
  ["O PÂNTANO DOS AFOGADOS", "Névoa venenosa e almas presas na lama. Nada sob a água está realmente morto."],
  ["A FLORESTA DE ESPINHOS", "Árvores que sangram e raízes que caçam. Dizem que a maldição nasceu aqui."],
  ["AS MINAS DE CINZA", "Túneis de carvão em brasa, onde os mineiros nunca pararam de cavar."],
  ["A CATEDRAL PARTIDA", "Vitrais quebrados e um coro de mortos. A fé de Vallack virou pó."],
  ["O CEMITÉRIO DOS REIS", "Tumbas abertas e reis sem descanso, ainda de coroa."],
  ["A PONTE DO ABISMO", "Uma ponte de correntes sobre o nada. Cada passo acorda o que mora embaixo."],
  ["AS TERRAS QUEIMADAS", "Campos de batalha que ainda ardem. O vento traz os gritos de guerras antigas."],
  ["A FORJA DOS CONDENADOS", "Ferreiros acorrentados forjam, dia e noite, as armas da maldição."],
  ["O LAGO DE GELO NEGRO", "Gelo escuro sobre um lago sem fundo. Os afogados olham de baixo."],
  ["A TORRE DO ALQUIMISTA", "Frascos, venenos e experimentos que escaparam das jaulas."],
  ["O LABIRINTO DE OSSOS", "Corredores erguidos com os restos de um exército inteiro."],
  ["O PORTO FANTASMA", "Navios sem tripulação atracados na névoa. Os sinos tocam sozinhos."],
  ["O SANTUÁRIO DE SYLLA", "O templo da chama sagrada, agora corrompida pela maldição."],
  ["O TRONO DE VALLACK", "O salão do rei que trouxe a maldição. Ele ainda espera."],
  ["O COVIL DO DRAGÃO", "Além do trono, sob o céu em chamas, o dragão de Vallack desperta. O chefão de toda a maldição."]
];
(() => {
  const romano = n => ["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII"][n];
  const g = $("#capitulos");
  CAPITULOS.forEach(([nome, txt], k) => {
    const d = cria("details", "cap revela" + (k === 0 ? " aberta" : "")); if (k === 0) d.open = true;
    const s = cria("summary"); s.append(cria("span", "num", romano(k)), cria("span", "", nome), cria("span", "estado", k === 0 ? "JOGÁVEL" : "🔒 EM DESENVOLVIMENTO"));
    d.append(s, cria("p", "", txt)); g.appendChild(d);
  });
})();

/* ---------- aparecer ao rolar ---------- */
(() => {
  const io = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add("visto"); io.unobserve(e.target); } }), { threshold: 0.08 });
  document.querySelectorAll(".revela").forEach(e => io.observe(e));
})();

/* =====================================================================
   COMENTÁRIOS: nome, estrelas, curtir e responder
   Com CONFIG.comentariosUrl preenchido, todos veem os mesmos comentários
   (Firebase Realtime Database pela API REST). Vazio: ficam só neste aparelho.
   ===================================================================== */
const Banco = (() => {
  const url = CONFIG.comentariosUrl.replace(/\/+$/, "");
  const CHAVE = "vallack_comentarios_v1";
  const lerLocal = () => { try { return JSON.parse(localStorage.getItem(CHAVE) || "{}"); } catch { return {}; } };
  const gravarLocal = d => { try { localStorage.setItem(CHAVE, JSON.stringify(d)); } catch {} };
  return {
    online: !!url,
    async listar() {
      if (!url) return lerLocal();
      const r = await fetch(`${url}/comentarios.json`); if (!r.ok) throw new Error("falha ao ler");
      return (await r.json()) || {};
    },
    async criar(c) {
      if (!url) { const d = lerLocal(); const id = "l" + Date.now().toString(36) + Math.random().toString(36).slice(2, 6); d[id] = c; gravarLocal(d); return id; }
      const r = await fetch(`${url}/comentarios.json`, { method: "POST", body: JSON.stringify(c) }); if (!r.ok) throw new Error("falha ao publicar");
      return (await r.json()).name;
    },
    async curtir(id, delta) {
      if (!url) { const d = lerLocal(); if (d[id]) { d[id].curtidas = Math.max(0, (d[id].curtidas || 0) + delta); gravarLocal(d); } return; }
      const r = await fetch(`${url}/comentarios/${encodeURIComponent(id)}/curtidas.json`, { method: "PUT", body: JSON.stringify({ ".sv": { increment: delta } }) });
      if (!r.ok) throw new Error("falha ao curtir");
    }
  };
})();

(() => {
  const guarda = { get: (k, p) => { try { return JSON.parse(localStorage.getItem(k)) ?? p; } catch { return p; } }, set: (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch {} } };
  const lista = $("#lista"), form = $("#form"), nome = $("#nome"), texto = $("#texto"), erro = $("#erro"), escolhe = $("#escolhe"), ordem = $("#ordem");
  let dados = {}, nota = 0, curtidos = new Set(guarda.get("vallack_curtidos", []));
  nome.value = guarda.get("vallack_nome", "");

  const modo = $("#modo");
  if (!Banco.online) { modo.hidden = false; modo.textContent = "Modo local: os comentários que você escrever ficam salvos só neste aparelho. Eles passam a aparecer para todos quando o banco de comentários online for ligado."; }

  // estrelas do formulário
  for (let n = 1; n <= 5; n++) {
    const b = cria("button", "", "★"); b.type = "button"; b.setAttribute("role", "radio"); b.setAttribute("aria-label", `${n} estrela${n > 1 ? "s" : ""}`);
    b.onclick = () => { nota = n; pinta(); };
    escolhe.appendChild(b);
  }
  const pinta = () => [...escolhe.children].forEach((b, k) => { b.classList.toggle("on", k < nota); b.setAttribute("aria-checked", k + 1 === nota); });
  texto.addEventListener("input", () => $("#conta").textContent = `${texto.value.length} / 600`);

  const limpa = s => String(s || "").replace(/[\u0000-\u0008\u000B-\u001F]/g, "").trim();
  function valida(n, t, precisaNota) {
    if (n.length < 2) return "Escreva o seu nome de jogador (pelo menos 2 letras).";
    if (precisaNota && !nota) return "Escolha de 1 a 5 estrelas.";
    if (t.length < 3) return "Escreva o seu comentário.";
    return "";
  }
  const cor = n => { let h = 0; for (const ch of n) h = (h * 31 + ch.charCodeAt(0)) % 360; return `hsl(${h} 62% 62%)`; };
  const quando = ms => { const d = (Date.now() - ms) / 1000; if (d < 60) return "agora"; if (d < 3600) return `há ${Math.floor(d / 60)} min`; if (d < 86400) return `há ${Math.floor(d / 3600)} h`; if (d < 2592000) return `há ${Math.floor(d / 86400)} d`; return new Date(ms).toLocaleDateString("pt-BR"); };

  async function carrega() {
    try { dados = await Banco.listar(); } catch { dados = {}; lista.replaceChildren(cria("p", "vazio", "Não foi possível carregar os comentários agora. Tente de novo em instantes.")); return; }
    desenha();
  }

  function desenha() {
    const todos = Object.entries(dados).map(([id, c]) => ({ id, ...c })).filter(c => c && c.nome && c.texto);
    const pais = todos.filter(c => !c.pai);
    const notas = pais.filter(c => c.estrelas >= 1 && c.estrelas <= 5);
    // resumo
    if (notas.length) {
      const m = notas.reduce((s, c) => s + c.estrelas, 0) / notas.length;
      $("#media").textContent = m.toFixed(1).replace(".", ",");
      $("#mediaEstrelas").textContent = "★".repeat(Math.round(m)) + "☆".repeat(5 - Math.round(m));
      $("#total").textContent = `${notas.length} avaliaç${notas.length > 1 ? "ões" : "ão"}`;
    } else { $("#media").textContent = "–"; $("#mediaEstrelas").textContent = "☆☆☆☆☆"; $("#total").textContent = "Nenhuma avaliação ainda"; }
    const barras = $("#barras"); barras.replaceChildren();
    for (let n = 5; n >= 1; n--) {
      const q = notas.filter(c => c.estrelas === n).length;
      const l = cria("div"); const i = cria("i"); const u = cria("u"); u.style.width = (notas.length ? q / notas.length * 100 : 0) + "%"; i.appendChild(u);
      l.append(cria("span", "", `${n} ★`), i, cria("span", "", String(q))); barras.appendChild(l);
    }
    // lista
    const o = ordem.value;
    pais.sort((a, b) => o === "curtidos" ? (b.curtidas || 0) - (a.curtidas || 0) || b.data - a.data : o === "nota" ? (b.estrelas || 0) - (a.estrelas || 0) || b.data - a.data : b.data - a.data);
    lista.replaceChildren();
    if (!pais.length) { lista.appendChild(cria("p", "vazio", "Seja o primeiro a comentar.")); return; }
    pais.forEach(p => {
      const el = cartao(p, p.id);
      const rs = todos.filter(c => c.pai === p.id).sort((a, b) => a.data - b.data);
      if (rs.length) { const box = cria("div", "respostas"); rs.forEach(r => box.appendChild(cartao(r, p.id))); el.appendChild(box); }
      lista.appendChild(el);
    });
  }

  function cartao(c, idPai) {
    const el = cria("article", "com");
    const cab = cria("div", "cab");
    const av = cria("span", "avatar", c.nome.trim()[0].toUpperCase()); av.style.background = cor(c.nome);
    cab.append(av, cria("span", "nome", c.nome));
    if (!c.pai && c.estrelas) { const e = cria("span", "estrelas", "★".repeat(c.estrelas) + "☆".repeat(5 - c.estrelas)); e.setAttribute("aria-label", `${c.estrelas} de 5 estrelas`); cab.appendChild(e); }
    cab.appendChild(cria("span", "quando", quando(c.data)));
    const acoes = cria("div", "acoes");
    const bc = cria("button", curtidos.has(c.id) ? "curtido" : "", `♥ ${c.curtidas || 0}`); bc.setAttribute("aria-pressed", curtidos.has(c.id)); bc.setAttribute("aria-label", "Curtir comentário");
    bc.onclick = async () => {
      const tinha = curtidos.has(c.id), delta = tinha ? -1 : 1;
      bc.disabled = true;
      try { await Banco.curtir(c.id, delta); tinha ? curtidos.delete(c.id) : curtidos.add(c.id); guarda.set("vallack_curtidos", [...curtidos]); dados[c.id].curtidas = Math.max(0, (dados[c.id].curtidas || 0) + delta); desenha(); }
      catch { bc.disabled = false; }
    };
    const br = cria("button", "", "↩ Responder");
    br.onclick = () => {
      if (el.querySelector(".resp-form")) { el.querySelector(".resp-form").remove(); return; }
      const f = cria("form", "resp-form"); const ta = cria("textarea"); ta.maxLength = 600; ta.placeholder = `Responder a ${c.nome}`; ta.setAttribute("aria-label", `Responder a ${c.nome}`);
      if (c.pai) ta.value = `@${c.nome} `;
      const li = cria("div", "linha"); const er = cria("span", "erro"); const ok = cria("button", "enviar", "RESPONDER"); ok.type = "submit"; li.append(er, ok);
      f.className = "resp-form form"; f.append(ta, li);
      f.onsubmit = async ev => {
        ev.preventDefault();
        const n = limpa(nome.value).slice(0, 24), t = limpa(ta.value).slice(0, 600), msg = valida(n, t, false);
        if (msg) { er.textContent = msg; if (n.length < 2) nome.focus(); return; }
        ok.disabled = true;
        try { const novo = { nome: n, texto: t, estrelas: 0, pai: idPai, data: Date.now(), curtidas: 0 }; const id = await Banco.criar(novo); dados[id] = novo; guarda.set("vallack_nome", n); desenha(); }
        catch { er.textContent = "Não foi possível publicar. Tente de novo."; ok.disabled = false; }
      };
      el.insertBefore(f, el.querySelector(".respostas")); ta.focus();
    };
    acoes.append(bc, br);
    el.append(cab, cria("p", "txt", c.texto), acoes);
    return el;
  }

  form.addEventListener("submit", async ev => {
    ev.preventDefault();
    const n = limpa(nome.value).slice(0, 24), t = limpa(texto.value).slice(0, 600), msg = valida(n, t, true);
    erro.textContent = msg; if (msg) { if (n.length < 2) nome.focus(); return; }
    const bt = form.querySelector(".enviar"); bt.disabled = true;
    try {
      const novo = { nome: n, texto: t, estrelas: nota, pai: "", data: Date.now(), curtidas: 0 };
      const id = await Banco.criar(novo); dados[id] = novo; guarda.set("vallack_nome", n);
      texto.value = ""; nota = 0; pinta(); $("#conta").textContent = "0 / 600"; desenha();
    } catch { erro.textContent = "Não foi possível publicar. Tente de novo."; }
    bt.disabled = false;
  });
  ordem.addEventListener("change", desenha);
  carrega();
})();
