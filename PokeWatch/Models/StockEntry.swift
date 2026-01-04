import Foundation
import SwiftUI

enum StockStatus: Equatable {
    case inStock
    case preOrder
    case outOfStock
    case unknown(String)

    init(rawText: String, cssClass: String? = nil) {
        if let cssClass {
            let normalizedClass = cssClass.lowercased()
            if normalizedClass.contains("stockstatusin") {
                self = .inStock
                return
            } else if normalizedClass.contains("stockstatuspre") {
                self = .preOrder
                return
            } else if normalizedClass.contains("stockstatusout") {
                self = .outOfStock
                return
            }
        }

        let normalized = rawText.lowercased()
        if normalized.contains("in stock") || normalized.contains("add to cart") || normalized.contains("buy") {
            self = .inStock
        } else if normalized.contains("preorder") || normalized.contains("pre-order") || normalized.contains("pre order") {
            self = .preOrder
        } else if normalized.contains("out of stock") || normalized.contains("sold out") || normalized.contains("unavailable") {
            self = .outOfStock
        } else {
            self = .unknown(rawText)
        }
    }

    var label: String {
        switch self {
        case .inStock: return "In Stock"
        case .preOrder: return "Pre-Order"
        case .outOfStock: return "Out of Stock"
        case .unknown(let raw): return raw.isEmpty ? "Unknown" : raw
        }
    }

    var color: Color {
        switch self {
        case .inStock: return .green
        case .preOrder: return .orange
        case .outOfStock: return .red
        case .unknown: return .gray
        }
    }

    var isAvailable: Bool {
        switch self {
        case .inStock, .preOrder:
            return true
        case .outOfStock, .unknown:
            return false
        }
    }
}

struct StockEntry: Identifiable, Equatable {
    let id = UUID()
    let store: String
    let status: StockStatus
    let productURL: URL?
    let lastChangeText: String?
}
