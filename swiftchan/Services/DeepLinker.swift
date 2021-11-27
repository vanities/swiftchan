//
//  DeepLinker.swift
//  swiftchan
//
//  Created by Adam Mischke on 11/26/21.
//

import Foundation

class Deeplinker {
    enum Deeplink: Equatable {
        case board(name: String)
        case thread(id: String)
        case post(id: String)
        case gallery(id: String)
        case none
    }

    static func getType(url: URL) -> Deeplink? {
        guard url.scheme == URL.appScheme else { return nil }
        switch url.getDetailType() {
        case .board:
            let name = String(url.query?.split(separator: "=").last ?? "")
            return .board(name: name)
        case .reply:
            let id = String(url.query?.split(separator: "=").last ?? "")
            return .post(id: id)
        case .none:
            return .none
        }
    }
}
