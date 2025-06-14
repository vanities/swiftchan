//
//  UserSettings.swift
//  swiftchan
//
//  Created on 11/23/20.
//

import FourChan
import SwiftUI

extension UserDefaults {
    // MARK: Getters
    static func getFavoriteBoards() -> [String] {
        return Array(rawValue: UserDefaults.standard.string(forKey: "favoriteBoards") ?? "[]") ?? []
    }
    static func getDeletedBoards() -> [String] {
        return Array(rawValue: UserDefaults.standard.string(forKey: "deletedBoards") ?? "[]") ?? []
    }
    static func getFullImagesForThumbanails() -> Bool {
        return UserDefaults.standard.bool(forKey: "fullImagesForThumbnails")
    }
    static func getShowGifThumbnails() -> Bool {
        return UserDefaults.standard.bool(forKey: "showGifThumbnails")
    }
    static func getShowGalleryPreview() -> Bool {
        return UserDefaults.standard.bool(forKey: "showGalleryPreview")
    }
    static func getShowOPPreview() -> Bool {
        return UserDefaults.standard.bool(forKey: "showOPPreview")
    }
    static func getAutoRefreshThreadTime() -> Int {
        return UserDefaults.standard.integer(forKey: "autoRefreshThreadTime")
    }
    static func getAutoRefreshEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "autoRefreshEnabled")
    }
    static func getBiometricsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "biometricsEnabled")
    }
    static func getDidUnlokcBiometrics() -> Bool {
        return UserDefaults.standard.bool(forKey: "didUnlokcBiometrics")
    }
    static func getShowNSFWBoards() -> Bool {
        return UserDefaults.standard.bool(forKey: "showNSFWBoards")
    }

    static func getSortRepliesBy(boardName: String) -> SortRow.SortType {
        return SortRow.SortType(rawValue: UserDefaults.standard.string(forKey: "sortRepliesBy\(boardName)") ?? "none") ?? .none
    }
    static func getSortFilesBy(boardName: String) -> SortRow.SortType {
        return SortRow.SortType(rawValue: UserDefaults.standard.string(forKey: "sortFilesBy\(boardName)") ?? "none") ?? .none
    }
    static func hiddenPosts(boardName: String, postId: Int) -> Bool {
        return UserDefaults.standard.bool(forKey: "hiddenPosts board=\(boardName) postId=\(postId)")
    }

    // MARK: Setters
    static func setDidUnlokcBiometrics(value: Bool) {
        UserDefaults.standard.set(value, forKey: "didUnlokcBiometrics")
    }
    static func hidePost(boardName: String, postId: Int) {
        UserDefaults.standard.set(true, forKey: "hiddenPosts board=\(boardName) postId=\(postId)")
    }
    static func setSortRepliesBy(boardName: String, type: SortRow.SortType) {
        UserDefaults.standard.set(type.rawValue, forKey: "sortRepliesBy\(boardName)")
        NotificationCenter.default.post(name: .sortingRepliesDidChange, object: nil, userInfo: [:])
    }
    static func setSortFilesBy(boardName: String, type: SortRow.SortType) {
        UserDefaults.standard.set(type.rawValue, forKey: "sortFilesBy\(boardName)")
        NotificationCenter.default.post(name: .sortingFilesDidChange, object: nil, userInfo: [:])
    }
}

extension Notification.Name {
    static let sortingRepliesDidChange = Notification.Name("sortingRepliesDidChange")
    static let sortingFilesDidChange = Notification.Name("sortingFilesDidChange")
}
