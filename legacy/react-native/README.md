# @keyda/bot-react-native — renamed

This package is now **[@telybot/react-native](https://www.npmjs.com/package/@telybot/react-native)**.

```bash
npm uninstall @keyda/bot-react-native
npm install @telybot/react-native react-native-webview
```

Then `KeydaBot` → `TelyBot`, `KeydaBotChat` → `TelyBotChat`, `useKeydaBot` →
`useTelyBot`, `useKeydaBotReplies` → `useTelyBotReplies`. Until you do, this
last release (0.2.1) forwards everything to the new package under the old
names, deprecated. It gets no further releases.
