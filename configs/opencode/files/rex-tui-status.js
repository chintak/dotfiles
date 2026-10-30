// opencode -> Rex agent status, over the Program Status Protocol (OSC 7501).
// Spec: https://www.superlogical.com/rex/docs (Program Status Protocol)
//
// A TUI plugin, not a server one: since opencode V2 the server is shared,
// so only the pane-local TUI knows which session this pane shows (same
// reason as herdr-tui-session.js). Each tick derives the state of the
// selected root session: blocked while it or a child has a pending
// permission or question, working while it runs, done once a run ends.
// Reports go to /dev/tty so they never mix into the TUI's own output.
// Outside Rex (no REX_BLOCK) it does nothing.

import { closeSync, openSync, writeSync } from "node:fs";

const POLL_MS = 250;

export default {
  id: "rex.opencode.status",
  setup,
};

function setup(api) {
  if (!process.env.REX_BLOCK) return;

  let tty;
  try {
    tty = openSync("/dev/tty", "w");
  } catch {
    return;
  }

  let selected;
  let ran = false;
  let last = "";

  function report(state, msg, kind) {
    const pairs = [`state=${state}`, "app=opencode"];
    if (kind) pairs.push(`kind=${kind}`);
    if (msg) {
      const line = String(msg).replace(/[\u0000-\u001f\u007f-\u009f]+/g, " ").trim().slice(0, 300);
      if (line) pairs.push(`msg=${Buffer.from(line).toString("base64")}`);
    }
    const seq = `\x1b]7501;${pairs.join(":")}\x1b\\`;
    if (seq === last) return;
    last = seq;
    try {
      writeSync(tty, seq);
    } catch {
      // The terminal went away; nothing left to report to.
    }
  }

  function root(id) {
    const seen = new Set();
    while (typeof id === "string" && !seen.has(id)) {
      seen.add(id);
      const session = api.data.session.get(id);
      if (!session) return;
      if (!session.parentID) return id;
      id = session.parentID;
    }
  }

  function blockedKind(id) {
    for (const member of [id, ...(api.data.session.family(id) ?? [])]) {
      if ((api.data.session.permission.list(member) ?? []).length) return "permission";
      if ((api.data.session.form.list(member) ?? []).length) return "question";
    }
  }

  function tick() {
    const route = api.ui.router.current();
    const id = route?.type === "session" ? root(route.sessionID) : undefined;
    if (id !== selected) {
      selected = id;
      ran = false;
    }
    if (!id) return report("idle");
    const title = api.data.session.get(id)?.title;
    const kind = blockedKind(id);
    if (kind) return report("blocked", title, kind);
    if (api.data.session.status(id) === "running") {
      ran = true;
      return report("working", title);
    }
    report(ran ? "done" : "idle", title);
  }

  const unsubscribe = api.data.listen(() => tick());
  const poll = setInterval(tick, POLL_MS);
  tick();

  return () => {
    clearInterval(poll);
    unsubscribe();
    try {
      writeSync(tty, "\x1b]7501;state=clear\x1b\\");
      closeSync(tty);
    } catch {
      // Already closed.
    }
  };
}
