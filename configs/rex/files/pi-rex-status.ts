// pi -> Rex agent status, over the Program Status Protocol (OSC 7501).
// Spec: https://www.superlogical.com/rex/docs (Program Status Protocol)
//
// Rex shows the record in tab headers and the session picker, and the
// agent switcher in init.lua lists it. Mirrors herdr's pi integration:
// working while the agent runs, done when it settles, blocked while any
// extension signals one (herdr's `herdr:blocked` bus event or `rex:blocked`,
// both { active, label }). Outside Rex (no REX_BLOCK) it does nothing.
//
// Rex drops a pane's status when the program marks a new prompt (OSC 133;A),
// and pi does that on every turn, so the report is resent every second
// while the agent runs. Only then: each resend refreshes the record's
// updated_at, which the switcher sorts by recency.
// @ts-nocheck

import { closeSync, openSync, writeSync } from "node:fs";

type State = "idle" | "working" | "done" | "blocked" | "clear";

const RESEND_MS = 1000;

// Reports go to the controlling terminal, not stdout, so they never mix
// into pi's own rendering.
let tty: number | undefined;

function oneLine(text: string): string {
  return text.replace(/[\u0000-\u001f\u007f-\u009f]+/g, " ").trim().slice(0, 300);
}

function report(state: State, msg?: string, kind?: string): void {
  if (tty === undefined) {
    try {
      tty = openSync("/dev/tty", "w");
    } catch {
      tty = -1;
    }
  }
  if (tty < 0) return;
  const pairs = [`state=${state}`, "app=pi"];
  if (kind) pairs.push(`kind=${kind}`);
  if (msg) pairs.push(`msg=${Buffer.from(oneLine(msg)).toString("base64")}`);
  try {
    writeSync(tty, `\x1b]7501;${pairs.join(":")}\x1b\\`);
  } catch {
    // The terminal went away; nothing left to report to.
  }
}

export default function (pi) {
  if (!process.env.REX_BLOCK) return;

  let tui = false;
  let active = false;
  let ran = false;
  let prompt: string | undefined;
  const blockers: string[] = [];

  function publish() {
    if (!tui) return;
    if (blockers.length > 0) report("blocked", blockers[blockers.length - 1], "question");
    else if (active) report("working", prompt);
    else if (ran) report("done", prompt);
    else report("idle");
  }

  function onBlocked(data) {
    if (data?.active) blockers.push(typeof data.label === "string" ? data.label : "Waiting for you");
    else blockers.pop();
    publish();
  }
  pi.events.on("herdr:blocked", onBlocked);
  pi.events.on("rex:blocked", onBlocked);

  let resend;
  pi.on("session_start", (_event, ctx) => {
    // Headless modes (rpc, json, print) have no pane to report for.
    if (ctx?.mode !== "tui") return;
    tui = true;
    active = ctx?.isIdle?.() === false;
    publish();
    resend ??= setInterval(() => active && publish(), RESEND_MS);
    resend.unref?.();
  });

  pi.on("before_agent_start", (event) => {
    if (typeof event?.prompt === "string" && event.prompt.trim()) prompt = event.prompt;
  });

  pi.on("agent_start", () => {
    active = true;
    ran = true;
    publish();
  });

  pi.on("agent_settled", (_event, ctx) => {
    if (ctx?.isIdle?.() !== true) return;
    active = false;
    publish();
  });

  pi.on("session_shutdown", () => {
    if (!tui) return;
    clearInterval(resend);
    resend = undefined;
    report("clear");
    if (tty !== undefined && tty >= 0) closeSync(tty);
    tty = undefined;
  });
}
