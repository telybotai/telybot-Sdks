/// Telybot chat for Flutter.
///
/// A thin wrapper that opens `{baseUrl}/chat/{clientId}` — the same hosted
/// chat page the web widget and every other Telybot SDK loads — in a WebView
/// over the host app.
library;

export 'src/chat_page.dart' show TelyBotExternalLinkHandler;
export 'src/client_id.dart' show TelyBotConfigError, kTelyBotDefaultBaseUrl;
export 'src/telybot.dart' show TelyBot, TelyBotChat;
