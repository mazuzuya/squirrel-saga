const CONTROL_MAP = {
  left: ["ArrowLeft", "KeyA"], right: ["ArrowRight", "KeyD"],
  jump: ["Space", "ArrowUp", "KeyW"], attack: ["KeyJ", "KeyX"], action: ["KeyE", "KeyK"],
};

export function createInput(shell) {
  const held = { left: false, right: false, jump: false, attack: false, action: false };
  const pressed = { jump: false, attack: false, action: false, pause: false };
  const listeners = [];

  const on = (target, type, handler, options) => {
    target.addEventListener(type, handler, options);
    listeners.push(() => target.removeEventListener(type, handler, options));
  };
  const setKey = (code, value, repeat = false) => {
    for (const [action, keys] of Object.entries(CONTROL_MAP)) {
      if (!keys.includes(code)) continue;
      if (value && !repeat && !held[action]) pressed[action] = true;
      held[action] = value;
    }
  };

  on(window, "keydown", (event) => {
    if (event.code === "Escape") pressed.pause = true;
    setKey(event.code, true, event.repeat);
    if (Object.values(CONTROL_MAP).flat().includes(event.code)) event.preventDefault();
  });
  on(window, "keyup", (event) => setKey(event.code, false));
  on(window, "blur", () => Object.keys(held).forEach((key) => { held[key] = false; }));

  shell.querySelectorAll("[data-control]").forEach((button) => {
    const action = button.dataset.control;
    const down = (event) => {
      event.preventDefault();
      button.setPointerCapture?.(event.pointerId);
      if (!held[action]) pressed[action] = true;
      held[action] = true;
      button.classList.add("is-held");
    };
    const up = (event) => {
      event.preventDefault();
      held[action] = false;
      button.classList.remove("is-held");
    };
    on(button, "pointerdown", down);
    on(button, "pointerup", up);
    on(button, "pointercancel", up);
    on(button, "lostpointercapture", up);
  });

  return {
    held,
    take(action) { const value = pressed[action]; pressed[action] = false; return value; },
    clearPressed() { Object.keys(pressed).forEach((key) => { pressed[key] = false; }); },
    destroy() { listeners.forEach((off) => off()); },
  };
}
