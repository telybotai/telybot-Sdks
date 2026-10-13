/**
 * @keyda/bot-react-native — renamed to @telybot/react-native in 1.0.0.
 *
 * This final release re-exports the new package and keeps the 0.x names as
 * deprecated aliases. Replace the dependency with @telybot/react-native and
 * the names with their TelyBot… versions.
 */
export * from '@telybot/react-native';
export {
  /** @deprecated Renamed: use TelyBot from @telybot/react-native. */
  TelyBot as KeydaBot,
  /** @deprecated Renamed: use TelyBotChat from @telybot/react-native. */
  TelyBotChat as KeydaBotChat,
  /** @deprecated Renamed: use useTelyBot from @telybot/react-native. */
  useTelyBot as useKeydaBot,
  /** @deprecated Renamed: use useTelyBotReplies from @telybot/react-native. */
  useTelyBotReplies as useKeydaBotReplies,
} from '@telybot/react-native';
export type {
  TelyBotProps as KeydaBotProps,
  TelyBotChatProps as KeydaBotChatProps,
  TelyBotController as KeydaBotController,
  TelyBotReplies as KeydaBotReplies,
  TelyBotRepliesOptions as KeydaBotRepliesOptions,
  TelyBotStorage as KeydaBotStorage,
  TelyBotVisitor as KeydaBotVisitor,
} from '@telybot/react-native';
