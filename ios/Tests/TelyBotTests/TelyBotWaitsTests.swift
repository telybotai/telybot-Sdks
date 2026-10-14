import XCTest
@testable import TelyBot

/// The reply check's rules: what the customer has seen, what a file read means, and what
/// a look may follow and read. No network: the looks go to a `URLProtocol` stand-in.
final class TelyBotWaitsTests: XCTestCase {

    private let c = "0b6f3c1e-2d4a-4b8e-9f10-1a2b3c4d5e6f"
    private let a0 = "2026-10-09T10:00:00.000Z"
    private let a1 = "2026-10-09T11:00:00.000Z"
    private let a2 = "2026-10-09T12:00:00.000Z"

    private func wait(at: String, page: String? = nil, told: String? = nil) -> TelyBotWait {
        TelyBotWait(c: c, at: at, page: page ?? at, t: 1, told: told ?? at)
    }

    private func incoming(_ at: String) -> [TelyBotWait] {
        TelyBotWait.parse([["c": c, "at": at, "t": Date().timeIntervalSince1970 * 1000]], now: Date())
    }

    // MARK: - What the customer has seen

    func testParseKeepsThreeWellFormedRecentWaits() {
        let now = Date()
        let ms = now.timeIntervalSince1970 * 1000
        let old = ms - TelyBotWait.lifetime * 1000 - 1
        let list: [Any] = [
            ["c": c, "at": a0, "t": ms],
            ["c": "not-a-uuid", "at": a0, "t": ms],
            ["c": c, "at": "10 o'clock", "t": ms],
            ["c": c, "at": a0, "t": old],
            ["c": c, "at": a1, "t": ms]
        ]
        XCTAssertEqual(TelyBotWait.parse(list, now: now).map(\.at), [a0], "the first three only, the bad ones dropped")
        XCTAssertEqual(TelyBotWait.parse(nil, now: now), [])
    }

    func testAHiddenChatMovingOnLightsNothingByItselfButCallsForALook() {
        let prior = [wait(at: a0)]
        XCTAssertTrue(TelyBotWait.pageMovedOn(prior, to: incoming(a1)))
        let hidden = TelyBotWait.merged(prior, with: incoming(a1), fromOnScreen: false)
        XCTAssertEqual(hidden.first?.at, a0, "nobody saw it")
        XCTAssertEqual(hidden.first?.page, a1)
        XCTAssertEqual(hidden.first?.told, a0, "an order update or a bot row moves the page too; only a look says it was a person")
        XCTAssertFalse(TelyBotWait.anyUnseen(hidden))

        // The same list again, or a chat we did not know of, is nothing new to look for.
        XCTAssertFalse(TelyBotWait.pageMovedOn(hidden, to: incoming(a1)))
        XCTAssertFalse(TelyBotWait.pageMovedOn([], to: incoming(a1)))

        // The look found a person's reply at a1: unread until a chat is on screen.
        var replied = hidden
        replied[0].told = a1
        XCTAssertTrue(TelyBotWait.anyUnseen(replied))
        let shown = TelyBotWait.seen(replied)
        XCTAssertEqual(shown.first?.at, a1, "on screen, what the page drew is in front of the customer")
        XCTAssertFalse(TelyBotWait.anyUnseen(shown))
    }

    func testAHiddenChatDoesNotRaiseWhatWasTold() {
        let hidden = TelyBotWait.merged([wait(at: a0, page: a1, told: a1)], with: incoming(a2), fromOnScreen: false)
        XCTAssertEqual(hidden.first?.told, a1, "kept, never raised to the page's place")
        XCTAssertEqual(hidden.first?.page, a2)
    }

    func testAChatOnScreenMovesWhatTheCustomerHasSeen() {
        let onScreen = TelyBotWait.merged([wait(at: a0)], with: incoming(a1), fromOnScreen: true)
        XCTAssertEqual(onScreen.first?.at, a1)
        XCTAssertFalse(TelyBotWait.anyUnseen(onScreen))
    }

    func testANewWaitStartsSeenWherever() {
        let fresh = TelyBotWait.merged([], with: incoming(a1), fromOnScreen: false)
        XCTAssertEqual(fresh.map { [$0.at, $0.page, $0.told] }, [[a1, a1, a1]])
        XCTAssertFalse(TelyBotWait.anyUnseen(fresh))
    }

    func testWhatTheCustomerWasToldSurvivesThePagesList() {
        // `onReply` told the app about a2; the page, loading, still says a0.
        let told = TelyBotWait.merged([wait(at: a0, told: a2)], with: incoming(a0), fromOnScreen: true)
        XCTAssertEqual(told.first?.told, a2, "so the next look does not announce it again")
        XCTAssertTrue(TelyBotWait.anyUnseen(told))
        // Then it draws the reply.
        let drawn = TelyBotWait.merged(told, with: incoming(a2), fromOnScreen: true)
        XCTAssertFalse(TelyBotWait.anyUnseen(drawn))
    }

    func testAFileFromBeforePageWasKeptReadsPageAsAt() throws {
        let json = #"[{"c":"\#(c)","at":"\#(a0)","t":1,"told":"\#(a1)"},{"c":"x","at":"\#(a0)","t":1,"told":"\#(a0)"}]"#
        let stored = try JSONDecoder().decode([TelyBotWait].self, from: Data(json.utf8))
        XCTAssertEqual(TelyBotWait.checked(stored), [wait(at: a0, page: a0, told: a1)])
        let written = try JSONEncoder().encode(TelyBotWait.checked(stored))
        XCTAssertTrue(String(decoding: written, as: UTF8.self).contains(#""page":"\#(a0)""#), "page is kept from now on")
    }

    // MARK: - Reading the device's copy

    func testAFileThatCannotBeReadIsNotAnEmptyList() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        XCTAssertEqual(TelyBotWait.read(directory.appendingPathComponent("waits_none.json")), .missing)

        let file = directory.appendingPathComponent("waits_x.json")
        try Data("[]".utf8).write(to: file)
        XCTAssertEqual(TelyBotWait.read(file), .data(Data("[]".utf8)))

        // Data protection before the first unlock looks like this to the reader.
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: file.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path) }
        if case .data = TelyBotWait.read(file) { throw XCTSkip("running as a user who can read anything") }
        XCTAssertEqual(TelyBotWait.read(file), .unreadable)
    }

    // MARK: - A look

    func testRedirectsStayOnTheChatsOwnSite() {
        let origin = URL(string: "https://example.com/api/business/v1/widget/tb_live_3f9a2c81/messages?conversationId=x")
        let follows = { (to: String) in TelyBotReplyFetch.followsRedirect(from: origin, to: URL(string: to)) }
        XCTAssertTrue(follows("https://example.com/other"))
        XCTAssertTrue(follows("https://www.example.com/api"))
        XCTAssertTrue(follows("https://EXAMPLE.com/api"))
        XCTAssertFalse(follows("http://example.com/api"), "never down to plain http")
        XCTAssertFalse(follows("https://evil.example/api"))
        XCTAssertFalse(follows("https://example.com.evil.example/api"))
        XCTAssertFalse(follows("https://notexample.com/api"))
        XCTAssertFalse(follows("https://api.example.com/api"))
        XCTAssertTrue(TelyBotReplyFetch.followsRedirect(from: URL(string: "http://www.example.com/a"), to: URL(string: "https://example.com/a")))
    }

    func testALookReadsAnOkAnswer() {
        Stub.answer("https://example.com/m", body: Data(#"{"messages":[]}"#.utf8))
        XCTAssertEqual(look("https://example.com/m"), Data(#"{"messages":[]}"#.utf8))
        Stub.answer("https://example.com/m", status: 404, body: Data("{}".utf8))
        XCTAssertNil(look("https://example.com/m"))
    }

    func testALookReadsNothingTooBig() {
        let limit = TelyBotReplyFetch.maxBodyBytes
        Stub.answer("https://example.com/said", headers: ["Content-Length": String(limit + 1)], body: Data("{}".utf8))
        XCTAssertNil(look("https://example.com/said"), "turned away on the length it states")
        Stub.answer("https://example.com/unsaid", body: Data(count: limit + 1))
        XCTAssertNil(look("https://example.com/unsaid"), "and on what arrives")
        Stub.answer("https://example.com/fits", body: Data(count: limit))
        XCTAssertEqual(look("https://example.com/fits")?.count, limit)
    }

    func testALookFollowsARedirectOnlyOnItsOwnSite() {
        Stub.answer("https://example.com/m", status: 301, headers: ["Location": "https://www.example.com/m"])
        Stub.answer("https://www.example.com/m", body: Data("{}".utf8))
        XCTAssertEqual(look("https://example.com/m"), Data("{}".utf8))

        Stub.answer("https://example.com/away", status: 302, headers: ["Location": "https://evil.example/m"])
        Stub.answer("https://evil.example/m", body: Data("{}".utf8))
        XCTAssertNil(look("https://example.com/away"))
        XCTAssertFalse(Stub.asked.contains("https://evil.example/m"), "the conversation id never left")
    }

    override func setUp() {
        super.setUp()
        Stub.reset()
    }

    private func look(_ url: String) -> Data? {
        let configuration = TelyBotReplyFetch.configuration()
        configuration.protocolClasses = [Stub.self]
        let finished = expectation(description: url)
        let result = Box()
        TelyBotReplyFetch.get(URLRequest(url: URL(string: url)!), configuration: configuration) { data in
            result.set(data)
            finished.fulfill()
        }
        wait(for: [finished], timeout: 10)
        return result.get()
    }
}

private final class Box: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Data?
    func set(_ data: Data?) { lock.lock(); value = data; lock.unlock() }
    func get() -> Data? { lock.lock(); defer { lock.unlock() }; return value }
}

/// Answers by URL, and remembers what it was asked.
private final class Stub: URLProtocol {
    private struct Answer {
        let status: Int
        let headers: [String: String]
        let body: Data
    }

    private static let lock = NSLock()
    private static var answers: [String: Answer] = [:]
    private static var askedURLs: [String] = []

    static var asked: [String] {
        lock.lock(); defer { lock.unlock() }
        return askedURLs
    }

    static func reset() {
        lock.lock(); answers = [:]; askedURLs = []; lock.unlock()
    }

    static func answer(_ url: String, status: Int = 200, headers: [String: String] = [:], body: Data = Data()) {
        lock.lock(); answers[url] = Answer(status: status, headers: headers, body: body); lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        Stub.lock.lock()
        Stub.askedURLs.append(url.absoluteString)
        let answer = Stub.answers[url.absoluteString]
        Stub.lock.unlock()
        guard let answer, let response = HTTPURLResponse(url: url, statusCode: answer.status, httpVersion: "HTTP/1.1", headerFields: answer.headers) else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        if let location = answer.headers["Location"], let target = URL(string: location) {
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: target), redirectResponse: response)
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: answer.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
