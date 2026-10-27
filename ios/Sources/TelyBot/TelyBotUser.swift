import Foundation

/// `TelyBot.setUser`'s token: a JWT as the page itself checks its shape (three
/// base64url parts, at most 2000 characters) before it is sent. Anything else is
/// dropped whole; the server does the real verification.
enum TelyBotUser {
    static let max = 2000

    static func clean(_ token: String?) -> String? {
        guard let t = token?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty, t.count <= max else { return nil }
        let parts = t.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, parts.allSatisfy({ !$0.isEmpty && $0.unicodeScalars.allSatisfy(isUrlSafe) }) else { return nil }
        return t
    }

    private static func isUrlSafe(_ c: Unicode.Scalar) -> Bool {
        switch c {
        case "A"..."Z", "a"..."z", "0"..."9", "-", "_": return true
        default: return false
        }
    }

    /// `user=…` for the URL's #fragment, or nothing.
    static func fragmentItems(_ token: String?, encode: (String) -> String) -> [String] {
        guard let token = token, !token.isEmpty else { return [] }
        return ["user=" + encode(token)]
    }

    /// The token as a JSON string for `TelyBot.identify` on a page that is up.
    static func json(_ token: String?) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [token ?? ""], options: []),
              let text = String(data: data, encoding: .utf8), text.count >= 2 else { return "\"\"" }
        return String(text.dropFirst().dropLast())
    }
}
