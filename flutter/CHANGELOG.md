# Changelog

## 2.0.0 — unreleased

* Removes everything that was kept for apps built before 1.0.0: the older message names and
  the one-time move of an older install's reply list. An app already on 1.0.0 changes
  nothing.
* Needs a Telybot server that names its messages `telybot:…` (telybot.com does).

## 1.0.0 — 2026-10-13

* `flutter pub add telybot`, then `import 'package:telybot/telybot.dart';`. Classes `TelyBot`,
  `TelyBotChat`, `TelyBotConfigError`, `TelyBotExternalLinkHandler`, `kTelyBotDefaultBaseUrl`.
* The chat full screen (`TelyBot.show`) or inside one of your own screens (`TelyBotChat`),
  with a question already typed, your signed-in customer's details offered in its forms, and
  Android back closing a sheet before it leaves the chat.
* A reply the customer was waiting for, while the chat is closed: `TelyBot.hasUnreadReply`
  and `TelyBot.onReply`.
* The JavaScript channel is `TelyBotFlutter`; the page's messages are `telybot:theme`,
  `telybot:sheets` and `telybot:waits`. The User-Agent mark is `TelyBot/1.0.0 (Flutter)`.

Versions before 1.0.0 were released under an earlier name; their notes are in the repository history.
