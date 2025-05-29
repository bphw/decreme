//
//  Constants.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import Foundation

enum NotificationConstants {
    static let authStateDidChange = Notification.Name("authStateDidChange")
}

extension NumberFormatter {
    static let rupiah: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

extension Decimal {
    var formattedRupiah: String {
        NumberFormatter.rupiah.string(from: NSDecimalNumber(decimal: self)) ?? "Rp0"
    }
} 