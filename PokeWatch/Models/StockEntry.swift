import Foundation
import SwiftUI

enum StockStatus: Equatable {
    case inStock
    case outOfStock
    case unknown(String)

    init(rawText: String) {
        let normalized = rawText.lowercased()
        if normalized.contains("in stock") || normalized.contains("add to cart") || normalized.contains("buy") {
            self = .inStock
        } else if normalized.contains("out of stock") || normalized.contains("sold out") || normalized.contains("unavailable") {
            self = .outOfStock
        } else {
            self = .unknown(rawText)
        }
    }

    var label: String {
        switch self {
        case .inStock: return "In Stock"
        case .outOfStock: return "Out of Stock"
        case .unknown(let raw): return raw.isEmpty ? "Unknown" : raw
        }
    }

    var color: Color {
        switch self {
        case .inStock: return .green
        case .outOfStock: return .red
        case .unknown: return .gray
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
