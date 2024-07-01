//
//  DateFormatterService.swift
//  swiftchan
//
//  Created by vanities on 11/16/20.
//

import Foundation

@MainActor
class DateFormatterService {
    static let shared = DateFormatterService()
    let dateFormatter = DateFormatter()

    init() {
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    }
}
