#if DEBUG
    import Foundation
    import FourChan
    import Kingfisher
    import UIKit

    /// Deterministic thread content for UI tests; never used in release builds or normal launches.
    enum ThreadUITestFixture {
        static func load(board: String, id: Int) throws -> ChanThread? {
            let arguments = ProcessInfo.processInfo.arguments
            guard arguments.contains("--ui-thread-fixture"), board == "biz",
                  id == 100 || ((arguments.contains("--ui-general-rollover") || arguments.contains("--ui-catalog-fixture")) && id == 200) else { return nil }
            let posts: [[String: Any]] = (id...(id + 14)).map { number in
                var post: [String: Any] = ["no": number, "time": 1_700_000_000, "name": "Anonymous",
                                           "com": "Reply \(number). " + String(repeating: "A sample discussion about collecting coins and precious metals. ", count: 6)]
                if number == id {
                    post["sub"] = "/pmg/ - Precious Metals General"
                    if arguments.contains("--ui-general-rollover"), id == 100 { post["archived"] = 1 }
                }
                if arguments.contains("--ui-media-fixture"), number < id + 3 {
                    let timestamp = 9_000_000_000 + number
                    post["tim"] = timestamp
                    post["filename"] = "collection-study-\(number - id + 1)"
                    post["ext"] = ".png"
                    post["w"] = 1200
                    post["h"] = 900
                    post["tn_w"] = 250
                    post["tn_h"] = 188
                    post["fsize"] = 100_000
                    seedMedia(timestamp: timestamp, index: number - id)
                }
                if arguments.contains("--ui-quote-fixture"), number == 105 || number == 104 {
                    post["com"] = "<a class=\"quotelink\" href=\"#p\(number - 1)\">&gt;&gt;\(number - 1)</a><br>Quoted reply \(number)"
                }
                return post
            }
            return try JSONDecoder().decode(ChanThread.self, from: JSONSerialization.data(withJSONObject: ["posts": posts]))
        }

        /// Invented local artwork keeps gallery tests independent of live posts.
        private static func seedMedia(timestamp: Int, index: Int) {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 900), format: format).image { renderer in
                let context = renderer.cgContext
                let backgrounds: [UIColor] = [.systemIndigo, .systemTeal, .systemBrown]
                backgrounds[index % backgrounds.count].setFill()
                context.fill(CGRect(x: 0, y: 0, width: 1200, height: 900))
                for coin in 0..<3 {
                    let rect = CGRect(x: 150 + coin * 310, y: 240 + (coin % 2) * 80, width: 260, height: 260)
                    context.setShadow(offset: CGSize(width: 8, height: 12), blur: 20, color: UIColor.black.withAlphaComponent(0.3).cgColor)
                    UIColor(red: 0.88, green: 0.72, blue: 0.35, alpha: 1).setFill()
                    context.fillEllipse(in: rect)
                    context.setShadow(offset: .zero, blur: 0)
                    UIColor(red: 0.98, green: 0.9, blue: 0.62, alpha: 1).setStroke()
                    context.setLineWidth(6)
                    context.strokeEllipse(in: rect.insetBy(dx: 18, dy: 18))
                }
                ("COLLECTION STUDY \(index + 1)" as NSString).draw(at: CGPoint(x: 100, y: 100), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 44, weight: .semibold), .foregroundColor: UIColor.white
                ])
                ("Invented gallery fixture" as NSString).draw(at: CGPoint(x: 100, y: 750), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 28), .foregroundColor: UIColor.white.withAlphaComponent(0.7)
                ])
            }
            ImageCache.default.store(image, forKey: "https://i.4cdn.org/biz/\(timestamp).png", toDisk: false)
            ImageCache.default.store(image, forKey: "https://i.4cdn.org/biz/\(timestamp)s.jpg", toDisk: false)
        }

        static func catalog(board: String) throws -> Catalog? {
            let arguments = ProcessInfo.processInfo.arguments
            guard board == "biz" else { return nil }
            if arguments.contains("--ui-catalog-fixture") {
                let threads: [[String: Any]] = [100, 200].map { id in
                    seedMedia(timestamp: 9_000_000_000 + id, index: id == 100 ? 0 : 1)
                    return ["no": id, "sub": id == 100 ? "Coin collecting — this week's finds" : "Designing a display for a collection",
                            "com": "A sample discussion about collecting coins and precious metals.", "replies": 14, "images": 3,
                            "tim": 9_000_000_000 + id, "ext": ".png", "tn_w": 250, "tn_h": 188]
                }
                return try JSONDecoder().decode(Catalog.self, from: JSONSerialization.data(withJSONObject: [["page": 1, "threads": threads]]))
            }
            guard arguments.contains("--ui-general-rollover") else { return nil }
            return try JSONDecoder().decode(Catalog.self, from: Data(#"[{"page":1,"threads":[{"no":100,"sub":"/pmg/ - Old"},{"no":200,"sub":"/pmg/ - New"}]}]"#.utf8))
        }
    }
#endif
