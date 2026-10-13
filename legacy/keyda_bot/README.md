# keyda_bot — renamed

This package is now **[telybot](https://pub.dev/packages/telybot)**.

```bash
flutter pub remove keyda_bot
flutter pub add telybot
```

Then `import 'package:telybot/telybot.dart';` and `KeydaBot` → `TelyBot`,
`KeydaBotChat` → `TelyBotChat`. Until you do, this last release (0.2.1) forwards
everything to the new package under the old names, deprecated. It gets no
further releases.
