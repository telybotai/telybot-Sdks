# Changelog — TelyBot (iOS)

## 2.0.0 — unreleased

* Removes everything that was kept for apps built before 1.0.0: the deprecated second
  product and its type names, the older message names and the one-time move of an older
  install's reply list. An app already on 1.0.0 changes nothing.
* Needs a Telybot server that names its messages `telybot:…` (telybot.com does).

## 1.0.0 — 2026-10-13

* Swift Package Manager: product `TelyBot` (`import TelyBot`) from
  `https://github.com/telybotai/telybot-Sdks`, package `telybot-sdks`. CocoaPods:
  `pod 'TelyBot', :podspec => 'https://raw.githubusercontent.com/telybotai/telybot-Sdks/v1.0.0/TelyBot.podspec'`.
* The chat as a sheet (`TelyBot.show`), as a view controller of your own
  (`TelyBot.makeChatViewController`) or in SwiftUI (`TelyBotView`, `.telyBot(isPresented:question:)`),
  with a question already typed and your signed-in customer's details offered in its forms.
* A reply the customer was waiting for, while the chat is closed: `onReply` and
  `hasUnreadReply`.
* The script message handler is `telyBot`; the page's messages are `telybot:theme` and
  `telybot:waits`. The User-Agent ends `TelyBot/1.0.0 (iOS)`. Log subsystem `com.telybot.sdk`.

Versions before 1.0.0 were released under an earlier name; their notes are in the repository history.
