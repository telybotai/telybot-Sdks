// @keyda/bot-capacitor — renamed to @telybot/capacitor in 1.0.0. This final
// release re-exports it, with the 0.x name as a deprecated alias.
'use strict';
const telybot = require('@telybot/capacitor');
module.exports = Object.assign({}, telybot, { KeydaBot: telybot.TelyBot, default: telybot.TelyBot });
