#if canImport(UIKit)
import UIKit

/// A reply from the business that arrives while the chat is closed.
///
/// A customer who asked for a person leaves their details and closes the chat; the
/// owner answers in the dashboard an hour later. The answer lands in the conversation,
/// and the chat page shows it the next time it opens — but nothing told the customer to
/// open it. This is that something.
///
/// The page is the source of truth. It keeps the chats it is waiting on (up to three,
/// for 14 days, each with the time of the last row it showed) and sends that list over
/// the bridge as `telybot:waits` whenever it changes. This keeps a copy on disk, and when
/// the app comes to the foreground with no chat on screen it asks the same public route
/// the page asks (`/widget/{clientId}/messages`) whether a person has written since.
/// Nothing here moves the page's place: the page does that when it draws the reply, and
/// sends the list back. A place sent by a chat that is not on screen is not what the
/// customer has seen, though (see `TelyBotWait`).
///
/// Stored as a small file in Application Support, excluded from backup — not
/// `UserDefaults`, which is a required-reason API the privacy manifest says this package
/// does not use. The file holds only what the web view already keeps: chat ids and times.
@available(iOSApplicationExtension, unavailable)
final class TelyBotReplies: @unchecked Sendable {

    static let shared = TelyBotReplies()

    /// One look per minute at most. Three requests a foreground is nothing; three a second is.
    private static let minInterval: TimeInterval = 60
    /// What `checkForReplies()` still waits between looks, for a host that calls it a lot.
    private static let minForcedInterval: TimeInterval = 10

    private struct Stored: Codable {
        let root: String
        let waits: [TelyBotWait]
    }

    /// Everything below `queue` is touched only on it.
    private let queue = DispatchQueue(label: "com.telybot.sdk.replies")
    private var file: URL?
    private var root: String?
    private var messagesURL: URL?
    private var waits: [TelyBotWait] = []
    private var lastLook: Date = .distantPast
    /// The file is there but could not be read (data protection, before the first unlock
    /// after a restart). Until a read succeeds it is neither written nor deleted, and the
    /// read is tried again on the next unlock, foreground, look or list from the page.
    private var unreadable = false

    /// Read from any thread.
    private let lock = NSLock()
    private var storedUnread = false
    private var storedOnScreen = 0
    /// `true` once `start` has read the list (or before any `start`: nothing to wait for).
    private var storedLoaded = true
    private var observing = false

    /// The list is read from disk on `queue` at `start`. Asked before that read is done
    /// — a screen's first appearance after a cold start — this waits for it, rather than
    /// answer `false` for a reply the customer has not seen. The read itself is tiny.
    var hasUnreadReply: Bool {
        lock.lock()
        let ready = storedLoaded
        lock.unlock()
        if !ready { queue.sync {} }
        lock.lock(); defer { lock.unlock() }
        return storedUnread
    }

    private var chatsOnScreen: Int {
        lock.lock(); defer { lock.unlock() }
        return storedOnScreen
    }

    /// From `TelyBot.initialize`. Safe to call again; a different client id or server
    /// starts afresh.
    func start(_ configuration: TelyBotConfiguration) {
        let chat = configuration.chatURL
        var components = URLComponents()
        components.scheme = chat.scheme
        components.host = chat.host
        components.port = chat.port
        components.path = "/api/business/v1/widget/\(configuration.clientId)/messages"
        let url = components.url
        let base = chat.absoluteString
        let file = TelyBotReplies.fileURL(clientId: configuration.clientId)
        lock.lock(); storedLoaded = false; lock.unlock()
        queue.async {
            self.messagesURL = url
            if self.file != file || self.root != base {
                self.file = file
                self.root = base
                self.load()
            } else {
                self.readAgainIfItFailed()
            }
            self.lock.lock(); self.storedLoaded = true; self.lock.unlock()
            self.removeOtherClientsFiles()
            self.lookNow(spacing: TelyBotReplies.minInterval)
        }

        lock.lock()
        let first = !observing
        observing = true
        lock.unlock()
        if first {
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.look(forced: false)
            }
            // The first unlock after a restart: a list that could not be read until now can be.
            NotificationCenter.default.addObserver(
                forName: UIApplication.protectedDataDidBecomeAvailableNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.look(forced: false)
            }
        }
    }

    /// A `telybot:waits` message from the page. `fromOnScreen`: the chat that sent it was
    /// on screen, so what it drew was seen. `chat`: that chat's address, to tell a chat
    /// still open from before `initialize` was called with another client id or server.
    func onWaits(_ list: [Any]?, fromOnScreen: Bool, chat: String) {
        let incoming = TelyBotWait.parse(list, now: Date())
        queue.async {
            guard chat == self.root else { return }
            self.readAgainIfItFailed()
            let movedOn = !fromOnScreen && TelyBotWait.pageMovedOn(self.waits, to: incoming)
            self.waits = TelyBotWait.merged(self.waits, with: incoming, fromOnScreen: fromOnScreen)
            self.settle()
            // A hidden chat drew a row nobody saw: an order update, the bot, or a person's
            // reply. Only a look can tell which, and it lights the dot (and calls
            // `onReply`) for a person's reply alone. No limit of its own: the page's own
            // poll already spaces these out.
            if movedOn { self.lookNow(spacing: 0) }
        }
    }

    /// A chat came on screen: what it has drawn, and whatever it draws while it stays,
    /// is in front of the customer. Unread reads `false` from this moment.
    func chatAppeared() {
        lock.lock()
        storedOnScreen += 1
        storedUnread = false
        lock.unlock()
        queue.async {
            self.waits = TelyBotWait.seen(self.waits)
            self.settle()
        }
    }

    /// Unread again only if no chat on screen got to show the reply: one that failed to
    /// load, say, or one that drew it while it was hidden.
    func chatWentAway() {
        lock.lock()
        if storedOnScreen > 0 { storedOnScreen -= 1 }
        lock.unlock()
        queue.async { self.settle() }
    }

    /// `TelyBot.checkForReplies()`, the foreground and the first unlock. With a chat on
    /// screen this only retries a list that could not be read; it asks nothing.
    func look(forced: Bool) {
        let spacing = forced ? TelyBotReplies.minForcedInterval : TelyBotReplies.minInterval
        queue.async { self.lookNow(spacing: spacing) }
    }

    // MARK: - On `queue`

    /// Unread: a person wrote past what the customer has seen, and no chat is on screen
    /// to show it. The count is read in the same lock the answer is written in, so a
    /// chat that appears meanwhile is never overwritten by this older verdict.
    private func settle() {
        publishUnread()
        save()
    }

    private func publishUnread() {
        let unseen = TelyBotWait.anyUnseen(waits)
        lock.lock()
        storedUnread = storedOnScreen == 0 && unseen
        lock.unlock()
    }

    /// Asks the route for every wait, unless a chat is on screen or the last look was
    /// less than `spacing` ago.
    private func lookNow(spacing: TimeInterval) {
        readAgainIfItFailed()
        guard let url = messagesURL else { return }
        let now = Date()
        let before = waits.count
        waits.removeAll { now.timeIntervalSince1970 * 1000 - $0.t >= TelyBotWait.lifetime * 1000 }
        if waits.count != before { settle() }
        if waits.isEmpty || chatsOnScreen > 0 { return }
        if now.timeIntervalSince(lastLook) < spacing { return }
        lastLook = now

        let asked = waits
        let group = DispatchGroup()
        let results = Results()
        for w in asked {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { continue }
            var items = [URLQueryItem(name: "conversationId", value: w.c)]
            if !w.at.isEmpty { items.append(URLQueryItem(name: "after", value: w.at)) }
            components.queryItems = items
            // `+` survives URLComponents as a literal plus, which a server reads as a
            // space; an ISO time with an offset would arrive broken.
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
            guard let requestURL = components.url else { continue }
            var request = URLRequest(url: requestURL)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            group.enter()
            TelyBotReplyFetch.get(request) { data in
                defer { group.leave() }
                // No network, a captive portal, a server hiccup: the next foreground asks again.
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let rows = json["messages"] as? [Any] else { return }
                var latest = ""
                for case let row as [String: Any] in rows {
                    guard row["from"] as? String == "human", let at = row["at"] as? String else { continue }
                    if at > w.at && at > latest { latest = at }
                }
                results.set(w.c, latest)
            }
        }
        group.notify(queue: queue) {
            // Offline is not "no reply": a failed look changes nothing, so a badge the
            // customer has not acted on stays until the page shows them the reply.
            var fresh = false
            for i in self.waits.indices {
                guard let latest = results.get(self.waits[i].c), latest > self.waits[i].told else { continue }
                self.waits[i].told = latest
                fresh = true
            }
            self.settle()
            if fresh {
                DispatchQueue.main.async {
                    // The customer opened the chat while we were asking: they are reading it.
                    if self.chatsOnScreen == 0 && self.hasUnreadReply { TelyBot.deliverReply() }
                }
            }
        }
    }

    /// Reads the list for `file` and `root`. A file that is missing, damaged or for
    /// another server is an empty list; one that is there but cannot be read is not.
    private func load() {
        waits = []
        unreadable = false
        defer { publishUnread() }
        guard let file else { return }
        switch TelyBotWait.read(file) {
        case .missing:
            return
        case .unreadable:
            unreadable = true
            TelyBotLog.error("The reply list could not be read yet; trying again once the device is unlocked.")
        case .data(let data):
            guard let stored = try? JSONDecoder().decode(Stored.self, from: data), stored.root == root else { return }
            waits = TelyBotWait.checked(stored.waits)
        }
    }

    /// The list on disk is the earlier one: it replaces what is in memory, which before
    /// the first unlock can only be empty (no chat can be on a locked screen).
    private func readAgainIfItFailed() {
        guard unreadable else { return }
        load()
    }

    private func save() {
        // A list that was never read must not be replaced by an empty one.
        guard let file, let root, !unreadable else { return }
        if waits.isEmpty {
            try? FileManager.default.removeItem(at: file)
            return
        }
        do {
            let directory = file.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(Stored(root: root, waits: waits)).write(to: file, options: .atomic)
            var url = file
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? url.setResourceValues(values)
        } catch {
            TelyBotLog.error("Could not save the reply list: \(error.localizedDescription)")
        }
    }

    /// The lists of client ids this app no longer uses: nothing will ever ask for them.
    private func removeOtherClientsFiles() {
        guard let file else { return }
        let directory = file.deletingLastPathComponent()
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return }
        for name in names where name.hasPrefix("waits_") && name.hasSuffix(".json") && name != file.lastPathComponent {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    // MARK: - Helpers

    private static func fileURL(clientId: String) -> URL? {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = support.appendingPathComponent("TelyBot", isDirectory: true)
        let file = folder.appendingPathComponent("waits_\(clientId).json")
        // 0.2.x kept the list under Application Support/KeydaBot/. Carried across once, so a
        // reply a 0.2.x install was still waiting for lights the dot after the update to 1.0;
        // the old folder is removed after.
        let fileManager = FileManager.default
        let old = support.appendingPathComponent("KeydaBot", isDirectory: true)
        if fileManager.fileExists(atPath: old.path) {
            let oldFile = old.appendingPathComponent("waits_\(clientId).json")
            if !fileManager.fileExists(atPath: file.path), fileManager.fileExists(atPath: oldFile.path) {
                try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                try? fileManager.moveItem(at: oldFile, to: file)
                var moved = file
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try? moved.setResourceValues(values)
            }
            try? fileManager.removeItem(at: old)
        }
        return file
    }

    /// The newest reply time per chat, written from URLSession's queue.
    private final class Results: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [String: String] = [:]
        func set(_ key: String, _ value: String) { lock.lock(); values[key] = value; lock.unlock() }
        func get(_ key: String) -> String? { lock.lock(); defer { lock.unlock() }; return values[key] }
    }
}
#endif
