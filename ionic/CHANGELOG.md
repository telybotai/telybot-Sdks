# Changelog — @telybot/capacitor

## 2.0.0 — 2026-10-14

* **Client ids start with `tb_live_`.** Every key was renamed on the server (its random
  part kept), and a `kb_live_` id is now refused. Copy the new key from Install in the
  dashboard. A 1.0.0 app cannot take a `tb_live_` key, so it needs this release.
* Removes what was kept for apps built before 1.0.0: an older copy's script tag is no longer
  recognised, and the embedded widget is read from `window.TelyBot` only. An app already on
  1.0.0 changes nothing.

## 1.0.0 — 2026-10-13

* `npm install @telybot/capacitor`; `TelyBot` (also the default export), `TelyBotOptions`,
  `TelyBotVisitor`. Console messages start `[TelyBot]`.
* The chat full screen in the system browser (`TelyBot.open`), with a question already typed,
  or embedded in your own web view (`embedWidget`, `getEmbeddedWidget`), where your
  signed-in customer's details can be offered with `setVisitor`.

Versions before 1.0.0 were released under an earlier name; their notes are in the repository history.
