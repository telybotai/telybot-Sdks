# The old package names, one last time

1.0.0 renamed the packages (see the root README, "Moving from 0.x"). These three
directories are the **final** releases of the old registry names, 0.2.1 each.
Each one depends on its new package and re-exports it, with the 0.x names as
deprecated aliases, so an app can take the update first and rename after.
They are published by hand once, after the 1.0.0 packages exist
(`docs/SDK_REBRAND_PLAN.md` step 8 in the Telybot repository), and never again.

| Directory | Old name | Forwards to |
|---|---|---|
| `react-native/` | npm `@keyda/bot-react-native` | `@telybot/react-native` |
| `capacitor/` | npm `@keyda/bot-capacitor` | `@telybot/capacitor` |
| `flutter/` | pub.dev `keyda_bot` | `telybot` |

They sit outside `tools/release.mjs` on purpose: they keep their own version.
Android and iOS need no shim — the deprecated `KeydaBot` names ship inside 1.0.0.
