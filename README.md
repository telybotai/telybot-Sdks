<img src="assets/telybot-mark.svg" alt="" width="56" height="56">

# Telybot SDKs

Drop the Telybot bot into your app. One key, every platform.

| Platform | Package | Status |
|---|---|---|
| Android | `com.telybot:telybot` | JitPack `com.github.telybotai:telybot-Sdks:v1.0.0` |
| iOS | `TelyBot` (SPM / CocoaPods) | SPM from this repository at tag `v1.0.0` |
| React Native | `@telybot/react-native` | npm `@telybot/react-native@1.0.0` |
| Flutter | `telybot` | pub.dev `telybot ^1.0.0` |
| Ionic / Capacitor | `@telybot/capacitor` | npm `@telybot/capacitor@1.0.0` |
| WordPress | `telybot` plugin | source here (`wordpress/telybot/`, 1.0.0) |
| Any website | `<script src="https://telybot.com/widget.js">` | shipped |

Every one of these opens the same hosted chat page, so a change an owner makes
in their dashboard is live everywhere at once — including its theme: light,
dark or "match the visitor" is set in the dashboard, the page carries it, and
the native SDKs match their status bar and close control to it (no theme
option on any SDK). See [CONTRACT.md](CONTRACT.md) for what that means and
what it costs.

Get your client id from **Install** in the [Telybot
dashboard](https://telybot.com/app/).

## Moving from 0.x

1.0.0 gave every package the Telybot name. The old names keep working, as
deprecated aliases or forwarding releases, until 2.0.0, so an app can take the
update first and rename after. A reply your customer was waiting for is carried
over on the first start.

| 0.x | 1.0.0 |
|---|---|
| Android `in.keyda:keyda-bot`, ``import `in`.keyda.bot.KeydaBot`` | `com.telybot:telybot`, `import com.telybot.sdk.TelyBot` |
| iOS product `KeydaBot`, `import KeydaBot` | product `TelyBot`, `import TelyBot` |
| npm `@keyda/bot-react-native`, `<KeydaBot>` | `@telybot/react-native`, `<TelyBot>` |
| pub.dev `keyda_bot`, `KeydaBot` | `telybot`, `TelyBot` |
| npm `@keyda/bot-capacitor`, `KeydaBot` | `@telybot/capacitor`, `TelyBot` |
| WordPress `keyda-bot` | `telybot` — your client id is carried over |

## Licence

MIT — see [LICENSE](LICENSE). The WordPress plugin is GPLv2 or later, as
WordPress.org requires.
