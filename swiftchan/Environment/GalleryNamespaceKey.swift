//
//  GalleryNamespaceKey.swift
//  swiftchan
//

import SwiftUI

struct GalleryNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var galleryNamespace: Namespace.ID? {
        get { self[GalleryNamespaceKey.self] }
        set { self[GalleryNamespaceKey.self] = newValue }
    }
}
