import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'client_id.dart';
import 'replies.dart';
import 'visitor.dart';

/// The whole public surface of the Telybot SDK for Flutter.
///
/// Configure once, present when the customer asks for help, close it again:
///
/// ```dart
/// TelyBot.init('kb_live_9f2c41ab');            // once, e.g. in main()
/// TelyBot.show(context);                       // on a "Chat with us" tap
/// ```
///
/// There is no message API and no identify call. The one unread signal,
/// [hasUnreadReply], is a reply from a person at the business that the chat has
/// not shown yet — something the server can answer honestly (CONTRACT.md).
class TelyBot {
  // Static-only: the chat is a single presentation over the host app, and an
  // instance would suggest two of them could exist.
  TelyBot._();

  static Uri? _chatUrl;
  static NavigatorState? _navigator;
  static Route<void>? _route;
  static bool _isShowing = false;

  /// The chat on screen, for a [show] with a question while it is open. A new
  /// key per chat: the last one can still be animating out when the next opens.
  static GlobalKey<TelyBotChatPageState>? _page;

  /// Whether the chat is on screen right now.
  ///
  /// Stays truthful when the customer leaves with the Android back gesture,
  /// not only when [dismiss] is called.
  static bool get isShowing => _isShowing;

  /// Stores the configuration and validates it immediately.
  ///
  /// [clientId] is the `kb_live_...` id from **Install** in the Telybot
  /// dashboard. [baseUrl] only changes for staging or a self-hosted install —
  /// give it as an origin (`https://staging.example.com`), optionally with a
  /// path prefix.
  ///
  /// Throws [TelyBotConfigError] straight away if either is malformed. That
  /// is deliberate: a bad id discovered here costs a rebuild, and discovered
  /// in production shows a customer a 404 where the chat should be. Calling
  /// [init] again replaces the configuration; it does not affect a chat that
  /// is already on screen.
  static void init(String clientId, {String baseUrl = kTelyBotDefaultBaseUrl}) {
    final Uri chatUrl = buildChatUrl(clientId: clientId, baseUrl: baseUrl);
    _chatUrl = chatUrl;
    TelyBotReplies.instance.start(chatUrl, clientId);
  }

  /// True when the business has replied to this customer while no chat was on
  /// screen, until a chat is on screen. Only a reply the customer has not seen
  /// counts: a [TelyBotChat] with `focused: false` draws the reply out of
  /// sight, which does not clear this. A [ValueListenable], so a badge can
  /// follow it:
  ///
  /// ```dart
  /// ValueListenableBuilder<bool>(
  ///   valueListenable: TelyBot.hasUnreadReply,
  ///   builder: (_, bool unread, __) => Badge(isLabelVisible: unread, child: chatIcon),
  /// )
  /// ```
  static ValueListenable<bool> get hasUnreadReply => TelyBotReplies.instance.unread;

  /// Called when a person from the business has answered a customer who asked
  /// for one, while no chat was on screen — once per new reply. The SDK asks
  /// when the app comes to the foreground (once a minute at most), only for
  /// chats in which the customer asked for a person in the last 14 days.
  static VoidCallback? get onReply => TelyBotReplies.instance.onReply;
  static set onReply(VoidCallback? callback) => TelyBotReplies.instance.onReply = callback;

  /// Asks now whether the business has replied, rather than at the next
  /// foreground. At most one request every 10 seconds.
  static Future<void> checkForReplies() => TelyBotReplies.instance.look(forced: true);

  /// Your signed-in customer, so the chat does not ask them what your app
  /// already knows. Offered — never sent — in the forms that ask for them:
  /// "talk to a person", an order, a booking, and a welcome question for a
  /// name, a phone number or an email. The customer sees the values and
  /// submits them; until then nothing leaves the phone (they travel in the
  /// URL's #fragment, which no server sees). They are your app's word, not a
  /// verified identity. Each is optional; one that does not look like what it
  /// claims is dropped whole, never cut: a name of 1–80 characters on one
  /// line, a phone number with 8–15 digits (and only spaces and `+ - ( ) .`
  /// besides), an email up to 254 characters. Applies to the chats open now
  /// and every one after.
  static void setVisitor({String? name, String? phone, String? email}) {
    telyBotVisitor.value = TelyBotVisitor.of(name: name, phone: phone, email: email);
  }

  /// Forgets [setVisitor]'s details — call it when the customer signs out.
  static void clearVisitor() {
    telyBotVisitor.value = null;
  }

  /// Presents the chat full-screen over the host app.
  ///
  /// The returned future completes when the chat is closed — by [dismiss], by
  /// the close button, or by the system back gesture. Awaiting it is optional.
  ///
  /// Links that leave the chat's own origin (the "Powered by Telybot" link,
  /// `mailto:`, `tel:`, WhatsApp or UPI deep links) are never followed inside
  /// the WebView — that would replace the customer's conversation with a page
  /// they have no way back from. By default they are opened in the system
  /// browser. [onExternalLink] takes that over, for a host app that wants to
  /// route links itself.
  ///
  /// Throws [StateError] if [init] has not been called.
  /// [question] is optional: put in the chat's message box for the customer
  /// to send — they still tap send. It travels in the URL's #fragment, never
  /// in a server log. With the chat already showing, it replaces what is in
  /// the box.
  static Future<void> show(
    BuildContext context, {
    TelyBotExternalLinkHandler? onExternalLink,
    String? question,
  }) async {
    final Uri? chatUrl = _chatUrl;
    if (chatUrl == null) {
      throw StateError(
        'TelyBot.show() was called before TelyBot.init(). Call '
        "TelyBot.init('kb_live_...') once at startup.",
      );
    }
    if (_isShowing) {
      // A second tap on the launcher while the chat is opening would stack a
      // second WebView on the first, and closing once would look like nothing
      // happened. A question for the chat already open goes into its box.
      if (question != null) {
        _page?.currentState?.prefill(question);
      }
      return;
    }

    // rootNavigator: a chat pushed inside a tab's nested navigator keeps the
    // host's tab bar drawn over it, which is exactly where the keyboard and
    // the message input want to be.
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final GlobalKey<TelyBotChatPageState> page = GlobalKey<TelyBotChatPageState>();
    _page = page;
    final MaterialPageRoute<void> route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext _) => TelyBotChatPage(
        key: page,
        chatUrl: chatUrl,
        onExternalLink: onExternalLink,
        question: question,
      ),
    );

    _navigator = navigator;
    _route = route;
    _isShowing = true;
    try {
      await navigator.push(route);
    } finally {
      // Cleared here rather than inside dismiss(), because the customer can
      // also leave with the back gesture; state is reset on every exit path.
      // The identity check keeps a slow teardown from clearing a newer chat.
      if (identical(_route, route)) {
        _isShowing = false;
        _route = null;
        _navigator = null;
      }
    }
  }

  /// Closes the chat if it is open.
  ///
  /// Safe to call when nothing is showing; that is a no-op, not an error.
  /// The conversation itself survives — it lives in the page's DOM storage and
  /// comes back on the next [show].
  static void dismiss() {
    final NavigatorState? navigator = _navigator;
    final Route<void>? route = _route;
    if (navigator == null || route == null) {
      return;
    }
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      // The host pushed one of their own screens over the chat. Popping would
      // close theirs; removing takes only ours out of the stack.
      navigator.removeRoute(route);
    }
  }
}

/// The chat as a widget of your own screen — a Help tab, a support screen —
/// rather than the full-screen route [TelyBot.show] pushes. Same hosted page,
/// same rules. Call [TelyBot.init] first.
///
/// ```dart
/// const TelyBotChat(question: 'Is this in stock?')
/// ```
///
/// No close button (your screen's navigation is the way out) and no insets:
/// lay it out inside a `SafeArea` like any other widget; a `Scaffold` with
/// `resizeToAvoidBottomInset` keeps it clear of the keyboard. With a sheet open
/// in the chat (an item, the cart, a booking) back closes the sheet first; it
/// is your navigator's back otherwise.
class TelyBotChat extends StatelessWidget {
  /// Creates the embedded chat.
  const TelyBotChat({
    this.question,
    this.onExternalLink,
    this.onCanGoBackChanged,
    this.focused = true,
    super.key,
  });

  /// Is the screen this chat is in the one in front? Pass false while your tab
  /// with the chat is not selected (an `IndexedStack`, a `TabBarView` that
  /// keeps it alive): back is then yours alone — it would otherwise close a
  /// sheet in a chat nobody can see — and the chat counts as off screen: a
  /// reply it draws stays unread in [TelyBot.hasUnreadReply] until the tab is
  /// selected. Default true.
  final bool focused;

  /// Optional: put in the chat's message box for the customer to send. A new
  /// value on a chat already showing replaces what is in the box.
  final String? question;

  /// As on [TelyBot.show].
  final TelyBotExternalLinkHandler? onExternalLink;

  /// Called with true when the chat opens a sheet over the conversation and
  /// with false when the last one closes.
  final ValueChanged<bool>? onCanGoBackChanged;

  @override
  Widget build(BuildContext context) {
    final Uri? chatUrl = TelyBot._chatUrl;
    if (chatUrl == null) {
      throw StateError(
        'TelyBotChat was built before TelyBot.init(). Call '
        "TelyBot.init('kb_live_...') once at startup.",
      );
    }
    return TelyBotChatPage(
      chatUrl: chatUrl,
      onExternalLink: onExternalLink,
      question: question,
      embedded: true,
      onCanGoBackChanged: onCanGoBackChanged,
      focused: focused,
    );
  }
}
