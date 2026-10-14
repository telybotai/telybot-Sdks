=== Telybot ===
Contributors: telybot
Tags: chatbot, live chat, customer support, ai, assistant
Requires at least: 5.6
Tested up to: 7.1
Requires PHP: 7.4
Stable tag: 2.0.0
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

Adds your Telybot chat assistant to your site. One field: your client id. Everything else comes from your Telybot dashboard.

== Description ==

This plugin adds one hosted script to your site's front end, with your client
id attached to it. That script draws the chat — a launcher button in the corner
and a panel that opens when a visitor clicks it.

It is worth being plain about what that means, because it decides whether this
plugin suits you:

* The chat interface is served by Telybot, not rendered by this plugin. Your bot's
  greeting, accent colour, position, languages and answers are all set in your
  Telybot dashboard, and a change there is live on your site straight
  away — no plugin update, no cache to clear, no code to edit.
* Because there is one chat interface for every place a Telybot bot appears — your
  website, your Android app, your iOS app — a fix or an improvement reaches all
  of them at once.
* Your visitors' questions go to Telybot to be answered. That is what the bot is.
  See "External services" below for exactly what is sent.

The widget renders inside a shadow root, so your theme's CSS cannot break it and
its CSS cannot reach your site. It never throws an error into your page: if it
cannot reach Telybot while your page is loading it adds nothing at all and writes
one `[TelyBot]` warning to the browser console, and a message that fails to
send is answered in the chat itself.

Your bot has to be set live in the dashboard. While it is still a draft the
widget adds nothing to your pages at all — it only writes one console line:
`[TelyBot] this bot is in draft — set it live in your Telybot dashboard to show
it here.`

= What this plugin does not do =

* No offline mode. The bot is a hosted service; with no connection there is no
  answer.
* No push notifications.
* No third-party libraries, no tracking pixels, no device fingerprinting, no
  cookies. The widget keeps a few things in the visitor's own browser,
  described under "External services". The one thing reported without a
  visitor writing anything is that the widget loaded, so your dashboard can tell
  you your bot is installed.
* No link to us on your site unless you ask for one. The chat can show a
  "Powered by Telybot" credit at the foot of its panel, and it is off until you
  tick the box on the settings screen.
* No per-page targeting. The widget loads on every front-end page, which is the
  same behaviour as pasting the script tag into your footer.
* No theming beyond what your dashboard already controls. Light, dark or
  "match the visitor" is a dashboard setting; the widget applies it.
* No PHP-side network calls. This plugin never contacts any server from your
  web host; only the visitor's browser talks to Telybot.

= External services =

This plugin loads a script from Telybot and the bot answers from Telybot's API, so
some data leaves the visitor's browser. Nothing leaves your server.

The script is loaded from `https://telybot.com/widget.js` (or from
whichever host you configure — see the FAQ). Once running, the visitor's browser
makes four kinds of request to that same host:

1. It fetches your bot's public settings — greeting, colour, launcher label —
   using your client id.
2. It records that your widget loaded, sending the path of the page it loaded
   on. This is the "your bot is live" confirmation on your dashboard, which
   keeps your site's domain and the time — not the path, and nothing about the
   visitor.
3. When a visitor sends a message, it posts that message and a conversation id.
4. If your bot offers "Talk to a person" (a toggle in your dashboard) and a
   visitor chooses to fill in that form, what they typed — their email or
   phone, any name and message they added — is sent to Telybot together with the
   conversation id, the last question they asked the bot, and the full address
   of the page they were on (unlike the load ping above, this one does include
   the page URL). It is stored so you can reply from your dashboard's Leads
   screen, and it is sent only when the visitor presses Send on that form.

The widget keeps a few things in the visitor's browser, never in a cookie and
never read by this plugin: the conversation id for as long as the browser tab
is open (moving between your pages keeps the chat; closing the tab ends it),
references to the visitor's own orders and bookings, and what they typed at
checkout, for 24 hours. It also keeps a random id that means nothing outside
your site and is sent with each chat, so your dashboard can show that separate
chats came from the same browser. That id is not created when the browser
sends Do Not Track or Global Privacy Control. Telybot's privacy policy lists
each item and how long it is kept.

Telybot's terms: https://telybot.com/terms
Telybot's privacy policy: https://telybot.com/privacy

== Installation ==

1. Install and activate the plugin.
2. Go to **Settings &rarr; Telybot**.
3. Paste the client id from the Install page of your Telybot dashboard.
   It looks like `tb_live_` followed by 8 to 48 characters from 0-9 and a-f.
4. Save, then open your site in a new tab. The chat button appears in the corner.

If the field is empty, the plugin adds nothing at all to your pages.

== Frequently Asked Questions ==

= Does this put a link to Telybot on my site? =

Not unless you turn it on. The chat panel can carry a small "Powered by Telybot"
credit that links to telybot.com, and the setting for it is unticked when you
install the plugin. Nothing else the plugin renders links anywhere off your
site. If you tick it, the credit appears at the foot of the chat panel, where
only a visitor who opens the chat will see it.

= Where do I find my client id? =

In the Telybot dashboard at https://telybot.com/app/, on the
Install page. Copy the id itself, not the whole script tag.

= It says my client id was not saved. =

The id must be `tb_live_` followed by 8 to 48 hexadecimal characters (0-9 and
a-f). The most common cause is pasting the entire `<script ...>` tag from the
dashboard instead of just the id. A rejected value never replaces the id you
already had saved, so a live bot stays live while you fix the typo.

= Can I point the plugin at a different host? =

Yes. Add this to `wp-config.php`:

`define( 'TELYBOT_BASE_URL', 'https://chat.example.com' );`

or filter it from a theme or mu-plugin:

`add_filter( 'telybot_base_url', function () { return 'https://chat.example.com'; } );`

The value is the directory `widget.js` is served from — the plugin appends
`/widget.js` to it. A path prefix is fine, and is in fact how the default works:
`https://telybot.com` loads `https://telybot.com/widget.js`. The
widget then reaches its API at that *origin's* `/api/business/v1`, whatever the
path was, so a self-host must answer there — a bare host such as
`https://chat.example.com` only works when `widget.js` sits at its root. An
override that is not a valid http or https URL is ignored and the default is
used.

= I installed it but no chat appears on my site. =

In this order:

1. **Settings &rarr; Telybot**. With the field empty the plugin adds nothing.
2. Clear your caching plugin's cache. A page cached before you saved the id has
   no script tag in it.
3. Open your browser's developer console and look for a line beginning
   `[TelyBot]`. "missing data-key" means something rewrote or merged the tag —
   exclude the handle `telybot` from script concatenation.
4. If your bot has an authorised-domains list in the dashboard, your site's
   domain has to be on it. Until it is, the request is refused and the widget
   renders nothing.
5. Your bot may still be a draft. A draft bot renders nothing on a customer
   site — the console line in step 3 will say so plainly. Set it live in the
   Telybot dashboard.

= My inline embed says the chat is not available. =

The inline container (`data-telybot-bot`, below) renders even for a draft bot so
that a page under construction is not left with an invisible hole — and inside
it, visitors are told the chat is not available. Set the bot live in the Telybot
dashboard. The floating button is different: while the bot is a draft
it does not appear at all.

= Can I show the chat inside the page instead of as a floating button? =

Yes, and it needs nothing from this plugin. Put an empty container with a height
anywhere on a page, in a Custom HTML block:

`<div data-telybot-bot style="height:520px"></div>`

The widget fills that container instead of showing a launcher. That behaviour
belongs to the widget script itself, so it works wherever the widget loads.

= Does it work with WooCommerce? =

There is nothing extra to do. The widget loads on product, cart and checkout
pages like any other front-end page.

= Does it work with a caching plugin? =

The script is registered through WordPress's own enqueue system with the handle
`telybot`, which is what caching and optimisation plugins read. If one of them
combines external scripts into a single file, exclude this handle: the widget
reads its own tag to find your client id, so a merged copy loses it.

= Does it slow my site down? =

The tag is async, so it never blocks your page. On load the widget makes two
small requests to Telybot — your bot's settings and the install ping described
above — and nothing more until a visitor sends a message.

= What happens when I delete the plugin? =

Both options this plugin owns — your client id and the credit-link setting —
are removed, on every site of a network install. Nothing else is stored.

== Changelog ==

= 2.0.0 =
* Client ids start with `tb_live_`. Every key was renamed on the server (its random part
  kept), and a `kb_live_` id is now refused: paste the new key from Install in the
  dashboard into Settings > Telybot.
* Removes what was kept for sites coming from the plugin's earlier name: its settings are
  no longer read, and only TELYBOT_BASE_URL and the telybot_base_url filter set the host.

= 1.0.0 =
* First release as `telybot` (folder `telybot/`, file `telybot.php`): one field for your
  client id, an optional "Powered by Telybot" credit (off until you tick it), and nothing
  else to configure. Everything the chat says and looks like comes from your dashboard.
* Point it at another host with the `TELYBOT_BASE_URL` constant or the `telybot_base_url`
  filter (see the FAQ).
* "External services" says exactly what leaves the visitor's browser and what the chat
  keeps there. The console lines the chat writes begin `[TelyBot]`.
* Uninstalling removes both settings, on every site of a network install.

Versions before 1.0.0 were released under an earlier name.

== Upgrade Notice ==

= 2.0.0 =
Your client id now starts with tb_live_. Copy it from Install in your dashboard and paste it into Settings > Telybot.

= 1.0.0 =
First release under this name.
