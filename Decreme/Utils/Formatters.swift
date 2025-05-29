//
//  Formatters.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 11/12/24.
//

import Foundation

func formatPrice(_ price: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "id_ID")
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "Rp0"
} 