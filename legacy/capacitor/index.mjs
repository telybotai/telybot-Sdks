// @keyda/bot-capacitor — renamed to @telybot/capacitor in 1.0.0. This final
// release re-exports it, with the 0.x name as a deprecated alias.
import TelyBot from '@telybot/capacitor';
export * from '@telybot/capacitor';
/** @deprecated Renamed: use TelyBot from @telybot/capacitor. */
export const KeydaBot = TelyBot;
export default TelyBot;
