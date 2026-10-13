import XCTest
@testable import TelyBot

/// Deliberately platform-free: these cover the two rules that decide whether a
/// customer sees their chat or a 404, and they run under `swift test` on any machine
/// with no simulator involved.
final class TelyBotConfigurationTests: XCTestCase {

    // MARK: - Client id

    func testAcceptsWellFormedClientIds() {
        let valid = [
            "kb_live_3f9a2c81",                                     // 8 hex, the minimum
            "kb_live_0123456789abcdef",
            "kb_live_" + String(repeating: "a", count: 48)          // 48 hex, the maximum
        ]
        for clientId in valid {
            XCTAssertTrue(TelyBotConfiguration.isValidClientId(clientId), "expected \(clientId) to be valid")
        }
    }

    func testRejectsMalformedClientIds() {
        let invalid = [
            "",
            "kb_live_",
            "kb_live_3f9a2c8",                                      // 7 hex, one short
            "kb_live_" + String(repeating: "a", count: 49),         // 49 hex, one long
            "kb_test_3f9a2c81",                                     // wrong environment prefix
            "3f9a2c81",                                             // no prefix
            "KB_LIVE_3f9a2c81",                                     // prefix is case sensitive
            "kb_live_3F9A2C81",                                     // uppercase hex is not in the contract
            "kb_live_3f9a2c8g",                                     // g is not hex
            "kb_live_3f9a2c81 ",                                    // trailing space
            " kb_live_3f9a2c81",
            "kb_live_3f9a2c81\n",                                   // a paste out of the dashboard
            "kb_live_3f9a2c81/../admin",                            // no path smuggling into the URL
            "kb_live_\u{0663}\u{0663}\u{0663}\u{0663}\u{0663}\u{0663}\u{0663}\u{0663}" // Arabic-Indic digits
        ]
        for clientId in invalid {
            XCTAssertFalse(TelyBotConfiguration.isValidClientId(clientId), "expected \(clientId) to be rejected")
        }
    }

    func testInitThrowsOnMalformedClientId() {
        XCTAssertThrowsError(try TelyBotConfiguration(clientId: "nope")) { error in
            guard case TelyBotConfigurationError.invalidClientId = error else {
                return XCTFail("expected .invalidClientId, got \(error)")
            }
        }
    }

    // MARK: - URL building

    func testDefaultBaseUrlMatchesTheContract() {
        // Repeated as a literal in TelyBot.initialize's default argument; if this
        // changes, that changes.
        XCTAssertEqual(TelyBotConfiguration.defaultBaseUrl, "https://telybot.com")
    }

    func testBuildsTheContractUrl() throws {
        let configuration = try TelyBotConfiguration(clientId: "kb_live_3f9a2c81")
        XCTAssertEqual(configuration.chatURL.absoluteString, "https://telybot.com/chat/kb_live_3f9a2c81")
    }

    func testTrailingSlashesInBaseUrlAreDropped() throws {
        for baseUrl in ["https://telybot.com/", "https://telybot.com///", "  https://telybot.com/  "] {
            let configuration = try TelyBotConfiguration(clientId: "kb_live_3f9a2c81", baseUrl: baseUrl)
            XCTAssertEqual(configuration.chatURL.absoluteString, "https://telybot.com/chat/kb_live_3f9a2c81")
        }
    }

    func testBaseUrlPathIsPreservedForSelfHosting() throws {
        let configuration = try TelyBotConfiguration(clientId: "kb_live_3f9a2c81", baseUrl: "https://shop.example.in/support")
        XCTAssertEqual(configuration.chatURL.absoluteString, "https://shop.example.in/support/chat/kb_live_3f9a2c81")
    }

    func testPlainHttpIsAllowedForLocalAndStagingHosts() throws {
        let configuration = try TelyBotConfiguration(clientId: "kb_live_3f9a2c81", baseUrl: "http://192.168.1.5:3000")
        XCTAssertEqual(configuration.chatURL.absoluteString, "http://192.168.1.5:3000/chat/kb_live_3f9a2c81")
    }

    func testRejectsBaseUrlsThatCannotBeLoadedOrHostChecked() {
        for baseUrl in ["", "   ", "/", "telybot.com", "ftp://telybot.com", "file:///tmp", "https://"] {
            XCTAssertThrowsError(try TelyBotConfiguration(clientId: "kb_live_3f9a2c81", baseUrl: baseUrl)) { error in
                guard case TelyBotConfigurationError.invalidBaseUrl = error else {
                    return XCTFail("expected .invalidBaseUrl for \(baseUrl), got \(error)")
                }
            }
        }
    }

    // MARK: - Internal schemes

    /// These are blocked outright rather than handed to `UIApplication.open`, which
    /// cannot open any of them. `javascript:` is the one that matters: a URL that is
    /// really a script must not be passed out of the WebView that contains it.
    func testInternalSchemesAreNotSomewhereAPersonCanBeTaken() {
        for scheme in ["blob", "data", "javascript", "JavaScript", "BLOB", "Data"] {
            XCTAssertTrue(TelyBotConfiguration.isInternalScheme(scheme), "expected \(scheme) to be internal")
        }
    }

    /// `about:` is excluded on purpose — WebKit loads `about:blank` into frames as
    /// part of normal operation, so the navigation policy allows it rather than
    /// cancelling it. The rest are real destinations that belong in the browser or
    /// another app.
    func testSchemesThatMustNotBeTreatedAsInternal() {
        for scheme in ["http", "https", "tel", "mailto", "sms", "whatsapp", "about"] {
            XCTAssertFalse(TelyBotConfiguration.isInternalScheme(scheme), "expected \(scheme) to be external")
        }
    }
}

// MARK: - Staying in the chat
//
// These exist because of a specific, verified trap: the chat page's own
// "Powered by Telybot" link points at the SAME HOST as the chat. A host-only
// comparison lets it load in place, and the customer's conversation is gone —
// the widget re-greets on mount and keeps nothing but a session id.
extension TelyBotConfigurationTests {
    private var chat: URL { URL(string: "https://telybot.com/chat/kb_live_835686cd7c9bf18b9f70c34f")! }

    func testTheChatPageItselfStays() {
        XCTAssertTrue(TelyBotConfiguration.staysInChat(chat, chatURL: chat))
    }

    func testQueryAndFragmentAreStillTheChat() {
        XCTAssertTrue(TelyBotConfiguration.staysInChat(
            URL(string: chat.absoluteString + "?preview=abc.def")!, chatURL: chat))
        XCTAssertTrue(TelyBotConfiguration.staysInChat(
            URL(string: chat.absoluteString + "#top")!, chatURL: chat))
    }

    func testTheSameHostMarketingSiteLeaves() {
        // The exact link the widget renders in its footer.
        XCTAssertFalse(TelyBotConfiguration.staysInChat(
            URL(string: "https://telybot.com/")!, chatURL: chat))
        XCTAssertFalse(TelyBotConfiguration.staysInChat(
            URL(string: "https://telybot.com/pricing")!, chatURL: chat))
    }

    func testAnotherBotsChatLeaves() {
        XCTAssertFalse(TelyBotConfiguration.staysInChat(
            URL(string: "https://telybot.com/chat/kb_live_0000000000000000000000ff")!, chatURL: chat))
    }

    func testDifferentSchemeOrHostLeaves() {
        XCTAssertFalse(TelyBotConfiguration.staysInChat(
            URL(string: "http://telybot.com/chat/kb_live_835686cd7c9bf18b9f70c34f")!, chatURL: chat))
        XCTAssertFalse(TelyBotConfiguration.staysInChat(
            URL(string: "https://evil.example/chat/kb_live_835686cd7c9bf18b9f70c34f")!, chatURL: chat))
    }

    func testAPathThatMerelyStartsWithTheChatPathLeaves() {
        // "/chat/kb_live_835686cd7c9bf18b9f70c34fEXTRA" is a different page.
        XCTAssertFalse(TelyBotConfiguration.staysInChat(
            URL(string: chat.absoluteString + "EXTRA")!, chatURL: chat))
    }
}
