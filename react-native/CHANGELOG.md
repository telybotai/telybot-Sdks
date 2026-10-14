# Changelog — @telybot/react-native

## 2.0.0 — 2026-10-14

* **Client ids start with `tb_live_`.** Every key was renamed on the server (its random
  part kept), and a `kb_live_` id is now refused. Copy the new key from Install in the
  dashboard. A 1.0.0 app cannot take a `tb_live_` key, so it needs this release.
* Removes everything that was kept for apps built before 1.0.0: the older message names and
  the one-time move of an older install's reply list. Apart from the new key, an app already on 1.0.0 changes nothing.
* Needs a Telybot server that names its messages `telybot:…` (telybot.com does).

## 1.0.0 — 2026-10-13

* `npm install @telybot/react-native react-native-webview`. Components and hooks `TelyBot`,
  `TelyBotChat`, `useTelyBot`, `useTelyBotReplies`; types `TelyBot…`.
* The chat as a modal (`<TelyBot />`) or inside one of your own screens (`<TelyBotChat />`),
  with a question already typed, your signed-in customer's details offered in its forms, and
  Android back closing a sheet before it leaves the chat.
* A reply the customer was waiting for, while the chat is closed: `useTelyBotReplies`.
* The page's messages are `telybot:theme`, `telybot:sheets` and `telybot:waits`, and back is
  answered as `telybot:back`. The User-Agent mark is `TelyBot/1.0.0 (ReactNative)`.

Versions before 1.0.0 were released under an earlier name; their notes are in the repository history.
