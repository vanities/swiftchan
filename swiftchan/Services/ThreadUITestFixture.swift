#if DEBUG
import Foundation
import FourChan

/// Deterministic thread content for UI tests; never used in release builds or normal launches.
enum ThreadUITestFixture {
    static func load(board: String, id: Int) throws -> ChanThread? {
        guard ProcessInfo.processInfo.arguments.contains("--ui-thread-fixture"), board == "biz", id == 100 else { return nil }
        let posts: [[String: Any]] = (100...114).map { number in
            var post: [String: Any] = ["no": number, "time": 1_700_000_000, "name": "Anonymous",
                "com": "Reply \(number). " + String(repeating: "A sample discussion about collecting coins and precious metals. ", count: 6)]
            if number == 100 { post["sub"] = "/pmg/ - Precious Metals General" }
            return post
        }
        return try JSONDecoder().decode(ChanThread.self, from: JSONSerialization.data(withJSONObject: ["posts": posts]))
    }
}
#endif
