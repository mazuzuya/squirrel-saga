export function createUI(mount) {
  const shell = document.createElement("section");
  shell.className = "game-shell";
  shell.innerHTML = `
    <header class="hud-row game-hud">
      <div class="badge area-badge"><span class="area-index">01</span><span class="area-name">Oak Canopy</span></div>
      <div class="hud-center">
        <div class="pip-row hearts" aria-label="Nyawa"></div>
        <div class="stamina-track" aria-label="Stamina"><i></i></div>
      </div>
      <div class="hud-right">
        <div class="badge key-badge"><b>◆</b><span>0/2</span></div>
        <div class="badge timer-badge" hidden>95</div>
        <button class="icon-btn pause-btn" type="button" aria-label="Jeda">Ⅱ</button>
      </div>
    </header>
    <div class="game-stage">
      <canvas class="game-surface" aria-label="Petualangan Luma"></canvas>
      <div class="loading-panel"><span class="loading-acorn">◆</span><strong>Menumbuhkan Yggdrasil…</strong></div>
      <div class="game-toast" hidden></div>
      <div class="overlay pause-overlay" hidden>
        <div class="overlay-panel">
          <h2>Perjalanan Dijeda</h2>
          <div class="area-select" aria-label="Pilih area"></div>
          <h3 class="skin-heading">Skin & Buff</h3>
          <div class="skin-select" aria-label="Pilih skin"></div>
          <div class="overlay-actions">
            <button class="menu-btn resume-btn" type="button"><span class="control-label">Lanjut</span></button>
            <button class="menu-btn retry-btn" type="button"><span class="control-label">Ulang Checkpoint</span></button>
            <button class="menu-btn sound-btn" type="button"><span class="control-label">Suara: Aktif</span></button>
          </div>
        </div>
      </div>
      <div class="overlay result-overlay" hidden>
        <div class="overlay-panel result-panel">
          <div class="result-rune">◆</div>
          <h2>Portal Pulih!</h2>
          <p></p>
          <button class="menu-btn next-btn" type="button"><span class="control-label">Area Berikutnya</span></button>
        </div>
      </div>
      <div class="overlay error-overlay" hidden>
        <div class="overlay-panel"><h2>Yggdrasil tertidur</h2><p>Aset dunia belum berhasil dimuat.</p><button class="menu-btn reload-btn" type="button"><span class="control-label">Coba Lagi</span></button></div>
      </div>
    </div>
    <footer class="controls-row game-controls">
      <div class="control-cluster move-controls">
        <button class="control-btn round-btn" data-control="left" type="button" aria-label="Kiri">◀</button>
        <button class="control-btn round-btn" data-control="right" type="button" aria-label="Kanan">▶</button>
      </div>
      <div class="control-cluster action-controls">
        <button class="control-btn action-btn context-btn" data-control="action" type="button"><span class="control-label">AKSI</span></button>
        <button class="control-btn action-btn attack-btn" data-control="attack" type="button"><span class="control-label">EKOR</span></button>
        <button class="control-btn jump-btn" data-control="jump" type="button"><span class="control-label">LOMPAT</span></button>
      </div>
    </footer>`;
  mount.replaceChildren(shell);

  const q = (selector) => shell.querySelector(selector);
  const canvas = q("canvas"); const toast = q(".game-toast");
  const hearts = q(".hearts"); const stamina = q(".stamina-track i");
  let toastTimer = 0;

  function setHearts(value, maximum = 3) {
    hearts.replaceChildren(...Array.from({ length: maximum }, (_, index) => {
      const pip = document.createElement("i"); pip.className = `pip heart-pip${index < value ? " is-full" : ""}`; return pip;
    }));
  }
  setHearts(3);

  function update(state) {
    q(".area-index").textContent = String(state.areaIndex + 1).padStart(2, "0");
    q(".area-name").textContent = state.area.name;
    q(".key-badge span").textContent = `${state.collected}/${state.area.required}`;
    q(".key-badge").classList.toggle("is-complete", state.collected >= state.area.required);
    setHearts(state.player.hearts, state.player.maxHearts || 3);
    stamina.style.width = `${Math.max(0, Math.min(100, state.player.stamina))}%`;
    const timer = q(".timer-badge");
    timer.hidden = !state.area.timeLimit;
    if (state.area.timeLimit) {
      timer.textContent = `${Math.max(0, Math.ceil(state.timeLeft))}`;
      timer.classList.toggle("is-danger", state.timeLeft < 20);
    }
  }

  function hint(text, duration = 2600) {
    clearTimeout(toastTimer); toast.textContent = text; toast.hidden = false;
    toastTimer = window.setTimeout(() => { toast.hidden = true; }, duration);
  }

  function buildAreaSelect(totalAreas, unlocked, current, onSelect) {
    const container = q(".area-select"); container.replaceChildren();
    for (let index = 0; index < totalAreas; index += 1) {
      const button = document.createElement("button"); button.type = "button"; button.textContent = index + 1;
      button.disabled = index > unlocked; button.className = index === current ? "is-current" : "";
      button.addEventListener("click", () => onSelect(index)); container.append(button);
    }
  }

  function buildSkinSelect(skins, selected, onSelect) {
    const container = q(".skin-select"); container.replaceChildren();
    skins.forEach((skin) => {
      const button = document.createElement("button"); button.type = "button";
      button.className = skin.id === selected ? "skin-option is-current" : "skin-option";
      button.style.setProperty("--skin-color", skin.color);
      button.innerHTML = `<b>${skin.name}</b><small>${skin.buff}</small>`;
      button.addEventListener("click", () => onSelect(skin.id)); container.append(button);
    });
  }

  return {
    shell, canvas,
    ready() { q(".loading-panel").hidden = true; },
    update, hint,
    showPause(value) { q(".pause-overlay").hidden = !value; },
    showResult({ victory = false, areaName, emblems, totalEmblems, totalPossible, score, seconds }) {
      const overlay = q(".result-overlay"); overlay.hidden = false;
      q(".result-panel h2").textContent = victory ? "Yggdrasil Terbangun!" : "Portal Pulih!";
      q(".result-panel p").textContent = victory ? `Waktu ${seconds} dtk • ${totalEmblems}/${totalPossible} Emblem • Skor ${score}` : `${areaName} • ${emblems}/3 Emblem Daun`;
      q(".next-btn .control-label").textContent = victory ? "Mainkan Lagi" : "Area Berikutnya";
    },
    hideResult() { q(".result-overlay").hidden = true; },
    showError() { q(".loading-panel").hidden = true; q(".error-overlay").hidden = false; },
    buildAreaSelect, buildSkinSelect,
    setSoundLabel(enabled) { q(".sound-btn .control-label").textContent = `Suara: ${enabled ? "Aktif" : "Mati"}`; },
    buttons: {
      pause: q(".pause-btn"), resume: q(".resume-btn"), retry: q(".retry-btn"), sound: q(".sound-btn"), next: q(".next-btn"), reload: q(".reload-btn"),
    },
    destroy() { clearTimeout(toastTimer); mount.replaceChildren(); },
  };
}
