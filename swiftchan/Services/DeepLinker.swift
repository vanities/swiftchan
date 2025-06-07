//
//  DeepLinker.swift
//  swiftchan
//
//  Created on 11/26/21.
//

import Foundation

class Deeplinker {
    enum Deeplink: Equatable {
        case board(name: String)
        case thread(board: String, id: String)
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
        case .thread:
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let board = queryItems?.first(where: { $0.name == "board" })?.value ?? ""
            let id = queryItems?.first(where: { $0.name == "id" })?.value ?? ""
            return .thread(board: board, id: id)
        case .reply:
            let id = String(url.query?.split(separator: "=").last ?? "")
            return .post(id: id)
        case .none:
            return Deeplinker.Deeplink.none
        }
    }
}
