export async function createAudio(sdk) {
  let managed;
  let musicTimer = 0;
  let nextNote = 0;
  let step = 0;
  let enabled = true;

  try { managed = await sdk.audio.getContext(); } catch { managed = null; }
  const context = () => managed?.context;

  function tone(frequency, duration = 0.08, type = "square", volume = 0.05, delay = 0) {
    const ctx = context();
    if (!enabled || !ctx || ctx.state !== "running") return;
    const start = ctx.currentTime + delay;
    const oscillator = ctx.createOscillator();
    const gain = ctx.createGain();
    oscillator.type = type;
    oscillator.frequency.setValueAtTime(frequency, start);
    gain.gain.setValueAtTime(volume, start);
    gain.gain.exponentialRampToValueAtTime(0.001, start + duration);
    oscillator.connect(gain).connect(ctx.destination);
    oscillator.start(start); oscillator.stop(start + duration);
  }

  function startMusic() {
    const ctx = context();
    if (!enabled || !ctx || ctx.state !== "running" || musicTimer) return;
    nextNote = ctx.currentTime + 0.05;
    const notes = [261.63, 329.63, 392, 523.25, 392, 329.63, 293.66, 440];
    musicTimer = window.setInterval(() => {
      if (!enabled || ctx.state !== "running") return;
      while (nextNote < ctx.currentTime + 0.2) {
        tone(notes[step % notes.length], 0.32, "triangle", 0.018, Math.max(0, nextNote - ctx.currentTime));
        if (step % 4 === 0) tone(notes[step % notes.length] / 2, 0.6, "sine", 0.012, Math.max(0, nextNote - ctx.currentTime));
        step += 1; nextNote += 0.34;
      }
    }, 100);
  }

  return {
    async unlock() { try { await managed?.unlock(); startMusic(); } catch { /* silent fallback */ } },
    setEnabled(value) { enabled = value; if (enabled) startMusic(); },
    play(name) {
      if (name === "jump") { tone(310, 0.08, "square", 0.045); tone(510, 0.1, "triangle", 0.03, 0.05); }
      else if (name === "hit") { tone(95, 0.12, "square", 0.07); tone(170, 0.05, "sawtooth", 0.035); }
      else if (name === "key") { tone(660, 0.1, "triangle", 0.045); tone(880, 0.16, "triangle", 0.04, 0.08); }
      else if (name === "portal") { [330, 440, 660, 880].forEach((n, i) => tone(n, 0.42, "triangle", 0.04, i * 0.09)); }
      else if (name === "hurt") { tone(145, 0.18, "sawtooth", 0.045); }
      else if (name === "bounce") { tone(220, 0.08, "square", 0.04); tone(520, 0.12, "triangle", 0.035, 0.06); }
    },
    async destroy() { if (musicTimer) clearInterval(musicTimer); await managed?.dispose?.(); },
  };
}
