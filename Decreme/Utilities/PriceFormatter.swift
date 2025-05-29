//
//  PriceFormatter.swift
//  Decreme
//
//  Created by Bambang Puji Haryo Wicaksono on 24/12/24.
//

import Foundation

func formatPrice(_ price: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "id_ID") // Indonesian Rupiah
    return formatter.string(from: NSNumber(value: price)) ?? "Rp0"
}
