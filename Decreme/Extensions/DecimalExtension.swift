//
//  DecimalExtension.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 24/12/24.
//

import Foundation

extension Decimal {
    var formattedRupiah: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID") // Indonesian Rupiah
        formatter.maximumFractionDigits = 0
        return formatter.string(from: self as NSDecimalNumber) ?? "Rp0"
    }
}
