# Changelog — com.telybot:telybot

## 2.0.0 — 2026-10-14

* **Client ids start with `tb_live_`.** Every key was renamed on the server (its random
  part kept), and a `kb_live_` id is now refused. Copy the new key from Install in the
  dashboard. A 1.0.0 app cannot take a `tb_live_` key, so it needs this release.
* Removes everything that was kept for apps built before 1.0.0: the deprecated class and
  package names, the older message names and the one-time move of an older install's reply
  list. Apart from the new key, an app already on 1.0.0 changes nothing.
* Needs a Telybot server that names its messages `telybot:…` (telybot.com does).

## 1.0.0 — 2026-10-13

* `implementation("com.github.telybotai:telybot-Sdks:v1.0.0")` (Maven `com.telybot:telybot`),
  package `com.telybot.sdk`: `TelyBot`, `TelyBot.Listener`, `TelyBotView`, `TelyBotActivity`.
* The chat full screen (`TelyBot.show`) or inside one of your own screens (`TelyBotView`),
  with a question already typed, your signed-in customer's details offered in its forms, and
  back closing a sheet before it leaves the chat.
* A reply the customer was waiting for, while the chat is closed: `onReply` and
  `hasUnreadReply`.
* The JavaScript bridge is `TelyBotNative`; the page's messages are `telybot:theme`,
  `telybot:sheets` and `telybot:waits`. The User-Agent mark is `TelyBot/1.0.0 (Android)`.

Versions before 1.0.0 were released under an earlier name; their notes are in the repository history.
