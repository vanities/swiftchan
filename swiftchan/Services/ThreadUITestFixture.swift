#if DEBUG
import Foundation
import FourChan

/// Deterministic thread content for UI tests; never used in release builds or normal launches.
enum ThreadUITestFixture {
    static func load(board: String, id: Int) throws -> ChanThread? {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--ui-thread-fixture"), board == "biz",
              id == 100 || (arguments.contains("--ui-general-rollover") && id == 200) else { return nil }
        let posts: [[String: Any]] = (id...(id + 14)).map { number in
            var post: [String: Any] = ["no": number, "time": 1_700_000_000, "name": "Anonymous",
                "com": "Reply \(number). " + String(repeating: "A sample discussion about collecting coins and precious metals. ", count: 6)]
            if number == id {
                post["sub"] = "/pmg/ - Precious Metals General"
                if arguments.contains("--ui-general-rollover"), id == 100 { post["archived"] = 1 }
            }
            if arguments.contains("--ui-quote-fixture"), number == 105 || number == 104 {
                post["com"] = "<a class=\"quotelink\" href=\"#p\(number - 1)\">&gt;&gt;\(number - 1)</a><br>Quoted reply \(number)"
            }
            return post
        }
        return try JSONDecoder().decode(ChanThread.self, from: JSONSerialization.data(withJSONObject: ["posts": posts]))
    }

    static func catalog(board: String) throws -> Catalog? {
        guard ProcessInfo.processInfo.arguments.contains("--ui-general-rollover"), board == "biz" else { return nil }
        return try JSONDecoder().decode(Catalog.self, from: Data(#"[{"page":1,"threads":[{"no":100,"sub":"/pmg/ - Old"},{"no":200,"sub":"/pmg/ - New"}]}]"#.utf8))
    }
}
#endif
