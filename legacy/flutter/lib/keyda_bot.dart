/// keyda_bot — renamed to `telybot` in 1.0.0.
///
/// This final release re-exports `package:telybot/telybot.dart` and keeps the
/// 0.x names as deprecated aliases. Replace the dependency with `telybot` and
/// the names with their TelyBot… versions.
library;

import 'package:telybot/telybot.dart';

export 'package:telybot/telybot.dart';

/// Renamed: use [TelyBot].
@Deprecated('Renamed: use TelyBot from package:telybot')
typedef KeydaBot = TelyBot;

/// Renamed: use [TelyBotChat].
@Deprecated('Renamed: use TelyBotChat from package:telybot')
typedef KeydaBotChat = TelyBotChat;

/// Renamed: use [TelyBotConfigError].
@Deprecated('Renamed: use TelyBotConfigError from package:telybot')
typedef KeydaBotConfigError = TelyBotConfigError;

/// Renamed: use [TelyBotExternalLinkHandler].
@Deprecated('Renamed: use TelyBotExternalLinkHandler from package:telybot')
typedef KeydaExternalLinkHandler = TelyBotExternalLinkHandler;

/// Renamed: use [kTelyBotDefaultBaseUrl].
@Deprecated('Renamed: use kTelyBotDefaultBaseUrl from package:telybot')
const String kKeydaDefaultBaseUrl = kTelyBotDefaultBaseUrl;
