import Foundation
import SwiftUI

enum AssetType: String, Codable, CaseIterable, Identifiable {
    case crypto
    case stock
    case etf
    case bond
    case commodity
    case cash
    case realEstate
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .crypto: return "Crypto"
        case .stock: return "Stock"
        case .etf: return "ETF"
        case .bond: return "Bond"
        case .commodity: return "Commodity"
        case .cash: return "Cash"
        case .realEstate: return "Real Estate"
        case .other: return "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .crypto: return "bitcoinsign.circle.fill"
        case .stock: return "chart.line.uptrend.xyaxis"
        case .etf: return "chart.pie.fill"
        case .bond: return "doc.text.fill"
        case .commodity: return "cube.fill"
        case .cash: return "banknote.fill"
        case .realEstate: return "house.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .crypto: return .orange
        case .stock: return .blue
        case .etf: return .purple
        case .bond: return .green
        case .commodity: return .yellow
        case .cash: return .mint
        case .realEstate: return .brown
        case .other: return .gray
        }
    }
}
